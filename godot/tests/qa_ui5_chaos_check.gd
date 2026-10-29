extends Node
## QA-only (UI-05 b1 QA, item 2): the Chaos confirm on the real reward screen, driven like a player:
## Take on the Chaos card -> ConfirmBar (Footer hidden) -> Back (Footer back, nothing taken) -> Take -> Take it ->
## the Chaos relic is owned and the node finished. The flows never drew a Chaos card at index 0, so this is checked here.
##   godot/tools/shot.sh res://tests/qa_ui5_chaos_check.tscn 1920x1080     -> QA_CHAOS ok=... lines

const U := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()
var _fails: Array[String] = []


func _ok(c: bool, m: String) -> void:
	print("QA_CHAOS %s %s" % ["PASS" if c else "FAIL", m])
	if not c:
		_fails.append(m)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _ready() -> void:
	_guard.capture()
	UI3Theme.set_scale_override(1.0 if get_window().size.x >= 1600 else 2.0 / 3.0)
	RunState.start_new_run(555001, RunBot.DEFAULT_TEAM, "short", 0, false)
	RunState.pending_rewards.clear()
	RunState.phase = RunState.RunPhase.REWARD
	var rng := Rng.new(77)
	var none: Array[Dictionary] = []
	var chaos := RewardGenerator._make_chaos_reward(rng, RunState.owned_relic_ids, none)
	var hp := RewardGenerator._make_reward("hp", [0, 1], 2, rng, [], RunState.roster, none)
	_ok(not chaos.is_empty(), "a Chaos card could be built")
	RunState.pending_rewards.assign([chaos, hp])
	var key := String(chaos.get("key", ""))
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	await _frames(20)
	_ok(m.find_child("RewardPick", true, false) != null, "reward screen open")
	m.call("_select_reward", 0)
	m.call("_take_selected_reward")
	await _frames(10)
	var bar := m.find_child("ConfirmBar", true, false)
	if bar == null:
		for ch in m.find_children("*", "", true, false):
			if ch.has_signal("confirmed") and ch.has_signal("back_pressed"):
				bar = ch
	_ok(bar != null, "Take on Chaos opens the confirm bar")
	var foot := m.find_child("Footer", true, false) as Control
	_ok(foot != null and not foot.visible, "the Footer is hidden while the bar is up")
	U.save(get_viewport(), "chaos-confirm")
	_ok(not RunState.owned_relic_ids.has(key), "nothing taken yet")
	if bar != null:
		bar.emit_signal("back_pressed")
	await _frames(10)
	_ok(foot != null and foot.visible, "Back puts the Footer back")
	_ok(not RunState.owned_relic_ids.has(key) and RunState.pending_rewards.size() == 2, "Back takes nothing")
	m.call("_take_selected_reward")
	await _frames(10)
	bar = null
	for ch in m.find_children("*", "", true, false):
		if ch.has_signal("confirmed") and ch.has_signal("back_pressed"):
			bar = ch
	_ok(bar != null, "Take again opens the bar again")
	if bar != null:
		bar.emit_signal("confirmed")
	for _i in 180:
		await get_tree().process_frame
		if not bool(m.get("_taking")):
			break
	await _frames(10)
	U.save(get_viewport(), "chaos-after-take")
	_ok(RunState.owned_relic_ids.has(key), "Take it: the Chaos relic %s is owned" % key)
	_ok(RunState.pending_rewards.is_empty(), "the offer is closed")
	print("QA_CHAOS_RESULT %s" % ("PASS" if _fails.is_empty() else "FAIL " + str(_fails)))
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)
