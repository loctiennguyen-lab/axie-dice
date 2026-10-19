"""Renders a contact sheet of every clip of a rigged Venom .blend (and a turnaround).
Blender -b <file.blend> -P render_poses.py -- --out <dir> [--tag name]"""
import bpy, os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from venom_common import arg, setup_render, camera_at, bounds
from mathutils import Vector
out = arg("out"); tag = arg("tag", "v"); size = int(arg("size", "384"))
view = arg("view", "tq")
arm = bpy.data.objects["VenomRig"]
meshes = [o for o in bpy.data.objects if o.type == 'MESH']
setup_render((size, size))
for t in arm.animation_data.nla_tracks:
    t.mute = True
mn, mx = bounds(meshes)
c = (mn + mx) / 2 + Vector((0, 0, -0.1))
dirs = {"tq": (0.8, -1, 0.3), "front": (0, -1, 0.12), "side": (1, 0, 0.1), "back": (0, 1, 0.1)}
paths = []
if arg("turn"):
    for name in ["front", "tq", "side", "back"]:
        camera_at(dirs[name], c, 14, ortho=4.4)
        bpy.context.scene.frame_set(0)
        arm.animation_data.action = bpy.data.actions["Idle"]
        p = os.path.join(out, f"{tag}_turn_{name}.png"); bpy.context.scene.render.filepath = p
        bpy.ops.render.render(write_still=True); paths.append(p)
else:
    camera_at(dirs[view], c, 14, ortho=4.6)
    for act in ["Idle", "Attack", "Hit", "Cast", "Roar", "Dead"]:
        a = bpy.data.actions[act]
        arm.animation_data.action = a
        if arm.animation_data.action_slot is None and len(a.slots):
            arm.animation_data.action_slot = a.slots[0]
        f0, f1 = int(a.frame_range[0]), int(a.frame_range[1])
        for i in range(6):
            f = f0 + round((f1 - f0) * i / 5)
            bpy.context.scene.frame_set(f)
            p = os.path.join(out, f"{tag}_{act}_{f:02d}.png"); bpy.context.scene.render.filepath = p
            bpy.ops.render.render(write_still=True); paths.append(p)
print("RENDERED", len(paths))
