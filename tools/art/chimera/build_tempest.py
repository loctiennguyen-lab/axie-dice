"""Tempest (Bird) Chimera: AI mesh -> game mesh -> rig -> skin -> 6 clips -> GLB.

Headless and reproducible:
  Blender -b --factory-startup -P tools/art/chimera/build_tempest.py -- \
      --src "<.../Tempest (Bird)/3D/tempest_ai.glb>" --out godot/assets/bosses/chimera_tempest
Options: --blend <file.blend> saves the rigged source; --cache <dir> reuses/creates the baked
low-poly (the decimate+bake step is the slow part); --ratio 0.05 (decimate); --tex 2048.

Blender space: metres, Z up, the bird faces -Y, wings spread along X. The mesh is centred on
the origin (z -0.39 tail tip .. +0.39 head). The creature HOVERS: every clip keeps the root
bone `HOVER` metres above the rest pose, so the game slot (rest pose) stays on the floor.
Weights come from distance to bone segments with region gates (like venom_common), because the
wings and the head crest overlap in distance terms.
"""
import bpy, os, sys, math
from mathutils import Vector, Quaternion
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from tempest_common import *

SRC = arg("src", "/Users/loc.tien.nguyen/my-game/asset-library/chimera-src/Tempest (Bird)/3D/tempest_ai.glb")
OUT = arg("out", "/tmp/tempest")
BLEND = arg("blend")
CACHE = arg("cache")
RATIO = float(arg("ratio", "0.05"))
TEX = int(arg("tex", "2048"))
FPS = 30
HOVER = 0.22     # 28% of the 0.78 m body height; lives in the root bone of every clip

BONES = [
    ("root",      (0, 0, -0.39),      (0, 0, -0.30),       None),
    ("spine_low", (0, 0, -0.22),      (0, -0.01, -0.08),   "root"),
    ("chest",     (0, -0.01, -0.08),  (0, -0.02, 0.06),    "spine_low"),
    ("neck",      (0, -0.02, 0.06),   (0, -0.04, 0.14),    "chest"),
    ("head",      (0, -0.04, 0.14),   (0, -0.05, 0.40),    "neck"),
    ("wing1.L",   (0.09, 0.04, 0.05), (0.38, 0.05, 0.06),  "chest"),
    ("wing2.L",   (0.38, 0.05, 0.06), (0.66, 0.05, 0.04),  "wing1.L"),
    ("wing3.L",   (0.66, 0.05, 0.04), (0.97, 0.05, -0.01), "wing2.L"),
    ("hand.L",    (0.38, 0.03, 0.08), (0.52, 0.0, 0.22),   "wing1.L"),
    ("thigh.L",   (0.07, 0, -0.14),   (0.09, -0.03, -0.23), "spine_low"),
    ("foot.L",    (0.09, -0.03, -0.23), (0.13, -0.10, -0.31), "thigh.L"),
    ("tail1",     (0, 0.04, -0.20),   (0, 0.08, -0.30),    "spine_low"),
    ("tail2",     (0, 0.08, -0.30),   (0, 0.12, -0.39),    "tail1"),
]


def mirrored(bones):
    out = []
    for n, h, t, p in bones:
        out.append((n, h, t, p))
        if n.endswith(".L"):
            out.append((n[:-2] + ".R", (-h[0], h[1], h[2]), (-t[0], t[1], t[2]),
                        p[:-2] + ".R" if p and p.endswith(".L") else p))
    return out


BONES = mirrored(BONES)


