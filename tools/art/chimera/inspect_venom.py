import bpy, os, sys
SRC = "/Users/loc.tien.nguyen/my-game/asset-library/chimera-src/Venom (Reptile)/3D"
for v in ["01","02","03","04","05"]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    d = os.path.join(SRC, "Reptile_"+v)
    for part in ["Body","Coat","Mask","Tail"]:
        bpy.ops.import_scene.fbx(filepath=os.path.join(d, f"SM_Reptile_{part}_{v}.fbx"))
    for o in bpy.data.objects:
        if o.type != 'MESH':
            print(v, "nonmesh", o.name, o.type); continue
        me = o.data
        tris = sum(len(p.vertices)-2 for p in me.polygons)
        import mathutils
        ws = [o.matrix_world @ mathutils.Vector(c) for c in o.bound_box]
        mn = [min(w[i] for w in ws) for i in range(3)]; mx = [max(w[i] for w in ws) for i in range(3)]
        mats = [m.name if m else None for m in me.materials]
        print(v, o.name, "verts", len(me.vertices), "tris", tris, "loc", tuple(round(x,3) for x in o.location), "rot", tuple(round(x,3) for x in o.rotation_euler), "scale", tuple(round(x,3) for x in o.scale),
              "min", [round(x,3) for x in mn], "max", [round(x,3) for x in mx], "mats", mats, "uv", len(me.uv_layers))
