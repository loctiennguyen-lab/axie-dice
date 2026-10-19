"""Brine (Aqua) Chimera: AI mesh -> straighten -> weighted decimate -> bake -> rig -> 6 clips -> 2 GLBs.

Headless and reproducible:
  Blender -b --factory-startup -P tools/art/chimera/build_brine.py -- \
      --src "<.../Brine (Aqua)/3D/brine_ai.glb>" --out godot/assets/bosses/chimera_brine
Options: --blend <file.blend> saves the rigged source; --cache <dir> reuses/creates the baked low-poly
(decimate+bake is the slow step); --ratio 0.024; --tex 2048.
Writes chimera_brine.glb (art colours, gooey_king) and chimera_brine_frost.glb (icy colourway,
frost_lord): same mesh, same rig, same clips, second texture.

Blender space: metres, Z up, Brine faces -Y, feet on z=0, body axis x=0. It stands (no hover).
The mace ball is a separate part of the AI mesh, so it gets its own free bone and swings in Attack.
"""
import bpy, os, sys, math
import numpy as np
from mathutils import Vector, Quaternion
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from brine_common import *

SRC = arg("src", "/Users/loc.tien.nguyen/my-game/asset-library/chimera-src/Brine (Aqua)/3D/brine_ai.glb")
OUT = arg("out", "/tmp/brine")
BLEND = arg("blend")
CACHE = arg("cache")
RATIO = float(arg("ratio", "0.024"))
TEX = int(arg("tex", "2048"))
FPS = 30

X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))
MACE_C = [Vector((0.96, -0.07, 0.25))]    # replaced by the measured ball centre in main()

BONES = [
    ("root",  (0, 0, 0),        (0, 0, 0.15),       None),
    ("hips",  (0, 0, 0.15),     (0, 0, 0.55),       "root"),
    ("chest", (0, 0, 0.55),     (0, -0.03, 0.95),   "hips"),
    ("head",  (0, -0.03, 0.92), (0, -0.06, 1.38),   "chest"),
    ("arm.L", (-0.42, 0.05, 0.80), (-0.68, -0.10, 0.42), "chest"),
    ("arm.R", (0.42, 0.05, 0.80),  (0.68, -0.10, 0.42),  "chest"),
]


