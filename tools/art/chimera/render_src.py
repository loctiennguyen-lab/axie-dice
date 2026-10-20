"""Render the raw Brine AI mesh from 5 views. Blender -b --factory-startup -P render_src.py -- --src X --out DIR [--tex image]"""
import bpy, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from brine_common import *
from mathutils import Vector
bpy.ops.wm.read_factory_settings(use_empty=True)
o = import_src(arg("src"))
mn, mx = bounds([o])
print("BOUNDS", tuple(mn), tuple(mx), "tris", tri_count(o), "verts", len(o.data.vertices))
size = int(arg("size", "900"))
setup_render((size, size))
c = (mn + mx) / 2
ext = max(mx - mn) * 1.1
views = {"front": (0, -1, 0.05), "back": (0, 1, 0.05), "side": (1, 0, 0.05), "tq": (0.8, -1, 0.4), "top": (0, -0.01, 1)}
for n, d in views.items():
    camera_at(d, c, 20, ortho=ext)
    bpy.context.scene.render.filepath = os.path.join(arg("out"), f"{arg('tag','src')}_{n}.png")
    bpy.ops.render.render(write_still=True)
