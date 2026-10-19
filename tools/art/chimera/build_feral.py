"""Feral (Beast) Chimera, boss key `mirror` (MIRROR CHIMERA): AI mesh -> fix -> game mesh -> rig -> 6 clips -> GLB.

Headless and reproducible:
  Blender -b --factory-startup -P tools/art/chimera/build_feral.py -- \
      --src "<.../Feral (Beast)/3D/feral_ai.glb>" --out godot/assets/bosses/chimera_feral
Options: --blend <file.blend> saves the rigged source; --cache <dir> reuses/creates the baked
low-poly (decimate+bake is the slow part); --ratio 0.04; --tex 2048; --mesh-only (stop after cache).

Blender space: metres, Z up, Feral faces -Y. Mesh is centred on the origin (z -0.95 floor .. +0.95
crown tip, x +-0.89). The big harlequin rabbit sits on the floor; its upper body (cat torso, ruff,
head, crown, arms) sits on top of the dome and carries most of the animation. Everything is keyed
relative to the rest pose so the game slot (rest pose) stays on the floor.

DEFECTS found in the AI mesh (see the before/after sheets) and their fixes:
 1. Open back of the neck: the white chest is a thin shell with no back, so from behind (and from
    the 3/4 combat camera when the head turns) you see two floating tubes. FIX: a curved back sheet
    (neck_patch) is added, with its own solid blue material, and baked/joined with the mesh.
 2. Mesh was checked for left/right asymmetry (KD-tree mirror test): arms/torso/body are within
    ~4 mm, the only intentional asymmetry is the bow. Nothing to symmetrise.
 3. 657k triangle soup with UV-split vertices: welded first, then decimated with a vertex-group so the
    face / rabbit muzzle / mouth stage / paws keep their triangles, UV islands of those regions get a
    texel-density boost, original colour baked onto a fresh UV layout.
"""
import bpy, os, sys, math
from mathutils import Vector, Quaternion
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from feral_common import *

SRC = arg("src", "/Users/loc.tien.nguyen/my-game/asset-library/chimera-src/Feral (Beast)/3D/feral_ai.glb")
OUT = arg("out", "/tmp/feral")
BLEND = arg("blend")
CACHE = arg("cache")
RATIO = float(arg("ratio", "0.04"))
TEX = int(arg("tex", "2048"))
MESH_ONLY = "--mesh-only" in sys.argv
FPS = 30
FLOOR = -0.95

# ---------------------------------------------------------------------------------------------
# Defect fix 1: close the open back of the neck.
# ---------------------------------------------------------------------------------------------
def neck_patch():
    import bmesh
    bm = bmesh.new()
    zs = [-0.05 + 0.26 * i / 9 for i in range(10)]
    xs = [i / 8.0 * 2 - 1 for i in range(9)]
    rows = []
    for z in zs:
        hw = min(0.098, max(0.075, 0.075 + 0.1 * (z + 0.02))) + 0.012
        yb = min(0.105, 0.07 + 0.25 * max(z, 0.0))
        rows.append([bm.verts.new((u * hw, yb - 0.035 * u * u, z)) for u in xs])
    for r in range(len(zs) - 1):
        for c in range(len(xs) - 1):
            bm.faces.new((rows[r][c], rows[r][c + 1], rows[r + 1][c + 1], rows[r + 1][c]))
    me = bpy.data.meshes.new("NeckPatch")
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("NeckPatch", me)
    bpy.context.scene.collection.objects.link(o)
    me.materials.append(solid_material("M_NeckPatch", (0.10, 0.27, 0.80)))
    return o


def patches():
    return [neck_patch()]


def detail(co):
    """0..1 weight that keeps triangles where the painted detail is."""
    x, y, z = co
    if z > 0.28 and abs(x) < 0.45 and y > -0.3:
        return 1.0                       # head, ruff, crown, bow
    if y < -0.3 and abs(x) < 0.5 and -0.95 < z < -0.05:
        return 0.9                       # rabbit face + mouth stage
    if abs(x) > 0.5 and z > -0.2 and y > -0.3:
        return 0.7                       # paws
    return 0.0


