#!/usr/bin/env python3
"""Turn a Spine clip into a sprite SHEET Godot can play with no runtime.

WHY A SHEET AND NOT A RUNTIME
-----------------------------
Godot 4.7 has no Spine runtime, and the kit is Spine 3.8 so spine-godot could not read it
even if it were added. But nothing says the animation has to be solved at play time: the
3.8 runtime solves it HERE, once, and the game just steps through frames. Exactly the
mechanism the Origins skill VFX in godot/assets/vfx already use.

FRAME BOX. One box per MONSTER, not per clip: the union of every frame of every clip it
exports, plus its resting pose. Sizing per frame would make the creature jitter as its own
bounding box breathed; sizing per CLIP would be worse still — the sprite would jump in
size and footing the instant it switched from resting to attacking, because an attack
reaches further than a stand. One box means every state is drawn at the same scale on the
same ground line, so swapping textures at runtime moves nothing that should not move.

The `base` sheet is the resting pose rendered in that same box. It replaces the monster's
plain PNG in godot/assets/monsters/, which is what keeps the resting sprite aligned with
the animated ones.

Usage:
  spine_sheet.py <chimeras-dir> <out-dir> --clips idle=action/idle/normal,attack=... [--fps 12]
                 [--cell 256] [--only a,b]
"""
import argparse, json, math, pathlib, subprocess, sys
from PIL import Image
import spine_pose_render as R

HERE = pathlib.Path(__file__).resolve().parent


def frame_bounds(frames):
    """Bounding box over a list of frames. Callers union these across clips."""
    xs, ys = [], []
    for slots in frames:
        for s in slots:
            if R.is_effect_slot(s["slot"]):
                continue
            v = s["verts"]
            xs += [v[i] for i in range(0, len(v), 2)]
            ys += [v[i] for i in range(1, len(v), 2)]
    if not xs:
        raise ValueError("clip has no drawable geometry")
    return min(xs), max(xs), min(ys), max(ys)


