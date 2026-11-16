# Minimal stateless client for the Macro Deck 3 MCP server (protocol 2026-07-28), for use without an MCP client
# (e.g. before the session has the server loaded). Usage: MACRODECK_MCP_TOKEN=... python3 mdmcp.py <tool> '<json args>'
# Env MACRODECK_MCP_URL overrides http://127.0.0.1:8193/mcp. Prints the tool result text.
import json, os, sys, urllib.request
tool, args = sys.argv[1], json.loads(sys.argv[2] if len(sys.argv) > 2 else "{}")
body = {"jsonrpc": "2.0", "id": 1, "method": "tools/call",
        "params": {"name": tool, "arguments": args, "_meta": {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}, "io.modelcontextprotocol/clientInfo": {"name": "macro-deck-plugin", "version": "1"}}}}
req = urllib.request.Request(os.environ.get("MACRODECK_MCP_URL", "http://127.0.0.1:8193/mcp"), json.dumps(body).encode(), {
    "Authorization": "Bearer " + os.environ["MACRODECK_MCP_TOKEN"], "Content-Type": "application/json",
    "Accept": "application/json, text/event-stream", "MCP-Protocol-Version": "2026-07-28", "Mcp-Method": "tools/call", "Mcp-Name": tool})
try: t = urllib.request.urlopen(req).read().decode()
except urllib.error.HTTPError as e: t = e.read().decode()
d = json.loads(t[t.find("{"):t.rfind("}") + 1])
r = d.get("result", d)
if "error" in d: print("ERROR", d["error"])
for c in r.get("content", []): print(c.get("text", ""))
if r.get("isError"): print("ISERROR")
