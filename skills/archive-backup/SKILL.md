---
name: archive-backup
description: Copy a Macro Deck .macroDeckBackup file into the user's private decks repo, index it and push. Use on "save my Macro Deck backup", "archive the backup".
---

# Archive a Macro Deck backup in the decks repo

Macro Deck's own backups (Settings → Backups) are the full-fidelity copy: profiles, scripts, automations, variables,
icons, plugins, settings, accounts and secrets. They complement `save-decks` snapshots, which are readable but leave
secrets out. This skill keeps the backup files safe in the user's private decks repo (`decks_repo` in
`${CLAUDE_USER_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/claude-plugins}/macro-deck/config.json`; run
`init-decks-repo` first if missing).

## What a backup file is

`<UTC timestamp>-<backupId>.macroDeckBackup` is a zip of two entries:

- `manifest.json`: plaintext metadata (`backupId`, `macroDeckVersion`, `createdAt`, `trigger`, `hostPlatform`,
  `recoveryKeyId`, `components`, `encryption`). No secrets.
- `payload.enc`: the data, AES-256-GCM, key derived (HKDF-SHA256) from the installation's **recovery key**.

The file cannot be restored without the recovery key, so it is safe in a **private** repo. The recovery key itself
never goes in the repo; it belongs in the user's password manager. Never commit a backup to a public repo.

## Steps

1. **Find the file.** Use the path the user gives; else look in `~/Desktop`, `~/Downloads` and Macro Deck's data
   folder `${XDG_DATA_HOME:-$HOME/.local/share}/MacroDeck/backups/` for `*.macroDeckBackup`, newest first. Several
   found: list them (name, size, date) and ask which, default the newest.
2. **Check it.** `unzip -l` must show exactly `manifest.json` and `payload.enc`; read `manifest.json`
   (`unzip -p <file> manifest.json`). Refuse a file without `encryption` in its manifest (unencrypted: ask the user
   before committing it). Note `recoveryKeyId`.
3. **Copy, don't move**, to `backups/<hostname>/<original file name>` in the decks repo. Same `backupId` already
   there with the same sha256: say so and stop.
4. **Index.** Append one entry to `backups/index.json` (create it as `[]` if missing), sorted by `createdAt`:
   `{"file", "host", "backupId", "createdAt", "macroDeckVersion", "trigger", "components", "recoveryKeyId",
   "sha256", "bytes", "archivedAt"}`.
5. **Recovery key check.** Tell the user which `recoveryKeyId` the backup needs and ask whether that key is in their
   password manager (don't read the key). A backup whose key is lost is useless; if they rotated the key since, the
   old key must be kept too.
6. **Commit and push** only the two paths (`git add backups/<hostname>/<file> backups/index.json`),
   message `Archive Macro Deck backup <createdAt> from <hostname>`. Report the repo path and size. Files are about
   1 MB; if `backups/` passes ~200 MB, suggest pruning to the newest few per host (ask before deleting).

The original file stays where it was; offer to delete it only after the push succeeds.

## Restore (pointer)

In Macro Deck: Settings → Backups → restore from file, then enter the recovery key. Copy the file out of the repo
first; use `backups/index.json` to pick the right one by host and date.
