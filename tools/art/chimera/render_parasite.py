"""Raw FBX assembly views. Blender -b --factory-startup -P render_parasite.py -- --out DIR [--only Body,Hair,Mask,Weapon]"""
import bpy, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from parasite_common import *
bpy.ops.wm.read_factory_settings(use_empty=True)
only = arg("only"); objs = import_parts(only.split(",") if only else None)
for n, o in objs.items():
    mn, mx = bounds([o]); print("B", n, tuple(round(x, 2) for x in mn), tuple(round(x, 2) for x in mx))
setup_render((700, 900))
for n, d in {"front": (0, -1, 0.05), "side": (1, 0, 0.05), "back": (0, 1, 0.05), "tq": (0.8, -1, 0.4)}.items():
    camera_at(d, mathutils.Vector((0, 0.3, 1.8)), 30, ortho=6.5)
    bpy.context.scene.render.filepath = os.path.join(arg("out"), "raw_%s.png" % n)
    bpy.ops.render.render(write_still=True)
