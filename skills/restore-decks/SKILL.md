---
name: restore-decks
description: Recreate decks from the user's decks repo on a Macro Deck host, e.g. a new or rebuilt computer. Use on "restore my decks", "put my decks on this machine".
---

# Restore decks on a host

1. Check the host is set up (`setup-host`) and the MCP server is connected (`connect-mcp`).
2. Pull the decks repo (`decks_repo` in the plugin's `config.json`; if this is a new machine, clone the repo and run
   `init-decks-repo`, which records the existing clone instead of creating a new repo).
3. Ask which decks (default: all under `decks/`). For each, run `build-deck` from its `deck.json`. If there is only a
   `snapshot.json`, convert it to a spec first; do not replay snapshot ids, they belong to the old host.
4. Host-specific values (ports, IPs, paths) come from `hosts/<this hostname>.json` if present; otherwise ask, and write
   that file.
5. Secrets are not in the repo: `build-deck` asks for each one through `set_secret`, and the user approves the steps in
   the app.
6. `save-decks` to record the new host's ids, commit and push.
