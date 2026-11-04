"""Measure art pieces against the game-art-reskin-design thresholds.

usage: python measure.py <png> [<png> ...]   -> prints one JSON line per file
Tight crop on alpha, longest side 256, then:
  black  = % of solid pixels with V < 0.2
  minV   = min V over solid pixels (also p1 for robustness)
  cov    = solid pixels / crop area
  grain  = mean |img - gaussian(1px)| over RGB, inside the shape eroded 2px (0-255 scale)
  colors = distinct 16-level RGB bins among solid pixels
"""
import json, sys
import numpy as np
from PIL import Image, ImageFilter

SOLID = 200


def erode(m, n):
    m = m.copy()
    for _ in range(n):
        e = m.copy()
        e[1:, :] &= m[:-1, :]; e[:-1, :] &= m[1:, :]
        e[:, 1:] &= m[:, :-1]; e[:, :-1] &= m[:, 1:]
        m = e
    return m


def measure(path):
    im = Image.open(path)
    info = {"file": path.split("/")[-1], "mode": im.mode, "size": list(im.size),
            "icc": "icc_profile" in im.info, "gamma": im.info.get("gamma")}
    im = im.convert("RGBA")
    a = np.asarray(im)[:, :, 3]
    ys, xs = np.nonzero(a > 8)
    if len(xs) == 0:
        info["empty"] = True
        return info
    im = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    w, h = im.size
    s = 256 / max(w, h)
    im = im.resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)
    arr = np.asarray(im).astype(np.float32)
    rgb, al = arr[:, :, :3], arr[:, :, 3]
    solid = al >= SOLID
    v = rgb.max(axis=2) / 255.0
    vs = v[solid]
    blur = np.asarray(im.convert("RGB").filter(ImageFilter.GaussianBlur(1))).astype(np.float32)
    inner = erode(solid, 2)
    grain = float(np.abs(rgb - blur)[inner].mean()) if inner.any() else None
    bins = (rgb[solid].astype(np.int32) // 16)
    colors = len(np.unique(bins[:, 0] * 256 + bins[:, 1] * 16 + bins[:, 2]))
    info.update({
        "cov": round(float(solid.mean()), 3),
        "black": round(float((vs < 0.2).mean() * 100), 2),
        "minV": round(float(vs.min()), 3),
        "p1V": round(float(np.percentile(vs, 1)), 3),
        "grain": round(grain, 2) if grain is not None else None,
        "colors": colors,
    })
    p = {"black": info["black"] <= 1, "minV": info["minV"] >= 0.20,
         "cov": 0.37 <= info["cov"] <= 0.83,
         "grain": grain is not None and 1.1 <= grain <= 2.8,
         "colors": 16 <= colors <= 160}
    info["fail"] = [k for k, ok in p.items() if not ok]
    return info


if __name__ == "__main__":
    for f in sys.argv[1:]:
        print(json.dumps(measure(f)))
