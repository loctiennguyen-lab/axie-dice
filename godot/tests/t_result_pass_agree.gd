extends Node
## QA S2-1 / BUG-0007: the run Result screen and the Pass screen must say the same thing about the Pass
## (name, level, XP into the level, next reward), both from Pass v2. The Result used to read the old BP_TRACK
## ("Lunacia Pass Lv 2, +180 XP, Lv 2 pays 200 shard") while the Pass screen showed Season Pass / 0 of 500.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bird1"]


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _texts(root: Node) -> String:
	var out := ""
	for n in root.find_children("*", "Label", true, false):
		out += (n as Label).text + "\n"
	return out


func _result() -> Node:
	RunState.start_new_run(777002, TEAM, "short", 0, false)
	RunState.set_phase(RunState.RunPhase.WON)
	var v: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(v)
	await get_tree().process_frame
	await get_tree().process_frame
	return v


func _pass() -> PassView:
	var s: PassView = load("res://scenes/pass/Pass.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	s.today_override = "2026-11-10"
	add_child(s)
	await get_tree().process_frame
	return s


func _check_state(xp: int, tag: String) -> void:
	MetaState.pass_season = PassV2.new_state("s1")
	MetaState.pass_season["xp"] = xp
	MetaState.pass_season["level"] = PassV2.level_for_xp(xp)
	var pv := await _pass()
	var info_txt := (pv.find_child("XpInfo", true, false) as Label).text
	var lvl_txt := (pv.find_child("LevelNumber", true, false) as Label).text
	var rv := await _result()
	var card := rv.find_child("PassCard", true, false)
	_ok(card != null, tag + ": Result has no PassCard")
	if card != null:
		var t := _texts(card)
		var line := (rv.find_child("PassXpLine", true, false) as Label).text
		_ok(t.contains(PassSummary.NAME) and not t.contains("Lunacia"), tag + ": Result pass name wrong: " + t)
		_ok(t.contains("Lv " + lvl_txt), tag + ": Result level differs from Pass level " + lvl_txt + ": " + t)
		# Same "x / y XP to level N" text as the Pass screen shows.
		_ok(line.begins_with(info_txt), tag + ": Result line '%s' vs Pass '%s'" % [line, info_txt])
		# Next reward comes from the Pass table's next level (Lv 1 = 300 Shard, Lv 2 = 1 ticket).
		var nxt := PassV2.level_def(PassV2.level_for_xp(xp) + 1)
		if not nxt.is_empty():
			var want := PassView.reward_text((nxt["free"] as Array)[0] as Dictionary)
			_ok(line.contains(want), tag + ": next reward '%s' missing in '%s'" % [want, line])
		_ok(not line.contains("shard") or line.contains("Shard"), tag + ": legacy lowercase shard wording: " + line)
	pv.queue_free()
	rv.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	print("=== t_result_pass_agree: start ===")
	_guard.capture()
	await get_tree().process_frame
	await _check_state(0, "xp0")      # Lv 0 -> Lv 1 pays 300 Shard
	await _check_state(700, "xp700")  # Lv 1, 200 into Lv 2 -> 1 ticket
	await _check_state(3000, "xp3000")
	# Remote economy: the client must not claim an XP number for this run (server counts it).
	_guard.restore()
	print("=== t_result_pass_agree: %d checks, %d failure(s) ===" % [_checks, _fail.size()])
	if _fail.is_empty():
		print("t_result_pass_agree: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fail:
		print("t_result_pass_agree: FAIL — %s" % f)
	get_tree().quit(1)
