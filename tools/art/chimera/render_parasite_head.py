"""Head close-ups (front, side from the creature's left, top) of the rigged Parasite .blend, Idle frame 0.
Blender -b <file.blend> -P render_parasite_head.py -- --out <dir> --tag name [--size 600]"""
import bpy, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from parasite_common import arg, setup_render, camera_at
from mathutils import Vector
out = arg("out"); tag = arg("tag", "p"); size = int(arg("size", "600"))
arm = bpy.data.objects["ParasiteRig"]
setup_render((size, size))
for t in arm.animation_data.nla_tracks:
    t.mute = True
a = bpy.data.actions["Idle"]
arm.animation_data.action = a
if arm.animation_data.action_slot is None and len(a.slots):
    arm.animation_data.action_slot = a.slots[0]
bpy.context.scene.frame_set(0)
c = Vector((0, -0.25, 0.98))
for view, d in {"front": (0, -1, 0), "side": (1, 0, 0), "top": (0, -0.001, 1)}.items():
    camera_at(d, c, 8, ortho=1.3)
    bpy.context.scene.render.filepath = os.path.join(out, f"{tag}_head_{view}.png")
    bpy.ops.render.render(write_still=True)
print("RENDERED")
