"""Parasite (Bug) Chimera: AI mesh -> defect fixes -> game mesh -> rig -> skin -> 6 clips -> GLB.

Headless and reproducible:
  Blender -b --factory-startup -P tools/art/chimera/build_parasite.py -- \
      --src "<.../Parasite (Bug)/3D/parasite_ai.glb>" --out godot/assets/bosses/chimera_parasite
Options: --blend <file.blend> saves the rigged source; --cache <dir> reuses/creates the baked
low-poly (decimate + bake is the slow part); --ratio 0.03 (decimate); --tex 2048.

Defect pass (parasite_common.straighten_beak): the AI nose spike was twisted ~50 degrees forward
and wavy; it is re-framed along a straight line pointing to the creature's left (screen right in
front view), 12 deg forward-yaw and 12 deg up, with a clean monotone taper. The mesh is then
dropped so the cape hem / feet sit on z = 0 (standing, no hover).

Blender space: metres, Z up, the creature faces -Y. Floor at z = 0; height ~1.47, sword 1.9 wide.
"""
import bpy, os, sys, math
import numpy as np
from mathutils import Vector, Quaternion
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from parasite_common import *

# --src / --out defaults below are machine-local (Liam's checkout, /tmp); pass both when running elsewhere.
SRC = arg("src", "/Users/loc.tien.nguyen/my-game/asset-library/chimera-src/Parasite (Bug)/3D/parasite_ai.glb")
OUT = arg("out", "/tmp/parasite")
BLEND = arg("blend")
CACHE = arg("cache")
RATIO = float(arg("ratio", "0.03"))
TEX = int(arg("tex", "2048"))
FPS = 30
F = 0.736   # floor offset: source z -0.736 -> 0


def bz(p):
    return (p[0], p[1], p[2] + F)


# name, head, tail (source coords), parent
BONES = [
    ("root",      (0, -0.10, -0.736), (0, -0.10, -0.60), None),
    ("hips",      (0, -0.12, -0.45),  (0, -0.12, -0.30), "root"),
    ("chest",     (0, -0.12, -0.30),  (0, -0.12, 0.0),   "hips"),
    ("neck",      (0, -0.14, 0.0),    (0, -0.17, 0.14),  "chest"),
    ("head",      (0, -0.17, 0.14),   (0, -0.17, 0.72),  "neck"),
    ("arm1.L",    (0.14, -0.12, -0.02), (0.36, -0.14, -0.28), "chest"),
    ("arm2.L",    (0.36, -0.14, -0.28), (0.41, -0.17, -0.52), "arm1.L"),
    ("thigh.L",   (0.09, -0.12, -0.45), (0.14, -0.14, -0.60), "hips"),
    ("foot.L",    (0.14, -0.14, -0.60), (0.17, -0.20, -0.72), "thigh.L"),
    ("sidecape.L", (0.45, 0.0, -0.15), (0.62, 0.0, -0.70), "chest"),
    ("cape1",     (0, 0.05, -0.05),   (0, 0.25, -0.40),  "chest"),
    ("cape2",     (0, 0.25, -0.40),   (0, 0.45, -0.72),  "cape1"),
]
SWORD_A = np.array([-0.94, -0.20, 0.22])
SWORD_B = np.array([0.94, 0.69, -0.22])


def mirrored(bones):
    out = []
    for n, h, t, p in bones:
        out.append((n, bz(h), bz(t), p))
        if n.endswith(".L"):
            out.append((n[:-2] + ".R", bz((-h[0], h[1], h[2])), bz((-t[0], t[1], t[2])),
                        p[:-2] + ".R" if p and p.endswith(".L") else p))
    return out


BONES = mirrored(BONES)


