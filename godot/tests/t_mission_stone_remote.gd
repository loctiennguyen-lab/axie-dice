extends Node
## Remote wallet: a WON server-settled Mission pays Stone only through POST /api/econ/claim {kind:"mission", run_id};
## nothing is added locally. Local wallet keeps the old local Stone. Fake server, no network.
var _fails := 0
var _guard := SaveGuard.new()
var _log: Array = []


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _ready() -> void:
	_guard.capture()
	MetaState.reload_from_store()
	var srv := {"shard": 0, "stone": 40, "ticket": 0, "unlocks": [], "owned": [], "pity": {}, "opens": 0, "buy_day": "", "buy_count": 0, "reset_id": ""}
	var net := func(_m: String, _path: String, body: String, done: Callable) -> void:
		var b: Dictionary = JSON.parse_string(body) if body != "" else {}
		if b.get("kind", "") == "mission":
			_log.append(b)
			srv["stone"] = int(srv["stone"]) + 25
		var d: Dictionary = srv.duplicate(true); d["ok"] = true; d["result"] = {"stone": 25}
		done.call(200, JSON.stringify(d))
	MetaState.use_remote_econ(RemoteEcon.new(net))
	MetaState.stone = 40
	var rid := "0123456789abcdef0123456789abcdef"
	MetaState.mission_escrow = {"tier": "t1", "mission_id": "ms_x", "stake": 10, "payout": 30, "stone": 25, "run_id": rid, "t": 1}
	var shard := MetaState.shard_pool
	_check(MetaState.apply_mission_settlement({"run_id": rid, "state": "won", "payout": 30}), "settlement applied")
	_check(_log.size() == 1 and _log[0]["run_id"] == rid, "claim mission {run_id} sent")
	_check(MetaState.stone == 65, "Stone = server's number (65), not 40 + local grant")
	_check(MetaState.mission_stone_day.get("n", 0) == 0, "no local Stone day counter")
	# lost: no claim
	MetaState.mission_escrow = {"tier": "t1", "mission_id": "ms_y", "stake": 10, "payout": 30, "stone": 25, "run_id": rid.reverse(), "t": 1}
	MetaState.apply_mission_settlement({"run_id": rid.reverse(), "state": "lost", "payout": 0})
	_check(_log.size() == 1, "lost run: no claim")
	# local settle (no run id) while remote: no local Stone either
	MetaState.mission_escrow = {"tier": "t1", "mission_id": "ms_z", "stake": 10, "payout": 30, "stone": 25, "t": 1}
	var before := MetaState.stone
	MetaState.settle_mission_stake(true, false)
	_check(MetaState.stone == before and _log.size() == 1, "remote wallet: no local Stone without a server run")
	# local wallet: as before
	MetaState.use_remote_econ(null)
	MetaState.mission_escrow = {"tier": "t1", "mission_id": "ms_w", "stake": 10, "payout": 30, "stone": 25, "t": 1}
	MetaState.mission_stone_day = {}
	MetaState.stone = 0
	MetaState.settle_mission_stake(true, false)
	var cap := int(MissionBoard.config().get("stone_day_cap", 0))
	_check(MetaState.stone == mini(25, cap) and _log.size() == 1, "local wallet: local Stone as before (%d)" % MetaState.stone)
	MetaState.reload_from_store()
	_guard.restore()
	print("t_mission_stone_remote: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
