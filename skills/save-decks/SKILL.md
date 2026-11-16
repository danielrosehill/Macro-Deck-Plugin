---
name: save-decks
description: Snapshot the live Macro Deck profiles, folders and buttons into the user's decks repo and push. Use on "save my decks", "back up the macropad", after any deck edit.
---

# Save decks to the repo

Reads the live state over the `macro-deck` MCP server and writes it into the decks repo (`decks_repo` in
`${CLAUDE_USER_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/claude-plugins}/macro-deck/config.json`; run
`init-decks-repo` first if missing).

## Steps

1. `list {entity: "profiles"}`, then per profile `list {entity: "folders", profileId}` and
   `list {entity: "widgets", folderId}`; `get` each widget (its `data` holds the action flows). Also `list` scripts,
   automations and variables, and `get` each script/automation for its flows.
2. Write per deck folder `decks/<folder-slug>/snapshot.json`:
   `{"saved_at": <ISO>, "host": <hostname>, "contract": "macrodeck-mcp/1", "profile": {...}, "folder": {...}, "widgets": [...]}`.
   Scripts, automations and variables go in `shared/{scripts,automations,variables}.json`.
   Sort keys and arrays (by position, then id) so diffs show real changes only.
3. `secretBlocks` and `{"$secret": ...}` references are kept as references. Secret values are never readable over MCP;
   do not try to get them another way.
4. If a deck has no `deck.json` yet (built by hand in the app), derive one from the snapshot (see
   `build-deck/references/deck-spec.md`) so it can be rebuilt.
5. Update `hosts/<hostname>.json` (Macro Deck version from `dpkg-query -W macro-deck` or the app, port, folder ids).
6. Commit only the files written (`Save decks from <hostname>`) and push. Report which decks changed.

Snapshots are for history and restore. To change a deck, edit `deck.json` and run `build-deck`.

For a full-fidelity backup of everything (including secrets), point the user to the app's own encrypted backups
(Settings → Backups, `.macroDeckBackup`) and keep the recovery key in their password manager. Do not put those files in git.
