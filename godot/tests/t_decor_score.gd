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
	# Beta (LD-D 26/10): best reachable score per tier, from decor.json (craftable decor only, no Trophy)
	_ok(_max_score(1) == 14, "T1 max 14, got %d" % _max_score(1))
	_ok(_max_score(2) == 32, "T2 max 32, got %d" % _max_score(2))
	_ok(_max_score(3) == 54, "T3 max 54, got %d" % _max_score(3))
	var m4 := 0
	for m in LandDecor.milestones():
		if String(m["id"]) == "m4":
			m4 = int(m["points"])
	_ok(_max_score(2) >= m4 + 2, "T2 ceiling %d must be >= m4 (%d) + 2" % [_max_score(2), m4])
	for x in _f:
		print("FAIL ", x)
	print("t_decor_score: %s" % ("PASS" if _f.is_empty() else "FAIL"))
	get_tree().quit(1 if not _f.is_empty() else 0)

## Greedy best score at `tier`: top tier_cap copies by points (each id counts 3 at most), then 2 per distinct biome used.
func _max_score(tier: int) -> int:
	var pts := LandDecor.data()["rarity_points"] as Dictionary
	var copies: Array = []
	for d in LandDecor.all_defs():
		if not bool(d["craftable"]) or int(d["min_tier"]) > tier:
			continue
		for i in mini(3, int(d["max_own"])):
			copies.append({"p": int(pts[String(d["rarity"])]), "b": String(d["biome"])})
	copies.sort_custom(func(a, b): return a["p"] > b["p"])
	var cap := LandDecor.tier_cap(tier)
	var used := {}
	var biomes := {}
	for i in copies.size(): # one copy of every biome first (the +2 bonus)
		var bi := String(copies[i]["b"])
		if bi != "" and not biomes.has(bi):
			biomes[bi] = true
			used[i] = true
	for i in copies.size():
		if used.size() >= cap:
			break
		used[i] = true
	var total := 0
	for i in used:
		total += int(copies[i]["p"])
	return total + 2 * biomes.size()
