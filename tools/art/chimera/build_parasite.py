"""Parasite (Bug) Chimera (boss plague_mother) from the art team's FBX parts:
import -> place sword -> rig -> skin per part -> 6 clips -> GLB.

  Blender -b --factory-startup -P tools/art/chimera/build_parasite.py -- \
      --out godot/assets/bosses/chimera_parasite [--blend path.blend]

Parts (asset-library/chimera-src/Parasite (Bug)/3D/Bug_01): Body (torso+arms, legs, 2 cape layers
and 2 shoulder boards, 6 islands), Hair (plume), Mask (beak), Sheath (sword in its scabbard; the
bare Weapon mesh is not used, idle keeps the sword sheathed). Body/Hair/Mask already share one
frame; the sheath ships upright at the origin and is laid across the back here.
Textures are the art team's, untouched. Blender space: metres, Z up, creature faces -Y
(-Y becomes +Z in the glTF, which is what Godot's "forward" is).
"""
import bpy, os, sys, math
import mathutils
from mathutils import Vector, Quaternion, Matrix
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from parasite_common import *

OUT = arg("out", "/tmp/parasite")   # machine-local default; pass --out godot/assets/bosses/chimera_parasite
BLEND = arg("blend")
FPS = 30
SWORD_SCALE = 0.95    # the art shows a huge blade, as wide as the cape; the FBX is 4.7 m at 1.0
HAIR_SCALE = 1.3      # the crest in Bug_1.png is clearly bigger than the delivered mesh (about 0.75 of the cape width)
HAIR_PIVOT = Vector((0, 0.15, 2.30))

