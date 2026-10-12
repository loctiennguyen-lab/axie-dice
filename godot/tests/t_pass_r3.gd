extends Node
## M4 Season Pass R3: node states, claim once, weekly claim (500 XP, once), after-season claims
## allowed but no XP, premium locked with no purchase, before-season banner.

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


func _ready() -> void:
	print("=== t_pass_r3: start ===")
	_guard.capture()
	MetaState.pass_season = PassV2.new_state("s1")
	MetaState.pass_season["xp"] = 3000      # level 5 (xp_total 2900)
	MetaState.pass_season["level"] = 5
	var s := _mk("2026-11-10")              # Tuesday of season week 2
	await get_tree().process_frame
	_ok(s.season_phase() == "active", "phase active")
	_ok(s.season_text() == "Season 1 · ends 29 Dec 2026", "header text: " + s.season_text())
	_ok(s.level() == 5, "level 5")
	_ok(s.find_children("NodeBtn_*", "Button", true, false).size() == 30, "30 nodes")
	_ok(s.node_state(5) == "claimable" and s.node_state(6) == "next" and s.node_state(9) == "locked", "node states")
	_ok((s.find_child("NodeBtn_6", true, false) as Button).disabled, "next node disabled")
	_ok((s.find_child("NodeBtn_9", true, false) as Button).text == "Reach LV 9", "locked text")
	_ok(s.find_child("PremiumRibbon", true, false) != null and (s.find_child("PremiumRibbon", true, false) as Label).text == "SEASON 2", "premium ribbon")
	_ok(s.find_children("*", "Button", true, false).filter(func(b): return "buy" in (b as Button).text.to_lower()).is_empty(), "no purchase button")
	# claim once
	var shards := MetaState.shard_pool
	var r := s.claim_level(1)
	_ok(bool(r.ok) and MetaState.shard_pool == shards + 300, "lv1 claimed +300 shard")
	_ok(s.node_state(1) == "claimed" and (s.find_child("NodeBtn_1", true, false) as Button).disabled, "lv1 shows claimed")
	var again := s.claim_level(1)
	_ok(not bool(again.ok) and MetaState.shard_pool == shards + 300, "no double claim")
	_ok(not bool(s.claim_level(6).ok), "unreached level refused")
	# claim all
	var n := s.claim_all()
	_ok(n == 4 and PassV2.claimable_levels(MetaState).is_empty(), "claim all took levels 2-5")
	_ok((s.find_child("ClaimAll", true, false) as Button).disabled, "claim all disabled when nothing left")
	# weekly
	var wk := PassV2.week_key("2026-11-10")
	_ok(s.week_reset_text() == "resets Mon 16 Nov 2026, 00:00 UTC", "reset text: " + s.week_reset_text())
	_ok((s.find_child("WeeklyClaim_win_runs", true, false) as Button).disabled, "weekly not done: disabled")
	MetaState.pass_season["weekly"] = {wk: {"runs": 5, "wins": 2, "boss": 0, "claimed": []}}
	s.refresh()
	await get_tree().process_frame
	_ok(not (s.find_child("WeeklyClaim_play_runs", true, false) as Button).disabled, "play 5 claimable")
	_ok((s.find_child("WeeklyClaim_reach_boss", true, false) as Button).disabled, "boss task not done")
	var xp0 := s.xp()
	_ok(bool(s.claim_weekly("play_runs").ok) and s.xp() == xp0 + 500, "weekly +500 XP")
	_ok(not bool(s.claim_weekly("play_runs").ok) and s.xp() == xp0 + 500, "weekly once only")
	_ok(not bool(s.claim_weekly("reach_boss").ok), "unfinished weekly refused")
	# pressing the node button claims (level 5 was taken by claim_all, so use 6 after raising level)
	MetaState.pass_season["xp"] = 3600
	MetaState.pass_season["level"] = 6
	s.refresh()
	await get_tree().process_frame
	var nb := s.find_child("NodeBtn_6", true, false) as Button
	_ok(nb != null and nb.text == "CLAIM" and s.node_state(6) == "claimable", "lv6 claimable button")
	nb.pressed.emit()
	_ok(s.node_state(6) == "claimed", "pressing NodeBtn_6 claims it")
	# post-30 loop through the view
	MetaState.pass_season["xp"] = 200000
	MetaState.pass_season["level"] = 30
	var sh7 := MetaState.shard_pool
	var lp := s.claim_loop()
	_ok(lp > 0 and MetaState.shard_pool == sh7 + lp, "claim_loop pays shards post-30")
	_ok(s.claim_loop() == 0, "claim_loop nothing left")
	s.queue_free()
	# season over: reached rewards still claimable, XP stops, weekly closed
	MetaState.pass_season["xp"] = 6800
	MetaState.pass_season["level"] = 10
	var o := _mk("2027-01-05")
	await get_tree().process_frame
	_ok(o.season_phase() == "over" and o.find_child("Banner", true, false) != null, "over banner")
	_ok(MetaState.pass_add_run_xp(1000) == 0, "no XP after season (real clock is outside season too)")
	var xp1 := o.xp()
	MetaState.pass_season["weekly"] = {PassV2.week_key("2027-01-05"): {"runs": 5, "wins": 2, "boss": 1, "claimed": []}}
	o.refresh()
	_ok((o.find_child("WeeklyClaim_play_runs", true, false) as Button).disabled, "weekly disabled after season")
	_ok(not bool(o.claim_weekly("play_runs").ok) and o.xp() == xp1, "weekly refused after season, no XP")
	_ok((o.find_child("NodeBtn_7", true, false) as Button).text == "CLAIM", "reached level claimable after season")
	_ok((o.find_child("NodeBtn_12", true, false) as Button).text == "Not claimed", "unreached shows Not claimed")
	_ok(bool(o.claim_level(7).ok) and o.xp() == xp1, "claim after season works, XP unchanged")
	o.queue_free()
	# before season banner
	var b := _mk("2026-10-12")
	await get_tree().process_frame
	_ok(b.season_phase() == "before" and b.season_text() == "Season 1 · starts 3 Nov 2026", "before-season text")
	b.queue_free()
	_guard.restore()
	if _fail.is_empty():
		print("t_pass_r3: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_pass_r3: FAIL")
		get_tree().quit(1)
