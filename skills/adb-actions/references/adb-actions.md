# ADB action catalogue

One row per action. `adb-deck.sh <subcommand>` is what goes on a button; the raw command is what it runs.
Add new actions here as they are found (skill `adb-actions`, step 4).

## Confirmed

Confirmed 2026-11-16 on an Android 16 phone (API 36, OnePlus CPH2493) over wireless debugging, from an Ubuntu host.

| Action | `adb-deck.sh` | Raw adb | What was seen |
|---|---|---|---|
| Find and connect over Wi-Fi | `connect` | `avahi-browse -rpt _adb-tls-connect._tcp` → `adb connect <ip>:<port>` | `connected to <ip>:<port>`, device listed as `device` |
| Is an app installed | `has <pkg>` | `adb shell pm list packages` | package listed |
| Launch an app | `launch <pkg>` | `adb shell monkey -p <pkg> -c android.intent.category.LAUNCHER 1` | app opened in front |
| Open a Play Store page | `play-store <pkg>` | `adb shell am start -a android.intent.action.VIEW -d market://details?id=<pkg> com.android.vending` | intent started (`Starting: Intent {...}`) |
| Screenshot to the host | `screenshot [file]` | `adb exec-out screencap -p > file.png` | full-resolution PNG (1240x2772) |

## Untested

Standard adb commands wired into the script but not yet run from a deck button on a real device.

| Action | `adb-deck.sh` | Raw adb |
|---|---|---|
| Open any URL | `open-url <url> [pkg]` | `adb shell am start -a android.intent.action.VIEW -d <url> [pkg]` |
| Key press (Home, Back, volume, media) | `key <KEYCODE>` | `adb shell input keyevent KEYCODE_HOME` (`KEYCODE_BACK`, `KEYCODE_VOLUME_UP`, `KEYCODE_MEDIA_PLAY_PAUSE`) |
| Type text | `text <words>` | `adb shell input text` (spaces sent as `%s`) |
| Swipe / scroll | `swipe x1 y1 x2 y2 [ms]` | `adb shell input swipe` (pixels of the real screen, not a scaled screenshot) |
| Tap | `tap x y` | `adb shell input tap` |

## Traps

- **The wireless port does not last.** The `_adb-tls-connect` port changes each time Wireless debugging is switched on,
  and the phone can drop it a few minutes into a session (seen 2026-11-16: connected, then `device not found` on the
  next command and no `_adb-tls-connect` advert at all). `adb-deck.sh` rediscovers on every call; if nothing is
  advertised, Wireless debugging is off on the phone and only the user can turn it back on.
- **`adb mdns services` can miss the phone** while `avahi-browse` sees it. The script uses avahi.
- **Screenshots shown to an agent may be scaled.** Take tap and swipe coordinates from the device's real resolution
  (`adb shell wm size`), not from a downscaled image.
- **Working out a tap target for a button:** if a [mobile-mcp](https://github.com/mobile-next/mobile-mcp) server is
  connected to the device, read the element's coordinates from `mobile_list_elements_on_screen` (real screen pixels)
  instead of a screenshot or `uiautomator dump`, which can return stale XML on some screens. The button itself still
  runs `adb-deck.sh`: the deck host runs plain commands, not MCP tools. Don't put a secret in a `text` button.
