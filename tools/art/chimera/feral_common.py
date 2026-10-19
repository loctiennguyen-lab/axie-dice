"""Shared helpers for the Feral (Bird) Chimera pipeline (headless Blender 5.2).

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


def boost_islands(obj, regions):
    """Smart UV gives every triangle the same texel density, which starves the small painted
    details (face, rabbit muzzle, mouth stage, paws). Scale the UV islands whose centre sits in a
    region by that region's boost, then repack everything. regions: [((x0,x1),(y0,y1),(z0,z1),boost)]
    in mesh space (metres); first matching region wins."""
    import bmesh
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
        for (x0, x1), (y0, y1), (z0, z1), boost in regions:
            if x0 <= cen.x <= x1 and y0 <= cen.y <= y1 and z0 <= cen.z <= z1:
                uvs = [l[uv].uv for f in fs for l in f.loops]
                c = sum(uvs, Vector((0, 0))) / len(uvs)
                for f in fs:
                    for l in f.loops:
                        l[uv].uv = c + (l[uv].uv - c) * boost
                n += 1
                break
    bm.to_mesh(obj.data)
    bm.free()
    print("FERAL: boosted", n, "islands of", len(groups))
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.pack_islands(rotate=False, margin=0.004, scale=True)
    bpy.ops.object.mode_set(mode='OBJECT')


def solid_material(name, rgb):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = next(n for n in m.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
    b.inputs["Base Color"].default_value = (rgb[0], rgb[1], rgb[2], 1)
    b.inputs["Roughness"].default_value = 0.85
    return m


def prepare_mesh(src, ratio, tex_size, tex_out, patches_fn, detail_fn, regions, decimate_factor=0.0):
    """Returns the low-poly mesh object (material = baked texture saved at tex_out).
    patches_fn() -> list of extra objects (defect-fix geometry, own solid material); they are
    baked into the colour as well and joined into the low poly. detail_fn(co) -> 0..1 weight that
    keeps triangles where the painted detail is."""
    import bmesh
    hi = import_src(src)
    hi.name = "Hi"
    patches = patches_fn()
    low = hi.copy()
    low.data = hi.data.copy()
    low.name = "Feral"
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
    print("FERAL: welded verts", len(low.data.vertices), "of", len(hi.data.vertices))
    vg = low.vertex_groups.new(name="keep")
    for v in low.data.vertices:
        w = detail_fn(v.co)
        if w > 0:
            vg.add([v.index], w, 'REPLACE')
    m = low.modifiers.new("D", 'DECIMATE')
    m.ratio = ratio
    m.use_collapse_triangulate = True
    if decimate_factor > 0:
        m.vertex_group = "keep"
    m.vertex_group_factor = decimate_factor
    bpy.ops.object.modifier_apply(modifier="D")
    low.vertex_groups.clear()
    print("FERAL: decimated tris", tri_count(low))
    # the fix patches are already clean low poly: join copies of them
    bpy.ops.object.select_all(action='DESELECT')
    for pt in patches:
        c = pt.copy()
        c.data = pt.data.copy()
        bpy.context.scene.collection.objects.link(c)
        c.select_set(True)
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    bpy.ops.object.join()
    for p_ in low.data.polygons:
        p_.use_smooth = True
    # fresh UVs for the low poly
    while len(low.data.uv_layers):
        low.data.uv_layers.remove(low.data.uv_layers[0])
    low.data.uv_layers.new(name="UVMap")
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(88), island_margin=0.004, correct_aspect=True)
    bpy.ops.object.mode_set(mode='OBJECT')
    boost_islands(low, regions)
    img = bpy.data.images.new("T_Feral", tex_size, tex_size, alpha=False)
    mat = bpy.data.materials.new("M_Feral")
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
    sc.render.bake.cage_extrusion = 0.04
    sc.render.bake.max_ray_distance = 0.2
    bpy.ops.object.select_all(action='DESELECT')
    hi.select_set(True)
    for pt in patches:
        pt.select_set(True)
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    bpy.ops.object.bake(type='DIFFUSE')
    os.makedirs(os.path.dirname(os.path.abspath(tex_out)), exist_ok=True)
    img.filepath_raw = tex_out
    img.file_format = 'PNG'
    img.save()
    bpy.data.objects.remove(hi)
    for pt in patches:
        bpy.data.objects.remove(pt)
    return low
