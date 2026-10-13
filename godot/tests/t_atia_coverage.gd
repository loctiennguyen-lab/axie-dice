extends Node
## L1 lane C gate (contract 4.3, production/l1-interfaces.md): every one of the 27 enemy keys
## resolves through MonsterArt.resolve() to glb / sprite / placeholder, every glb path exists
## and loads, and every clip named in `anims` exists in that model.
##
## Run: godot --headless --path godot res://tests/t_atia_coverage.tscn

const KINDS := ["glb", "sprite", "placeholder"]
const NON_ROSTER := ["egg"]   # summon token in ContentDB.enemies, not one of the 27 roster keys

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_atia_coverage: start ===")
	test_frozen_key_list_matches_content()
	test_every_key_resolves_to_a_valid_entry()
	test_elites_and_bosses_are_fitted_and_animated()
	test_unknown_key_falls_back_without_error()
	print("=== t_atia_coverage: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_atia_coverage: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_atia_coverage: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func test_frozen_key_list_matches_content() -> void:
	_assert(MonsterArt.NORMAL_KEYS.size() == 17, "expected 17 normal keys")
	_assert(MonsterArt.ELITE_KEYS.size() == 4, "expected 4 elite keys")
	_assert(MonsterArt.BOSS_KEYS.size() == 6, "expected 6 boss keys")
	for k in ContentDB.enemies.keys():
		if NON_ROSTER.has(String(k)):
			continue
		_assert(MonsterArt.NORMAL_KEYS.has(String(k)) or MonsterArt.ELITE_KEYS.has(String(k)),
			"ContentDB.enemies has '%s', not in the frozen key list — tell lane C" % k)
	for k in ContentDB.bosses.keys():
		if not ContentDB.bosses[k].has("die"):
			continue   # non-boss encounter entries (shrine, campfire, ...)
		_assert(MonsterArt.BOSS_KEYS.has(String(k)),
			"ContentDB.bosses has '%s', not in the frozen key list — tell lane C" % k)
	for k in MonsterArt.NORMAL_KEYS + MonsterArt.ELITE_KEYS:
		_assert(ContentDB.enemies.has(k), "frozen key '%s' is no longer in ContentDB.enemies" % k)
	for k in MonsterArt.BOSS_KEYS:
		_assert(ContentDB.bosses.has(k), "frozen boss key '%s' is no longer in ContentDB.bosses" % k)


func test_every_key_resolves_to_a_valid_entry() -> void:
	var all: Array = []
	for k in MonsterArt.NORMAL_KEYS + MonsterArt.ELITE_KEYS:
		all.append([k, false])
	for k in MonsterArt.BOSS_KEYS:
		all.append([k, true])
	for pair in all:
		var key: String = pair[0]
		var e := MonsterArt.resolve(key, pair[1])
		_assert(KINDS.has(String(e.get("kind", ""))), "'%s' resolves to bad kind '%s'" % [key, e.get("kind")])
		_assert(String(e.get("kind")) != "placeholder", "'%s' has no art at all (placeholder)" % key)
		var fb := String(e.get("fallback_sprite", ""))
		_assert(fb != "" and ResourceLoader.exists(MonsterArt.SPRITE_DIR + fb + ".png"),
			"'%s' fallback_sprite '%s' does not exist" % [key, fb])
		if String(e.get("kind")) != "glb":
			continue
		var path := String(e.get("path", ""))
		_assert(path.begins_with("res://assets/") and not path.contains("asset-library"),
			"'%s' path '%s' must live under res://assets/" % [key, path])
		_assert(ResourceLoader.exists(path), "'%s' path %s does not exist" % [key, path])
		var packed := load(path) as PackedScene
		_assert(packed != null, "'%s' %s does not load as a scene" % [key, path])
		if packed == null:
			continue
		var inst := packed.instantiate()
		var clips := {}
		for n in _walk(inst):
			if n is AnimationPlayer:
				for c in (n as AnimationPlayer).get_animation_list():
					clips[String(c)] = true
		for slot in (e.get("anims", {}) as Dictionary).keys():
			var clip := String(e["anims"][slot])
			if clip == "":
				continue
			_assert(clips.has(clip), "'%s' anim %s -> '%s' not in model (has %s)" % [key, slot, clip, clips.keys()])
		inst.free()


## B6: every elite/boss resolves to a real model (Atia or mascot) or its Chimera sprite, is sized
## above rank-and-file (2.2 m), and a 3D one has at least an idle clip so it is never frozen.
func test_elites_and_bosses_are_fitted_and_animated() -> void:
	for pair in [[MonsterArt.ELITE_KEYS, false, 2.8], [MonsterArt.BOSS_KEYS, true, 4.0]]:
		for key in pair[0]:
			var e := MonsterArt.resolve(String(key), pair[1])
			_assert(String(e.get("source", "")) != "" or String(e.get("kind")) == "glb", "'%s' registry entry has no source" % key)
			if String(e.get("kind")) == "glb":
				_assert(float(e.get("height_m", 0.0)) >= float(pair[2]), "'%s' height_m %s below %s" % [key, e.get("height_m"), pair[2]])
				var a: Dictionary = e.get("anims", {})
				_assert(a.has("idle") and (not pair[1] or a.has("die")), "'%s' glb needs idle (+ die for bosses), has %s" % [key, a.keys()])
			else:
				_assert(String(e.get("kind")) == "sprite", "'%s' is neither glb nor sprite" % key)


func test_unknown_key_falls_back_without_error() -> void:
	var e := MonsterArt.resolve("no_such_monster_key", false)
	_assert(String(e.get("kind")) == "placeholder", "unknown key should resolve to placeholder")


func _walk(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_walk(c))
	return out
