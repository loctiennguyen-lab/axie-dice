extends Node
## Land v1: aesthetic score (spec §4 example = 21, cap of 3 per id, biome bonus).
var _f: Array[String] = []
func _ok(c: bool, m: String) -> void:
	if not c:
		_f.append(m)
func _e(id: String, n: int = 1) -> Array:
	var a: Array = []
	for i in n:
		a.append({"id": id, "x": float(i), "z": 0.0, "rot": 0})
	return a
func _ready() -> void:
	var ex: Array = _e("decor_sav_tree", 3) + _e("decor_arc_stone", 2) + _e("decor_terrarium_a4c")
	_ok(LandDecor.aesthetic(ex) == 21, "spec example 21, got %d" % LandDecor.aesthetic(ex))
	_ok(LandDecor.aesthetic([]) == 0, "empty")
	_ok(LandDecor.aesthetic(_e("decor_sav_tree", 5)) == 3 + 2, "4th+ copy scores 0")
	_ok(LandDecor.aesthetic(_e("decor_sav_tree") + _e("decor_sav_rock")) == 2 + 2, "same biome counts once")
	_ok(LandDecor.aesthetic(_e("decor_luna_tree") + _e("decor_for_tree")) == 8 + 1 + 4, "E + C + 2 biomes")
	for x in _f:
		print("FAIL ", x)
	print("t_decor_score: %s" % ("PASS" if _f.is_empty() else "FAIL"))
	get_tree().quit(1 if not _f.is_empty() else 0)
