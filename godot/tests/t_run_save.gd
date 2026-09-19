extends Node
## Gate for CONTINUE RUN: a saved run must come back as the run that was saved.
##
## WHY THIS GOES THROUGH REAL JSON
## ------------------------------
## `t_combat_roundtrip` already round-trips a CombatEngine 200 times and passes. It cannot
## catch what this test exists for, because it round-trips IN MEMORY: `to_data()` returns
## dictionaries and `from_data()` reads them back with their types intact.
##
## A save file does not work that way. `JSON.stringify` turns every integer key into a string
## and every number into a float, so a `growth` dictionary written as `{3: 2}` comes back as
## `{"3": 2.0}`. Nothing errors. `growth.get(3, 0)` simply misses and returns 0, and the player
## loses every point of accumulated growth on resume — a silent, permanent loss of progress
## that looks exactly like growth having never been very strong.
##
## So every assertion below serialises with `JSON.stringify` and parses with
## `JSON.parse_string` first. If that step were removed, this file would pass while the feature
## was broken.
##
## Run: godot --headless --path godot res://tests/t_run_save.tscn

const SEEDS := [11, 2024, 90210, 777, 31337]

var _failures: Array[String] = []
var _checks := 0


## Borrows the player's real save file and puts it back byte for byte — this gate writes to the
## real `MetaState` autoload. See `save_guard.gd` for why a hand-written field list is not enough.
var _save_guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_run_save: start ===")
	_save_guard.capture()
	test_run_state_survives_a_json_round_trip()
	test_roster_growth_keys_survive_json_as_integers()
	test_unit_growth_keys_survive_json_as_integers()
	test_run_mod_multipliers_stay_fractional()
	test_saving_and_loading_restores_a_mid_combat_fight()
	test_a_finished_run_leaves_no_resumable_save()
	test_a_wrong_version_save_is_refused_not_half_loaded()
	test_quitting_a_fight_leaves_it_resumable()
	_save_guard.restore()

	print("=== t_run_save: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_run_save: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_run_save: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


## The step that matters: everything a save file does to the data on its way to disk and back.
func _through_json(d: Dictionary) -> Dictionary:
	var parsed = JSON.parse_string(JSON.stringify(d))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


## A stable string for comparing two nested structures. JSON does not preserve dictionary key
## order, so comparing `str(a) == str(b)` reports every dictionary as changed even when every
## key and value is identical — which is what the first version of this test did, producing ten
## failures that were entirely the test's own fault. Sorting keys compares the DATA instead of
## the order Godot happened to hash it into.
func _canon(v) -> String:
	match typeof(v):
		TYPE_DICTIONARY:
			var keys: Array = (v as Dictionary).keys()
			keys.sort_custom(func(a, b): return str(a) < str(b))
			var parts: Array = []
			for k in keys:
				parts.append("%s=%s" % [str(k), _canon((v as Dictionary)[k])])
			return "{" + ",".join(PackedStringArray(parts)) + "}"
		TYPE_ARRAY:
			var items: Array = []
			for x in (v as Array):
				items.append(_canon(x))
			return "[" + ",".join(PackedStringArray(items)) + "]"
		TYPE_FLOAT:
			# JSON has one number type: an int written out comes back as a float. Comparing
			# "6" to "6.0" would flag every integer field as changed.
			var f: float = v
			return str(int(f)) if is_equal_approx(f, float(int(f))) else str(f)
		TYPE_INT:
			return str(v)
		_:
			return str(v)


func _start_run(seed_value: int) -> void:
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
	RunState.reset()
	RunState.start_new_run(seed_value, team, "short", 0, false)


# ---------------------------------------------------------------------------

func test_run_state_survives_a_json_round_trip() -> void:
	for seed_value in SEEDS:
		# Arrange — a run that has actually progressed, so the fields under test are non-default.
		_start_run(seed_value)
		RunState.shards_this_run = 137
		RunState.power_level = 6
		RunState.bonus_reroll = 2
		RunState.owned_relic_ids = ["r_claw", "r_ember", "r_ancientgene"]
		RunState.visited_node_ids = ["r1_c0", "r2_c1"]
		RunState.set_phase(RunState.RunPhase.MAP)
		var before := RunState.to_data()

		# Act
		RunState.from_data(_through_json(before))
		var after := RunState.to_data()

		# Assert — compared field by field so a failure names the field, not "dictionaries differ".
		for key in before.keys():
			_assert(_canon(before[key]) == _canon(after[key]),
				"seed %d: field '%s' changed across a JSON save/load: %s -> %s"
					% [seed_value, key, _canon(before[key]), _canon(after[key])])


## The specific corruption this whole file exists for, asserted on the roster.
func test_roster_growth_keys_survive_json_as_integers() -> void:
	_start_run(4242)
	RunState.set_phase(RunState.RunPhase.MAP)
	# Arrange — growth as the engine writes it: integer face indexes.
	var entry: Dictionary = RunState.roster[0]
	entry["growth"] = {0: 3, 2: 1, 5: 4}

	# Act
	RunState.from_data(_through_json(RunState.to_data()))

	# Assert
	var restored: Dictionary = (RunState.roster[0] as Dictionary).get("growth", {})
	for face_index in [0, 2, 5]:
		_assert(restored.has(face_index),
			"roster growth lost face %d after a JSON round trip — keys came back as %s"
				% [face_index, str(restored.keys())])
	_assert(int(restored.get(0, -1)) == 3 and int(restored.get(2, -1)) == 1
			and int(restored.get(5, -1)) == 4,
		"roster growth values changed across a JSON round trip: %s" % str(restored))


## And on a Unit, which takes the other path (Unit.from_data, not RunState.from_data).
func test_unit_growth_keys_survive_json_as_integers() -> void:
	var u := Unit.new()
	u.uid = 7
	u.growth = {1: 2, 4: 5}
	var restored := Unit.from_data(_through_json(u.to_data()))
	for face_index in [1, 4]:
		_assert(restored.growth.has(face_index),
			"Unit growth lost face %d after a JSON round trip — keys came back as %s"
				% [face_index, str(restored.growth.keys())])
	_assert(int(restored.growth.get(1, -1)) == 2 and int(restored.growth.get(4, -1)) == 5,
		"Unit growth values changed across a JSON round trip: %s" % str(restored.growth))


## CURSE PACT writes fractional multipliers. JSON gives every number back as a float, and an
## int() cast anywhere on this path would turn a 1.5x enemy-HP curse into 1x — the run would
## quietly get easier on resume.
func test_run_mod_multipliers_stay_fractional() -> void:
	_start_run(555)
	RunState.set_phase(RunState.RunPhase.MAP)
	RunState.run_mods = {"enemy_hp": 1.45, "enemy_dmg": 1.2}
	RunState.from_data(_through_json(RunState.to_data()))
	_assert(is_equal_approx(float(RunState.run_mods["enemy_hp"]), 1.45),
		"run_mods.enemy_hp came back as %s, not 1.45" % RunState.run_mods["enemy_hp"])
	_assert(is_equal_approx(float(RunState.run_mods["enemy_dmg"]), 1.2),
		"run_mods.enemy_dmg came back as %s, not 1.2" % RunState.run_mods["enemy_dmg"])


## The end-to-end path, through a real file: fight for a few turns, save, wipe the autoload,
## load, and require the fight to come back where it was.
func test_saving_and_loading_restores_a_mid_combat_fight() -> void:
	_start_run(8080)
	RunState.enter_node("r3_c1", "battle")
	var combat := CombatEngine.new()
	combat.setup_new(RunState.pending_combat)
	RunState.pending_combat = {}
	RunState.set_phase(RunState.RunPhase.COMBAT)

	# Act — two turns of a real fight, so turn/mana/HP are all off their starting values.
	combat.end_turn()
	combat.end_turn()
	var want_turn := combat.turn
	var want_enemy_hp: Array = []
	for e in combat.enemies:
		want_enemy_hp.append(e.hp)
	RunState.save_run(combat.to_data())

	_assert(RunState.has_saved_run(), "save_run() wrote no file for an in-progress combat")
	RunState.reset()
	_assert(RunState.load_run(), "load_run() refused a file save_run() had just written")

	# Assert — the run came back, and it came back mid-fight rather than at the node's start.
	_assert(RunState.run_seed == 8080,
		"restored run has seed %d, expected 8080" % RunState.run_seed)
	_assert(not RunState.resume_combat.is_empty(),
		"a run saved mid-combat restored with no combat snapshot — CONTINUE RUN would restart "
		+ "the fight with fresh, full-health enemies")

	var resumed := CombatEngine.new()
	resumed.from_data(RunState.resume_combat)
	_assert(resumed.turn == want_turn,
		"resumed fight is on turn %d, the save was on turn %d" % [resumed.turn, want_turn])
	_assert(resumed.enemies.size() == want_enemy_hp.size(),
		"resumed fight has %d enemies, the save had %d"
			% [resumed.enemies.size(), want_enemy_hp.size()])
	for i in mini(resumed.enemies.size(), want_enemy_hp.size()):
		_assert(resumed.enemies[i].hp == int(want_enemy_hp[i]),
			"resumed enemy %d has %d HP, the save had %d"
				% [i, resumed.enemies[i].hp, int(want_enemy_hp[i])])
	RunState.clear_saved_run()


## JS removes the slot once the run is won or lost (client.html:3420). A finished run that
## still offers CONTINUE would drop the player back into a fight they had already resolved.
func test_a_finished_run_leaves_no_resumable_save() -> void:
	_start_run(31415)
	RunState.set_phase(RunState.RunPhase.MAP)
	RunState.save_run({})
	_assert(RunState.has_saved_run(), "an in-progress run left no save")

	RunState.end_run(false)
	_assert(not RunState.has_saved_run(),
		"the save survived end_run() — the menu would offer CONTINUE for a finished run")

	# And a save attempt made while the run is already over must not recreate it.
	RunState.set_phase(RunState.RunPhase.LOST)
	RunState.save_run({})
	_assert(not RunState.has_saved_run(),
		"save_run() wrote a slot for a run in the LOST phase")


## A save written by a different build must be refused outright. Half-loading one is worse
## than ignoring it: the run would look restored and be wrong in ways nobody can see.
func test_a_wrong_version_save_is_refused_not_half_loaded() -> void:
	var path: String = RunState.SAVE_PATH
	var f := FileAccess.open(path, FileAccess.WRITE)
	_assert(f != null, "could not write a fixture save file")
	if f == null:
		return
	f.store_string(JSON.stringify({
		"version": RunState.SAVE_VERSION + 99,
		"run": {"run_seed": 12345, "power_level": 99},
		"combat": {},
	}))
	f.close()

	_start_run(600)                      # a real, current run in memory
	var seed_before := RunState.run_seed
	_assert(not RunState.load_run(), "load_run() accepted a save from another version")
	_assert(RunState.run_seed == seed_before,
		"load_run() refused the file but had already overwritten the live run (seed %d -> %d)"
			% [seed_before, RunState.run_seed])
	RunState.clear_saved_run()

	# Same for a file that is not JSON at all.
	var f2 := FileAccess.open(path, FileAccess.WRITE)
	if f2 != null:
		f2.store_string("this is not json {{{")
		f2.close()
	_assert(not RunState.load_run(), "load_run() accepted a file that is not JSON")
	RunState.clear_saved_run()
	_assert(not RunState.has_saved_run(), "clear_saved_run() left the file behind")


## The Quit button's contract. It is not what makes progress survive — every action already
## saves — but it is the only path that a player takes deliberately, and a save written on the
## way out must land the player back in the same fight rather than at the node's start.
func test_quitting_a_fight_leaves_it_resumable() -> void:
	_start_run(90909)
	RunState.enter_node("r4_c0", "battle")
	var combat := CombatEngine.new()
	combat.setup_new(RunState.pending_combat)
	RunState.pending_combat = {}
	RunState.set_phase(RunState.RunPhase.COMBAT)
	combat.end_turn()
	var want_turn := combat.turn

	# Act — what CombatView._on_quit_confirmed() does before changing scene.
	RunState.save_run(combat.to_data())
	RunState.reset()

	# Assert
	_assert(RunState.load_run(), "a run quit from combat could not be loaded back")
	_assert(not RunState.resume_combat.is_empty(),
		"quitting from a fight saved no combat snapshot — CONTINUE RUN would restart the node")
	_assert(int((RunState.resume_combat as Dictionary).get("turn", -1)) == want_turn,
		"resumed fight is on turn %s, the quit happened on turn %d"
			% [(RunState.resume_combat as Dictionary).get("turn", "?"), want_turn])
	_assert(String((RunState.resume_combat as Dictionary).get("node_id", "")) == "r4_c0",
		"resumed fight is at node '%s', the quit happened at r4_c0"
			% (RunState.resume_combat as Dictionary).get("node_id", ""))
	RunState.clear_saved_run()
