"""Arena v2 (lane V) - build + export one biome. Needs Blender (imports bpy).

In Blender's Python console / MCP:
    BIOME = 'forest'; exec(open('/Users/loc.tien.nguyen/my-game-wt/V/tools/art/arena_v2/export.py').read())
or for every biome:  BIOME = 'all'.  FRESH = True re-imports the biome's kit.
Steps per biome: kit.setup (FBX kit, cliffs, ground mesh) -> layout.check/build (props) ->
ground.paint (texture, with contact shadows under the props) -> GLB that REFERENCES the texture files
next to it (export_keep_originals + glb_strip_images), at godot/assets/atia/arena_v2/<biome>/<biome>_arena.glb.
Stage geometry comes from godot/assets/atia/arena_v2/stage_layout.json: edit it, re-run, re-import.
"""
import importlib
import os
import sys

import bpy
import numpy as np

HERE = '/Users/loc.tien.nguyen/my-game-wt/V/tools/art/arena_v2'
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import biomes  # noqa: E402
import ground  # noqa: E402
import kit  # noqa: E402
import layout  # noqa: E402
import glb_strip_images  # noqa: E402
for _m in (biomes, ground, kit, layout, glb_strip_images):
    importlib.reload(_m)


def write_ground(biome, size=2048):
    a = ground.paint(biomes.PALETTES[biome], size, layout.blobs(biome))
    path = os.path.join(kit.tex_dir(biome), 'T_%s_Ground.jpg' % biome.capitalize())
    img = bpy.data.images.get('gen_ground') or bpy.data.images.new('gen_ground', size, size, alpha=False)
    img.colorspace_settings.name = 'sRGB'
    rgba = np.ones((size, size, 4), np.float32)
    rgba[..., :3] = a[::-1]
    img.pixels.foreach_set(rgba.ravel())
    img.filepath_raw = path
    img.file_format = 'JPEG'
    img.save(quality=90)
    kit.ground_material(biome, path)
    return path


def export(biome):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    objs = list(bpy.data.collections['Arena_' + biome].all_objects)
    for o in objs:
        o.select_set(True)
    path = os.path.join(kit.OUT, biome, '%s_arena.glb' % biome)
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', use_selection=True, export_keep_originals=True,
                              export_yup=True, export_apply=False, export_cameras=False, export_lights=False,
                              export_animations=False, export_vertex_color='MATERIAL', export_materials='EXPORT')
    glb_strip_images.strip(path)
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs if o.type == 'MESH')
    return path, os.path.getsize(path), tris, len(objs)


def run(biome):
    log = kit.setup(biome, bool(globals().get('FRESH', False)))
    n = layout.build(biome)
    write_ground(biome)
    res = export(biome)
    tex = kit.tex_dir(biome)
    tex_bytes = sum(os.path.getsize(os.path.join(tex, f)) for f in os.listdir(tex) if not f.endswith('.import'))
    return {'biome': biome, 'props': n, 'glb': res[0], 'glb_bytes': res[1], 'tris': res[2],
            'tex_bytes': tex_bytes, 'kit': log}


_targets = list(biomes.PALETTES) if globals().get('BIOME', 'savannah') == 'all' else [globals().get('BIOME', 'savannah')]
for _b in _targets:
    print(run(_b))
