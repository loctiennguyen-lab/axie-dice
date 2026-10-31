extends Node
## UI-05 b23 lane 0b: the action log + epoch tape of a real-UI seed-walk (RunMap <-> Combat) must stay byte-identical across the
## RunMapController split. Golden in tests/data/. Write it with AXIE_WRITE_GOLDEN=1.

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
const SEED_A := 515151
const GOLDEN := "res://tests/data/runmap_split_log.golden.json"
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
	await _unload()
	CombatView.disable_juice_for_tests = false
	_guard.restore()
	if _fails.is_empty():
		print("t_runmap_split_log_golden: PASS — %d checks, UI run verified after %d won fights (ended by %s); log + tape match golden" % [_checks, _wins, str(_end_fns)])
		_tree.quit(0)
	else:
		for f in _fails:
			print("t_runmap_split_log_golden: FAIL — " + f)
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
	var blob := JSON.stringify({"entries": log.entries, "tape": tape}, "", true)
	if OS.get_environment("AXIE_WRITE_GOLDEN") == "1":
		var wf := FileAccess.open(ProjectSettings.globalize_path(GOLDEN), FileAccess.WRITE)
		wf.store_string(blob)
		wf.close()
		print("t_runmap_split_log_golden: golden written, %d bytes" % blob.length())
	else:
		var rf := FileAccess.open(GOLDEN, FileAccess.READ)
		_check(rf != null, "A: golden file missing")
		if rf != null:
			var want := rf.get_as_text()
			_check(want == blob, "A: action log/tape differ from golden (len %d vs %d)" % [blob.length(), want.length()])
	print("t_runmap_split_log_golden: A wins=%d rewards=%d log=%d verify=%s %s" % [_wins, rewards, log.entries.size(), v["ok"], v.get("error", "")])


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


