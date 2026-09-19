extends Node
## Gate for the build-time die-mutation pass (`modFace`) and the INV-5 ordering it must obey.
##
## `modFace` had NO call site anywhere in the Godot port until the Phase-1 parity pass. That
## single gap blocked 31 of the 94 relics — every relic that permanently rewrites a die face —
## and no amount of relic authoring could have worked around it. It also made the CURSE PACT
## reward a pure downside, because JS delivers that reward's upside through a pseudo-relic
## whose entire body is a modFace (src/engine.js:1188-1189).
##
## The ordering assertion is the important one. src/engine.js:36-47 explains why at length:
## with pickup-order application, `+1` then `x1.3` gives (v+1)*1.3 or v*1.3+1 depending purely
## on which relic the run happened to offer first, so a relic's power stops being a NUMBER and
## becomes a RANGE. Sorting by [phase, rarity, sort_index] makes the result independent of
## pickup order — that is INV-1, not a nicety.
##
## Run: godot --headless --path godot res://tests/t_mod_face.tscn

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_mod_face: start ===")
	test_curse_pact_adds_four_to_every_damage_face()
	test_curse_pact_leaves_non_damage_faces_alone()
	test_mod_face_result_is_independent_of_pickup_order()
	test_mod_face_phases_run_keyword_then_add_then_multiply()
	test_pseudo_relics_are_never_offered_as_loot()

	print("=== t_mod_face: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_mod_face: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_mod_face: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _roster(keys: Array) -> Array:
	var out: Array = []
	for i in keys.size():
		out.append({
			"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [], "growth": {}, "bonus_hp": 0,
		})
	return out


func _combat(relic_ids: Array) -> CombatEngine:
	var c := CombatEngine.new()
	c.setup_new({
		"node_id": "t_mod_face", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": _roster(["plant1", "beast1", "aqua1", "reptile1", "bug1"]),
		"relic_ids": relic_ids, "combat_seed": 1234, "bonus_reroll": 0,
	})
	return c


## Face values of party member `i`, as built into the combat (post-modFace).
func _faces(c: CombatEngine, i: int) -> Array:
	var out: Array = []
	for f in (c.party[i] as Unit).die:
		out.append([String((f as Dictionary).get("type", "")), int((f as Dictionary).get("value", 0))])
	return out


# ---------------------------------------------------------------------------

func test_curse_pact_adds_four_to_every_damage_face() -> void:
	# Arrange
	var plain := _combat([])
	var cursed := _combat(["__curse_dmg"])

	# Act / Assert
	for i in plain.party.size():
		var before := _faces(plain, i)
		var after := _faces(cursed, i)
		_assert(before.size() == after.size(),
			"party %d die length changed under CURSE PACT: %d vs %d" % [i, before.size(), after.size()])
		for f in before.size():
			var t: String = before[f][0]
			var expected: int = (int(before[f][1]) + 4) if t == "dmg" else int(before[f][1])
			_assert(int(after[f][1]) == expected,
				"party %d face %d (%s): expected %d under CURSE PACT, got %d"
					% [i, f, t, expected, int(after[f][1])])


func test_curse_pact_leaves_non_damage_faces_alone() -> void:
	# Arrange — JS: `u.die.forEach(f => { if (f.t === 'dmg') f.v += 4 })`. Shield, heal, mana,
	# poison and blank faces must be untouched; a blanket +4 would silently rebalance the game.
	var plain := _combat([])
	var cursed := _combat(["__curse_dmg"])

	# Act / Assert
	var non_dmg_checked := 0
	for i in plain.party.size():
		var before := _faces(plain, i)
		var after := _faces(cursed, i)
		for f in before.size():
			if String(before[f][0]) != "dmg":
				non_dmg_checked += 1
				_assert(int(after[f][1]) == int(before[f][1]),
					"party %d face %d is '%s' and must be unchanged, went %d -> %d"
						% [i, f, before[f][0], int(before[f][1]), int(after[f][1])])
	_assert(non_dmg_checked > 0,
		"the test roster contained no non-damage faces, so this check proved nothing")


func test_mod_face_result_is_independent_of_pickup_order() -> void:
	# Arrange — INV-5. Ordering must come from relic DATA, so the same relic set in a
	# different pickup order must build byte-identical dice.
	var owned := ["__curse_dmg"]
	for def in RelicRegistry.offerable_defs_sorted():
		if owned.size() >= 4:
			break
		owned.append(String(def.id))
	var reversed_owned := owned.duplicate()
	reversed_owned.reverse()

	# Act
	var forward := _combat(owned)
	var backward := _combat(reversed_owned)

	# Assert
	_assert(owned.size() >= 2, "need at least 2 relics to test ordering, had %d" % owned.size())
	for i in forward.party.size():
		_assert(_faces(forward, i) == _faces(backward, i),
			"party %d built DIFFERENT dice depending on relic pickup order (INV-5 violation)\n"
				% i
			+ "  order %s -> %s\n  order %s -> %s"
				% [owned, _faces(forward, i), reversed_owned, _faces(backward, i)])


func test_mod_face_phases_run_keyword_then_add_then_multiply() -> void:
	# Arrange — assert the ORDER ITSELF rather than a specific relic pairing, so this keeps
	# holding as relics are authored. Every entry RelicHooks.mod_face_order() returns must be
	# sorted by [phase, rarity, sort_index]; a later entry may never outrank an earlier one.
	var owned: Array = ["__curse_dmg"]
	for def in RelicRegistry.offerable_defs_sorted():
		owned.append(String(def.id))
	var c := _combat(owned)

	# Act
	var order: Array = RelicHooks.mod_face_order(c)

	# Assert
	for i in range(1, order.size()):
		var a: Dictionary = order[i - 1]
		var b: Dictionary = order[i]
		var key_a := [int(a["ph"]), int(a["def"].rarity), int(a["def"].sort_index), int(a["sub"])]
		var key_b := [int(b["ph"]), int(b["def"].rarity), int(b["def"].sort_index), int(b["sub"])]
		_assert(key_a <= key_b,
			"mod_face_order is not sorted by [phase, rarity, sort_index, sub]: %s came before %s"
				% [key_a, key_b])
	_assert(order.size() >= 1,
		"no relic declares a mod_face entry, so the ordering rule is untested — at minimum "
		+ "'__curse_dmg' should be present")


func test_pseudo_relics_are_never_offered_as_loot() -> void:
	# Arrange — '__curse_dmg' must resolve through get_def() (it is a real owned relic once
	# the CURSE PACT is taken) but must never appear in a reward/shop offer.
	_assert(RelicRegistry.get_def("__curse_dmg") != null,
		"'__curse_dmg' must be loadable — the CURSE PACT reward carries it as an owned relic")

	# Act / Assert
	for def in RelicRegistry.offerable_defs_sorted():
		_assert(not String(def.id).begins_with("__"),
			"pseudo-relic '%s' is in the offerable pool and could be handed out as loot" % def.id)

	for i in 200:
		var picked := RewardGenerator.pick_relic(Rng.new(i * 7919 + 13), [], 0, 4)
		if picked != null:
			_assert(not String(picked.id).begins_with("__"),
				"RewardGenerator.pick_relic() offered pseudo-relic '%s' at seed index %d"
					% [picked.id, i])
