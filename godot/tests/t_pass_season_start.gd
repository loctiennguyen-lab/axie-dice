extends Node
## QA: Season Pass season 1 start (3/11/2026 UTC), client side, fixed clock (PassView.today_override and the
## `day` argument of PassV2; no real time). Start date comes from pass_v2.json, not from code.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _mk(day: String) -> PassView:
	var s: PassView = load("res://scenes/pass/Pass.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	s.today_override = day
	add_child(s)
	return s


func _banner_text(s: PassView) -> String:
	var out := ""
	for l in s.find_children("*", "Label", true, false):
		out += (l as Label).text + "\n"
	return out


func _ready() -> void:
	print("=== t_pass_season_start: start ===")
	_guard.capture()
	var start := String(PassV2._cfg().get("start_day", ""))
	_ok(start == "2026-11-03", "start_day in data is 2026-11-03, got " + start)

	# --- pure rules around the boundary (day string is a UTC date) ---
	_ok(not PassV2.season_active("2026-11-02"), "2/11 not active")
	_ok(PassV2.season_active("2026-11-03"), "3/11 active")
	_ok(PassV2.season_active("2026-12-28") and not PassV2.season_active("2026-12-29"), "last day 28/12, 29/12 over")
	MetaState.pass_season = PassV2.new_state("s1")
	_ok(PassV2.add_run_xp(MetaState, 370, "2026-11-02") == 0 and int(MetaState.pass_season["xp"]) == 0, "run on 2/11 gives 0 XP")
	_ok(PassV2.add_daily_bonus_xp(MetaState, "2026-11-02") == 0, "daily bonus on 2/11 gives 0")
	_ok(PassV2.claim_weekly(MetaState, "2026-11-02", "play_runs", "2026-11-02").get("reason", "") == "season_over", "weekly claim before start refused")
	PassV2.record_run(MetaState, "2026-11-02", true, true)
	_ok((MetaState.pass_season.get("weekly", {}) as Dictionary).is_empty(), "run on 2/11 not recorded as weekly progress")
	_ok(PassV2.add_run_xp(MetaState, 370, "2026-11-03") == 370, "run on 3/11 gives 370 XP")
	_ok(PassV2.add_run_xp(MetaState, 370, "2026-11-03") == 370 and int(MetaState.pass_season["xp"]) == 740, "2nd run 740 total")
	_ok(int(MetaState.pass_season["level"]) == 1, "level 1 at 500+ XP")
	# weekly week keys: season week 1 = Mon 2/11, week 2 = Mon 9/11
	_ok(PassV2.week_key("2026-11-03") == "2026-11-02", "3/11 belongs to week of Mon 2/11, got " + PassV2.week_key("2026-11-03"))
	_ok(PassV2.week_key("2026-11-08") == "2026-11-02", "8/11 still week 1")
	_ok(PassV2.week_key("2026-11-09") == "2026-11-09", "9/11 starts week 2")
	PassV2.record_run(MetaState, "2026-11-03", true, true)
	var wk: Dictionary = (MetaState.pass_season["weekly"] as Dictionary).get("2026-11-02", {})
	_ok(int(wk.get("runs", 0)) == 1 and int(wk.get("wins", 0)) == 1 and int(wk.get("boss", 0)) == 1, "3/11 run recorded in week 1")
	# a run counted by closing day: a run that started 2/11 and closes 3/11 is recorded with day = 3/11 (RunState end_run)
	# level 1 pays what the table (and the Pass screen) shows
	var sh := MetaState.shard_pool
	var table_pay := int((((PassV2.level_def(1)["free"] as Array)[0]) as Dictionary)["value"])
	var r := PassV2.claim_free(MetaState, 1)
	_ok(bool(r["ok"]) and MetaState.shard_pool == sh + table_pay and table_pay == 300, "lv1 pays 300 = table")

	# --- screen: same build, only the date changes ---
	MetaState.pass_season = PassV2.new_state("s1")
	var b := _mk("2026-11-02")
	await get_tree().process_frame
	_ok(b.season_phase() == "before", "2/11 phase before")
	_ok(b.season_text() == "Season 1 · starts 3 Nov 2026", "before header: " + b.season_text())
	_ok(_banner_text(b).contains("The season has not started") and _banner_text(b).contains("XP starts counting on 3 Nov 2026"), "before banner text")
	_ok(b.week_reset_text() == "resets Mon 9 Nov 2026, 00:00 UTC", "week 1 resets Mon 9 Nov: " + b.week_reset_text())
	b.queue_free()
	await get_tree().process_frame
	var a := _mk("2026-11-03")
	await get_tree().process_frame
	_ok(a.season_phase() == "active", "3/11 phase active")
	_ok(a.season_text() == "Season 1 · ends 29 Dec 2026", "active header: " + a.season_text())
	_ok(not _banner_text(a).contains("has not started"), "no 'not started' banner on 3/11")
	_ok(a.week_reset_text() == "resets Mon 9 Nov 2026, 00:00 UTC", "3/11 week resets Mon 9 Nov: " + a.week_reset_text())
	a.queue_free()
	await get_tree().process_frame
	var w2 := _mk("2026-11-09")
	await get_tree().process_frame
	_ok(w2.week_reset_text() == "resets Mon 16 Nov 2026, 00:00 UTC", "week 2 resets Mon 16 Nov: " + w2.week_reset_text())
	w2.queue_free()

	# --- Result card reads the same table whether before or after the start ---
	for xp in [0, 740]:
		var ps := PassV2.new_state("s1")
		ps["xp"] = xp
		var info := PassSummary.info(ps)
		_ok(int(info["level"]) == PassV2.level_for_xp(xp), "PassSummary level matches PassV2 at xp %d" % xp)
		if xp == 0:
			_ok(PassSummary.line(info).begins_with("0 / 500 XP to level 1") and PassSummary.line(info).contains("300 Shard"), "pre-start Result line: " + PassSummary.line(info))

	_guard.restore()
	if _fail.is_empty():
		print("t_pass_season_start: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_pass_season_start: FAIL")
		get_tree().quit(1)
