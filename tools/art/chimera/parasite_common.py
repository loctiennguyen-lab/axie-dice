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


def straighten_beak(obj, p0=(0.09, -0.28, 0.222), tip0=(0.455, -0.73, 0.337),
                    new_dir_deg=(12.0, 12.0), length=0.44, tube=0.075,
                    s_free=0.0, s_full=0.22, nbins=80):
    """Rebuild the long nose spike as ONE straight tapered spike.

    The beak centreline is measured from the mesh (mean of its vertices per slice), then every
    beak vertex is re-expressed in a parallel-transport frame around that centreline and
    re-placed around a straight line leaving p0 at (yaw forward, pitch up) degrees from +X,
    with a clean monotone taper (bumps in the radius are removed). The first s_free metres
    stay on the original surface and blend to the straight line by s_full, so the root stays
    welded to the mask. Texture/UVs are untouched (vertices move, topology does not).
    """
    me = obj.data
    co = get_co(me)
    P0 = np.array(p0, dtype=np.float64)
    U = np.array(tip0, dtype=np.float64) - P0
    Ulen = np.linalg.norm(U)
    U /= Ulen
    rel = co - P0
    s_ax = rel @ U
    perp = rel - np.outer(s_ax, U)
    dist = np.linalg.norm(perp, axis=1)
    sel = (dist < tube) & (s_ax > 0.0) & (s_ax < Ulen * 1.08) & (co[:, 1] < -0.30)
    # the first slice(s) also include verts that are still on the mask (y >= -0.30): those are
    # left alone by construction (they are not selected) and the blend weight is 0 there.
    idx = np.nonzero(sel)[0]
    print("PARASITE beak: selected verts", len(idx), "of", len(co))
    sa = s_ax[idx]
    edges = np.linspace(sa.min(), sa.max() + 1e-6, nbins + 1)
    bi = np.clip(np.digitize(sa, edges) - 1, 0, nbins - 1)
    cen = np.zeros((nbins, 3))
    cnt = np.zeros(nbins)
    for k in range(nbins):
        m = bi == k
        cnt[k] = m.sum()
        if m.any():
            cen[k] = co[idx[m]].mean(axis=0)
    ok = cnt > 0
    ks = np.arange(nbins)
    for d in range(3):  # fill empty slices
        cen[:, d] = np.interp(ks, ks[ok], cen[ok, d])
    # smooth centreline a little, keep ends
    sm = cen.copy()
    for _ in range(3):
        sm[1:-1] = 0.25 * sm[:-2] + 0.5 * sm[1:-1] + 0.25 * sm[2:]
    cen = sm
    seg = np.diff(cen, axis=0)
    arc = np.concatenate([[0.0], np.cumsum(np.linalg.norm(seg, axis=1))])
    arc += 0.0
    # tangents
    T_old = np.gradient(cen, axis=0)
    T_old /= np.linalg.norm(T_old, axis=1)[:, None]
    # new centreline: blended old->line
    yaw, pitch = [math.radians(v) for v in new_dir_deg]
    D = np.array([math.cos(pitch) * math.cos(yaw), -math.cos(pitch) * math.sin(yaw), math.sin(pitch)])
    s0 = edges[0]
    s_here = arc + s0  # measured from p0 along beak (approx; arc starts at first slice)
    line = P0[None, :] + (arc[:, None] + 0.0) * 0.0  # placeholder to keep shape
    # the line starts at the first slice centre, not at p0
    start = cen[0]
    tot = arc[-1]
    scale = length / tot
    line = start[None, :] + np.outer(arc * scale, D)
    t = np.clip((s_here - s_free) / (s_full - s_free), 0.0, 1.0)
    w = t * t * (3 - 2 * t)
    cen_new = cen * (1 - w)[:, None] + line * w[:, None]
    arc_new_seg = np.linalg.norm(np.diff(cen_new, axis=0), axis=1)
    T_new = np.gradient(cen_new, axis=0)
    T_new /= np.linalg.norm(T_new, axis=1)[:, None]

    def frames(T):
        N = np.zeros_like(T)
        B = np.zeros_like(T)
        ref = np.array([0.0, 0.0, 1.0])
        n0 = np.cross(T[0], ref)
        n0 /= np.linalg.norm(n0)
        N[0] = n0
        B[0] = np.cross(T[0], n0)
        for i in range(1, len(T)):
            R = _rot_between(T[i - 1], T[i])
            N[i] = R @ N[i - 1]
            N[i] -= T[i] * np.dot(N[i], T[i])
            N[i] /= np.linalg.norm(N[i])
            B[i] = np.cross(T[i], N[i])
        return N, B
    N_o, B_o = frames(T_old)
    N_n, B_n = frames(T_new)
    # radius per slice (median distance to the centreline), monotone clean taper
    r = np.zeros(nbins)
    for k in range(nbins):
        m = bi == k
        if m.any():
            rr = np.linalg.norm(np.cross(co[idx[m]] - cen[k], T_old[k]), axis=1)
            r[k] = np.median(rr)
    r[~ok] = np.nan
    r = np.interp(ks, ks[ok], r[ok])
    rs = r.copy()
    for _ in range(12):
        rs[1:-1] = 0.25 * rs[:-2] + 0.5 * rs[1:-1] + 0.25 * rs[2:]
    rt = np.minimum.accumulate(rs)
    # blend radius correction in with the same weight so the root is not touched
    fac = 1.0 + (rt / np.maximum(r, 1e-6) - 1.0) * w
    fac = np.clip(fac, 0.2, 1.5)
    # per-vertex: interpolate slice data at the vertex's fractional slice position
    cen_pos = np.array([(edges[k] + edges[k + 1]) * 0.5 for k in range(nbins)])
    fpos = np.interp(sa, cen_pos, ks.astype(np.float64))
    i0 = np.clip(np.floor(fpos).astype(int), 0, nbins - 2)
    fr = (fpos - i0)[:, None]

    def lerp(A):
        return A[i0] * (1 - fr) + A[i0 + 1] * fr
    C0, C1 = lerp(cen), lerp(cen_new)
    n0v, b0v, t0v = lerp(N_o), lerp(B_o), lerp(T_old)
    n1v, b1v, t1v = lerp(N_n), lerp(B_n), lerp(T_new)
    f = lerp(fac[:, None])
    off = co[idx] - C0
    a = np.einsum('ij,ij->i', off, n0v)[:, None]
    b = np.einsum('ij,ij->i', off, b0v)[:, None]
    c = np.einsum('ij,ij->i', off, t0v)[:, None]
    new = C1 + (a * n1v + b * b1v) * f + c * t1v
    co[idx] = new
    set_co(me, co)
    print("PARASITE beak: new tip", co[idx][np.argmax(((co[idx] - start) @ D))], "arc old", tot, "new", arc_new_seg.sum())
    return len(idx)


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
