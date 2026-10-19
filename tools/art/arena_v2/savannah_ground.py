"""Savannah arena v2 - ground colour map (lane V, 10/2026).

Paints the 2048x2048 ground texture for the Savannah battle diorama with numpy only, so it can run
inside Blender (exec this file) or standalone (python3 + numpy, writes a .npy you can convert).

Coordinates are GODOT world coordinates of the combat stage: x to the right, z toward the camera.
The ground UV is warped (piecewise linear) so most texels land on the part the combat camera sees:
  x [-26, 26] -> u [0.06, 0.94]     z [-28, 12] -> t [0.06, 0.96]  (t = 1 - v, image row from top)
Everything outside is squeezed into the thin border. `uv_of(x, z)` / `world_of(u, t)` are the
single source of truth for that warp; build_savannah.py uses the same functions for the mesh UVs.

Layout facts it paints around (CombatStage3D.gd, 19/10): party x -10..-4.8 at z 3.6 / -1.4,
eggs z 6.9, enemies x ~0..4 at z -4.9 / 1.1 / 6.4, boss adds down to z -10.2, gate (portal) at
x 6.7 on the march line z 1.1 (arena node at z = LANE_Z 1.1, rotated -90 deg).
"""
import numpy as np

SIZE = 2048
UX = ([-46.0, -26.0, 26.0, 46.0], [0.0, 0.06, 0.94, 1.0])
TZ = ([-44.0, -28.0, 12.0, 18.0], [0.0, 0.06, 0.96, 1.0])
LANE_Z = 1.1
GATE_X = 6.7


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


