"""Brine texture work done on the baked low-poly texture (numpy, headless Blender).

texel_maps()      position/normal of every texel of the baked UV layout (triangle rasteriser)
paint_back()      the AI mesh back is a smooth bag; the official art has a round spiral vent, two
                  eye plates, a toothy mouth and the chain. Project that part of the art back view
                  (ref/brine_back_*.png) onto the back-facing belly texels.
official_blue()   frost_lord colourway: per-region recolour of the red bake to the official blue/purple
                  figure (row 2 left of Brine chimera preview.png): blue body + legs, pink fists,
                  orange-pink crest, lilac chain, indigo shell, blue-violet mace.
"""
import bpy, os
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))


def rgb2hsv(rgb):
    mx = rgb.max(-1)
    d = mx - rgb.min(-1)
    s = np.where(mx > 1e-6, d / np.maximum(mx, 1e-6), 0.0)
    dd = np.maximum(d, 1e-6)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    h = np.where(mx == r, ((g - b) / dd) % 6, np.where(mx == g, (b - r) / dd + 2, (r - g) / dd + 4)) / 6.0
    return h % 1.0, s, mx


def hsv2rgb(h, s, v):
    h = h % 1.0
    i = np.floor(h * 6.0).astype(int) % 6
    f = h * 6.0 - np.floor(h * 6.0)
    p, q, u = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
    out = np.zeros(h.shape + (3,), dtype=np.float32)
    for k, (a, b, c) in enumerate([(v, u, p), (q, v, p), (p, v, u), (p, q, v), (u, p, v), (v, p, q)]):
        m = (i == k)
        out[..., 0] = np.where(m, a, out[..., 0])
        out[..., 1] = np.where(m, b, out[..., 1])
        out[..., 2] = np.where(m, c, out[..., 2])
    return out


def texel_maps(obj, W, H):
    """pos (H,W,3), nrm (H,W,3), valid (H,W). Row index = v*H (Blender image rows run bottom-up)."""
    me = obj.data
    me.calc_loop_triangles()
    uv = np.zeros(len(me.loops) * 2, dtype=np.float32)
    me.uv_layers[0].data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2) * np.array([W, H], dtype=np.float32)
    co = np.zeros(len(me.vertices) * 3, dtype=np.float32)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    nm = np.zeros(len(me.vertices) * 3, dtype=np.float32)
    me.vertices.foreach_get("normal", nm)
    nm = nm.reshape(-1, 3)
    pos = np.zeros((H, W, 3), np.float32)
    nrm = np.zeros((H, W, 3), np.float32)
    valid = np.zeros((H, W), bool)
    for t in me.loop_triangles:
        l = t.loops
        v = t.vertices
        a, b, c = uv[l[0]], uv[l[1]], uv[l[2]]
        x0, x1 = int(max(0, np.floor(min(a[0], b[0], c[0])))), int(min(W - 1, np.ceil(max(a[0], b[0], c[0]))))
        y0, y1 = int(max(0, np.floor(min(a[1], b[1], c[1])))), int(min(H - 1, np.ceil(max(a[1], b[1], c[1]))))
        if x1 < x0 or y1 < y0:
            continue
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(den) < 1e-9:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        w0 = ((b[1] - c[1]) * (xs - c[0]) + (c[0] - b[0]) * (ys - c[1])) / den
        w1 = ((c[1] - a[1]) * (xs - c[0]) + (a[0] - c[0]) * (ys - c[1])) / den
        w2 = 1 - w0 - w1
        m = (w0 >= -0.02) & (w1 >= -0.02) & (w2 >= -0.02)
        if not m.any():
            continue
        p = w0[..., None] * co[v[0]] + w1[..., None] * co[v[1]] + w2[..., None] * co[v[2]]
        n = w0[..., None] * nm[v[0]] + w1[..., None] * nm[v[1]] + w2[..., None] * nm[v[2]]
        sl = (slice(y0, y1 + 1), slice(x0, x1 + 1))
        pos[sl][m] = p[m]
        nrm[sl][m] = n[m]
        valid[sl] |= m
    for _ in range(8):   # bleed into the margin so filtering seams get a sensible position
        inv = ~valid
        if not inv.any():
            break
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            sp, sn, sv = np.roll(pos, (dy, dx), (0, 1)), np.roll(nrm, (dy, dx), (0, 1)), np.roll(valid, (dy, dx), (0, 1))
            take = inv & sv
            pos[take] = sp[take]
            nrm[take] = sn[take]
            valid = valid | take
            inv = ~valid
    return pos, nrm, valid


def load_rgb(path):
    img = bpy.data.images.load(path, check_existing=False)
    w, h = img.size
    a = np.zeros(w * h * 4, np.float32)
    img.pixels.foreach_get(a)
    a = a.reshape(h, w, 4)[::-1, :, :3]   # top row first
    bpy.data.images.remove(img)
    return a


