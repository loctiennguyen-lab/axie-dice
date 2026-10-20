"""Shared helpers for the Parasite (Bug) Chimera pipeline (headless Blender 5.2).

Source: AI mesh (~780k tris, one 2048 texture). Defect fixes run on the HIGH-poly mesh before
welding/decimation, as deterministic functions of vertex position (no hand-picked indices).
"""
import bpy, os, sys, math
import numpy as np
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from venom_common import arg, bounds, setup_render, camera_at  # noqa: F401


def import_src(path):
    bpy.ops.import_scene.gltf(filepath=path)
    o = [o for o in bpy.data.objects if o.type == 'MESH'][0]
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return o


def tri_count(o):
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def get_co(me):
    a = np.empty(len(me.vertices) * 3, dtype=np.float64)
    me.vertices.foreach_get("co", a)
    return a.reshape(-1, 3)


def set_co(me, co):
    me.vertices.foreach_set("co", co.astype(np.float32).ravel())
    me.update()


def _rot_between(a, b):
    """Rotation matrix taking unit vector a to unit vector b (minimal rotation)."""
    v = np.cross(a, b)
    c = float(np.dot(a, b))
    if c < -0.999999:
        # 180 degrees: any perpendicular axis
        ax = np.cross(a, [1, 0, 0] if abs(a[0]) < 0.9 else [0, 1, 0])
        ax /= np.linalg.norm(ax)
        return 2 * np.outer(ax, ax) - np.eye(3)
    k = np.array([[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]])
    return np.eye(3) + k + k @ k / (1.0 + c)


def straighten_beak(obj, tube=0.075, base_r=0.05, length=0.5, yaw_deg=0.0, pitch_deg=-10.0,
                    axis_pt=(0.0, -0.22, 0.215), rings=48, sides=20):
    """Replace the AI nose spike (twisted ~50 deg forward, wavy, needle-thin) by ONE straight
    solid horn, as in the art: thick at the base (~1/3 of the mask width), tapering to a sharp
    tip, yellow at the base -> orange -> red at the tip, leaving the face centre and pointing to
    straight FORWARD (-Y in Blender = +Z in glTF = toward the party), centred on the face
    (yaw 0), 10 deg below horizontal, as in Bug_1.png columns 2 (front, foreshortened) and 3 (side).

    The old spike (found as the vertices inside a tube around its measured axis, in front of the
    mask) is folded back into the head (y = -0.20) so no needle remains; the new horn is a
    separate cone mesh with vertex colours, joined into the mesh (its own material slot; the
    colour is baked with everything else). Deterministic: the region is by position.
    """
    import bmesh
    me = obj.data
    co = get_co(me)
    P0 = np.array((0.09, -0.28, 0.222))
    U = np.array((0.455, -0.73, 0.337)) - P0
    Ulen = np.linalg.norm(U)
    U /= Ulen
    rel = co - P0
    s_ax = rel @ U
    dist = np.linalg.norm(rel - np.outer(s_ax, U), axis=1)
    sel = (dist < tube) & (s_ax > 0.0) & (s_ax < Ulen * 1.08) & (co[:, 1] < -0.30)
    print("PARASITE beak: old spike verts folded into head", int(sel.sum()))
    co[sel, 1] = -0.20
    # shave the stub where the spike met the mask (a ring that still pokes out ~2 cm): clamp the
    # surface around the old root back to y >= -0.255 so the new horn sits in a clean socket
    near = np.linalg.norm(co - np.array((0.09, -0.285, 0.222)), axis=1) < 0.085
    co[near, 1] = np.maximum(co[near, 1], -0.255)
    set_co(me, co)
    # --- new horn
    yaw, pitch = math.radians(yaw_deg), math.radians(pitch_deg)
    D = Vector((math.cos(pitch) * math.sin(yaw), -math.cos(pitch) * math.cos(yaw), math.sin(pitch)))
    A = Vector(axis_pt)
    N = D.cross(Vector((0, 0, 1))).normalized()
    Bv = D.cross(N).normalized()
    s0 = -0.075                  # base buried inside the head
    L = -s0 + length
    bm = bmesh.new()
    col = bm.loops.layers.color.new("Col")
    ring_verts = []
    for r_i in range(rings):
        u = r_i / (rings - 1)
        sp = s0 + u * L
        rad = base_r * max(1.0 - u, 0.0) ** 0.85
        if r_i == rings - 1:
            ring_verts.append([bm.verts.new(A + D * sp)])
            continue
        ring = []
        for k in range(sides):
            a = 2 * math.pi * k / sides
            ring.append(bm.verts.new(A + D * sp + (N * math.cos(a) + Bv * math.sin(a)) * rad))
        ring_verts.append(ring)
    for r_i in range(rings - 1):
        a, b = ring_verts[r_i], ring_verts[r_i + 1]
        for k in range(sides):
            k2 = (k + 1) % sides
            if len(b) == 1:
                bm.faces.new((a[k], a[k2], b[0]))
            else:
                bm.faces.new((a[k], a[k2], b[k2], b[k]))
    bm.faces.new(ring_verts[0][::-1])
    bm.normal_update()

    def ramp(u):   # linear colours: yellow base -> orange -> red tip
        stops = [(0.0, (1.0, 0.80, 0.05)), (0.22, (1.0, 0.70, 0.04)),
                 (0.55, (1.0, 0.30, 0.03)), (1.0, (0.85, 0.07, 0.02))]
        for (u0, c0), (u1, c1) in zip(stops, stops[1:]):
            if u <= u1:
                t = (u - u0) / (u1 - u0)
                return tuple(c0[i] + (c1[i] - c0[i]) * t for i in range(3)) + (1.0,)
        return stops[-1][1] + (1.0,)
    for f in bm.faces:
        for l in f.loops:
            u = max(0.0, min(1.0, ((l.vert.co - A).dot(D) - s0) / L))
            l[col] = ramp(u)
        f.smooth = True
    hm = bpy.data.meshes.new("HornMesh")
    bm.to_mesh(hm)
    bm.free()
    horn = bpy.data.objects.new("Horn", hm)
    bpy.context.scene.collection.objects.link(horn)
    mat = bpy.data.materials.new("M_Horn")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    cn = nt.nodes.new("ShaderNodeVertexColor")
    cn.layer_name = hm.color_attributes[0].name
    nt.links.new(cn.outputs["Color"], bsdf.inputs["Base Color"])
    hm.materials.append(mat)
    bpy.ops.object.select_all(action='DESELECT')
    horn.select_set(True)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.join()
    print("PARASITE beak: horn added, tip", tuple(round(v, 3) for v in (A + D * (s0 + L))))
    return int(sel.sum())


