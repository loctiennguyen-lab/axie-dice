"""Venom (Reptile) Chimera: import -> rig -> skin -> animate -> export GLB.

Headless and reproducible:
  Blender -b -P tools/art/chimera/build_venom.py -- --variant 01 --out godot/assets/bosses/chimera_venom
Optional: --blend <path.blend> saves the rigged source; --tex 1024 sets texture size.

The art team's 5 Reptile variants share one frame (same origin, same body envelope, parts
already placed), so one armature and one set of clips fits all of them. Weights are computed
from distance to bone segments per part (bone heat fails on these thin, open cloak shells).
"""
import bpy, os, sys, math, tempfile
import mathutils
from mathutils import Vector, Quaternion, Matrix
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from venom_common import *

V = arg("variant", "01")
OUT = arg("out", "/tmp/venom")
BLEND = arg("blend")
TEX = int(arg("tex", "1024"))
FPS = 30

# ---------------------------------------------------------------------------------------------
# Skeleton. Blender space: metres, Z up, the creature faces -Y. (name, head, tail, parent)
# ---------------------------------------------------------------------------------------------
BONES = [
    ("root",      (0, 0.10, 0.00),  (0, 0.10, 0.30),  None),
    ("spine_low", (0, 0.10, 0.30),  (0, 0.05, 0.75),  "root"),
    ("spine_mid", (0, 0.05, 0.75),  (0, 0.00, 1.10),  "spine_low"),
    ("chest",     (0, 0.00, 1.10),  (0, -0.02, 1.35), "spine_mid"),
    ("neck",      (0, -0.02, 1.35), (0, -0.08, 1.52), "chest"),
    ("head",      (0, -0.08, 1.52), (0, -0.30, 1.72), "neck"),
    # the dragon hood: rises from the upper back, arches over, ends in the mask
    ("hood_root", (0, 0.45, 1.20),  (0, 0.70, 1.85),  "chest"),
    ("hood_top",  (0, 0.70, 1.85),  (0, 0.35, 2.55),  "hood_root"),
    ("mask",      (0, 0.35, 2.55),  (0, -0.30, 2.30), "hood_top"),
    ("jaw",       (0, -0.10, 2.05), (0, -0.40, 1.80), "mask"),
    # crest wings at the top of the cloak
    ("wing1.L",   (0.35, 0.45, 2.15), (0.95, 0.45, 2.30), "hood_top"),
    ("wing2.L",   (0.95, 0.45, 2.30), (1.60, 0.45, 2.20), "wing1.L"),
    # sleeve panels
    ("sleeve1.L", (0.55, 0.20, 1.30), (0.90, 0.25, 0.65), "chest"),
    ("sleeve2.L", (0.90, 0.25, 0.65), (1.05, 0.25, -0.35), "sleeve1.L"),
    # back cape
    ("cape1",     (0, 0.80, 1.35),  (0, 1.05, 0.70),  "spine_mid"),
    ("cape2",     (0, 1.05, 0.70),  (0, 1.25, 0.00),  "cape1"),
    # tail along the ground
    ("tail1",     (0, 0.20, 0.10),  (0, 0.60, 0.08),  "root"),
    ("tail2",     (0, 0.60, 0.08),  (0, 1.00, 0.07),  "tail1"),
    ("tail3",     (0, 1.00, 0.07),  (0, 1.55, 0.06),  "tail2"),
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

# Which bones each part may be weighted to. Mask is rigid except the fang islands (jaw).
ALLOWED = {
    "Body": ["spine_low", "spine_mid", "chest", "neck", "head", "root", "tail1", "tail2"],
    "Coat": ["spine_mid", "chest", "hood_root", "hood_top", "mask", "wing1.L", "wing2.L",
             "wing1.R", "wing2.R", "sleeve1.L", "sleeve2.L", "sleeve1.R", "sleeve2.R",
             "cape1", "cape2", "spine_low"],
    "Mask": ["mask"],
    "Tail": ["tail2", "tail3"],
}


def build_armature():
    arm_data = bpy.data.armatures.new("VenomRig")
    arm = bpy.data.objects.new("VenomRig", arm_data)
    bpy.context.scene.collection.objects.link(arm)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    eb = {}
    for n, h, t, p in BONES:
        b = arm_data.edit_bones.new(n)
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


def islands(me):
    import bmesh
    bm = bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table()
    comp = [-1] * len(bm.verts); groups = []
    for v in bm.verts:
        if comp[v.index] >= 0:
            continue
        gid = len(groups); stack = [v]; comp[v.index] = gid; g = []
        while stack:
            x = stack.pop(); g.append(x.index)
            for e in x.link_edges:
                y = e.other_vert(x)
                if comp[y.index] < 0:
                    comp[y.index] = gid; stack.append(y)
        groups.append(g)
    bm.free()
    return groups


def skin(part, obj, arm):
    segs = {n: (Vector(h), Vector(t)) for n, h, t, p in BONES}
    allowed = ALLOWED[part]
    for n in allowed:
        obj.vertex_groups.new(name=n)
    me = obj.data
    rigid = {}   # vertex -> single bone (small islands move as one piece)
    if part == "Body":
        for g in islands(me):
            if len(g) < 60:
                zs = [me.vertices[i].co.z for i in g]
                if min(zs) > 1.35:
                    for i in g: rigid[i] = "head"
    if part == "Mask":
        for g in islands(me):
            if len(g) < 120:     # the two fang pieces under the mask
                for i in g: rigid[i] = "jaw"
        if "jaw" not in [vg.name for vg in obj.vertex_groups]:
            obj.vertex_groups.new(name="jaw")
    for v in me.vertices:
        if v.index in rigid:
            obj.vertex_groups[rigid[v.index]].add([v.index], 1.0, 'REPLACE')
            continue
        p = v.co
        ws = []
        for n in allowed:
            a, b = segs[n]
            d = seg_dist(p, a, b)
            # side bones never reach across the midline
            if n.endswith(".L") and p.x < 0.15: continue
            if n.endswith(".R") and p.x > -0.15: continue
            # cape only owns what hangs behind the body
            if n.startswith("cape") and p.y < 0.55: continue
            # sleeves own the lower side panels, wings the upper crest
            if n.startswith("sleeve") and p.z > 1.55: continue
            if n.startswith("wing") and p.z < 1.55: continue
            ws.append((1.0 / (d + 0.04) ** 4, n))
        ws.sort(reverse=True)
        ws = ws[:3]
        tot = sum(w for w, _ in ws)
        for w, n in ws:
            obj.vertex_groups[n].add([v.index], w / tot, 'REPLACE')
    # smooth seams, then renormalise and prune
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True); bpy.context.view_layer.objects.active = obj
    if part in ("Body", "Coat", "Tail"):
        bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
        bpy.ops.object.vertex_group_smooth(group_select_mode='ALL', factor=0.5, repeat=3)
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.vertex_group_limit_total(group_select_mode='ALL', limit=4)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    bpy.ops.object.vertex_group_clean(group_select_mode='ALL', limit=0.01)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    obj.parent = arm
    mod = obj.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm


