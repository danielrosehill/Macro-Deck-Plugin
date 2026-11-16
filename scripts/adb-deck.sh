#!/usr/bin/env bash
# adb-deck: run ADB actions on a connected Android device from a Macro Deck button.
# Each subcommand is one deck action; see skills/adb-actions/references/adb-actions.md for which are confirmed.
#
# Device selection, first match wins:
#   1. $ADB_SERIAL (e.g. 10.0.0.52:39995 or a USB serial)
#   2. "serial" in the config file below
#   3. the only device in `adb devices`
#   4. wireless reconnect: find _adb-tls-connect._tcp on the LAN with avahi-browse (optionally limited to "ip" in
#      the config file) and `adb connect` to it. The wireless-debugging port changes every time it is turned on, so
#      a fixed ip:port goes stale; this step finds the current one.
#
# Config (user data, never in this repo):
#   ${CLAUDE_USER_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/claude-plugins}/macro-deck/adb.json
#   {"serial": "<optional fixed serial>", "ip": "<optional phone LAN IP for wireless reconnect>"}
set -euo pipefail

CFG="${CLAUDE_USER_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/claude-plugins}/macro-deck/adb.json"
cfg() { [ -f "$CFG" ] && command -v jq >/dev/null && jq -r ".$1 // empty" "$CFG" || true; }

online() { adb devices | awk 'NR>1 && $2=="device"{print $1}'; }

resolve() {
  local s="${ADB_SERIAL:-$(cfg serial)}"
  if [ -n "$s" ] && online | grep -qx "$s"; then echo "$s"; return; fi
  local devs; devs=$(online)
  if [ -z "$s" ] && [ "$(printf '%s\n' "$devs" | grep -c .)" = 1 ]; then echo "$devs"; return; fi
  local ip; ip="$(cfg ip)"
  local hit
  hit=$(timeout 8 avahi-browse -rpt _adb-tls-connect._tcp 2>/dev/null \
        | awk -F';' -v ip="$ip" '/^=/ && $3=="IPv4" && (ip=="" || $8==ip) {print $8":"$9; exit}')
  if [ -n "$hit" ]; then
    adb connect "$hit" >/dev/null 2>&1 || true
    if online | grep -qx "$hit"; then echo "$hit"; return; fi
  fi
  echo "adb-deck: no device. Turn on Wireless debugging (or plug in USB) and pair this host once." >&2
  exit 2
}

cmd="${1:-}"; shift || true
case "$cmd" in
  serial)     resolve ;;
  connect)    S=$(resolve); echo "connected: $S" ;;
  launch)     S=$(resolve); adb -s "$S" shell monkey -p "$1" -c android.intent.category.LAUNCHER 1 >/dev/null ;;
  open-url)   S=$(resolve); adb -s "$S" shell am start -a android.intent.action.VIEW -d "$1" ${2:+"$2"} >/dev/null ;;
  play-store) S=$(resolve); adb -s "$S" shell am start -a android.intent.action.VIEW \
                -d "market://details?id=$1" com.android.vending >/dev/null ;;
  screenshot) S=$(resolve); out="${1:-$HOME/Pictures/adb-$(date +%Y%m%d-%H%M%S).png}"
              adb -s "$S" exec-out screencap -p > "$out"; echo "$out" ;;
  has)        S=$(resolve); adb -s "$S" shell pm list packages | grep -qx "package:$1" && echo yes || { echo no; exit 1; } ;;
  key)        S=$(resolve); adb -s "$S" shell input keyevent "$1" ;;
  text)       S=$(resolve); adb -s "$S" shell input text "$(printf '%s' "$*" | sed 's/ /%s/g')" ;;
  swipe)      S=$(resolve); adb -s "$S" shell input swipe "$@" ;;
  tap)        S=$(resolve); adb -s "$S" shell input tap "$1" "$2" ;;
  *) echo "usage: adb-deck.sh serial|connect|launch <pkg>|open-url <url> [pkg]|play-store <pkg>|screenshot [file]|has <pkg>|key <KEYCODE>|text <s>|swipe x1 y1 x2 y2 [ms]|tap x y" >&2; exit 64 ;;
esac
