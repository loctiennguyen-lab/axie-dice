"""Arena v2 (lane V) - prop layout shared by every biome. Needs Blender (imports bpy).

Positions are GODOT world coordinates of the combat stage (x right, z toward the camera, y up);
Blender gets (x, -z, y). Heights are target heights in metres (tuned on Savannah; biomes.ROLE_H
scales them per biome, biomes.EXTRAS adds biome-only props). Roles are explained in biomes.py.
check() rejects any prop whose centre falls in a keep-out of godot/assets/atia/arena_v2/stage_layout.json.
"""
import math
import os
import sys

import bpy
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import biomes  # noqa: E402
import ground  # noqa: E402

# (kit id, x, z, yaw_deg, height_m)
LAYOUT = [
    # back ridge: broken sandstone mesas along the top of the frame
    ('mesa_wide', -27.0, -27.0, 0, 8.5),
    ('mesa_b', -7.5, -25.5, 160, 7.0),
    ('ridge', 8.0, -27.5, 180, 6.0),
    ('mesa_a', 22.0, -24.0, 15, 8.0),
    # trees on the slope in front of the ridge (tops crop at the frame edge, like the Land rim)
    ('tree_c', -3.5, -22.5, 30, 8.0),
    ('tree_a', 6.0, -21.5, 200, 6.5),
    ('tree_a', -16.0, -19.0, 80, 7.0),
    ('tree_b', 13.0, -18.0, 120, 6.0),
    ('tree_d', -24.0, -15.0, 0, 6.5),
    # smaller trees close enough that the whole canopy is in frame (colour against the sand)
    ('tree_a', -7.0, -14.5, 60, 4.2),
    ('tree_d', 8.5, -13.0, 200, 3.8),
    ('tree_a', 17.5, -10.0, 300, 4.5),
    # low rock lip along the back of the field: reads as a terrace edge (clear of lane C's 2nd add row, z -18.3)
    ('ledge_b', -5.5, -15.5, 10, 1.4),
    ('ridge', -27.0, -15.5, 90, 2.6),
    ('ledge', 14.5, -14.0, 140, 1.8),
    # upper-left outcrop (the big empty quarter above the party)
    ('butte', -18.0, -10.5, 25, 3.6),
    ('ledge', -13.5, -14.0, 200, 2.4),
    ('rock_b', -14.0, -8.0, 40, 1.4),
    ('rock_a', -20.5, -6.5, 300, 1.1),
    ('tree_b', -9.5, -16.5, 250, 5.5),
    ('tree_a', -22.5, -11.5, 140, 6.0),
    # grass clumps, in small groups at tree / rock feet so they read as tufts, not confetti
    ('grass_a', -15.8, -6.2, 0, 1.3),
    ('grass_b', -16.9, -7.0, 120, 1.0),
    ('grass_b', -11.8, -11.6, 50, 1.4),
    ('grass_c', -10.6, -12.6, 200, 1.1),
    ('grass_c', -20.0, -14.0, 120, 1.6),
    ('grass_a', -5.2, -19.5, 90, 1.5),
    ('grass_b', 0.2, -22.0, 10, 1.2),
    ('grass_c', 4.6, -21.0, 300, 1.4),
    ('grass_a', 6.4, -17.2, 30, 1.2),
    ('grass_b', 10.2, -15.8, 150, 1.4),
    # right of the gate (march exit side)
    ('rock_b', 12.5, -2.8, 200, 2.2),
    ('rock_a', 10.8, -0.6, 20, 1.0),
    ('grass_c', 11.8, 4.2, 70, 1.6),
    ('grass_a', 13.8, 1.6, 160, 1.4),
    ('grass_b', 10.6, -5.6, 240, 1.3),
    ('tree_a', 15.5, -7.5, 30, 7.0),
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


# contact-shadow radius per role, as a fraction of the placed height
BLOB = {'rock_a': 0.9, 'rock_b': 1.0, 'grass_a': 0.7, 'grass_b': 0.7, 'grass_c': 0.7, 'tree_a': 0.35,
        'tree_d': 0.25, 'tree_c': 0.4, 'tree_b': 0.4, 'butte': 0.9, 'ledge': 1.2, 'log': 1.2, 'flower': 0.6}


# Trees spread wide only up in the canopy, so their ground footprint counts at a fraction of the box.
FOOTPRINT = {'tree_a': 0.35, 'tree_b': 0.35, 'tree_c': 0.35, 'tree_d': 0.35,
             # the big mesas are long and shallow; a circle round their box is far too wide
             'mesa_wide': 0.45, 'mesa_a': 0.45, 'mesa_b': 0.45, 'ridge': 0.45}


def placements(biome):
    """LAYOUT with the biome's height multipliers, plus its extras."""
    mul = biomes.ROLE_H.get(biome, {})
    out = [(k, x, z, yaw, h * mul.get(k, 1.0)) for (k, x, z, yaw, h) in LAYOUT]
    return out + list(biomes.EXTRAS.get(biome, []))


def check(biome, radius=None):
    """Raises if a prop's ground footprint (circle of `radius(kid, h)` metres, 0 = centre only)
    comes within unit_clearance of any unit slot (ground.unit_slots, lane C's formation incl. the
    second back row of adds) or its centre lands in a stage_layout keep-out (gate, march exit)."""
    st = ground.stage()
    slots = ground.unit_slots(st)
    clear = float(st.get('unit_clearance', 1.6))
    bad = []
    for (k, x, z, _yaw, h) in placements(biome):
        r = radius(k, h) if radius else 0.0
        for (sx, sz) in slots:
            if math.hypot(x - sx, z - sz) < r + clear:
                bad.append((k, x, z, 'unit slot (%.2f, %.2f)' % (sx, sz)))
                break
        for ko in st['keepouts']:
            if ko['x'][0] <= x <= ko['x'][1] and ko['z'][0] <= z <= ko['z'][1]:
                bad.append((k, x, z, ko['name']))
    if bad:
        raise ValueError('props too close to units / in keep-outs: %s' % bad)


def blobs(biome):
    """(x, z, radius) pools for ground.paint(); the big mesas get none (they stand on the slope)."""
    return [(x, z, h * BLOB[k]) for (k, x, z, _y, h) in placements(biome) if k in BLOB]


def ground_y(gobj, x, z):
    hit, loc, _n, _i = gobj.ray_cast(Vector((x, -z, 50.0)), Vector((0, 0, -1)))
    return loc.z if hit else 0.0


def build(biome):
    """Lays the props of `biome` into collection Arena_<biome> as linked duplicates of Kit_<biome>."""
    def footprint(kid, h):
        src = bpy.data.objects.get('K_%s_%s' % (biome, kid))
        if src is None:
            return 0.0
        s = h / max(src.dimensions.z, 1e-4)
        return 0.5 * max(src.dimensions.x, src.dimensions.y) * s * FOOTPRINT.get(kid, 1.0)

    check(biome, footprint)
    col = bpy.data.collections['Arena_' + biome]
    gobj = bpy.data.objects['G_%s_Ground' % biome]
    for o in list(col.objects):
        if o.name.startswith('P_%s_' % biome):
            bpy.data.objects.remove(o, do_unlink=True)
    n = 0
    for i, (kid, x, z, yaw, h) in enumerate(placements(biome)):
        src = bpy.data.objects.get('K_%s_%s' % (biome, kid))
        if src is None:
            continue
        o = bpy.data.objects.new('P_%s_%02d_%s' % (biome, i, kid), src.data)   # linked mesh -> glTF instancing
        col.objects.link(o)
        s = h / max(src.dimensions.z, 1e-4)
        o.scale = (s, s, s)
        if 'face_yaw' in src:      # camera-projected mesh: keep its painted side to the camera
            yaw = float(src['face_yaw']) + (yaw % 16.0) - 8.0
        o.rotation_euler = (0.0, 0.0, math.radians(yaw))
        o.location = (x, -z, ground_y(gobj, x, z) - 0.05 * h)   # sink a little so nothing floats
        n += 1
    return n
