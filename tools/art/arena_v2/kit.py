"""Arena v2 (lane V) - kit + ground setup for one biome. Needs Blender (imports bpy).

Builds, in Blender scene 'ArenaV2':
  Kit_common        Atia RockCliff source meshes (imported once, hidden, never exported)
  Kit_<biome>       K_<biome>_<role>: the biome's trees/shrubs/rocks (biomes.KIT) + its own vertex-
                    painted copies of the cliffs (biomes.CLIFF); transforms applied (FBX cm/Y-up ->
                    m/Z-up), origin bottom centre, hidden, never exported
  Arena_<biome>     G_<biome>_Ground (shaped terrain, warped UV from ground.uv_of) + the props that
                    layout.build() places; this collection is what export.py writes
  SA_Camera/SA_Sun  combat camera + sun, for `look` and renders
Textures are copied (downscaled) into godot/assets/atia/arena_v2/<biome>/textures/.
"""
import math
import os
import sys

import bpy
import bmesh
from mathutils import Matrix, Vector, noise

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import biomes  # noqa: E402
import ground  # noqa: E402

SRC = '/Users/loc.tien.nguyen/my-game/asset-library/godot-ready/src/'
OUT = os.path.normpath(os.path.join(HERE, '../../../godot/assets/atia/arena_v2'))
CLIFFS = {'mesa_wide': 18, 'mesa_a': 12, 'mesa_b': 15, 'butte': 9, 'ledge': 3, 'ledge_b': 6, 'ridge': 0}
TEX_PX = 512          # foliage / rock textures are small on screen
_INDEX = {}


def tex_dir(biome):
    d = os.path.join(OUT, biome, 'textures')
    os.makedirs(d, exist_ok=True)
    return d


def find_tex(fbx, base):
    """Texture file by basename: next to the FBX, then anywhere in the library (first hit)."""
    base = base.replace('\\', '/').split('/')[-1]
    stem = os.path.splitext(base)[0]
    for ext in ('.png', '.jpg', '.tga', '.PNG'):
        p = os.path.join(os.path.dirname(SRC + fbx), stem + ext)
        if os.path.exists(p):
            return p
    if not _INDEX:
        for root, _dirs, files in os.walk(SRC):
            for f in files:
                if not f.endswith('.import'):
                    _INDEX.setdefault(os.path.splitext(f)[0].lower(), os.path.join(root, f))
    return _INDEX.get(stem.lower())


def copy_tex(biome, src_path):
    """Downscaled copy in the biome's texture folder; JPEG when opaque, PNG when it has alpha."""
    img = bpy.data.images.load(src_path, check_existing=True)
    has_alpha = img.depth in (32, 64, 128) and not src_path.lower().endswith(".jpg")   # depth 24 = RGB
    name = os.path.splitext(os.path.basename(src_path))[0]
    out = os.path.join(tex_dir(biome), name + ('.png' if has_alpha else '.jpg'))
    if not os.path.exists(out):
        cp = img.copy()
        if max(cp.size) > TEX_PX:
            cp.scale(TEX_PX, TEX_PX)
        cp.filepath_raw = out
        cp.file_format = 'PNG' if has_alpha else 'JPEG'
        if has_alpha:
            cp.save()
        else:
            cp.save(quality=88)
        bpy.data.images.remove(cp)
    return bpy.data.images.load(out, check_existing=True)


def make_material(name, img, clip=None, unlit=False):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    ti = nt.nodes.new('ShaderNodeTexImage')
    ti.image = img
    if unlit:   # Background shader -> glTF KHR_materials_unlit (the Land kit's trees are unshaded)
        bg = nt.nodes.new('ShaderNodeBackground')
        nt.links.new(ti.outputs['Color'], bg.inputs['Color'])
        nt.links.new(bg.outputs[0], out.inputs['Surface'])
    else:
        b = nt.nodes.new('ShaderNodeBsdfPrincipled')
        b.inputs['Roughness'].default_value = 1.0
        nt.links.new(ti.outputs['Color'], b.inputs['Base Color'])
        if clip is not None:
            nt.links.new(ti.outputs['Alpha'], b.inputs['Alpha'])
        nt.links.new(b.outputs[0], out.inputs['Surface'])
    m.use_backface_culling = False
    return m


def lin(h):
    h = h.lstrip('#')
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return [(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4) for x in c] + [1.0]


