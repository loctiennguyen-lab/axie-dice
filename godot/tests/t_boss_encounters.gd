extends Node
## Gate for the Phase-1 encounter + boss-mechanic port.
##
## Before this pass, `CombatEngine._generate_encounter()` returned a scaled SLIME pack for
## every node type — including boss nodes — so `Unit.is_boss` was never true in real play and
## every boss code path below was unreachable dead code that nonetheless read as "implemented".
## `_boss_turn_traits()` was a stub that incremented a counter. These checks exist so that
## regressing any of it fails loudly instead of quietly turning bosses back into filler.
##
## Everything here drives the REAL engine (CombatEngine/DamagePipeline), never a
## re-implementation of the rule being tested. Source of truth: src/engine.js genEncounter()
## (:336-351), mkBoss() (:325-335), checkBossPhase() (:877-888), bossTurnTraits() (:889-902).
##
## Run: godot --headless --path godot res://tests/t_boss_encounters.tscn

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_boss_encounters: start ===")
	test_boss_node_spawns_a_real_boss()
	test_normal_encounter_draws_from_the_pool()
	test_normal_pool_is_gated_by_power_level()
	test_elite_encounter_leads_with_an_elite()
	test_mecha_has_permanent_thorns_from_turn_one()
	test_mecha_enters_overdrive_every_third_turn()
	test_agony_switches_to_phase_two_on_death()
	test_a_status_tick_that_triggers_a_boss_phase_change_completes()
	test_gooey_king_splits_at_two_thirds_and_one_third()
	test_gooey_king_split_respects_add_cap()
	test_frost_lord_freezes_one_axie_per_turn()
	test_mirror_copies_the_players_biggest_face()
	test_ascension_hp_is_not_double_counted()

	print("=== t_boss_encounters: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_boss_encounters: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_boss_encounters: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


# ---------------------------------------------------------------------------
# Arrange helpers
# ---------------------------------------------------------------------------

func _roster(keys: Array) -> Array:
	var out: Array = []
	for i in keys.size():
		out.append({
			"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [], "growth": {}, "bonus_hp": 0,
		})
	return out


func _combat(kind: String, p_pw: int, boss_key: String = "", asc: int = 0,
		combat_seed: int = 4242) -> CombatEngine:
	var c := CombatEngine.new()
	c.setup_new({
		"node_id": "t_boss_encounters", "kind": kind, "pw": p_pw, "ascension": asc,
		"roster_snapshot": _roster(["plant1", "beast1", "aqua1", "reptile1", "bug1"]),
		"relic_ids": [], "combat_seed": combat_seed, "bonus_reroll": 0,
		"boss_key": boss_key,
	})
	return c


func _bosses_in(c: CombatEngine) -> Array:
	var out: Array = []
	for e in c.enemies:
		if (e as Unit).is_boss:
			out.append(e)
	return out


func _enemy_keys(c: CombatEngine) -> Array:
	var out: Array = []
	for e in c.enemies:
		out.append(String((e as Unit).key))
	return out


# ---------------------------------------------------------------------------
# Encounter generation
# ---------------------------------------------------------------------------

func test_boss_node_spawns_a_real_boss() -> void:
	# Arrange / Act
	for boss_key in ContentDB.bosses.keys():
		var c := _combat("boss", 8, String(boss_key))
		var bosses := _bosses_in(c)

		# Assert
		_assert(c.enemies.size() == 1,
			"boss node should field exactly ONE unit (JS returns [mkBoss(...)]), got %d for '%s': %s"
				% [c.enemies.size(), boss_key, _enemy_keys(c)])
		_assert(bosses.size() == 1,
			"boss node for '%s' produced no is_boss unit — enemies were %s" % [boss_key, _enemy_keys(c)])
		if bosses.size() == 1:
			var b: Unit = bosses[0]
			var expected := ContentDB.boss_stats(String(boss_key), 8, ContentDB.ascension_mods(0))
			_assert(b.key == String(boss_key),
				"asked for boss '%s', got '%s'" % [boss_key, b.key])
			_assert(b.max_hp == int(expected["max_hp"]),
				"boss '%s' max_hp %d != ContentDB.boss_stats() %d"
					% [boss_key, b.max_hp, int(expected["max_hp"])])
			_assert(b.hp == b.max_hp, "boss '%s' should start at full HP" % boss_key)
			_assert(b.die.size() == 6, "boss '%s' should have a 6-face die, has %d" % [boss_key, b.die.size()])


func test_normal_encounter_draws_from_the_pool() -> void:
	# Arrange / Act — several seeds, because one encounter legitimately repeats a key.
	var seen := {}
	for seed_value in [1, 2, 3, 4, 5, 6, 7, 8]:
		for key in _enemy_keys(_combat("battle", 9, "", 0, seed_value)):
			seen[key] = true

	# Assert
	_assert(seen.size() >= 3,
		"battles drew only %d distinct monster key(s) across 8 seeds: %s — JS genEncounter() "
			% [seen.size(), seen.keys()]
		+ "picks from the cost-sorted top ~70%% of NORMAL_POOL")
	_assert(not seen.has("egg"), "the egg token must never appear as a wild encounter")


func test_normal_pool_is_gated_by_power_level() -> void:
	# Arrange — JS filters NORMAL_POOL by `p.min <= pw+1`, so a pw-0 encounter can only ever
	# contain the three starter monsters (min 1), never e.g. a Warden (min 11).
	var early := {}
	for seed_value in range(1, 25):
		for key in _enemy_keys(_combat("battle", 0, "", 0, seed_value)):
			early[key] = true

	# Assert
	for key in early.keys():
		var gate := 99
		for entry in ContentDB.normal_pool:
			if String((entry as Dictionary).get("k", "")) == String(key):
				gate = int((entry as Dictionary).get("min", 99))
		_assert(gate <= 1,
			"monster '%s' (pool min %d) appeared at pw 0 — JS gates on `min <= pw+1`" % [key, gate])


func test_elite_encounter_leads_with_an_elite() -> void:
	# Arrange / Act
	for seed_value in [11, 12, 13, 14]:
		var c := _combat("elite", 9, "", 0, seed_value)
		var keys := _enemy_keys(c)

		# Assert
		var has_elite := false
		for k in keys:
			if ContentDB.elite_pool.has(k):
				has_elite = true
		_assert(has_elite,
			"elite node (seed %d) contained no ELITE_POOL monster: %s — in JS an elite wave "
				% [seed_value, keys]
			+ "always pushes one elite key before filling the rest")


func test_ascension_hp_is_not_double_counted() -> void:
	# Arrange — the encounter budget must scale by the CURSE modifier only; the ascension
	# `hp` modifier belongs to mkMonster alone. Applying it in both places (the bug this
	# guards) compounded it into ~1.21x instead of 1.10x at A1, and ~2.11x at A10.
	var a0 := _combat("battle", 9, "", 0, 777)
	var a1 := _combat("battle", 9, "", 1, 777)

	# Act — same seed means the same monster keys, so total HP is directly comparable.
	_assert(_enemy_keys(a0) == _enemy_keys(a1),
		"same seed should draw the same monsters regardless of ascension: %s vs %s"
			% [_enemy_keys(a0), _enemy_keys(a1)])
	var hp0 := 0
	for e in a0.enemies:
		hp0 += (e as Unit).max_hp
	var hp1 := 0
	for e in a1.enemies:
		hp1 += (e as Unit).max_hp

	# Assert — A1 is hp x1.10. Allow a small band for per-monster integer rounding, but a
	# double-count (x1.21) sits well outside it.
	var ratio: float = float(hp1) / maxf(1.0, float(hp0))
	_assert(ratio > 1.04 and ratio < 1.16,
		"Ascension-1 enemy HP ratio was %.3f, expected ~1.10 — a ratio near 1.21 means the "
			% ratio
		+ "ascension hp modifier is being applied to the budget AND per-monster")


# ---------------------------------------------------------------------------
# Boss traits
# ---------------------------------------------------------------------------

func test_mecha_has_permanent_thorns_from_turn_one() -> void:
	# Arrange / Act
	var c := _combat("boss", 9, "mecha")
	var bosses := _bosses_in(c)
	if bosses.is_empty():
		_assert(false, "mecha did not spawn")
		return
	var b: Unit = bosses[0]

	# Assert — JS seeds e.st.thorns from permThorns in startCombat, BEFORE the first turn.
	var perm := int(b.custom_state.get("permanent_thorns", 0))
	_assert(perm >= 2, "mecha permanent_thorns should be max(2, round(0.09*budget)), got %d" % perm)
	_assert(int(b.status.get("thorns", 0)) == perm,
		"mecha should already have %d thorns on turn 1, has %d" % [perm, int(b.status.get("thorns", 0))])


func test_mecha_enters_overdrive_every_third_turn() -> void:
	# Arrange
	var c := _combat("boss", 9, "mecha")
	var bosses := _bosses_in(c)
	if bosses.is_empty():
		_assert(false, "mecha did not spawn")
		return
	var b: Unit = bosses[0]

	# Act / Assert — turn_count increments at the START of each turn after the first, and
	# OVERDRIVE is on exactly when turn_count % 3 == 0.
	for _i in 6:
		if c.won or c.lost:
			break
		c.end_turn()
		var tc := int(b.custom_state.get("turn_count", 0))
		if b.hp > 0:
			_assert(b.overdrive == (tc % 3 == 0),
				"mecha overdrive was %s at turn_count %d (expected %s)"
					% [b.overdrive, tc, tc % 3 == 0])


func test_agony_switches_to_phase_two_on_death() -> void:
	# Arrange
	var c := _combat("boss", 9, "agony")
	var bosses := _bosses_in(c)
	if bosses.is_empty():
		_assert(false, "agony did not spawn")
		return
	var b: Unit = bosses[0]
	var phase1_die: Array = b.die.duplicate(true)
	var expected_hp2 := int(b.custom_state.get("max_hp2", -1))
	_assert(expected_hp2 > 0, "agony should carry a phase-2 HP pool, custom_state had %s" % [b.custom_state.keys()])

	# Act — one lethal hit through the real pipeline.
	DamagePipeline.resolve({"combat": c, "src": c.party[0], "tgt": b, "value": b.hp + 999,
		"pierce": true, "attack": true, "face_type": "dmg"})

	# Assert
	_assert(int(b.custom_state.get("phase", 1)) == 2,
		"agony should be in phase 2 after its first death, phase=%s" % b.custom_state.get("phase", 1))
	_assert(b.hp == expected_hp2 and b.max_hp == expected_hp2,
		"agony phase 2 should restore to its phase-2 pool %d, got hp=%d max=%d"
			% [expected_hp2, b.hp, b.max_hp])
	_assert(b.die != phase1_die, "agony should swap to its phase-2 die, but the die is unchanged")


func test_gooey_king_splits_at_two_thirds_and_one_third() -> void:
	# Arrange
	var c := _combat("boss", 9, "gooey_king")
	var bosses := _bosses_in(c)
	if bosses.is_empty():
		_assert(false, "gooey_king did not spawn")
		return
	var b: Unit = bosses[0]
	_assert(c.enemies.size() == 1, "gooey_king should start alone, got %s" % [_enemy_keys(c)])

	# Act — chip it just past the 2/3 threshold.
	DamagePipeline.resolve({"combat": c, "src": c.party[0], "tgt": b,
		"value": int(b.max_hp * 0.4), "pierce": true, "attack": true, "face_type": "dmg"})

	# Assert
	_assert(c.enemies.size() == 2,
		"gooey_king should have split once below 2/3 HP (hp %d/%d), board is %s"
			% [b.hp, b.max_hp, _enemy_keys(c)])

	# Act — down past 1/3.
	DamagePipeline.resolve({"combat": c, "src": c.party[0], "tgt": b,
		"value": int(b.max_hp * 0.4), "pierce": true, "attack": true, "face_type": "dmg"})

	# Assert
	_assert(c.enemies.size() == 3,
		"gooey_king should have split a second time below 1/3 HP (hp %d/%d), board is %s"
			% [b.hp, b.max_hp, _enemy_keys(c)])


func test_gooey_king_split_respects_add_cap() -> void:
	# Arrange — a single huge hit skips both thresholds at once. JS recomputes how many adds
	# SHOULD exist rather than firing on the crossing, so both still spawn — but never more
	# than add_cap.
	var c := _combat("boss", 9, "gooey_king")
	var bosses := _bosses_in(c)
	if bosses.is_empty():
		_assert(false, "gooey_king did not spawn")
		return
	var b: Unit = bosses[0]
	var cap := int(b.custom_state.get("add_cap", 0))

	# Act
	DamagePipeline.resolve({"combat": c, "src": c.party[0], "tgt": b,
		"value": int(b.max_hp * 0.8), "pierce": true, "attack": true, "face_type": "dmg"})

	# Assert
	_assert(int(b.custom_state.get("split_done", 0)) == cap,
		"one hit past both thresholds should top up to add_cap (%d), split_done=%s"
			% [cap, b.custom_state.get("split_done", 0)])
	_assert(c.enemies.size() == 1 + cap,
		"board should be the boss plus %d adds, got %s" % [cap, _enemy_keys(c)])


func test_frost_lord_freezes_one_axie_per_turn() -> void:
	# Arrange
	var c := _combat("boss", 9, "frost_lord")
	if _bosses_in(c).is_empty():
		_assert(false, "frost_lord did not spawn")
		return
	var frozen_at_start := 0
	for u in c.party:
		if (u as Unit).frozen:
			frozen_at_start += 1

	# Act
	c.end_turn()

	# Assert — DEEP FREEZE constrains a die (no reroll) rather than destroying it, so the
	# Axie must still be alive and able to act; only `frozen` flips.
	var frozen_after := 0
	for u in c.party:
		if (u as Unit).frozen:
			frozen_after += 1
	_assert(frozen_after > frozen_at_start or c.lost or c.won,
		"frost_lord should freeze one Axie per turn: %d frozen before, %d after"
			% [frozen_at_start, frozen_after])


func test_mirror_copies_the_players_biggest_face() -> void:
	# Arrange
	var c := _combat("boss", 9, "mirror")
	var bosses := _bosses_in(c)
	if bosses.is_empty():
		_assert(false, "mirror did not spawn")
		return
	var b: Unit = bosses[0]
	var before: int = int((b.die[0] as Dictionary).get("value", 0))
	# Stand in for "the strongest face the player used last turn".
	c.last_big = {"v": before + 100, "f": {"part": "horn", "type": "dmg",
		"value": before + 100, "keywords": [], "rarity": 0}}

	# Act
	c.end_turn()

	# Assert — JS: die[0].v = max(die[0].v, ceil(lastBig.v * 1.1)).
	var after: int = int((b.die[0] as Dictionary).get("value", 0))
	if b.hp > 0:
		_assert(after >= int(ceil((before + 100) * 1.1)),
			"mirror should have copied the player's biggest face at x1.1: die[0] went %d -> %d"
				% [before, after])


## Regression for the crash found on 2026-09-19 while re-tuning the difficulty curve.
##
## `DamagePipeline.check_boss_phase()` resets a boss's `status` to {} when it flips to phase 2.
## `StatusEngine.tick_status()` was reading `u.status["poison"]` directly, on the line AFTER the
## damage that could cause exactly that reset — so poisoning agony to death threw
## "Invalid access to property or key 'poison'", and the rest of the tick never ran.
##
## It stayed hidden because the auto-player never survived far enough to poison a boss to death;
## it appeared the moment the curve was softened and runs started reaching row 18.
##
## THE ASSERTION HAS TO BE A UNIT THAT TICKS *AFTER* THE BOSS. The first version of this test
## used a party member and passed with the bug still in place — `tick_status()` iterates
## `party + enemies`, so every ally had already ticked before the boss threw. The victim of an
## aborted tick is whatever comes next in the ENEMY list, so that is what is checked here.
func test_a_status_tick_that_triggers_a_boss_phase_change_completes() -> void:
	# Arrange — agony poisoned past lethal, and a second enemy AFTER it carrying its own poison.
	var c := _combat("boss", 9, "agony")
	var bosses := _bosses_in(c)
	if bosses.is_empty():
		_assert(false, "agony did not spawn")
		return
	var b: Unit = bosses[0]
	_assert(c.enemies[0] == b, "this test assumes agony is first in the enemy list")
	b.hp = 3
	b.status["poison"] = 50

	var later: Unit = c._mk_monster("slime", 1.0, {"hp": 1.0, "dmg": 1.0})
	later.max_hp = 40
	later.hp = 40
	later.status["poison"] = 4
	c.enemies.append(later)            # strictly after the boss in tick order

	# Act
	StatusEngine.tick_status(c)

	# Assert
	_assert(int(b.custom_state.get("phase", 1)) == 2,
		"poison did not push agony into phase 2 (phase=%s, hp=%d)"
			% [b.custom_state.get("phase", 1), b.hp])
	_assert(later.hp < 40,
		"the enemy queued after the boss never took its poison damage — the status tick aborted "
		+ "when the boss changed phase (hp still %d/40)" % later.hp)
	_assert(int(later.status.get("poison", 0)) < 4,
		"the enemy queued after the boss never had its poison decay — the tick aborted "
		+ "(poison still %d)" % int(later.status.get("poison", 0)))
	_assert(int(b.status.get("poison", 0)) >= 0,
		"agony ended the tick with poison %d — the decay wrote to a key the phase change had "
			% int(b.status.get("poison", 0)) + "already removed")
