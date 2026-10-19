"""Render the low-poly (cache .blend or rigged .blend) from several views.
Blender -b <file.blend> -P render_low.py -- --out DIR --tag low [--size 800]"""
import bpy, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from brine_common import arg, setup_render, camera_at
from mathutils import Vector
setup_render((int(arg("size", "800")),) * 2)
for n, d, c, e in [("front", (0, -1, 0.05), (0.1, 0, 0.7), 2.1), ("tq", (0.8, -1, 0.4), (0.1, 0, 0.7), 2.1),
                   ("head", (0, -1, 0.05), (0, 0, 1.1), 0.8), ("mace", (0, -1, 0.05), (0.9, 0, 0.35), 0.8),
                   ("side", (1, 0, 0.05), (0, 0, 0.7), 2.1)]:
    camera_at(d, Vector(c), 20, ortho=e)
    bpy.context.scene.render.filepath = os.path.join(arg("out"), "%s_%s.png" % (arg("tag", "low"), n))
    bpy.ops.render.render(write_still=True)