def build_armature():
    data = bpy.data.armatures.new("ParasiteRig")
    arm = bpy.data.objects.new("ParasiteRig", data)
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
    """p in SOURCE coords (floor offset removed)."""
    ax = abs(p.x)
    base = n.split(".")[0]
    if n.endswith(".L") and p.x < -0.04:
        return False
    if n.endswith(".R") and p.x > 0.04:
        return False
    if base in ("arm1", "arm2"):
        return ax > 0.16 and -0.62 < p.z < 0.0 and p.y < 0.12
    if base == "sidecape":
        return ax > 0.33 and p.z < -0.08
    if base in ("cape1", "cape2"):
        return p.y > 0.0 and p.z < 0.0 and ax < 0.62
    if base in ("thigh", "foot"):
        return p.z < -0.40 and ax < 0.30 and p.y < 0.0
    if base == "head":
        return p.z > 0.08
    if base == "neck":
        return -0.10 < p.z < 0.24 and ax < 0.25
    if base == "hips":
        return p.z < -0.18 and ax < 0.35
    return True


ARM_COLOR = [0.55, 0.12, 0.08]   # filled by split_hands: mean linear red of the body/arm texture
HAND_COLOR = [0.3, 0.7, 0.7]   # filled by split_hands: mean linear colour of the hand texture


def is_cyan(c):
    """c: linear RGB mean of a face's baked texture. Hands/feet/hair/sword are cyan, cape is red/orange."""
    return (c[1] + c[2]) * 0.5 - c[0] > 0.22 and c[2] > 0.35


