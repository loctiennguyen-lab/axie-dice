extends Node
## END-TO-END gate for the L1 B1 bug (15/10): with a REMOTE epoch source every UI action that consumes an
## epoch must go through an async request_* wrapper. A real run is driven through the real scenes
## (RunMap.tscn <-> Combat.tscn, real scene changes) and their real handlers (node press, die/target clicks,
## reroll, end turn, reward + reroll, shop buy, event choice, Pact swap/pick), against an in-process fake
## remote source whose replies arrive one frame LATER (is_remote() true). Passing means: no
## "needs the async request_*" error was logged, every epoch kind the UI uses was answered late, and the run
## reached the first boss. The fake also VALIDATES every request against worker/src/epoch_args.json (the same file
## the Worker's argsProblem reads) and rejects like the server would, and it injects failures: `expired` on the first
## node press (NetNotice must offer SIGN IN, input must not stay locked), `offline` once on a mid-combat end_turn and
## once on the reward request (NetNotice -> RETRY -> the run goes on). No network (the fake never opens a socket).
##
## Run: godot --headless --path godot res://tests/t_remote_epoch_ui_run.tscn

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
const BUDGET_MS := 100000
const STUCK_LIMIT := 120

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
var _tree: SceneTree
var _fake: FakeRemote
var _logger: ErrCatcher
var _nodes_by_type: Dictionary = {}
var _signin_seen := 0
var _retries := 0
var _last_combat: CombatEngine = null


## Same seeds as LocalEpochSource (so rules are unchanged), but every reply settles one frame later.
class FakeRemote extends LocalEpochSource:
	var late_kinds: Dictionary = {}
	var tree: SceneTree
	var spec: Dictionary = {}
	var rejected: Array[String] = []
	## [{kind, code}] each fires once, on the first matching request, and does not advance the hash chain
	var fail_plan: Array = []
	var injected := 0

	static func load_spec() -> Dictionary:
		var path := ProjectSettings.globalize_path("res://").path_join("../worker/src/epoch_args.json")
		var f := FileAccess.open(path, FileAccess.READ)
		return JSON.parse_string(f.get_as_text()) as Dictionary if f != null else {}

	## null-string when the args are acceptable for the kind, else why not (mirrors run_core.js argsProblem).
	func problem(kind: String, args: Dictionary) -> String:
		var ks: Dictionary = (spec.get("kinds", {}) as Dictionary).get(kind, {})
		if ks.is_empty():
			return "kind"
		for k in args.keys():
			if not (ks["keys"] as Array).has(k):
				return "key_" + String(k)
			var sp: Dictionary = (spec["args"] as Dictionary).get(k, {})
			if sp.is_empty() or not _value_ok(sp, args[k]):
				return "value_" + String(k)
		for k in ks["required"]:
			if not args.has(k):
				return "missing_" + String(k)
		return ""

	func _is_int(v) -> bool:
		return typeof(v) == TYPE_INT or (typeof(v) == TYPE_FLOAT and v == floor(v))

	func _value_ok(sp: Dictionary, v) -> bool:
		match String(sp["type"]):
			"enum": return (sp["values"] as Array).has(v)
			"int": return _is_int(v) and v >= sp["min"] and v <= sp["max"]
			"int_list":
				if not (v is Array) or v.size() < int(sp["min_len"]) or v.size() > int(sp["max_len"]):
					return false
				for x in v:
					if not _is_int(x) or x < sp["min"] or x > sp["max"]:
						return false
				return true
			"ident", "node_id":
				if typeof(v) != TYPE_STRING:
					return false
				var re := RegEx.new()
				re.compile(String(sp["regex"]))
				return re.search(v) != null
		return false

	func is_remote() -> bool:
		return true

	func request(kind: String, args: Dictionary) -> EpochReply:
		var r := EpochReply.new()
		late_kinds[kind] = int(late_kinds.get(kind, 0)) + 1
		var why := problem(kind, args)
		if why != "":
			rejected.append("%s: %s %s" % [kind, why, str(args)])
			tree.process_frame.connect(func(): r.settle(false, 0, "bad_request"), CONNECT_ONE_SHOT)
			return r
		for i in fail_plan.size():
			if String(fail_plan[i]["kind"]) == kind:
				var code := String(fail_plan[i]["code"])
				fail_plan.remove_at(i)
				injected += 1
				tree.process_frame.connect(func(): r.settle(false, 0, code), CONNECT_ONE_SHOT)
				return r
		var inner := super.request(kind, args)
		tree.process_frame.connect(func(): r.settle(inner.ok, inner.seed, inner.code, inner.extra),
			CONNECT_ONE_SHOT)
		return r