# ---------------------------------------------------------------------------------------------
# Animation. Rotations are written as (axis in armature space, degrees) and converted into the
# bone's local frame, so "pitch forward" means the same thing on every bone.
# ---------------------------------------------------------------------------------------------
X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))
# Creature faces -Y: rotating about +X by a positive angle tips the top toward -Y (forward).


def local_q(arm, bone, rots):
    B = arm.data.bones[bone].matrix_local.to_3x3()
    q = Quaternion()
    for axis, deg in rots:
        q = Quaternion(axis, math.radians(deg)) @ q
    return (B.inverted() @ q.to_matrix() @ B).to_quaternion()


CHAIN_DAMP = {"spine_low": 0.6, "spine_mid": 0.6, "chest": 0.6, "neck": 0.8, "head": 0.9,
              "hood_root": 0.4, "hood_top": 0.4, "mask": 0.45, "sleeve1": 0.75, "sleeve2": 0.75,
              "cape1": 0.8, "cape2": 0.8}


class Clip:
    def __init__(self, arm, name, frames, loop=False):
        self.arm, self.name, self.frames, self.loop = arm, name, frames, loop
        self.keys = {}   # bone -> {frame: (rots, loc, scale)}

    def k(self, f, bone, rots=(), loc=None, scale=None):
        # Child bones inherit the parent's turn, so the long hood chain (spine -> chest ->
        # hood_root -> hood_top -> mask) multiplies every angle. Action clips are authored in
        # "how far this joint bends" terms and damped here per joint; Idle is authored final.
        m = 1.0 if self.name == "Idle" else CHAIN_DAMP.get(bone.split(".")[0], 1.0)
        self.keys.setdefault(bone, {})[f] = ([(a, d * m) for a, d in rots], loc, scale)

    def bake(self):
        arm = self.arm
        act = bpy.data.actions.new(self.name)
        act.use_fake_user = True
        arm.animation_data_create()
        arm.animation_data.action = act
        for pb in arm.pose.bones:
            pb.rotation_mode = 'QUATERNION'
        used = set(self.keys)
        for bone in [b.name for b in arm.pose.bones]:
            pb = arm.pose.bones[bone]
            fr = self.keys.get(bone, {0: ([], None, None)})
            if self.frames not in fr and bone in used:
                fr[self.frames] = fr[min(fr)] if self.loop else fr[max(fr)]
            for f in sorted(fr):
                rots, loc, sc = fr[f]
                pb.rotation_quaternion = local_q(arm, bone, rots)
                pb.location = Vector(loc) if loc else Vector()
                if loc:
                    # loc is given in armature space; convert to bone local
                    B = arm.data.bones[bone].matrix_local.to_3x3()
                    pb.location = B.inverted() @ Vector(loc)
                pb.scale = Vector(sc) if sc else Vector((1, 1, 1))
                pb.keyframe_insert("rotation_quaternion", frame=f)
                pb.keyframe_insert("location", frame=f)
                pb.keyframe_insert("scale", frame=f)
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


