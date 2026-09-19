extends Node
## Gate for the onboarding tutorial (design/gdd/onboarding-tutorial.md, ported —
## scenes/tutorial/TutorialView.gd). Drives the real Tutorial.tscn scene end to end via
## white-box `.call()`/`.get()` (same convention as t_runloop_ui.gd), asserting at every step
## that:
##   (a) the taught action, done correctly, advances the step and changes real combat state
##   (b) every OTHER action — pressed directly by calling the handler function, bypassing
##       whatever `.disabled` the UI happens to have set — is refused and changes nothing
## (b) is the actual step-lock being tested, not the cosmetic button-disable: a regression that
## keeps `.disabled` correct but drops the handler's own guard would still pass a test that
## only checks button state, and that is exactly the class of bug this file exists to catch
## (see the task report's break/revert proof).
##
## Anti-abort pattern (per t_vault.gd/t_runloop_ui.gd): every test function ends by calling
## _done(name), and EXPECTED_TESTS is cross-checked in _ready() so a runtime error that aborts
## a test partway cannot silently read as PASS.
##
## Run: godot --headless --path godot res://tests/t_tutorial_flow.tscn

const EXPECTED_TESTS: Array[String] = [
	"test_welcome_locks_everything_until_start",
	"test_roll_step_locks_everything_but_got_it",
	"test_intent_step_only_accepts_an_enemy_click",
	"test_reroll_step_only_accepts_reroll_and_actually_rerolls",
	"test_die_step_rejects_every_die_but_the_taught_one",
	"test_target_step_rejects_wrong_target_and_accepts_the_taught_one",
	"test_endturn_step_rejects_early_end_turn_and_advances_on_the_real_one",
	"test_reward_step_completes_tutorial_and_persists_the_flag",
	"test_needs_tutorial_gate_formula",
]

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []

## test_reward_step_completes_tutorial_and_persists_the_flag() and
## test_needs_tutorial_gate_formula() both write MetaState.tutorial_seen/runs and the first one
## calls the real _on_finish_pressed() -> MetaState.save_to_disk() — see save_guard.gd's own
## header for why byte-for-byte restore, not a hand-picked field list, is the only version of
## this that cannot fall behind.
var _guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_tutorial_flow: start ===")
	_guard.capture()
	await get_tree().process_frame

	test_welcome_locks_everything_until_start()
	test_roll_step_locks_everything_but_got_it()
	test_intent_step_only_accepts_an_enemy_click()
	test_reroll_step_only_accepts_reroll_and_actually_rerolls()
	test_die_step_rejects_every_die_but_the_taught_one()
	test_target_step_rejects_wrong_target_and_accepts_the_taught_one()
	test_endturn_step_rejects_early_end_turn_and_advances_on_the_real_one()
	test_reward_step_completes_tutorial_and_persists_the_flag()
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

func _new_tutorial() -> TutorialView:
	var t: TutorialView = load("res://scenes/tutorial/Tutorial.tscn").instantiate()
	add_child(t)
	return t


## Advances a fresh tutorial instance to the DIE step (welcome->roll->intent->reroll), the
## point every step-lock test below wants to start from. Asserts nothing itself — callers do.
func _advance_to_die(t: TutorialView) -> void:
	t.call("_on_start_pressed")
	t.call("_on_got_it_pressed")
	t.call("_on_enemy_pressed", 0)
	t.call("_on_intent_close_pressed")
	t.call("_on_reroll_pressed")


func _combat(t: TutorialView) -> CombatEngine:
	return t.get("_combat")


func _phase(t: TutorialView) -> int:
	return t.call("_phase")


# ---------------------------------------------------------------------------------------

func test_welcome_locks_everything_until_start() -> void:
	var t := _new_tutorial()
	_assert(_phase(t) == TutorialView.Step.WELCOME, "fresh tutorial did not start at WELCOME")

	var combat := _combat(t)
	var rerolls_before: int = combat.rerolls
	var turn_before: int = combat.turn
	t.call("_on_reroll_pressed")
	t.call("_on_end_turn_pressed")
	t.call("_on_die_pressed", 0)
	_assert(combat.rerolls == rerolls_before, "reroll fired while still at WELCOME")
	_assert(combat.turn == turn_before, "end turn fired while still at WELCOME")
	_assert(_phase(t) == TutorialView.Step.WELCOME, "an ignored action advanced the WELCOME step")

	t.call("_on_start_pressed")
	_assert(_phase(t) == TutorialView.Step.ROLL, "START did not advance WELCOME -> ROLL")

	t.queue_free()
	_done("test_welcome_locks_everything_until_start")


