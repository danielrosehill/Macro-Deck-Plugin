# Macro Deck Plugin

Agent skills for turning a phone or tablet into a macropad for **host operations** with
[Macro Deck 3](https://macro-deck.app/): install the host on Linux, connect its built-in MCP server, have the agent
build decks from a short spec, and keep every deck in a private git repo you own.

Macro Deck 3 (stable since 2026-10-31) runs on Windows, macOS and Linux. The phone shows the deck (free web client or
the paid Companion app) and sends presses; the computer runs the actions. Its MCP server lets an agent create folders,
buttons and action flows directly, with dry runs and undo.

## Skills

| Skill | What it does |
|---|---|
| `setup-host` | Install Macro Deck 3 from its APT repo, open the ports to the LAN/tailnet, connect the phone; Linux/Wayland caveats |
| `connect-mcp` | Register the host's MCP server (`/mcp`, bearer token) with Claude Code and verify the nine tools |
| `init-decks-repo` | Onboarding: create a private repo for your decks (`decks/<slug>/deck.json` specs, snapshots, `hosts/`) |
| `build-deck` | Build or update a deck from a spec: schema discovery via `catalog`, dry run, apply, verify, record |
| `save-decks` | Snapshot the live decks into the repo and push |
| `archive-backup` | Copy an encrypted `.macroDeckBackup` into the decks repo, index it, check the recovery key is kept |
| `restore-decks` | Recreate decks on a new or rebuilt host from the repo |

Order on a new setup: `setup-host` → `connect-mcp` → `init-decks-repo` → `build-deck`.

## Host operations, not keystrokes

Buttons should call something that works without window focus: a local HTTP API (best), or a command. Keystroke buttons
need the target window focused and, on Wayland, reach only XWayland apps.

## Data

- Your decks: the private repo you create with `init-decks-repo`.
- Plugin config (pointer to that repo): `${CLAUDE_USER_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/claude-plugins}/macro-deck/config.json`.
- Tokens and secrets: your password manager; never the repo.

## Installation

```bash
claude plugins install macro-deck@danielrosehill
```

## License

MIT