def build_armature():
    data = bpy.data.armatures.new("TempestRig")
    arm = bpy.data.objects.new("TempestRig", data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    eb = {}
    for n, h, t, p in BONES:
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


def gate(n, p):
    ax = abs(p.x)
    base = n.split(".")[0]
    if n.endswith(".L") and p.x < 0.0 and base in ("wing1", "wing2", "wing3", "hand"):
        return False
    if n.endswith(".R") and p.x > 0.0 and base in ("wing1", "wing2", "wing3", "hand"):
        return False
    if n.endswith(".L") and p.x < -0.03:
        return False
    if n.endswith(".R") and p.x > 0.03:
        return False
    if base in ("wing1", "wing2", "wing3", "hand"):
        if ax < 0.07 or not (ax > 0.30 or p.z < 0.09):
            return False
        if base == "hand" and ax < 0.33:
            return False
    if base in ("thigh", "foot") and p.z > -0.10:
        return False
    if base in ("tail1", "tail2") and not (p.z < -0.17 and ax < 0.08):
        return False
    if base == "head" and ax > 0.32:
        return False
    if base in ("neck", "chest", "spine_low") and ax > 0.30:
        return False
    return True


def skin(obj, arm):
    segs = {n: (Vector(h), Vector(t)) for n, h, t, p in BONES}
    names = [n for n, _, _, _ in BONES if n != "root"]
    for n in names:
        obj.vertex_groups.new(name=n)
    me = obj.data
    for v in me.vertices:
        p = v.co
        if p.y > 0.07 and p.z > 0.08 and abs(p.x) < 0.25:      # quiver on the back
            obj.vertex_groups["chest"].add([v.index], 1.0, 'REPLACE')
            continue
        ws = []
        for n in names:
            if not gate(n, p):
                continue
            a, b = segs[n]
            ws.append((1.0 / (seg_dist(p, a, b) + 0.03) ** 4, n))
        ws.sort(reverse=True)
        ws = ws[:3]
        tot = sum(w for w, _ in ws)
        for w, n in ws:
            obj.vertex_groups[n].add([v.index], w / tot, 'REPLACE')
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
    bpy.ops.object.vertex_group_smooth(group_select_mode='ALL', factor=0.5, repeat=2)
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.vertex_group_limit_total(group_select_mode='ALL', limit=4)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    bpy.ops.object.vertex_group_clean(group_select_mode='ALL', limit=0.01)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    obj.parent = arm
    mod = obj.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm


# ---------------------------------------------------------------------------------------------
# Animation. Rotations are (armature-space axis, degrees), converted to each bone's local frame.
# Creature faces -Y: +X rotation tips the top FORWARD (and swings a hanging foot backward).
# Wing: Y rotation, negative on the +X (L) side lifts the tip.
# ---------------------------------------------------------------------------------------------
X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))


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


BODY = ["spine_low", "chest", "neck", "head", "tail1", "tail2"]
LIMBS = [b for b, _, _, _ in BONES if "." in b]


class Clip:
    def __init__(self, arm, name, frames, loop=False):
        self.arm, self.name, self.frames, self.loop = arm, name, frames, loop
        self.keys = {}

    def k(self, f, bone, rots=(), loc=None):
        self.keys.setdefault(bone, {})[f] = (list(rots), loc)

    def pose(self, f, d=None, hover=0.0, off=(0, 0), wings=None, legs=0.0, tail=0.0):
        """Keys every bone at frame f. d: bone -> rots (others zero). hover: root height
        above HOVER. off: root (x, y) offset. wings: dict(up, fold, sweep, hand). legs: thigh
        swing (neg = forward). tail: yaw sway."""
        d = d or {}
        for b in BODY:
            self.k(f, b, d.get(b, []))
        self.k(f, "root", d.get("root", []), (off[0], off[1], HOVER + hover))
        w = dict(up=0.0, fold=0.0, sweep=0.0, hand=0.0, lag=0.0)
        w.update(wings or {})
        for side, sg in (("L", 1), ("R", -1)):
            sw = d.get("sweep_" + side, w["sweep"])
            self.k(f, "wing1." + side, [(Y, -sg * w["up"]), (Z, sg * sw)])
            self.k(f, "wing2." + side, [(Y, -sg * (w["up"] * 0.6 + w["fold"] + w["lag"])), (Z, sg * sw * 0.5)])
            self.k(f, "wing3." + side, [(Y, -sg * (w["up"] * 0.5 + w["fold"] * 1.4 + w["lag"] * 2.0))])
            self.k(f, "hand." + side, [(Y, sg * (w["up"] * 0.8 + w["hand"])), (X, -w["hand"] * 0.6)])
            self.k(f, "thigh." + side, [(X, legs), (Y, sg * -4)])
            self.k(f, "foot." + side, [(X, legs * 0.5 - 6)])

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


def make_idle(arm):
    n = 40   # 1.33 s hover loop: one wing beat per cycle
    c = Clip(arm, "Idle", n, loop=True)
    for i in range(0, n + 1, 4):
        s = lambda a, ph=0.0: sn(i, n, a, ph)
        lagp = -0.5
        up = 6 + s(20)
        d = {"spine_low": [(X, s(2, 0.6))], "chest": [(X, s(2.5, 0.8))],
             "neck": [(X, s(-3, 1.0))], "head": [(X, s(3, 1.4)), (Z, s(3, 0.2))],
             "tail1": [(Z, s(8, 0.4)), (X, s(6, 0.5))], "tail2": [(Z, s(12, 1.0)), (X, s(8, 1.0))]}
        # body sinks on the up-stroke, rises on the down-stroke
        c.pose(i, d, hover=-s(0.03), off=(0, 0), wings=dict(up=up, fold=s(8, -0.9) , lag=0.0),
               legs=s(8, 1.8) + 6)
        # wing tips lag the root of the wing
        for side, sg in (("L", 1), ("R", -1)):
            c.k(i, "wing2." + side, [(Y, -sg * (up * 0.6 + s(10, lagp)))])
            c.k(i, "wing3." + side, [(Y, -sg * (up * 0.5 + s(16, lagp * 2)))])
    return c.bake()