def paint_back(px, pos, nrm, art_name, mesh_box, z_rng=(0.17, 0.67), x_half=0.52):
    """Project the art's back view onto the back-facing belly texels. mesh_box = (xmin, xmax, zmax) of the
    whole mesh (mace + chain included), matched to the art figure's silhouette box."""
    art = load_rgb(os.path.join(HERE, "ref", art_name))
    bg = np.abs(art - art[2, 2]).sum(-1) < 0.06
    ys, xs = np.where(~bg)
    ax0, ax1, ay0, ay1 = xs.min(), xs.max(), ys.min(), ys.max()
    xmin, xmax, zmax = mesh_box
    x, z = pos[..., 0], pos[..., 2]
    # back view: screen right = -x
    u = ax0 + (xmax - x) / (xmax - xmin) * (ax1 - ax0)
    vv = ay1 - z / zmax * (ay1 - ay0)
    ui = np.clip(u.astype(int), 0, art.shape[1] - 1)
    vi = np.clip(vv.astype(int), 0, art.shape[0] - 1)
    col = art[vi, ui]
    inside = (nrm[..., 1] > 0.45) & (z > z_rng[0]) & (z < z_rng[1]) & (np.abs(x) < x_half) & ~bg[vi, ui]
    fx = np.clip((x_half - np.abs(x)) / 0.07, 0, 1)
    fz = np.clip(np.minimum(z - z_rng[0], z_rng[1] - z) / 0.05, 0, 1)
    fn = np.clip((nrm[..., 1] - 0.45) / 0.25, 0, 1)
    w = (inside * fx * fz * fn)[..., None]
    res = px.copy()
    res[..., :3] = px[..., :3] * (1 - w) + col * w
    return res


def official_blue(px, pos):
    """Red bake -> official blue/purple colourway, region by region (see module doc)."""
    rgb = px[..., :3]
    h, s, v = rgb2hsv(rgb)
    x, z = np.abs(pos[..., 0]), pos[..., 2]
    ox = pos[..., 0]
    red = ((h > 0.94) | (h < 0.03)) & (s > 0.35)
    yel = (h >= 0.03) & (h < 0.20) & (s > 0.35)
    mag = (h >= 0.80) & (h <= 0.94) & (s > 0.25)
    cool = (h > 0.45) & (h < 0.80)
    h2, s2, v2 = h.copy(), s.copy(), v.copy()
    crest = yel & (z > 1.12)
    other_y = yel & ~crest
    fistw = np.clip((x - 0.50) / 0.10, 0, 1) * np.clip((z - 0.36) / 0.05, 0, 1) * np.clip((0.74 - z) / 0.06, 0, 1) * cool
    mace = (ox > 0.72) & (z < 0.62)
    dmace = np.sqrt((ox - 0.96) ** 2 + (pos[..., 1] + 0.07) ** 2 + (z - 0.25) ** 2)
    fistw = fistw * np.clip((dmace - 0.27) / 0.05, 0, 1)
    # legs / skin / shoulder armour: red -> blue
    h2 = np.where(red, 0.60 + 0.03 * np.clip((z - 0.2) / 0.9, 0, 1), h2)
    s2 = np.where(red, np.minimum(1.0, s * 0.85 + 0.05), s2)
    v2 = np.where(red, np.minimum(1.0, 0.55 + v * 0.5), v2)
    # crest: yellow -> orange-pink gradient
    t = np.clip((z - 1.12) / 0.35, 0, 1)
    h2 = np.where(crest, 0.07 - 0.14 * t, h2)
    s2 = np.where(crest, 0.55 + 0.1 * t, s2)
    v2 = np.where(crest, 1.0, v2)
    # chain, mace ring, other gold: lilac
    h2 = np.where(other_y, 0.74, h2)
    s2 = np.where(other_y, 0.38, s2)
    v2 = np.where(other_y, np.minimum(1.0, 0.60 + v * 0.45), v2)
    # magenta bits stay pink
    h2 = np.where(mag, 0.89, h2)
    # shell, plates and spikes: slate/purple -> saturated indigo-blue
    h2 = np.where(cool, 0.66, h2)
    s2 = np.where(cool, np.minimum(1.0, 0.45 + s * 1.6), s2)
    v2 = np.where(cool, np.clip(v * 1.05 + 0.02, 0, 1), v2)
    # mace: periwinkle, fluffy-looking pale blue
    h2 = np.where(mace & cool, 0.63, h2)
    s2 = np.where(mace & cool, 0.48, s2)
    v2 = np.where(mace & cool, 0.88, v2)
    out = hsv2rgb(h2, s2, v2)
    pink = hsv2rgb(np.full_like(h, 0.90), np.full_like(h, 0.42), np.full_like(h, 0.97))   # fists: pink, soft edge
    out = out * (1 - fistw[..., None]) + pink * fistw[..., None]
    res = px.copy()
    res[..., :3] = out
    return res