def mixc(a, b, t):
    return [a[i] + (b[i] - a[i]) * t for i in range(4)]


def cliff_material(biome):
    m = bpy.data.materials.get('M_%s_Cliff' % biome) or bpy.data.materials.new('M_%s_Cliff' % biome)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    b = nt.nodes.new('ShaderNodeBsdfPrincipled')
    va = nt.nodes.new('ShaderNodeVertexColor')
    va.layer_name = 'Col'
    b.inputs['Roughness'].default_value = 1.0
    nt.links.new(va.outputs['Color'], b.inputs['Base Color'])
    nt.links.new(b.outputs[0], out.inputs['Surface'])
    return m


def paint_cliff(me, pal):
    """Strata bands by height + a grass/snow cap on up-facing faces, one colour per face."""
    top_a, top_b = lin(pal['top'][0]), lin(pal['top'][1])
    bands = [lin(c) for c in pal['bands']]
    under = lin(pal['under'])
    if 'Col' in me.color_attributes:
        me.color_attributes.remove(me.color_attributes['Col'])
    ca = me.color_attributes.new('Col', 'FLOAT_COLOR', 'CORNER')
    zs = [v.co.z for v in me.vertices]
    z0, z1 = min(zs), max(zs)
    for p in me.polygons:
        n, c = p.normal, p.center
        h = (c.z - z0) / max(z1 - z0, 1e-3)
        nv = noise.noise(Vector((c.x * 0.15, c.y * 0.15, c.z * 0.15)))
        if n.z > 0.6:
            col = mixc(top_a, top_b, min(max(0.5 + nv * 0.9, 0), 1))
        else:
            col = bands[max(min(int((h + nv * 0.08) * len(bands)), len(bands) - 1), 0)]
            if n.z < -0.2:
                col = mixc(col, under, 0.5)
            if h > 0.85 and n.z > 0.25:
                col = mixc(col, top_a, 0.6)
        for li in p.loop_indices:
            ca.data[li].color = col
        p.use_smooth = False


def _collection(sc, name):
    col = bpy.data.collections.get(name) or bpy.data.collections.new(name)
    if col.name not in sc.collection.children:
        sc.collection.children.link(col)
    return col


def import_fbx(path, col, name):
    """Imports one FBX, joins its meshes into one object `name` with applied transforms."""
    before = set(bpy.data.objects)
    bpy.ops.import_scene.fbx(filepath=SRC + path)
    new = [o for o in bpy.data.objects if o not in before]
    bpy.context.view_layer.update()
    meshes = [o for o in new if o.type == 'MESH']
    for o in meshes:
        o.data = o.data.copy()
        o.data.transform(o.matrix_world)         # FBX: cm, Y-up, rotated 90 deg X
    keep = meshes[0]
    if len(meshes) > 1:                         # join, keeping every material slot
        mats = []
        for o in meshes:
            for m in o.data.materials:
                if m not in mats:
                    mats.append(m)
        bm = bmesh.new()
        for o in meshes:
            remap = [mats.index(m) for m in o.data.materials] or [0]
            tmp = bmesh.new()
            tmp.from_mesh(o.data)
            for f in tmp.faces:
                f.material_index = remap[min(f.material_index, len(remap) - 1)]
            me_tmp = bpy.data.meshes.new('tmp')
            tmp.to_mesh(me_tmp)
            tmp.free()
            bm.from_mesh(me_tmp)
            bpy.data.meshes.remove(me_tmp)
        bm.to_mesh(keep.data)
        bm.free()
        keep.data.materials.clear()
        for m in mats:
            keep.data.materials.append(m)
    for o in new:
        if o is not keep:
            bpy.data.objects.remove(o, do_unlink=True)
    keep.parent = None
    keep.matrix_world = Matrix.Identity(4)
    vs = [v.co for v in keep.data.vertices]
    cx = (min(v.x for v in vs) + max(v.x for v in vs)) / 2
    cy = (min(v.y for v in vs) + max(v.y for v in vs)) / 2
    keep.data.transform(Matrix.Translation((-cx, -cy, -min(v.z for v in vs))))
    for c in list(keep.users_collection):
        c.objects.unlink(keep)
    col.objects.link(keep)
    keep.name = name
    keep.data.name = name
    keep.location.y = 300.0
    keep.hide_render = True
    keep.hide_set(True)
    return keep


