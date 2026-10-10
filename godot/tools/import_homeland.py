#!/usr/bin/env python3
"""Copy Homeland/Atia scenes from the Godot-ready asset library into the game, with everything they
depend on, and rewrite their paths so they resolve inside this project.

    python3 godot/tools/import_homeland.py scenes/HomeLand_Asset/Building_HomeLand/Portal/SM_Portal_01.tscn ...
    python3 godot/tools/import_homeland.py --list my_scenes.txt

Source: asset-library/godot-ready/ (see asset-library/README.md), a separate Godot project whose
res:// is its own root. Destination: godot/assets/homeland/, i.e. res://assets/homeland/<same path>.

Why a copier and not a symlink: the library holds ~1,950 FBX. Pointing the game at it would make
the editor import all of them and bloat every export. Copying only the closure of the scenes a
screen uses keeps the game small, and keeping the library's relative paths means a re-run is
idempotent and two scenes that share a texture share one copy.

What it follows: every `res://` reference in text resources (.tscn, .tres, .gdshader) and in each
FBX/texture's `.import` file (that is where the FBX -> material binding lives), plus `.import` and
`.uid` sidecars. It strips the `[remap]` destination lines from copied `.import` files so Godot
re-imports into this project's own `.godot/` instead of trusting the library's cache.
"""
import argparse
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT_ROOT = os.path.dirname(HERE)                       # .../my-game/godot
REPO_ROOT = os.path.dirname(GODOT_ROOT)
DEFAULT_SRC = os.path.join(REPO_ROOT, "asset-library", "godot-ready")
DEST_REL = "assets/homeland"                             # under res://
TEXT_EXT = {".tscn", ".tres", ".gdshader", ".gdshaderinc", ".import"}
REF_RE = re.compile(r'res://(?!\.godot/)([^"\'\s)\]]+)')
# Lines in a copied .import that point into the library's import cache.
REMAP_RE = re.compile(r'^(path(\.[a-z0-9_]+)?|dest_files)=.*$', re.M)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("paths", nargs="*", help="paths relative to the library root, e.g. scenes/...tscn")
    ap.add_argument("--list", help="file with one library-relative path per line (# comments ok)")
    ap.add_argument("--src", default=DEFAULT_SRC, help="library root (default: asset-library/godot-ready)")
    ap.add_argument("--dest", default=DEST_REL,
                    help="destination under res:// (default: assets/homeland; a prototype passes its own folder)")
    ap.add_argument("--dry-run", action="store_true", help="report what would be copied, copy nothing")
    args = ap.parse_args()

    src_root = os.path.realpath(args.src)
    if not os.path.isfile(os.path.join(src_root, "project.godot")):
        print(f"not a Godot-ready library: {src_root}", file=sys.stderr)
        return 2

    wanted = list(args.paths)
    if args.list:
        with open(args.list, encoding="utf-8") as fh:
            wanted += [l.strip() for l in fh if l.strip() and not l.lstrip().startswith("#")]
    if not wanted:
        ap.print_usage()
        return 2

    dest_rel = args.dest.strip("/").removeprefix("res://")
    dest_root = os.path.join(GODOT_ROOT, dest_rel)
    queue = [p.lstrip("/").removeprefix("res://") for p in wanted]
    seen: set[str] = set()
    missing: list[tuple[str, str]] = []   # (reference, referenced from)
    copied = 0
    total_bytes = 0
    origin: dict[str, str] = {}

    while queue:
        rel = os.path.normpath(queue.pop())
        if rel in seen:
            continue
        seen.add(rel)
        src = os.path.join(src_root, rel)
        if not os.path.isfile(src):
            missing.append((rel, origin.get(rel, "(command line)")))
            continue

        for side in (rel + ".import", rel + ".uid"):
            if os.path.isfile(os.path.join(src_root, side)) and side not in seen:
                origin.setdefault(side, rel)
                queue.append(side)

        ext = os.path.splitext(rel)[1].lower()
        dst = os.path.join(dest_root, rel)
        if ext in TEXT_EXT:
            with open(src, encoding="utf-8") as fh:
                text = fh.read()
            for ref in REF_RE.findall(text):
                ref = os.path.normpath(ref)
                if ref not in seen:
                    origin.setdefault(ref, rel)
                    queue.append(ref)
            text = REF_RE.sub(lambda m: f"res://{dest_rel}/{m.group(1)}", text)
            if ext == ".import":
                text = REMAP_RE.sub("", text)
            data = text.encode("utf-8")
            if not args.dry_run:
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                with open(dst, "wb") as fh:
                    fh.write(data)
            total_bytes += len(data)
        else:
            if not args.dry_run:
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copy2(src, dst)
            total_bytes += os.path.getsize(src)
        copied += 1

    verb = "would copy" if args.dry_run else "copied"
    print(f"{verb} {copied} files ({total_bytes / 1048576:.1f} MB) into res://{dest_rel}/")
    if missing:
        print(f"{len(missing)} references not found in the library (left as-is):")
        for ref, frm in sorted(missing)[:40]:
            print(f"  {ref}   <- {frm}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