def boost_head_islands(obj, head_box, boost):
    """Smart UV gives every triangle the same texel density, which starves the small painted
    face. Scale the UV islands that sit in head_box ((xmin,xmax)-style: ((x0,x1),(z0,z1)) in
    metres, mesh space) up by `boost`, then repack everything."""
    import bmesh
    (x0, x1), (z0, z1) = head_box
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    uv = bm.loops.layers.uv.active
    bm.faces.ensure_lookup_table()
    parent = list(range(len(bm.faces)))

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a
    for e in bm.edges:
        fs = e.link_faces
        if len(fs) != 2:
            continue
        a, b = fs
        ok = True
        for v in e.verts:
            la = next(l for l in a.loops if l.vert == v)
            lb = next(l for l in b.loops if l.vert == v)
            if (la[uv].uv - lb[uv].uv).length > 1e-5:
                ok = False
                break
        if ok:
            parent[find(a.index)] = find(b.index)
    groups = {}
    for f in bm.faces:
        groups.setdefault(find(f.index), []).append(f)
    n = 0
    for fs in groups.values():
        cen = sum((f.calc_center_median() for f in fs), Vector()) / len(fs)
        if x0 <= cen.x <= x1 and z0 <= cen.z <= z1 and cen.y < 0.12:
            uvs = [l[uv].uv for f in fs for l in f.loops]
            c = sum(uvs, Vector((0, 0))) / len(uvs)
            for f in fs:
                for l in f.loops:
                    l[uv].uv = c + (l[uv].uv - c) * boost
            n += 1
    bm.to_mesh(obj.data)
    bm.free()
    print("PARASITE: boosted", n, "head islands of", len(groups))
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.pack_islands(rotate=False, margin=0.004, scale=True)
    bpy.ops.object.mode_set(mode='OBJECT')


def prepare_mesh(src, ratio, tex_size, tex_out, head_box=((-0.2, 0.55), (0.88, 1.2)), head_boost=2.4):
    """Returns the low-poly mesh object (material = baked texture saved at tex_out)."""
    hi = import_src(src)
    hi.name = "Hi"
    straighten_beak(hi)
    co = get_co(hi.data)
    co[:, 2] -= co[:, 2].min()   # feet/cape hem on the floor (z = 0)
    set_co(hi.data, co)
    low = hi.copy()
    low.data = hi.data.copy()
    low.name = "Parasite"
    bpy.context.scene.collection.objects.link(low)
    bpy.ops.object.select_all(action='DESELECT')
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    # glTF import splits vertices at every UV seam / hard normal; collapsing those separately
    # tears cracks in the surface. Weld first (UVs stay per-corner, they are rebuilt anyway).
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=1e-5)
    bpy.ops.object.mode_set(mode='OBJECT')
    print("PARASITE: welded verts", len(low.data.vertices), "of", len(hi.data.vertices))
    m = low.modifiers.new("D", 'DECIMATE')
    m.ratio = ratio
    m.use_collapse_triangulate = True
    bpy.ops.object.modifier_apply(modifier="D")
    for p in low.data.polygons:
        p.use_smooth = True
    # fresh UVs for the low poly
    while len(low.data.uv_layers):
        low.data.uv_layers.remove(low.data.uv_layers[0])
    low.data.uv_layers.new(name="UVMap")
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(88), island_margin=0.004, correct_aspect=True)
    bpy.ops.object.mode_set(mode='OBJECT')
    boost_head_islands(low, head_box, head_boost)
    # bake target
    img = bpy.data.images.new("T_Parasite", tex_size, tex_size, alpha=False)
    mat = bpy.data.materials.new("M_Parasite")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    node = nt.nodes.new("ShaderNodeTexImage")
    node.image = img
    nt.links.new(node.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.85
    bsdf.inputs["Metallic"].default_value = 0.0
    nt.nodes.active = node
    low.data.materials.clear()
    low.data.materials.append(mat)
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.device = 'CPU'
    sc.cycles.samples = 1
    sc.render.bake.use_pass_direct = False
    sc.render.bake.use_pass_indirect = False
    sc.render.bake.use_pass_color = True
    sc.render.bake.margin = 10
    sc.render.bake.use_selected_to_active = True
    sc.render.bake.cage_extrusion = 0.03
    sc.render.bake.max_ray_distance = 0.12
    bpy.ops.object.select_all(action='DESELECT')
    hi.select_set(True)
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    bpy.ops.object.bake(type='DIFFUSE')
    os.makedirs(os.path.dirname(os.path.abspath(tex_out)), exist_ok=True)
    img.filepath_raw = tex_out
    img.file_format = 'PNG'
    img.save()
    bpy.data.objects.remove(hi)
    return low
