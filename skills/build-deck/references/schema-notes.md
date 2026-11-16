# Macro Deck MCP schema notes

Confirmed against Macro Deck 3.0.2, contract `macrodeck-mcp/1`, on 2026-11-16 (first deck built end to end).
Re-check with `catalog` when the host version changes.

## Entity names differ by tool

- `list` and `get` take **plural** entities: `profiles`, `folders`, `widgets`, `automations`, `scripts`, `variables`.
  `get {entity: "widget"}` fails with `INVALID_ARGUMENT`.
- `apply_changes` takes **singular** entities: `profile`, `folder`, `widget`, `automation`, `script`, `variable`.

## Button widget

Type `ActionButton`. `data` (schema `widget-data-action-button-v2`): `label`, `backgroundColor` (`#rrggbb`),
`labelColor`, `icon` (`{type: "icon-pack", reference}`), `imageUrl`, `flows`, and state fields for N-state buttons.
`flows` is stored as a JSON string; an array is accepted on write.

## Action flow

```json
{
  "triggerId": "<uuid>",
  "triggerType": "onShortPress",
  "triggerLabel": "Short press",
  "children": [
    {
      "id": "<uuid>",
      "type": "action",
      "blockType": "app.macro-deck.http.send-request",
      "label": "Send HTTP Request",
      "color": "#4f7cff",
      "integrationId": "app.macro-deck.http",
      "actionId": "send-request",
      "parameters": [
        {"name": "method", "type": "choice", "label": "Method", "value": "POST"},
        {"name": "url", "type": "url", "label": "URL", "value": "http://127.0.0.1:8724/action"},
        {"name": "bodyType", "type": "choice", "label": "Body type", "value": "json"},
        {"name": "jsonBody", "type": "json", "label": "JSON body", "value": "{\"action\": \"record\"}"},
        {"name": "expectedStatus", "type": "string", "label": "Expected status", "value": "2xx"},
        {"name": "timeout", "type": "duration", "label": "Timeout", "value": 5000}
      ]
    }
  ]
}
```

- `blockType` is `<integrationId>.<actionId>` for integration actions. Built-in control blocks: `ifElse`, `switch`,
  `repeatLoop`, delays.
- Parameter values: strings, numbers, booleans, `{"$var": name}`, `{"$secret": id}`, `{"$event": id}`, hotkeys
  `{modifiers, key, code}`. A `json` parameter's value is a JSON **string**.
- Other press triggers exist besides `onShortPress` (long press etc.); check the source if a deck needs them
  (`ui/runtime/src/domain/action-builder.interface.ts`, `host/src/MacroDeckHost.Application/Actions/TriggerSelector.cs`
  in github.com/Macro-Deck-App/Macro-Deck).
- Useful built-in actions for host operations: `app.macro-deck.http/send-request`, `app.macro-deck.system/run-command`
  (`shell`: default|bash|powershell, `command`), `app.macro-deck.system/launch-application`. Full list:
  `catalog {kind: "actions"}` (about 54 KB).

## Writes

- **Dry runs do not catch layout clashes.** A batch that passed `dryRun` failed on apply with `PositionOccupied`
  (moving buttons onto each other's cells) and `Placement outside the folder grid` / `GridTooSmall` (grid resized
  while old buttons still sat outside it). Changes are checked in order. To relayout a deck, use one batch ordered:
  **delete every old widget → update the folder `rows`/`columns` → create the new widgets.** A failed apply is
  rolled back (`applied: false`).
- **Relayout in place, keeping widget ids and flows** (confirmed 2026-11-16, Macro Deck 3.0.2, daniellaptop, 3x3 to 2x4):
  `update widget {id, data: {positionX, positionY}}` moves a button and leaves its `data` (label, icon, flows) untouched.
  Order the batch so every move lands on a free cell: first `update folder` to a grid big enough for both layouts
  (here 3 cols x 4 rows), then the moves, then shrink the folder to the final grid last. A button that needs two moves
  (a swap through a spare cell) goes in a second batch.
- **Phone layout:** the web client scales the whole grid to fit the screen, so on a phone held upright a 2-column grid
  gives buttons half the screen wide; 3x3 left them small (user feedback 2026-11-16). Put the most-used buttons in the
  bottom row (thumb reach) and destructive ones away from them.
- Icons: `data.icon = {"type": "icon-pack", "reference": <icon id>}` plus `iconColor`; see skill `icon-packs`.

- `apply_changes` on any new HTTP/command block returns a `risky-action` confirmation; the batch still applies.
  It does not make the button wait for approval; only secret-using blocks wait for approval in the app.
- Folder grid: `update folder {name, rows, columns}`. Profiles cannot be deleted over MCP.

## Raw protocol (no MCP client)

The host speaks Streamable HTTP. The stateless revision `2026-07-28` needs, on every `tools/call`:
headers `MCP-Protocol-Version: 2026-07-28`, `Mcp-Method: tools/call`, `Mcp-Name: <tool>`, and in `params._meta`
`io.modelcontextprotocol/protocolVersion`, `io.modelcontextprotocol/clientCapabilities` (object) and
`io.modelcontextprotocol/clientInfo`. Without the protocol header the server wants a session (`initialize` first).
`scripts/mdmcp.py` does all of this.
