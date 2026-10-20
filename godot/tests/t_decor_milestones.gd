extends Node
## Land v1: 8 milestones, claim grants cosmetics/titles/decor only (never Stone), once, via SaveStore.
var _f: Array[String] = []
func _ok(c: bool, m: String) -> void:
	if not c:
		_f.append(m)
func _ready() -> void:
	var g := SaveGuard.new()
	g.capture()
	MetaState.reload_from_store()
	_ok(LandDecor.milestones().size() == 8, "8 milestones")
	_ok(LandDecor.claimable(4, []).is_empty() and LandDecor.claimable(12, []).size() == 2, "claimable by score")
	_ok(String(LandDecor.next_milestone(12)["id"]) == "m3", "next milestone")
	_ok(LandDecor.claim("m1") != "", "cannot claim below score")
	MetaState.land_decor_owned = {"decor_luna_tree": 2, "decor_terrarium_a4c": 2, "decor_terrarium_f19a": 2}
	MetaState.land_decor_placed = []
	for id in ["decor_luna_tree", "decor_terrarium_a4c", "decor_terrarium_f19a"]:
		for i in 2:
			MetaState.land_decor_placed.append({"id": id, "x": float(i), "z": 0.0, "rot": 0})
	var stone := MetaState.stone
	_ok(LandDecor.aesthetic(MetaState.land_decor_placed) >= 5, "score reached")
	_ok(LandDecor.claim("m1") == "", "claim m1")
	_ok(MetaState.cosmetics_owned.has("title:Gardener"), "title granted")
	_ok(LandDecor.claim("m1") == "Already claimed.", "claim once")
	_ok(MetaState.stone == stone, "no Stone")
	_ok(LandDecor.claim("m2") != "" or LandDecor.aesthetic(MetaState.land_decor_placed) >= 12, "m2 gated")
	MetaState.land_milestones_claimed.clear()
	MetaState.land_decor_placed = []
	MetaState.land_decor_placed.append_array(_many(10))
	_ok(LandDecor.claim("m8") != "", "m8 needs 90")
	MetaState.reload_from_store()
	g.restore()
	for x in _f:
		print("FAIL ", x)
	print("t_decor_milestones: %s" % ("PASS" if _f.is_empty() else "FAIL"))
	get_tree().quit(1 if not _f.is_empty() else 0)
func _many(n: int) -> Array:
	var a: Array = []
	for i in n:
		a.append({"id": "decor_sav_tree", "x": float(i), "z": 0.0, "rot": 0})
	return a