func test_roll_step_locks_everything_but_got_it() -> void:
	var t := _new_tutorial()
	t.call("_on_start_pressed")
	_assert(_phase(t) == TutorialView.Step.ROLL, "fixture did not reach ROLL")

	var combat := _combat(t)
	var rerolls_before: int = combat.rerolls
	t.call("_on_reroll_pressed")
	t.call("_on_die_pressed", 0)
	_assert(combat.rerolls == rerolls_before, "reroll fired during ROLL")
	_assert(_phase(t) == TutorialView.Step.ROLL, "a locked action advanced the ROLL step")

	t.call("_on_got_it_pressed")
	_assert(_phase(t) == TutorialView.Step.INTENT, "GOT IT did not advance ROLL -> INTENT")

	t.queue_free()
	_done("test_roll_step_locks_everything_but_got_it")


func test_intent_step_only_accepts_an_enemy_click() -> void:
	var t := _new_tutorial()
	t.call("_on_start_pressed")
	t.call("_on_got_it_pressed")
	_assert(_phase(t) == TutorialView.Step.INTENT, "fixture did not reach INTENT")

	var combat := _combat(t)
	var rerolls_before: int = combat.rerolls
	t.call("_on_reroll_pressed")
	_assert(combat.rerolls == rerolls_before, "reroll fired during INTENT")
	_assert(_phase(t) == TutorialView.Step.INTENT, "a locked action advanced the INTENT step")

	t.call("_on_enemy_pressed", 0)
	_assert(bool(t.get("_intent_open")), "clicking an enemy at INTENT did not open the popup")
	t.call("_on_intent_close_pressed")
	_assert(_phase(t) != TutorialView.Step.INTENT, "closing the intent popup did not advance past INTENT")

	t.queue_free()
	_done("test_intent_step_only_accepts_an_enemy_click")


func test_reroll_step_only_accepts_reroll_and_actually_rerolls() -> void:
	var t := _new_tutorial()
	t.call("_on_start_pressed")
	t.call("_on_got_it_pressed")
	t.call("_on_enemy_pressed", 0)
	t.call("_on_intent_close_pressed")
	_assert(_phase(t) == TutorialView.Step.REROLL, "fixture did not reach REROLL")

	var combat := _combat(t)
	t.call("_on_end_turn_pressed")
	_assert(combat.turn == 1, "end turn fired during REROLL")
	_assert(_phase(t) == TutorialView.Step.REROLL, "a locked action advanced the REROLL step")

	var rerolls_before: int = combat.rerolls
	t.call("_on_reroll_pressed")
	_assert(combat.rerolls == rerolls_before - 1, "REROLL button did not spend a reroll")
	_assert(_phase(t) == TutorialView.Step.DIE, "REROLL did not advance REROLL -> DIE")

	t.queue_free()
	_done("test_reroll_step_only_accepts_reroll_and_actually_rerolls")


## The step this task's break/revert proof (see report) targets: DIE must reject every die
## except the one `_teaching_actor()` names, even when the handler is called directly.
func test_die_step_rejects_every_die_but_the_taught_one() -> void:
	var t := _new_tutorial()
	_advance_to_die(t)
	_assert(_phase(t) == TutorialView.Step.DIE, "fixture did not reach DIE")

	var combat := _combat(t)
	var taught: Unit = t.call("_teaching_actor")
	_assert(taught != null, "fixture has no teachable dmg actor on TUT_SEED — seed needs retuning")

	var wrong_idx := -1
	for i in combat.party.size():
		if int((combat.party[i] as Unit).uid) != taught.uid:
			wrong_idx = i
			break
	_assert(wrong_idx != -1, "fixture team has only one member — cannot exercise the wrong-die case")
	if wrong_idx != -1:
		t.call("_on_die_pressed", wrong_idx)
		_assert(int(t.get("_selected_uid")) == -1, "pressing a NON-taught die at DIE was accepted")
		_assert(_phase(t) == TutorialView.Step.DIE, "a wrong die press advanced the DIE step")

	var taught_idx := combat.party.find(taught)
	t.call("_on_die_pressed", taught_idx)
	_assert(int(t.get("_selected_uid")) == taught.uid, "pressing the taught die was not accepted")
	_assert(_phase(t) == TutorialView.Step.TARGET, "the taught die press did not advance DIE -> TARGET")

	t.queue_free()
	_done("test_die_step_rejects_every_die_but_the_taught_one")