# (name, head, tail, parent). Left bones are written for +X and mirrored.
BONES = [
    ("root",     (0, 0.05, 0.00), (0, 0.05, 0.60), None),
    ("spine_low", (0, 0.05, 0.60), (0, 0.05, 1.20), "root"),
    ("spine_mid", (0, 0.05, 1.20), (0, 0.00, 1.65), "spine_low"),
    ("chest",    (0, 0.00, 1.65), (0, 0.00, 2.15), "spine_mid"),
    ("neck",     (0, -0.05, 2.15), (0, -0.20, 2.50), "chest"),
    ("head",     (0, -0.20, 2.50), (0, -0.30, 2.95), "neck"),
    # plume (hair): centre fan + side fans, parented to the head
    ("plume1",   (0, 0.20, 2.35), (0, 0.30, 3.00), "head"),
    ("plume2",   (0, 0.30, 3.00), (0, 0.40, 3.70), "plume1"),
    ("plumeS1.L", (0.20, 0.25, 2.60), (0.65, 0.30, 3.15), "head"),
    ("plumeS2.L", (0.65, 0.30, 3.15), (1.00, 0.35, 3.60), "plumeS1.L"),
    # legs
    ("thigh.L",  (0.18, 0.03, 1.13), (0.20, 0.03, 0.60), "root"),
    ("calf.L",   (0.20, 0.03, 0.60), (0.20, 0.00, 0.05), "thigh.L"),
    # arms: upper, fore, hand (claws)
    ("upper.L",  (0.62, 0.05, 1.88), (0.78, 0.07, 1.35), "chest"),
    ("fore.L",   (0.78, 0.07, 1.35), (0.92, 0.06, 0.88), "upper.L"),
    ("hand.L",   (0.92, 0.06, 0.88), (1.05, 0.06, 0.30), "fore.L"),
    # shoulder boards (hang behind the arms)
    ("board.L",  (0.45, 0.30, 2.10), (0.85, 0.40, 1.25), "chest"),
    # cape: back (centre), sides (swing out), front edges (hang beside the legs)
    ("capeB1",   (0, 0.30, 1.90), (0, 0.80, 1.00), "chest"),
    ("capeB2",   (0, 0.80, 1.00), (0, 1.80, 0.10), "capeB1"),
    ("capeS1.L", (0.55, 0.30, 1.85), (1.15, 0.55, 0.95), "chest"),
    ("capeS2.L", (1.15, 0.55, 0.95), (1.80, 1.00, 0.10), "capeS1.L"),
    ("capeF1.L", (0.60, 0.12, 1.85), (1.15, 0.15, 0.95), "chest"),
    ("capeF2.L", (1.15, 0.15, 0.95), (1.80, 0.25, 0.10), "capeF1.L"),
    # sword on the back
    ("sword",    (0, 0.75, 1.95), (0, 0.75, 2.40), "chest"),
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
SEGS = {n: (Vector(h), Vector(t)) for n, h, t, p in BONES}
SIDES = lambda stems: [s + k for s in stems for k in (".L", ".R")]

ALLOWED = {
    "torso": ["root", "spine_low", "spine_mid", "chest", "neck", "head"]
             + SIDES(["upper", "fore", "hand", "thigh"]),
    "legs": ["root", "spine_low"] + SIDES(["thigh", "calf"]),
    "cape": ["spine_mid", "chest", "capeB1", "capeB2"] + SIDES(["capeS1", "capeS2", "capeF1", "capeF2"]),
    "board": ["chest", "spine_mid"] + SIDES(["board"]),
    "Hair": ["head", "plume1", "plume2"] + SIDES(["plumeS1", "plumeS2"]),
}


def build_armature():
    arm_data = bpy.data.armatures.new("ParasiteRig")
    arm = bpy.data.objects.new("ParasiteRig", arm_data)
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


def island_lists(me):
    import bmesh
    bm = bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table()
    comp = [-1] * len(bm.verts); groups = []
    for v in bm.verts:
        if comp[v.index] >= 0:
            continue
        stack = [v]; comp[v.index] = len(groups); g = []
        while stack:
            x = stack.pop(); g.append(x.index)
            for e in x.link_edges:
                y = e.other_vert(x)
                if comp[y.index] < 0:
                    comp[y.index] = len(groups); stack.append(y)
        groups.append(g)
    bm.free()
    return groups


def classify_body(me):
    """Body island -> kind. cape: spans > 3 m wide; legs: all below 1.2; board: tiny; torso: rest."""
    kind = {}
    for g in island_lists(me):
        xs = [me.vertices[i].co.x for i in g]; zs = [me.vertices[i].co.z for i in g]
        if max(xs) - min(xs) > 3.0:
            k = "cape"
        elif max(zs) < 1.2:
            k = "legs"
        elif len(g) < 60:
            k = "board"
        else:
            k = "torso"
        for i in g:
            kind[i] = k
    return kind


def weight_for(kind, p):
    """[(bone, w)] for a vertex at p (armature space) of the given kind."""
    ws = []
    for n in ALLOWED[kind]:
        a, b = SEGS[n]
        if n.endswith(".L") and p.x < 0.05: continue
        if n.endswith(".R") and p.x > -0.05: continue
        d = seg_dist(p, a, b)
        pw = 4
        if kind == "torso":
            # arms own the outer region; spine/chest bones never reach out to the hands
            if n.split(".")[0] in ("upper", "fore", "hand") and abs(p.x) < 0.42: continue
            if n.split(".")[0] == "thigh" and p.z > 1.35: continue
            if n in ("spine_low", "spine_mid", "chest", "root", "neck") and abs(p.x) > 0.80 and p.z < 1.7: continue
        if kind == "cape":
            # side edges own |x| large, back owns the middle; front edges own y near the body
            if n.startswith("capeF") and p.y > 0.55: continue
            if n.startswith("capeS") and abs(p.x) < 0.5: continue
            if n.startswith("capeB") and abs(p.x) > 1.3: continue
        ws.append((1.0 / (d + 0.05) ** pw, n))
    ws.sort(reverse=True)
    ws = ws[:3]
    tot = sum(w for w, _ in ws)
    return [(n, w / tot) for w, n in ws]


def skin(part, obj, arm):
    me = obj.data
    kinds = None
    if part == "Body":
        kinds = classify_body(me)
        names = sorted({n for k in ALLOWED if k != "Hair" for n in ALLOWED[k]})
    elif part == "Hair":
        names = ALLOWED["Hair"]
    elif part == "Mask":
        names = ["head"]
    else:
        names = ["sword"]
    for n in names:
        obj.vertex_groups.new(name=n)
    for v in me.vertices:
        if part in ("Mask", "Sheath"):
            obj.vertex_groups[names[0]].add([v.index], 1.0, 'REPLACE'); continue
        kind = kinds[v.index] if kinds else "Hair"
        if kind == "torso" and v.co.z > 2.45:           # the head itself is rigid
            obj.vertex_groups["head"].add([v.index], 1.0, 'REPLACE'); continue
        for n, w in weight_for(kind, v.co):
            obj.vertex_groups[n].add([v.index], w, 'REPLACE')
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True); bpy.context.view_layer.objects.active = obj
    if part in ("Body", "Hair"):
        bpy.ops.object.mode_set(mode='WEIGHT_PAINT')
        bpy.ops.object.vertex_group_smooth(group_select_mode='ALL', factor=0.4, repeat=2)
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.vertex_group_limit_total(group_select_mode='ALL', limit=4)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    bpy.ops.object.vertex_group_clean(group_select_mode='ALL', limit=0.01)
    bpy.ops.object.vertex_group_normalize_all(lock_active=False)
    obj.parent = arm
    mod = obj.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm


