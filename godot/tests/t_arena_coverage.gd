extends Node
## L1 lane C gate: assets/atia/arenas.json is well-formed. Every journey biome exists, every prop
## scene and the portal/path exist and load, and CombatArena3D.biome_for() spreads a run's rows
## over the whole journey (first row = first biome, last row = last biome, never out of range).

var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_arena_coverage: start ===")
	var reg := CombatArena3D.registry()
	_assert(not reg.is_empty(), "arenas.json did not load")
	var journey: Array = reg.get("journey", [])
	var biomes: Dictionary = reg.get("biomes", {})
	_assert(journey.size() == 6, "journey should list the 6 Land biomes, has %d" % journey.size())
	for b in journey:
		_assert(biomes.has(b), "journey biome '%s' has no entry" % b)
		var bb: Dictionary = biomes.get(b, {})
		_assert((bb.get("props", []) as Array).size() > 0, "biome '%s' has no props" % b)
		for k in ["ground", "sky_top", "sky_horizon", "fog", "light"]:
			_assert(bb.has(k), "biome '%s' missing %s" % [b, k])
		for e in bb.get("props", []):
			var sp := String(e.get("scene", ""))
			_assert(ResourceLoader.exists(sp), "biome '%s' prop %s missing" % [b, sp])
			_assert(sp.begins_with("res://assets/") and not sp.contains("asset-library"), "prop %s must live under res://assets/" % sp)
			_assert(["flank", "back", "low", "sky"].has(String(e.get("zone", ""))), "bad zone in '%s'" % b)
		var path := String(bb.get("path", ""))
		_assert(path == "" or ResourceLoader.exists(path), "biome '%s' path %s missing" % [b, path])
	_assert(ResourceLoader.exists(String(reg.get("portal", {}).get("scene", ""))), "portal scene missing")
	_assert(CombatArena3D.biome_for(1, false) == String(journey[0]), "row 1 should be the first biome")
	_assert(CombatArena3D.biome_for(18, false) == String(journey[journey.size() - 1]), "row 18 should be the last biome")
	_assert(CombatArena3D.biome_for(99, false) == String(journey[journey.size() - 1]), "row past the end clamps")
	_assert(CombatArena3D.biome_for(0, false) == String(journey[0]), "row 0 clamps")
	var seen := {}
	for row in range(1, 19):
		seen[CombatArena3D.biome_for(row, false)] = true
	_assert(seen.size() == journey.size(), "an 18-row run should visit every biome, saw %d" % seen.size())
	print("=== t_arena_coverage: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_arena_coverage: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_arena_coverage: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)
