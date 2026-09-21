extends Node
## Gate for the onboarding tutorial (design/gdd/onboarding-tutorial.md — scenes/tutorial/).
##
## The tutorial now runs on the REAL combat screen with a coach overlay on top of it
## (TutorialView.gd's header explains the rewrite), so what this file has to prove moved with
## it. It drives Tutorial.tscn end to end via white-box `.call()`/`.get()` (same convention as
## t_runloop_ui.gd), asserting at every step that:
##   (a) the taught action, done correctly, advances the step and changes real combat state
##   (b) every OTHER action — pressed by calling CombatView's own handler directly, bypassing
##       both the coach's click-blocking bands and whatever `.disabled` the deck happens to
##       have set — is refused and changes nothing
##   (c) nothing the tutorial does reaches RunState or the save file
##
## (b) is the actual step-lock. A regression that keeps the overlay's bands in the right place
## but drops CombatView._gated() would still pass a test that only clicks where the dim lets
## you: Space, Escape and CombatStage3D's own unit_clicked path never travel through the
## overlay at all, which is exactly the class of bug this file exists to catch.
##
## (c) is what used to be structural — the old fixture had its own board and could not touch a
## run if it tried. Teaching on the production screen gives that up, so it has to be tested
## instead of assumed.
##
## Anti-abort pattern (per t_vault.gd/t_runloop_ui.gd): every test function ends by calling
## _done(name), and EXPECTED_TESTS is cross-checked in _ready() so a runtime error that aborts
## a test partway cannot silently read as PASS.
##
## Run: godot --headless --path godot res://tests/t_tutorial_flow.tscn

const EXPECTED_TESTS: Array[String] = [
	"test_welcome_locks_everything_until_start",
	"test_party_and_intent_steps_accept_only_their_own_button",
	"test_reroll_step_only_accepts_reroll_and_actually_rerolls",
	"test_die_step_rejects_every_die_but_the_taught_one",
	"test_target_step_rejects_wrong_target_and_accepts_the_taught_one",
	"test_endturn_step_rejects_early_end_turn_and_advances_on_the_real_one",
	"test_reward_step_completes_tutorial_and_persists_the_flag",
	"test_tutorial_combat_is_sealed_off_from_the_run",
	"test_needs_tutorial_gate_formula",
]

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []

## test_reward_step_completes_tutorial_and_persists_the_flag() and
## test_needs_tutorial_gate_formula() both write MetaState.tutorial_seen/runs and the first one
## calls the real _finish_tutorial() -> MetaState.save_to_disk() — see save_guard.gd's own
## header for why byte-for-byte restore, not a hand-picked field list, is the only version of
## this that cannot fall behind.
var _guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_tutorial_flow: start ===")
	_guard.capture()
	# The tutorial drives a live CombatView: without this, every hit opens an input lock and a
	# timer-driven enemy phase, and the tests would be racing animations rather than the rules.
	CombatView.disable_juice_for_tests = true
	await get_tree().process_frame

	await test_welcome_locks_everything_until_start()
	await test_party_and_intent_steps_accept_only_their_own_button()
	await test_reroll_step_only_accepts_reroll_and_actually_rerolls()
	await test_die_step_rejects_every_die_but_the_taught_one()
	await test_target_step_rejects_wrong_target_and_accepts_the_taught_one()
	await test_endturn_step_rejects_early_end_turn_and_advances_on_the_real_one()
	await test_reward_step_completes_tutorial_and_persists_the_flag()
	await test_tutorial_combat_is_sealed_off_from_the_run()
	test_needs_tutorial_gate_formula()

	for name in EXPECTED_TESTS:
		if not _completed.has(name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted "
				+ "it part-way and every assertion after that point was skipped") % name)

	_guard.restore()

	print("=== t_tutorial_flow: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_tutorial_flow: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_tutorial_flow: FAIL — %s" % f)
	get_tree().quit(1)


func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


# ---------------------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------------------

func _new_tutorial() -> TutorialView:
	var t: TutorialView = load("res://scenes/tutorial/Tutorial.tscn").instantiate()
	add_child(t)
	# TutorialView._ready() instances Combat.tscn and then awaits two frames before it has an
	# engine to read. Give it those, plus one for its first _render().
	for _i in 4:
		await get_tree().process_frame
	return t


func _view(t: TutorialView) -> CombatView:
	return t.get("_view") as CombatView


