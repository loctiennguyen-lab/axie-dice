"""Shared helpers for the Parasite (Bug) Chimera pipeline, built from the art team's FBX parts
(asset-library/chimera-src/Parasite (Bug)/3D/Bug_01). Headless Blender 5.x.
Parts: Body, Hair, Mask, Weapon, Weapon_Sheath share one frame (Body/Hair/Mask) - the two weapon
meshes ship at the origin, upright, and have to be placed on the back (see build_parasite.py).
"""
import bpy, os, sys, math, mathutils

SRC = "/Users/loc.tien.nguyen/my-game/asset-library/chimera-src/Parasite (Bug)/3D/Bug_01"
PARTS = {"Body": ("SM_Bug_Body_01.fbx", "T_Bug_Body_1_C.png"),
         "Hair": ("SM_Bug_Hair_01.fbx", "T_Bug_Hair_1_C.png"),
         "Mask": ("SM_Bug_Mask_01.fbx", "T_Bug_Mask_1_C.png"),
         "Weapon": ("SM_Bug_Weapon_01.fbx", "T_Bug_Weapon_1_C.png"),
         "Sheath": ("SM_Bug_Weapon_Sheath_01.fbx", "T_Bug_Weapon_1_C.png")}


def arg(name, default=None):
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    for i, a in enumerate(argv):
        if a == "--" + name and i + 1 < len(argv):
            return argv[i + 1]
    return default


def import_parts(only=None):
    """Imports the parts (metres, Z up, creature faces -Y), flat textured materials, smooth."""
    objs = {}
    for part, (fbx, tex) in PARTS.items():
        if only and part not in only:
            continue
        before = set(bpy.data.objects)
        bpy.ops.import_scene.fbx(filepath=os.path.join(SRC, fbx))
        new = [o for o in bpy.data.objects if o not in before]
        mesh = [o for o in new if o.type == 'MESH'][0]
        for o in new:
            if o is not mesh:
                bpy.data.objects.remove(o)
        bpy.ops.object.select_all(action='DESELECT')
        mesh.select_set(True)
        bpy.context.view_layer.objects.active = mesh
        mesh.parent = None
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        mesh.name = part
        mesh.data.name = part
        while len(mesh.data.uv_layers) > 1:      # Body/Hair ship a 2nd UV set; glTF wants one
            mesh.data.uv_layers.remove(mesh.data.uv_layers[-1])
        mat = bpy.data.materials.new("M_Bug_" + part)
        mat.use_nodes = True
        nt = mat.node_tree
        bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
        img = nt.nodes.new("ShaderNodeTexImage")
        img.image = bpy.data.images.load(os.path.join(SRC, tex), check_existing=True)
        nt.links.new(img.outputs["Color"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.85
        bsdf.inputs["Metallic"].default_value = 0.0
        mesh.data.materials.clear()
        mesh.data.materials.append(mat)
        for p in mesh.data.polygons:
            p.use_smooth = True
        objs[part] = mesh
    return objs


def bounds(objs):
    pts = [o.matrix_world @ mathutils.Vector(c) for o in objs for c in o.bound_box]
    mn = mathutils.Vector([min(p[i] for p in pts) for i in range(3)])
    mx = mathutils.Vector([max(p[i] for p in pts) for i in range(3)])
    return mn, mx


def setup_render(res=(1024, 1024)):
    sc = bpy.context.scene
    try:
        sc.render.engine = 'BLENDER_EEVEE'
    except TypeError:
        sc.render.engine = 'BLENDER_EEVEE_NEXT'
    sc.render.resolution_x, sc.render.resolution_y = res
    world = bpy.data.worlds.new("W") if not sc.world else sc.world
    sc.world = world
    world.use_nodes = True
    bg = next(n for n in world.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (0.16, 0.15, 0.2, 1)
    sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", 'SUN'))
    sun.data.energy = 3.0
    sun.rotation_euler = (math.radians(50), 0, math.radians(-30))
    sc.collection.objects.link(sun)
    try:
        sc.view_settings.view_transform = 'Standard'
    except TypeError:
        pass


def camera_at(direction, target, dist, ortho=None):
    sc = bpy.context.scene
    cam = sc.camera
    if cam is None:
        cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
        sc.collection.objects.link(cam)
        sc.camera = cam
    d = mathutils.Vector(direction).normalized()
    cam.location = target + d * dist
    cam.rotation_euler = (-d).to_track_quat('-Z', 'Y').to_euler()
    if ortho:
        cam.data.type = 'ORTHO'
        cam.data.ortho_scale = ortho
    else:
        cam.data.type = 'PERSP'
        cam.data.lens = 50
    return cam
