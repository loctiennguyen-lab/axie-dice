extends Node
## Land v1: placement rules (edge, zones, lanes, overlap, caps, storage), snap, rotation, sanitize.
var _f: Array[String] = []
func _ok(c: bool, m: String) -> void:
	if not c:
		_f.append(m)
func _ready() -> void:
	var ctx := {"zones": [{"p": Vector3(0, 0, 0), "r": 4.0}], "lanes": [[Vector3(0, 0, 10), Vector3(10, 0, 10)]], "props": [{"p": Vector3(-8, 0, -8), "r": 2.0}]}
	var owned := {"decor_sav_rock": 2, "decor_sav_shrub": 1}
	var P := Vector3(8, 0, -3)
	_ok(LandDecor.placement_block("decor_sav_rock", P, [], ctx, 1, owned) == "", "free spot ok")
	_ok(LandDecor.placement_block("decor_sav_rock", Vector3(15.3, 0, 0), [], ctx, 1, owned) != "", "edge")
	_ok(LandDecor.placement_block("decor_sav_rock", Vector3(1, 0, 1), [], ctx, 1, owned) != "", "zone")
	_ok(LandDecor.placement_block("decor_sav_rock", Vector3(5, 0, 10.4), [], ctx, 1, owned) != "", "lane")
	_ok(LandDecor.placement_block("decor_sav_rock", Vector3(-8, 0, -8.2), [], ctx, 1, owned) != "", "prop")
	_ok(LandDecor.placement_block("decor_sav_tree", P, [], ctx, 1, owned) != "", "none in storage")
	var placed := [{"id": "decor_sav_rock", "x": 8.0, "z": -3.0, "rot": 0}]
	_ok(LandDecor.placement_block("decor_sav_rock", Vector3(8.2, 0, -3), placed, ctx, 1, owned) != "", "overlap")
	_ok(LandDecor.placement_block("decor_sav_rock", Vector3(8.2, 0, -3), placed, ctx, 1, owned, 0) == "", "moving self ignores itself")
	_ok(LandDecor.placement_block("decor_sav_rock", Vector3(11, 0, -3), placed, ctx, 1, owned) == "", "second copy ok")
	var full: Array = []
	for i in 10:
		full.append({"id": "decor_sav_shrub", "x": float(i), "z": -12.0, "rot": 0})
	_ok(LandDecor.placement_block("decor_sav_rock", Vector3(12, 0, 6), full, ctx, 1, owned).contains("holds 10"), "tier cap tier1")
	_ok(not LandDecor.placement_block("decor_sav_rock", Vector3(12, 0, 6), full, ctx, 2, owned).contains("holds"), "tier2 holds more")
	_ok(LandDecor.snap(1.26) == 1.5 and LandDecor.snap(1.24) == 1.0 and LandDecor.snap(1.26, 0.01) == 1.26, "snap")
	_ok(LandDecor.rot_step(7) == 0 and LandDecor.rot_step(0, -1) == 7, "rot 8 steps")
	# sanitize: unknown id, off-land, over owned, over cap
	var raw := [{"id": "bogus", "x": 0, "z": 0, "rot": 0}, {"id": "decor_sav_rock", "x": 40.0, "z": 0.0, "rot": 9},
		{"id": "decor_sav_rock", "x": 5.0, "z": 5.0, "rot": 9}, {"id": "decor_sav_rock", "x": 6.0, "z": 5.0, "rot": 1},
		{"id": "decor_sav_rock", "x": 7.0, "z": 5.0, "rot": 1}]
	var clean := LandDecor.sanitize(raw, owned, 1)
	_ok(clean.size() == 2 and int(clean[0]["rot"]) == 1, "sanitize drops unknown/off-land/over-owned (%d)" % clean.size())
	_ok(LandDecor.sanitize(full, {"decor_sav_shrub": 99}, 1).size() == 10, "sanitize caps to tier")
	_ok(LandDecor.craft_block("decor_arc_tree", 1, {}, 999).contains("tier 3"), "craft tier gate")
	_ok(LandDecor.craft_block("decor_sav_tree", 1, {"decor_sav_tree": 6}, 999).contains("maximum"), "craft max_own")
	_ok(LandDecor.craft_block("decor_sav_tree", 1, {}, 39).contains("40"), "craft shard")
	_ok(LandDecor.craft_block("decor_sav_tree", 1, {}, 40) == "", "craft ok")
	_ok(LandDecor.craft_block("decor_trophy", 6, {}, 999) != "", "trophy not craftable")
	for x in _f:
		print("FAIL ", x)
	print("t_decor_rules: %s" % ("PASS" if _f.is_empty() else "FAIL"))
	get_tree().quit(1 if not _f.is_empty() else 0)
