"""Arena v2 (lane V) - ground colour map painter, shared by every biome.

numpy only: runs inside Blender (export.py) or plain python3 for a quick look:
    python3 -c "import ground, biomes; ground.preview('forest', '/tmp/f.png')"
Coordinates are GODOT world coordinates of the combat stage (x right, z toward the camera).
Stage geometry (gate, march line, flat area, field) comes from godot/assets/atia/arena_v2/stage_layout.json;
colours and optional layers from biomes.py (PALETTES). The ground UV is warped (piecewise linear) so most
texels land on what the combat camera sees:
  x [-26, 26] -> u [0.06, 0.94]     z [-28, 12] -> t [0.06, 0.96]  (t = 1 - v, image row from top)
`uv_of` / `world_of` are the single source of truth for that warp; kit.py uses them for the mesh UVs.
"""
import json
import os

import numpy as np

SIZE = 2048
UX = ([-46.0, -26.0, 26.0, 46.0], [0.0, 0.06, 0.94, 1.0])
TZ = ([-44.0, -28.0, 12.0, 18.0], [0.0, 0.06, 0.96, 1.0])
STAGE_PATH = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                          '../../../godot/assets/atia/arena_v2/stage_layout.json'))


def stage():
    with open(STAGE_PATH) as f:
        return json.load(f)


def unit_slots(st=None):
    """Every (x, z) a unit can stand on, from stage_layout.json 'formation' (lane C's CombatStage3D
    constants): party, eggs, 1-5 enemy patterns on both row sets, boss/elite and every add slot."""
    f = (st or stage())['formation']
    out = []
    for i in range(5):
        out.append((f['PARTY_X0'] + i * f['PARTY_PITCH_X'], f['PARTY_Z_FRONT'] if i % 2 == 0 else f['PARTY_Z_BACK']))
    for i in range(4):
        out.append((f['EGG_X0'] + i * f['EGG_PITCH_X'], f['EGG_Z']))
    for n, pat in f['ENEMY_PATTERNS'].items():
        for rows in (f['ENEMY_ROWS'], f['ENEMY_ROWS_TIGHT']):
            for col, row in pat:
                out.append((f['ENEMY_CENTER_X'] + col * f['ENEMY_PITCH_X'], rows[int(row) + 1]))
    for lead in (f['BOSS_POS'], f['ELITE_POS']):
        out.append(tuple(lead))
        for ent in [e for pat in f['ADD_PATTERNS'].values() for e in pat] + f['ADD_EXTRA']:
            col, row = ent
            z = f['ADD_Z_FRONT'] if row > 0 else (f['ADD_Z_BACK2'] if row < -1 else f['ADD_Z_BACK'])
            out.append((lead[0] + col * f['ADD_PITCH_X'], z))
    return sorted(set(out))


def uv_of(x, z):
    """World (x, z) -> (u, v) in Blender UV space (v up)."""
    u = np.interp(x, UX[0], UX[1])
    t = np.interp(z, TZ[0], TZ[1])
    return u, 1.0 - t


def world_of(u, t):
    return np.interp(u, UX[1], UX[0]), np.interp(t, TZ[1], TZ[0])


def srgb(h):
    h = h.lstrip('#')
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)], dtype=np.float32)


class Noise:
    """Value noise on a hashed lattice, smoothstep-interpolated. Deterministic (fixed seed)."""

    def __init__(self, seed, n=256):
        r = np.random.default_rng(seed)
        self.n = n
        self.t = r.random((n, n)).astype(np.float32)

    def __call__(self, x, y):
        n = self.n
        xi = np.floor(x).astype(np.int64)
        yi = np.floor(y).astype(np.int64)
        fx = x - xi
        fy = y - yi
        fx = fx * fx * (3 - 2 * fx)
        fy = fy * fy * (3 - 2 * fy)
        x0 = xi % n
        y0 = yi % n
        x1 = (x0 + 1) % n
        y1 = (y0 + 1) % n
        t = self.t
        a = t[y0, x0] + (t[y0, x1] - t[y0, x0]) * fx
        b = t[y1, x0] + (t[y1, x1] - t[y1, x0]) * fx
        return a + (b - a) * fy

    def fbm(self, x, y, octaves=4, lac=2.03, gain=0.5):
        s = np.zeros_like(x, dtype=np.float32)
        amp, f, tot = 1.0, 1.0, 0.0
        for o in range(octaves):
            s += amp * self(x * f + o * 17.3, y * f + o * 31.7)
            tot += amp
            amp *= gain
            f *= lac
        return s / tot


def smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def lerp(a, b, t):
    return a + (b - a) * t[..., None]