def iter_fcurves(act):
    if hasattr(act, "fcurves") and len(getattr(act, "fcurves", [])):
        yield from act.fcurves
        return
    for layer in getattr(act, "layers", []):
        for strip in layer.strips:
            for bag in strip.channelbags:
                yield from bag.fcurves


def sinw(i, n, amp, phase=0.0):
    return amp * math.sin(2 * math.pi * (i / n) + phase)


def make_idle(arm):
    n = 60   # 2.0 s loop
    c = Clip(arm, "Idle", n, loop=True)
    for i in range(0, n + 1, 6):
        s = lambda a, ph=0.0: sinw(i, n, a, ph)
        c.k(i, "root", [], (0, 0, s(0.04, 0.3) + 0.0))
        c.k(i, "spine_low", [(X, s(2.0))])
        c.k(i, "chest", [(X, s(2.5, 0.6))], scale=(1 + s(0.03, 0.6) * 0.5, 1 + s(0.04, 0.6), 1))
        c.k(i, "neck", [(X, s(-4.0, 1.0)), (Y, s(3.0, 0.3))])
        c.k(i, "head", [(X, s(6.0, 1.4)), (Z, s(5.0, 0.2))])
        c.k(i, "hood_root", [(X, s(2.0, 0.9))])
        c.k(i, "hood_top", [(X, s(2.5, 1.3))])
        c.k(i, "mask", [(X, s(-3.0, 1.7)), (Y, s(2.5, 0.5))])
        c.k(i, "jaw", [(X, s(-4.0, 2.0) - 4.0)])
        for side, sg in (("L", 1), ("R", -1)):
            c.k(i, "wing1." + side, [(Y, sg * s(-9.0, 1.0))])
            c.k(i, "wing2." + side, [(Y, sg * s(-14.0, 1.6))])
            c.k(i, "sleeve1." + side, [(Y, sg * s(-3.0, 1.2)), (X, s(3.0, 1.5))])
            c.k(i, "sleeve2." + side, [(Y, sg * s(-4.5, 1.8)), (X, s(4.5, 2.0))])
        c.k(i, "cape1", [(X, s(-3.5, 1.4))])
        c.k(i, "cape2", [(X, s(-6.0, 2.0))])
        c.k(i, "tail1", [(Z, s(10.0, 0.0))])
        c.k(i, "tail2", [(Z, s(15.0, 0.8))])
        c.k(i, "tail3", [(Z, s(20.0, 1.6)), (X, s(6.0, 1.6) - 4.0)])
    return c.bake()