class ErrCatcher extends Logger:
	var async_errors := 0
	var other: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			editor_notify: bool, error_type: int, script_backtraces: Array) -> void:
		var msg := code + " " + rationale
		if msg.contains("needs the async request_"):
			async_errors += 1
		elif msg.contains("refused"):
			other.append(msg)


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	_tree = get_tree()
	_guard.capture()
	_logger = ErrCatcher.new()
	OS.add_logger(_logger)
	CombatView.disable_juice_for_tests = true
	# This node must outlive the real scene changes: park it under root and detach it as current scene.
	await _tree.process_frame
	reparent(_tree.root)
	_tree.current_scene = null
	_fake = FakeRemote.new(PackedByteArray(), 424242)
	_fake.tree = _tree
	_fake.spec = FakeRemote.load_spec()
	_check(not _fake.spec.is_empty(), "worker/src/epoch_args.json not readable")
	_fake.fail_plan = [{"kind": "node", "code": "expired"}, {"kind": "end_turn", "code": "offline"},
		{"kind": "reward", "code": "offline"}]
	_check(RunState.start_run_with_epoch(_fake, {"team_keys": TEAM.duplicate(), "mode": "short",
		"ascension": 0, "ranked": false}, 424242), "run did not start on the fake remote source")
	RunState.shards_this_run = 999   # so the shop's heal item (a `shop_roll` epoch) can be bought
	_tree.change_scene_to_file("res://scenes/run_map/RunMap.tscn")
	await _drive()
	_finish_test()


func _finish_test() -> void:
	OS.remove_logger(_logger)
	CombatView.disable_juice_for_tests = false
	_check(_logger.async_errors == 0, "%d 'needs the async request_*' errors" % _logger.async_errors)
	RunState.shop_items = [{"kind": "heal", "cost": 1}, {"kind": "relic", "cost": 1}]
	_check(_fake.problem("shop_roll", {"node_id": "r2_c0", "item": RunState._shop_item_arg(0)}) == "",
		"shop_roll item arg '%s' would be refused by the server" % RunState._shop_item_arg(0))
	_check(_fake.problem("shop_roll", {"node_id": "r2_c0", "item": 0}) != "", "validator accepts an int item")
	_check(_fake.rejected.is_empty(), "requests the server would refuse: %s" % str(_fake.rejected))
	_check(_fake.fail_plan.is_empty(), "injected failures never fired: %s" % str(_fake.fail_plan))
	_check(_signin_seen >= 1, "expired: NetNotice never showed SIGN IN")
	_check(_retries >= 2, "offline: NetNotice RETRY pressed %d times (want >= 2)" % _retries)
	_check(not RunState.epoch_busy and not (_last_combat != null and _last_combat.epoch_pending), "input lock left on")
	_check(_logger.other.is_empty(), "epoch refusals logged: %s" % str(_logger.other))
	_check(RunState.bosses_started >= 1, "the run never reached the first boss (bosses_started=0)")
	for k in ["node", "reroll", "end_turn", "reward"]:
		_check(int(_fake.late_kinds.get(k, 0)) > 0, "epoch kind '%s' was never requested through the UI" % k)
	print("=== t_remote_epoch_ui_run: nodes=%s late_kinds=%s phase=%d bosses=%d ===" % [
		_nodes_by_type, _fake.late_kinds, RunState.phase, RunState.bosses_started])
	_guard.restore()
	if _fails.is_empty():
		print("t_remote_epoch_ui_run: PASS — %d checks, a run reached the first boss on a late-replying remote epoch" % _checks)
		_tree.quit(0)
	else:
		for f in _fails:
			print("t_remote_epoch_ui_run: FAIL — " + f)
		_tree.quit(1)


func _frames(n: int) -> void:
	for i in n:
		await _tree.process_frame


