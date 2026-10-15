extends Node
## LIVE SMOKE: proves a real online run works against the PRODUCTION Worker (axie/server_url) before a build
## goes to a human. Real DesktopTransport (Bearer), real RunSession/RemoteEpochSource over a real WebSocket,
## real scenes (RunSetup -> RunMap <-> Combat). NOT a test: it must NOT run with AXIE_TEST_NO_NET.
##
## Run it through godot/tools/live_smoke.sh (own user dir + session copy + lock + kill timer).
##
## Steps (one line each, OK/FAIL + server code): session, preflight (no open run), begin, node press, combat won,
## reward, second node, gates, abandon (real endpoint), no open run left. Exit 0 only if every step passed.
## Exit 2 = preflight found an open run on the account: it is NOT ours, the tool leaves it alone (never calls begin).
##
## Never touch the player's own run: preflight GETs /api/run/open BEFORE Begin. Because preflight proved nothing
## was open, whatever is open at exit is ours, so cleanup always abandons it (even if Begin failed half way, on a
## soft timeout, and on the hard quit). A lost fight is retried once with a fresh run (costs one more RUNS_PER_DAY).
##
## `-- --cleanup-only`: only the open -> abandon check (live_smoke.sh runs it as a second pass when the first
## pass died or was killed after preflight). Works with AXIE_TEST_NO_NET=1 (then it just reports it cannot reach the server).
##
## `-- --full` (live_smoke.sh --full): three extra phases on top of the default run, each prints OK/FAIL/SKIP lines.
##   resume  - mid-run (the default run, after the gates): release() the RunSession, drop the scene, go through the
##             game's own Continue path (RunState.load_run from run_save; the game must reconnect the session itself,
##             the tool never calls open_existing/attach), enter one more node, check the epoch tape grew.
##   retry   - during the first end_turn of a fight the session is flipped to "closed" for that one request, so the
##             epoch fails with "offline" exactly once. Expects NetNotice with RETRY, presses it, expects the turn to
##             finish with a server-answered epoch. (end_turn travels over the WebSocket, which the HTTP wrapper
##             cannot intercept, hence the flip; no game code is touched.)
##   daily   - after the run above is abandoned: GET /api/run/daily, begin kind=daily, enter one node, abandon, tries
##             used must be +1. COSTS ONE OF THE 3 DAILY TRIES (a warning line is printed first). SKIP at 0 left.
## Default run is unchanged. Full run budget: soft limit 245 s, hard 255 s, live_smoke.sh kills at 280 s.
##
## Safety: cloud save uploads are impossible here (SaveStore.on_changed cleared, and the transport wrapper
## refuses every write except /api/run*). Tokens are never printed.

const HARD_TIMEOUT_S := 140.0   # soft: abort the drive, clean up (abandon), quit 1
const KILL_AT_S := 150.0        # hard quit(1), after a short cleanup
const FULL_HARD_TIMEOUT_S := 245.0   # same two limits for --full (live_smoke.sh kills at 280 s)
const FULL_KILL_AT_S := 255.0
const HARD_CLEANUP_MS := 8000   # budget for the cleanup that runs inside the hard quit
const MAX_ATTEMPTS := 2         # a lost fight is retried once (fresh run)
const PREFLIGHT_MARKER := "user://live_smoke_preflight_ok"   # tells live_smoke.sh a cleanup-only pass is safe
const MAX_NODES := 6
const STUCK_LIMIT := 150

var _tree: SceneTree
var _failed := false
var _aborted := false
var _fail_code := ""
var _blocked: Array[String] = []
var _began := false
var _cleanup_only := false
var _full := false
var _soft_s := HARD_TIMEOUT_S
var _kill_s := KILL_AT_S
var _retry_done := false
var _preflight_ok := false
var _cleaning := false
var _fight_lost := false
var _exit_code := 0
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


func _skip(name: String, detail: String = "") -> void:
	print("[SKIP] %s%s" % [name, (" - " + detail) if detail != "" else ""])


