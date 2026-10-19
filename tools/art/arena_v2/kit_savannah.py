"""Needs Blender (imports bpy); no standalone run.
Savannah arena v2 - kit + ground mesh setup (run inside Blender once, before export_savannah.py).

Creates scene 'SavannahArena' with:
  Kit    - the source meshes, imported from asset-library/godot-ready/src (HomeLand + Atia FBX),
           transforms applied (cm/Y-up -> m/Z-up), origin at bottom centre, hidden, never exported
  Arena  - SA_Ground (shaped terrain, warped UV, see savannah_ground.py) + the props that
           build_savannah.py lays out as linked duplicates of the kit meshes
  SA_Camera / SA_Sun - the combat camera and sun, for `look` and the Blender render
Textures are downscaled copies living in godot/assets/atia/arena_v2/savannah/textures/.
"""
import math
import os
import sys

import bpy
import bmesh
from mathutils import Matrix, Vector, noise

HERE = '/Users/loc.tien.nguyen/my-game-wt/V/tools/art/arena_v2'
SRC = '/Users/loc.tien.nguyen/my-game/asset-library/godot-ready/src/'
TEX = os.path.normpath(os.path.join(HERE, '../../../godot/assets/atia/arena_v2/savannah/textures')) + '/'
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import savannah_ground  # noqa: E402

FILES = {
    'Tree01': 'HomeLand_Asset/Environment/Savannah/Tree/Source/SM_Tree01_Allside.fbx',
    'Tree02': 'HomeLand_Asset/Environment/Savannah/Tree/Source/SM_Tree02_Allside.fbx',
    'Tree03': 'HomeLand_Asset/Environment/Savannah/Tree/Source/SM_Tree03_Allside.fbx',
    'Tree03a': 'HomeLand_Asset/Environment/Savannah/Tree/Source/SM_Tree03a_Allside.fbx',
    'Shrub01': 'HomeLand_Asset/Environment/Savannah/Shrub/Source/SM_Shrub01_Allside_NoPlane.fbx',
    'Shrub02': 'HomeLand_Asset/Environment/Savannah/Shrub/Source/SM_Shrub02_Allside.fbx',
    'Shrub03': 'HomeLand_Asset/Environment/Savannah/Shrub/Source/SM_Shrub03_Allside.fbx',
    'Rock01': 'Atia_Asset/DeliveryAssets/Environment/Rock/SavannahRock/SM_SavannahRock_01.fbx',
    'Rock02': 'Atia_Asset/DeliveryAssets/Environment/Rock/SavannahRock/SM_SavannahRock_02.fbx',
}
for i in (0, 3, 6, 9, 12, 15, 18):
    FILES['RC%d' % i] = 'Atia_Asset/DeliveryAssets/Environment/Rock/RockCliff/SM_Rock_Cliff_%d.fbx' % i

# mesh name after import -> (material name, texture file, alpha clip or None, unlit)
MATS = {
    'SM_Tree_01_Allside': ('M_SA_Tree01', 'T_Tree01_C.png', 0.5, True),
    'SM_Tree02_Allside': ('M_SA_Tree02', 'T_Tree02_C.png', 0.5, True),
    'SM_Tree03_1_Allside': ('M_SA_Tree03', 'T_Tree03_C.png', 0.5, True),
    'SM_Tree03_2_Allside': ('M_SA_Tree03', 'T_Tree03_C.png', 0.5, True),
    'SM_Shrub_01_AllSide_NoPlane': ('M_SA_Shrub', 'T_Shrub_savannah.png', 0.6, False),
    'SM_Shrub_02_Allside': ('M_SA_Shrub', 'T_Shrub_savannah.png', 0.6, False),
    'SM_Shrub_03_Allside': ('M_SA_Shrub', 'T_Shrub_savannah.png', 0.6, False),
    'SM_SavannahRock_01': ('M_SA_Rock01', 'T_SavannahRock_01_C.jpg', None, False),
    'SM_SavannahRock_02': ('M_SA_Rock02', 'T_SavannahRock_02_C.jpg', None, False),
}


def lin(h):
    h = h.lstrip('#')
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return [(x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4) for x in c] + [1.0]


def mixc(a, b, t):
    return [a[i] + (b[i] - a[i]) * t for i in range(4)]


def make_material(name, tex, clip=None, unlit=False):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    ti = nt.nodes.new('ShaderNodeTexImage')
    ti.image = bpy.data.images.load(TEX + tex, check_existing=True)
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


def cliff_material():
    m = bpy.data.materials.get('M_SA_Cliff') or bpy.data.materials.new('M_SA_Cliff')
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


# Sandstone strata + golden grass tops, painted per face (values are lit ~x1.3 in game, so darker
# than the Land hub's cliff A9673A on purpose).
TOP_A, TOP_B = lin('BC9440'), lin('9C8536')
BANDS = [lin('74452A'), lin('8A5432'), lin('9C633A'), lin('8E5634'), lin('AC7644')]


