extends Node
## RemoteEcon against a fake server (no network): snapshot lands in the MetaState cache, unlock/ticket/open/claim
## go through the server, refusals change nothing, strip_server_fields, reset wipe.
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
	var srv := {"shard": 1000, "stone": 0, "ticket": 2, "unlocks": [], "owned": [], "pity": {}, "opens": 0, "buy_day": "", "buy_count": 0, "reset_id": ""}
	var net := func(_m: String, path: String, body: String, done: Callable) -> void:
		var b: Variant = JSON.parse_string(body) if body != "" else {}
		if path == "/api/econ":
			done.call(200, JSON.stringify(srv))
		elif path == "/api/econ/spend":
			var sku := String(b["sku"])
			if sku.begins_with("unlock:"):
				if int(srv["shard"]) < 300:
					var d: Dictionary = srv.duplicate(); d["ok"] = false; d["code"] = "insufficient"
					done.call(402, JSON.stringify(d)); return
				srv["shard"] = int(srv["shard"]) - 300
				(srv["unlocks"] as Array).append(sku.substr(7))
			done.call(200, JSON.stringify(_with(srv, {"ok": true, "result": {}})))
		elif path == "/api/echobox/open":
			srv["ticket"] = int(srv["ticket"]) - 1
			srv["stone"] = int(srv["stone"]) + 500
			done.call(200, JSON.stringify(_with(srv, {"ok": true, "result": {"kind": "stone", "amount": 500}})))
		else:
			done.call(404, "")
	var e := RemoteEcon.new(net)
	MetaState.use_remote_econ(e)
	e.refresh()
	_check(MetaState.shard_pool == 1000 and int(MetaState.tickets["normal"]) == 2, "refresh fills the cache")
	var got := []
	e.buy_unlock("u_hp", func(r: Dictionary) -> void: got.append(r))
	_check(got[0]["ok"] and MetaState.shard_pool == 700 and MetaState.has_unlock("u_hp"), "unlock bought on the server, cache follows")
	_check(MetaState.buy_unlock("u_x") != "", "local buy_unlock refused while remote")
	srv["shard"] = 10
	e.buy_unlock("u_hp2", func(r: Dictionary) -> void: got.append(r))
	_check(not got[1]["ok"] and got[1]["code"] == "insufficient" and MetaState.shard_pool == 10 and not MetaState.has_unlock("u_hp2"), "refusal: nothing granted, cache = server")
	e.open_box(func(r: Dictionary) -> void: got.append(r))
	_check(got[2]["result"]["amount"] == 500 and MetaState.stone == 500 and int(MetaState.tickets["normal"]) == 1, "open: result from server, balances follow")
	var off := RemoteEcon.new(func(_m: String, _p: String, _b: String, done: Callable) -> void: done.call(0, ""))
	off.buy_tickets(1, func(r: Dictionary) -> void: got.append(r))
	_check(got[3]["code"] == "offline" and not got[3]["net"] and MetaState.shard_pool == 10, "offline: nothing changes")
	var stripped := MetaState.strip_server_fields({"shard_pool": 5, "stone": 1, "runs": 3})
	_check(not stripped.has("shard_pool") and not stripped.has("stone") and stripped["runs"] == 3, "strip_server_fields")
	srv["reset_id"] = "m1"; srv["shard"] = 0; srv["stone"] = 0; srv["unlocks"] = []; srv["ticket"] = 0
	MetaState.runs = 9
	e.refresh()
	_check(MetaState.runs == 0 and MetaState.shard_pool == 0 and MetaState.econ_reset_seen == "m1" and not MetaState.has_unlock("u_hp"), "reset id wipes local state")
	MetaState.use_remote_econ(null)
	_guard.restore()
	print("t_economy_remote_wallet: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)


func _with(a: Dictionary, b: Dictionary) -> Dictionary:
	var d := a.duplicate()
	d.merge(b, true)
	return d