func _ready() -> void:
	_tree = get_tree()
	_t0 = Time.get_ticks_msec()
	await _tree.process_frame
	reparent(_tree.root)
	_tree.current_scene = null
	_cleanup_only = "--cleanup-only" in OS.get_cmdline_user_args() or "--cleanup-only" in OS.get_cmdline_args()
	if not _cleanup_only and OS.get_environment("AXIE_TEST_NO_NET") == "1":
		_step("env", false, "AXIE_TEST_NO_NET=1 is set, this tool needs the network")
		_quit()
		return
	_full = not _cleanup_only and ("--full" in OS.get_cmdline_user_args() or "--full" in OS.get_cmdline_args())
	if _full:
		_soft_s = FULL_HARD_TIMEOUT_S
		_kill_s = FULL_KILL_AT_S
	_tree.create_timer(_soft_s).timeout.connect(func() -> void:
		_aborted = true
		_step("timeout", false, "%d s soft limit hit, aborting" % int(_soft_s)))
	_tree.create_timer(_kill_s).timeout.connect(_hard_quit)
	_tree.create_timer(_kill_s + 15.0).timeout.connect(func() -> void:
		print("[FAIL] timeout - cleanup itself did not finish, quitting")
		_tree.quit(1))
	CombatView.disable_juice_for_tests = true
	RunState.epoch_failed.connect(func(code: String) -> void: _fail_code = code)
	print("live_smoke: server=%s rules=%s%s" % [AccountService.server_url(), ActionLog.RULES_VERSION,
		" (cleanup-only)" if _cleanup_only else (" (full: resume + retry + daily)" if _full else "")])
	if await _boot_session():
		if _cleanup_only:
			pass   # the cleanup below is the whole job
		elif await _preflight():
			for attempt in MAX_ATTEMPTS:
				_reset_attempt()
				if not await _begin():
					break
				await _drive()
				if not _fight_lost or _failed or _aborted:
					break
				if attempt + 1 >= MAX_ATTEMPTS:
					_step("combat", false, "party lost the fight in %d runs (the bot is unskilled; pick another team)" % MAX_ATTEMPTS)
					break
				print("  (fight lost: abandoning this run and retrying once with a fresh run)")
				await _cleanup()
				await _discard_scenes()
			if not _failed and not _aborted:
				_gates()
			if _full:
				await _phase_resume()
				if not _retry_done:
					_skip("offline retry", "no end_turn was pressed in any fight of this run")
			await _cleanup()
			if _full:
				await _discard_scenes()
				if _failed:
					_skip("daily", "an earlier step failed; not spending one of the 3 daily tries")
				else:
					await _phase_daily()
	await _cleanup()
	_quit()


## Hard limit: clean up first (own short budget), then quit(1). Never leaves our run open.
func _hard_quit() -> void:
	print("[FAIL] timeout - %d s hard limit, cleaning up then quitting" % int(_kill_s))
	_failed = true
	_aborted = true
	await _cleanup(HARD_CLEANUP_MS)
	_tree.quit(1)


func _reset_attempt() -> void:
	_began = false
	_combat_won = false
	_reward_taken = false
	_nodes_entered = 0
	_fight_lost = false
	_fail_code = ""


## Frees whatever scene the previous attempt left behind so the next Begin starts clean.
func _discard_scenes() -> void:
	var cur := _tree.current_scene
	if cur != null and is_instance_valid(cur):
		cur.queue_free()
	_tree.current_scene = null
	await _frames(3)


func _quit() -> void:
	var rotated: bool = _tokens_before != "" and String(DeviceTokens.load_tokens().get("refresh", "")) != _tokens_before
	if rotated:
		print("note: refresh token rotated (the wrapper writes it back to the desktop app if untouched)")
	if not _blocked.is_empty():
		print("note: refused %d write request(s): %s" % [_blocked.size(), str(_blocked.slice(0, 5))])
	print("LIVE SMOKE %s (%.1f s)" % ["FAIL" if _failed else "PASS", (Time.get_ticks_msec() - _t0) / 1000.0])
	_tree.quit(_exit_code if _exit_code != 0 else (1 if _failed else 0))


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
	AccountService._dt.request(method, path, body, func(code: int, text: String) -> void:
		if code != 200 and code != 204:
			var err := ""
			var j: Variant = JSON.parse_string(text) if text != "" else null
			if typeof(j) == TYPE_DICTIONARY and (j as Dictionary).has("error"):
				err = " error=" + String((j as Dictionary)["error"])
			print("  (http %s %s -> %d%s)" % [method, path.get_slice("?", 0), code, err])
		done.call(code, text))


func _http(method: String, path: String, timeout_ms: int = 15000) -> Array:
	if not AccountService.transport.is_valid():
		return [0, ""]
	var box := {"done": false, "code": 0, "text": ""}
	AccountService.transport.call(method, path, "", func(code: int, text: String) -> void:
		box["done"] = true
		box["code"] = code
		box["text"] = text)
	var t := Time.get_ticks_msec()
	while not box["done"] and Time.get_ticks_msec() - t < timeout_ms:
		await _tree.process_frame
	return [int(box["code"]), String(box["text"])]


