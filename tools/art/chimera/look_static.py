import bpy, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from venom_common import *
v = arg("variant", "01"); out = arg("out")
bpy.ops.wm.read_factory_settings(use_empty=True)
objs = import_variant(v)
setup_render((768, 768))
mn, mx = bounds(objs.values())
c = (mn + mx) / 2
for name, d in [("front", (0, -1, 0.05)), ("side", (1, 0, 0.05)), ("back", (0, 1, 0.05)), ("tq", (0.8, -1, 0.35))]:
    camera_at(d, c, 12, ortho=max(mx - mn) * 1.1)
    bpy.context.scene.render.filepath = os.path.join(out, f"static_{v}_{name}.png")
    bpy.ops.render.render(write_still=True)
