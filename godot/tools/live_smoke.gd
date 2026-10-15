extends Node
## LIVE SMOKE: proves a real online run works against the PRODUCTION Worker (axie/server_url) before a build
## goes to a human. Real DesktopTransport (Bearer), real RunSession/RemoteEpochSource over a real WebSocket,
## real scenes (RunSetup -> RunMap <-> Combat). NOT a test: it must NOT run with AXIE_TEST_NO_NET.
##
## Run it through godot/tools/live_smoke.sh (own user dir + session copy + lock + kill timer).
##
## Steps (one line each, OK/FAIL + server code): session, begin, node press, combat won, reward, second node,
## abandon (real endpoint), no open run left. Exit 0 only if every step passed.
##
## Safety: cloud save uploads are impossible here (SaveStore.on_changed cleared, and the transport wrapper
## refuses every write except /api/run*). Tokens are never printed.

const HARD_TIMEOUT_S := 140.0   # soft: abort the drive, clean up (abandon), quit 1
const KILL_AT_S := 150.0        # hard quit(1)
const MAX_NODES := 6
const STUCK_LIMIT := 150

var _tree: SceneTree
var _failed := false
var _aborted := false
var _fail_code := ""
var _blocked: Array[String] = []
var _began := false
var _combat_won := false
var _reward_taken := false
var _nodes_entered := 0
var _t0 := 0
var _last_combat: CombatEngine = null
var _tokens_before := ""


func _step(name: String, ok: bool, detail: String = "") -> void:
	if not ok:
		_failed = true
	print("[%s] %s%s" % ["OK  " if ok else "FAIL", name, (" - " + detail) if detail != "" else ""])


func _ready() -> void:
	_tree = get_tree()
	_t0 = Time.get_ticks_msec()
	await _tree.process_frame
	reparent(_tree.root)
	_tree.current_scene = null
	if OS.get_environment("AXIE_TEST_NO_NET") == "1":
		_step("env", false, "AXIE_TEST_NO_NET=1 is set, this tool needs the network")
		_quit()
		return
	_tree.create_timer(HARD_TIMEOUT_S).timeout.connect(func() -> void:
		_aborted = true
		_step("timeout", false, "%d s soft limit hit, aborting" % int(HARD_TIMEOUT_S)))
	_tree.create_timer(KILL_AT_S).timeout.connect(func() -> void:
		print("[FAIL] timeout - %d s hard limit, quitting" % int(KILL_AT_S))
		_tree.quit(1))
	CombatView.disable_juice_for_tests = true
	RunState.epoch_failed.connect(func(code: String) -> void: _fail_code = code)
	print("live_smoke: server=%s rules=%s" % [AccountService.server_url(), ActionLog.RULES_VERSION])
	if await _boot_session():
		if await _begin():
			await _drive()
	await _cleanup()
	_quit()


func _quit() -> void:
	var rotated: bool = String(DeviceTokens.load_tokens().get("refresh", "")) != _tokens_before
	if rotated:
		print("note: refresh token rotated (the wrapper writes it back to the desktop app if untouched)")
	if not _blocked.is_empty():
		print("note: refused %d write request(s): %s" % [_blocked.size(), str(_blocked.slice(0, 5))])
	print("LIVE SMOKE %s (%.1f s)" % ["FAIL" if _failed else "PASS", (Time.get_ticks_msec() - _t0) / 1000.0])
	_tree.quit(1 if _failed else 0)


# ---------------------------------------------------------------- plumbing

func _frames(n: int) -> void:
	for i in n:
		await _tree.process_frame


## Writes other than /api/run* never leave this process (a smoke run must not touch the player's cloud save).
func _guarded(method: String, path: String, body: String, done: Callable) -> void:
	if method != "GET" and not path.begins_with("/api/run"):
		_blocked.append("%s %s" % [method, path])
		done.call(0, "")
		return
	AccountService._dt.request(method, path, body, done)


func _http(method: String, path: String) -> Array:
	var box := {"done": false, "code": 0, "text": ""}
	AccountService.transport.call(method, path, "", func(code: int, text: String) -> void:
		box["done"] = true
		box["code"] = code
		box["text"] = text)
	var t := Time.get_ticks_msec()
	while not box["done"] and Time.get_ticks_msec() - t < 15000:
		await _tree.process_frame
	return [int(box["code"]), String(box["text"])]


# ---------------------------------------------------------------- 1. session

