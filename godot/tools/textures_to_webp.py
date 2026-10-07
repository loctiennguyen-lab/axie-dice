#!/usr/bin/env python3
"""Convert the Axie Mixer 3D texture pack from PNG to lossless WebP.

Why: the pack's textures ship as raw PNG (importer "keep", decoded at runtime with
Image.load_from_file) and make up ~63 MB of the ~225 MB web export. Lossless WebP is ~52% of
that size and decodes to exactly the same pixels, so nothing about the game's look changes.

What it does, per godot/addons/axie_mixer_3d_assets/textures/<id>.png:
  1. writes <id>.webp (lossless, exact=True so RGB under alpha 0 is kept),
  2. decodes it back and refuses to continue unless every RGBA byte matches the PNG,
  3. writes <id>.webp.import with importer="keep" (same as the PNG has), so the editor does
     not turn the .webp into a second, imported copy inside the export,
  4. points textures.json "file" at the .webp.
The PNGs stay on disk as the source of truth; export_presets.cfg excludes them from the pack.

Safe to re-run: files already converted are verified again and skipped.

    python3 godot/tools/textures_to_webp.py            # convert everything (all CPU cores)
    python3 godot/tools/textures_to_webp.py --limit 120  # stop after N new files (for short shells)
"""
import argparse
import io
import json
import os
import sys
import time
from multiprocessing import Pool

import numpy as np
from PIL import Image

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'addons', 'axie_mixer_3d_assets'))
TEX = os.path.join(ROOT, 'textures')
IMPORT_TEXT = '[remap]\n\nimporter="keep"\n'


def convert(name):
    png = os.path.join(TEX, name + '.png')
    webp = os.path.join(TEX, name + '.webp')
    src = Image.open(png)
    src.load()
    a = np.array(src.convert('RGBA'))
    if os.path.exists(webp):
        b = np.array(Image.open(webp).convert('RGBA'))
        if a.shape == b.shape and np.array_equal(a, b):
            return name, 'skipped', os.path.getsize(png), os.path.getsize(webp)
    buf = io.BytesIO()
    Image.fromarray(a, 'RGBA').save(buf, 'WEBP', lossless=True, quality=100, method=6, exact=True)
    data = buf.getvalue()
    b = np.array(Image.open(io.BytesIO(data)).convert('RGBA'))
    if a.shape != b.shape or not np.array_equal(a, b):
        return name, 'MISMATCH', os.path.getsize(png), len(data)
    tmp = webp + '.tmp'
    with open(tmp, 'wb') as f:
        f.write(data)
    os.replace(tmp, webp)
    imp = webp + '.import'
    if not os.path.exists(imp):
        with open(imp, 'w', newline='\n') as f:
            f.write(IMPORT_TEXT)
    return name, 'converted', os.path.getsize(png), len(data)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--limit', type=int, default=0, help='convert at most N new files, then stop')
    args = ap.parse_args()

    manifest_path = os.path.join(ROOT, 'textures.json')
    with open(manifest_path, encoding='utf8') as f:
        manifest = json.load(f)
    names = sorted(n[:-4] for n in os.listdir(TEX) if n.endswith('.png'))
    todo = [n for n in names if not os.path.exists(os.path.join(TEX, n + '.webp'))]
    if args.limit:
        todo = todo[: args.limit]
    skip = [n for n in names if os.path.exists(os.path.join(TEX, n + '.webp'))]
    t0 = time.time()
    bad = []
    tot_png = tot_webp = 0
    with Pool() as pool:
        for name, status, spng, swebp in pool.imap_unordered(convert, todo + skip, chunksize=4):
            tot_png += spng
            tot_webp += swebp
            if status == 'MISMATCH':
                bad.append(name)
    print(f'{len(names)} textures | {len(todo)} newly converted, {len(skip)} re-verified | {time.time() - t0:.0f}s')
    print(f'png {tot_png / 1e6:.1f} MB -> webp {tot_webp / 1e6:.1f} MB')
    if bad:
        print('PIXEL MISMATCH, manifest NOT changed:', bad[:10])
        return 1

    # Only repoint the manifest for textures that really have a verified .webp.
    changed = 0
    for tid, info in manifest.items():
        f = info.get('file', '')
        if f.endswith('.png') and os.path.exists(os.path.join(ROOT, f[:-4] + '.webp')):
            info['file'] = f[:-4] + '.webp'
            changed += 1
    if changed:
        with open(manifest_path, 'w', encoding='utf8', newline='\n') as fh:
            # Same compact layout the pack was exported with, so the git diff is only the paths.
            json.dump(manifest, fh, separators=(',', ':'), ensure_ascii=False)
    left = sum(1 for i in manifest.values() if i.get('file', '').endswith('.png'))
    print(f'textures.json: {changed} entries repointed to .webp, {left} still .png')
    return 0


if __name__ == '__main__':
    sys.exit(main())