def fix_sheath_uv(o):
    """The delivered weapon.png no longer matches the FBX UVs (scabbard/grip land on empty texels, so
    they render black or show the red blade variant). Re-project the three big pieces onto their
    regions of T_Bug_Weapon_1_C.png: scabbard -> the orange sheath with the cyan flame tip, grip ->
    the cyan wrap, guard + dome -> flat sheath orange. Pommel and ring already map correctly."""
    me = o.data
    uv = me.uv_layers[0].data
    comps = island_lists(me)
    comp_of = {}
    for ci, g in enumerate(comps):
        for i in g:
            comp_of[i] = ci
    kinds = {}
    for ci, g in enumerate(comps):
        zs = [me.vertices[i].co.z for i in g]
        if max(zs) < 2.9:
            kinds[ci] = "scabbard"
        elif min(zs) > 2.7 and max(zs) < 4.15:
            kinds[ci] = "hilt"
    for poly in me.polygons:
        k = kinds.get(comp_of[poly.vertices[0]])
        if not k:
            continue
        for li in poly.loop_indices:
            co = me.vertices[me.loops[li].vertex_index].co
            if k == "scabbard":
                # sheath piece of the atlas: u .655-.825, v .02-.745 (tip at the bottom)
                u = 0.665 + (co.y + 0.42) / 0.84 * 0.15
                v = 0.03 + (co.z + 0.11) / 2.94 * 0.70
            else:
                thin = abs(co.x) < 0.1 and abs(co.y) < 0.15
                if thin:                       # grip: the cyan wrap (u .37-.47, v .41-.69)
                    u = 0.385 + (co.y + 0.12) / 0.24 * 0.07
                    v = 0.42 + (co.z - 2.83) / 1.26 * 0.26
                else:                          # guard + dome: flat sheath orange
                    u, v = 0.74, 0.62
            uv[li].uv = (u, v)