def make_attack(arm):
    # 1.0 s: rear back (0-9), lunge + rake (9-15), hold (15-20), recover (20-30)
    c = Clip(arm, "Attack", 30)
    c.pose(0, wings=dict(up=6), legs=6)
    c.pose(9, {"spine_low": [(X, -10)], "chest": [(X, -10)], "neck": [(X, -8)], "head": [(X, -10)],
               "tail1": [(Z, 10)], "tail2": [(X, 10)]}, hover=0.07, off=(0, 0.12),
           wings=dict(up=48, fold=10, sweep=-6, hand=-10), legs=10)
    c.pose(14, {"spine_low": [(X, 16)], "chest": [(X, 16)], "neck": [(X, 14)], "head": [(X, 12)],
                "tail1": [(Z, -8), (X, -12)], "tail2": [(X, -18)]}, hover=-0.03, off=(0, -0.45),
           wings=dict(up=-30, fold=-8, sweep=18, hand=24), legs=-55)
    c.pose(19, {"spine_low": [(X, 12)], "chest": [(X, 12)], "neck": [(X, 10)], "head": [(X, 8)],
                "tail1": [(X, -8)], "tail2": [(X, -10)]}, hover=-0.01, off=(0, -0.38),
           wings=dict(up=-10, fold=-4, sweep=12, hand=14), legs=-40)
    c.pose(30, wings=dict(up=6), legs=6)
    return c.bake()


def make_hit(arm):
    c = Clip(arm, "Hit", 15)
    c.pose(0, wings=dict(up=6), legs=6)
    c.pose(3, {"spine_low": [(X, -12), (Y, 6)], "chest": [(X, -10), (Y, 8)], "neck": [(X, -14)],
               "head": [(X, -22), (Z, 16)], "tail1": [(Z, -14), (X, 14)], "tail2": [(Z, -18), (X, 20)]},
           hover=0.04, off=(0, 0.28), wings=dict(up=46, fold=6, sweep=-4, hand=10), legs=-24)
    c.pose(7, {"spine_low": [(X, -3)], "chest": [(X, -3)], "neck": [(X, -5)], "head": [(X, -6), (Z, 5)]},
           hover=-0.02, off=(0, 0.08), wings=dict(up=-8, fold=-6), legs=-6)
    c.pose(11, {"head": [(X, 2)]}, hover=0.01, off=(0, 0.02), wings=dict(up=12, fold=3), legs=4)
    c.pose(15, wings=dict(up=6), legs=6)
    return c.bake()


def make_cast(arm):
    # 1.2 s: rise, wings high, head up (0-12); hold with tremble (12-26); release (26-36)
    c = Clip(arm, "Cast", 36)
    c.pose(0, wings=dict(up=6), legs=6)
    base = {"spine_low": [(X, -6)], "chest": [(X, -6)], "neck": [(X, -10)], "head": [(X, -16)],
            "tail1": [(X, 10)], "tail2": [(X, 16)]}
    for f, tw in ((12, 0), (16, 1), (20, -1), (24, 1), (26, 0)):
        d = dict(base)
        d["head"] = [(X, -16), (Z, 3 * tw)]
        c.pose(f, d, hover=0.16 + 0.01 * tw, wings=dict(up=62 + 3 * tw, fold=8, hand=-8), legs=8)
    c.pose(30, {"chest": [(X, 4)], "head": [(X, 6)]}, hover=0.06, wings=dict(up=0, fold=-4), legs=0)
    c.pose(36, wings=dict(up=6), legs=6)
    return c.bake()