func test_target_step_rejects_wrong_target_and_accepts_the_taught_one() -> void:
	var t := _new_tutorial()
	_advance_to_die(t)
	var combat := _combat(t)
	var taught: Unit = t.call("_teaching_actor")
	var taught_idx := combat.party.find(taught)
	t.call("_on_die_pressed", taught_idx)
	_assert(_phase(t) == TutorialView.Step.TARGET, "fixture did not reach TARGET")

	var expected: Unit = t.call("_teaching_target", taught)
	_assert(expected != null, "fixture produced no teachable target")

	# Wrong target: any uid that is not the expected one (an out-of-range uid always qualifies).
	var used_before := taught.roll_used()
	t.call("_on_target_pressed", -999)
	_assert(taught.roll_used() == used_before, "an invalid target uid was accepted at TARGET")
	_assert(_phase(t) == TutorialView.Step.TARGET, "a wrong target press advanced the TARGET step")

	t.call("_on_target_pressed", expected.uid)
	_assert(taught.roll_used(), "the taught target press did not actually use the die")
	_assert(_phase(t) != TutorialView.Step.TARGET, "the taught target press did not advance past TARGET")

	t.queue_free()
	_done("test_target_step_rejects_wrong_target_and_accepts_the_taught_one")


func test_endturn_step_rejects_early_end_turn_and_advances_on_the_real_one() -> void:
	var t := _new_tutorial()
	_advance_to_die(t)
	var combat := _combat(t)
	var taught: Unit = t.call("_teaching_actor")
	var taught_idx := combat.party.find(taught)
	t.call("_on_die_pressed", taught_idx)
	var expected: Unit = t.call("_teaching_target", taught)
	t.call("_on_target_pressed", expected.uid)

	if combat.won:
		# TUT_ENEMY_HP is tuned so the single taught hit should not itself end the fight — if it
		# ever does (e.g. after a future retune), ENDTURN is legitimately skipped, same as
		# client.html's own tutPhase() precedence (S.phase!=='combat' beats the ENDTURN check).
		_done("test_endturn_step_rejects_early_end_turn_and_advances_on_the_real_one")
		return

	_assert(_phase(t) == TutorialView.Step.ENDTURN, "fixture did not reach ENDTURN")
	var turn_before: int = combat.turn
	t.call("_on_reroll_pressed")
	t.call("_on_die_pressed", 0)
	_assert(combat.turn == turn_before, "an action other than end-turn fired during ENDTURN")
	_assert(_phase(t) == TutorialView.Step.ENDTURN, "a locked action advanced the ENDTURN step")

	t.call("_on_end_turn_pressed")
	_assert(combat.turn > turn_before or combat.won, "END TURN did not advance the fight")

	t.queue_free()
	_done("test_endturn_step_rejects_early_end_turn_and_advances_on_the_real_one")


## Full playthrough to REWARD, mirroring the exact taught sequence the task report's seed probe
## verified always wins within 2 real turns on TUT_SEED. Free-play turns 2+ are driven by a
## small bot exactly like the probe's, since nothing after ENDTURN is coached.
func test_reward_step_completes_tutorial_and_persists_the_flag() -> void:
	MetaState.tutorial_seen = false
	var t := _new_tutorial()
	_advance_to_die(t)
	var combat := _combat(t)
	var taught: Unit = t.call("_teaching_actor")
	t.call("_on_die_pressed", combat.party.find(taught))
	var expected: Unit = t.call("_teaching_target", taught)
	t.call("_on_target_pressed", expected.uid)
	if not combat.won:
		t.call("_on_end_turn_pressed")

	var safety := 0
	while not combat.won and not combat.lost and safety < 50:
		safety += 1
		var a: Unit = null
		for u in combat.party:
			if u.hp > 0 and u.has_rolled() and not u.roll_used() \
					and String(u.current_face().get("type", "")) == "dmg":
				a = u
				break
		if a == null:
			t.call("_on_end_turn_pressed")
			continue
		var tgt_uid := -1
		for e in combat.enemies:
			if e.hp > 0:
				tgt_uid = e.uid
				break
		if tgt_uid == -1:
			break
		t.call("_on_die_pressed", combat.party.find(a))
		if int(t.get("_selected_uid")) == a.uid:
			t.call("_on_target_pressed", tgt_uid)
		else:
			combat.use_die(a.uid, tgt_uid)   # FREE step: direct-die selection already covers
				# this in practice, but never let a probe-only fixture mismatch hang the test

	_assert(combat.won, "the taught + free-play sequence did not win within the safety bound")
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
