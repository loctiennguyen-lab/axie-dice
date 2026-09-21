extends Node
## Guards the 2026-09-21 split of `CombatEngine.end_turn()` into begin / step / finish.
##
## The split exists so CombatView can put a gap between enemies and let each one's attack
## animation play out. The split is only allowed to exist if it cannot change a run — this file
## is the proof, and it asks the question `t_rules_version.gd` tells a human to ask, in a form a
## machine can answer.
##
## WHAT THIS FILE DOES NOT COVER, stated because the boundary was measured rather than assumed.
## The reference below reproduces the pre-split BEGIN block and ENEMY LOOP, which is exactly
## what changed shape, and stops there. The tail — status tick, end check, next-turn setup — is
## `finish_end_turn()` verbatim and both paths call the same function, so a break in it is
## invisible here (checked: deleting `StatusEngine.tick_status()` leaves this file green). That
## tail is covered by `t_replay`, `t_vertical_slice`, `t_full_run_loop` and
## `t_combat_roundtrip`, all of which drive `end_turn()` and all of which were green across
## this refactor.
##
## Run: godot --headless --path godot res://tests/t_enemy_phase_pacing.tscn

## SAVE GUARD. This test drives real combat, and combat writes: CombatView._ready() ends with
## `_save_run_progress()`, and a finished fight banks into MetaState. Both land in the file a
## real player's run history lives in. Every progression-touching gate in this suite borrows
## and restores it — see save_guard.gd's own header for the measurement that made that a rule.
var _guard := SaveGuard.new()


var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_enemy_phase_pacing: start ===")
	_guard.capture()
	CombatView.disable_juice_for_tests = true

	test_the_split_reproduces_the_pre_split_enemy_phase()
	test_an_enemy_summoned_mid_phase_still_acts_this_turn()
	test_begin_refuses_a_second_call_and_finish_refuses_a_stray_one()
	test_the_view_paces_by_the_animation_it_is_waiting_for()

	if _fails.is_empty():
		print("=== t_enemy_phase_pacing: %d checks, 0 failure(s) ===" % _checks)
		print("t_enemy_phase_pacing: PASS — %d checks OK" % _checks)
		_guard.restore()
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_enemy_phase_pacing: FAIL — %s" % f)
		_guard.restore()
		get_tree().quit(1)


## THE headline guarantee: the split did not change the run.
##
## THE REFERENCE PATH IS THE PRE-SPLIT CODE, written out in `_legacy_begin_and_enemy_phase()`
## below. That matters, and it is not the obvious way to write this test. The first version
## compared `end_turn()` against begin/step/finish — but `end_turn()` IS begin/step/finish
## since the split, so it compared identical code to itself. It was checked: deleting
## `StatusEngine.tick_status()` from the engine outright did not make it fail. A test that
## survives having the thing it guards removed is not a test.
##
## `to_data()` is the right comparison because it is the same serialisation the save file and
## the run verifier use: if these two agree, a run played through the paced path verifies
## against a log recorded through the old one.
func test_the_split_reproduces_the_pre_split_enemy_phase() -> void:
	var legacy := _fresh_engine()
	var split := _fresh_engine()
	_check(legacy.to_data() == split.to_data(),
		"two engines built from the same seed did not start identical — this test cannot say "
		+ "anything until they do")

	for turn_i in 6:
		if legacy.won or legacy.lost or split.won or split.lost:
			break
		# Same player actions on both, chosen without RNG so the comparison is about the split.
		_spend_every_die(legacy)
		_spend_every_die(split)
		_check(legacy.to_data() == split.to_data(),
			"the two engines diverged while SPENDING dice on turn %d — the fault is in the "
			% turn_i + "test's own action picker, not in the end_turn() split")

		_legacy_begin_and_enemy_phase(legacy)
		legacy.finish_end_turn()

		# Exactly what CombatView._run_enemy_phase() does, minus the waiting.
		if split.begin_end_turn():
			var i := 0
			while i < split.enemies.size():
				if not split.step_end_turn_action(i):
					break
				i += 1
			split.finish_end_turn()

		_check(legacy.to_data() == split.to_data(),
			"the split enemy phase produced a DIFFERENT engine from the pre-split one on turn "
			+ "%d — the refactor changed the run, which is the one thing it must never do"
			% turn_i)
		if _fails.size() > 0:
			return
	_done("test_the_split_reproduces_the_pre_split_enemy_phase")


## `CombatEngine.end_turn()` exactly as it read before the 2026-09-21 split, up to and
## including the enemy loop. The tail (status tick, end check, next turn) is NOT duplicated —
## the split did not touch it, `finish_end_turn()` is that tail verbatim, and copying a long
## block of turn setup into a test is how a golden reference rots into a second, wrong copy of
## the rules. What is copied here is precisely what changed shape, and nothing else.
func _legacy_begin_and_enemy_phase(c: CombatEngine) -> void:
	if c.won or c.lost:
		return
	if c.phase == CombatEngine.CombatPhase.END_TURN:
		return
	c._log("end_turn", [])
	c._set_turn_phase(CombatEngine.CombatPhase.END_TURN)
	c.undo_stack = []
	c.first_used = false

	if c.mana > 0 and (RelicHooks.has(c, "manaOverflow")
			or c._any_die_has_keyword(c.party, "overflow")):
		var v := c.mana
		var src: Unit = (c.alive_party()[0] if c.alive_party().size() > 0 else null)
		for t in c.alive_enemies().duplicate():
			DamagePipeline.resolve({"combat": c, "src": src, "tgt": t, "value": v,
				"attack": false})
		EventBus.float_text.emit((src.uid if src != null else 0), "OVERFLOW %d" % v, "man", 1)
		c.mana = 0

	for e in c.enemies:
		if e.hp <= 0 or e.intent.is_empty():
			continue
		EventBus.enemy_intent_executed.emit(e.uid)
		if int(e.status.get("stun", 0)) > 0:
			e.status["stun"] = 0
			EventBus.float_text.emit(e.uid, "STUNNED", "deb", 0)
			continue
		c._exec_face(e, int(e.intent.get("target_uid", -1)))
		if not c._any_real_party_alive():
			break