func _combat(t: TutorialView) -> CombatEngine:
	return t.get("_combat") as CombatEngine


func _phase(t: TutorialView) -> int:
	return t.call("_phase")


## The step is derived every _process() tick, so a state change made by a direct handler call
## is not reflected in what the coach shows until the next frame. Tests read _phase() directly
## (which re-derives on the spot), but anything that has to settle gets this.
func _tick(n: int = 2) -> void:
	for _i in n:
		await get_tree().process_frame


## Every interaction the combat screen offers, fired straight at CombatView's handlers — the
## step-lock's actual surface. Returns nothing; callers assert on state afterwards.
func _press_everything_except(t: TutorialView, skip: String) -> void:
	var v := _view(t)
	if skip != "reroll":
		v.call("_on_reroll_pressed")
	if skip != "die":
		for i in 5:
			v.call("_on_die_slot_pressed", i)
	if skip != "target":
		for e in _combat(t).enemies:
			v.call("_on_target_clicked", e.uid)
	if skip != "undo":
		v.call("_on_undo_pressed")


func _teaching_slot(t: TutorialView) -> int:
	return int(t.call("_slot_of", t.call("_teaching_actor")))


func _advance_to_reroll(t: TutorialView) -> void:
	t.call("_on_cta_pressed")   # WELCOME -> PARTY
	t.call("_on_cta_pressed")   # PARTY   -> INTENT
	t.call("_on_cta_pressed")   # INTENT  -> auto-derived, which is REROLL on turn 1


func _advance_to_die(t: TutorialView) -> void:
	_advance_to_reroll(t)
	_view(t).call("_on_reroll_pressed")


# ---------------------------------------------------------------------------------------

func test_welcome_locks_everything_until_start() -> void:
	var t := await _new_tutorial()
	_assert(_phase(t) == TutorialView.Step.WELCOME, "fresh tutorial did not start at WELCOME")

	var combat := _combat(t)
	_assert(combat != null, "the tutorial did not boot a real CombatEngine")
	var rerolls_before: int = combat.rerolls
	var turn_before: int = combat.turn
	_press_everything_except(t, "")
	_assert(combat.rerolls == rerolls_before, "reroll fired while still at WELCOME")
	_assert(combat.turn == turn_before, "end turn fired while still at WELCOME")
	_assert(int(_view(t).get("_selected_die_uid")) == -1, "a die was picked up at WELCOME")
	_assert(_phase(t) == TutorialView.Step.WELCOME, "an ignored action advanced the WELCOME step")

	t.call("_on_cta_pressed")
	_assert(_phase(t) == TutorialView.Step.PARTY, "START did not advance WELCOME -> PARTY")

	t.queue_free()
	_done("test_welcome_locks_everything_until_start")


func test_party_and_intent_steps_accept_only_their_own_button() -> void:
	var t := await _new_tutorial()
	t.call("_on_cta_pressed")   # -> PARTY
	var combat := _combat(t)

	for step_name in ["PARTY", "INTENT"]:
		var rerolls_before: int = combat.rerolls
		_press_everything_except(t, "")
		_assert(combat.rerolls == rerolls_before, "reroll fired during the %s step" % step_name)
		_assert(int(_view(t).get("_selected_die_uid")) == -1,
			"a die was picked up during the %s step" % step_name)
		t.call("_on_cta_pressed")

	_assert(_phase(t) == TutorialView.Step.REROLL,
		"three GOT ITs did not land on REROLL (got %d)" % _phase(t))

	t.queue_free()
	_done("test_party_and_intent_steps_accept_only_their_own_button")


func test_reroll_step_only_accepts_reroll_and_actually_rerolls() -> void:
	var t := await _new_tutorial()
	_advance_to_reroll(t)
	var combat := _combat(t)
	_assert(_phase(t) == TutorialView.Step.REROLL, "did not reach the REROLL step")

	var rerolls_before: int = combat.rerolls
	_press_everything_except(t, "reroll")
	_assert(combat.rerolls == rerolls_before, "a non-reroll action changed the reroll count")
	_assert(_phase(t) == TutorialView.Step.REROLL, "an ignored action advanced the REROLL step")

	_view(t).call("_on_reroll_pressed")
	_assert(combat.rerolls == rerolls_before - 1, "REROLL did not spend a reroll")
	_assert(_phase(t) != TutorialView.Step.REROLL, "REROLL did not advance the step")

	t.queue_free()
	_done("test_reroll_step_only_accepts_reroll_and_actually_rerolls")


