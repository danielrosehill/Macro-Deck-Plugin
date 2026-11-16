---
name: adb-actions
description: Put ADB actions for a connected Android device (USB or wireless debugging) on Macro Deck buttons, and record each new ADB action once it is confirmed. Use on "add an adb button", "control my phone from the deck", "add this adb action to the plugin".
---

# ADB actions on deck buttons

The Macro Deck host runs the button's command; the command drives an Android device over `adb`. Every action goes
through `scripts/adb-deck.sh` (this plugin), which finds the device each time, so a wireless-debugging port that
changed since yesterday does not break the button.

Requires: `adb` and, for wireless reconnect, `avahi-browse` (package `avahi-utils`) on the host; the device paired
with this host once (Developer options → Wireless debugging → Pair, or USB with debugging authorised). Pairing is not
this skill: use an adb pairing skill or `adb pair <ip>:<pairing-port> <code>`.

## 1. Device config (once per host)

Optional user-data file, never in a repo:
`${CLAUDE_USER_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/claude-plugins}/macro-deck/adb.json`

```json
{"ip": "<phone LAN IP>"}
```

`ip` limits wireless reconnect to that phone when several devices advertise debugging. `serial` pins one device.
With neither, the only connected device is used. Check with `scripts/adb-deck.sh connect`.

## 2. Pick the action

Take it from `references/adb-actions.md`. Only **confirmed** entries go on a button without testing; an **untested**
one is run by hand against the device first and then moved to confirmed (step 4).

## 3. Build the button

Use `build-deck` with a Run Command block (`app.macro-deck.system` / `run-command`, `shell: bash`):

```json
{"type": "action", "blockType": "app.macro-deck.system.run-command", "label": "Run Command",
 "integrationId": "app.macro-deck.system", "actionId": "run-command",
 "parameters": [
   {"name": "shell", "type": "choice", "label": "Shell", "value": "bash"},
   {"name": "command", "type": "string", "label": "Command",
    "value": "<absolute path to the plugin>/scripts/adb-deck.sh launch app.macrodeck.companion"},
   {"name": "timeout", "type": "number", "label": "Timeout", "value": 15000}]}
```

Use the absolute path to the script (the plugin's install or clone path on that host), never `~` or a relative path.
Allow about 15 s on any action that may reconnect wirelessly (avahi discovery waits up to 8 s). Run Command is risk
category `programs`; `apply_changes` reports `risky-action` and still applies.

## 4. Record new actions (the point of this skill)

Whenever an ADB action is worked out in a session (for a deck or not), add it to `references/adb-actions.md`:

- the `adb-deck.sh` subcommand, adding one to the script if the action needs it (keep one subcommand per action);
- the raw adb command;
- **status**: `confirmed` (ran on a real device: give date, Android version or model, and what you saw) or
  `untested`;
- any trap found on the way.

Commit and push the plugin with the change. No personal IPs, serials or device names in the repo.