def place_sword(o):
    """Upright at the origin, 4.8 m -> 2.8 m, broad face to the back, laid across the back with
    the hilt up on the creature's right (-X), tip down on the left, outside the cape."""
    S = SWORD_SCALE
    M = Matrix.Rotation(math.radians(-75), 4, 'Y') @ Matrix.Rotation(math.radians(90), 4, 'Z') @ Matrix.Scale(S, 4)
    o.data.transform(M)
    def vbounds():
        vs = [v.co for v in o.data.vertices]
        return (Vector([min(v[i] for v in vs) for i in range(3)]), Vector([max(v[i] for v in vs) for i in range(3)]))
    mn, mx = vbounds()      # (object.bound_box is stale right after data.transform)
    o.data.transform(Matrix.Translation(Vector((0, 1.15, 1.95)) - (mn + mx) / 2))
    o.data.update()
    mn, mx = vbounds()
    print("PARASITE: sword bounds", tuple(round(x, 2) for x in mn), tuple(round(x, 2) for x in mx))


# -----------------------------------------------------------------------------------------------
# Animation. Rotations are (axis in armature space, degrees) converted to each bone's local frame.
# Faces -Y: +X rotation tips the top of a bone toward -Y (forward) and swings a hanging tip +Y (back).
# -----------------------------------------------------------------------------------------------
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


class Clip:
    def __init__(self, arm, name, frames, loop=False):
        self.arm, self.name, self.frames, self.loop = arm, name, frames, loop
        self.keys = {}

    def k(self, f, bone, rots=(), loc=None):
        self.keys.setdefault(bone, {})[f] = (list(rots), loc)

    def bake(self):
        arm = self.arm
        act = bpy.data.actions.new(self.name)
        act.use_fake_user = True
        arm.animation_data_create()
        arm.animation_data.action = act
        for pb in arm.pose.bones:
            pb.rotation_mode = 'QUATERNION'
        for bone in [b.name for b in arm.pose.bones]:
            pb = arm.pose.bones[bone]
            fr = self.keys.get(bone, {0: ([], None)})
            if self.frames not in fr and bone in self.keys:
                fr[self.frames] = fr[min(fr)] if self.loop else fr[max(fr)]
            for f in sorted(fr):
                rots, loc = fr[f]
                pb.rotation_quaternion = local_q(arm, bone, rots)
                B = arm.data.bones[bone].matrix_local.to_3x3()
                pb.location = (B.inverted() @ Vector(loc)) if loc else Vector()
                pb.scale = Vector((1, 1, 1))
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


SPINE = ["spine_low", "spine_mid", "chest", "neck", "head"]
SECOND = ["plume1", "plume2", "capeB1", "capeB2", "sword"]
SIDE2 = ["plumeS1", "plumeS2", "capeS1", "capeS2", "capeF1", "capeF2", "board", "upper", "fore", "hand", "thigh", "calf"]
ALL = SPINE + SECOND + SIDE2 + ["root"]


def sd(side):
    return 1 if side == "L" else -1


def pose(c, f, d):
    """d: bone (or 'stem*' for both sides, mirrored on Y/Z rotations via a (rots_L) list) -> rots.
    Keys not mentioned stay at rest for this frame."""
    for b in SPINE + SECOND:
        c.k(f, b, d.get(b, []), d.get(b + "@loc") if b == "root" else None)
    c.k(f, "root", d.get("root", []), d.get("root@loc"))
    for stem in SIDE2:
        for side in "LR":
            v = d.get(stem)
            if v is None:
                c.k(f, "%s.%s" % (stem, side), [])
            else:
                s = sd(side)
                # v is a list of (axis, deg) for the left bone; Y/Z rotations flip for the right side
                c.k(f, "%s.%s" % (stem, side), [(a, deg * (s if (a is Y or a is Z) else 1)) for a, deg in v])
    for side in "LR":
        for stem in SIDE2:
            o = d.get("%s.%s" % (stem, side))
            if o is not None:
                c.k(f, "%s.%s" % (stem, side), o)


def rest(c, f):
    pose(c, f, {})