def pose_set(c, f, d):
    for bone, v in d.items():
        if isinstance(v, dict):
            c.k(f, bone, v.get("r", []), v.get("loc"), v.get("s"))
        else:
            c.k(f, bone, v)


def wings(c, f, up, fold=0.0, sweep=0.0):
    """up: degrees the crest lifts; fold: wing2 extra; sweep: forward/back about Z."""
    for side, sg in (("L", 1), ("R", -1)):
        c.k(f, "wing1." + side, [(Y, -sg * up), (Z, sg * sweep)])
        c.k(f, "wing2." + side, [(Y, -sg * (up * 0.6 + fold))])


def sleeves(c, f, out, fwd=0.0):
    for side, sg in (("L", 1), ("R", -1)):
        c.k(f, "sleeve1." + side, [(Y, -sg * out), (X, fwd)])
        c.k(f, "sleeve2." + side, [(Y, -sg * out * 0.6), (X, fwd * 1.3)])


def make_attack(arm):
    # 1.0 s: coil back (0-9), strike (9-14), hold (14-19), recover (19-30)
    c = Clip(arm, "Attack", 30)
    rest = {}
    pose_set(c, 0, {"spine_low": [], "spine_mid": [], "chest": [], "neck": [], "head": [],
                    "hood_root": [], "hood_top": [], "mask": [], "jaw": [(X, -3)],
                    "cape1": [], "cape2": [], "tail1": [], "tail2": [], "tail3": [(X, -4)]})
    wings(c, 0, 0); sleeves(c, 0, 0)
    # wind-up: rear back, crest flares, jaw opens
    pose_set(c, 9, {"spine_low": [(X, -6)], "spine_mid": [(X, -6)], "chest": [(X, -5)],
                    "neck": [(X, -10)], "head": [(X, -8)], "hood_root": [(X, -10)],
                    "hood_top": [(X, -12)], "mask": [(X, -8)], "jaw": [(X, -22)],
                    "cape1": [(X, 6)], "cape2": [(X, 8)],
                    "tail1": [(Z, 10)], "tail2": [(Z, 18)], "tail3": [(Z, 24), (X, -14)]})
    wings(c, 9, 22, 10); sleeves(c, 9, 10, -8)
    # strike: lunge forward and down, jaw snaps
    pose_set(c, 14, {"root": {"r": [], "loc": (0, -0.35, 0)},
                     "spine_low": [(X, 9)], "spine_mid": [(X, 10)], "chest": [(X, 8)],
                     "neck": [(X, 14)], "head": [(X, 12)], "hood_root": [(X, 14)],
                     "hood_top": [(X, 18)], "mask": [(X, 14)], "jaw": [(X, 4)],
                     "cape1": [(X, -10)], "cape2": [(X, -14)],
                     "tail1": [(Z, -8)], "tail2": [(Z, -14)], "tail3": [(Z, -18), (X, 6)]})
    wings(c, 14, -10, -14, 8); sleeves(c, 14, 16, 18)
    pose_set(c, 19, {"root": {"r": [], "loc": (0, -0.30, 0)},
                     "spine_low": [(X, 7)], "spine_mid": [(X, 8)], "chest": [(X, 7)],
                     "neck": [(X, 11)], "head": [(X, 9)], "hood_root": [(X, 11)],
                     "hood_top": [(X, 14)], "mask": [(X, 11)], "jaw": [(X, -6)],
                     "cape1": [(X, -6)], "cape2": [(X, -9)],
                     "tail1": [(Z, -5)], "tail2": [(Z, -9)], "tail3": [(Z, -12), (X, 2)]})
    wings(c, 19, -6, -8, 5); sleeves(c, 19, 12, 12)
    pose_set(c, 30, {"root": {"r": [], "loc": (0, 0, 0)}, "spine_low": [], "spine_mid": [],
                     "chest": [], "neck": [], "head": [], "hood_root": [], "hood_top": [],
                     "mask": [], "jaw": [(X, -3)], "cape1": [], "cape2": [],
                     "tail1": [], "tail2": [], "tail3": [(X, -4)]})
    wings(c, 30, 0); sleeves(c, 30, 0)
    c.k(0, "root", [], (0, 0, 0)); c.k(9, "root", [], (0, 0.12, 0))
    return c.bake()


