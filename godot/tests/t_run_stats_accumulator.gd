extends Node
## Gate for the RunStats accumulator (docs/design-handoff-v2 §09) — specifically the two rules
## the spec says the whole accumulator exists to get right:
##   1. damage counts what actually lands: post-shield, clamped to the target's remaining HP,
##      so an overkill of 40 into a 6 HP enemy scores 6, not 40.
##   2. poison and thorns raise damage_dealt but never biggest_hit — biggest_hit is one die
##      resolution against one target, the number a player can recognise on the sprite.
##
## Exercises the REAL DamagePipeline.resolve() directly against bare Unit/CombatEngine
## objects (same pattern as t_content_expansion.gd's boss-phase test), rather than
## re-implementing the clamp/exclusion logic here — a test that reimplements the rule can
## pass while the rule it is supposed to gate has drifted.
##
## Implemented as a scene (t_run_stats_accumulator.tscn) for the same reason every other
## autoload-dependent gate in this suite is: CombatEngine/DamagePipeline reach EventBus and
## RelicRegistry as autoload globals, which a bare `--script` SceneTree override cannot
## resolve.

var _failures: Array[String] = []
var _checks := 0

## test_the_result_screen_reads_build_before_currency and friends already establish the
## pattern: anything that drives RunState.start_new_run()/apply_combat_result() can reach
## MetaState's real save file, so every gate that does either borrows it for the duration.
var _guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_run_stats_accumulator: start ===")
	_guard.capture()

	_check_overkill_is_clamped_to_remaining_hp()
	_check_poison_and_thorns_count_toward_damage_dealt_but_not_biggest_hit()
	_check_axies_lost_dedupes_a_revived_roster_unit()
	_check_accumulator_is_wired_through_a_real_combat()

	_guard.restore()
	print("=== t_run_stats_accumulator: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_run_stats_accumulator: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _failures:
			print("t_run_stats_accumulator: FAIL — %s" % f)
		get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _new_unit(uid: int, side: String, hp: int, status: Dictionary = {}) -> Unit:
	var u := Unit.new()
	u.uid = uid
	u.side = side
	u.hp = hp
	u.max_hp = hp
	u.status = status.duplicate(true)
	return u


# ===========================================================================
# Rule 1: the overkill clamp
# ===========================================================================
func _check_overkill_is_clamped_to_remaining_hp() -> void:
	var combat := CombatEngine.new()
	var attacker := _new_unit(1, "p", 20)
	var enemy := _new_unit(combat._alloc_token_uid(), "e", 6)

	var dealt: int = DamagePipeline.resolve({
		"combat": combat, "src": attacker, "tgt": enemy, "value": 40, "attack": true,
	})

	_assert(enemy.hp == 0, "a 6 HP enemy hit for 40 should be at 0 HP, got %d" % enemy.hp)
	_assert(dealt == 40,
		"resolve()'s return value feeds relic hooks (e.g. an on_hit 'dealt >= 4' check) and "
		+ "must stay UNCLAMPED — got %d, expected 40" % dealt)
	_assert(int(combat.stat.get("dmg", 0)) == 40,
		"the pre-existing 'dmg' key is documented as unclamped and must stay that way, or this "
		+ "test's premise (that a second, clamped key was needed) is stale — got %d"
		% int(combat.stat.get("dmg", 0)))
	_assert(int(combat.stat.get("dmg_dealt_clamped", 0)) == 6,
		("the RunStats accumulator's damage_dealt must clamp to the HP that actually existed "
		+ "before the hit — an overkill of 40 into a 6 HP enemy should score 6, got %d")
		% int(combat.stat.get("dmg_dealt_clamped", 0)))


# ===========================================================================
# Rule 2: poison/thorns raise damage_dealt but never biggest_hit
# ===========================================================================
func _check_poison_and_thorns_count_toward_damage_dealt_but_not_biggest_hit() -> void:
	# --- Poison tick on an enemy, called exactly as StatusEngine.tick_status() calls it:
	# src == null, pierce == true. ---
	var combat := CombatEngine.new()
	var poisoned_enemy := _new_unit(combat._alloc_token_uid(), "e", 50)
	DamagePipeline.resolve({
		"combat": combat, "src": null, "tgt": poisoned_enemy, "value": 5, "pierce": true,
	})
	_assert(int(combat.stat.get("dmg_dealt_clamped", 0)) == 5,
		("a poison tick landing on an enemy must count toward damage_dealt (it is the player's "
		+ "own status effect) — got %d, expected 5")
		% int(combat.stat.get("dmg_dealt_clamped", 0)))
	_assert(int(combat.stat.get("max_hit", 0)) == 0,
		"a poison tick must never raise biggest_hit — got %d, expected 0"
		% int(combat.stat.get("max_hit", 0)))
	_assert(int(combat.stat.get("dmg", 0)) == 0,
		("documents the bug this accumulator works around: the legacy 'dmg' key's own gate "
		+ "(`src != null`) drops every status tick, poison included — got %d, expected 0")
		% int(combat.stat.get("dmg", 0)))

	# --- Thorns: an enemy attacks a party unit that has a Thorns stack. The reflected damage
	# lands on the ATTACKING ENEMY and is the party's own status effect, so it should count
	# toward damage_dealt even though the enemy, not the player, is the one who "attacked". ---
	var combat2 := CombatEngine.new()
	var thorned_ally := _new_unit(2, "p", 30, {"thorns": 4})
	var attacking_enemy := _new_unit(combat2._alloc_token_uid(), "e", 10)
	DamagePipeline.resolve({
		"combat": combat2, "src": attacking_enemy, "tgt": thorned_ally, "value": 3, "attack": true,
	})
	_assert(attacking_enemy.hp == 6,
		"an enemy attacking a 4-Thorns ally should take 4 reflected damage — got hp %d, expected 6"
		% attacking_enemy.hp)
	_assert(int(combat2.stat.get("dmg_dealt_clamped", 0)) == 4,
		("Thorns reflecting off a party unit's own status must count toward damage_dealt — the "
		+ "main hit here is enemy-on-party (damage TAKEN, correctly excluded) and only the 4 "
		+ "thorns damage should land in damage_dealt, got %d")
		% int(combat2.stat.get("dmg_dealt_clamped", 0)))
	_assert(int(combat2.stat.get("max_hit", 0)) == 0,
		"Thorns damage must never raise biggest_hit — got %d, expected 0"
		% int(combat2.stat.get("max_hit", 0)))


# ===========================================================================
# axies_lost: dedup per persistent roster uid, and tokens/enemies are never counted
# ===========================================================================
func _check_axies_lost_dedupes_a_revived_roster_unit() -> void:
	RunStatsAccumulator.reset()

	# A roster unit (uid < CombatEngine.TOKEN_UID_BASE) dying twice in the same run (a relic
	# revive, then a second death) must count once, per the spec's own wording.
	EventBus.unit_died.emit(3)
	EventBus.unit_died.emit(3)
	_assert(RunStatsAccumulator.axies_lost == 1,
		"a roster unit that died twice this run should count as 1 Axie lost, got %d"
		% RunStatsAccumulator.axies_lost)

	# An in-combat token/enemy (uid >= TOKEN_UID_BASE) is not a roster Axie and must not count.
	EventBus.unit_died.emit(CombatEngine.TOKEN_UID_BASE + 5)
	_assert(RunStatsAccumulator.axies_lost == 1,
		"a token/enemy death must not raise axies_lost — got %d, expected still 1"
		% RunStatsAccumulator.axies_lost)

	# A second, different roster unit dying does raise the count.
	EventBus.unit_died.emit(4)
	_assert(RunStatsAccumulator.axies_lost == 2,
		"a second distinct roster unit dying should raise axies_lost to 2, got %d"
		% RunStatsAccumulator.axies_lost)

	RunStatsAccumulator.reset()


# ===========================================================================
# End-to-end: the REAL path (CombatEngine -> RunState.apply_combat_result() ->
# RunState.run_stats -> RunStatsAccumulator.snapshot()), not a hand-constructed shortcut.
#
# WHY THIS EXISTS. Every check above proves DamagePipeline.resolve() computes the right
# NUMBER. None of them prove the number actually reaches RunState.run_stats through the
# production code path a real fight uses — RunState.apply_combat_result(). A screenshot
# showing five zeroes on the stat ribbon (2026-09-20 QA capture, which sets RunState fields
# directly and never runs a fight) is consistent with "the harness never drove combat" AND
# with "the wiring is broken", and looks identical either way. This test rules out the
# second explanation by actually fighting a battle to its finish, the same
# always-legal-action bot t_vertical_slice.gd uses, then reading the numbers back through
# RunStatsAccumulator.snapshot() the way ResultView.gd does.
# ===========================================================================
func _check_accumulator_is_wired_through_a_real_combat() -> void:
	RunState.start_new_run(909090, ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"short", 0, false)

	var combat := CombatEngine.new()
	# Same pw/seed as t_vertical_slice.gd's own proven-to-finish setup (pw=9 stalemated past
	# 200 turns against this simple bot in practice — measured, not guessed). The axies_lost
	# check below does not need a death to prove anything: it compares two INDEPENDENT counts
	# of the same event and passes on 0-equals-0 just as meaningfully as on a real death.
	combat.setup_new({
		"node_id": "t_run_stats_accumulator_node", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": RunState.roster.duplicate(true), "relic_ids": [],
		"combat_seed": 424242,
	})

	# Independent observation, kept separate from RunStatsAccumulator's own listener, so
	# comparing the two actually proves something: it is the SAME roster-uid rule
	# (uid < CombatEngine.TOKEN_UID_BASE) applied twice, once here and once inside the
	# accumulator, not one copying the other's arithmetic.
	var observed_roster_deaths: Dictionary = {}
	var on_death := func(uid: int) -> void:
		if uid < CombatEngine.TOKEN_UID_BASE:
			observed_roster_deaths[uid] = true
	EventBus.unit_died.connect(on_death)

	# GDScript lambdas capture outer LOCAL variables BY VALUE at creation time — a bare
	# `finished = true` inside a lambda rebinds a copy, never the loop's own `finished`. A
	# single-element Array is a reference type, so mutating its slot IS visible outside the
	# closure. (Caught by this exact test looping all 200 turns while combat.stat showed the
	# fight had already ended at turn 4 — a test bug, not an accumulator bug; worth the
	# comment so it is not rediscovered the same way twice.)
	var finished_box := [false]
	var on_finished := func(_w: bool) -> void:
		finished_box[0] = true
	EventBus.combat_finished.connect(on_finished)

	var turns := 0
	while not finished_box[0] and turns < 200:
		_play_one_bot_turn(combat)
		turns += 1
	EventBus.unit_died.disconnect(on_death)
	EventBus.combat_finished.disconnect(on_finished)
	var finished: bool = finished_box[0]

	_assert(finished, "the real combat used for this check never reached combat_finished "
		+ "within 200 turns — cannot prove anything about the accumulator without a result")
	if not finished:
		RunState.reset()
		return

	# The actual production call a real fight makes when it ends (RunMapController /
	# CombatView both call this — see RunState.apply_combat_result()'s own doc comment).
	RunState.apply_combat_result(combat.get_result())

	var snap := RunStatsAccumulator.snapshot(RunState.mode)
	_assert(int(snap["turns_taken"]) > 0,
		"turns_taken should be > 0 after a %d-turn real fight, got %d"
		% [turns, int(snap["turns_taken"])])
	_assert(int(snap["nodes_total"]) == 18,
		"nodes_total should read 18 for a 'short' mode run, got %d" % int(snap["nodes_total"]))
	# A fight that runs multiple turns and ends almost always has SOME damage and a kill on
	# one side or the other; this combat has no relics and a plain always-legal-action bot on
	# both sides, so at least one enemy face lands.
	_assert(int(snap["damage_dealt"]) > 0,
		"damage_dealt should be > 0 after a real, multi-turn fight — got 0, which is exactly "
		+ "what a disconnected accumulator would also read")
	_assert(int(snap["damage_dealt"]) == int(RunState.run_stats.get("dmg_dealt_clamped", 0)),
		"RunStatsAccumulator.snapshot()'s damage_dealt must read straight from "
		+ "RunState.run_stats — got %d vs. run_stats' %d, so apply_combat_result() is not "
		% [int(snap["damage_dealt"]), int(RunState.run_stats.get("dmg_dealt_clamped", 0))]
		+ "folding into the same place the screen reads")
	_assert(int(snap["biggest_hit"]) > 0,
		"biggest_hit should be > 0 after a real fight with real damage faces — got 0")
	_assert(int(snap["kills"]) > 0,
		"a fight that reaches combat_finished ended with a side wiped out — kills should be "
		+ "> 0, got 0")
	_assert(int(snap["axies_lost"]) == observed_roster_deaths.size(),
		("axies_lost should equal the number of distinct roster uids this test independently "
		+ "saw die (%d) — got %d. Equal-but-both-zero still passes this if nobody died; it is "
		+ "the two DIFFERING that would prove the wiring is broken")
		% [observed_roster_deaths.size(), int(snap["axies_lost"])])

	RunState.reset()


## Copy of t_vertical_slice.gd's bot: use any legal die on any legal target until nothing
## more can be used, damage/poison/debuff faces at the first alive enemy, support faces on
## self. Duplicated rather than shared because it is ~15 lines and the two files' headless
## scene-test setup (no shared test-lib autoload in this project) makes a shared helper file
## more machinery than the duplication it would remove.
func _play_one_bot_turn(combat: CombatEngine) -> void:
	var guard := 0
	while guard < 64:
		guard += 1
		var acted := false
		for u in combat.party.duplicate():
			if u.hp <= 0 or not u.has_rolled() or u.roll_used():
				continue
			var fi: int = u.roll_face_index()
			var f: Dictionary = u.die[fi]
			var face_type := String(f.get("type", ""))
			var tgt_uid := -1
			if face_type in ["dmg", "poison", "debuff"]:
				var es: Array = combat.alive_enemies()
				if es.size() > 0:
					tgt_uid = es[0].uid
			elif face_type in ["shield", "heal", "buff"]:
				tgt_uid = u.uid
			else:
				tgt_uid = u.uid
			if combat.use_die(u.uid, tgt_uid):
				acted = true
		if not acted:
			break
	combat.end_turn()
