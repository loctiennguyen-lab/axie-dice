"""Shared helpers for the Brine (Aqua) Chimera pipeline (headless Blender 5.2).

The source is one AI-generated mesh (~485k tris, one texture). prepare_mesh() turns it into a
game mesh: collapse-decimate, unwrap the low poly, then BAKE the original colour onto it. Plain
decimation (even with UV delimit) tears the UVs and smears the painted face, baking does not.
"""
import bpy, os, sys, math, mathutils
from mathutils import Vector

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from venom_common import arg, bounds, setup_render, camera_at  # noqa: F401  (re-exported)


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


def boost_head_islands(obj, head_box, boost, ymax=0.12):
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
        if x0 <= cen.x <= x1 and z0 <= cen.z <= z1 and cen.y < ymax:
            uvs = [l[uv].uv for f in fs for l in f.loops]
            c = sum(uvs, Vector((0, 0))) / len(uvs)
            for f in fs:
                for l in f.loops:
                    l[uv].uv = c + (l[uv].uv - c) * boost
            n += 1
    bm.to_mesh(obj.data)
    bm.free()
    print("BRINE: boosted", n, "head islands of", len(groups))
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.pack_islands(rotate=False, margin=0.004, scale=True)
    bpy.ops.object.mode_set(mode='OBJECT')



def straighten(hi):
    """Defect pass (deterministic, by region). The AI mesh has the body axis at x=-0.19, the feet
    at z=-0.676 and the mace ball resting 2.5 cm BELOW the feet. Move the body axis to x=0, the
    feet to z=0, and lift the mace (the detached component right of x=0.58) onto the floor."""
    import numpy as np
    me = hi.data
    n = len(me.vertices)
    a = np.zeros(n * 3, dtype=np.float32)
    me.vertices.foreach_get("co", a)
    a = a.reshape(-1, 3)
    head = a[(a[:, 2] > 0.2) & (a[:, 2] < 0.7)]
    cx = (head[:, 0].min() + head[:, 0].max()) / 2          # tusk tip to tusk tip = body axis
    feet = a[a[:, 0] < 0.3][:, 2].min()          # the legs; the chain heap and mace lie a bit lower
    mace = a[:, 0] > 0.58
    lift = feet - a[mace][:, 2].min()
    a[mace, 2] += lift
    a[:, 0] -= cx
    a[:, 2] -= feet
    me.vertices.foreach_set("co", a.ravel())
    me.update()
    print("BRINE: axis x %.3f feet z %.3f mace lift %.3f" % (cx, feet, lift))


def chain_head_weights(low, img_node_image):
    """Vertex group 'keep' for the decimator: 1.0 on the orange chain (colour-picked from the
    source texture) and on the head/face, 0.2 elsewhere, so thin links survive."""
    import numpy as np
    me = low.data
    W, H = img_node_image.size
    px = np.zeros(W * H * 4, dtype=np.float32)
    img_node_image.pixels.foreach_get(px)
    px = px.reshape(H, W, 4)
    nl = len(me.loops)
    vi = np.zeros(nl, dtype=np.int32)
    me.loops.foreach_get("vertex_index", vi)
    uv = np.zeros(nl * 2, dtype=np.float32)
    me.uv_layers[0].data.foreach_get("uv", uv)
    uv = uv.reshape(-1, 2)
    nv = len(me.vertices)
    vuv = np.zeros((nv, 2), dtype=np.float32)
    vuv[vi] = uv
    xs = np.clip((vuv[:, 0] * (W - 1)).astype(int), 0, W - 1)
    ys = np.clip((vuv[:, 1] * (H - 1)).astype(int), 0, H - 1)
    c = px[ys, xs, :3]
    r = np.maximum(c[:, 0], 1e-4)
    orange = (c[:, 0] > 0.5) & (c[:, 1] / r > 0.3) & (c[:, 1] / r < 0.8) & (c[:, 2] / r < 0.3)
    co = np.zeros(nv * 3, dtype=np.float32)
    me.vertices.foreach_get("co", co)
    co = co.reshape(-1, 3)
    headm = (co[:, 2] > 0.75) & (np.abs(co[:, 0]) < 0.7)
    w = np.full(nv, 0.2, dtype=np.float32)
    w[orange | headm] = 1.0
    vg = low.vertex_groups.new(name="keep")
    for val in (0.2, 1.0):
        idx = np.nonzero(np.isclose(w, val))[0].tolist()
        vg.add(idx, val, 'REPLACE')
    print("BRINE: keep weights: orange %d head %d of %d" % (orange.sum(), headm.sum(), nv))


def prepare_mesh(src, ratio, tex_size, tex_out, head_box=((-0.7, 0.7), (0.75, 1.5)), head_boost=2.0):
    """Returns the low-poly mesh object (material = baked texture saved at tex_out)."""
    hi = import_src(src)
    hi.name = "Hi"
    src_img = None
    for m in hi.data.materials:
        for nd in m.node_tree.nodes:
            if nd.type == 'TEX_IMAGE' and nd.image and src_img is None:
                src_img = nd.image
    straighten(hi)
    low = hi.copy()
    low.data = hi.data.copy()
    low.name = "Brine"
    bpy.context.scene.collection.objects.link(low)
    bpy.ops.object.select_all(action='DESELECT')
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    # glTF import splits vertices at every UV seam / hard normal; collapsing those separately
    # tears cracks in the surface. Weld first.
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.remove_doubles(threshold=1e-5)
    bpy.ops.object.mode_set(mode='OBJECT')
    print("BRINE: welded verts", len(low.data.vertices), "of", len(hi.data.vertices))
    chain_head_weights(low, src_img)
    m = low.modifiers.new("D", 'DECIMATE')
    m.ratio = ratio
    m.use_collapse_triangulate = True
    m.vertex_group = "keep"
    m.vertex_group_factor = 1.0
    bpy.ops.object.modifier_apply(modifier="D")
    low.vertex_groups.clear()
    for p in low.data.polygons:
        p.use_smooth = True
    print("BRINE: decimated tris", tri_count(low))
    while len(low.data.uv_layers):
        low.data.uv_layers.remove(low.data.uv_layers[0])
    low.data.uv_layers.new(name="UVMap")
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(88), island_margin=0.003, correct_aspect=True)
    bpy.ops.object.mode_set(mode='OBJECT')
    boost_head_islands(low, head_box, head_boost, ymax=0.1)
    img = bpy.data.images.new("T_Brine", tex_size, tex_size, alpha=False)
    mat = bpy.data.materials.new("M_Brine")
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
    sc.render.bake.cage_extrusion = 0.015
    sc.render.bake.max_ray_distance = 0.06
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