## GET /api/run/open -> {code:int, run_id:String ("" = none open)}.
func _open_run(timeout_ms: int = 15000) -> Dictionary:
	var o := await _http("GET", "/api/run/open", timeout_ms)
	var j: Variant = JSON.parse_string(o[1]) if String(o[1]) != "" else null
	var rid := ""
	if o[0] == 200 and typeof(j) == TYPE_DICTIONARY and (j as Dictionary).has("run_id"):
		rid = String((j as Dictionary)["run_id"])
	return {"code": o[0], "run_id": rid}


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


# ---------------------------------------------------------------- 1b. preflight: never touch the player's own run

## True only when the account has NO open run. An open run is the player's: report, exit 2, do not call Begin
## and do not clean up (cleanup is gated on _preflight_ok).
func _preflight() -> bool:
	var o := await _open_run()
	if o["code"] != 200:
		_step("preflight", false, "cannot read GET /api/run/open (http %d), not starting" % o["code"])
		return false
	if String(o["run_id"]) != "":
		print("[FAIL] preflight - account has an open run, not touching it")
		_failed = true
		_exit_code = 2
		return false
	_preflight_ok = true
	var f := FileAccess.open(PREFLIGHT_MARKER, FileAccess.WRITE)
	if f != null:
		f.store_string("1")
		f.close()
	_step("preflight", true, "no open run on the account; anything open from here on is ours")
	return true


# ---------------------------------------------------------------- 2. Begin (real RunSetup)

func _begin(kind: String = "normal") -> bool:
	var setup: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	_tree.root.add_child(setup)
	_tree.current_scene = setup
	await _frames(3)
	if kind != "normal":
		var tw := Time.get_ticks_msec()
		while setup.daily_tries.is_empty() and Time.get_ticks_msec() - tw < 10000 and not _aborted:
			await _tree.process_frame
		if not setup.select_kind(kind):
			_step("begin", false, "kind %s not selectable in RunSetup: %s" % [kind, setup.kind_block_reason(kind)])
			return false
	var why := setup.begin_block_reason()
	if why != "":
		_step("begin", false, "Begin blocked in RunSetup: " + why)
		return false
	var r: Dictionary = await setup.begin()
	if not bool(r.get("ok", false)):
		var code := String(r.get("code", "?"))
		var extra := ""
		if code == "rejected" or code == "server":   # RemoteEpochSource folds run_open into "rejected"
			var o := await _open_run()
			if String(o["run_id"]) != "":
				code = "run_open"
				# Preflight proved nothing was open, so this run came from our own Begin (e.g. the create reply
				# got lost). Cleanup abandons it.
				extra = " (run %s... is open; created by our Begin, cleanup will abandon it)" % String(o["run_id"]).substr(0, 8)
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
		if _fight_lost:
			return
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
		if _full and not _retry_done:
			await _end_turn_with_fault(view, combat)
		else:
			await view.call("_on_end_turn_pressed")
		if _fail_code != "" or (is_instance_valid(view) and view.get_node_or_null("NetNotice") != null):
			return
	if combat.lost:
		_fight_lost = true   # _ready retries once with a fresh run, then fails
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


# ---------------------------------------------------------------- 4. gates (run still open, before abandon)

func _gates() -> void:
	var epochs := 0
	var remote := RunState.epoch != null and RunState.epoch.is_remote()
	if RunState.epoch is RemoteEpochSource:
		epochs = (RunState.epoch as RemoteEpochSource).tape().size()
	var ws := RunState.run_session().state
	_step("gate combat won", _combat_won)
	_step("gate reward taken", _reward_taken)
	_step("gate nodes entered >= 2", _nodes_entered >= 2, "entered %d" % _nodes_entered)
	_step("gate epoch source still remote", remote)
	_step("gate session ready", ws == "ready", "state=%s" % ws)
	_step("gate server-answered epochs > 0", epochs > 0, "%d epochs on the tape" % epochs)


# ---------------------------------------------------------------- 5. leave nothing open