def build_armature(ball):
    data = bpy.data.armatures.new("BrineRig")
    arm = bpy.data.objects.new("BrineRig", data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    eb = {}
    for n, h, t, p in BONES + [("mace", tuple(ball), tuple(ball + Vector((0, 0, 0.15))), "root")]:
        b = data.edit_bones.new(n)
        b.head, b.tail = Vector(h), Vector(t)
        b.roll = 0.0
        if p:
            b.parent = eb[p]
            b.use_connect = (Vector(eb[p].tail) - Vector(h)).length < 1e-4
        eb[n] = b
    bpy.ops.object.mode_set(mode='OBJECT')
    return arm


def seg_dist(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (p - (a + ab * t)).length


def mace_vertices(obj):
    """Indices of the connected component with the highest mean x (the ball), by flood fill."""
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.verts.ensure_lookup_table()
    seen = [False] * len(bm.verts)
    best = None
    for v in bm.verts:
        if seen[v.index]:
            continue
        st, comp = [v], []
        seen[v.index] = True
        while st:
            x = st.pop()
            comp.append(x.index)
            for e in x.link_edges:
                w = e.other_vert(x)
                if not seen[w.index]:
                    seen[w.index] = True
                    st.append(w)
        mx = sum(bm.verts[i].co.x for i in comp) / len(comp)
        if len(comp) > 200 and (best is None or mx > best[0]):
            best = (mx, comp)
    bm.free()
    return best[1]


def skin(obj, arm, mace_idx):
    segs = {n: (Vector(h), Vector(t)) for n, h, t, p in BONES}
    names = [n for n, _, _, _ in BONES]
    for n in names + ["mace"]:
        obj.vertex_groups.new(name=n)
    mset = set(mace_idx)
    obj.vertex_groups["mace"].add(mace_idx, 1.0, 'REPLACE')
    for v in obj.data.vertices:
        if v.index in mset:
            continue
        p = v.co
        wroot = max(0.0, min(1.0, (0.30 - p.z) / 0.13))
        ws = []
        for n in ("hips", "chest", "head", "arm.L", "arm.R"):
            if n == "head" and not (p.z > 0.78 and abs(p.x) < 0.46):
                continue
            if n == "arm.L" and not (p.x < -0.30 and 0.28 < p.z < 0.98):
                continue
            if n == "arm.R" and not (p.x > 0.30 and 0.28 < p.z < 0.98):
                continue
            a, b = segs[n]
            d = seg_dist(p, a, b)
            if n.startswith("arm") and d > 0.20:      # only the arm/hand itself, not the shell around it
                continue
            ws.append((1.0 / (d + 0.04) ** 4, n))
        ws.sort(reverse=True)
        ws = ws[:3]
        tot = sum(w for w, _ in ws)
        out = [("root", wroot)] if wroot > 0 else []
        for w, n in ws:
            out.append((n, (1.0 - wroot) * w / tot))
        for n, w in out:
            if w > 0.005:
                obj.vertex_groups[n].add([v.index], w, 'REPLACE')
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
    bpy.ops.object.vertex_group_smooth(group_select_mode='ALL', factor=0.5, repeat=2)
    bpy.ops.object.mode_set(mode='OBJECT')
    # smoothing must not leak the ball onto the body (the ball is rigid)
    vg = obj.vertex_groups
    bpy.ops.object.vertex_group_limit_total(group_select_mode='ALL', limit=4)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    bpy.ops.object.vertex_group_clean(group_select_mode='ALL', limit=0.01)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    obj.parent = arm
    mod = obj.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm


# ---------------------------------------------------------------------------------------------
# Animation. Rotations: (armature-space axis, degrees). Brine faces -Y: +X tips the top FORWARD.
# Arm bones point outward and down: Y rotation negative on the +X (R) side lifts the arm.
# ---------------------------------------------------------------------------------------------
def local_q(arm, bone, rots):
    B = arm.data.bones[bone].matrix_local.to_3x3()
    q = Quaternion()
    for axis, deg in rots:
        q = Quaternion(axis, math.radians(deg)) @ q
    return (B.inverted() @ q.to_matrix() @ B).to_quaternion()


def iter_fcurves(act):
    if hasattr(act, "fcurves") and len(getattr(act, "fcurves", [])):
        yield from act.fcurves
        return
    for layer in getattr(act, "layers", []):
        for strip in layer.strips:
            for bag in strip.channelbags:
                yield from bag.fcurves


ARM_SCALE = 0.6      # arms are short stubs on a big shell: keep their swing modest
ALL = ["root", "hips", "chest", "head", "arm.L", "arm.R", "mace"]


class Clip:
    def __init__(self, arm, name, frames):
        self.arm, self.name, self.frames = arm, name, frames
        self.keys = {}

    def pose(self, f, **bones):
        """bones: name (arm_L / arm_R for arm.L / arm.R) -> (rots, loc) | rots. Others rest."""
        for b in ALL:
            v = bones.get(b.replace(".", "_"))
            rots, loc = ([], None)
            if v is not None:
                rots, loc = v if (isinstance(v, tuple) and len(v) == 2 and (v[1] is None or isinstance(v[1], tuple))) else (v, None)
            if b.startswith("arm"):
                rots = [(ax, dg * ARM_SCALE) for ax, dg in rots]
            self.keys.setdefault(b, {})[f] = (list(rots), loc)

    def bake(self):
        arm = self.arm
        act = bpy.data.actions.new(self.name)
        act.use_fake_user = True
        arm.animation_data_create()
        arm.animation_data.action = act
        for pb in arm.pose.bones:
            pb.rotation_mode = 'QUATERNION'
        for bone, fr in self.keys.items():
            pb = arm.pose.bones[bone]
            for f in sorted(fr):
                rots, loc = fr[f]
                pb.rotation_quaternion = local_q(arm, bone, rots)
                if loc is not None:
                    B = arm.data.bones[bone].matrix_local.to_3x3()
                    pb.location = B.inverted() @ Vector(loc)
                else:
                    pb.location = Vector()
                pb.keyframe_insert("rotation_quaternion", frame=f)
                pb.keyframe_insert("location", frame=f)
        for fc in iter_fcurves(act):
            for kp in fc.keyframe_points:
                kp.interpolation = 'BEZIER'
                kp.easing = 'AUTO'
        act.frame_range = (0, self.frames)
        track = arm.animation_data.nla_tracks.new()
        track.name = self.name
        st = track.strips.new(self.name, 0, act)
        st.action_frame_end = self.frames
        arm.animation_data.action = None
        return act


def sn(i, n, amp, ph=0.0):
    return amp * math.sin(2 * math.pi * i / n + ph)


def R(deg):   # raise the +X (R) arm / lower: helper keeps the signs readable
    return deg


def make_idle(arm):
    n = 48
    c = Clip(arm, "Idle", n)
    for i in range(0, n + 1, 4):
        s = lambda a, ph=0.0: sn(i, n, a, ph)
        c.pose(i,
               hips=([(X, s(1.2, 0.5))], (0, 0, s(0.008, 0.2))),
               chest=([(X, s(2.2, 0.9)), (Y, s(1.2, 0.3))], None),
               head=([(X, s(-2.5, 1.2)), (Z, s(4, 0.3))], None),
               arm_L=([(Y, s(2.5, 0.6)), (X, s(2, 0.2))], None),
               arm_R=([(Y, -s(2.5, 0.6)), (X, s(2, 0.2))], None),
               mace=([(Z, s(2.5, 0.0))], None))
    return c.bake()


def make_attack(arm):
    # 1.3 s: lean back + mace up and behind (0-9), slam forward onto the floor (9-16),
    # contact bounce (16-21), drag back and recover (21-39)
    c = Clip(arm, "Attack", 39)
    c.pose(0)
    c.pose(9, hips=([(X, -4)], (0, 0.08, 0)), chest=([(X, -14)], None), head=([(X, -10)], None),
           arm_R=([(Y, -48), (X, 12)], None), arm_L=([(Y, 22)], None),
           mace=([(X, 100)], (0, 0.30, 0.60)))
    c.pose(13, hips=([(X, 3)], (0, -0.04, 0)), chest=([(X, 6)], None), head=([(X, 4)], None),
           arm_R=([(Y, -10), (X, -10)], None), arm_L=([(Y, 6)], None),
           mace=([(X, -10)], (0, -0.25, 0.50)))
    c.pose(16, hips=([(X, 8)], (0, -0.12, -0.02)), chest=([(X, 16)], None), head=([(X, 10)], None),
           arm_R=([(Y, 26), (X, -26)], None), arm_L=([(Y, -10)], None),
           mace=([(X, -110)], (0, -0.75, 0.0)))
    c.pose(20, hips=([(X, 6)], (0, -0.10, -0.01)), chest=([(X, 12)], None), head=([(X, 8)], None),
           arm_R=([(Y, 18), (X, -20)], None), arm_L=([(Y, -6)], None),
           mace=([(X, -140)], (0, -0.70, 0.07)))
    c.pose(28, hips=([(X, 2)], (0, -0.03, 0)), chest=([(X, 4)], None), head=([(X, 2)], None),
           arm_R=([(Y, 6), (X, -6)], None), mace=([(X, -70)], (0, -0.30, 0.0)))
    c.pose(39)
    return c.bake()


def make_hit(arm):
    c = Clip(arm, "Hit", 15)
    c.pose(0)
    c.pose(3, hips=([(X, -5)], (0, 0.12, 0)), chest=([(X, -10), (Y, 6)], None),
           head=([(X, -16), (Z, 14)], None), arm_R=([(Y, -16)], None), arm_L=([(Y, 16)], None),
           mace=([(X, 30)], (0, 0.15, 0.10)))
    c.pose(7, hips=([(X, -1)], (0, 0.04, 0)), chest=([(X, -3)], None), head=([(X, -5), (Z, 4)], None),
           mace=([(X, 8)], (0, 0.03, 0.0)))
    c.pose(11, head=([(X, 2)], None))
    c.pose(15)
    return c.bake()


def make_cast(arm):
    c = Clip(arm, "Cast", 42)
    c.pose(0)
    base = dict(chest=([(X, -8)], None), arm_R=([(Y, -58)], None), arm_L=([(Y, 58)], None))
    for f, tw in ((12, 0), (16, 1), (20, -1), (24, 1), (28, -1), (31, 0)):
        c.pose(f, hips=([(X, -2)], (0, 0, 0.02)), chest=([(X, -8), (Y, 2 * tw)], None),
               head=([(X, -16), (Z, 3 * tw)], None),
               arm_R=([(Y, -58 + 3 * tw)], None), arm_L=([(Y, 58 - 3 * tw)], None),
               mace=([(X, 40 + 6 * tw)], (0, 0, 0.28 + 0.02 * tw)))
    c.pose(36, chest=([(X, 4)], None), head=([(X, 6)], None), arm_R=([(Y, -10)], None),
           arm_L=([(Y, 10)], None), mace=([(X, 10)], (0, 0, 0.04)))
    c.pose(42)
    return c.bake()


def make_roar(arm):
    c = Clip(arm, "Roar", 48)
    c.pose(0)
    c.pose(8, hips=([(X, -3)], (0, 0.05, 0)), chest=([(X, -12)], None), head=([(X, -14)], None),
           arm_R=([(Y, -20)], None), arm_L=([(Y, 20)], None))
    for f, sh in ((14, 1), (17, -1), (20, 1), (23, -1), (26, 1), (29, -1), (32, 1), (36, 0)):
        c.pose(f, hips=([(X, 3)], (0, -0.05, 0)), chest=([(X, 8), (Y, 3 * sh)], None),
               head=([(X, 18), (Z, 5 * sh)], None),
               arm_R=([(Y, -34 + 4 * sh)], None), arm_L=([(Y, 34 - 4 * sh)], None),
               mace=([(X, 20 * sh)], (0, 0, 0.10 + 0.06 * sh)))
    c.pose(48)
    return c.bake()


def make_dead(arm):
    c = Clip(arm, "Dead", 54)
    c.pose(0)
    c.pose(6, hips=([(X, -4)], (0, 0.08, 0)), chest=([(X, -12)], None), head=([(X, -20), (Z, 10)], None),
           arm_R=([(Y, -20)], None), arm_L=([(Y, 20)], None), mace=([(X, 30)], (0, 0.15, 0.1)))
    c.pose(20, hips=([(X, 12)], (0, -0.10, -0.08)), chest=([(X, 22)], None), head=([(X, 28), (Z, -8)], None),
           arm_R=([(Y, 22)], None), arm_L=([(Y, -22)], None), mace=([(X, -40)], (0, -0.15, 0.0)))
    fin = dict(hips=([(X, 16)], (0, -0.14, -0.11)), chest=([(X, 30)], None), head=([(X, 36), (Z, -10)], None),
               arm_R=([(Y, 28)], None), arm_L=([(Y, -28)], None), mace=([(X, -60)], (0, -0.2, 0.0)))
    c.pose(32, **fin)
    c.pose(54, **fin)
    return c.bake()


# ---------------------------------------------------------------------------------------------
def frost_pixels(px):
    """Icy colourway of the baked texture (px: HxWx4 float). Warm hues (red/orange/yellow) go
    cyan-blue and brighter, magenta goes blue-violet, the purple-grey shell goes pale ice, whites
    and greys stay."""
    rgb = px[..., :3]
    mx = rgb.max(-1)
    mn = rgb.min(-1)
    d = mx - mn
    s = np.where(mx > 1e-6, d / np.maximum(mx, 1e-6), 0.0)
    dd = np.maximum(d, 1e-6)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    h = np.where(mx == r, ((g - b) / dd) % 6, np.where(mx == g, (b - r) / dd + 2, (r - g) / dd + 4)) / 6.0
    t = np.where(h > 0.88, h - 1.0, h)                       # warm band: -0.12 .. 0.2
    warm = (t > -0.12) & (t < 0.2)
    mag = (h >= 0.78) & (h <= 0.88)
    cool = (h > 0.45) & (h < 0.78)
    h2 = h.copy()
    s2 = s.copy()
    v2 = mx.copy()
    h2 = np.where(warm, 0.52 + (t + 0.12) / 0.32 * 0.07, h2)
    s2 = np.where(warm, s * 0.78, s2)
    v2 = np.where(warm, 0.5 + 0.5 * mx, v2)
    h2 = np.where(mag, 0.64, h2)
    s2 = np.where(mag, s * 0.7, s2)
    v2 = np.where(mag, 0.55 + 0.45 * mx, v2)
    h2 = np.where(cool, 0.60, h2)
    s2 = np.where(cool, np.minimum(1.0, s * 0.75 + 0.05), s2)
    v2 = np.where(cool, np.minimum(1.0, mx * 1.08 + 0.10), v2)
    i = np.floor(h2 * 6.0).astype(int) % 6
    f = h2 * 6.0 - np.floor(h2 * 6.0)
    p = v2 * (1 - s2)
    q = v2 * (1 - f * s2)
    u = v2 * (1 - (1 - f) * s2)
    out = np.zeros_like(rgb)
    for k, (a_, b_, c_) in enumerate([(v2, u, p), (q, v2, p), (p, v2, u), (p, q, v2), (u, p, v2), (v2, p, q)]):
        m = (i == k)
        out[..., 0] = np.where(m, a_, out[..., 0])
        out[..., 1] = np.where(m, b_, out[..., 1])
        out[..., 2] = np.where(m, c_, out[..., 2])
    res = px.copy()
    res[..., :3] = out
    return res


def export(path):
    bpy.ops.object.select_all(action='SELECT')
    kw = dict(filepath=path, export_format='GLB', use_selection=False, export_animations=True,
              export_animation_mode='NLA_TRACKS', export_skins=True, export_yup=True,
              export_apply=False, export_force_sampling=True, export_frame_step=1,
              export_def_bones=True, export_image_format='JPEG', export_jpeg_quality=88)
    props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
    bpy.ops.export_scene.gltf(**{k: v for k, v in kw.items() if k in props})
    print("BRINE: wrote", path, os.path.getsize(path))


def main():
    cache_blend = os.path.join(CACHE, "brine_low.blend") if CACHE else None
    if cache_blend and os.path.exists(cache_blend):
        bpy.ops.wm.open_mainfile(filepath=cache_blend)
        low = bpy.data.objects["Brine"]
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        low = prepare_mesh(SRC, RATIO, TEX, os.path.join(CACHE or "/tmp", "T_Brine_bake.png"))
        if cache_blend:
            os.makedirs(CACHE, exist_ok=True)
            bpy.data.images["T_Brine"].pack()
            bpy.ops.wm.save_as_mainfile(filepath=cache_blend, copy=True)
    sc = bpy.context.scene
    sc.render.fps = FPS
    mace_idx = mace_vertices(low)
    pts = [low.data.vertices[i].co for i in mace_idx]
    ball = Vector([(min(p[k] for p in pts) + max(p[k] for p in pts)) / 2 for k in range(3)])
    print("BRINE: mace verts", len(mace_idx), "ball centre", tuple(round(x, 3) for x in ball))
    arm = build_armature(ball)
    skin(low, arm, mace_idx)
    clips = [make_idle(arm), make_attack(arm), make_hit(arm), make_cast(arm), make_roar(arm), make_dead(arm)]
    if BLEND:
        os.makedirs(os.path.dirname(os.path.abspath(BLEND)), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=BLEND, compress=True, copy=True)
    print("BRINE: tris %d bones %d clips %s" % (tri_count(low), len(arm.data.bones), [a.name for a in clips]))
    os.makedirs(OUT, exist_ok=True)
    export(os.path.join(OUT, "chimera_brine.glb"))
    # frost colourway: same mesh/rig/clips, hue+value-shifted texture
    img = bpy.data.images["T_Brine"]
    W, H = img.size
    px = np.zeros(W * H * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    fr = frost_pixels(px.reshape(H, W, 4))
    img.pixels.foreach_set(fr.ravel())
    img.update()
    export(os.path.join(OUT, "chimera_brine_frost.glb"))


main()
