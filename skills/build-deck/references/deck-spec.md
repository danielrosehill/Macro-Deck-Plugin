# Deck spec (`decks/<slug>/deck.json`)

A small, app-independent description of a deck. `build-deck` turns it into Macro Deck MCP changes.

```json
{
  "spec": 1,
  "name": "ASR Recorder",
  "profile": "Default Profile",
  "folder": "ASR Recorder",
  "rows": 2,
  "columns": 3,
  "buttons": [
    {
      "label": "Record",
      "at": [0, 0],
      "color": "#c62828",
      "icon": "mdi:record",
      "action": {
        "kind": "http",
        "method": "POST",
        "url": "http://127.0.0.1:8724/action",
        "headers": {"content-type": "application/json"},
        "body": {"action": "record"}
      }
    },
    {
      "label": "Mute mic",
      "at": [0, 1],
      "action": {"kind": "command", "run": "pactl set-source-mute @DEFAULT_SOURCE@ toggle"}
    },
    {
      "label": "Save",
      "at": [0, 2],
      "action": {"kind": "keys", "keys": "ctrl+s"}
    }
  ]
}
```

| Field | Meaning |
|---|---|
| `profile` | Existing profile name to put the folder in (profiles cannot be deleted over MCP). |
| `folder` | The deck. One folder per spec. |
| `rows`, `columns` | Folder grid. Integers. |
| `at` | `[row, column]`, zero-based → widget `positionY`, `positionX`. |
| `action.kind` | `http` (preferred), `command`, `keys`, or `raw` (`{"integrationId", "actionId", "parameters"}` straight from `catalog`). |
| secrets | Any value can be `{"$secret": "<label>"}`; `build-deck` resolves it with `set_secret`. Never a literal secret. |

Keep the spec free of host-only values where possible; put host specifics (ports, ids) in `hosts/<hostname>.json`.
