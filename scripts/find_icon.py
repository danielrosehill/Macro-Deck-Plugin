#!/usr/bin/env python3
"""Find icons in the Macro Deck icon packs installed on this host (read-only).

Usage: find_icon.py [--pack NAME] [--exact] TERM [TERM ...]
       find_icon.py --packs            list installed packs
Prints JSON: one object per match {pack, packId, name, reference, tags}. `reference` is what a widget's
data.icon = {"type": "icon-pack", "reference": <reference>} expects (the icon id inside its pack).
Data folder: $XDG_DATA_HOME/MacroDeck (default ~/.local/share/MacroDeck) on Linux.
"""
import json, os, sys, pathlib

root = pathlib.Path(os.environ.get("XDG_DATA_HOME", pathlib.Path.home() / ".local/share")) / "MacroDeck/data/icons/packs"
args = sys.argv[1:]
packs = []
for pj in sorted(root.glob("*/pack.json")):
    p = json.loads(pj.read_text())
    packs.append(p)
if not args or args == ["--packs"]:
    print(json.dumps([{"packId": p["id"], "name": p.get("name"), "author": p.get("author"), "source": p.get("sourceId"),
                       "icons": len(p.get("icons") or [])} for p in packs], indent=2))
    sys.exit(0)
pack_filter, exact, terms = None, False, []
i = 0
while i < len(args):
    if args[i] == "--pack": pack_filter = args[i + 1].lower(); i += 2; continue
    if args[i] == "--exact": exact = True; i += 1; continue
    terms.append(args[i].lower()); i += 1
out = []
for p in packs:
    if pack_filter and pack_filter not in (p.get("name") or "").lower(): continue
    for ic in p.get("icons") or []:
        name = (ic.get("name") or "").lower(); tags = [t.lower() for t in (ic.get("tags") or [])]
        hit = any(name == t for t in terms) if exact else any(t in name or t in tags for t in terms)
        if hit:
            out.append({"pack": p.get("name"), "packId": p["id"], "name": ic.get("name"), "reference": ic["id"], "tags": ic.get("tags")})
print(json.dumps(out[:200], indent=2))
