extends Node
## B2 gate (29/10): a run played through the REAL screens must pass RunVerifier.
##
## The bug: the move that ends a fight (use_die / play_active) runs CombatEngine._check_end() BEFORE it logs itself,
## and CombatEngine emits combat_finished from inside _check_end(). CombatView used to ask for the `reward` epoch right
## there, so the epoch hashed a log one entry short; RunVerifier replays with that move included and rejected every UI
## run at its first won fight. Bot/soak paths never saw it (they apply the result after use_die returns).
##
## Part A: a real run (RunMap.tscn <-> Combat.tscn, real handlers: node press, die/target clicks, end turn, reward pick)
##   on a LocalEpochSource, several won fights, then RunVerifier.verify(log, tape) must be ok. Also checks, for every
##   `reward` epoch on the tape, that the log entry right before its log_len is the combat move that ended the fight.
## Part B: three probes on a fresh first fight each, the fight state edited so ONE chosen move ends it (so these runs
##   are not replayable; only the epoch's log_len is checked): a die kill (use_die), a relic active kill (play_active,
##   a_chomp), and poison at end of turn (end_turn). In each, the reward epoch must hash the log up to and including
##   that move.
##
## No network, worktree user dir (SaveGuard). Run: godot --headless --path godot res://tests/t_ui_run_verifies.tscn

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
const SEED_A := 515151
const WINS_WANTED := 3
const BUDGET_MS := 90000
const COMBAT_FNS := ["use_die", "play_active", "reroll_dice", "undo_last", "end_turn", "tweak", "hold_pick",
	"loaded_pick", "continue", "stash", "overcast", "wild_face"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
var _tree: SceneTree
var _src: LocalEpochSource = null
var _wins := 0
var _end_fns: Dictionary = {}


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	_tree = get_tree()
	_guard.capture()
	CombatView.disable_juice_for_tests = true
	# This node must outlive the real scene changes: park it under root and detach it as current scene.
	await _tree.process_frame
	reparent(_tree.root)
	_tree.current_scene = null
	await _part_a()
	await _probe("use_die", 616161)
	await _probe("play_active", 626262)
	await _probe("end_turn", 636363)
	await _unload()
	CombatView.disable_juice_for_tests = false
	_guard.restore()
	if _fails.is_empty():
		print("t_ui_run_verifies: PASS — %d checks, UI run verified after %d won fights (ended by %s); reward epoch after the final move for use_die, play_active, end_turn" % [_checks, _wins, str(_end_fns)])
		_tree.quit(0)
	else:
		for f in _fails:
			print("t_ui_run_verifies: FAIL — " + f)
		_tree.quit(1)


func _params() -> Dictionary:
	# HP bonus so the simple UI bot keeps winning; unranked, so verify() needs allow_unranked (the log header carries it).
	return {"team_keys": TEAM.duplicate(), "mode": "short", "ascension": 0, "ranked": false,
		"bonuses": {"hp_bonus": 40}}


func _frames(n: int) -> void:
	for i in n:
		await _tree.process_frame


func _unload() -> void:
	if _tree.current_scene != null:
		_tree.unload_current_scene()
	await _frames(5)


# ------------------------------------------------------------------ part A

func _part_a() -> void:
	_src = LocalEpochSource.new(PackedByteArray(), SEED_A)
	_check(RunState.start_run_with_epoch(_src, _params(), SEED_A), "A: run did not start")
	_tree.change_scene_to_file("res://scenes/run_map/RunMap.tscn")
	await _drive_until_wins(WINS_WANTED)
	await _unload()   # the screen must be gone before the verifier drives RunState
	var log: ActionLog = RunState.action_log
	var tape: Array = _src.tape()
	_check(_wins >= 1, "A: the UI run never won a fight (wins=%d)" % _wins)
	var rewards := 0
	for t in tape:
		if String((t as Dictionary).get("kind", "")) != "reward":
			continue
		rewards += 1
		var n := int(((t as Dictionary).get("extra", {}) as Dictionary).get("log_len", -1))
		var prev_fn := String((log.entries[n - 1] as Dictionary).get("fn", "")) if n >= 1 and n <= log.entries.size() else ""
		var next_fn := String((log.entries[n] as Dictionary).get("fn", "")) if n >= 0 and n < log.entries.size() else ""
		_end_fns[prev_fn] = int(_end_fns.get(prev_fn, 0)) + 1
		_check(prev_fn in COMBAT_FNS, "A: reward epoch #%d hashed a log ending in '%s', not the fight's last move" % [rewards, prev_fn])
		_check(not (next_fn in COMBAT_FNS), "A: reward epoch #%d was drawn BEFORE combat move '%s' was logged (log_len=%d)" % [rewards, next_fn, n])
	_check(rewards >= 1, "A: no reward epoch on the tape")
	var v := RunVerifier.verify(log, tape, {}, true)
	_check(bool(v["ok"]), "A: RunVerifier rejected the UI run: %s %s (action %d)" % [v.get("error", ""), v.get("message", ""), int(v.get("action_index", -1))])
	print("t_ui_run_verifies: A wins=%d rewards=%d log=%d verify=%s %s" % [_wins, rewards, log.entries.size(), v["ok"], v.get("error", "")])


func _drive_until_wins(want: int) -> void:
	var t0 := Time.get_ticks_msec()
	var counted: CombatEngine = null
	while Time.get_ticks_msec() - t0 < BUDGET_MS:
		await _frames(2)
		if RunState.phase == RunState.RunPhase.WON or RunState.phase == RunState.RunPhase.LOST:
			return
		var scene := _tree.current_scene
		if scene == null or not is_instance_valid(scene) or not scene.is_node_ready():
			continue
		var intro_layer := scene.get_node_or_null("BossIntroLayer")
		if intro_layer != null:
			for c in intro_layer.get_children():
				if c is BossIntro:
					(c as BossIntro).skip()
			continue
		if scene is CombatView:
			var c: CombatEngine = (scene as CombatView).get("_combat") as CombatEngine
			await _play_fight(scene as CombatView)
			if c != null and c.won and c != counted:
				counted = c
				_wins += 1
		elif scene.has_method("_on_node_pressed"):
			if _wins >= want and RunState.phase == RunState.RunPhase.MAP:
				return
			await _map_step(scene)
		else:
			return
	_check(false, "A: did not reach %d won fights within %d ms (wins=%d)" % [want, BUDGET_MS, _wins])


func _map_step(ctrl: Node) -> void:
	match RunState.phase:
		RunState.RunPhase.MAP:
			var ids: Array = ctrl.call("_reachable_now_ids")
			if ids.is_empty():
				_check(false, "map has no reachable node")
				return
			await ctrl.call("_on_node_pressed", ids[0])
		RunState.RunPhase.EVENT:
			await ctrl.call("_on_event_choice", 0)
			ctrl.call("_finish_node")
		RunState.RunPhase.SHOP:
			ctrl.call("_finish_node")
		RunState.RunPhase.TREASURE, RunState.RunPhase.REWARD:
			if RunState.pending_rewards.is_empty():
				ctrl.call("_maybe_show_pending_reward")
			else:
				ctrl.call("_on_reward_chosen", RunState.pending_rewards[0])
		RunState.RunPhase.PACT:
			RunState.take_pact(0)
			ctrl.call("_after_pact")


func _play_fight(view: CombatView) -> void:
	var combat: CombatEngine = view.get("_combat") as CombatEngine
	if combat == null:
		return
	var turns := 0
	while is_instance_valid(view) and not (combat.won or combat.lost) and turns < 60:
		turns += 1
		await _wait_anim(view)
		var guard := 0
		var moved := true
		while moved and guard < 32 and not (combat.won or combat.lost):
			guard += 1
			moved = false
			var units: Array = view.call("_party_dice_units")
			for move in RunBot.legal_moves(combat):
				for i in units.size():
					if (units[i] as Unit).uid == int(move[0]):
						await _wait_anim(view)
						view.call("_on_die_slot_pressed", i)
						view.call("_on_target_clicked", int(move[1]))
						moved = true
						break
				break
		if combat.won or combat.lost:
			break
		await view.call("_on_end_turn_pressed")
	await _settle()


## Until the fight's result has been applied (the deferred _finish) and the scene moved on.
func _settle() -> void:
	var g := 0
	while g < 600 and (RunState.phase == RunState.RunPhase.COMBAT or RunState.epoch_busy):
		await _tree.process_frame
		g += 1
	await _frames(4)


func _wait_anim(view: Node) -> void:
	var g := 0
	while is_instance_valid(view) and bool(view.get("_is_animating")) and g < 300:
		await _tree.process_frame
		g += 1


# ------------------------------------------------------------------ part B

## Starts a fresh run, enters its first battle through RunMap, and returns the CombatView (null on failure).
func _enter_first_fight(seed: int) -> CombatView:
	await _unload()
	_src = LocalEpochSource.new(PackedByteArray(), seed)
	if not RunState.start_run_with_epoch(_src, _params(), seed):
		_check(false, "B: run %d did not start" % seed)
		return null
	_tree.change_scene_to_file("res://scenes/run_map/RunMap.tscn")
	var g := 0
	while g < 600:
		await _tree.process_frame
		g += 1
		var scene := _tree.current_scene
		if scene == null or not is_instance_valid(scene) or not scene.is_node_ready():
			continue
		if scene is CombatView:
			var v := scene as CombatView
			if v.get("_combat") != null:
				await _wait_anim(v)
				await _frames(2)
				return v
		elif scene.has_method("_on_node_pressed") and not RunState.epoch_busy:
			await _map_step(scene)   # a run can open on a Core offer before the map
	var cs := _tree.current_scene
	_check(false, "B: run %d never reached its first fight (scene=%s phase=%d busy=%s)" % [seed,
		cs.name if cs != null else "null", RunState.phase, RunState.epoch_busy])
	return null


func _probe(kind: String, seed: int) -> void:
	var view := await _enter_first_fight(seed)
	if view == null:
		return
	var combat: CombatEngine = view.get("_combat") as CombatEngine
	_check(RunState.phase == RunState.RunPhase.COMBAT and combat.kind != "boss", "B %s: first node is not a plain fight" % kind)
	# Leave one enemy, at 1 HP (state edited: this fight cannot be replayed, only its epoch order is checked).
	var alive := combat.alive_enemies()
	var last: Unit = alive[alive.size() - 1]
	for e in alive:
		if e != last:
			e.hp = 0
	last.hp = 1
	last.shield = 0
	view.call("_rebuild_all")
	var log: ActionLog = RunState.action_log
	match kind:
		"use_die":
			var units: Array = view.call("_party_dice_units")
			var hit := false
			for i in units.size():
				var u: Unit = units[i]
				var fi: int = u.roll_face_index() if u.has_rolled() and not u.roll_used() else -1
				if u.hp <= 0 or fi < 0 or String((u.die[fi] as Dictionary).get("type", "")) != "dmg":
					continue
				view.call("_on_die_slot_pressed", i)
				view.call("_on_target_clicked", last.uid)
				hit = combat.won
				if hit:
					break
			_check(hit, "B use_die: no rolled damage die ended the fight (cannot construct)")
		"play_active":
			combat.mana = maxi(combat.mana, 10)
			view.call("_on_active_pressed", "a_chomp")
			view.call("_on_target_clicked", last.uid)
			_check(combat.won, "B play_active: a_chomp did not end the fight (mana=%d)" % combat.mana)
		"end_turn":
			last.status["poison"] = 5
			for u in combat.party:
				u.hp = u.max_hp + 200   # the enemy's own hit must not end it first
			await view.call("_on_end_turn_pressed")
			_check(combat.won, "B end_turn: poison at end of turn did not end the fight")
	if not combat.won:
		return
	var at_end := log.entries.size()
	_check(String((log.entries[at_end - 1] as Dictionary).get("fn", "")) == kind,
		"B %s: the last log entry is '%s'" % [kind, String((log.entries[at_end - 1] as Dictionary).get("fn", ""))])
	await _settle()
	var reward: Dictionary = {}
	for t in _src.tape():
		if String((t as Dictionary).get("kind", "")) == "reward":
			reward = t
	_check(not reward.is_empty(), "B %s: no reward epoch was requested after the win" % kind)
	if reward.is_empty():
		return
	var n := int((reward.get("extra", {}) as Dictionary).get("log_len", -1))
	_check(n == at_end, "B %s: the reward epoch hashed %d log entries, the fight ended at entry %d ('%s' must be inside the hash)" % [kind, n, at_end, kind])
	_check(RunState.phase != RunState.RunPhase.COMBAT, "B %s: the result was never applied" % kind)
	print("t_ui_run_verifies: B %s reward.log_len=%d fight_end=%d phase=%d" % [kind, n, at_end, RunState.phase])