def voronoi(x, z, cell, seed):
    """F1, F2 distances and a per-cell random value, on a jittered grid of size `cell` metres."""
    r = np.random.default_rng(seed)
    jit = r.random((64, 64, 2)).astype(np.float32)
    val = r.random((64, 64)).astype(np.float32)
    gx = x / cell
    gz = z / cell
    ix = np.floor(gx).astype(np.int64)
    iz = np.floor(gz).astype(np.int64)
    f1 = np.full(x.shape, 9.0, np.float32)
    f2 = np.full(x.shape, 9.0, np.float32)
    cv = np.zeros(x.shape, np.float32)
    for dz in (-1, 0, 1):
        for dx in (-1, 0, 1):
            cx = ix + dx
            cz = iz + dz
            j = jit[cz % 64, cx % 64]
            px = cx + 0.15 + 0.7 * j[..., 0]
            pz = cz + 0.15 + 0.7 * j[..., 1]
            d = np.hypot(gx - px, gz - pz)
            closer = d < f1
            f2 = np.where(closer, f1, np.minimum(f2, d))
            cv = np.where(closer, val[cz % 64, cx % 64], cv)
            f1 = np.where(closer, d, f1)
    return f1 * cell, f2 * cell, cv


def paint(pal, size=SIZE, blobs=(), st=None):
    """`pal`: a biomes.PALETTES entry. `blobs`: (x, z, radius) contact-shadow pools under props
    (layout.blobs()). Returns an (size, size, 3) float32 sRGB image, row 0 = far back (t = 0)."""
    st = st or stage()
    GATE_X = float(st['gate_x'])
    LANE_Z = float(st['lane_z'])
    fx, fz = st['field']['x'], st['field']['z']
    seed = int(pal.get('seed', 0))

    def C(key):
        return np.broadcast_to(srgb(pal[key]), X.shape + (3,))

    t = (np.arange(size, dtype=np.float32) + 0.5) / size
    u = (np.arange(size, dtype=np.float32) + 0.5) / size
    U, Tt = np.meshgrid(u, t)
    X, Z = world_of(U, Tt)
    X = X.astype(np.float32)
    Z = Z.astype(np.float32)

    n1 = Noise(11 + seed)
    n2 = Noise(23 + seed)
    n3 = Noise(37 + seed)
    n4 = Noise(41 + seed)

    # Distance from the battle area (rounded rectangle) - 0 inside, metres outside.
    dx = np.maximum(np.maximum(fx[0] - X, X - fx[1]), 0)
    dz = np.maximum(np.maximum(fz[0] - Z, Z - fz[1]), 0)
    d_field = np.hypot(dx, dz)
    outer = smooth(0.0, 9.0, d_field)          # 0 in the field, 1 well outside

    # 1. base, broad soft mottling
    b = n1.fbm(X / 9.0, Z / 9.0, 4)
    col = lerp(C('light'), C('mid'), smooth(0.35, 0.72, b))

    # 2. darker stains, painterly (soft but defined edges)
    s = n2.fbm(X / 4.5, Z / 4.5, 4)
    st_mask = smooth(0.55, 0.62, s)
    col = lerp(col, C('stain'), st_mask * float(pal.get('stain_w', 0.55)))
    # smaller splotches between the big ones (Land-style mottling at unit scale)
    s2 = n4.fbm(X / 2.0 + 13.0, Z / 2.0 - 5.0, 3)
    col = lerp(col, C('stain'), smooth(0.64, 0.70, s2) * float(pal.get('stain2_w', 0.25)))
    # lighter sweeps (sun-bleached sand, wind-blown snow, ...)
    s3 = n1.fbm(X / 3.5 - 20.0, Z / 3.5 + 8.0, 3)
    col = lerp(col, C('bleach'), smooth(0.62, 0.70, s3) * float(pal.get('bleach_w', 0.6)))
    # fine dappling so close-ups are not flat
    f = n3.fbm(X / 0.9, Z / 0.9, 3)
    col *= (0.94 + 0.10 * f)[..., None]

    # 3. grass / moss / ice patches, mostly outside the field, a few soft ones inside
    g = n4.fbm(X / 6.0 + 3.1, Z / 6.0 - 1.7, 4)
    grass_w = 0.15 + 0.85 * outer
    gmask = smooth(0.60 - 0.12 * outer, 0.66 - 0.12 * outer, g) * grass_w
    gt = n3.fbm(X / 1.6 + 9.0, Z / 1.6, 3)
    gcol = lerp(C('grass_dark'), C('grass_light'), smooth(0.3, 0.7, gt))
    # rim: a slightly darker ring round each grass patch reads like the Land's turf edges
    rim = smooth(0.55 - 0.12 * outer, 0.60 - 0.12 * outer, g) * (1 - gmask) * grass_w
    col = lerp(col, C('grass_rim'), rim * 0.5)
    # wind-swept strokes inside the grass (anisotropic noise: long in x, thin in z)
    stroke = n2.fbm(X / 2.2 + 40.0, Z / 0.35, 2)
    gcol = gcol * (0.9 + 0.2 * smooth(0.35, 0.75, stroke))[..., None]
    col = lerp(col, gcol, gmask * float(pal.get('grass_w', 0.92)))

    # 4. the march line: a worn trail from the left edge to the gate (z = LANE_Z)
    wob = (n1.fbm(X / 5.0, np.full_like(X, 3.3), 3) - 0.5) * 1.1
    tz = np.abs(Z - (LANE_Z + wob))
    half_w = 1.25 + 0.25 * (n2(X / 2.0, np.full_like(X, 7.7)) - 0.5)
    trail = (1 - smooth(half_w - 0.35, half_w + 0.15, tz)) * (1 - smooth(GATE_X + 1.0, GATE_X + 2.5, X)) * smooth(float(st['trail_from_x']), float(st['trail_from_x']) + 10.0, X)
    tex = n3.fbm(X / 0.7, Z / 0.7, 3)
    col = lerp(col, C('dust') * (0.95 + 0.08 * tex)[..., None], trail * float(pal.get('dust_w', 0.85)))
    # two faint wheel/foot ruts along the trail
    rut = (np.exp(-((tz - 0.55) / 0.12) ** 2)) * trail * smooth(0.3, 0.6, n4.fbm(X / 1.3, Z / 1.3, 2))
    col = lerp(col, C('rut'), rut * 0.45)

    # 5. stone paving: last few metres of the trail + a round plaza under the gate
    plaza_r = np.hypot(X - GATE_X, Z - LANE_Z)
    pave_trail = (1 - smooth(1.15, 1.45, np.abs(Z - LANE_Z))) * smooth(float(st['pave_from_x']), float(st['pave_from_x']) + 2.8, X) * (1 - smooth(GATE_X, GATE_X + 0.5, X))
    pr = float(st['plaza_radius'])
    pave = np.maximum(pave_trail, 1 - smooth(pr - 0.15, pr + 0.15, plaza_r))
    # ragged edge: stones drop out near the border of the paved area
    f1, f2, cv = voronoi(X, Z, 0.62, 5)
    edge_noise = n2(X / 0.8, Z / 0.8)
    keep = pave > (0.1 + 0.3 * edge_noise + 0.55 * cv)
    stone = lerp(C('stone_a'), C('stone_b'), cv)
    # bevel: lighter towards the cell centre, grout dark
    bevel = smooth(0.0, 0.35, f2 - f1)
    stone = stone * (0.82 + 0.18 * bevel)[..., None]
    grout = 1 - smooth(0.05, 0.11, f2 - f1)
    stone = lerp(stone, C('grout'), grout)
    # soft dark halo round the paving so it sits in the ground
    halo = smooth(0.0, 0.6, pave) * (1 - keep)
    col = lerp(col, C('halo'), halo * 0.35)
    col = np.where(keep[..., None], stone, col)

    # 6. pebbles: tiny darker speckles outside the trail
    p1, p2, pv = voronoi(X, Z, 1.7, 9)
    peb = (1 - smooth(0.06, 0.10, p1)) * (pv > 0.72) * (1 - trail) * (1 - pave)
    col = lerp(col, C('peb'), peb * 0.8)
    pebhi = (1 - smooth(0.02, 0.05, np.hypot(p1, 0))) * (pv > 0.72) * (1 - trail) * (1 - pave)
    col = lerp(col, C('pebhi'), pebhi * 0.5)

    # 7. optional biome layers: dots (flowers, sparkles, ice glints) and craters (Luna)
    for k, (dcol, cell, dens, rad) in enumerate(pal.get('dots', [])):
        q1, _q2, qv = voronoi(X, Z, cell, 101 + k + seed)
        dot = (1 - smooth(rad * 0.6, rad, q1)) * (qv > 1.0 - dens) * (1 - trail) * (1 - pave)
        col = lerp(col, np.broadcast_to(srgb(dcol), X.shape + (3,)), dot * 0.9)
    if pal.get('craters'):
        c1, _c2, cvv = voronoi(X, Z, float(pal['craters'].get('cell', 6.0)), 131 + seed)
        rr = float(pal['craters'].get('radius', 1.6)) * (0.5 + cvv)
        has = (cvv > 0.45) * (1 - smooth(0.0, 0.5, trail)) * (1 - pave)
        bowl = (1 - smooth(rr * 0.75, rr * 0.95, c1)) * has
        lip = (smooth(rr * 0.8, rr * 0.95, c1) * (1 - smooth(rr * 0.95, rr * 1.2, c1))) * has
        col = lerp(col, C('crater'), bowl * 0.6)
        col = lerp(col, C('crater_lip'), lip * 0.7)

    # 8. contact-shadow pools under props
    for (bx, bz, br) in blobs:
        dd = np.hypot((X - bx) / br, (Z - bz) / (br * 0.8))
        col *= (1.0 - 0.28 * (1 - smooth(0.45, 1.0, dd)))[..., None]

    # 9. outer slopes drift toward the outer tint with distance; far edge darkens a little
    col = lerp(col, C('outer'), smooth(6.0, 18.0, d_field) * 0.2)
    col *= (1.0 - 0.12 * smooth(14.0, 30.0, d_field))[..., None]
    return np.clip(col, 0.0, 1.0).astype(np.float32)


def preview(biome, out, size=1024):
    """Quick look without Blender (no contact shadows): writes a PNG of the whole texture."""
    import biomes
    from PIL import Image
    a = paint(biomes.PALETTES[biome], size)
    Image.fromarray((a * 255 + 0.5).astype(np.uint8)).save(out)