func _drive() -> void:
	var t0 := Time.get_ticks_msec()
	var last_sig := ""
	var same := 0
	var rerolled_reward := false
	while Time.get_ticks_msec() - t0 < BUDGET_MS:
		await _frames(2)
		if RunState.bosses_started >= 1 and RunState.phase != RunState.RunPhase.COMBAT \
				and RunState.phase != RunState.RunPhase.MAP:
			return
		if RunState.phase == RunState.RunPhase.WON or RunState.phase == RunState.RunPhase.LOST:
			return
		var scene := _tree.current_scene
		if scene == null or not is_instance_valid(scene) or not scene.is_node_ready():
			continue
		var sig := "%s|%d|%s|%d" % [scene.name, RunState.phase, RunState.current_node_id, RunState.pending_rewards.size()]
		same = same + 1 if sig == last_sig else 0
		last_sig = sig
		if same > STUCK_LIMIT:
			_check(false, "stuck for %d iterations at %s" % [STUCK_LIMIT, sig])
			return
		if await _handle_notice(scene):
			continue
		if scene.has_method("_on_end_turn_pressed"):
			await _play_fight(scene)
		elif scene.has_method("_on_node_pressed"):
			rerolled_reward = await _map_step(scene, rerolled_reward)
		else:
			return   # Result screen
	_check(false, "run did not finish within %d ms" % BUDGET_MS)


## A NetNotice on `scene`: RETRY when offered, else (fatal code) check SIGN IN is there and dismiss with OK.
## Returns true when there was one.
func _handle_notice(scene: Node) -> bool:
	if scene == null or not is_instance_valid(scene):
		return false
	var n := scene.get_node_or_null("NetNotice")
	if n == null:
		return false
	var retry := n.find_child("RetryButton", true, false) as Button
	if retry != null:
		_retries += 1
		retry.pressed.emit()
	else:
		_check(n.find_child("SignInButton", true, false) != null and n.find_child("BackButton", true, false) != null,
			"fatal notice without SIGN IN / BACK TO MENU")
		_signin_seen += 1
		(n.find_child("OkButton", true, false) as Button).pressed.emit()
	await _frames(4)
	while RunState.epoch_busy or (_last_combat != null and _last_combat.epoch_pending):
		await _tree.process_frame
	return true


func _map_step(ctrl: Node, rerolled_reward: bool) -> bool:
	match RunState.phase:
		RunState.RunPhase.MAP:
			var ids: Array = ctrl.call("_reachable_now_ids")
			if ids.is_empty():
				_check(false, "map has no reachable node")
				return rerolled_reward
			var graph := RunMapGraph.from_data(RunState.map_graph)
			var nt := String(graph.find_node(String(ids[0])).node_type)
			_nodes_by_type[nt] = int(_nodes_by_type.get(nt, 0)) + 1
			await ctrl.call("_on_node_pressed", ids[0])
		RunState.RunPhase.EVENT:
			await ctrl.call("_on_event_choice", 0)
			ctrl.call("_finish_node")
		RunState.RunPhase.SHOP:
			for i in RunState.shop_items.size():
				await ctrl.call("_on_shop_buy", i)
			ctrl.call("_finish_node")
		RunState.RunPhase.TREASURE, RunState.RunPhase.REWARD:
			if RunState.pending_rewards.is_empty():
				ctrl.call("_maybe_show_pending_reward")
			else:
				if not rerolled_reward and RunState.reward_reroll_charges > 0:
					rerolled_reward = true
					await ctrl.call("_on_reward_reroll", "CHOOSE ONE REWARD")
				ctrl.call("_on_reward_chosen", RunState.pending_rewards[0])
		RunState.RunPhase.PACT:
			var view := ctrl.find_child("PactView", true, false)
			if view != null:
				view.emit_signal("swap_requested", 0)
				while RunState.epoch_busy:
					await _tree.process_frame
				view.emit_signal("picked", 0, "")
				if RunState.phase == RunState.RunPhase.PACT:
					view.emit_signal("skipped")
			if RunState.phase == RunState.RunPhase.PACT:
				RunState.take_pact(0)
				ctrl.call("_after_pact")
	return rerolled_reward


func _play_fight(view: Node) -> void:
	var combat: CombatEngine = view.get("_combat") as CombatEngine
	if combat == null:
		return
	_last_combat = combat
	var rolls := 0
	while is_instance_valid(view) and not (combat.won or combat.lost) and rolls < 200:
		rolls += 1
		await _wait_anim(view)
		if rolls == 1 and combat.rerolls > 0:
			await view.call("_on_reroll_pressed")   # one reroll per fight through the real handler
			await _wait_anim(view)
		var moved := true
		var guard := 0
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
				break   # state changed: recompute the legal moves
		if combat.won or combat.lost:
			break
		await view.call("_on_end_turn_pressed")
		if is_instance_valid(view) and await _handle_notice(view):
			continue
	await _frames(4)   # let _finish() apply the result and change the scene


func _wait_anim(view: Node) -> void:
	var g := 0
	while is_instance_valid(view) and bool(view.get("_is_animating")) and g < 300:
		await _tree.process_frame
		g += 1
