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
			_assert(["flank", "back", "low", "low_g", "sky"].has(String(e.get("zone", ""))), "bad zone in '%s'" % b)
		var path := String(bb.get("path", ""))
		_assert(path == "" or ResourceLoader.exists(path), "biome '%s' path %s missing" % [b, path])
	_assert(ResourceLoader.exists(String(reg.get("portal", {}).get("scene", ""))), "portal scene missing")
	_assert(CombatArena3D.biome_for(1, false) == String(journey[0]), "row 1 should be the first biome")
	_assert(CombatArena3D.biome_for(18, false) == String(journey[journey.size() - 1]), "row 18 should be the last biome")
	_assert(CombatArena3D.biome_for(99, false) == String(journey[journey.size() - 1]), "row past the end clamps")
	_assert(CombatArena3D.biome_for(0, false) == String(journey[0]), "row 0 clamps")
	# a boss keeps its row's biome (journey stays consistent) and the choice is a pure function
	for row in range(1, 19):
		_assert(CombatArena3D.biome_for(row, true) == CombatArena3D.biome_for(row, false),
			"boss row %d keeps the row biome" % row)
		_assert(CombatArena3D.biome_for(row, true, 30) == CombatArena3D.biome_for(row, true, 30), "deterministic")
	var seen := {}
	for row in range(1, 19):
		seen[CombatArena3D.biome_for(row, false)] = true
	_assert(seen.size() == journey.size(), "an 18-row run should visit every biome, saw %d" % seen.size())
	_check_scene_deps("res://assets/atia/arena/scenes")
	await _check_framing(journey)
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


## Every arena scene: all dependencies exist on disk (a clean checkout must not have broken
## refs, e.g. files swallowed by .gitignore) and the scene instantiates.
func _check_scene_deps(dir_path: String) -> void:
	var scenes: Array[String] = []
	_collect(dir_path, scenes)
	_assert(scenes.size() > 0, "no arena scenes found under %s" % dir_path)
	for sp in scenes:
		for d in ResourceLoader.get_dependencies(sp):
			# get_dependencies returns "uid::type::path" or plain path; take the last part
			var parts := String(d).split("::")
			var dp := parts[parts.size() - 1]
			if dp == "":
				dp = parts[0]
			_assert(ResourceLoader.exists(dp) or FileAccess.file_exists(dp), "%s depends on missing %s" % [sp, dp])
		var ps := load(sp) as PackedScene
		_assert(ps != null, "%s does not load" % sp)
		if ps != null:
			var inst := ps.instantiate()
			_assert(inst != null, "%s does not instantiate" % sp)
			if inst != null:
				inst.free()


func _collect(dir_path: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir_path):
		if f.ends_with(".tscn"):
			out.append(dir_path.path_join(f))
	for d in DirAccess.get_directories_at(dir_path):
		_collect(dir_path.path_join(d), out)


## The portal tower must not touch the frame top (16:9 stage) in any biome, normal or boss, and
## no prop may sit inside the enemy-flank / portal-line keep-out.
func _check_framing(journey: Array) -> void:
	_assert(CombatArena3D.in_keepout(0.0, -30.0), "portal line should be keep-out")
	_assert(CombatArena3D.in_keepout(5.0, -6.5), "enemy row should be keep-out")
	_assert(not CombatArena3D.in_keepout(15.0, -6.5), "far flank should be allowed")
	var stage: CombatStage3D = load("res://scenes/shared/CombatStage3D.tscn").instantiate()
	add_child(stage)
	await get_tree().process_frame
	for b in journey:
		for boss in [false, true]:
			stage.set_arena(String(b), boss)
			var m: float = stage.portal_top_margin()
			print("  margin ", b, " boss=", boss, " ", snappedf(m, 0.001))
			_assert(m >= (0.012 if boss else 0.03), "%s boss=%s portal top margin %.3f too small" % [b, boss, m])
			var arena: Node = stage.get("_arena")
			var root: Node = arena.get("_props_root")
			for n in root.get_children():
				if n is Node3D and not (n is MeshInstance3D) and not (n is OmniLight3D) and not (n is MultiMeshInstance3D) \
						and n != arena.get("_portal") and n.position.z > -30.0 and n.position.z < 6.0 and n.position.x != 0.0:
					_assert(not CombatArena3D.in_keepout(n.position.x, n.position.z) or n.position.z == 8.0 or n.position.x == 0.0,
						"%s prop %s inside keep-out at %s" % [b, n.name, n.position])
	stage.queue_free()