def make_idle(arm):
    n = 60
    c = Clip(arm, "Idle", n, loop=True)
    for i in range(0, n + 1, 6):
        s = lambda a, ph=0.0: a * math.sin(2 * math.pi * i / n + ph)
        d = {"root@loc": (0, 0, s(0.03, 0.3)),
             "spine_low": [(X, s(1.5))], "chest": [(X, s(2.0, 0.6))],
             "neck": [(X, s(-3.0, 1.0)), (Z, s(3.0, 0.3))], "head": [(X, s(3.0, 1.4)), (Z, s(4.0, 0.2))],
             "plume1": [(X, s(4.0, 1.0)), (Y, s(3.0, 0.4))], "plume2": [(X, s(7.0, 1.5)), (Y, s(5.0, 0.9))],
             "capeB1": [(X, s(2.5, 1.4))], "capeB2": [(X, s(5.0, 2.0))], "sword": [(X, s(0.8, 1.0))],
             "plumeS1": [(Y, s(-4.0, 1.0))], "plumeS2": [(Y, s(-7.0, 1.6))],
             "capeS1": [(Y, s(-1.5, 1.0))], "capeS2": [(Y, s(-3.0, 1.6))],
             "capeF1": [(Y, s(-1.0, 1.2))], "capeF2": [(Y, s(-2.0, 1.8))],
             "upper": [(Y, s(-1.5, 1.0)), (X, s(2.0, 1.5))], "fore": [(X, s(3.0, 2.0)) ],
             "hand": [(X, s(4.0, 2.5))], "board": [(Y, s(-1.5, 1.2))]}
        pose(c, i, d)
    return c.bake()


def make_attack(arm):
    # 1.0 s: coil back (0-9), claw lunge forward (9-15), hold (15-20), recover (20-30)
    c = Clip(arm, "Attack", 30)
    rest(c, 0)
    pose(c, 9, {"root@loc": (0, 0.2, -0.05), "spine_low": [(X, -6)], "spine_mid": [(X, -6)],
                "chest": [(X, -8)], "neck": [(X, -6)], "head": [(X, -6)],
                "plume1": [(X, -10)], "plume2": [(X, -12)], "capeB1": [(X, 8)], "capeB2": [(X, 10)],
                "upper": [(X, 30), (Y, -22)], "fore": [(X, -35)], "hand": [(X, -10)],
                "plumeS1": [(Y, -8)], "capeS1": [(Y, -6)], "capeF1": [(Y, -6)]})
    pose(c, 14, {"root@loc": (0, -0.65, -0.10), "spine_low": [(X, 10)], "spine_mid": [(X, 12)],
                 "chest": [(X, 12)], "neck": [(X, 8)], "head": [(X, 10)],
                 "plume1": [(X, 14)], "plume2": [(X, 20)], "capeB1": [(X, -12)], "capeB2": [(X, -18)],
                 "upper": [(X, -75), (Y, 12)], "fore": [(X, -25)], "hand": [(X, -10)],
                 "thigh": [(X, -18)], "calf": [(X, 24)],
                 "plumeS1": [(Y, 10)], "capeS1": [(Y, -8)], "capeF1": [(Y, -8)], "capeS2": [(Y, -6)]})
    pose(c, 20, {"root@loc": (0, -0.55, -0.08), "spine_low": [(X, 8)], "spine_mid": [(X, 9)],
                 "chest": [(X, 9)], "neck": [(X, 6)], "head": [(X, 7)],
                 "plume1": [(X, 9)], "plume2": [(X, 13)], "capeB1": [(X, -7)], "capeB2": [(X, -11)],
                 "upper": [(X, -65), (Y, 8)], "fore": [(X, -20)],
                 "thigh": [(X, -14)], "calf": [(X, 18)]})
    rest(c, 30)
    return c.bake()


