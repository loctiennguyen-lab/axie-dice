extends Node
## BUG-0008: with the economy remote, the gates (newcomer, depth stage, runs count, Daily tries) come from the
## server's GET /api/econ `gates`, not from this device's save.
var _fails := 0
var _guard := SaveGuard.new()


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _setup() -> RunSetup:
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.state = "normal"
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.daily_info_hook = func(cb: Callable) -> void: cb.call(false, {"code": "offline"})
	add_child(s)
	await get_tree().process_frame
	return s


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	MetaState.reload_from_store()
	MetaState.runs_with_battle = 1
	MetaState.runs_completed = 0
	var srv := {"shard": 500, "stone": 0, "ticket": 3, "unlocks": [], "owned": [], "pity": {}, "opens": 0, "buy_day": "", "buy_count": 0, "reset_id": "",
		"gates": {"runs_with_battle": 5, "newcomer": false, "depth_stage": 3, "daily": {"used": 1, "max": 3, "resets_at": 0}}}
	var e := RemoteEcon.new(func(_m: String, _p: String, _b: String, done: Callable) -> void: done.call(200, JSON.stringify(srv)))
	_check(MetaState.is_newcomer() and MetaState.depth_stage() == 1, "local only: newcomer, stage 1")
	MetaState.use_remote_econ(e)
	_check(MetaState.is_newcomer() and MetaState.gate_runs_with_battle() == 1, "remote but no snapshot yet: local numbers")
	e.refresh()
	_check(not MetaState.is_newcomer(), "server says not a newcomer")
	_check(MetaState.depth_stage() == 3 and MetaState.gate_runs_with_battle() == 5, "server stage 3, 5 runs")
	_check(MetaState.server_daily() == {"used": 1, "max": 3}, "server Daily tries")
	_check(MetaState.runs_with_battle == 1, "local save untouched")

	var s: RunSetup = await _setup()
	_check(s.kind_block_reason("ranked") == "", "Run Setup: Ranked open")
	_check(s.kind_block_reason("daily") == "" and s._kind_sub("daily") == "2 of 3 left", "Run Setup: Daily shows server tries (%s)" % s._kind_sub("daily"))
	s.queue_free()

	srv["gates"] = {"runs_with_battle": 2, "newcomer": true, "depth_stage": 1, "daily": {"used": 0, "max": 3}}
	e.refresh()
	var s2: RunSetup = await _setup()
	_check(s2.kind_block_reason("ranked") == "Opens after 5 runs · 2 of 5", "Run Setup: locked text uses server count (%s)" % s2.kind_block_reason("ranked"))
	s2.queue_free()

	# max case: a 5th run finished on this device, server snapshot (2 runs, stage 1) not refetched yet
	MetaState.runs_with_battle = 5
	MetaState.runs_completed = 3
	_check(not MetaState.is_newcomer() and MetaState.gate_runs_with_battle() == 5, "local ahead of server: max wins, not a newcomer")
	_check(MetaState.depth_stage() == 3, "local stage 3 beats server stage 1")
	MetaState.runs_with_battle = 1
	MetaState.runs_completed = 0
	_check(MetaState.is_newcomer() and MetaState.gate_runs_with_battle() == 2 and MetaState.depth_stage() == 1, "server ahead: server wins")

	MetaState.reload_from_store()
	_check(MetaState.server_gates.is_empty(), "reload_from_store clears the gates")
	MetaState.use_remote_econ(null)
	_guard.restore()
	print("t_server_gates: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