def planar_uv_error(me):
    """Mean error of the best LINEAR fit uv = A * position. Small (< 0.05) means the UVs were
    projected from one direction: a "painted from the Land camera" mesh that only looks right
    from that side (Genesis trees, some Luna / Arctic trees)."""
    import numpy as np
    uv = me.uv_layers[0].data
    P, U = [], []
    for p in me.polygons:
        for li in p.loop_indices:
            P.append(tuple(me.vertices[me.loops[li].vertex_index].co) + (1.0,))
            U.append(tuple(uv[li].uv))
    P, U = np.array(P), np.array(U)
    A = np.linalg.lstsq(P, U, rcond=None)[0]
    return float(np.abs(P @ A - U).mean())


# Yaw (deg) that turns a camera-projected kit mesh toward the combat camera; the Land's iso camera
# looks from 45 degrees, so -45 brings that side to the front (checked on Genesis SM_Tree_G_01).
FACE_YAW = -45.0


def common_kit(sc):
    col = _collection(sc, 'Kit_common')
    for role, n in CLIFFS.items():
        if bpy.data.objects.get('KC_' + role) is None:
            import_fbx('Atia_Asset/DeliveryAssets/Environment/Rock/RockCliff/SM_Rock_Cliff_%d.fbx' % n, col, 'KC_' + role)
    return col


def biome_kit(sc, biome):
    col = _collection(sc, 'Kit_' + biome)
    log = []
    for role, (fbx, tex, clip, unlit) in biomes.KIT[biome].items():
        name = 'K_%s_%s' % (biome, role)
        if bpy.data.objects.get(name) is not None:
            continue
        o = import_fbx(fbx, col, name)
        new_mats = []
        for i, m in enumerate(o.data.materials):
            base = tex
            if base is None and m is not None and m.use_nodes:
                imgs = [n.image for n in m.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image]
                base = imgs[0].filepath if imgs else None
            path = find_tex(fbx, base) if base else None
            if path is None:
                log.append('%s slot %d: NO TEXTURE (%s)' % (name, i, base))
                new_mats.append(m)
                continue
            # '_cut' suffix = alpha cut-out card; ArenaV2Diorama keys on it (glTF unlit drops alphaMode)
            mname = 'M_%s_%s%s' % (biome, os.path.splitext(os.path.basename(path))[0], '_cut' if clip is not None else '')
            new_mats.append(make_material(mname, copy_tex(biome, path), clip, unlit))
            log.append('%s slot %d: %s' % (name, i, os.path.relpath(path, SRC)))
        o.data.materials.clear()
        for m in new_mats:
            o.data.materials.append(m)
        if role in biomes.FACE_CAM.get(biome, []) or (o.data.uv_layers and planar_uv_error(o.data) < 0.05):
            o['face_yaw'] = FACE_YAW
            log.append('%s: camera-projected UVs, faces the camera' % name)
    cm = cliff_material(biome)
    for role in CLIFFS:
        name = 'K_%s_%s' % (biome, role)
        if bpy.data.objects.get(name) is not None:
            continue
        src = bpy.data.objects['KC_' + role]
        o = bpy.data.objects.new(name, src.data.copy())
        col.objects.link(o)
        paint_cliff(o.data, biomes.CLIFF[biome])
        o.data.materials.clear()
        o.data.materials.append(cm)
        o.location.y = 300.0
        o.hide_render = True
        o.hide_set(True)
    return log


def smooth(e0, e1, x):
    t = min(max((x - e0) / (e1 - e0), 0), 1)
    return t * t * (3 - 2 * t)


def height(x, z, st):
    """Terrain height (godot coords). Exactly 0 inside the flat area so every unit stands on y = 0."""
    (fx0, fx1), (fz0, fz1) = st['flat_area']['x'], st['flat_area']['z']
    dx = max(fx0 - x, 0, x - fx1)
    dz = max(fz0 - z, 0, z - fz1)
    d = math.hypot(dx, dz)
    if d <= 0:
        return 0.0
    m = smooth(0, 6, d)
    n = noise.noise(Vector((x * 0.09, z * 0.09, 0.3))) * 1.2 + noise.noise(Vector((x * 0.25, z * 0.25, 1.7))) * 0.35
    back = smooth(fz0, fz0 - 10, z) * 2.2 if z < fz0 else 0.0
    side = smooth(fx1, fx1 + 10, x) * 1.6 if x > fx1 else (smooth(fx0, fx0 - 10, x) * 1.8 if x < fx0 else 0.0)
    front = -smooth(fz1, fz1 + 5, z) * 0.6 if z > fz1 else 0.0
    return m * (0.5 + n * 0.6) + back + side + front


