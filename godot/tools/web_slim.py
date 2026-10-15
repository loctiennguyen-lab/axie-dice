#!/usr/bin/env python3
"""Web-only texture slimming. Run on a STAGING COPY of godot/, never on the real project.

Usage:  python3 -I web_slim.py <path to staged godot/ dir> [--dry-run]
Refuses unless <dir>/.web_stage_marker exists and <dir> is not inside the real godot/ tree.
Normally called by godot/tools/export_web_slim.sh, which makes the copy, runs this, re-imports
and exports the Web preset. Desktop (macOS/Windows) exports are made from the untouched
godot/ tree and never see any of this.

What it does (all by editing the staged copy's .import files / text refs, no runtime code):
  1. Dedupe  - arena textures that are byte-identical to a Land texture (same params too) get their
               references rewritten to the Land copy; the arena png + .import are deleted.
  2. Lossy   - 2D textures imported lossless (compress/mode=0) under LOSSY_DIRS -> lossy WebP.
  3. Size cap- 3D VRAM textures (compress/mode=2) under CAP_DIRS bigger than CAP_PX after
               import -> process/size_limit=CAP_PX.
Every number is a knob below. Output: one summary line per step.
"""
import hashlib
import os
import re
import struct
import sys

# ---- knobs -------------------------------------------------------------------------------
LOSSY_DIRS = ["assets/vfx", "assets/backgrounds/origins", "assets/monsters/anim", "assets/bosses"]
LOSSY_QUALITY = 0.8          # Godot default is 0.7; 0.8 keeps soft alpha edges clean
CAP_DIRS = ["assets/land", "assets/atia"]
CAP_PX = 1024
DEDUPE_FROM = "assets/atia/arena/meshsrc"   # duplicates live here ...
DEDUPE_TO = "assets/land/homeland"          # ... canonical copies live here
TEXT_EXT = (".tres", ".tscn")               # files whose refs we may rewrite
# -------------------------------------------------------------------------------------------

DRY = "--dry-run" in sys.argv


def walk(root, ext):
    for dp, _, fs in os.walk(root):
        for f in fs:
            if f.endswith(ext):
                yield os.path.join(dp, f)


def read(p):
    with open(p, "r", encoding="utf-8") as f:
        return f.read()


def write(p, s):
    if not DRY:
        with open(p, "w", encoding="utf-8") as f:
            f.write(s)


def params_of(txt):
    """Normalised [params] block: the part that decides how pixels are processed."""
    return txt.split("[params]", 1)[1].strip() if "[params]" in txt else ""


def get(txt, key):
    m = re.search(r"^" + re.escape(key) + r"=(.*)$", txt, re.M)
    return m.group(1).strip() if m else None


def set_param(txt, key, val):
    if re.search(r"^" + re.escape(key) + r"=", txt, re.M):
        return re.sub(r"^" + re.escape(key) + r"=.*$", key + "=" + str(val), txt, flags=re.M)
    return txt.rstrip("\n") + "\n" + key + "=" + str(val) + "\n"


def img_dims(p):
    with open(p, "rb") as f:
        head = f.read(32)
    if head[:8] == b"\x89PNG\r\n\x1a\n":
        return struct.unpack(">II", head[16:24])
    try:
        from PIL import Image
        with Image.open(p) as im:
            return im.size
    except Exception:
        return None


def force_reimport(g, imp_txt):
    """Godot only re-imports when the SOURCE md5 changes, not when .import params change, so drop
    the cached output (.ctex, .s3tc.ctex, .etc2.ctex, .md5) and the next --import rebuilds it."""
    m = re.search(r'^path="res://\.godot/imported/(.*)\.ctex"$', imp_txt, re.M)
    if not m or DRY:
        return
    d = os.path.join(g, ".godot", "imported")
    for f in os.listdir(d) if os.path.isdir(d) else []:
        if f.startswith(m.group(1) + "."):
            os.remove(os.path.join(d, f))


def md5(p):
    with open(p, "rb") as f:
        return hashlib.md5(f.read()).hexdigest()


def source_of(imp):
    """Source texture path (absolute) for a .import file."""
    return imp[: -len(".import")]