def build_sheet(dump, page_path, cell, box):
    page = Image.open(page_path).convert("RGBA")
    pw, ph = page.size
    frames = dump.get("frames") or [dump["slots"]]
    min_x, max_x, min_y, max_y = box
    src_w = max(1.0, max_x - min_x)
    src_h = max(1.0, max_y - min_y)
    k = min(cell / src_w, cell / src_h)          # one scale for both axes: no squashing
    fw = max(1, int(math.ceil(src_w * k)))
    fh = max(1, int(math.ceil(src_h * k)))

    n = len(frames)
    cols = min(n, max(1, int(math.ceil(math.sqrt(n)))))
    rows = int(math.ceil(n / cols))
    sheet = Image.new("RGBA", (cols * fw, rows * fh), (0, 0, 0, 0))

    for i, slots in enumerate(frames):
        cv = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
        for s in slots:
            if R.is_effect_slot(s["slot"]):
                continue
            v, uv = s["verts"], s["uvs"]
            m = len(v) // 2
            tris = s.get("triangles") or [0, 1, 2, 2, 3, 0]
            dst = [((v[2 * j] - min_x) * k, (max_y - v[2 * j + 1]) * k) for j in range(m)]
            src = [(uv[2 * j] * pw, uv[2 * j + 1] * ph) for j in range(m)]
            for t in range(0, len(tris) - 2, 3):
                a, b, c = tris[t], tris[t + 1], tris[t + 2]
                if max(a, b, c) >= m:
                    continue
                R.draw_tri(cv, page, [src[a], src[b], src[c]], [dst[a], dst[b], dst[c]])
        sheet.paste(cv, ((i % cols) * fw, (i // cols) * fh))

    return sheet, {"frames": n, "cols": cols, "rows": rows, "frame_w": fw, "frame_h": fh,
                   "fps": dump.get("fps", 0.0), "duration": round(dump.get("duration", 0.0), 4)}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("chimeras_dir")
    ap.add_argument("out_dir")
    ap.add_argument("--clips", required=True,
                    help="key=animation,key=animation — first match per key wins")
    ap.add_argument("--fps", type=float, default=12.0)
    ap.add_argument("--cell", type=int, default=256)
    ap.add_argument("--runtime", default=str(HERE / "vendor" / "spine-core-3.8.js"))
    ap.add_argument("--only", default="")
    ap.add_argument("--rest-clip", default="action/idle/normal",
                    help="the clip whose t=0 is the resting pose; '' uses the setup pose")
    ap.add_argument("--min-frames", type=int, default=4,
                    help="a clip shorter than this is treated as empty and the next "
                         "candidate is tried — several skeletons carry a placeholder "
                         "defense/hit-die of near-zero length while the real death is "
                         "under action/die")
    args = ap.parse_args()

    # key -> [candidate animation names], so a creature missing the usual clip can fall back
    # to its own variant instead of dropping the state entirely.
    clips = {}
    for pair in args.clips.split(","):
        if "=" not in pair:
            continue
        k, v = pair.split("=", 1)
        clips.setdefault(k.strip(), []).append(v.strip())

    src = pathlib.Path(args.chimeras_dir)
    out = pathlib.Path(args.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    wanted = {s.strip() for s in args.only.split(",") if s.strip()}
    dumper = str(HERE / "spine_pose_dump.js")
    manifest = {}

    for d in sorted(p for p in src.iterdir() if p.is_dir()):
        name = d.name
        if wanted and name not in wanted:
            continue
        if not (d / f"{name}.skel").exists() or not (d / f"{name}.png").exists():
            continue
        probe = subprocess.run(["node", dumper, args.runtime, str(d), name],
                               capture_output=True, timeout=180)
        if probe.returncode != 0:
            print(f"  FAIL  {name}: {probe.stderr.decode()[:120]}")
            continue
        durations = {a["name"]: a["duration"]
                     for a in json.loads(probe.stdout)["animations"]}
        entry = {}
        dumps = {}
        chosen_by_key = {}
        for key, candidates in clips.items():
            # Walk the candidates in order and take the first one that is actually animated.
            # A present-but-empty clip is worse than a missing one: it would ship as a
            # one-frame "animation" that reads as a freeze.
            chosen = ""
            for c in candidates:
                if c in durations and round(durations[c] * args.fps) >= args.min_frames:
                    chosen = c
                    break
            if not chosen:
                stubs = [f"{c}({durations[c]:.2f}s)" for c in candidates if c in durations]
                why = f"only stubs: {stubs}" if stubs else "none present"
                print(f"  skip  {name:22s} {key:8s} {why}")
                continue
            proc = subprocess.run(
                ["node", dumper, args.runtime, str(d), name, chosen, str(args.fps)],
                capture_output=True, timeout=300)
            if proc.returncode != 0:
                print(f"  FAIL  {name} {key}: {proc.stderr.decode()[:120]}")
                continue
            dumps[key] = json.loads(proc.stdout)
            chosen_by_key[key] = chosen

        # The resting pose, in the same box as everything else — see FRAME BOX.
        base = subprocess.run(
            ["node", dumper, args.runtime, str(d), name] +
            ([args.rest_clip] if args.rest_clip else []),
            capture_output=True, timeout=180)
        if base.returncode == 0:
            dumps["base"] = json.loads(base.stdout)

        if not dumps:
            continue
        boxes = [frame_bounds(dp.get("frames") or [dp["slots"]]) for dp in dumps.values()]
        box = (min(b[0] for b in boxes), max(b[1] for b in boxes),
               min(b[2] for b in boxes), max(b[3] for b in boxes))

        for key, dump in dumps.items():
            sheet, meta = build_sheet(dump, str(d / f"{name}.png"), args.cell, box)
            sheet.save(out / f"{name}_{key}.png")
            meta["clip"] = chosen_by_key.get(key, args.rest_clip or "(setup)")
            entry[key] = meta
            print(f"  OK    {name:22s} {key:8s} {meta['frames']:3d}f "
                  f"{sheet.size[0]:4d}x{sheet.size[1]:<4d} {meta['clip']}")
        if entry:
            manifest[name] = entry

    # MERGE, do not overwrite: the full set has to be run in batches to stay inside the
    # shell's time limit, and each batch would otherwise drop the ones before it.
    mpath = out / "monster_anim.json"
    merged = {}
    if mpath.exists():
        try:
            merged = json.loads(mpath.read_text()).get("clips", {})
        except (json.JSONDecodeError, OSError):
            merged = {}
    merged.update(manifest)
    mpath.write_text(json.dumps(
        {"_source": "axie-origins-asset-kit PvE/Chimeras, sampled with spine-ts 3.8",
         "clips": merged}, indent=1))
    print(f"\n{len(manifest)} this run, {len(merged)} total -> {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
