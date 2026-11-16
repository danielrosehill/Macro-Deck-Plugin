---
name: connect-mcp
description: Connect Claude Code to Macro Deck 3's built-in MCP server (Streamable HTTP at /mcp) with an access token, then verify the tools. Use on "connect Macro Deck MCP".
---

# Connect the Macro Deck MCP server

Macro Deck 3 has an MCP server built into the host. Nothing extra to install. Contract `macrodeck-mcp/1`.

- Endpoint: `http://127.0.0.1:<port>/mcp` (port from Settings → Network, default 8193). Plain HTTP: use it on the same
  machine, not across an untrusted network.
- Auth: `Authorization: Bearer mdmcp_<64 hex>`. Tokens are made in the app only, shown once, never expire, and work only on
  `/mcp`. Requests with a foreign `Origin` header are refused.

## 1. The user creates a token

Only the user can do this. Ask them to open **Settings → AI clients → Create token**, name it after the agent
(e.g. `claude-code`), and either paste it or save it in their password manager and tell you where. Never echo the token
back in the reply.

Store it where the user keeps secrets (their password manager), not in a plain file in a repo.

## 2. Register with Claude Code

User scope, so every project can use it. Keep the token out of the config file: use a `headersHelper`, a command
Claude Code runs on connect that prints the headers as JSON and reads the token from the user's secret store.

```bash
cat > ~/.local/bin/macro-deck-mcp-headers <<'EOF'
#!/bin/sh
# Prints {"Authorization": "Bearer <token>"}. Replace the token source with the user's own:
#   op read "op://<vault>/<item>/credential"   (1Password)
#   with-secrets sh -c 'echo "$MACRODECK_MCP_TOKEN"'   (an env injector)
TOKEN=$(op read "op://<vault>/<item>/credential")
printf '{"Authorization": "Bearer %s"}' "$TOKEN"
EOF
chmod +x ~/.local/bin/macro-deck-mcp-headers
claude mcp add-json --scope user macro-deck \
  "{\"type\":\"http\",\"url\":\"http://127.0.0.1:8193/mcp\",\"headersHelper\":\"$HOME/.local/bin/macro-deck-mcp-headers\"}"
claude mcp get macro-deck    # Status: ✔ Connected
```

The app shows a ready-made `claude mcp add ... --header "Authorization: Bearer mdmcp_..."` line when the token is
created; it works, but it writes the token into `~/.claude.json`. Prefer the helper. Tools load at the next session
start; until then use `scripts/mdmcp.py` (stateless client, see `build-deck/references/schema-notes.md`).

Fallback for clients without HTTP transport: the stdio bridge
`MACRODECK_MCP_TOKEN=mdmcp_... <Macro Deck executable> mcp`.

## 3. Verify without the MCP client

```bash
curl -s http://127.0.0.1:8193/mcp \
  -H "Authorization: Bearer $MACRODECK_MCP_TOKEN" -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

Expect nine tools: `catalog`, `list`, `get`, `set_secret`, `apply_changes`, `undo`, `run_action`, `run_script`,
`trigger_event`. A 401 means a wrong or revoked token.

## 4. Action policy

In **Settings → AI clients → Actions AI clients may run**, built-in actions in the risk categories `scripts`, `programs`,
`input`, `network`, `files` and `power` ask first by default, and every plugin action asks first. This only affects
`run_action` / `run_script` from the agent, not presses on the deck. Leave it as is unless the user wants the agent to
test-fire buttons.

Next: `init-decks-repo` (once), then `build-deck`.
