extends Node
## Run Shard claim that did not get through (offline, run not closed yet) is saved and sent again until the server
## says ok or a permanent no. Fake server, no network.
var _fails := 0
var _guard := SaveGuard.new()


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _ready() -> void:
	_guard.capture()
	MetaState.reload_from_store()
	MetaState.starter_granted = true
	MetaState.pending_run_claims = []
	var mode := ["offline"]
	var sent: Array = []
	var net := func(_m: String, _p: String, body: String, done: Callable) -> void:
		var b: Dictionary = JSON.parse_string(body) if body != "" else {}
		if b.has("run_id"):
			sent.append(b["run_id"])
		match mode[0]:
			"offline": done.call(0, "")
			"not_closed": done.call(409, JSON.stringify({"ok": false, "code": "run_not_closed", "shard": 1, "stone": 0, "ticket": 0}))
			"permanent": done.call(409, JSON.stringify({"ok": false, "code": "run_too_short", "shard": 1, "stone": 0, "ticket": 0}))
			_: done.call(200, JSON.stringify({"ok": true, "result": {}, "shard": 77, "stone": 0, "ticket": 0}))
	MetaState.use_remote_econ(RemoteEcon.new(net))
	var r1 := "a".repeat(32)
	var r2 := "b".repeat(32)
	MetaState.econ_claims_after_run(r1, 30, "normal")
	_check(MetaState.pending_run_claims.size() == 1, "offline: claim stays queued")
	MetaState.reload_from_store()
	_check(MetaState.pending_run_claims.size() == 1 and MetaState.pending_run_claims[0]["run_id"] == r1, "queue survives a restart (SaveStore)")
	mode[0] = "not_closed"
	MetaState.retry_pending_run_claims()
	_check(MetaState.pending_run_claims.size() == 1, "run_not_closed: kept for the next try")
	mode[0] = "ok"
	sent.clear()
	MetaState.retry_pending_run_claims()
	_check(sent.has(r1) and MetaState.pending_run_claims.is_empty() and MetaState.shard_pool == 77, "server ok: sent again, queue empty, balance = server's")
	mode[0] = "permanent"
	MetaState.econ_claims_after_run(r2, 10, "normal")
	_check(MetaState.pending_run_claims.is_empty(), "permanent refusal: dropped")
	MetaState.use_remote_econ(null)
	_check("pending_run_claims" in MetaState.SERVER_FIELDS and not MetaState.strip_server_fields({"pending_run_claims": [1]}).has("pending_run_claims"), "not uploaded in the cloud save")
	MetaState.reload_from_store()
	_guard.restore()
	print("t_run_claim_retry: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
