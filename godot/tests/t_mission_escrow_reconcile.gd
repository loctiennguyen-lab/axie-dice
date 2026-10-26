extends Node
## Beta Missions escrow reconcile: the screen asks the server about the last mission BEFORE the stake button is
## usable; a refunded old-rules run says "Old run, stake refunded"; a saved run made under other rules is
## abandoned on the server (which refunds it) instead of leaving the mirror stuck. Fake transport, no network.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _texts(n: Node, out: Array) -> void:
	if n is Label:
		out.append((n as Label).text)
	for c in n.get_children():
		_texts(c, out)


func _ready() -> void:
	print("=== t_mission_escrow_reconcile: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	MetaState.saved_run_probe = func() -> bool: return false
	MetaState.runs = 8
	MetaState.runs_with_battle = 8
	MetaState.shard_pool = 5000
	MetaState.starter_shard_locked = 0
	MetaState.set_mission_unlocks(["N1"], false)
	MissionEscrowSync.take_applied()
	var held: Array = []   # held replies: the screen must stay blocked until they are released
	var board := {"open": null, "settled": []}
	var log: Array = []
	MissionEscrowSync.transport_override = func(method: String, path: String, _b: String, done: Callable) -> void:
		log.append(method + " " + path)
		if path == "/api/missions/escrow" and not held.is_empty():
			held.append(func() -> void: done.call(200, JSON.stringify(board)))
			return
		if path == "/api/missions/unlocks":
			done.call(200, JSON.stringify({"tiers": {"N1": {"unlocked": true, "wins": 1, "needs": 0}, "N2": {"unlocked": true, "wins": 0, "needs": 1}}}))
			return
		done.call(200, JSON.stringify(board) if method == "GET" else "{}")
	MetaState.mission_escrow = {"tier": "N1", "mission_id": "ms_a", "stake": 300, "payout": 1080, "stone": 4, "t": 1, "run_id": "ra"}
	board.clear()   # in place: the transport lambda captured the variable by value
	board.merge({"open": null, "settled": [{"run_id": "ra", "state": "refunded", "payout": 300}]}, true)
	held.append(null)   # switch the hold on (first entry is a marker)
	ProjectSettings.set_setting("axie/epoch_source", "remote")   # the screen only asks the server with remote dice
	var s: MissionsScreen = load("res://scenes/missions/MissionsScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	add_child(s)
	await get_tree().process_frame
	_ok(s.block_reason("N1") == "Checking your last mission...", "stake blocked while the server check is in flight: " + s.block_reason("N1"))
	_ok(not MetaState.mission_escrow.is_empty(), "mirror still open before the answer")
	var p0 := MetaState.shard_pool
	var rel: Callable = held[1]
	held.clear()
	rel.call()
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(MetaState.mission_escrow.is_empty() and MetaState.shard_pool == p0 + 300, "refund from the server applied (+300)")
	_ok(log.has("GET /api/missions/unlocks") and log.find("GET /api/missions/escrow") < log.find("GET /api/missions/unlocks"), "unlocks asked after the escrow check")
	_ok(MetaState.mission_unlock_cache == ["N1", "N2"], "unlock cache refreshed from the server")
	_ok(s.block_reason("N1") == "", "stake allowed once the check is done")
	var txt: Array = []
	_texts(s, txt)
	_ok("\n".join(txt).find("Old run, stake refunded") >= 0, "banner says: Old run, stake refunded")
	s.queue_free()

	# saved run under other rules + server still has it open: abandon on the server, then read the refund
	ProjectSettings.set_setting("axie/epoch_source", "remote")
	MetaState.mission_escrow = {"tier": "N2", "mission_id": "ms_b", "stake": 500, "payout": 2325, "stone": 8, "t": 1, "run_id": "rb"}
	SaveStore.write_text(RunState.SAVE_PATH, JSON.stringify({"version": RunState.SAVE_VERSION, "rules_version": "old-rules", "run": {"run_id": "rb"}}))
	_ok(String(RunState.saved_run_status().get("reason", "")) == "rules", "fixture: save has other rules")
	var phase := [0]
	log.clear()
	MissionEscrowSync.transport_override = func(method: String, path: String, _b: String, done: Callable) -> void:
		log.append(method + " " + path)
		if method == "POST" and path == "/api/run/rb/abandon":
			phase[0] = 1
			done.call(200, "{}")
		elif path == "/api/missions/escrow":
			if phase[0] == 0:
				done.call(200, JSON.stringify({"open": {"run_id": "rb", "tier": "N2", "stake": 500}, "settled": []}))
			else:
				done.call(200, JSON.stringify({"open": null, "settled": [{"run_id": "rb", "state": "refunded", "payout": 500}]}))
		else:
			done.call(404, "")
	p0 = MetaState.shard_pool
	_ok(RunState.discard_unresumable_run(), "old-rules save discarded")
	await get_tree().process_frame
	_ok(log.has("POST /api/run/rb/abandon"), "abandoned on the server: " + str(log))
	_ok(MetaState.mission_escrow.is_empty() and MetaState.shard_pool == p0 + 500, "stake refunded, mirror closed")
	_ok(String(MissionEscrowSync.take_applied().get("state", "")) == "refunded", "applied settlement recorded as refunded")
	# same situation but the save is a CURRENT-rules run lost some other way: never abandoned by us
	SaveStore.erase(RunState.SAVE_PATH)
	MetaState.mission_escrow = {"tier": "N2", "mission_id": "ms_c", "stake": 500, "payout": 2325, "stone": 8, "t": 1, "run_id": "rc"}
	log.clear()
	phase[0] = 0
	MissionEscrowSync.settle_dead_run_mirror()
	_ok(not log.has("POST /api/run/rb/abandon") and log.filter(func(l): return l.begins_with("POST")).is_empty(), "no abandon without the old-rules save")
	ProjectSettings.set_setting("axie/epoch_source", "local")
	MissionEscrowSync.transport_override = Callable()
	MetaState.mission_escrow = {}
	MetaState.saved_run_probe = Callable()
	_guard.restore()
	if _fail.is_empty():
		print("t_mission_escrow_reconcile: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_mission_escrow_reconcile: FAIL")
		get_tree().quit(1)