def make_roar(arm):
    # 1.6 s: head forward, wings flare wide, shake
    c = Clip(arm, "Roar", 48)
    c.pose(0, wings=dict(up=6), legs=6)
    c.pose(8, {"spine_low": [(X, -4)], "chest": [(X, -4)], "neck": [(X, 8)], "head": [(X, 12)]},
           hover=0.04, off=(0, 0.04), wings=dict(up=-6, fold=-4), legs=8)
    for f, sh in ((14, 1), (17, -1), (20, 1), (23, -1), (26, 1), (29, -1), (32, 1), (36, 0)):
        c.pose(f, {"spine_low": [(Y, 3 * sh)], "chest": [(X, 6), (Y, 4 * sh)], "neck": [(X, 14)],
                   "head": [(X, 20), (Z, 5 * sh)], "tail1": [(Z, 12 * sh)], "tail2": [(Z, 16 * sh)]},
               hover=0.10 + 0.012 * sh, off=(0.03 * sh, -0.10),
               wings=dict(up=14 + 6 * sh, fold=-2, sweep=10, hand=-6), legs=-10 + 4 * sh)
    c.pose(48, wings=dict(up=6), legs=6)
    return c.bake()


def make_dead(arm):
    # 1.8 s: last flap (0-6), wings fail and the body drops (6-24), lands and settles (24-40),
    # then holds. HOVER goes to ~0 so it ends on the floor.
    c = Clip(arm, "Dead", 54)
    c.pose(0, wings=dict(up=6), legs=6)
    c.pose(6, {"spine_low": [(X, -8)], "chest": [(X, -8)], "neck": [(X, -12)], "head": [(X, -18), (Z, 12)],
               "tail2": [(X, 16)]}, hover=0.06, off=(0, 0.10), wings=dict(up=38, fold=6), legs=-12)
    c.pose(16, {"spine_low": [(X, 10)], "chest": [(X, 12)], "neck": [(X, 14)], "head": [(X, 16), (Z, -8)],
                "tail1": [(X, -10)], "tail2": [(X, -16)]}, hover=-0.12, off=(0, 0.02),
           wings=dict(up=-22, fold=-10, lag=-3), legs=-14)
    fin = {"spine_low": [(X, 22)], "chest": [(X, 20)], "neck": [(X, 18)], "head": [(X, 24), (Z, -10)],
           "tail1": [(X, -14)], "tail2": [(X, -22)]}
    c.pose(26, fin, hover=-HOVER - 0.01, off=(0, -0.06), wings=dict(up=-8, fold=-8), legs=-20)
    c.pose(32, fin, hover=-HOVER + 0.02, off=(0, -0.06), wings=dict(up=-12, fold=-6), legs=-18)
    for f in (40, 54):
        c.pose(f, fin, hover=-HOVER, off=(0, -0.06), wings=dict(up=-16, fold=-8), legs=-20)
    return c.bake()


def main():
    cache_blend = os.path.join(CACHE, "tempest_low.blend") if CACHE else None
    if cache_blend and os.path.exists(cache_blend):
        bpy.ops.wm.open_mainfile(filepath=cache_blend)
        low = bpy.data.objects["Tempest"]
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        tex_tmp = os.path.join(CACHE or "/tmp", "T_Tempest_bake.png")
        low = prepare_mesh(SRC, RATIO, TEX, tex_tmp)
        if cache_blend:
            os.makedirs(CACHE, exist_ok=True)
            bpy.data.images["T_Tempest"].pack()
            bpy.ops.wm.save_as_mainfile(filepath=cache_blend, copy=True)
    sc = bpy.context.scene
    sc.render.fps = FPS
    arm = build_armature()
    skin(low, arm)
    clips = [make_idle(arm), make_attack(arm), make_hit(arm), make_cast(arm), make_roar(arm), make_dead(arm)]
    if BLEND:
        os.makedirs(os.path.dirname(os.path.abspath(BLEND)), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=BLEND, compress=True, copy=True)
    print("TEMPEST: tris %d bones %d clips %s" % (tri_count(low), len(arm.data.bones), [a.name for a in clips]))
    os.makedirs(OUT, exist_ok=True)
    glb = os.path.join(OUT, "chimera_tempest.glb")
    bpy.ops.object.select_all(action='SELECT')
    kw = dict(filepath=glb, export_format='GLB', use_selection=False, export_animations=True,
              export_animation_mode='NLA_TRACKS', export_skins=True, export_yup=True,
              export_apply=False, export_force_sampling=True, export_frame_step=1,
              export_def_bones=True, export_image_format='JPEG', export_jpeg_quality=90)
    props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
    kw = {k: v for k, v in kw.items() if k in props}
    bpy.ops.export_scene.gltf(**kw)
    print("TEMPEST: wrote", glb, os.path.getsize(glb))


main()