REGIONS = [
    ((-0.45, 0.45), (-0.3, 1.0), (0.28, 1.0), 2.0),        # head
    ((-0.5, 0.5), (-1.0, -0.3), (-0.95, -0.05), 1.8),      # rabbit face + mouth
    ((-1.0, -0.5), (-0.3, 1.0), (-0.2, 0.4), 1.5),         # paw R
    ((0.5, 1.0), (-0.3, 1.0), (-0.2, 0.4), 1.5),           # paw L
]

# ---------------------------------------------------------------------------------------------
# Rig
# ---------------------------------------------------------------------------------------------
BONES = [
    ("root",    (0, 0, -0.95),          (0, 0, -0.80),          None),
    ("body",    (0, 0, -0.90),          (0, 0, -0.10),          "root"),
    ("ear.L",   (0.55, -0.25, -0.20),   (0.70, -0.25, -0.82),   "body"),
    ("waist",   (0, 0, -0.10),          (0, 0, 0.12),           "body"),
    ("chest",   (0, 0, 0.12),           (0, -0.01, 0.24),       "waist"),
    ("neck",    (0, -0.01, 0.24),       (0, -0.03, 0.32),       "chest"),
    ("head",    (0, -0.03, 0.32),       (0, -0.03, 0.62),       "neck"),
    ("crown",   (0, -0.02, 0.62),       (0, 0.0, 0.95),         "head"),
    ("bow",     (0.12, -0.10, 0.66),    (0.28, -0.10, 0.70),    "head"),
    ("upper.L", (0.18, -0.01, 0.15),    (0.36, -0.03, 0.13),    "chest"),
    ("fore.L",  (0.36, -0.03, 0.13),    (0.58, -0.05, 0.07),    "upper.L"),
    ("hand.L",  (0.58, -0.05, 0.07),    (0.86, -0.08, 0.04),    "fore.L"),
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
    data = bpy.data.armatures.new("FeralRig")
    arm = bpy.data.objects.new("FeralRig", data)
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


def dome_z(x, y):
    a = 1 - (x / 0.89) ** 2 - (y / 0.56) ** 2
    return -0.95 + 0.93 * math.sqrt(max(0.0, a))


def is_upper(p):
    return p.y > -0.25 and p.z > -0.2 and p.z > dome_z(p.x, p.y) + 0.02


def gate(n, p):
    base = n.split(".")[0]
    ax = abs(p.x)
    if n.endswith(".L") and p.x < 0.0:
        return False
    if n.endswith(".R") and p.x > 0.0:
        return False
    if base == "upper":
        return ax > 0.12
    if base == "fore":
        return ax > 0.30
    if base == "hand":
        return ax > 0.50
    if base in ("head", "bow"):
        return p.z > 0.26
    if base == "crown":
        return p.z > 0.60 and ax < 0.32
    if base == "neck":
        return ax < 0.25
    return True


UPPER = {"waist", "chest", "neck", "head", "crown", "bow", "upper", "fore", "hand"}


def skin(obj, arm):
    segs = {n: (Vector(h), Vector(t)) for n, h, t, p in BONES}
    names = [n for n, _, _, _ in BONES if n != "root"]
    for n in names:
        obj.vertex_groups.new(name=n)
    me = obj.data
    for v in me.vertices:
        p = v.co
        if is_upper(p):
            cand = [n for n in names if n.split(".")[0] in UPPER and gate(n, p)]
            ws = []
            for n in cand:
                a, b = segs[n]
                ws.append((1.0 / (seg_dist(p, a, b) + 0.03) ** 4, n))
            ws.sort(reverse=True)
            ws = ws[:3]
            tot = sum(w for w, _ in ws)
            for w, n in ws:
                obj.vertex_groups[n].add([v.index], w / tot, 'REPLACE')
        else:
            # rabbit: the ears hang off the sides, everything else is the body
            dx = abs(p.x) - 0.89 * math.sqrt(max(0.0, 1 - (p.y / 0.56) ** 2 - ((p.z + 0.95) / 0.93) ** 2))
            e = max(0.0, min(1.0, (dx - 0.0) / 0.10)) if (abs(p.x) > 0.45 and p.z < -0.12) else 0.0
            e *= max(0.0, min(1.0, (-0.12 - p.z) / 0.25))      # stiff at the root, free at the tip
            if e > 0.01:
                obj.vertex_groups["ear." + ("L" if p.x > 0 else "R")].add([v.index], e, 'REPLACE')
            obj.vertex_groups["body"].add([v.index], 1.0 - e, 'REPLACE')
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
# Animation. Rotations are (armature-space axis, degrees) converted to each bone's local frame.
# Feral faces -Y: +X rotation tips the top FORWARD. Arms: L tip (+X) is raised by -Y rotation
# (R mirrored); swung forward by -Z (R mirrored).
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


BODYCHAIN = ["body", "waist", "chest", "neck", "head", "crown"]


class Clip:
    def __init__(self, arm, name, frames):
        self.arm, self.name, self.frames = arm, name, frames
        self.keys = {}

    def k(self, f, bone, rots=(), loc=None, scale=None):
        self.keys.setdefault(bone, {})[f] = (list(rots), loc, scale)

    def pose(self, f, d=None, root=(0, 0, 0), arms=None, ears=0.0, bow=0.0, crown=0.0, squash=0.0, sides=None):
        """Keys every bone at frame f. d: bone -> rots for the body chain. root: (x, y, z) offset
        of the whole creature. arms: dict(up, fwd, elbow, hand) in degrees, mirrored. sides: dict
        'L'/'R' -> arms dict overrides. ears: swing out (deg). squash: rabbit body z scale delta."""
        d = d or {}
        for b in BODYCHAIN:
            self.k(f, b, d.get(b, []), scale=((1 + 0.5 * squash, 1 + 0.5 * squash, 1 - squash) if b == "body" else None))
        self.k(f, "root", d.get("root", []), root)
        self.k(f, "crown", d.get("crown", []) + [(X, crown)])
        w = dict(up=0.0, fwd=0.0, elbow=0.0, hand=0.0, twist=0.0)
        w.update(arms or {})
        for side, sg in (("L", 1), ("R", -1)):
            a = dict(w)
            a.update((sides or {}).get(side, {}))
            self.k(f, "upper." + side, [(Y, -sg * a["up"]), (Z, -sg * a["fwd"]), (X, a["twist"])])
            self.k(f, "fore." + side, [(Y, -sg * a["up"] * 0.3), (Z, -sg * (a["elbow"] + a["fwd"] * 0.4))])
            self.k(f, "hand." + side, [(Y, sg * a["hand"]), (Z, -sg * a["fwd"] * 0.3), (X, a["twist"] * 0.5)])
            self.k(f, "ear." + side, [(Y, sg * ears)])
        self.k(f, "bow", d.get("bow", []) + [(X, bow), (Z, bow * 0.5)])

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
                rots, loc, scale = fr[f]
                pb.rotation_quaternion = local_q(arm, bone, rots)
                if loc is not None:
                    B = arm.data.bones[bone].matrix_local.to_3x3()
                    pb.location = B.inverted() @ Vector(loc)
                else:
                    pb.location = Vector()
                pb.scale = Vector(scale) if scale else Vector((1, 1, 1))
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


def sn(i, n, amp, ph=0.0):
    return amp * math.sin(2 * math.pi * i / n + ph)


REST_ARMS = dict(up=0.0, fwd=0.0, elbow=0.0, hand=0.0)


def make_idle(arm):
    n = 64   # 2.1 s breathing loop, secondary parts lag behind
    c = Clip(arm, "Idle", n)
    for i in range(0, n + 1, 4):
        s = lambda a, ph=0.0: sn(i, n, a, ph)
        d = {"waist": [(X, s(1.6, 0.3)), (Z, s(1.5, 1.0))], "chest": [(X, s(1.8, 0.6))],
             "neck": [(X, s(-1.5, 1.0))], "head": [(X, s(2.5, 1.0)), (Z, s(4.0, 0.2)), (Y, s(2.0, 0.6))],
             "body": [(X, s(0.5, 0.0))]}
        c.pose(i, d, root=(0, 0, 0), squash=s(0.012, 0.0),
               arms=dict(up=3 + s(4, 0.9), fwd=s(2.5, 0.2), elbow=s(2, 0.5), hand=s(5, 1.4)),
               ears=2 + s(4, 1.6), bow=s(5, 1.6), crown=s(2.5, 2.0))
    return c.bake()


def make_attack(arm):
    # 1.0 s: rear back, arms wide + up (0-10); claws sweep forward and down (10-15); hold; recover.
    c = Clip(arm, "Attack", 30)
    c.pose(0, arms=REST_ARMS)
    c.pose(10, {"waist": [(X, -14)], "chest": [(X, -10)], "neck": [(X, -6)], "head": [(X, -14)],
                "body": [(X, -3)]}, root=(0, 0.10, 0.02), squash=-0.02,
           arms=dict(up=48, fwd=-22, elbow=-12, hand=-18), ears=-6, bow=-8, crown=-8)
    c.pose(15, {"waist": [(X, 26)], "chest": [(X, 20)], "neck": [(X, 12)], "head": [(X, 18)],
                "body": [(X, 5)]}, root=(0, -0.28, -0.01), squash=0.03,
           arms=dict(up=-30, fwd=70, elbow=12, hand=28), ears=12, bow=10, crown=12)
    c.pose(20, {"waist": [(X, 20)], "chest": [(X, 14)], "neck": [(X, 8)], "head": [(X, 12)],
                "body": [(X, 4)]}, root=(0, -0.22, 0.0), squash=0.02,
           arms=dict(up=-20, fwd=60, elbow=10, hand=20), ears=8, bow=6, crown=8)
    c.pose(30, arms=REST_ARMS)
    return c.bake()


def make_hit(arm):
    c = Clip(arm, "Hit", 16)
    c.pose(0, arms=REST_ARMS)
    c.pose(3, {"waist": [(X, -16), (Y, 6)], "chest": [(X, -10), (Y, 6)], "neck": [(X, -10)],
               "head": [(X, -22), (Z, 14)], "body": [(X, -3)]}, root=(0, 0.14, 0.0), squash=0.04,
           arms=dict(up=40, fwd=-14, elbow=-8, hand=-14), ears=-10, bow=-14, crown=-12)
    c.pose(8, {"waist": [(X, -4)], "chest": [(X, -3)], "neck": [(X, -4)], "head": [(X, -6), (Z, 5)]},
           root=(0, 0.04, 0.0), squash=-0.02, arms=dict(up=10, fwd=-4, hand=-4), ears=6, bow=6, crown=6)
    c.pose(12, {"head": [(X, 2)]}, root=(0, 0.01, 0.0), arms=dict(up=-2), ears=-2)
    c.pose(16, arms=REST_ARMS)
    return c.bake()


def make_cast(arm):
    # 1.5 s MIRROR gesture: arms rise, then sweep inward in front, the head tilts side to side as if
    # copying (0-14), mirror beats (14-34), release (34-45).
    c = Clip(arm, "Cast", 45)
    c.pose(0, arms=REST_ARMS)
    c.pose(14, {"waist": [(X, -4)], "chest": [(X, -4)], "neck": [(X, -6)], "head": [(X, -8)]},
           root=(0, 0, 0.03), squash=-0.01, arms=dict(up=52, fwd=-10, elbow=-6, hand=-12), ears=4, bow=-6, crown=-6)
    for f, t in ((20, 1), (26, -1), (32, 1)):
        c.pose(f, {"waist": [(X, 2), (Z, 3 * t)], "chest": [(X, 2)], "neck": [(X, -2)],
                   "head": [(X, -4), (Y, 12 * t), (Z, 6 * t)]},
               root=(0, -0.04, 0.02), squash=0.0,
               arms=dict(up=24, fwd=44, elbow=14, hand=10),
               sides={"L": dict(fwd=44 + 6 * t), "R": dict(fwd=44 - 6 * t)}, ears=-4 * t, bow=8 * t, crown=6 * t)
    c.pose(38, {"chest": [(X, 4)], "head": [(X, 4)]}, root=(0, 0, 0.0), arms=dict(up=8, fwd=10), ears=2)
    c.pose(45, arms=REST_ARMS)
    return c.bake()


def make_roar(arm):
    # 1.6 s: rear back, the whole rabbit swells, arms thrown wide, head forward and shaking.
    c = Clip(arm, "Roar", 48)
    c.pose(0, arms=REST_ARMS)
    c.pose(10, {"waist": [(X, -10)], "chest": [(X, -8)], "neck": [(X, -6)], "head": [(X, -14)],
                "body": [(X, -4)]}, root=(0, 0.06, 0.03), squash=-0.04,
           arms=dict(up=36, fwd=-18, elbow=-8, hand=-14), ears=-6, bow=-8, crown=-10)
    for f, sh in ((16, 1), (19, -1), (22, 1), (25, -1), (28, 1), (31, -1), (34, 1), (38, 0)):
        c.pose(f, {"waist": [(X, 10), (Y, 2 * sh)], "chest": [(X, 6), (Y, 3 * sh)], "neck": [(X, 8)],
                   "head": [(X, 14), (Z, 6 * sh)], "body": [(X, 3)]},
               root=(0.02 * sh, -0.12, 0.0), squash=0.05 + 0.01 * sh,
               arms=dict(up=62 + 3 * sh, fwd=20, elbow=-6, hand=-18), ears=10 + 4 * sh, bow=6 * sh, crown=8 + 4 * sh)
    c.pose(48, arms=REST_ARMS)
    return c.bake()


def make_dead(arm):
    # 1.8 s: staggers back (0-6), upper body folds forward, arms drop, rabbit slumps (6-30), holds.
    c = Clip(arm, "Dead", 54)
    c.pose(0, arms=REST_ARMS)
    c.pose(6, {"waist": [(X, -10)], "chest": [(X, -8)], "neck": [(X, -8)], "head": [(X, -16), (Z, 10)]},
           root=(0, 0.10, 0.0), squash=0.03, arms=dict(up=36, fwd=-8, hand=-10), ears=-8, bow=-12, crown=-10)
    fin = {"waist": [(X, 34)], "chest": [(X, 24)], "neck": [(X, 14)], "head": [(X, 22), (Z, -14), (Y, 8)],
           "body": [(X, 4)]}
    c.pose(18, {"waist": [(X, 20)], "chest": [(X, 14)], "neck": [(X, 8)], "head": [(X, 14), (Z, -8)]},
           root=(0, 0.02, -0.04), squash=0.05, arms=dict(up=-30, fwd=14, elbow=6, hand=10), ears=8, bow=8, crown=6)
    c.pose(28, fin, root=(0, -0.06, -0.10), squash=0.09,
           arms=dict(up=-62, fwd=10, elbow=8, hand=16), ears=16, bow=14, crown=14)
    for f in (36, 54):
        c.pose(f, fin, root=(0, -0.06, -0.11), squash=0.10,
               arms=dict(up=-66, fwd=10, elbow=8, hand=16), ears=18, bow=14, crown=14)
    return c.bake()


def main():
    cache_blend = os.path.join(CACHE, "feral_low.blend") if CACHE else None
    if cache_blend and os.path.exists(cache_blend):
        bpy.ops.wm.open_mainfile(filepath=cache_blend)
        low = bpy.data.objects["Feral"]
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        tex_tmp = os.path.join(CACHE or "/tmp", "T_Feral_bake.png")
        low = prepare_mesh(SRC, RATIO, TEX, tex_tmp, patches, detail, REGIONS)
        if cache_blend:
            os.makedirs(CACHE, exist_ok=True)
            bpy.data.images["T_Feral"].pack()
            bpy.ops.wm.save_as_mainfile(filepath=cache_blend, copy=True)
    print("FERAL: low tris", tri_count(low))
    if MESH_ONLY:
        return
    sc = bpy.context.scene
    sc.render.fps = FPS
    arm = build_armature()
    skin(low, arm)
    clips = [make_idle(arm), make_attack(arm), make_hit(arm), make_cast(arm), make_roar(arm), make_dead(arm)]
    if BLEND:
        os.makedirs(os.path.dirname(os.path.abspath(BLEND)), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=BLEND, compress=True, copy=True)
    print("FERAL: tris %d bones %d clips %s" % (tri_count(low), len(arm.data.bones), [a.name for a in clips]))
    os.makedirs(OUT, exist_ok=True)
    glb = os.path.join(OUT, "chimera_feral.glb")
    bpy.ops.object.select_all(action='SELECT')
    kw = dict(filepath=glb, export_format='GLB', use_selection=False, export_animations=True,
              export_animation_mode='NLA_TRACKS', export_skins=True, export_yup=True,
              export_apply=False, export_force_sampling=True, export_frame_step=1,
              export_def_bones=True, export_image_format='JPEG', export_jpeg_quality=90)
    props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
    kw = {k: v for k, v in kw.items() if k in props}
    bpy.ops.export_scene.gltf(**kw)
    print("FERAL: wrote", glb, os.path.getsize(glb))


main()