def step_dedupe(g):
    src_root, dst_root = os.path.join(g, DEDUPE_FROM), os.path.join(g, DEDUPE_TO)
    canon = {}  # md5 -> import path of the canonical copy
    for imp in sorted(walk(dst_root, ".import")):
        s = source_of(imp)
        if s.endswith(".png") and os.path.exists(s):
            canon.setdefault(md5(s), imp)
    texts = [p for r in ("assets", "scenes", "resources") for p in walk(os.path.join(g, r), TEXT_EXT)]
    blobs = {p: read(p) for p in texts}
    other_refs = [p for r in ("assets", "scenes", "scripts", "autoload", "resources", "tests")
                  for p in walk(os.path.join(g, r), (".gd", ".json", ".cfg"))]
    other_blobs = {p: read(p) for p in other_refs}
    fbx_blobs = []  # FBX files embed texture file names; the baked scene then loads that png by path
    for p in walk(src_root, ".fbx"):
        with open(p, "rb") as f:
            fbx_blobs.append(f.read())
    n = saved = skipped = 0
    for imp in sorted(walk(src_root, ".import")):
        s = source_of(imp)
        if not s.endswith(".png") or not os.path.exists(s):
            continue
        h = md5(s)
        cimp = canon.get(h)
        if not cimp:
            continue
        itxt, ctxt = read(imp), read(cimp)
        if params_of(itxt) != params_of(ctxt):
            skipped += 1
            continue
        dup_res = "res://" + os.path.relpath(s, g)
        can_res = "res://" + os.path.relpath(source_of(cimp), g)
        stem = os.path.splitext(os.path.basename(s))[0].encode()
        if any(stem in b for b in fbx_blobs):
            skipped += 1  # an FBX in the arena tree embeds this texture: keep it
            continue
        if any(dup_res in b for b in other_blobs.values()):
            skipped += 1  # referenced from script/json by path: leave it alone
            continue
        dup_uid, can_uid = get(itxt, "uid"), get(ctxt, "uid")
        for p, b in blobs.items():
            if dup_res in b or (dup_uid and dup_uid.strip('"') in b):
                b = b.replace(dup_res, can_res)
                if dup_uid and can_uid:
                    b = b.replace(dup_uid.strip('"'), can_uid.strip('"'))
                blobs[p] = b
        saved += os.path.getsize(s)
        n += 1
        if not DRY:
            os.remove(s)
            os.remove(imp)
    for p, b in blobs.items():
        if b != read(p):
            write(p, b)
    print("dedupe: %d arena textures -> Land copy (%.1f MB source, %d kept: params differ or an FBX/script still uses them)"
          % (n, saved / 1e6, skipped))


def step_lossy(g):
    n = 0
    for d in LOSSY_DIRS:
        for imp in walk(os.path.join(g, d), ".import"):
            t = read(imp)
            if get(t, "importer") != '"texture"' or get(t, "compress/mode") != "0":
                continue
            t = set_param(t, "compress/mode", 1)
            t = set_param(t, "compress/lossy_quality", LOSSY_QUALITY)
            force_reimport(g, t)
            write(imp, t)
            n += 1
    print("lossy: %d 2D textures lossless -> lossy WebP q=%.2f" % (n, LOSSY_QUALITY))


def step_cap(g):
    n = 0
    for d in CAP_DIRS:
        for imp in walk(os.path.join(g, d), ".import"):
            t = read(imp)
            if get(t, "importer") != '"texture"' or get(t, "compress/mode") != "2":
                continue
            dims = img_dims(source_of(imp))
            if not dims:
                continue
            lim = int(get(t, "process/size_limit") or 0)
            eff = max(dims)
            if lim > 0:
                eff = min(eff, lim)
            if eff > CAP_PX:
                force_reimport(g, t)
                write(imp, set_param(t, "process/size_limit", CAP_PX))
                n += 1
                print("  cap %d -> %d  %s" % (eff, CAP_PX, os.path.relpath(source_of(imp), g)))
    print("cap: %d 3D textures limited to %d px" % (n, CAP_PX))


MARKER = ".web_stage_marker"  # written by export_web_slim.sh into the staged godot/ dir
REAL_GODOT = os.path.realpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))


def refuse_unless_stage(g):
    """Exit unless g is a staged godot/ copy made by export_web_slim.sh, never the real tree."""
    if not os.path.isfile(os.path.join(g, "project.godot")):
        sys.exit("refusing: %s has no project.godot" % g)
    if not os.path.isfile(os.path.join(g, MARKER)):
        sys.exit("refusing: %s has no %s (only export_web_slim.sh writes it)" % (g, MARKER))
    if os.path.commonpath([g, REAL_GODOT]) == REAL_GODOT:
        sys.exit("refusing: %s is inside the real godot/ tree %s" % (g, REAL_GODOT))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if len(args) != 1:
        sys.exit("usage: web_slim.py <staged godot dir> [--dry-run]")
    g = os.path.realpath(args[0])
    refuse_unless_stage(g)
    step_dedupe(g)
    step_lossy(g)
    step_cap(g)


main()
