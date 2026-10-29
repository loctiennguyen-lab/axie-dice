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
	await _case_stale()
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


## Fresh run + real Combat.tscn on an elite node; free sample Continue left unless `paid`.
func _open_view(paid: bool) -> CombatView:
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
	return v


func _case(paid: bool) -> void:
	var tag := "paid" if paid else "free"
	var v := await _open_view(paid)
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

	# UI-05 DefeatPanel: ContinueButton = caption "Continue" + a CostChip (Gem price or "Free").
	v._defeat.set("_armed_at", 0)   # UI-05: the primary arms 1000 ms after the panel shows (tests skip the wait)
	var cont: Button = v._defeat.find_child("ContinueButton", true, false)
	_check(cont != null and not cont.disabled, "%s: Continue offered and enabled" % tag)
	var chip_txt: Array = _label_texts(cont.find_child("CostChip", true, false), []) if cont else []
	if paid:
		_check(cont != null and cont.get("caption") == "Continue" and chip_txt.has("90"), "%s: label %s" % [tag, str(chip_txt)])
	else:
		_check(cont != null and cont.get("caption") == "Continue" and chip_txt.has("Free"), "%s: label %s" % [tag, str(chip_txt)])
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


## Review follow-up: a defeat landing while End turn's enemy phase is still parked on a pacing timer, and
## Continue pressed in the same frame. The old coroutine must not move any enemy or finish a turn on the
## revived party when its timer fires. (The engine only raises a defeat inside finish_end_turn(), after
## those timers, so this is forced with _check_end(): a guard test, not a real flow. No replay check.)
func _case_stale() -> void:
	var tag := "stale"
	var v := await _open_view(false)
	var c: CombatEngine = v._combat
	_check(c != null and c.enemies.size() > 0, "%s: fight built" % tag)
	if c == null:
		return
	_intents = 0
	v._on_end_turn_pressed()   # not awaited: it parks on the enemy-step timer
	for _i in 300:
		await _tree.process_frame
		if _intents > 0:
			break
	_check(_intents > 0 and c.phase == CombatEngine.CombatPhase.END_TURN, "%s: enemy phase under way" % tag)
	var turn_before := c.turn
	for u in c.party:
		if not (u as Unit).is_token:
			(u as Unit).hp = 0
	c._check_end()
	_check(c.lost and v._defeat != null and v._defeat.visible, "%s: defeat panel up mid-phase" % tag)
	if v._defeat == null:
		v.queue_free()
		return
	v._defeat.set("_armed_at", 0)   # UI-05 1000 ms arm delay skipped for this guard test
	var cont: Button = v._defeat.find_child("ContinueButton", true, false)
	cont.pressed.emit()   # same frame
	_check(not c.lost and c.phase == CombatEngine.CombatPhase.EXECUTE, "%s: Continue took" % tag)
	var acted := _intents
	var gap := CombatView.enemy_step_gap()
	await _tree.create_timer(gap * float(c.enemies.size() + 2) + 0.5).timeout
	await _settle(v)
	_check(_intents == acted, "%s: no enemy moved after Continue (%d -> %d)" % [tag, acted, _intents])
	_check(c.turn == turn_before and c.phase == CombatEngine.CombatPhase.EXECUTE and not c.lost,
		"%s: still the revived player turn (turn %d -> %d, phase %d)" % [tag, turn_before, c.turn, c.phase])
	_check(not v._end_turn_button.disabled, "%s: End turn usable" % tag)
	_intents = 0
	await v._on_end_turn_pressed()
	await _settle(v)
	_check(_intents > 0 and (c.lost or (c.turn == turn_before + 1 and c.phase == CombatEngine.CombatPhase.EXECUTE)),
		"%s: the next End turn plays normally (turn %d, phase %d)" % [tag, c.turn, c.phase])
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


func _label_texts(n: Node, out: Array) -> Array:
	if n == null:
		return out
	if n is Label and (n as Label).is_visible_in_tree():
		out.append((n as Label).text)
	for ch in n.get_children():
		_label_texts(ch, out)
	return out