func _boot_session() -> bool:
	AccountService._ensure_dt()
	var tokens := DeviceTokens.load_tokens()
	_tokens_before = String(tokens.get("refresh", ""))
	if _tokens_before == "":
		_step("session", false, "no usable device tokens in user dir (missing, or encrypted for another machine)")
		return false
	AccountService._dt.tokens = tokens
	AccountService.ask = func(kind: String, _info: Dictionary, done: Callable) -> void:
		done.call("skip" if kind == "move" else "cloud")   # never pick "local": that would upload
	AccountService.toast = func(code: String) -> void: print("  (toast: %s)" % code)
	AccountService.start(_guarded)
	SaveStore.on_changed = Callable()
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < 25000 and not _aborted:
		await _frames(5)
		var st: int = AccountService.status
		if st == AccountService.Status.SAVED:
			_step("session", true, "signed in, /api/me + /api/save ok, Bearer tokens from device_tokens.dat")
			return true
		if st == AccountService.Status.EXPIRED or st == AccountService.Status.OFFLINE \
				or (st == AccountService.Status.GUEST and Time.get_ticks_msec() - t > 3000):
			break
	_step("session", false, "status=%d (0 guest,1 checking,2 saved,4 offline,5 expired) - sign in again in the desktop app" % AccountService.status)
	return false


# ---------------------------------------------------------------- 2. Begin (real RunSetup)

func _begin() -> bool:
	var setup: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	_tree.root.add_child(setup)
	_tree.current_scene = setup
	await _frames(3)
	var why := setup.begin_block_reason()
	if why != "":
		_step("begin", false, "Begin blocked in RunSetup: " + why)
		return false
	var r: Dictionary = await setup.begin()
	if not bool(r.get("ok", false)):
		var code := String(r.get("code", "?"))
		var extra := ""
		if code == "rejected" or code == "server":   # RemoteEpochSource folds run_open into "rejected"
			var o := await _http("GET", "/api/run/open")
			var j: Variant = JSON.parse_string(o[1]) if String(o[1]) != "" else null
			if o[0] == 200 and typeof(j) == TYPE_DICTIONARY and (j as Dictionary).has("run_id"):
				code = "run_open"
				extra = " (stuck server run %s..., not ours: left untouched)" % String((j as Dictionary)["run_id"]).substr(0, 8)
		_step("begin", false, "code=%s%s" % [code, extra])
		return false
	_began = true
	var sess := RunState.run_session()
	_step("begin", RunState.epoch != null and RunState.epoch.is_remote(),
		"run %s... kind=%s mode=%s A%d ws=%s remote=%s" % [sess.run_id.substr(0, 8), RunState.run_kind,
		RunState.mode, RunState.ascension, sess.state, str(RunState.epoch != null and RunState.epoch.is_remote())])
	return true


# ---------------------------------------------------------------- 3. drive the real scenes

func _drive() -> void:
	var last_sig := ""
	var same := 0
	while not _aborted and not _failed:
		await _frames(2)
		if RunState.phase == RunState.RunPhase.WON or RunState.phase == RunState.RunPhase.LOST:
			_step("drive", false, "run ended (phase %d) before the smoke path finished" % RunState.phase)
			return
		var scene := _tree.current_scene
		if scene == null or not is_instance_valid(scene) or not scene.is_node_ready():
			continue
		var sig := "%s|%d|%s|%d" % [scene.name, RunState.phase, RunState.current_node_id, RunState.pending_rewards.size()]
		same = same + 1 if sig == last_sig else 0
		last_sig = sig
		if same > STUCK_LIMIT:
			_step("drive", false, "stuck at %s (last server code %s)" % [sig, _fail_code])
			return
		if scene.get_node_or_null("NetNotice") != null or _fail_code != "":
			_step("server", false, "request refused, code=%s (scene %s, phase %d)" % [_fail_code, scene.name, RunState.phase])
			return
		if scene.has_method("_on_end_turn_pressed"):
			await _play_fight(scene)
		elif scene.has_method("_on_node_pressed"):
			if await _map_step(scene):
				return
		else:
			_step("drive", false, "unexpected scene %s" % scene.name)
			return