def make_hit(arm):
    # 0.5 s recoil
    c = Clip(arm, "Hit", 15)
    zero = ["spine_low", "spine_mid", "chest", "neck", "head", "hood_root", "hood_top",
            "mask", "cape1", "cape2", "tail1", "tail2", "tail3"]
    pose_set(c, 0, {b: [] for b in zero}); c.k(0, "jaw", [(X, -3)]); c.k(0, "root", [], (0, 0, 0))
    wings(c, 0, 0); sleeves(c, 0, 0)
    pose_set(c, 3, {"root": {"r": [], "loc": (0, 0.34, -0.08)}, "spine_low": [(X, -6), (Y, 7)],
                    "spine_mid": [(X, -6)], "chest": [(X, -5), (Y, 9)], "neck": [(X, -16), (Y, 10)],
                    "head": [(X, -22), (Z, 16)], "hood_root": [(X, -6)], "hood_top": [(X, -8), (Y, 14)],
                    "mask": [(X, -8), (Y, 16)], "jaw": [(X, -24)], "cape1": [(X, 12)], "cape2": [(X, 16)],
                    "tail1": [(Z, -14)], "tail2": [(Z, -18)], "tail3": [(Z, -22)]})
    wings(c, 3, -22, -12); sleeves(c, 3, 14, -16)
    pose_set(c, 7, {"root": {"r": [], "loc": (0, 0.08, 0)}, "spine_low": [(X, -2)],
                    "spine_mid": [(X, -3)], "chest": [(X, -2)], "neck": [(X, -5)], "head": [(X, -4), (Z, 4)],
                    "hood_root": [(X, -3)], "hood_top": [(X, -4)], "mask": [(X, -5)], "jaw": [(X, -8)],
                    "cape1": [(X, 3)], "cape2": [(X, 5)], "tail1": [(Z, 4)], "tail2": [(Z, 6)], "tail3": [(Z, 8)]})
    wings(c, 7, 4, 4); sleeves(c, 7, 3, -3)
    pose_set(c, 15, {b: [] for b in zero}); c.k(15, "jaw", [(X, -3)]); c.k(15, "root", [], (0, 0, 0))
    c.k(15, "tail3", [(X, -4)])
    wings(c, 15, 0); sleeves(c, 15, 0)
    return c.bake()


