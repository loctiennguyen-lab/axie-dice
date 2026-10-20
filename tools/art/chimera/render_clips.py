"""Clip contact sheet of the rigged Brine .blend: rows = clips, 6 frames each, one PNG per view.
Blender -b <rigged.blend> -P render_clips.py -- --out <dir> [--view front|tq] [--size 300]"""
import bpy, os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from brine_common import arg, setup_render, camera_at
from mathutils import Vector
out = arg("out"); size = int(arg("size", "300")); view = arg("view", "front")
arm = bpy.data.objects["BrineRig"]
setup_render((size, size))
for t in arm.animation_data.nla_tracks:
    t.mute = True
bpy.ops.mesh.primitive_plane_add(size=8, location=(0, 0, 0))
fl = bpy.context.object
m = bpy.data.materials.new("F"); m.diffuse_color = (0.3, 0.3, 0.3, 1); m.use_nodes = True
fl.data.materials.append(m)
dirs = {"tq": (0.8, -1, 0.35), "front": (0, -1, 0.1)}
camera_at(dirs[view], Vector((0.1, 0, 0.7)), 14, ortho=2.5)
clips = ["Idle", "Attack", "Hit", "Cast", "Roar", "Dead"]
sheet = np.zeros((size * len(clips), size * 6, 4), dtype=np.float32)
tmp = os.path.join(out, "_t.png")
for r, act in enumerate(clips):
    a = bpy.data.actions[act]
    arm.animation_data.action = a
    if arm.animation_data.action_slot is None and len(a.slots):
        arm.animation_data.action_slot = a.slots[0]
    f0, f1 = int(a.frame_range[0]), int(a.frame_range[1])
    for i in range(6):
        f = f0 + round((f1 - f0) * i / 5)
        bpy.context.scene.frame_set(f)
        bpy.context.scene.render.filepath = tmp
        bpy.ops.render.render(write_still=True)
        im = bpy.data.images.load(tmp)
        px = np.zeros(size * size * 4, dtype=np.float32); im.pixels.foreach_get(px)
        sheet[(len(clips) - 1 - r) * size:(len(clips) - r) * size, i * size:(i + 1) * size] = px.reshape(size, size, 4)
        bpy.data.images.remove(im)
res = bpy.data.images.new("sheet", size * 6, size * len(clips), alpha=False)
res.pixels.foreach_set(sheet.ravel())
res.filepath_raw = os.path.join(out, "clips_%s.png" % view); res.file_format = 'PNG'; res.save()
os.remove(tmp)
print("RENDERED")