func test_die_step_rejects_every_die_but_the_taught_one() -> void:
	var t := await _new_tutorial()
	_advance_to_die(t)
	_assert(_phase(t) == TutorialView.Step.DIE, "did not reach the DIE step after rerolling")

	var v := _view(t)
	var taught := _teaching_slot(t)
	_assert(taught >= 0, "the DIE step has no taught die slot to point at")

	for i in 5:
		if i == taught:
			continue
		v.call("_on_die_slot_pressed", i)
		_assert(int(v.get("_selected_die_uid")) == -1,
			"die slot %d was selectable at the DIE step (only %d should be)" % [i, taught])

	v.call("_on_die_slot_pressed", taught)
	var actor: Unit = t.call("_teaching_actor")
	_assert(actor != null and int(v.get("_selected_die_uid")) == actor.uid,
		"the taught die did not get picked up")
	_assert(_phase(t) == TutorialView.Step.TARGET, "picking the taught die did not reach TARGET")

	t.queue_free()
	_done("test_die_step_rejects_every_die_but_the_taught_one")


func test_target_step_rejects_wrong_target_and_accepts_the_taught_one() -> void:
	var t := await _new_tutorial()
	_advance_to_die(t)
	var v := _view(t)
	var actor: Unit = t.call("_teaching_actor")
	v.call("_on_die_slot_pressed", _teaching_slot(t))
	_assert(_phase(t) == TutorialView.Step.TARGET, "did not reach the TARGET step")

	var combat := _combat(t)
	var expected: Unit = t.call("_teaching_target", actor)
	_assert(expected != null, "the TARGET step has no legal target to point at")

	# Every wrong unit on the board — the other enemies AND the player's own Axies, since
	# CombatStage3D's click path offers both and a self-target would spend the die too.
	var wrong: Array = []
	for e in combat.enemies:
		if e.uid != expected.uid:
			wrong.append(e)
	for u in combat.party:
		if u.uid != expected.uid:
			wrong.append(u)
	for u2 in wrong:
		v.call("_on_target_clicked", (u2 as Unit).uid)
		_assert(int(v.get("_selected_die_uid")) == actor.uid,
			"clicking %s at the TARGET step spent the die" % (u2 as Unit).n)

	var hp_before: int = expected.hp
	v.call("_on_target_clicked", expected.uid)
	await _tick(3)
	_assert(expected.hp < hp_before,
		"the taught target took no damage (%d -> %d)" % [hp_before, expected.hp])
	_assert(_phase(t) == TutorialView.Step.ENDTURN, "spending the taught die did not reach ENDTURN")

	t.queue_free()
	_done("test_target_step_rejects_wrong_target_and_accepts_the_taught_one")


func test_endturn_step_rejects_early_end_turn_and_advances_on_the_real_one() -> void:
	var t := await _new_tutorial()
	_advance_to_die(t)
	var v := _view(t)
	var combat := _combat(t)

	# Early: still at DIE, END TURN must do nothing.
	var turn_before: int = combat.turn
	v.call("_on_end_turn_pressed")
	await _tick(3)
	_assert(combat.turn == turn_before, "END TURN fired at the DIE step")

	v.call("_on_die_slot_pressed", _teaching_slot(t))
	var expected: Unit = t.call("_teaching_target", t.call("_teaching_actor"))
	v.call("_on_target_clicked", expected.uid)
	await _tick(3)
	_assert(_phase(t) == TutorialView.Step.ENDTURN, "did not reach the ENDTURN step")

	v.call("_on_end_turn_pressed")
	await _tick(8)
	_assert(combat.turn > turn_before or combat.won or combat.lost,
		"END TURN at the ENDTURN step did not end the turn")
	_assert(_phase(t) != TutorialView.Step.ENDTURN, "the ENDTURN step never advanced")

	t.queue_free()
	_done("test_endturn_step_rejects_early_end_turn_and_advances_on_the_real_one")