def paint_cliff(me):
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
            col = mixc(TOP_A, TOP_B, min(max(0.5 + nv * 0.9, 0), 1))
        else:
            idx = max(min(int((h + nv * 0.08) * len(BANDS)), len(BANDS) - 1), 0)
            col = BANDS[idx]
            if n.z < -0.2:
                col = mixc(col, lin('5A3420'), 0.5)
            if h > 0.85 and n.z > 0.25:
                col = mixc(col, TOP_A, 0.6)
        for li in p.loop_indices:
            ca.data[li].color = col
        p.use_smooth = False


def import_kit(sc):
    kit = bpy.data.collections.get('Kit') or bpy.data.collections.new('Kit')
    if kit.name not in sc.collection.children:
        sc.collection.children.link(kit)
    cliff = cliff_material()
    for _k, f in FILES.items():
        before = set(bpy.data.objects)
        bpy.ops.import_scene.fbx(filepath=SRC + f)
        for o in [o for o in bpy.data.objects if o not in before]:
            for c in list(o.users_collection):
                c.objects.unlink(o)
            kit.objects.link(o)
            if o.type != 'MESH':
                continue
            bpy.context.view_layer.update()
            o.data.transform(o.matrix_world)          # FBX: cm, Y-up, rotated 90 deg X
            o.parent = None
            o.matrix_world = Matrix.Identity(4)
            vs = [v.co for v in o.data.vertices]
            cx = (min(v.x for v in vs) + max(v.x for v in vs)) / 2
            cy = (min(v.y for v in vs) + max(v.y for v in vs)) / 2
            o.data.transform(Matrix.Translation((-cx, -cy, -min(v.z for v in vs))))
            if o.name in MATS:
                name, tex, clip, unlit = MATS[o.name]
                o.data.materials.clear()
                o.data.materials.append(make_material(name, tex, clip, unlit))
            elif o.name.startswith('SM_Rock_Cliff'):
                paint_cliff(o.data)
                o.data.materials.clear()
                o.data.materials.append(cliff)
            o.location.y = 300.0
            o.hide_render = True
    return kit


def smooth(e0, e1, x):
    t = min(max((x - e0) / (e1 - e0), 0), 1)
    return t * t * (3 - 2 * t)


FX0, FX1, FZ0, FZ1 = -16.0, 13.0, -13.0, 11.5   # flat battle area, godot x / z


def height(x, z):
    """Terrain height (godot coords). Exactly 0 inside the battle area so every unit stands on y = 0."""
    dx = max(FX0 - x, 0, x - FX1)
    dz = max(FZ0 - z, 0, z - FZ1)
    d = math.hypot(dx, dz)
    if d <= 0:
        return 0.0
    m = smooth(0, 6, d)
    n = noise.noise(Vector((x * 0.09, z * 0.09, 0.3))) * 1.2 + noise.noise(Vector((x * 0.25, z * 0.25, 1.7))) * 0.35
    back = smooth(FZ0, FZ0 - 10, z) * 2.2 if z < FZ0 else 0.0
    side = smooth(FX1, FX1 + 10, x) * 1.6 if x > FX1 else (smooth(FX0, FX0 - 10, x) * 1.8 if x < FX0 else 0.0)
    front = -smooth(FZ1, FZ1 + 5, z) * 0.6 if z > FZ1 else 0.0
    return m * (0.5 + n * 0.6) + back + side + front


def build_ground(col):
    X0, X1, Z0, Z1, nx, nz = -46, 46, -44, 18, 92, 62
    me = bpy.data.meshes.get('SA_Ground') or bpy.data.meshes.new('SA_Ground')
    bm = bmesh.new()
    rows = []
    for j in range(nz + 1):
        z = Z0 + (Z1 - Z0) * j / nz
        rows.append([bm.verts.new((X0 + (X1 - X0) * i / nx, -z, height(X0 + (X1 - X0) * i / nx, z))) for i in range(nx + 1)])
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
            u, vv = savannah_ground.uv_of(v.x, -v.y)
            uv[li].uv = (float(u), float(vv))
    m = make_material('M_SA_Ground', 'T_SA_Ground.jpg')
    me.materials.clear()
    me.materials.append(m)
    ob = bpy.data.objects.get('SA_Ground') or bpy.data.objects.new('SA_Ground', me)
    if ob.name not in col.objects:
        col.objects.link(ob)
    return ob


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


def setup():
    sc = bpy.data.scenes.get('SavannahArena') or bpy.data.scenes.new('SavannahArena')
    bpy.context.window.scene = sc
    import_kit(sc)
    col = bpy.data.collections.get('Arena') or bpy.data.collections.new('Arena')
    if col.name not in sc.collection.children:
        sc.collection.children.link(col)
    build_ground(col)
    rig(sc)


if __name__ == '__main__':
    setup()
