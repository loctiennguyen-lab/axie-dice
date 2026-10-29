extends Node
## Hotfix B1 (29/10): after a defeat, Continue (free sample or paid with Gem) revived the party but the first
## End turn afterwards hung on "Waiting…": _finish(false) had set CombatView._result_shown and Continue never
## cleared it, so _still_running() was false, End turn logged `end_turn` and stopped before the enemy phase.
##
## Drives the REAL Combat.tscn with juice on (the defeat panel only shows with juice): a party left at 1 HP is
## wiped by End turn, the panel's Continue button is pressed, then End turn again. Passing means the enemy
## turn ran, the next player turn started, the run was saved, and the fight state equals a plain engine replay
## (end_turn / continue_after_wipe with the same epoch seeds), i.e. what RunVerifier will replay.
## Two cases: free sample Continue, and paid Continue with fake local Gem. No network (local epoch source).
##
## Run: godot --headless --path godot res://tests/t_continue_then_end_turn.tscn

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
const RUN_SEED := 424242
const NODE_ID := "r10_c0"
const MAX_TURNS := 20

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
var _tree: SceneTree
var _intents := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	_tree = get_tree()
	_guard.capture()
	CombatView.disable_juice_for_tests = false   # the defeat panel is skipped in the juice-off test mode
	EventBus.enemy_intent_executed.connect(func(_uid: int) -> void: _intents += 1)
	await _case(false)
	await _case(true)
	for f in _fails:
		print("t_continue_then_end_turn: FAIL — %s" % f)
	_guard.restore()
	if _fails.is_empty():
		print("t_continue_then_end_turn: PASS — %d checks OK" % _checks)
		_tree.quit(0)
	else:
		_tree.quit(1)


func _setup() -> Dictionary:
	var roster: Array = []
	for i in TEAM.size():
		roster.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return {"node_id": NODE_ID, "kind": "elite", "pw": 2, "ascension": 0, "roster_snapshot": roster,
		"relic_ids": [], "combat_seed": RUN_SEED, "newcomer": false, "mission": false}


## Every real party member down to 1 HP, so a couple of enemy turns wipe them (same edit on the twin).
func _frail(c: CombatEngine) -> void:
	for u in c.party:
		if not (u as Unit).is_token:
			(u as Unit).hp = 1