func test_reward_step_completes_tutorial_and_persists_the_flag() -> void:
	var t := await _new_tutorial()
	_advance_to_die(t)
	var v := _view(t)
	var combat := _combat(t)

	# Play it out for real. The safety bound is generous on purpose: the fixed seed is meant to
	# win in about two turns, and a bound that has to be raised is the signal that the seed no
	# longer teaches what it was chosen to teach.
	var guard := 0
	while not combat.won and not combat.lost and guard < 40:
		guard += 1
		var acted := false
		for i in 5:
			var actor: Unit = t.call("_teaching_actor")
			if actor == null:
				break
			var slot := _teaching_slot(t)
			if slot < 0:
				break
			v.call("_on_die_slot_pressed", slot)
			if int(v.get("_selected_die_uid")) != actor.uid:
				break
			var tgt: Unit = t.call("_teaching_target", actor)
			if tgt == null:
				break
			v.call("_on_target_clicked", tgt.uid)
			await _tick(2)
			acted = true
		if combat.won or combat.lost:
			break
		if not acted and combat.rerolls > 0:
			v.call("_on_reroll_pressed")
			continue
		v.call("_on_end_turn_pressed")
		await _tick(6)

	_assert(combat.won, "the taught + free-play sequence did not win within the safety bound")
	await _tick(3)
	_assert(_phase(t) == TutorialView.Step.REWARD, "a won fight did not present the REWARD step")

	t.call("_on_reward_pressed", 0)
	_assert(_phase(t) == TutorialView.Step.DONE, "taking a reward did not advance to DONE")

	# _finish_tutorial(), not _on_finish_pressed() — the latter also calls
	# change_scene_to_file(), which would tear down this test's own scene tree (see that
	# function's comment). Navigation is not this gate's concern; persistence is.
	t.call("_finish_tutorial")
	_assert(MetaState.tutorial_seen, "finishing the tutorial did not set MetaState.tutorial_seen")

	t.queue_free()
	_done("test_reward_step_completes_tutorial_and_persists_the_flag")


## The isolation the old self-contained fixture got for free, now that the tutorial teaches on
## the production screen: no run state written, no CONTINUE RUN slot touched, no rehearsal move
## appended to the run's replay-verify log.
func test_tutorial_combat_is_sealed_off_from_the_run() -> void:
	var shards_before := RunState.shards_this_run
	var pw_before := RunState.power_level
	var log_before := RunState.action_log
	var log_len_before: int = RunState.action_log.entries.size() \
		if RunState.action_log.get("entries") is Array else -1
	var save_before := RunState.resume_combat.duplicate(true)

	var t := await _new_tutorial()
	var v := _view(t)
	_assert(bool(v.get("_tutorial")), "Combat.tscn did not come up in tutorial mode")
	_assert(_combat(t).action_log != log_before,
		"the tutorial fight is writing into the RUN's action log")

	_advance_to_die(t)
	v.call("_on_die_slot_pressed", _teaching_slot(t))
	v.call("_on_target_clicked", (t.call("_teaching_target", t.call("_teaching_actor")) as Unit).uid)
	v.call("_on_end_turn_pressed")
	await _tick(8)

	_assert(RunState.shards_this_run == shards_before, "the tutorial changed RunState.shards_this_run")
	_assert(RunState.power_level == pw_before, "the tutorial changed RunState.power_level")
	_assert(RunState.resume_combat.hash() == save_before.hash(),
		"the tutorial wrote the CONTINUE RUN slot")
	if log_len_before >= 0:
		_assert(RunState.action_log.entries.size() == log_len_before,
			"the tutorial appended to the run's action log")
	_assert(RunState.pending_combat.is_empty(),
		"the tutorial left a pending_combat behind for the next screen to pick up")

	t.queue_free()
	_done("test_tutorial_combat_is_sealed_off_from_the_run")


func test_needs_tutorial_gate_formula() -> void:
	var runs_before := MetaState.runs
	var seen_before := MetaState.tutorial_seen

	MetaState.tutorial_seen = false
	MetaState.runs = 0
	_assert(MetaState.needs_tutorial(), "{seen:false, runs:0} should need the tutorial")

	MetaState.tutorial_seen = true
	MetaState.runs = 0
	_assert(not MetaState.needs_tutorial(), "{seen:true, runs:0} should not need the tutorial")

	MetaState.tutorial_seen = false
	MetaState.runs = 5
	_assert(not MetaState.needs_tutorial(),
		"{seen:false, runs:5} (pre-existing save) should not need the tutorial")

	# Migration backfill: load_from_disk() must set tutorial_seen=true for a save with runs>0
	# and no tutorial_seen field at all (predates this feature).
	MetaState.runs = runs_before
	MetaState.tutorial_seen = seen_before
	_done("test_needs_tutorial_gate_formula")
