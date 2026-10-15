extends Node
## L1 S (missions online, option A): the client side of the server-held stake. No network: a fake transport
## answers GET /api/missions/escrow and a RunSession with a fake http answers POST /api/run.
## Checks: the create body carries {tier, stake}; the new refusal codes pass through; the local escrow binds to the
## server run_id (and survives a save round trip); the mirror closes from the SERVER's settlement (payout is the
## server's number, not local math), for won / lost / refunded; wrong run_id / no escrow / offline change nothing;
## a remote mission's end_run does NOT settle locally, the reconcile after close does.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


class RemoteStub extends LocalEpochSource:
	func is_remote() -> bool:
		return true


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _open_escrow(run_id: String, stake := 300, payout := 1) -> void:
	MetaState.mission_escrow = {"tier": "N1", "mission_id": "ms_t", "stake": stake, "payout": payout, "stone": 4, "t": 1, "run_id": run_id}


func _ready() -> void:
	print("=== t_mission_escrow_sync: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	MetaState.saved_run_probe = func() -> bool: return false
	MetaState.shard_pool = 1000
	MetaState.stone = 0
	MetaState.mission_stone_day = {"day": "", "n": 0}

	# --- POST /api/run body and refusal codes (RunSession.http fake) ---
	var sent: Array = []
	var session := RunSession.new()
	add_child(session)
	var answer := [403, JSON.stringify({"error": "tier_locked"})]
	session.http = func(_m: String, path: String, body: String, done: Callable) -> void:
		if path == "/api/run":
			sent.append(JSON.parse_string(body))
		done.call(answer[0], answer[1])
	var params := {"mode": "short", "ascension": 3, "kind": "mission", "team_keys": ["plant1"],
		"mission": {"mission_id": "ms_t", "tier": 1, "stake": 300, "rules": []}}
	for code in ["tier_locked", "stake_mismatch", "tier_mismatch"]:
		answer[1] = JSON.stringify({"error": code})
		var src := RemoteEpochSource.new(session)
		var r := src.start_run(params)
		_ok(r.done and not r.ok and r.code == code, "refusal %s passes through (got %s)" % [code, r.code])
	var m: Dictionary = (sent[0] as Dictionary).get("mission", {})
	_ok(String(m.get("tier", "")) == "N1" and int(m.get("stake", 0)) == 300, "create body carries mission {tier N1, stake 300}")
	sent.clear()
	var normal := RemoteEpochSource.new(session)
	normal.start_run({"mode": "short", "ascension": 0, "kind": "normal"})
	_ok(not (sent[0] as Dictionary).has("mission"), "a normal run sends no mission block")
	session.queue_free()

	# --- bind + persistence of run_id ---
	_open_escrow("", 300, 645)
	_ok(not MetaState.bind_mission_run("other", "r1") and String(MetaState.mission_escrow.get("run_id", "")) == "", "bind needs the matching mission_id")
	_ok(MetaState.bind_mission_run("ms_t", "r1") and String(MetaState.mission_escrow["run_id"]) == "r1", "bind stores the server run id")
	_ok(String(MetaState._escrow_from_json(MetaState.mission_escrow).get("run_id", "")) == "r1", "run_id survives the save round trip")

	# --- apply_mission_settlement: server numbers win ---
	_open_escrow("r1", 300, 1)   # local payout deliberately wrong: must not be used
	var p0 := MetaState.shard_pool
	_ok(not MetaState.apply_mission_settlement({"run_id": "zzz", "state": "won", "payout": 645}) and not MetaState.mission_escrow.is_empty(), "another run id changes nothing")
	_ok(MetaState.apply_mission_settlement({"run_id": "r1", "state": "won", "payout": 645}), "won applies")
	_ok(MetaState.mission_escrow.is_empty() and MetaState.shard_pool == p0 + 645, "won pays the SERVER payout (645), not the local number")
	_ok(MetaState.stone == 4, "won gives the tier Stone")
	_ok(not MetaState.apply_mission_settlement({"run_id": "r1", "state": "won", "payout": 645}) and MetaState.shard_pool == p0 + 645, "second apply is a no-op")
	_open_escrow("r2")
	p0 = MetaState.shard_pool
	_ok(MetaState.apply_mission_settlement({"run_id": "r2", "state": "lost", "payout": 0}) and MetaState.shard_pool == p0 and MetaState.stone == 4, "lost: nothing paid, no Stone")
	_open_escrow("r3", 500)
	_ok(MetaState.apply_mission_settlement({"run_id": "r3", "state": "refunded", "payout": 500}) and MetaState.shard_pool == p0 + 500 and MetaState.stone == 4, "refunded: the stake comes back, no Stone")

	# --- reconcile through the fake transport ---
	var board := {}   # mutated in place: lambdas capture the variable by value
	board.merge({"open": null, "settled": []}, true)
	var calls := [0]
	var code := [200]
	MissionEscrowSync.transport_override = func(method: String, path: String, _b: String, done: Callable) -> void:
		calls[0] += 1
		_ok(method == "GET" and path == "/api/missions/escrow", "reconcile asks GET /api/missions/escrow")
		done.call(code[0], JSON.stringify(board) if code[0] == 200 else "")
	var applied := [null]
	var cb := func(a: bool) -> void: applied[0] = a
	MetaState.mission_escrow = {}
	MissionEscrowSync.reconcile(cb, true)
	_ok(calls[0] == 0 and applied[0] == false, "no escrow: no request")
	_open_escrow("r4", 300, 1)
	board.clear()
	board.merge({"open": {"run_id": "r4", "tier": "N1", "stake": 300}, "settled": []}, true)
	MissionEscrowSync.reconcile(cb, true)
	_ok(calls[0] == 1 and applied[0] == false and not MetaState.mission_escrow.is_empty(), "server still has it open: mirror stays open")
	code[0] = 0
	MissionEscrowSync.reconcile(cb, true)
	_ok(applied[0] == false and not MetaState.mission_escrow.is_empty(), "offline: mirror stays open")
	code[0] = 200
	board.clear()
	board.merge({"open": null, "settled": [{"run_id": "old", "state": "lost", "payout": 0}, {"run_id": "r4", "state": "won", "payout": 645}]}, true)
	p0 = MetaState.shard_pool
	MissionEscrowSync.reconcile(cb, true)
	_ok(applied[0] == true and MetaState.mission_escrow.is_empty() and MetaState.shard_pool == p0 + 645, "settled list closes the mirror from the server payout")
	_ok(not MissionEscrowSync.needed(), "needed() is false with the local dice flag")

	# --- end_run with a remote epoch: no local settle, the reconcile after close does it ---
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var mp := {"team_keys": team, "mode": "short", "ascension": 3, "ranked": false, "kind": "mission", "newcomer": false,
		"mission": {"mission_id": "ms_e", "tier": 1, "rules": [], "stake": 300, "m_base": 2.15, "m_scale": 1.0, "m_eff": 2.15}}
	MetaState.mission_escrow = {"tier": "N1", "mission_id": "ms_e", "stake": 300, "payout": 645, "stone": 4, "t": 1, "run_id": "re"}
	RunState.reset()
	RunState.epoch = RemoteStub.new(PackedByteArray(), 5)
	RunState.start_new_run_seeded(5, mp)
	board.clear()
	board.merge({"open": null, "settled": [{"run_id": "re", "state": "lost", "payout": 0}]}, true)
	calls[0] = 0
	p0 = MetaState.shard_pool
	ProjectSettings.set_setting("axie/epoch_source", "remote")
	RunState.end_run(true)   # the client CLAIMS a win; the server says lost: the server wins
	ProjectSettings.set_setting("axie/epoch_source", "local")
	_ok(calls[0] == 1, "end_run asked the server for the settlement once")
	_ok(MetaState.mission_escrow.is_empty() and MetaState.shard_pool < p0 + 645, "remote mission: settled from the server answer (lost), not from the local win")
	# local epoch: the old local settle still works and sends no request
	MetaState.mission_escrow = {"tier": "N1", "mission_id": "ms_l", "stake": 300, "payout": 645, "stone": 4, "t": 1}
	var mp2: Dictionary = mp.duplicate(true)
	(mp2["mission"] as Dictionary)["mission_id"] = "ms_l"
	RunState.reset()
	RunState.epoch = LocalEpochSource.new(PackedByteArray(), 6)
	RunState.start_new_run_seeded(6, mp2)
	calls[0] = 0
	p0 = MetaState.shard_pool
	RunState.end_run(true)
	_ok(calls[0] == 0 and MetaState.mission_escrow.is_empty() and MetaState.shard_pool >= p0 + 645, "local mission: settled locally, no request")

	MissionEscrowSync.transport_override = Callable()
	RunState.reset()
	MetaState.mission_escrow = {}
	MetaState.saved_run_probe = Callable()
	_guard.restore()
	if _fail.is_empty():
		print("t_mission_escrow_sync: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_mission_escrow_sync: FAIL")
		get_tree().quit(1)
