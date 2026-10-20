"""Shared helpers for the Tempest (Bird) Chimera pipeline (headless Blender 5.2).

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
    print("TEMPEST: boosted", n, "head islands of", len(groups))
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.pack_islands(rotate=False, margin=0.004, scale=True)
    bpy.ops.object.mode_set(mode='OBJECT')


def prepare_mesh(src, ratio, tex_size, tex_out, head_box=((-0.28, 0.28), (0.10, 0.5)), head_boost=2.6, head_share=0.42):
    """Returns the low-poly mesh object (material = baked texture saved at tex_out)."""
    hi = import_src(src)
    hi.name = "Hi"
    low = hi.copy()
    low.data = hi.data.copy()
    low.name = "Tempest"
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
    print("TEMPEST: welded verts", len(low.data.vertices), "of", len(hi.data.vertices))
    # Two-zone decimate with the edit-mode operator (it only touches the selection, so the zones
    # stay welded): the head zone (face, mask, gem, crest, arrows) keeps ~HEAD_TRIS, the rest
    # collapses to the remaining budget. A whole-mesh ratio smears the painted face.
    import bmesh
    total_budget = int(484604 * ratio)

    def in_head(p):
        return p.z > 0.10 and abs(p.x) < 0.28
    bm = bmesh.new()
    bm.from_mesh(low.data)
    bm.faces.ensure_lookup_table()
    head_faces = sum(1 for f in bm.faces if in_head(f.calc_center_median()))
    all_faces = len(bm.faces)
    bm.free()
    head_target = int(total_budget * head_share)
    r_head = min(1.0, head_target / max(head_faces, 1))
    r_body = max(0.001, (total_budget - head_target) / max(all_faces - head_faces, 1))
    print("TEMPEST: faces head %d body %d -> ratios head %.3f body %.3f" % (head_faces, all_faces - head_faces, r_head, r_body))
    for zone_head, r in ((False, r_body), (True, r_head)):
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_mode(type='FACE')
        bpy.ops.mesh.select_all(action='DESELECT')
        bpy.ops.object.mode_set(mode='OBJECT')
        for f in low.data.polygons:
            f.select = in_head(Vector(f.center)) == zone_head
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.decimate(ratio=r)
        bpy.ops.object.mode_set(mode='OBJECT')
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.quads_convert_to_tris()
    bpy.ops.mesh.remove_doubles(threshold=1e-5)
    bpy.ops.object.mode_set(mode='OBJECT')
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
    img = bpy.data.images.new("T_Tempest", tex_size, tex_size, alpha=False)
    mat = bpy.data.materials.new("M_Tempest")
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
    sc.render.bake.cage_extrusion = 0.012
    sc.render.bake.max_ray_distance = 0.035
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


# Model silhouette (front render, ortho 2.3 m wide in 1100 px => 478.26 px/m) fitted onto the front
# art crop: model px x 96..1002 <-> art px 88..4304, y 173..526 <-> 34..1697 (both include the
# arrows). The back-view crop shares those coordinates (see cut_tempest_ref.py), mirrored in X.
def _art_xy(x, z):
    mx = 550.0 - 478.26 * x            # seen from behind: +X is on the left
    my = 350.0 - 478.26 * z
    ax = 88 + (mx - 96) * (4216 / 906.0)
    ay = 34 + (my - 173) * (1663 / 353.0)
    return ax / 2.0, ay / 2.0          # reference png is half resolution


def paint_back_from_art(low, img, ref_png, ny_min=0.35, quiver=lambda p: p.y > 0.07 and p.z > 0.08 and abs(p.x) < 0.25):
    """Repaints every back-facing triangle (normal +Y; the bird faces -Y) of the baked texture from
    the official BACK VIEW art, by planar projection along Y. The AI source guessed the back of the
    bird; the sheet is authoritative (dark-green wings, yellow hood, tan only on the small wings,
    dark-green tail stripe). The quiver keeps its baked colour. Art pixels that are neutral grey
    (sheet background / captions) are skipped, so nothing outside the painted silhouette changes."""
    import numpy as np
    ref = bpy.data.images.load(ref_png)
    rw, rh = ref.size
    R = np.array(ref.pixels[:], dtype=np.float32).reshape(rh, rw, 4)[::-1, :, :3]   # row 0 = top
    W, H = img.size
    T = np.array(img.pixels[:], dtype=np.float32).reshape(H, W, 4)                    # row 0 = bottom
    uv = low.data.uv_layers.active.data
    vs = low.data.vertices
    painted = 0
    for poly in low.data.polygons:
        if poly.normal.y < ny_min:
            continue
        if quiver(Vector(poly.center)):
            continue
        li = list(poly.loop_indices)
        for k in range(1, len(li) - 1):
            ids = (li[0], li[k], li[k + 1])
            tuv = np.array([[uv[i].uv.x * W, uv[i].uv.y * H] for i in ids])
            tp = np.array([vs[poly.vertices[j]].co[:] for j in (0, k, k + 1)])
            x0, y0 = np.floor(tuv.min(0)).astype(int) - 1
            x1, y1 = np.ceil(tuv.max(0)).astype(int) + 1
            x0, y0, x1, y1 = max(x0, 0), max(y0, 0), min(x1, W - 1), min(y1, H - 1)
            if x1 < x0 or y1 < y0:
                continue
            gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
            a, b, c = tuv
            d = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
            if abs(d) < 1e-9:
                continue
            l1 = ((b[1] - c[1]) * (gx - c[0]) + (c[0] - b[0]) * (gy - c[1])) / d
            l2 = ((c[1] - a[1]) * (gx - c[0]) + (a[0] - c[0]) * (gy - c[1])) / d
            l3 = 1 - l1 - l2
            m = (l1 >= -0.06) & (l2 >= -0.06) & (l3 >= -0.06)
            if not m.any():
                continue
            P = l1[m, None] * tp[0] + l2[m, None] * tp[1] + l3[m, None] * tp[2]
            axy = np.array([_art_xy(p[0], p[2]) for p in P])
            ix = np.clip(axy[:, 0].astype(int), 0, rw - 1)
            iy = np.clip(axy[:, 1].astype(int), 0, rh - 1)
            col = R[iy, ix]
            ok = (col.max(1) - col.min(1)) > 0.07
            ys, xs = np.nonzero(m)
            T[ys[ok] + y0, xs[ok] + x0, :3] = col[ok]
            painted += int(ok.sum())
    img.pixels[:] = T.ravel()
    bpy.data.images.remove(ref)
    print("TEMPEST: back repainted px", painted)
