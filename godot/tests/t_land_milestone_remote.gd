extends Node
## Remote wallet: a Land milestone claim goes to POST /api/econ/claim {kind:"land", milestone, points}; the items come
## from the server answer (snapshot `owned`), a refusal marks nothing. Fake server, no network.
var _fails := 0
var _guard := SaveGuard.new()
var _log: Array = []
var srv := {}


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _ready() -> void:
	_guard.capture()
	MetaState.reload_from_store()
	srv = {"shard": 0, "stone": 0, "ticket": 0, "unlocks": [], "owned": [], "pity": {}, "opens": 0, "buy_day": "", "buy_count": 0, "reset_id": ""}
	var net := func(_m: String, path: String, body: String, done: Callable) -> void:
		var b: Dictionary = JSON.parse_string(body) if body != "" else {}
		if path != "/api/econ/claim":
			done.call(200, JSON.stringify(srv)); return
		_log.append(b)
		var d: Dictionary = srv.duplicate(true)
		var m := {}
		for x in LandDecor.milestones():
			if String(x["id"]) == String(b["milestone"]):
				m = x
		if m.is_empty() or int(b["points"]) < int(m["points"]):
			d["ok"] = false; d["code"] = "not_reached"
			done.call(409, JSON.stringify(d)); return
		var items: Array = [m["item"]] if m.has("item") else (m.get("items", []) as Array).duplicate()
		for it in items:
			if not (srv["owned"] as Array).has(it):
				(srv["owned"] as Array).append(it)
		d = srv.duplicate(true); d["ok"] = true; d["result"] = {"items": items}
		done.call(200, JSON.stringify(d))
	MetaState.use_remote_econ(RemoteEcon.new(net))
	MetaState.land_decor_placed = []
	MetaState.land_milestones_claimed.clear()
	var errs: Array = []
	LandDecor.claim_remote("m1", func(e: String) -> void: errs.append(e))
	_check(errs[0] != "" and _log.is_empty(), "below the score: refused locally, no request (%s)" % errs[0])
	MetaState.land_decor_owned = {"decor_luna_tree": 2, "decor_terrarium_a4c": 2, "decor_terrarium_f19a": 2}
	for id in ["decor_luna_tree", "decor_terrarium_a4c", "decor_terrarium_f19a"]:
		for i in 2:
			MetaState.land_decor_placed.append({"id": id, "x": float(i), "z": 0.0, "rot": 0})
	var pts := LandDecor.aesthetic(MetaState.land_decor_placed)
	LandDecor.claim_remote("m1", func(e: String) -> void: errs.append(e))
	_check(errs[1] == "" and _log.size() == 1 and _log[0]["milestone"] == "m1" and int(_log[0]["points"]) == pts, "claim sends milestone + points")
	_check(MetaState.land_milestones_claimed.has("m1") and MetaState.cosmetics_owned.has("title:Gardener"), "marked claimed, item from the server answer")
	LandDecor.claim_remote("m1", func(e: String) -> void: errs.append(e))
	_check(errs[2] == "Already claimed." and _log.size() == 1, "second claim: no request")
	# server refusal (client score is higher than it really is): nothing marked
	var m2 := {}
	for x in LandDecor.milestones():
		if int(x["points"]) > 0 and int(x["points"]) <= pts and String(x["id"]) != "m1":
			m2 = x
	if not m2.is_empty():
		var fake_srv_owned := (srv["owned"] as Array).size()
		srv["force_refuse"] = true
	MetaState.use_remote_econ(RemoteEcon.new(func(_m: String, _p: String, _b: String, done: Callable) -> void:
		var d: Dictionary = srv.duplicate(true); d["ok"] = false; d["code"] = "not_reached"
		done.call(409, JSON.stringify(d))))
	LandDecor.claim_remote("m3", func(e: String) -> void: errs.append(e))
	var m3_ok := not MetaState.land_milestones_claimed.has("m3")
	_check(m3_ok, "refused claim marks nothing (%s)" % str(errs.back()))
	MetaState.use_remote_econ(null)
	var stone := MetaState.stone
	MetaState.land_milestones_claimed.clear()
	_check(LandDecor.claim("m1") == "" and MetaState.stone == stone, "local wallet: old local claim still works")
	MetaState.reload_from_store()
	_guard.restore()
	print("t_land_milestone_remote: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