def make_cast(arm):
    # 1.2 s: rise and spread (0-12), hold with tremble (12-26), release (26-36)
    c = Clip(arm, "Cast", 36)
    zero = ["spine_low", "spine_mid", "chest", "neck", "head", "hood_root", "hood_top",
            "mask", "cape1", "cape2", "tail1", "tail2", "tail3"]
    pose_set(c, 0, {b: [] for b in zero}); c.k(0, "jaw", [(X, -3)]); c.k(0, "root", [], (0, 0, 0))
    wings(c, 0, 0); sleeves(c, 0, 0)
    up = {"root": {"r": [], "loc": (0, 0, 0.18)}, "spine_low": [(X, -4)], "spine_mid": [(X, -5)],
          "chest": [(X, -4)], "neck": [(X, -8)], "head": [(X, -12)], "hood_root": [(X, -6)],
          "hood_top": [(X, -9)], "mask": [(X, -10)], "jaw": [(X, -18)], "cape1": [(X, 10)],
          "cape2": [(X, 14)], "tail1": [(Z, 6)], "tail2": [(Z, 10)], "tail3": [(X, -20)]}
    for f, tw in ((12, 0), (16, 1), (20, -1), (24, 1), (26, 0)):
        d = dict(up)
        d["mask"] = [(X, -10), (Y, 2.5 * tw)]
        pose_set(c, f, d)
        wings(c, f, 30 + 3 * tw, 14); sleeves(c, f, 28 + 2 * tw, -6)
    pose_set(c, 30, {"root": {"r": [], "loc": (0, -0.1, 0.0)}, "spine_low": [(X, 4)], "chest": [(X, 4)],
                     "neck": [(X, 6)], "head": [(X, 6)], "hood_top": [(X, 6)], "mask": [(X, 8)],
                     "jaw": [(X, -10)], "cape1": [(X, -4)]})
    wings(c, 30, -6, -6); sleeves(c, 30, 14, 12)
    pose_set(c, 36, {b: [] for b in zero}); c.k(36, "jaw", [(X, -3)]); c.k(36, "root", [], (0, 0, 0))
    c.k(36, "tail3", [(X, -4)])
    wings(c, 36, 0); sleeves(c, 36, 0)
    return c.bake()


def make_roar(arm):
    # 1.6 s phase-change roar: rear up (0-12), roar + shake (12-36), settle (36-48)
    c = Clip(arm, "Roar", 48)
    zero = ["spine_low", "spine_mid", "chest", "neck", "head", "hood_root", "hood_top",
            "mask", "cape1", "cape2", "tail1", "tail2", "tail3"]
    pose_set(c, 0, {b: [] for b in zero}); c.k(0, "jaw", [(X, -3)]); c.k(0, "root", [], (0, 0, 0))
    wings(c, 0, 0); sleeves(c, 0, 0)
    pose_set(c, 8, {"spine_low": [(X, 5)], "chest": [(X, 6)], "neck": [(X, 10)], "head": [(X, 10)],
                    "hood_top": [(X, 10)], "mask": [(X, 12)], "jaw": [(X, 0)]})
    wings(c, 8, -10, -6); sleeves(c, 8, 4, 6)
    for f, sh in ((14, 1), (17, -1), (20, 1), (23, -1), (26, 1), (29, -1), (32, 1), (36, 0)):
        pose_set(c, f, {"root": {"r": [], "loc": (0, 0.05, 0.16)}, "spine_low": [(X, -6)],
                        "spine_mid": [(X, -5)], "chest": [(X, -5), (Y, 3 * sh)],
                        "neck": [(X, -14)], "head": [(X, -18), (Z, 3 * sh)], "hood_root": [(X, -6)],
                        "hood_top": [(X, -8)], "mask": [(X, -8), (Y, 6 * sh)], "jaw": [(X, -34)],
                        "cape1": [(X, 12)], "cape2": [(X, 16)], "tail1": [(Z, 12 * sh)],
                        "tail2": [(Z, 16 * sh)], "tail3": [(Z, 20 * sh), (X, -24)]})
        wings(c, f, 38 + 4 * sh, 18, 4 * sh); sleeves(c, f, 30 + 3 * sh, -10)
    pose_set(c, 48, {b: [] for b in zero}); c.k(48, "jaw", [(X, -3)]); c.k(48, "root", [], (0, 0, 0))
    c.k(48, "tail3", [(X, -4)])
    wings(c, 48, 0); sleeves(c, 48, 0)
    return c.bake()


