"""Contact sheets of every clip of the rigged Parasite .blend, on a floor plane.
Blender -b <file.blend> -P render_parasite.py -- --out <dir> [--view front|tq|side] [--size 384]"""
import bpy, os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from parasite_common import arg, setup_render, camera_at
from mathutils import Vector
out = arg("out"); size = int(arg("size", "400")); view = arg("view", "front")
arm = bpy.data.objects["ParasiteRig"]
setup_render((size, size))
for t in arm.animation_data.nla_tracks:
    t.mute = True
bpy.ops.mesh.primitive_plane_add(size=6, location=(0, 0, 0))
fl = bpy.context.object
m = bpy.data.materials.new("F"); m.diffuse_color = (0.3, 0.3, 0.3, 1); m.use_nodes = True
fl.data.materials.append(m)
dirs = {"tq": (0.8, -1, 0.3), "front": (0, -1, 0.1), "side": (1, 0, 0.1), "back": (0, 1, 0.1)}
camera_at(dirs[view], Vector((0, 0, 0.75)), 14, ortho=2.4)
for act in ["Idle", "Attack", "Hit", "Cast", "Roar", "Dead"]:
    a = bpy.data.actions[act]
    arm.animation_data.action = a
    if arm.animation_data.action_slot is None and len(a.slots):
        arm.animation_data.action_slot = a.slots[0]
    f0, f1 = int(a.frame_range[0]), int(a.frame_range[1])
    for i in range(6):
        f = f0 + round((f1 - f0) * i / 5)
        bpy.context.scene.frame_set(f)
        bpy.context.scene.render.filepath = os.path.join(out, f"{view}_{act}_{f:02d}.png")
        bpy.ops.render.render(write_still=True)
print("RENDERED")