## The one real fidelity trap in the split, and the reason the stepper takes an INDEX rather
## than a list of uids taken up front.
##
## The loop this replaced was `for e in enemies`, and GDScript re-reads an Array's size on every
## iteration — so an enemy SUMMONED by an earlier enemy acts in the same phase. A snapshot of
## uids taken before the first enemy moved would silently skip it: same inputs, different run.
## This appends an enemy between two steps and checks it still gets its turn.
func test_an_enemy_summoned_mid_phase_still_acts_this_turn() -> void:
	var c := _fresh_engine()
	_spend_every_die(c)
	if not c.begin_end_turn():
		_check(false, "begin_end_turn() refused a fresh EXECUTE-phase engine")
		return

	var acted: Array[int] = []
	var probe := func(uid: int): acted.append(uid)
	EventBus.enemy_intent_executed.connect(probe)

	var newcomer_uid := -1
	var i := 0
	while i < c.enemies.size():
		if not c.step_end_turn_action(i):
			break
		i += 1
		if newcomer_uid == -1 and i < c.enemies.size():
			# A clone of a living enemy, with its intent intact, appended exactly where a real
			# summon would land: after the enemy that just acted.
			var src: Unit = c.enemies[0]
			var clone := Unit.from_data(src.to_data())
			clone.uid = 987654
			clone.hp = src.max_hp
			clone.intent = src.intent.duplicate(true)
			newcomer_uid = clone.uid
			c.enemies.append(clone)
	c.finish_end_turn()
	EventBus.enemy_intent_executed.disconnect(probe)

	_check(newcomer_uid != -1,
		"this encounter had too few enemies to append one mid-phase — pick another seed")
	_check(acted.has(newcomer_uid),
		"an enemy appended DURING the phase never acted (uids that acted: %s). The stepper is "
		% str(acted) + "no longer reaching summons the way `for e in enemies` did.")
	_done("test_an_enemy_summoned_mid_phase_still_acts_this_turn")


## Each phase refuses to run out of order, so a stray call cannot tick status twice or start a
## second enemy phase on top of a running one. This is what makes the view's re-entrancy guard
## a backstop rather than the only thing holding the door.
func test_begin_refuses_a_second_call_and_finish_refuses_a_stray_one() -> void:
	var c := _fresh_engine()
	_check(c.can_end_turn(), "a fresh EXECUTE-phase engine says it cannot end its turn")
	_check(c.begin_end_turn(), "begin_end_turn() refused a fresh EXECUTE-phase engine")
	_check(not c.can_end_turn(), "can_end_turn() still says yes while a phase is running")
	_check(not c.begin_end_turn(), "begin_end_turn() started a SECOND enemy phase on top of a "
		+ "running one")

	var turn_before := c.turn
	c.finish_end_turn()
	_check(c.turn == turn_before + 1 or c.won or c.lost,
		"finish_end_turn() did not advance the turn (%d -> %d)" % [turn_before, c.turn])
	var snapshot := c.to_data()
	c.finish_end_turn()   # stray second call — the phase is no longer END_TURN
	_check(c.to_data() == snapshot,
		"a stray finish_end_turn() moved the engine — status would tick twice")
	_done("test_begin_refuses_a_second_call_and_finish_refuses_a_stray_one")


## The gap between enemies and the length of the animation it is waiting for live in two
## different files. Pinned, because "one at a time" stops being true the moment they disagree.
func test_the_view_paces_by_the_animation_it_is_waiting_for() -> void:
	CombatView.disable_juice_for_tests = false
	_check(is_equal_approx(CombatView.enemy_step_gap(),
			CombatStage3D.action_motion_duration()),
		"the enemy-phase gap is %.3fs but the attack animation runs %.3fs — enemies will "
		% [CombatView.enemy_step_gap(), CombatStage3D.action_motion_duration()]
		+ "overlap or the phase will stall")
	CombatView.disable_juice_for_tests = true
	_check(is_equal_approx(CombatView.enemy_step_gap(), 0.0),
		"the paced phase does not collapse in test mode — every combat test would now have to "
		+ "wait on real timers")
	_done("test_the_view_paces_by_the_animation_it_is_waiting_for")


# ---------------------------------------------------------------------------

func _fresh_engine() -> CombatEngine:
	var c := CombatEngine.new()
	c.setup_new({
		"node_id": "pacing_node", "kind": "battle", "pw": 6, "ascension": 0,
		"roster_snapshot": _synthetic_roster(), "relic_ids": [], "combat_seed": 246813,
	})
	return c


## Deterministic and RNG-free: every living party member uses its rolled face on the first
## living enemy. The point is to reach an interesting board state the same way twice, not to
## play well.
func _spend_every_die(c: CombatEngine) -> void:
	for u in c.party:
		if u.hp <= 0 or not u.has_rolled() or u.roll_used():
			continue
		var targets := c.alive_enemies()
		if targets.is_empty():
			return
		c.use_die(u.uid, (targets[0] as Unit).uid)


func _synthetic_roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({
			"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [], "growth": {}, "bonus_hp": 0,
		})
	return out


func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)


func _done(name: String) -> void:
	if _fails.is_empty():
		print("  ok — %s" % name)
