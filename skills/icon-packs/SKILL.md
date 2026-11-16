---
name: icon-packs
description: Find, install and use Macro Deck icon packs (MDI-Icons, Store packs, own images) on deck buttons. Use on "add icons", "which icon packs", "install an icon pack".
---

# Icon packs

Buttons look best with icons from an installed **icon pack**, one consistent pack per deck, rather than SVG data URIs
in `imageUrl` (tried 2026-11-16: mixed sizes, colours and home-made images looked worse than standard media icons).

## What is installed

```bash
python3 scripts/find_icon.py --packs                 # packs: id, name, source, icon count
python3 scripts/find_icon.py --exact pause skip-next # icons by exact name, all packs
python3 scripts/find_icon.py --pack mdi record       # substring search in one pack
```

Packs live read-only under `${XDG_DATA_HOME:-$HOME/.local/share}/MacroDeck/data/icons/packs/<packId>/pack.json`
(plus `icons/`). Never edit them; the app owns them. Every host has:

- **Included**: Lucide icons (ISC licence), about 27, read-only.
- **Imported Icons**: the user's own imported images (default pack, writable through the app).

## Recommended Store packs

| Pack | Store id | Use |
|---|---|---|
| **MDI-Icons** (SimplyJames) | `com.simplyjames.mdi-icons` | 7,400 Material Design Icons, monochrome, tint with `iconColor`. Default choice: names match materialdesignicons.com (`record`, `pause`, `skip-next`, `restart`, `delete`, `cloud-upload`...). |
| **Colorful Generic Icons** (SuchByte) | `com.suchbyte.colorful-generic-icons` | 19 coloured tiles from Macro Deck 2 (play/pause, next track, mic muted...). Only for decks whose every button has a match; don't mix with MDI. |

## Installing a pack

There is no MCP tool or documented API for the Store. Two routes:

1. **Ask the user** (default): Macro Deck → **Store** → search the pack → **Install**. Then re-run `find_icon.py --packs`.
2. **Drive the GUI** if a desktop driver is available (e.g. kwin-mcp on KDE Plasma Wayland), on the live session only
   with the user's go-ahead: open the Store page, find the pack card, press Install, confirm with `find_icon.py`.

A `.macroDeckIconPack` file (zip with `pack.json` + images) is imported in the app's **Library**. Plugin authors can bundle
packs with `macrodeck-plugin icon-pack add <file>` (see the official skill `macro-deck-plugin-creator` in
github.com/Macro-Deck-App/Macro-Deck-Skills, installable with `gh skill install`).

## Using an icon on a button

In the widget `data` (see `build-deck/references/schema-notes.md`):

```json
"icon": {"type": "icon-pack", "reference": "<icon id from find_icon.py>"},
"iconColor": "#ffffff"
```

- `reference` is the icon's id inside its pack on **this** host. Ids are not portable: in a deck spec store the
  portable name too (`"icon": "mdi:skip-next"`) plus `iconRef`, and look the id up again with `find_icon.py` on
  another host (`restore-decks`).
- `iconColor` tints monochrome icons (MDI). Leave it unset for coloured packs.
- Style that worked: one dark `backgroundColor` for every button, white icons, colour only for meaning (red Record,
  green Next), labels kept short.
- Set either `icon` or `imageUrl`, not both: rebuild the button rather than adding `icon` next to an old `imageUrl`.