## Always runs. Gated only on "preflight proved no open run" (or --cleanup-only, where live_smoke.sh checked the
## marker): then anything open on the server is ours. Abandons it and checks again.
func _cleanup(budget_ms: int = 30000) -> void:
	if _cleaning:   # another cleanup (e.g. the hard quit) is in flight: wait for it, bounded
		var w := Time.get_ticks_msec()
		while _cleaning and Time.get_ticks_msec() - w < budget_ms:
			await _tree.process_frame
		return
	if not (_preflight_ok or _cleanup_only):
		return   # never proved the account was clean: whatever is open might be the player's
	_cleaning = true
	var deadline := Time.get_ticks_msec() + budget_ms
	if _began:
		RunState.run_session().release()   # drop our socket, the server run is handled below
	var o := await _open_run(clampi(deadline - Time.get_ticks_msec(), 1000, 15000))
	if o["code"] != 200:
		_step("cleanup", false, "cannot reach server: GET /api/run/open -> %d (a run of ours may still be open)" % o["code"])
	elif String(o["run_id"]) == "":
		_step("no open run left", true, "GET /api/run/open -> 200, none open")
	else:
		var rid := String(o["run_id"])
		var a := await _http("POST", "/api/run/%s/abandon" % rid, clampi(deadline - Time.get_ticks_msec(), 1000, 12000))
		_step("abandon", a[0] == 200, "POST /api/run/%s.../abandon -> %d" % [rid.substr(0, 8), a[0]])
		var o2 := await _open_run(clampi(deadline - Time.get_ticks_msec(), 1000, 15000))
		var open_left: bool = o2["code"] != 200 or String(o2["run_id"]) != ""
		_step("no open run left", not open_left, "GET /api/run/open -> %d%s" % [o2["code"], " (still open or unreadable!)" if open_left else ""])
	if _began:
		RunState.clear_saved_run()
		RunState.reset()
		_began = false
	_cleaning = false


# ---------------------------------------------------------------- --full: shared helpers

func _tape_size() -> int:
	return (RunState.epoch as RemoteEpochSource).tape().size() if RunState.epoch is RemoteEpochSource else 0


## Waits for `cond` (a Callable returning bool) up to timeout_ms; false on timeout or abort.
func _wait_until(cond: Callable, timeout_ms: int) -> bool:
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < timeout_ms and not _aborted:
		if cond.call():
			return true
		await _tree.process_frame
	return bool(cond.call())


## GET /api/run/daily through RunSession.daily_info -> {ok, used, max, code}.
func _daily_info() -> Dictionary:
	var box := {"done": false, "ok": false, "d": {}}
	RunState.run_session().daily_info(func(ok: bool, d: Dictionary) -> void:
		box["ok"] = ok
		box["d"] = d
		box["done"] = true)
	await _wait_until(func() -> bool: return bool(box["done"]), 15000)
	var d: Dictionary = box["d"]
	return {"ok": bool(box["ok"]), "used": int(d.get("used", 0)), "max": int(d.get("max", 3)), "code": String(d.get("code", "timeout"))}


# ---------------------------------------------------------------- --full: offline -> RETRY

## Presses END TURN once with a one-shot failure: the RunSession is flipped to "closed" for that single request, so
## RunSession.submit() settles it "offline" (end_turn travels over the WebSocket, which the HTTP wrapper cannot
## intercept). Expects NetNotice + RETRY, presses RETRY, expects the turn to finish with a server-answered epoch.
func _end_turn_with_fault(view: Node, combat: CombatEngine) -> void:
	_retry_done = true
	var sess := RunState.run_session()
	var prev := sess.state
	if prev != "ready" or not (RunState.epoch is RemoteEpochSource):
		_step("offline retry", false, "cannot inject: session state=%s" % prev)
		return
	var tape_before := _tape_size()
	var turn_before := combat.turn
	print("  (offline retry: failing the next end_turn request once)")
	sess.state = "closed"
	await view.call("_on_end_turn_pressed")
	sess.state = prev   # one-shot: the request already settled, the socket was never touched
	var notice: Node = view.get_node_or_null("NetNotice") if is_instance_valid(view) else null
	var retry_btn: Button = null
	if notice != null:
		retry_btn = notice.find_child("RetryButton", true, false) as Button
	_fail_code = ""
	if retry_btn == null:
		_step("offline retry", false, "no NetNotice with a RETRY button after the failed end_turn (notice=%s)" % str(notice != null))
		return
	_step("offline notice", true, "NetNotice shown with RETRY")
	retry_btn.pressed.emit()
	var ok := await _wait_until(func() -> bool:
		return _tape_size() > tape_before and (combat.turn > turn_before or combat.won or combat.lost), 25000)
	if is_instance_valid(view):
		await _wait_anim(view)
	var gone: bool = not is_instance_valid(view) or view.get_node_or_null("NetNotice") == null
	_step("offline retry", ok and gone, "RETRY -> turn %d -> %d, tape %d -> %d" % [turn_before, combat.turn, tape_before, _tape_size()])


# ---------------------------------------------------------------- --full: resume after quit