func _case(paid: bool) -> void:
	var tag := "paid" if paid else "free"
	RunState.start_new_run(RUN_SEED, TEAM, "short", 0, false)
	RunState.current_node_id = NODE_ID
	MetaState.runs = 10
	MetaState.runs_with_battle = 30
	MetaState.runs_completed = 10
	MetaState.free_continue_used = paid
	MetaState.gems_cache = 500 if paid else 0
	var rows_d: Array = []
	for r in range(1, 19):
		rows_d.append([{"id": NODE_ID if r == 10 else "r%d" % r, "row": r, "col": 0,
			"node_type": "elite" if r == 10 else "battle", "next_ids": [], "visited": false, "locked": false}])
	RunState.map_graph = {"rows": rows_d, "boss_rows": [], "elite_rows": [10], "start_node_id": "r1"}
	var setup := _setup()
	var pending := setup.duplicate(true)
	pending["epoch"] = RunState.epoch
	RunState.pending_combat = pending

	var v: CombatView = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(v)
	for _i in 3:
		await _tree.process_frame
	var c: CombatEngine = v._combat
	_check(c != null and not c.lost, "%s: fight built" % tag)
	if c == null:
		return
	_frail(c)
	v._rebuild_all()

	# Lose: End turn until the defeat panel is up.
	var n := 0
	while n < MAX_TURNS and not (v._defeat != null and v._defeat.visible):
		await _settle(v)
		await v._on_end_turn_pressed()
		await _settle(v)
		n += 1
	_check(c.lost and v._defeat != null and v._defeat.visible, "%s: party wiped, defeat panel shown (%d turns)" % [tag, n])
	if not c.lost or v._defeat == null:
		v.queue_free()
		await _tree.process_frame
		return

	var cont: Button = v._defeat.find_child("Continue", true, false)
	_check(cont != null and not cont.disabled, "%s: Continue offered and enabled" % tag)
	if paid:
		_check(cont != null and cont.text == "Continue · 90 Gem", "%s: label '%s'" % [tag, cont.text if cont else ""])
	else:
		_check(cont != null and cont.text == "Continue · Free", "%s: label '%s'" % [tag, cont.text if cont else ""])
	var turn_at_wipe := c.turn

	# Continue, through the button.
	cont.pressed.emit()
	for _i in 30:
		await _tree.process_frame
		if not c.epoch_pending and not v._defeat.visible:
			break
	_check(not c.lost and c.attempt == 1, "%s: Continue revived the party" % tag)
	_check(not v._defeat.visible, "%s: panel closed" % tag)
	_check(not v._result_shown, "%s: _result_shown cleared (the bug)" % tag)
	_check(c.phase == CombatEngine.CombatPhase.EXECUTE and c.can_end_turn(), "%s: back in EXECUTE, End turn allowed" % tag)
	_check(not v._end_turn_button.disabled, "%s: End turn button enabled" % tag)
	if paid:
		_check(MetaState.gem_wallet().balance() == 410, "%s: charged 90 Gem once (balance %d)" % [tag, MetaState.gem_wallet().balance()])
	else:
		_check(MetaState.free_continue_used and MetaState.gem_wallet().balance() == 0, "%s: free sample spent, no Gem" % tag)
	var saved: Variant = JSON.parse_string(SaveStore.read_text(RunState.SAVE_PATH))
	_check(saved is Dictionary and int(((saved as Dictionary).get("combat", {}) as Dictionary).get("attempt", -1)) == 1,
		"%s: run saved right after Continue" % tag)

	# The first End turn after Continue: the enemy turn runs and the next player turn starts.
	_intents = 0
	await _settle(v)
	await v._on_end_turn_pressed()
	await _settle(v)
	_check(_intents > 0, "%s: enemies acted after Continue" % tag)
	_check(c.turn == turn_at_wipe + 1, "%s: next turn started (turn %d -> %d)" % [tag, turn_at_wipe, c.turn])
	_check(not c.lost and c.phase == CombatEngine.CombatPhase.EXECUTE, "%s: player turn again (lost=%s phase=%d)" % [tag, c.lost, c.phase])
	_check(not v._hud_frame._seed_wait, "%s: not left on 'Waiting for server'" % tag)
	_check(not v._end_turn_button.disabled, "%s: End turn button enabled for the next turn" % tag)
	saved = JSON.parse_string(SaveStore.read_text(RunState.SAVE_PATH))
	_check(saved is Dictionary and int(((saved as Dictionary).get("combat", {}) as Dictionary).get("turn", -1)) == c.turn,
		"%s: run saved after the enemy turn" % tag)

	# Same fight as a plain engine replay with the same seeds (what RunVerifier does from the log + tape).
	var twin := CombatEngine.new()
	twin.setup_new(_setup())
	_frail(twin)
	var applied := 0
	for t in RunState.epoch.tape():
		match String(t["kind"]):
			"end_turn":
				twin.end_turn(int(t["seed"]))
				applied += 1
			"continue":
				twin.continue_after_wipe(int(t["seed"]), -1)
				applied += 1
	var fns: Array = []
	for en in RunState.action_log.entries:
		if String(en["fn"]) in ["end_turn", "continue"]:
			fns.append(String(en["fn"]))
	_check(applied == fns.size() and fns.has("continue"), "%s: log and tape agree (%d tape, %s)" % [tag, applied, str(fns)])
	_check(JSON.stringify(twin.to_data()) == JSON.stringify(c.to_data()), "%s: UI fight equals the engine replay" % tag)

	v.queue_free()
	for _i in 3:
		await _tree.process_frame


## Waits until no hit animation, seed request or dice roll is in progress (bounded).
func _settle(v: CombatView) -> void:
	for _i in 600:
		if not is_instance_valid(v) or (not v._is_animating and not v._combat.epoch_pending and not v._dice_in_air()):
			return
		if v._dice_in_air():
			v._land_dice_now()
		await _tree.process_frame