def make_hit(arm):
    c = Clip(arm, "Hit", 15)
    rest(c, 0)
    pose(c, 3, {"root@loc": (0, 0.30, -0.06), "spine_low": [(X, -6), (Y, 6)], "spine_mid": [(X, -6)],
                "chest": [(X, -8), (Y, 8)], "neck": [(X, -14), (Z, 8)], "head": [(X, -18), (Z, 14)],
                "plume1": [(X, -16)], "plume2": [(X, -20)], "capeB1": [(X, 12)], "capeB2": [(X, 16)],
                "upper": [(X, 18), (Y, -16)], "fore": [(X, -14)], "plumeS1": [(Y, -14)],
                "capeS1": [(Y, -10)], "capeF1": [(Y, -8)], "sword": [(X, -4)]})
    pose(c, 7, {"root@loc": (0, 0.08, 0), "spine_low": [(X, -2)], "chest": [(X, -3)], "neck": [(X, -4)],
                "head": [(X, -5), (Z, 4)], "plume1": [(X, 5)], "plume2": [(X, 8)],
                "capeB1": [(X, 3)], "capeB2": [(X, 5)], "upper": [(X, 5)]})
    rest(c, 15)
    return c.bake()


def make_cast(arm):
    # 1.2 s: rise, arms up and out, plume flares (0-12); trembling hold (12-26); release (26-36)
    c = Clip(arm, "Cast", 36)
    rest(c, 0)
    up = {"root@loc": (0, 0, 0.15), "spine_low": [(X, -3)], "chest": [(X, -5)], "neck": [(X, -8)],
          "head": [(X, -12)], "plume1": [(X, -4)], "plume2": [(X, -6)], "capeB1": [(X, 8)],
          "capeB2": [(X, 12)], "upper": [(X, -55), (Y, -30)], "fore": [(X, -45), (Y, -10)],
          "hand": [(X, -12)], "plumeS1": [(Y, 22)], "plumeS2": [(Y, 18)], "capeS1": [(Y, -14)],
          "capeS2": [(Y, -18)], "capeF1": [(Y, -12)], "board": [(Y, -10)]}
    for f, tw in ((12, 0), (16, 1), (20, -1), (24, 1), (26, 0)):
        d = dict(up)
        d["head"] = [(X, -12), (Z, 3 * tw)]
        d["hand"] = [(X, -12 + 4 * tw)]
        d["root@loc"] = (0, 0, 0.15 + 0.02 * tw)
        pose(c, f, d)
    pose(c, 30, {"root@loc": (0, -0.1, 0.0), "spine_low": [(X, 4)], "chest": [(X, 5)], "neck": [(X, 5)],
                 "head": [(X, 6)], "upper": [(X, -35), (Y, -12)], "fore": [(X, -25)]})
    rest(c, 36)
    return c.bake()


def make_roar(arm):
    # 1.6 s: rear up (0-10), roar and shake (10-36), settle (36-48)
    c = Clip(arm, "Roar", 48)
    rest(c, 0)
    pose(c, 8, {"spine_low": [(X, 4)], "chest": [(X, 6)], "neck": [(X, 8)], "head": [(X, 8)],
                "upper": [(X, 6), (Y, -12)], "plume1": [(X, 8)]})
    for f, sh in ((14, 1), (17, -1), (20, 1), (23, -1), (26, 1), (29, -1), (32, 1), (36, 0)):
        pose(c, f, {"root@loc": (0, 0.05, 0.12), "spine_low": [(X, -5)], "spine_mid": [(X, -4)],
                    "chest": [(X, -8), (Y, 3 * sh)], "neck": [(X, -10)], "head": [(X, -14), (Z, 3 * sh)],
                    "plume1": [(X, -6)], "plume2": [(X, -10), (Y, 6 * sh)],
                    "capeB1": [(X, 12)], "capeB2": [(X, 16)],
                    "upper": [(X, -25), (Y, -(28 + 3 * sh))], "fore": [(X, -35), (Y, -8)],
                    "hand": [(X, -10)], "plumeS1": [(Y, 20)], "plumeS2": [(Y, 14)],
                    "capeS1": [(Y, -(10 + 2 * sh))], "capeS2": [(Y, -12)], "capeF1": [(Y, -8)]})
    rest(c, 48)
    return c.bake()


