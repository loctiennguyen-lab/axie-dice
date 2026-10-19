"""Render the raw/fixed mesh from 5 views. Blender -b -P inspect_feral.py -- --src <glb> --out <dir> [--tag raw]"""
import bpy, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from feral_common import *
bpy.ops.wm.read_factory_settings(use_empty=True)
o = import_src(arg("src"))
mn, mx = bounds([o])
print("BOUNDS", tuple(mn), tuple(mx), "tris", tri_count(o))
out = arg("out"); tag = arg("tag", "raw")
setup_render((700, 700))
c = (mn + mx) / 2
sz = max((mx - mn))
for name, d in {"front": (0,-1,0.05), "side": (1,0,0.05), "back": (0,1,0.05), "tq": (0.8,-1,0.4), "top": (0,-0.05,1)}.items():
    camera_at(d, c, 12, ortho=sz*1.1)
    bpy.context.scene.render.filepath = os.path.join(out, f"{tag}_{name}.png")
    bpy.ops.render.render(write_still=True)
