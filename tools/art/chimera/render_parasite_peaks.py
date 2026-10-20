"""Peak frames (Cast 20, Roar 20, Attack 14, Idle 0) of the rigged Parasite .blend, front + 3/4.
Blender -b <file.blend> -P render_parasite_peaks.py -- --out <dir> [--tag before] [--size 640]"""
import bpy, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from parasite_common import arg, setup_render, camera_at
from mathutils import Vector
out = arg("out"); tag = arg("tag", "p"); size = int(arg("size", "640"))
arm = bpy.data.objects["ParasiteRig"]
setup_render((size, size))
for t in arm.animation_data.nla_tracks:
    t.mute = True
bpy.ops.mesh.primitive_plane_add(size=6, location=(0, 0, 0))
dirs = {"front": (0, -1, 0.1), "tq": (0.8, -1, 0.3)}
for view, d in dirs.items():
    camera_at(d, Vector((0, 0, 0.75)), 14, ortho=2.4)
    for act, f in (("Idle", 0), ("Cast", 20), ("Roar", 20), ("Attack", 14)):
        a = bpy.data.actions[act]
        arm.animation_data.action = a
        if arm.animation_data.action_slot is None and len(a.slots):
            arm.animation_data.action_slot = a.slots[0]
        bpy.context.scene.frame_set(f)
        bpy.context.scene.render.filepath = os.path.join(out, f"{tag}_{view}_{act}.png")
        bpy.ops.render.render(write_still=True)
print("RENDERED")