def split_hands(obj):
    """Cut the cyan hands off the red cape. Faces whose baked colour is cyan and that sit in the
    hand zone become 'hand'; the edge loop between hand and the rest is split (duplicated verts),
    so the cape no longer shares vertices with the hand. The cape-side holes are capped with flat patches. Returns the set of hand vertex indices (after split).
    Deterministic: colour + position only, no hand-picked indices."""
    import bmesh
    img = bpy.data.images["T_Parasite"]
    w, h = img.size
    px = np.empty(w * h * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    px = px.reshape(h, w, 4)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    uv = bm.loops.layers.uv.active
    bm.faces.ensure_lookup_table()
    cyan = set()
    partial = set()
    cols = {}
    for f in bm.faces:
        us = [l[uv].uv for l in f.loops]
        c = sum(us, Vector((0, 0))) / len(us)
        col = np.mean([px[min(h - 1, int(q.y * h)), min(w - 1, int(q.x * w)), :3] for q in us + [c]], axis=0)
        if is_cyan(col):
            cyan.add(f.index)
            cols[f.index] = col
        elif any((q_[1] + q_[2]) * 0.5 - q_[0] > 0.12 and q_[2] > 0.3 for q_ in
                 (px[min(h - 1, int(q.y * h)), min(w - 1, int(q.x * w)), :3] for q in us + [c])):
            partial.add(f.index)     # cape faces that only touch cyan texels (edge bleed)
    # connected cyan pieces; a piece is "hand" when its whole bounding box sits in the hand zone
    # (|x| > 0.2, -0.66 < z < -0.15, y < 0): that keeps the sword, hair, feet and shoulder trim out.
    seen, hand = set(), set()
    for fi in sorted(cyan):
        if fi in seen:
            continue
        comp, stack = [], [fi]
        seen.add(fi)
        while stack:
            a = stack.pop()
            comp.append(a)
            for e in bm.faces[a].edges:
                for g in e.link_faces:
                    if g.index in cyan and g.index not in seen:
                        seen.add(g.index)
                        stack.append(g.index)
        pts = np.array([[*(v.co - Vector((0, 0, F)))] for a in comp for v in bm.faces[a].verts])
        lo, hi = pts.min(0), pts.max(0)
        if len(comp) >= 5 and min(abs(lo[0]), abs(hi[0])) > 0.2 and lo[0] * hi[0] > 0 \
                and lo[2] > -0.66 and hi[2] < -0.15 and hi[1] < 0.0:
            hand.update(comp)
    reds = []
    red_uvs = []
    for f in bm.faces:
        p_ = f.calc_center_median() - Vector((0, 0, F))
        if 0.08 < abs(p_.x) < 0.3 and -0.3 < p_.z < 0.0 and p_.y < 0.0:
            us = [l[uv].uv for l in f.loops]
            c_ = np.mean([px[min(h - 1, int(q.y * h)), min(w - 1, int(q.x * w)), :3] for q in us], axis=0)
            if c_[0] > 0.45 and c_[1] < 0.3 and c_[2] < 0.25:
                reds.append(c_)
                red_uvs.append(sum(us, Vector((0, 0))) / len(us))
    if reds:
        ARM_COLOR[:] = np.mean(reds, axis=0).tolist()
    print("PARASITE arm red from", len(reds), "faces", [round(x, 2) for x in ARM_COLOR])
    HAND_COLOR[:] = np.mean([cols[i] for i in hand], axis=0).tolist()
    edges = [e for e in bm.edges if len(e.link_faces) == 2
             and ((e.link_faces[0].index in hand) != (e.link_faces[1].index in hand))]
    print("PARASITE hands: faces %d, boundary edges %d" % (len(hand), len(edges)))
    hand_idx = set(hand)
    for f in bm.faces:
        f.tag = f.index in hand_idx
    cyan_faces = {bm.faces[i] for i in cyan | partial}
    cut_pos = {tuple(round(c, 5) for c in v.co) for e in edges for v in e.verts}
    bmesh.ops.split_edges(bm, edges=edges)
    bm.verts.ensure_lookup_table()
    bm.faces.ensure_lookup_table()
    hv = set()
    for f in bm.faces:
        if f.tag:
            for v in f.verts:
                hv.add(v.index)
    # --- cleanup of what the cut left on the cape side
    def in_cape_zone(p):
        return abs(p.x) > 0.12 and -0.66 < p.z < -0.1 and p.y < 0.1
    hand_faces = {f for f in bm.faces if f.tag}
    # (a) loose islands: tiny connected pieces in the cape zone are deleted
    seen_f, kill = set(), []
    for f0 in bm.faces:
        if f0 in seen_f or f0 in hand_faces:
            continue
        comp, stack = [], [f0]
        seen_f.add(f0)
        while stack:
            a = stack.pop()
            comp.append(a)
            for e in a.edges:
                for g in e.link_faces:
                    if g not in seen_f and g not in hand_faces:
                        seen_f.add(g)
                        stack.append(g)
        if len(comp) < 40 and all(in_cape_zone(f.calc_center_median() - Vector((0, 0, F))) for f in comp):
            kill.extend(comp)
    if kill:
        bmesh.ops.delete(bm, geom=kill, context='FACES_ONLY')
        bm.faces.ensure_lookup_table()
    print("PARASITE cleanup: loose faces deleted", len(kill))
    # (b) hand-cyan texels left on the cape: copy the neighbouring cape colour (flat UV) so no cyan shard remains
    todo = {f for f in cyan_faces if f.is_valid and f not in hand_faces
            and in_cape_zone(f.calc_center_median() - Vector((0, 0, F)))}
    n_re = len(todo)
    for _ in range(8):
        if not todo:
            break
        done = []
        for f in todo:
            ref = None
            for v in f.verts:
                for g in v.link_faces:
                    if g is not f and g not in todo and g not in hand_faces and g not in cyan_faces:
                        us = [l[uv].uv for l in g.loops]
                        ref = sum(us, Vector((0, 0))) / len(us)
                        break
                if ref is not None:
                    break
            if ref is not None:
                for l in f.loops:
                    l[uv].uv = ref
                done.append(f)
        todo.difference_update(done)
    print("PARASITE cleanup: cyan cape faces recoloured", n_re - len(todo), "left", len(todo))
    # tuck: cap the matching holes left in the cape (static, cape-weighted) so no see-through gap opens
    crim = [e for e in bm.edges if e.is_boundary and not any(v.index in hv for v in e.verts)
            and all(tuple(round(c, 5) for c in v.co) in cut_pos for v in e.verts)]
    if crim:
        res = bmesh.ops.triangle_fill(bm, edges=crim, use_beauty=True)
        for f in res["geom"]:
            if isinstance(f, bmesh.types.BMFace):
                f.smooth = True
                ref = None
                for l in f.loops:       # one flat colour per patch: the first rim vertex's cape texel
                    for ol in l.vert.link_loops:
                        if ol.face is not f:
                            ref = ol[uv].uv.copy()
                            break
                    if ref is not None:
                        break
                for l in f.loops:
                    l[uv].uv = ref if ref is not None else l[uv].uv
    print("PARASITE cape holes capped: rim edges", len(crim))
    # (c) straighten the cape-side cut: smooth the rim vertices along the cut (two passes)
    rim_v = {v for e in crim for v in e.verts}
    for _ in range(2):
        newp = {}
        for v in rim_v:
            nb = [o for e in v.link_edges if e.is_boundary for o in (e.other_vert(v),) if o in rim_v]
            if len(nb) >= 2:
                newp[v] = v.co * 0.5 + sum((o.co for o in nb), Vector()) / len(nb) * 0.5
        for v, c in newp.items():
            v.co = c
    bm.verts.ensure_lookup_table()
    bm.edges.index_update()
    bm.faces.index_update()
    # the top of each hand piece is really forearm: paint it body-red so only the claws read cyan
    if red_uvs:
        ref_uv = sorted(red_uvs, key=lambda q: (q.x, q.y))[len(red_uvs) // 2]
        n_fore = 0
        for sg in (1, -1):
            fs = [f for f in bm.faces if f.tag and sg * f.calc_center_median().x > 0.15]
            if not fs:
                continue
            ztop = max(v.co.z for f in fs for v in f.verts)
            for f in fs:
                if f.calc_center_median().z > ztop - 0.18:
                    for l in f.loops:
                        l[uv].uv = ref_uv
                    n_fore += 1
        print("PARASITE forearm faces painted red:", n_fore)
    # the real forearm is hidden under the cape in the AI mesh, so a raised hand would float: add a
    # slim tapered cyan arm from each shoulder to the wrist (top of the hand piece)
    tube = set()
    bm.verts.ensure_lookup_table()
    mat_idx = len(obj.data.materials)
    for side, sg in (("L", 1), ("R", -1)):
        bm.verts.ensure_lookup_table()
        hp = [bm.verts[i] for i in hv if sg * (bm.verts[i].co.x) > 0.15]
        if not hp:
            continue
        zs = sorted(v.co.z for v in hp)
        top = [v.co for v in hp if v.co.z >= zs[int(len(zs) * 0.9)]]
        wrist = sum(top, Vector()) / len(top) - Vector((0, 0, 0.01))   # tube ends just inside the hand: cyan starts at the wrist
        sh = Vector(next(h_ for n_, h_, t_, p_ in BONES if n_ == "arm1." + side))
        d = wrist - sh
        d_n = d.normalized()
        n1 = d_n.cross(Vector((0, 1, 0))).normalized()
        n2 = d_n.cross(n1).normalized()
        rings, sides = 7, 8
        rv = []
        for r_i in range(rings):
            u = r_i / (rings - 1)
            c = sh + d * u
            rad = 0.042 - 0.014 * u
            ring = [bm.verts.new(c + (n1 * math.cos(2 * math.pi * k / sides) + n2 * math.sin(2 * math.pi * k / sides)) * rad)
                    for k in range(sides)]
            rv.append(ring)
        for r_i in range(rings - 1):
            for k in range(sides):
                k2 = (k + 1) % sides
                f = bm.faces.new((rv[r_i][k], rv[r_i][k2], rv[r_i + 1][k2], rv[r_i + 1][k]))
                f.material_index = mat_idx
                f.smooth = True
        cap = bm.faces.new(rv[0][::-1])
        cap.material_index = mat_idx
        for ring in rv:
            tube.update(v.index for v in ring)
    bm.to_mesh(obj.data)
    bm.free()
    m = bpy.data.materials.new("M_Forearm")   # red like the body; only the hands are cyan
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = tuple(ARM_COLOR) + (1.0,)
    b.inputs["Roughness"].default_value = 0.85
    obj.data.materials.append(m)
    obj.data.update()
    return hv, tube


def skin(obj, arm):
    hands, tube = split_hands(obj)
    segs = {n: (Vector(h), Vector(t)) for n, h, t, p in BONES}
    names = [n for n, _, _, _ in BONES if n != "root"]
    for n in names:
        obj.vertex_groups.new(name=n)
    me = obj.data
    A, B = Vector(SWORD_A), Vector(SWORD_B)
    for v in me.vertices:
        p = v.co - Vector((0, 0, F))
        if seg_dist(p, A, B) < 0.17 and p.y > 0.0:      # the huge sword rides the chest rigidly
            obj.vertex_groups["chest"].add([v.index], 1.0, 'REPLACE')
            continue
        if v.index in tube:                              # forearm tube: upper arm bone only
            obj.vertex_groups[("arm1.L" if v.co.x > 0 else "arm1.R")].add([v.index], 1.0, 'REPLACE')
            continue
        if v.index in hands:                             # hands are rigid on the forearm bone: nothing to stretch
            obj.vertex_groups[("arm2.L" if v.co.x > 0 else "arm2.R")].add([v.index], 1.0, 'REPLACE')
            continue
        ws = []
        is_hand = v.index in hands
        for n in names:
            if not gate(n, p):
                continue
            base = n.split(".")[0]
            if is_hand and base not in ("arm1", "arm2"):
                continue                      # hands follow only arm bones
            if not is_hand and base == "arm2":
                continue                      # cape / body never follows the forearm
            if not is_hand and base == "arm1" and seg_dist(v.co, Vector(segs[n][0]), Vector(segs[n][0])) > 0.12:
                continue                      # ...and only follows the upper arm right at the shoulder
            a, b = segs[n]
            ws.append((1.0 / (seg_dist(v.co, a, b) + 0.03) ** 4, n))
        if not ws:
            ws = [(1.0, "chest")]
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
# Animation. Rotations are (armature-space axis, degrees). Creature faces -Y: +X tips the top
# forward. Arms hang down: -X swings them forward, L (x>0) raises outward with -Y, R with +Y.
# ---------------------------------------------------------------------------------------------
X, Y, Z = Vector((1, 0, 0)), Vector((0, 1, 0)), Vector((0, 0, 1))


def local_q(arm, bone, rots):
    Bm = arm.data.bones[bone].matrix_local.to_3x3()
    q = Quaternion()
    for axis, deg in rots:
        q = Quaternion(axis, math.radians(deg)) @ q
    return (Bm.inverted() @ q.to_matrix() @ Bm).to_quaternion()


def iter_fcurves(act):
    if hasattr(act, "fcurves") and len(getattr(act, "fcurves", [])):
        yield from act.fcurves
        return
    for layer in getattr(act, "layers", []):
        for strip in layer.strips:
            for bag in strip.channelbags:
                yield from bag.fcurves


ALL = [b for b, _, _, _ in BONES]


class Clip:
    def __init__(self, arm, name, frames):
        self.arm, self.name, self.frames = arm, name, frames
        self.keys = {}

    def k(self, f, bone, rots=(), loc=None):
        self.keys.setdefault(bone, {})[f] = (list(rots), loc)

    def pose(self, f, d=None, off=(0, 0, 0)):
        """Keys every bone at frame f; d: bone -> rots. off: root offset in metres."""
        d = d or {}
        for b in ALL:
            if b == "root":
                self.k(f, "root", d.get("root", []), off)
            else:
                self.k(f, b, d.get(b, []))

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
                    Bm = arm.data.bones[bone].matrix_local.to_3x3()
                    pb.location = Bm.inverted() @ Vector(loc)
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


def arms(sg_up=0.0, fwd=0.0, el=0.0, l=None, r=None):
    """Both arms: up = outward raise, fwd = swing forward (neg X), el = elbow bend forward.
    l / r override as (up, fwd, el)."""
    out = {}
    for side, sg, ov in (("L", 1, l), ("R", -1, r)):
        u, f_, e = ov if ov else (sg_up, fwd, el)
        out["arm1." + side] = [(X, -f_), (Y, -sg * u)]
        out["arm2." + side] = [(X, -e), (Y, -sg * u * 0.3)]
    return out


def cape(d, a, b=None, side=0.0):
    b = a * 1.6 if b is None else b
    d["cape1"] = [(X, a)]
    d["cape2"] = [(X, b)]
    d["sidecape.L"] = [(Y, -side)]
    d["sidecape.R"] = [(Y, side)]
    return d


def make_idle(arm):
    n = 48
    c = Clip(arm, "Idle", n)
    for i in range(0, n + 1, 4):
        s = lambda a, ph=0.0: sn(i, n, a, ph)
        d = {"chest": [(X, s(1.6)), (Z, s(1.5, 1.0))], "neck": [(X, s(-1.2, 0.6))],
             "head": [(X, s(2.0, 0.9)), (Z, s(3.0, 1.9))], "hips": [(Z, s(-1.0, 1.0))]}
        d.update(arms(sg_up=3 + s(2.0, 0.5), fwd=s(3, 0.3), el=6 + s(3, 0.8)))
        cape(d, s(3.0, -0.7), s(5.5, -1.3), side=s(2.5, -0.5))
        c.pose(i, d, off=(0, 0, s(0.008, 0.2)))
    return c.bake()


def make_attack(arm):
    c = Clip(arm, "Attack", 30)
    c.pose(0, cape({}, 0), (0, 0, 0))
    d = {"chest": [(X, -10), (Z, 12)], "head": [(X, -8)], "hips": [(Z, 8)]}
    d.update(arms(l=(25, -40, 30), r=(40, 55, 40)))
    c.pose(9, cape(d, 8, 14, 4), (0, 0.10, 0))
    d = {"chest": [(X, 20), (Z, -16)], "head": [(X, 14)], "hips": [(X, 6), (Z, -8)],
         "thigh.L": [(X, -14)], "thigh.R": [(X, 10)]}
    d.update(arms(l=(10, 80, 35), r=(14, 85, 40)))
    c.pose(14, cape(d, -16, -28, 6), (0, -0.30, -0.04))
    d = {"chest": [(X, 14), (Z, -10)], "head": [(X, 10)], "hips": [(X, 4)]}
    d.update(arms(l=(10, 60, 25), r=(12, 65, 28)))
    c.pose(19, cape(d, -8, -14, 4), (0, -0.26, -0.03))
    c.pose(30, cape({}, 0), (0, 0, 0))
    return c.bake()


def make_hit(arm):
    c = Clip(arm, "Hit", 15)
    c.pose(0, cape({}, 0))
    d = {"chest": [(X, -12), (Y, 6)], "neck": [(X, -8)], "head": [(X, -18), (Z, 14)], "hips": [(X, -4)]}
    d.update(arms(sg_up=18, fwd=-14, el=8))
    c.pose(3, cape(d, 14, 22, 6), (0, 0.18, 0))
    d = {"chest": [(X, -3)], "head": [(X, -5), (Z, 4)]}
    d.update(arms(sg_up=8, el=6))
    c.pose(7, cape(d, 4, 6, 2), (0, 0.06, 0))
    c.pose(11, cape({"head": [(X, 2)]}, -3, -5), (0, 0.01, 0))
    c.pose(15, cape({}, 0))
    return c.bake()


def make_cast(arm):
    c = Clip(arm, "Cast", 36)
    c.pose(0, cape({}, 0))
    base = {"chest": [(X, -6)], "neck": [(X, -8)], "head": [(X, -14)]}
    for f, tw in ((12, 0), (16, 1), (20, -1), (24, 1), (26, 0)):
        d = dict(base)
        d["head"] = [(X, -14), (Z, 3 * tw)]
        d.update(arms(sg_up=62 + 4 * tw, fwd=-10, el=18))
        c.pose(f, cape(d, 6 + tw, 10, 3), (0, 0, 0.01 * tw))
    d = {"chest": [(X, 4)], "head": [(X, 5)]}
    d.update(arms(sg_up=40, el=10))
    c.pose(31, cape(d, -3, -5))
    c.pose(36, cape({}, 0))
    return c.bake()


def make_roar(arm):
    c = Clip(arm, "Roar", 48)
    c.pose(0, cape({}, 0))
    d = {"chest": [(X, -14)], "neck": [(X, -10)], "head": [(X, -26)]}
    d.update(arms(sg_up=30, fwd=-12, el=10))
    c.pose(10, cape(d, 8, 14, 5), (0, 0.05, 0))
    for f, sh in ((14, 1), (17, -1), (20, 1), (23, -1), (26, 1), (29, -1), (32, 1), (36, 0)):
        d = {"chest": [(X, 8), (Y, 3 * sh)], "neck": [(X, 14)], "head": [(X, 22), (Z, 5 * sh)]}
        d.update(arms(sg_up=40 + 5 * sh, fwd=15, el=25))
        c.pose(f, cape(d, -8 + 3 * sh, -14, 6), (0.02 * sh, -0.14, 0))
    c.pose(48, cape({}, 0))
    return c.bake()


def make_dead(arm):
    c = Clip(arm, "Dead", 54)
    c.pose(0, cape({}, 0))
    d = {"chest": [(X, -8)], "head": [(X, -14), (Z, 10)]}
    d.update(arms(sg_up=15, fwd=-10))
    c.pose(6, cape(d, 8, 14), (0, 0.10, 0))
    d = {"chest": [(X, 20)], "hips": [(X, 14)], "neck": [(X, 12)], "head": [(X, 18), (Z, -8)],
         "thigh.L": [(X, -34)], "thigh.R": [(X, -34)], "foot.L": [(X, 24)], "foot.R": [(X, 24)]}
    d.update(arms(sg_up=18, fwd=20, el=20))
    c.pose(18, cape(d, -10, -18, 6), (0, -0.08, -0.22))
    fin = {"chest": [(X, 26)], "hips": [(X, 14)], "neck": [(X, 18)], "head": [(X, 28), (Z, -10)],
           "thigh.L": [(X, -44)], "thigh.R": [(X, -40)], "foot.L": [(X, 32)], "foot.R": [(X, 30)]}
    fin.update(arms(sg_up=22, fwd=34, el=28))
    c.pose(30, cape(dict(fin), -14, -24, 8), (0, -0.10, -0.30))
    for f in (40, 54):
        c.pose(f, cape(dict(fin), -12, -20, 7), (0, -0.10, -0.30))
    return c.bake()


def main():
    cache_blend = os.path.join(CACHE, "parasite_low.blend") if CACHE else None
    if cache_blend and os.path.exists(cache_blend):
        bpy.ops.wm.open_mainfile(filepath=cache_blend)
        low = bpy.data.objects["Parasite"]
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        tex_tmp = os.path.join(CACHE or "/tmp", "T_Parasite_bake.png")
        low = prepare_mesh(SRC, RATIO, TEX, tex_tmp)
        if cache_blend:
            os.makedirs(CACHE, exist_ok=True)
            bpy.data.images["T_Parasite"].pack()
            bpy.ops.wm.save_as_mainfile(filepath=cache_blend, copy=True)
    bpy.context.scene.render.fps = FPS
    arm = build_armature()
    skin(low, arm)
    clips = [make_idle(arm), make_attack(arm), make_hit(arm), make_cast(arm), make_roar(arm), make_dead(arm)]
    if BLEND:
        os.makedirs(os.path.dirname(os.path.abspath(BLEND)), exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=BLEND, compress=True, copy=True)
    print("PARASITE: tris %d bones %d clips %s" % (tri_count(low), len(arm.data.bones), [a.name for a in clips]))
    os.makedirs(OUT, exist_ok=True)
    glb = os.path.join(OUT, "chimera_parasite.glb")
    bpy.ops.object.select_all(action='SELECT')
    kw = dict(filepath=glb, export_format='GLB', use_selection=False, export_animations=True,
              export_animation_mode='NLA_TRACKS', export_skins=True, export_yup=True,
              export_apply=False, export_force_sampling=True, export_frame_step=1,
              export_def_bones=True, export_image_format='JPEG', export_jpeg_quality=90)
    props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
    kw = {k: v for k, v in kw.items() if k in props}
    bpy.ops.export_scene.gltf(**kw)
    print("PARASITE: wrote", glb, os.path.getsize(glb))


main()
