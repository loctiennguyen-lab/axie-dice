#!/usr/bin/env python3
"""Rasterise the geometry spine_pose_dump.js emitted, and batch the whole chimera folder.

DELIBERATELY DUMB. spine-ts already resolved bones, IK / transform / path constraints, the
animation stack, atlas rotation and trimming, and it hands over UVs in page space. So every
attachment here is just textured triangles sampled from the atlas page. Every place
tools/spine_to_sprites.py could be — and was — wrong is simply absent from this file.

Usage:
  spine_pose_render.py <chimeras-dir> <out-dir> [--runtime P] [--anim NAME] [--max-dim N]
                       [--only a,b,c]
"""
import argparse, json, math, os, pathlib, subprocess, sys
from PIL import Image, ImageDraw
import numpy as np

HERE = pathlib.Path(__file__).resolve().parent

# Origins rigs carry their loose particles as ordinary slots, so a STATIC sprite has to drop
# them or the creature ships with a frozen spark field around it. Same list
# tools/spine_to_sprites.py uses, plus the sleep glyph: `Z`/`Z2`/`Z3` is the zzz parked on
# dryad-ranger, which is art for a sleep state rather than part of the body.
_FX = ("fx", "vfx", "glow", "trail", "spark", "impact")


def is_effect_slot(name: str) -> bool:
    n = (name or "").lower()
    if n == "z" or (n.startswith("z") and n[1:].isdigit()):
        return True
    parts = n.split("-")
    return any(p in parts or n.startswith(p) or n.endswith(p) for p in _FX)


def draw_tri(canvas, src, src_tri, dst_tri):
    """One textured triangle, via an affine warp of the source page."""
    xs = [p[0] for p in dst_tri]
    ys = [p[1] for p in dst_tri]
    minx, maxx = int(math.floor(min(xs))), int(math.ceil(max(xs)))
    miny, maxy = int(math.floor(min(ys))), int(math.ceil(max(ys)))
    w, h = maxx - minx, maxy - miny
    if w <= 0 or h <= 0:
        return
    a_mat = np.array([[dst_tri[i][0], dst_tri[i][1], 1] for i in range(3)], dtype=float)
    try:
        inv = np.linalg.inv(a_mat)
    except np.linalg.LinAlgError:
        return                                  # degenerate triangle, nothing to draw
    cu = inv.dot(np.array([p[0] for p in src_tri], dtype=float))
    cv = inv.dot(np.array([p[1] for p in src_tri], dtype=float))
    a, b, c = cu
    d, e, f = cv
    # PIL's AFFINE maps OUTPUT -> INPUT, and the patch's origin is (minx, miny).
    c += a * minx + b * miny
    f += d * minx + e * miny
    patch = src.transform((w, h), Image.AFFINE, (a, b, c, d, e, f), resample=Image.BILINEAR)
    poly = Image.new("L", (w, h), 0)
    ImageDraw.Draw(poly).polygon([(x - minx, y - miny) for x, y in dst_tri], fill=255)
    # Mask by the triangle AND the source's own alpha, or the triangle's bounding wedge
    # paints the page's transparent padding as opaque black.
    mask = Image.composite(patch.split()[3], Image.new("L", (w, h), 0), poly)
    canvas.paste(patch, (minx, miny), mask)


def render(dump: dict, page_path: str, max_dim: int = 0) -> Image.Image:
    page = Image.open(page_path).convert("RGBA")
    pw, ph = page.size
    slots = [s for s in dump["slots"] if not is_effect_slot(s["slot"])]
    pts = []
    for s in slots:
        v = s["verts"]
        pts += [(v[i], v[i + 1]) for i in range(0, len(v), 2)]
    if not pts:
        raise ValueError("no drawable geometry")
    min_x, max_x = min(p[0] for p in pts), max(p[0] for p in pts)
    min_y, max_y = min(p[1] for p in pts), max(p[1] for p in pts)
    pad = 4
    cw = max(1, int(math.ceil(max_x - min_x)) + pad * 2)
    ch = max(1, int(math.ceil(max_y - min_y)) + pad * 2)
    canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))

    def to_c(x, y):
        return ((x - min_x) + pad, (max_y - y) + pad)   # Spine is Y-up, images are Y-down

    for s in slots:
        v, uv = s["verts"], s["uvs"]
        n = len(v) // 2
        tris = s.get("triangles") or [0, 1, 2, 2, 3, 0]   # a region is two triangles
        dst = [to_c(v[2 * i], v[2 * i + 1]) for i in range(n)]
        src = [(uv[2 * i] * pw, uv[2 * i + 1] * ph) for i in range(n)]
        for t in range(0, len(tris) - 2, 3):
            i0, i1, i2 = tris[t], tris[t + 1], tris[t + 2]
            if max(i0, i1, i2) >= n:
                continue
            draw_tri(canvas, page, [src[i0], src[i1], src[i2]], [dst[i0], dst[i1], dst[i2]])

    if max_dim and max(canvas.size) > max_dim:
        k = max_dim / max(canvas.size)
        canvas = canvas.resize((max(1, round(cw * k)), max(1, round(ch * k))), Image.LANCZOS)
    return canvas


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("chimeras_dir")
    ap.add_argument("out_dir")
    ap.add_argument("--runtime", default=str(HERE / "vendor" / "spine-core-3.8.js"))
    ap.add_argument("--anim", default="", help="animation to sample at t=0; '' = setup pose")
    ap.add_argument("--max-dim", type=int, default=512)
    ap.add_argument("--only", default="")
    args = ap.parse_args()

    src = pathlib.Path(args.chimeras_dir)
    out = pathlib.Path(args.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    wanted = {s.strip() for s in args.only.split(",") if s.strip()}
    dumper = str(HERE / "spine_pose_dump.js")

    ok = fail = 0
    for d in sorted(p for p in src.iterdir() if p.is_dir()):
        name = d.name
        if wanted and name not in wanted:
            continue
        if not (d / f"{name}.skel").exists() or not (d / f"{name}.png").exists():
            continue
        cmd = ["node", dumper, args.runtime, str(d), name]
        if args.anim:
            cmd.append(args.anim)
        try:
            proc = subprocess.run(cmd, capture_output=True, timeout=120)
            if proc.returncode != 0:
                raise RuntimeError(proc.stderr.decode()[:200])
            dump = json.loads(proc.stdout)
            img = render(dump, str(d / f"{name}.png"), args.max_dim)
            img.save(out / f"{name}.png")
            print(f"  OK    {name:24s} {img.size[0]:4d}x{img.size[1]:<4d} "
                  f"{len(dump['slots']):2d} slots, pose {dump['anim']}")
            ok += 1
        except Exception as exc:                              # noqa: BLE001
            print(f"  FAIL  {name:24s} {type(exc).__name__}: {exc}")
            fail += 1
    print(f"\n{ok} rendered, {fail} failed")
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
