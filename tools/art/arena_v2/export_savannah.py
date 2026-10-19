"""Savannah arena v2 - rebuild + export (run inside Blender, scene 'SavannahArena').

  exec(open('/Users/.../tools/art/arena_v2/export_savannah.py').read())

1. repaints the ground texture (savannah_ground.py) straight to godot/.../textures/T_SA_Ground.jpg
   with PIL-free numpy -> Blender image save (JPEG q90, no view transform),
2. re-lays the props (build_savannah.py),
3. exports collection 'Arena' as GLB that REFERENCES the texture files next to it
   (export_keep_originals), so Godot imports them as normal textures.
The kit (FBX import, materials, cliff vertex paint) is set up by kit_savannah.py.
"""
import importlib
import os
import sys

import bpy
import numpy as np

HERE = '/Users/loc.tien.nguyen/my-game-wt/V/tools/art/arena_v2'
OUT_DIR = os.path.normpath(os.path.join(HERE, '../../../godot/assets/atia/arena_v2/savannah'))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import savannah_ground  # noqa: E402
import build_savannah  # noqa: E402
import glb_strip_images  # noqa: E402
importlib.reload(savannah_ground)
importlib.reload(build_savannah)


def write_ground(size=2048):
    a = savannah_ground.paint(size, build_savannah.blobs())
    img = bpy.data.images.get('T_SA_Ground_gen') or bpy.data.images.new('T_SA_Ground_gen', size, size, alpha=False)
    img.colorspace_settings.name = 'sRGB'
    rgba = np.ones((size, size, 4), np.float32)
    rgba[..., :3] = a[::-1]
    img.pixels.foreach_set(rgba.ravel())
    img.filepath_raw = os.path.join(OUT_DIR, 'textures', 'T_SA_Ground.jpg')
    img.file_format = 'JPEG'
    img.save(quality=90)
    g = bpy.data.images.get('T_SA_Ground')
    if g is not None:
        g.reload()


def export():
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    objs = list(bpy.data.collections['Arena'].all_objects)
    for o in objs:
        o.select_set(True)
    path = os.path.join(OUT_DIR, 'savannah_arena.glb')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_keep_originals=True,
                              export_yup=True, export_apply=False, export_cameras=False, export_lights=False,
                              export_animations=False, export_vertex_color='MATERIAL', export_materials='EXPORT')
    glb_strip_images.strip(path)
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs if o.type == 'MESH')
    return path, os.path.getsize(path), tris, len(objs)


write_ground()
build_savannah.build()
print(export())