def paint(size=SIZE, blobs=()):
    """`blobs`: (x, z, radius) contact-shadow pools painted under props (from build_savannah.LAYOUT).
    Returns an (size, size, 3) float32 sRGB image, row 0 = far back (t = 0)."""
    t = (np.arange(size, dtype=np.float32) + 0.5) / size
    u = (np.arange(size, dtype=np.float32) + 0.5) / size
    U, Tt = np.meshgrid(u, t)
    X, Z = world_of(U, Tt)
    X = X.astype(np.float32)
    Z = Z.astype(np.float32)

    n1 = Noise(11)
    n2 = Noise(23)
    n3 = Noise(37)
    n4 = Noise(41)

    # Distance from the battle area (rounded rectangle) - 0 inside, metres outside.
    dx = np.maximum(np.maximum(-12.5 - X, X - 9.5), 0)
    dz = np.maximum(np.maximum(-9.0 - Z, Z - 9.0), 0)
    d_field = np.hypot(dx, dz)
    outer = smooth(0.0, 9.0, d_field)          # 0 in the field, 1 well outside

    # 1. base sand-gold, broad soft mottling (Land hub savannah: FAD27C / F2B652 / DE9A3C)
    light, mid, stain = srgb('C9B052'), srgb('B68A36'), srgb('8C4E1C')
    b = n1.fbm(X / 9.0, Z / 9.0, 4)
    col = lerp(np.broadcast_to(light, X.shape + (3,)), np.broadcast_to(mid, X.shape + (3,)), smooth(0.35, 0.72, b))

    # 2. darker orange stains, painterly (soft but defined edges), fewer in the field
    s = n2.fbm(X / 4.5, Z / 4.5, 4)
    st_mask = smooth(0.55, 0.62, s)
    col = lerp(col, np.broadcast_to(stain, X.shape + (3,)), st_mask * 0.7)
    # smaller splotches between the big ones (Land-style mottling at unit scale)
    s2 = n4.fbm(X / 2.0 + 13.0, Z / 2.0 - 5.0, 3)
    col = lerp(col, np.broadcast_to(stain, X.shape + (3,)), smooth(0.64, 0.70, s2) * 0.35)
    # lighter sun-bleached sweeps
    s3 = n1.fbm(X / 3.5 - 20.0, Z / 3.5 + 8.0, 3)
    col = lerp(col, np.broadcast_to(srgb('D6BE62'), X.shape + (3,)), smooth(0.62, 0.70, s3) * 0.6)
    # fine dappling so close-ups are not flat
    f = n3.fbm(X / 0.9, Z / 0.9, 3)
    col *= (0.94 + 0.10 * f)[..., None]

    # 3. dry grass patches (olive gold), mostly outside the field, a few soft ones inside
    g = n4.fbm(X / 6.0 + 3.1, Z / 6.0 - 1.7, 4)
    grass_w = 0.15 + 0.85 * outer
    gmask = smooth(0.60 - 0.12 * outer, 0.66 - 0.12 * outer, g) * grass_w
    g_dark, g_light = srgb('9C8C3C'), srgb('B3A04C')
    gt = n3.fbm(X / 1.6 + 9.0, Z / 1.6, 3)
    gcol = lerp(np.broadcast_to(g_dark, X.shape + (3,)), np.broadcast_to(g_light, X.shape + (3,)), smooth(0.3, 0.7, gt))
    # rim: a slightly darker ring round each grass patch reads like the Land's turf edges
    rim = smooth(0.55 - 0.12 * outer, 0.60 - 0.12 * outer, g) * (1 - gmask) * grass_w
    col = lerp(col, np.broadcast_to(srgb('A0742C'), X.shape + (3,)), rim * 0.5)
    # wind-swept strokes inside the grass (anisotropic noise: long in x, thin in z)
    stroke = n2.fbm(X / 2.2 + 40.0, Z / 0.35, 2)
    gcol = gcol * (0.9 + 0.2 * smooth(0.35, 0.75, stroke))[..., None]
    col = lerp(col, gcol, gmask * 0.92)

    # 4. the march line: a worn dusty trail from the left edge to the gate (z = LANE_Z)
    wob = (n1.fbm(X / 5.0, np.full_like(X, 3.3), 3) - 0.5) * 1.1
    tz = np.abs(Z - (LANE_Z + wob))
    half_w = 1.25 + 0.25 * (n2(X / 2.0, np.full_like(X, 7.7)) - 0.5)
    trail = (1 - smooth(half_w - 0.35, half_w + 0.15, tz)) * (1 - smooth(GATE_X + 1.0, GATE_X + 2.5, X)) * smooth(-34.0, -24.0, X)
    dust = srgb('CDB476')
    tex = n3.fbm(X / 0.7, Z / 0.7, 3)
    col = lerp(col, np.broadcast_to(dust, X.shape + (3,)) * (0.95 + 0.08 * tex)[..., None], trail * 0.85)
    # two faint wheel/foot ruts along the trail
    rut = (np.exp(-((tz - 0.55) / 0.12) ** 2)) * trail * smooth(0.3, 0.6, n4.fbm(X / 1.3, Z / 1.3, 2))
    col = lerp(col, np.broadcast_to(srgb('A87A3A'), X.shape + (3,)), rut * 0.45)

    # 5. stone paving: last few metres of the trail + a round plaza under the gate
    plaza_r = np.hypot(X - GATE_X, Z - LANE_Z)
    pave_trail = (1 - smooth(1.15, 1.45, np.abs(Z - LANE_Z))) * smooth(GATE_X - 4.6, GATE_X - 1.8, X) * (1 - smooth(GATE_X, GATE_X + 0.5, X))
    pave = np.maximum(pave_trail, 1 - smooth(1.75, 2.05, plaza_r))
    # ragged edge: stones drop out near the border of the paved area
    f1, f2, cv = voronoi(X, Z, 0.62, 5)
    edge_noise = n2(X / 0.8, Z / 0.8)
    keep = pave > (0.1 + 0.3 * edge_noise + 0.55 * cv)
    stone_a, stone_b = srgb('ABA28A'), srgb('8C8670')
    stone = lerp(np.broadcast_to(stone_a, X.shape + (3,)), np.broadcast_to(stone_b, X.shape + (3,)), cv)
    # bevel: lighter towards the cell centre, grout dark
    bevel = smooth(0.0, 0.35, f2 - f1)
    stone = stone * (0.82 + 0.18 * bevel)[..., None]
    grout = 1 - smooth(0.05, 0.11, f2 - f1)
    stone = lerp(stone, np.broadcast_to(srgb('6C5634'), X.shape + (3,)), grout)
    # soft dark halo round the paving so it sits in the sand
    halo = smooth(0.0, 0.6, pave) * (1 - keep)
    col = lerp(col, np.broadcast_to(srgb('9E6A2C'), X.shape + (3,)), halo * 0.35)
    col = np.where(keep[..., None], stone, col)

    # 6. pebbles: tiny darker speckles outside the trail
    p1, p2, pv = voronoi(X, Z, 1.7, 9)
    peb = (1 - smooth(0.06, 0.10, p1)) * (pv > 0.72) * (1 - trail) * (1 - pave)
    col = lerp(col, np.broadcast_to(srgb('8C6434'), X.shape + (3,)), peb * 0.8)
    pebhi = (1 - smooth(0.02, 0.05, np.hypot(p1, 0))) * (pv > 0.72) * (1 - trail) * (1 - pave)
    col = lerp(col, np.broadcast_to(srgb('CDB27E'), X.shape + (3,)), pebhi * 0.5)

    # 7. contact-shadow pools under props
    for (bx, bz, br) in blobs:
        dd = np.hypot((X - bx) / br, (Z - bz) / (br * 0.8))
        col *= (1.0 - 0.28 * (1 - smooth(0.45, 1.0, dd)))[..., None]

    # 8. outer slopes turn more grassy/olive with distance; far edge darkens a little
    col = lerp(col, np.broadcast_to(srgb('A48C40'), X.shape + (3,)), smooth(6.0, 18.0, d_field) * 0.2)
    col *= (1.0 - 0.12 * smooth(14.0, 30.0, d_field))[..., None]
    return np.clip(col, 0.0, 1.0).astype(np.float32)


if __name__ == '__main__':
    import sys
    out = sys.argv[1] if len(sys.argv) > 1 else 'savannah_ground.npy'
    np.save(out, paint(int(sys.argv[2]) if len(sys.argv) > 2 else SIZE))