func _saved_tape_size() -> int:
	var parsed: Variant = JSON.parse_string(SaveStore.read_text(RunState.SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return -1
	var run: Variant = (parsed as Dictionary).get("run", {})
	if typeof(run) != TYPE_DICTIONARY:
		return -1
	return ((run as Dictionary).get("epoch_tape", []) as Array).size()


## Mid-run quit and Continue, using ONLY the game's own path (RunState.load_run + the resumed scene). The tool does
## not attach the session itself, so this fails until the game reconnects a resumed remote run on its own.
func _phase_resume() -> void:
	if _failed or _aborted or not _began:
		_skip("resume", "no healthy open run (earlier failure)")
		return
	var sess := RunState.run_session()
	var rid := sess.run_id
	await _frames(10)   # let a pending scene change and its autosave land
	var live_tape := _tape_size()
	var st := RunState.saved_run_status()
	if not bool(st["resumable"]):
		_step("resume", false, "no resumable run_save (exists=%s reason=%s)" % [str(st["exists"]), st["reason"]])
		return
	var saved_tape := _saved_tape_size()
	if saved_tape != live_tape:
		print("  (note: run_save holds %d epochs, the live run %d)" % [saved_tape, live_tape])
	sess.release()
	await _discard_scenes()
	if not RunState.load_run() or not (RunState.epoch is RemoteEpochSource):
		_step("resume", false, "RunState.load_run() failed or did not restore a remote epoch source")
		return
	LandNav.run_started()
	var path := "res://scenes/combat/Combat.tscn" if not RunState.resume_combat.is_empty() else "res://scenes/run_map/RunMap.tscn"
	var scene: Node = load(path).instantiate()
	_tree.root.add_child(scene)
	_tree.current_scene = scene
	# Only the game's own Continue path from here: the tool does NOT call open_existing()/attach().
	var ready := await _wait_until(func() -> bool: return sess.state == "ready" and sess.run_id == rid, 15000)
	_step("resume reconnect (game's Continue path)", ready, "session state=%s run_id match=%s, tape restored %d epochs" % [sess.state, str(sess.run_id == rid), _tape_size()])
	if not ready:
		return
	_fight_lost = false
	_fail_code = ""
	var nodes_before := _nodes_entered
	var tape_before := _tape_size()
	await _drive()   # flags from the default run are set, so the map step presses exactly one more node
	if _fight_lost:
		_step("resume", false, "fight lost after resume")
		return
	var grew := _tape_size() > tape_before
	_step("resume: one more node", not _failed and not _aborted and _nodes_entered > nodes_before and grew,
		"nodes %d -> %d, tape %d -> %d, ws=%s" % [nodes_before, _nodes_entered, tape_before, _tape_size(), sess.state])


# ---------------------------------------------------------------- --full: Daily

func _phase_daily() -> void:
	if _aborted:
		_skip("daily", "aborted by the time limit")
		return
	var o := await _open_run()
	if o["code"] != 200 or String(o["run_id"]) != "":
		_step("daily", false, "account not clean before Daily (open run or unreadable: http %d)" % o["code"])
		return
	var before := await _daily_info()
	if not bool(before["ok"]):
		_step("daily tries", false, "GET /api/run/daily failed: %s" % before["code"])
		return
	if int(before["used"]) >= int(before["max"]):
		_skip("daily", "0 tries left today (%d of %d used)" % [before["used"], before["max"]])
		return
	print("WARNING: the Daily phase spends 1 of %d Daily tries today (%d used so far); abandoning does not give it back" % [before["max"], before["used"]])
	_step("daily tries", true, "%d of %d used before" % [before["used"], before["max"]])
	_reset_attempt()
	if not await _begin("daily"):
		return
	_step("daily kind", RunState.run_kind == "daily", "run_kind=%s" % RunState.run_kind)
	var tape_before := _tape_size()
	var found := await _wait_until(func() -> bool:
		var c := _tree.current_scene
		return c != null and is_instance_valid(c) and c.is_node_ready() and c.has_method("_on_node_pressed"), 10000)
	if not found:
		_step("daily node", false, "RunMap did not appear after Begin")
	else:
		var ctrl := _tree.current_scene
		var ids: Array = ctrl.call("_reachable_now_ids")
		if ids.is_empty():
			_step("daily node", false, "map has no reachable node")
		else:
			await ctrl.call("_on_node_pressed", ids[0])
			_step("daily node", _fail_code == "" and RunState.phase != RunState.RunPhase.MAP and _tape_size() > tape_before,
				"phase=%d code=%s tape %d -> %d" % [RunState.phase, _fail_code, tape_before, _tape_size()])
	await _cleanup()   # real abandon + "no open run left"
	await _discard_scenes()
	var after := await _daily_info()
	_step("daily tries after abandon", bool(after["ok"]) and int(after["used"]) == int(before["used"]) + 1,
		"used %d -> %d of %d" % [before["used"], after["used"], after["max"]])
