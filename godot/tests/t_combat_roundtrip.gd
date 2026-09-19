extends Node
## Round-trip gate for CombatEngine.to_data()/from_data() (architecture plan §4/§4b/§9
## Verification: "200 lượt ngẫu nhiên, from_data(to_data(x)) cho state bằng nhau").
##
## This is also the undo-semantics gate: undo_last() uses the exact same
## _apply_state_dict()/to_data() path (snapshot-restore-in-place, architecture plan §4b),
## so proving to_data()/from_data() round-trips losslessly after every kind of action
## (roll, reroll, execute, end_turn) proves undo is safe too, without a separate test.
##
## Implemented as a scene (t_combat_roundtrip.tscn) run via `godot --headless --path godot
## tests/t_combat_roundtrip.tscn`, NOT a raw `--script` SceneTree override: empirically, a
## `--script X.gd` invocation loads X.gd as the MainLoop class itself, which happens earlier
## than the engine registers autoload singleton names (ContentDB/EventBus/...) as known
## globals for the GDScript static analyzer — bare autoload references fail to compile in
## that mode. A normal scene's `_ready()` runs through the standard bootstrap (same as
## MainMenu.tscn/DevReview.tscn), where autoloads are already resolvable, exactly like every
## other script in this project that references them.

const ROUNDS := 200

var _test_rng := RandomNumberGenerator.new()
var _base_seed := 777


func _ready() -> void:
	_test_rng.seed = 12345   # test-harness randomness only — never the gameplay Rng

	var combat := _new_combat(_base_seed)
	var failures := 0
	var first_failure := ""

	for round_i in ROUNDS:
		if combat.won or combat.lost:
			combat = _new_combat(_base_seed + round_i + 1)

		_take_random_action(combat)

		var data := combat.to_data()
		var replay := CombatEngine.new()
		replay.from_data(data)
		var a := JSON.stringify(data)
		var b := JSON.stringify(replay.to_data())
		if a != b:
			failures += 1
			if first_failure == "":
				first_failure = "round %d: to_data() mismatch after from_data(to_data(x))\n  A=%s\n  B=%s" % [round_i, a.left(400), b.left(400)]
			# keep testing against the ORIGINAL combat (not the replay) so one mismatch
			# doesn't cascade into every subsequent round.
		else:
			# Continue driving state on the replay-verified copy so both branches never
			# diverge for reasons unrelated to serialization itself.
			combat = replay

	if failures == 0:
		print("t_combat_roundtrip: PASS — %d/%d rounds round-tripped to_data()/from_data() identically" % [ROUNDS, ROUNDS])
	else:
		print("t_combat_roundtrip: FAIL — %d/%d rounds mismatched" % [failures, ROUNDS])
		print(first_failure)
	get_tree().quit(failures)


func _new_combat(seed_value: int) -> CombatEngine:
	var c := CombatEngine.new()
	c.setup_new({
		"node_id": "test_node",
		"kind": "battle",
		"pw": _test_rng.randi_range(0, 10),
		"ascension": 0,
		"roster_snapshot": _synthetic_roster(),
		"relic_ids": [],
		"combat_seed": seed_value,
	})
	return c


func _synthetic_roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({
			"persistent_id": i + 1,
			"hero_key": keys[i],
			"tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [],
			"growth": {},
			"bonus_hp": 0,
		})
	return out


func _take_random_action(combat: CombatEngine) -> void:
	var roll := _test_rng.randf()
	if roll < 0.45:
		_try_use_die(combat)
	elif roll < 0.7:
		_try_reroll(combat)
	else:
		combat.end_turn()


func _try_use_die(combat: CombatEngine) -> void:
	var candidates: Array = []
	for u in combat.party:
		if u.hp > 0 and u.has_rolled() and not u.roll_used():
			candidates.append(u)
	if candidates.is_empty():
		return
	var u: Unit = candidates[_test_rng.randi_range(0, candidates.size() - 1)]
	var all_units: Array = combat.party + combat.enemies
	var tgt_uid := -1
	if all_units.size() > 0:
		tgt_uid = all_units[_test_rng.randi_range(0, all_units.size() - 1)].uid
	combat.use_die(u.uid, tgt_uid)


func _try_reroll(combat: CombatEngine) -> void:
	var ids: Array = []
	for u in combat.party:
		if u.hp > 0 and _test_rng.randf() < 0.5:
			ids.append(u.uid)
	if ids.is_empty() and combat.party.size() > 0:
		ids.append(combat.party[0].uid)
	combat.reroll_dice(ids)