def make_dead(arm):
    # 1.6 s: stagger back (0-8), buckle at the knees and slump forward (8-40), hold the last pose
    c = Clip(arm, "Dead", 48)
    rest(c, 0)
    pose(c, 8, {"root@loc": (0, 0.20, -0.05), "spine_low": [(X, -6)], "chest": [(X, -8), (Y, 4)],
                "neck": [(X, -12)], "head": [(X, -18), (Z, 10)], "plume1": [(X, -12)], "plume2": [(X, -16)],
                "upper": [(X, 14), (Y, 24)], "fore": [(X, -12)], "capeB1": [(X, 10)], "capeB2": [(X, 14)],
                "capeS1": [(Y, 8)], "capeF1": [(Y, 6)]})
    pose(c, 22, {"root@loc": (0, -0.12, -0.45), "spine_low": [(X, 8)], "spine_mid": [(X, 6)],
                 "chest": [(X, 5)], "neck": [(X, 8)], "head": [(X, 10)],
                 "thigh": [(X, -55)], "calf": [(X, 78)],
                 "plume1": [(X, 10)], "plume2": [(X, 16)], "upper": [(X, 20), (Y, 8)], "fore": [(X, -20)],
                 "capeB1": [(X, -8)], "capeB2": [(X, -14)], "capeS1": [(Y, -4)]})
    final = {"root@loc": (0, -0.30, -0.80), "spine_low": [(X, 14)], "spine_mid": [(X, 10)],
             "chest": [(X, 8)], "neck": [(X, 10)], "head": [(X, 16), (Z, -8)],
             "thigh": [(X, -85)], "calf": [(X, 120)],
             "plume1": [(X, 10)], "plume2": [(X, 16)], "upper": [(X, 20), (Y, 6)], "fore": [(X, -25)],
             "hand": [(X, -10)], "capeB1": [(X, -8)], "capeB2": [(X, -12)],
             "capeS1": [(Y, -6)], "capeS2": [(Y, -6)], "capeF1": [(Y, -4)]}
    pose(c, 40, final)
    pose(c, 48, final)
    return c.bake()


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.fps = FPS
    objs = import_parts(["Body", "Hair", "Mask", "Sheath"])
    for o in objs.values():
        o.data.materials[0].use_backface_culling = False
    hv = objs["Hair"].data
    for v in hv.vertices:
        v.co = HAIR_PIVOT + (v.co - HAIR_PIVOT) * HAIR_SCALE
    hv.update()
    fix_sheath_uv(objs["Sheath"])
    place_sword(objs["Sheath"])
    arm = build_armature()
    for part, o in objs.items():
        skin(part, o, arm)
    clips = [make_idle(arm), make_attack(arm), make_hit(arm), make_cast(arm), make_roar(arm), make_dead(arm)]
    if BLEND:
        os.makedirs(os.path.dirname(os.path.abspath(BLEND)), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=BLEND, compress=True, copy=True)
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs.values())
    print("PARASITE: tris %d bones %d clips %s" % (tris, len(arm.data.bones), [a.name for a in clips]))
    os.makedirs(OUT, exist_ok=True)
    glb = os.path.join(OUT, "chimera_parasite.glb")
    bpy.ops.object.select_all(action='SELECT')
    kw = dict(filepath=glb, export_format='GLB', use_selection=False, export_animations=True,
              export_animation_mode='NLA_TRACKS', export_skins=True, export_yup=True,
              export_apply=False, export_force_sampling=True, export_frame_step=1,
              export_def_bones=True, export_image_format='AUTO')
    props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
    kw = {k: v for k, v in kw.items() if k in props}
    bpy.ops.export_scene.gltf(**kw)
    print("PARASITE: wrote", glb, os.path.getsize(glb))


main()