def build_ground(biome, col):
    st = ground.stage()
    X0, X1, Z0, Z1, nx, nz = -46, 46, -44, 18, 92, 62
    name = 'G_%s_Ground' % biome
    me = bpy.data.meshes.get(name) or bpy.data.meshes.new(name)
    bm = bmesh.new()
    rows = []
    for j in range(nz + 1):
        z = Z0 + (Z1 - Z0) * j / nz
        rows.append([bm.verts.new((X0 + (X1 - X0) * i / nx, -z, height(X0 + (X1 - X0) * i / nx, z, st))) for i in range(nx + 1)])
    for j in range(nz):
        for i in range(nx):
            f = bm.faces.new((rows[j][i], rows[j][i + 1], rows[j + 1][i + 1], rows[j + 1][i]))
            if f.normal.z < 0:
                f.normal_flip()
    bm.to_mesh(me)
    bm.free()
    uv = (me.uv_layers.get('UVMap') or me.uv_layers.new(name='UVMap')).data
    for p in me.polygons:
        p.use_smooth = True
        for li in p.loop_indices:
            v = me.vertices[me.loops[li].vertex_index].co
            u, vv = ground.uv_of(v.x, -v.y)
            uv[li].uv = (float(u), float(vv))
    ob = bpy.data.objects.get(name) or bpy.data.objects.new(name, me)
    if ob.name not in col.objects:
        col.objects.link(ob)
    return ob


def ground_material(biome, path):
    """Called by export.py once the ground JPEG exists on disk."""
    img = bpy.data.images.load(path, check_existing=True)
    img.reload()
    m = make_material('M_%s_Ground' % biome, img)
    me = bpy.data.objects['G_%s_Ground' % biome].data
    me.materials.clear()
    me.materials.append(m)


def rig(sc):
    cd = bpy.data.cameras.get('SA_CamData') or bpy.data.cameras.new('SA_CamData')
    cd.sensor_fit = 'VERTICAL'
    cd.angle_y = math.radians(27.607)          # CombatStage3D fov 19 after frame_band(1080, 140.4, 876)
    cd.clip_end = 400
    cam = bpy.data.objects.get('SA_Camera') or bpy.data.objects.new('SA_Camera', cd)
    if cam.name not in sc.collection.objects:
        sc.collection.objects.link(cam)
    cam.location = (-0.2, -28.0, 17.0)         # godot (-0.2, 17, 28)
    cam.rotation_euler = (math.radians(90 - 30.829), 0, 0)
    sc.camera = cam
    sc.render.resolution_x, sc.render.resolution_y = 1920, 1080
    ld = bpy.data.lights.get('SA_SunData') or bpy.data.lights.new('SA_SunData', 'SUN')
    ld.energy, ld.color = 3.0, (1.0, 0.92, 0.78)
    sun = bpy.data.objects.get('SA_Sun') or bpy.data.objects.new('SA_Sun', ld)
    if sun.name not in sc.collection.objects:
        sc.collection.objects.link(sun)
    d = Vector((0.321, -0.766, -0.557))         # godot sun rotation (-50, -30, 0) forward
    sun.rotation_euler = Vector((d.x, -d.z, d.y)).to_track_quat('-Z', 'Y').to_euler()


def setup(biome, fresh=False):
    """`fresh`: drop the biome's kit first (re-import FBX, re-copy textures, repaint cliffs)."""
    sc = bpy.data.scenes.get('ArenaV2') or bpy.data.scenes.new('ArenaV2')
    bpy.context.window.scene = sc
    if fresh and bpy.data.collections.get('Kit_' + biome):
        for o in list(bpy.data.collections['Kit_' + biome].objects):
            bpy.data.objects.remove(o, do_unlink=True)
    rig(sc)
    common_kit(sc)
    log = biome_kit(sc, biome)
    col = _collection(sc, 'Arena_' + biome)
    build_ground(biome, col)
    for c in sc.collection.children:      # only this biome visible
        if c.name.startswith('Arena_'):
            c.hide_viewport = c.name != 'Arena_' + biome
            c.hide_render = c.name != 'Arena_' + biome
    return log
