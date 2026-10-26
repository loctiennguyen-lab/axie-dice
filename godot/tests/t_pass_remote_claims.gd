extends Node
## Remote wallet: Pass level / XP come from the server snapshot, no local XP, claims go to POST /api/econ/claim
## (pass, pass_weekly, pass_post30), server refusals show as plain text, local wallet keeps the old behaviour.
## Fake server, no network.
const _Econ := preload("res://scripts/meta/economy_db.gd")
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


func _snap() -> Dictionary:
	var d: Dictionary = srv.duplicate(true)
	return d


func _ready() -> void:
	_guard.capture()
	MetaState.reload_from_store()
	var cfg: Dictionary = _Econ.get_table("pass_v2")
	var season := String(cfg.get("season_id", "s1"))
	srv = {"shard": 100, "stone": 0, "ticket": 0, "unlocks": [], "owned": [], "pity": {}, "opens": 0, "buy_day": "", "buy_count": 0, "reset_id": "",
		"pass": {"season": season, "xp": 1300, "level": PassV2.level_for_xp(1300), "claimed": [],
			"weekly": {"week": "2026-10-26", "runs": 5, "wins": 0, "boss": 0, "claimed": []}, "post30": {"pending": 0, "claimed": 0}}}
	var net := func(_m: String, path: String, body: String, done: Callable) -> void:
		if path == "/api/econ":
			done.call(200, JSON.stringify(_snap())); return
		var b: Dictionary = JSON.parse_string(body)
		_log.append(b)
		var fail := func(code: String) -> void:
			var d := _snap(); d["ok"] = false; d["code"] = code
			done.call(409, JSON.stringify(d))
		var ok := func(res: Dictionary) -> void:
			var d := _snap(); d["ok"] = true; d["result"] = res
			done.call(200, JSON.stringify(d))
		var p: Dictionary = srv["pass"]
		match String(b["kind"]):
			"pass":
				var lv := int(b["level"])
				if lv > int(p["level"]):
					fail.call("not_reached"); return
				if not (p["claimed"] as Array).has(lv):
					(p["claimed"] as Array).append(lv)
					srv["shard"] = int(srv["shard"]) + 10
				ok.call({"shards": 10})
			"pass_weekly":
				if String(b["task"]) != "play_runs":
					fail.call("not_done"); return
				var wk: Dictionary = p["weekly"]
				if not (wk["claimed"] as Array).has("play_runs"):
					(wk["claimed"] as Array).append("play_runs")
					p["xp"] = int(p["xp"]) + 500
					p["level"] = PassV2.level_for_xp(int(p["xp"]))
				ok.call({"xp": 500})
			"pass_post30":
				var pp: Dictionary = p["post30"]
				if int(pp["pending"]) <= 0:
					fail.call("nothing_to_claim"); return
				srv["shard"] = int(srv["shard"]) + 50 * int(pp["pending"])
				pp["claimed"] = int(pp["claimed"]) + int(pp["pending"]); pp["pending"] = 0
				ok.call({"shards": 50})
			_:
				fail.call("bad_request")
	var e := RemoteEcon.new(net)
	MetaState.use_remote_econ(e)
	e.refresh()
	var ps := MetaState.pass_state()
	_check(int(ps["xp"]) == 1300 and int(ps["level"]) == int(srv["pass"]["level"]), "refresh: Pass xp/level = server's")
	_check(MetaState.pass_add_run_xp(900) == 0 and int(MetaState.pass_season["xp"]) == 1300, "no local run XP while remote")
	MetaState.record_run_outcome({"mode": "short", "ascension": 0, "ranked": false, "reached_boss": true, "kind": "normal", "aid_used": 0, "mission_id": ""}, true)
	var wkn: Dictionary = (MetaState.pass_season.get("weekly", {}) as Dictionary).get("2026-10-26", {})
	_check(int(wkn.get("runs", 0)) == 5, "no local weekly progress while remote (server's 5 stays)")

	var view: Node = (load("res://scenes/pass/Pass.tscn") as PackedScene).instantiate()
	view.set("no_scene_change", true)
	view.set("use_account", false)
	add_child(view)
	# level claim
	var lv: int = int(srv["pass"]["level"])
	view.call("claim_level", 1)
	_check(_log.size() == 1 and _log[0]["kind"] == "pass" and int(_log[0]["level"]) == 1, "claim_level sends pass {level}")
	_check((MetaState.pass_season["claimed_free"] as Array).has(1) and MetaState.shard_pool == 110, "level 1 claimed, Shard from server")
	view.call("claim_level", lv + 5)
	_check(String(view.get("last_result")) == "Not reached yet", "not_reached shown as text: " + String(view.get("last_result")))
	_check(not (MetaState.pass_season["claimed_free"] as Array).has(lv + 5), "refused level not marked claimed")
	# claim all
	_log.clear()
	view.call("claim_all")
	var want := PassV2.claimable_levels(MetaState).size()
	_check(want == 0 and _log.size() == lv - 1, "claim_all sent one claim per unclaimed level (%d)" % _log.size())
	# weekly
	view.call("claim_weekly", "win_runs")
	_check(String(view.get("last_result")) == "Task not finished", "weekly refusal text")
	view.call("claim_weekly", "play_runs")
	_check(int(MetaState.pass_season["xp"]) == 1800, "weekly: XP from server after claim")
	_check(((MetaState.pass_season["weekly"] as Dictionary)["2026-10-26"]["claimed"] as Array).has("play_runs"), "weekly marked claimed from server")
	# post30
	view.call("claim_loop")
	_check(String(view.get("last_result")) == "Nothing to claim", "post30 refusal text")
	srv["pass"]["post30"]["pending"] = 2
	var sh := MetaState.shard_pool
	view.call("claim_loop")
	_check(MetaState.shard_pool == sh + 100 and String(view.get("last_result")) == "+50 Shard", "post30 pays what the server says")
	# out_of_season text
	_check(view.call("remote_msg", "out_of_season") == "The season is not running", "out_of_season text")
	view.queue_free()

	# local wallet: old behaviour
	MetaState.use_remote_econ(null)
	_log.clear()
	var v2: Node = (load("res://scenes/pass/Pass.tscn") as PackedScene).instantiate()
	v2.set("no_scene_change", true)
	v2.set("use_account", false)
	add_child(v2)
	MetaState.pass_season = PassV2.new_state(season)
	MetaState.pass_season["xp"] = 600
	var r: Dictionary = v2.call("claim_level", 1)
	_check(_log.is_empty() and bool(r.get("ok", false)), "local wallet: claim_level is local, no request")
	_check(MetaState.pass_add_run_xp(100) > 0 or not PassV2.season_active(MetaState.today_utc()), "local wallet: run XP still counts")
	v2.queue_free()
	_guard.restore()
	print("t_pass_remote_claims: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
