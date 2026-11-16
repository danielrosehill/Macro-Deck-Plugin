---
name: build-deck
description: Build or update a Macro Deck deck (folder of buttons) from a short spec through the MCP server, dry run first. Use on "make a deck for X", "add a button".
---

# Build a deck

A deck is a **folder** of button **widgets** in a Macro Deck **profile**. Each button's actions live in the widget's
`data` as action flows. The source of truth is a spec, `decks/<slug>/deck.json` in the user's decks repo (path in
`config.json`, see `init-decks-repo`); the live deck is generated from it.

Requires the `macro-deck` MCP server (`connect-mcp`). Tools: `catalog`, `list`, `get`, `apply_changes`, `undo`,
`set_secret`, `run_action`.

## 1. Write or update the spec

From the user's request, write `deck.json` in the format of `references/deck-spec.md`. Ask only what you cannot
infer (usually: what each button should do on the host). For host operations, prefer in this order:

1. **HTTP request** to a local API the app already exposes (no focus needed, works on Wayland).
2. **Run a command** (shell, `curl`, `qdbus`, `playerctl`, a script in the repo's `scripts/`).
3. **Keystrokes** only as a last resort: they need the target window focused and do not reach native Wayland apps.

Find the target app's control surface first (`ss -ltnp` for local ports, its docs, its CLI `--help`) rather than guessing.

## 2. Learn the schemas (every build; they are versioned)

Start from `references/schema-notes.md` (button data, flow and block format, entity-name traps, all confirmed on a
real build); then confirm against the live host:

- `catalog {kind: "widgetTypes"}`: each type's `defaultData` and `dataSchema` (use the button type).
- `catalog {kind: "actions"}`: integration and action ids and their parameters. Pick the HTTP-request and run-program
  actions from the built-in integrations.
- `list {entity: "profiles"}`, `list {entity: "folders", profileId}`: what exists. Update in place if the spec's deck
  folder exists (match by name, or by ids recorded in `hosts/<hostname>.json`).

Record any schema detail you had to work out in `references/schema-notes.md` of this plugin (contract version, date).

## 3. Dry run, then apply

One `apply_changes` batch (max 100 changes), `dryRun: true` first:

- `create folder {profileId, name}` with `ref: "f"`, then `update` it with `rows`/`columns` in a **second** batch
  (an object created in a batch cannot be changed in the same batch).
- `create widget {folderId: "@f", type, positionX, positionY, width: 1, height: 1, data}` per button, `data` built from
  the type's `defaultData` plus label, colours, icon and the action flow.
- Secrets: call `set_secret` (user types the value in a browser page), put the returned `{"$secret": "<id>"}` in the
  parameter. Steps using a secret stay inactive until the user approves them in the app (Approvals sidebar). Tell them.

Show the user the dry-run `problems[]`/`confirmations[]` only if non-empty, fix, then apply with `dryRun: false`. Keep the
returned `batchId`; `undo {batchId}` reverts it.

## 4. Verify and record

- `get {entity: "widget", id}` for one button and check its flow matches the spec.
- If the user allowed it, `run_action` with a harmless action to prove the route (never a destructive one).
- Ask the user to look at the phone: the deck updates live.
- Write the ids into `hosts/<hostname>.json`, run `save-decks` for a snapshot, commit and push the decks repo.
