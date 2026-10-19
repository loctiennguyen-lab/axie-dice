"""Needs Blender (imports bpy); no standalone run.
Savannah arena v2 - prop layout (lane V, 10/2026). Run inside Blender after the kit is imported.

Positions are GODOT world coordinates of the combat stage (x right, z toward the camera, y up);
Blender gets (x, -z, y). Heights are target heights in metres, measured from each kit mesh.
Keep-outs this layout respects (CombatStage3D.gd, 19/10):
  party + eggs  x [-11, -4]  z [-2.5, 8]      enemies x [-1.5, 5.5] z [-12.5, 8] (boss adds z -10.2)
  gate          x ~6.7 on z 1.1, march exits to x ~8
  HUD           top-left panels and the right enemy column cover the top corners, so tall props
                there only need to frame, not read.
"""
import math

import bpy
from mathutils import Vector

# kit object name -> short id
KIT = {
    'tree_acacia': 'SM_Tree02_Allside',
    'tree_palm': 'SM_Tree_01_Allside',
    'tree_baobab': 'SM_Tree03_1_Allside',
    'tree_baobab_s': 'SM_Tree03_2_Allside',
    'grass_a': 'SM_Shrub_01_AllSide_NoPlane',
    'grass_b': 'SM_Shrub_02_Allside',
    'grass_c': 'SM_Shrub_03_Allside',
    'rock_a': 'SM_SavannahRock_01',
    'rock_b': 'SM_SavannahRock_02',
    'mesa_wide': 'SM_Rock_Cliff_18',
    'mesa_a': 'SM_Rock_Cliff_12',
    'mesa_b': 'SM_Rock_Cliff_15',
    'butte': 'SM_Rock_Cliff_9',
    'ledge': 'SM_Rock_Cliff_3',
    'ledge_b': 'SM_Rock_Cliff_6',
    'ridge': 'SM_Rock_Cliff_0',
}

# (kit id, x, z, yaw_deg, height_m)
LAYOUT = [
    # back ridge: broken sandstone mesas along the top of the frame
    ('mesa_wide', -27.0, -27.0, 0, 8.5),
    ('mesa_b', -7.5, -25.5, 160, 7.0),
    ('ridge', 8.0, -27.5, 180, 6.0),
    ('mesa_a', 22.0, -24.0, 15, 8.0),
    # trees on the slope in front of the ridge (tops crop at the frame edge, like the Land rim)
    ('tree_baobab', -2.0, -21.0, 30, 8.0),
    ('tree_acacia', 4.5, -19.5, 200, 6.5),
    ('tree_acacia', -16.0, -19.0, 80, 7.0),
    ('tree_baobab_s', 13.0, -18.0, 120, 6.0),
    ('tree_palm', -24.0, -15.0, 0, 6.5),
    # smaller trees close enough that the whole canopy is in frame (colour against the sand)
    ('tree_acacia', -7.0, -14.5, 60, 4.2),
    ('tree_palm', 8.5, -13.0, 200, 3.8),
    ('tree_acacia', 17.5, -10.0, 300, 4.5),
    # low rock lip along the back of the field: reads as a terrace edge
    ('ledge_b', -3.0, -16.2, 10, 1.4),
    ('ridge', -27.0, -15.5, 90, 2.6),
    ('ledge', 14.5, -14.0, 140, 1.8),
    # upper-left outcrop (the big empty quarter above the party)
    ('butte', -18.0, -10.5, 25, 3.6),
    ('ledge', -13.5, -14.0, 200, 2.4),
    ('rock_b', -14.0, -8.0, 40, 1.4),
    ('rock_a', -20.5, -6.5, 300, 1.1),
    ('tree_baobab_s', -9.5, -16.5, 250, 5.5),
    ('tree_acacia', -22.5, -11.5, 140, 6.0),
    # grass clumps, in small groups at tree / rock feet so they read as tufts, not confetti
    ('grass_a', -15.8, -6.2, 0, 1.3),
    ('grass_b', -16.9, -7.0, 120, 1.0),
    ('grass_b', -11.8, -11.6, 50, 1.4),
    ('grass_c', -10.6, -12.6, 200, 1.1),
    ('grass_c', -20.0, -14.0, 120, 1.6),
    ('grass_a', -3.8, -18.2, 90, 1.5),
    ('grass_b', -0.6, -19.0, 10, 1.2),
    ('grass_c', 3.0, -17.6, 300, 1.4),
    ('grass_a', 6.4, -17.2, 30, 1.2),
    ('grass_b', 10.2, -15.8, 150, 1.4),
    # right of the gate (march exit side)
    ('rock_b', 12.5, -2.8, 200, 2.2),
    ('rock_a', 10.8, -0.6, 20, 1.0),
    ('grass_c', 11.8, 4.2, 70, 1.6),
    ('grass_a', 13.8, 1.6, 160, 1.4),
    ('grass_b', 10.6, -5.6, 240, 1.3),
    ('tree_acacia', 15.5, -7.5, 30, 7.0),
    ('grass_a', 8.8, 8.8, 0, 1.1),
    ('rock_b', 8.7, 6.0, 330, 1.3),
    ('grass_c', 9.8, 4.9, 80, 1.2),
    ('grass_b', 7.7, 7.4, 190, 0.9),
    ('rock_a', 10.5, 7.2, 120, 0.8),
    # lower-left corner
    ('grass_b', -11.6, 10.6, 20, 1.0),
    # a couple of pebbles in the field, away from every unit slot
    ('rock_a', -5.5, -9.0, 77, 0.35),
    ('rock_a', -13.2, -3.5, 160, 0.45),
]


# contact-shadow radius per kit id, as a fraction of the placed height
BLOB = {'rock_a': 0.9, 'rock_b': 1.0, 'grass_a': 0.7, 'grass_b': 0.7, 'grass_c': 0.7, 'tree_acacia': 0.35,
        'tree_palm': 0.25, 'tree_baobab': 0.4, 'tree_baobab_s': 0.4, 'butte': 0.9, 'ledge': 1.2}


def blobs():
    """(x, z, radius) pools for savannah_ground.paint(); the big mesas get none (they stand on the slope)."""
    return [(x, z, h * BLOB[k]) for (k, x, z, _y, h) in LAYOUT if k in BLOB]


def ground_y(ground, x, z):
    hit, loc, _n, _i = ground.ray_cast(Vector((x, -z, 50.0)), Vector((0, 0, -1)))
    return loc.z if hit else 0.0


def build(collection_name='Arena'):
    col = bpy.data.collections[collection_name]
    ground = bpy.data.objects['SA_Ground']
    for o in list(col.objects):
        if o.name.startswith('P_'):
            bpy.data.objects.remove(o, do_unlink=True)
    for i, (kid, x, z, yaw, h) in enumerate(LAYOUT):
        src = bpy.data.objects[KIT[kid]]
        o = bpy.data.objects.new('P_%02d_%s' % (i, kid), src.data)   # linked mesh -> glTF mesh instancing
        col.objects.link(o)
        s = h / max(src.dimensions.z, 1e-4)
        o.scale = (s, s, s)
        o.rotation_euler = (0.0, 0.0, math.radians(yaw))
        # sink a little so nothing floats on the slope
        o.location = (x, -z, ground_y(ground, x, z) - 0.05 * h)
    return len(LAYOUT)


if __name__ == '__main__':
    print(build())
