extends Node
## Daily screen with the remote economy (Liam 1/11: Claim stayed lit after a claim, week strip stuck at 0 of 4).
## The server snapshot's `daily` block {day, claimed, week, days, weekly_paid} fills MetaState.daily_date / daily_week
## (RemoteEcon.apply_daily); the Claim button turns off while the request is out and after the claim; the weekly bonus
## paid with the 4th claim shows on the card. Fake server, no network.
var _fails := 0
var _guard := SaveGuard.new()
var _log: Array = []
var _held: Array = []   # claim answers waiting: the test releases them, like a slow server
var srv := {}


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _snap() -> Dictionary:
	return srv.duplicate(true)


func _btn(d: Node, n: String) -> Button:
	return d.find_child(n, true, false) as Button


func _ready() -> void:
	_guard.capture()
	MetaState.reload_from_store()
	var today := MetaState.today_utc()
	var wk := PassV2.week_key(today)
	MetaState.daily_date = ""
	MetaState.daily_week = {"week": "", "n": 0, "paid": false}
	srv = {"shard": 100, "stone": 0, "ticket": 0, "unlocks": [], "owned": [], "pity": {}, "opens": 0, "buy_day": "", "buy_count": 0,
		"reset_id": "", "daily": {"day": today, "claimed": false, "week": wk, "days": 3, "weekly_paid": false}}
	var net := func(_m: String, path: String, body: String, done: Callable) -> void:
		if path == "/api/econ":
			done.call(200, JSON.stringify(_snap())); return
		_log.append(JSON.parse_string(body))
		_held.append(func() -> void:
			var dd: Dictionary = srv["daily"]
			var res := {"shards": 60}
			if not bool(dd["claimed"]):
				dd["claimed"] = true
				dd["days"] = int(dd["days"]) + 1
				srv["shard"] = int(srv["shard"]) + 60
				if int(dd["days"]) >= 4 and not bool(dd["weekly_paid"]):
					dd["weekly_paid"] = true
					srv["shard"] = int(srv["shard"]) + 150
					res["weekly"] = {"shards": 150}
			var d := _snap(); d["ok"] = true; d["result"] = res
			done.call(200, JSON.stringify(d)))
	MetaState.use_remote_econ(RemoteEcon.new(net))

	var d: DailyScreen = load("res://scenes/daily/DailyScreen.tscn").instantiate()
	d.use_account = false
	d.state = "normal"
	d.remote_on = true
	d.no_scene_change = true
	d.test_mode = true
	add_child(d)
	await get_tree().process_frame
	_check(MetaState.daily_date == "" and MetaState.weekly_daily_days() == 3, "open: snapshot gives 3 days this week, not claimed")
	_check(not _btn(d, "DailyClaim").disabled, "open: Claim is live")
	_check("3 of 4" in _btn(d, "WeeklyStatus").text, "open: week card says 3 of 4 (%s)" % _btn(d, "WeeklyStatus").text)

	d.claim_daily()
	_check(_btn(d, "DailyClaim").disabled, "request out: Claim is off")
	d.claim_daily()
	_check(_log.size() == 1, "double click sends one request (%d)" % _log.size())
	(_held.pop_front() as Callable).call()
	await get_tree().process_frame
	_check(MetaState.daily_date == today, "after claim: daily_date = server day")
	_check(_btn(d, "DailyClaim").disabled and "Claimed today" in _btn(d, "DailyClaim").text, "after claim: Claim off, says Claimed today (%s)" % _btn(d, "DailyClaim").text)
	_check("weekly bonus paid" in d.daily_result, "4th claim: result says the weekly bonus was paid (%s)" % d.daily_result)
	_check(_btn(d, "WeeklyStatus").text == "Paid this week" and MetaState.weekly_bonus_paid(), "week card: Paid this week")
	_check(MetaState.shard_pool == 310, "wallet = server's (%d)" % MetaState.shard_pool)
	d.queue_free()

	# A new UTC day on the server (or a reset): claimed false for the day we cached -> the cache lets go.
	RemoteEcon.apply_daily({"daily": {"day": today, "claimed": false, "week": wk, "days": 0, "weekly_paid": false}})
	_check(MetaState.daily_date == "" and MetaState.weekly_daily_days() == 0 and not MetaState.weekly_bonus_paid(), "server says not claimed: cache cleared")
	# An older server without the block changes nothing.
	MetaState.daily_date = today
	RemoteEcon.apply_daily({"shard": 1})
	_check(MetaState.daily_date == today, "no daily block: cache untouched")

	MetaState.use_remote_econ(null)
	_guard.restore()
	if _fails == 0:
		print("t_daily_remote_state: PASS")
		get_tree().quit(0)
	else:
		print("t_daily_remote_state: FAIL (%d)" % _fails)
		get_tree().quit(1)