def make_dead(arm):
    # 1.6 s: stagger back (0-8), sway (8-18), then slump forward and sink into the robe (18-40);
    # holds the last frame (CombatStage3D fades the slot after the clip ends)
    c = Clip(arm, "Dead", 48)
    zero = ["spine_low", "spine_mid", "chest", "neck", "head", "hood_root", "hood_top",
            "mask", "cape1", "cape2", "tail1", "tail2", "tail3"]
    pose_set(c, 0, {b: [] for b in zero}); c.k(0, "jaw", [(X, -3)]); c.k(0, "root", [], (0, 0, 0))
    wings(c, 0, 0); sleeves(c, 0, 0)
    pose_set(c, 8, {"root": {"r": [], "loc": (0, 0.15, 0)}, "spine_low": [(X, -8), (Y, 4)],
                    "chest": [(X, -8), (Y, 4)], "neck": [(X, -14)], "head": [(X, -18), (Z, 12)],
                    "hood_top": [(X, -12)], "mask": [(X, -14), (Y, 6)], "jaw": [(X, -28)],
                    "tail1": [(Z, 12)], "tail2": [(Z, 18)]})
    wings(c, 8, 16, 8); sleeves(c, 8, 12, -8)
    pose_set(c, 18, {"root": {"r": [], "loc": (0, 0.12, -0.04)}, "spine_low": [(X, -3), (Y, -4)],
                     "chest": [(X, -2), (Y, -5)], "neck": [(X, -6)], "head": [(X, -6), (Z, -8)],
                     "hood_top": [(X, -4)], "mask": [(X, -4), (Y, -6)], "jaw": [(X, -20)],
                     "tail1": [(Z, -6)], "tail2": [(Z, -10)]})
    wings(c, 18, 8, 4); sleeves(c, 18, 6, -4)
    final = {"root": {"r": [], "loc": (0, -0.05, -0.42)}, "spine_low": [(X, 16)],
             "spine_mid": [(X, 14)], "chest": [(X, 10)], "neck": [(X, 18)], "head": [(X, 24), (Z, -10)],
             "hood_root": [(X, 6)], "hood_top": [(X, 6)], "mask": [(X, 8)],
             "jaw": [(X, -6)], "cape1": [(X, -10)], "cape2": [(X, -14)],
             "tail1": [(Z, 18)], "tail2": [(Z, 24)], "tail3": [(Z, 30), (X, 4)]}
    for f in (40, 48):
        pose_set(c, f, final)
        wings(c, f, -16, -10)
        sleeves(c, f, -4, 14)
    return c.bake()


def downsize_textures(objs, size):
    tmp = tempfile.mkdtemp(prefix="venomtex")
    for part, o in objs.items():
        mat = o.data.materials[0]
        mat.use_backface_culling = False
        img = next(n for n in mat.node_tree.nodes if n.type == "TEX_IMAGE").image
        if max(img.size) > size:
            img.scale(size, size)
        img.filepath_raw = os.path.join(tmp, "T_Venom_%s_%s.png" % (part, V))
        img.file_format = 'PNG'
        img.save()
        img.name = "T_Venom_%s_%s" % (part, V)


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.fps = FPS
    objs = import_variant(V)
    arm = build_armature()
    for part, o in objs.items():
        skin(part, o, arm)
    clips = [make_idle(arm), make_attack(arm), make_hit(arm), make_cast(arm), make_roar(arm), make_dead(arm)]
    if BLEND:
        # Saved before the texture downsize, unpacked: the images point at the art team's
        # originals in asset-library/chimera-src, which keeps the source file small.
        os.makedirs(os.path.dirname(os.path.abspath(BLEND)), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=BLEND, compress=True, copy=True)
    downsize_textures(objs, TEX)
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs.values())
    print("VENOM: variant %s tris %d bones %d clips %s" % (V, tris, len(arm.data.bones), [a.name for a in clips]))
    os.makedirs(OUT, exist_ok=True)
    glb = os.path.join(OUT, "chimera_venom_%s.glb" % V)
    bpy.ops.object.select_all(action='SELECT')
    kw = dict(filepath=glb, export_format='GLB', use_selection=False, export_animations=True,
              export_animation_mode='NLA_TRACKS', export_skins=True, export_yup=True,
              export_apply=False, export_force_sampling=True, export_frame_step=1,
              export_def_bones=True, export_image_format='AUTO')
    props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
    kw = {k: v for k, v in kw.items() if k in props}
    bpy.ops.export_scene.gltf(**kw)
    print("VENOM: wrote", glb, os.path.getsize(glb))


main()
