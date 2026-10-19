"""Rest views + clip contact sheets of the rigged Feral .blend.
Blender -b <file.blend> -P render_feral.py -- --out <dir> [--view front|tq|side|back] [--size 384] [--rest 1] [--clips 1]"""
import bpy, os, sys, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from feral_common import arg, setup_render, camera_at
from mathutils import Vector
out = arg("out"); size = int(arg("size", "400")); views = arg("view", "front").split(",")
arm = bpy.data.objects["FeralRig"]
setup_render((size, size))
for t in arm.animation_data.nla_tracks:
    t.mute = True
bpy.ops.mesh.primitive_plane_add(size=6, location=(0, 0, -0.95))
fl = bpy.context.object
m = bpy.data.materials.new("F"); m.diffuse_color = (0.3, 0.3, 0.3, 1); m.use_nodes = True
fl.data.materials.append(m)
dirs = {"tq": (0.8, -1, 0.3), "front": (0, -1, 0.05), "side": (1, 0, 0.05), "back": (0, 1, 0.05)}
for view in views:
    camera_at(dirs[view], Vector((0, 0, float(arg("cz","0.0")))), 14, ortho=float(arg("ortho","2.3")))
    if arg("rest"):
        arm.animation_data.action = None
        bpy.context.scene.render.filepath = os.path.join(out, f"rest_{view}.png")
        bpy.ops.render.render(write_still=True)
    if arg("clips"):
        for act in ["Idle", "Attack", "Hit", "Cast", "Roar", "Dead"]:
            a = bpy.data.actions[act]
            arm.animation_data.action = a
            if arm.animation_data.action_slot is None and len(a.slots):
                arm.animation_data.action_slot = a.slots[0]
            f0, f1 = int(a.frame_range[0]), int(a.frame_range[1])
            for i in range(6):
                f = f0 + round((f1 - f0) * i / 5)
                bpy.context.scene.frame_set(f)
                bpy.context.scene.render.filepath = os.path.join(out, f"{view}_{act}_{i}.png")
                bpy.ops.render.render(write_still=True)