## True when the smoke path is complete (second node entered).
func _map_step(ctrl: Node) -> bool:
	match RunState.phase:
		RunState.RunPhase.MAP:
			if _reward_taken and _nodes_entered >= 1 and _combat_won:
				pass
			elif _nodes_entered >= MAX_NODES:
				_step("drive", false, "no combat won within %d nodes" % MAX_NODES)
				return true
			var ids: Array = ctrl.call("_reachable_now_ids")
			if ids.is_empty():
				_step("node press", false, "map has no reachable node")
				return true
			var graph := RunMapGraph.from_data(RunState.map_graph)
			var nt := String(graph.find_node(String(ids[0])).node_type)
			await ctrl.call("_on_node_pressed", ids[0])
			if _fail_code != "":
				_step("node press %d (%s)" % [_nodes_entered + 1, nt], false, "code=" + _fail_code)
				return true
			_nodes_entered += 1
			var entered := RunState.phase != RunState.RunPhase.MAP
			_step("node press %d (%s)" % [_nodes_entered, nt], entered, "phase=%d node=%s" % [RunState.phase, RunState.current_node_id])
			if _combat_won and _reward_taken:
				return true   # the "one more node" is in; abandon next
		RunState.RunPhase.EVENT:
			await ctrl.call("_on_event_choice", 0)
			ctrl.call("_finish_node")
		RunState.RunPhase.SHOP:
			ctrl.call("_finish_node")
		RunState.RunPhase.TREASURE, RunState.RunPhase.REWARD:
			if RunState.pending_rewards.is_empty():
				ctrl.call("_maybe_show_pending_reward")
			else:
				if _combat_won and not _reward_taken:
					_step("reward offered", true, "%d cards (reward epoch answered)" % RunState.pending_rewards.size())
				ctrl.call("_on_reward_chosen", RunState.pending_rewards[0])
				if _combat_won and not _reward_taken:
					_reward_taken = true
					_step("reward taken", true)
		RunState.RunPhase.PACT:
			var view := ctrl.find_child("PactView", true, false)
			if view != null:
				view.emit_signal("picked", 0, "")
				if RunState.phase == RunState.RunPhase.PACT:
					view.emit_signal("skipped")
			if RunState.phase == RunState.RunPhase.PACT:
				RunState.take_pact(0)
				ctrl.call("_after_pact")
	return false


func _play_fight(view: Node) -> void:
	var combat: CombatEngine = view.get("_combat") as CombatEngine
	if combat == null:
		return
	_last_combat = combat
	var rolls := 0
	while is_instance_valid(view) and not (combat.won or combat.lost) and rolls < 200 and not _aborted:
		rolls += 1
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
				break
		if combat.won or combat.lost:
			break
		await view.call("_on_end_turn_pressed")
		if _fail_code != "" or (is_instance_valid(view) and view.get_node_or_null("NetNotice") != null):
			return
	if combat.lost:
		_step("combat", false, "party lost the fight (the bot is unskilled; rerun or pick another team)")
		return
	if combat.won and not _combat_won and not _aborted:
		_combat_won = true
		_step("combat won", true, "%d turns, end_turn epochs answered by the server" % rolls)
	await _frames(4)


func _wait_anim(view: Node) -> void:
	var g := 0
	while is_instance_valid(view) and bool(view.get("_is_animating")) and g < 300:
		await _tree.process_frame
		g += 1


# ---------------------------------------------------------------- 4. leave nothing open

func _cleanup() -> void:
	if not _began:
		return
	var sess := RunState.run_session()
	var rid := sess.run_id
	var box := {"done": false, "ok": false}
	sess.abandon(func(ok: bool) -> void:
		box["done"] = true
		box["ok"] = ok)
	var t := Time.get_ticks_msec()
	while not box["done"] and Time.get_ticks_msec() - t < 12000:
		await _tree.process_frame
	_step("abandon", bool(box["ok"]), "POST /api/run/%s.../abandon" % rid.substr(0, 8) if bool(box["ok"]) \
		else "POST /api/run/%s.../abandon did not answer 200" % rid.substr(0, 8))
	var o := await _http("GET", "/api/run/open")
	var j: Variant = JSON.parse_string(o[1]) if String(o[1]) != "" else null
	var open_left: bool = o[0] == 200 and typeof(j) == TYPE_DICTIONARY and (j as Dictionary).has("run_id")
	_step("no open run left", o[0] == 200 and not open_left, "GET /api/run/open -> %d%s" % [o[0], " (still open!)" if open_left else ""])
	RunState.clear_saved_run()
	RunState.reset()
