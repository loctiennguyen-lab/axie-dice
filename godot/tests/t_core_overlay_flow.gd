extends Node
## Regression: the chained Core offer must be SHOWN. Run 2+ (rules_on) opens a Run Rule offer, and picking it opens
## Core pick 1 in the same REWARD phase; the map used to close the overlay and show nothing (b1188 smoke).
## Same for a bonus Core offer queued by an event chest / quest / shop / Dim Stone.
## Set AXIE_SHOT=<png path> (non-headless only) to save the first Core offer screen.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame

func _cards(rm: Node) -> Array:
	var out: Array = []
	if rm._overlay_root == null or not rm._overlay_root.visible:
		return out
	for i in 8:
		var c: Node = rm._overlay_root.find_child("RewardCard%d" % i, true, false)
		if c != null:
			out.append(c)
	return out

func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": true})
	await _frames(2)
	_check(RunState.rules_on and RunState._rule_offer_active, "run starts on the Run Rule offer")
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)
	_check(_cards(rm).size() >= 2, "Run Rule overlay is up on entering the map")
	rm._select_reward(1)
	await _frames(2)
	rm._take_selected_reward()
	await _frames(8)
	# The bug: pending Core cards but no overlay.
	_check(RunState._core_offer_active and not RunState.pending_rewards.is_empty(), "Core offer 1 is pending after the rule pick")
	var cards := _cards(rm)
	_check(cards.size() >= 3, "Core offer overlay shows >= 3 Core cards (got %d)" % cards.size())
	var t: Node = rm._overlay_root.find_child("Title", true, false) if rm._overlay_root != null else null
	_check(t != null and (t as Label).text == "Choose a Core", "overlay title says Choose a Core")
	var shot := OS.get_environment("AXIE_SHOT")
	if shot != "" and DisplayServer.get_name() != "headless":
		await _frames(20)
		get_viewport().get_texture().get_image().save_png(shot)
	# Pick Core 1: overlay closes, map is back, the Core panel holds one Core.
	rm._select_reward(0)
	await _frames(2)
	rm._take_selected_reward()
	await get_tree().create_timer(0.6).timeout   # UI-04 core_take (320 ms) plays before the overlay closes
	await _frames(8)
	_check(RunState.pending_rewards.is_empty(), "no pending offer after Core 1")
	_check(not rm._overlay_root.visible and rm._board.visible, "overlay closed, map visible")
	_check(RelicSlots.owned_cores(RunState.owned_relic_ids).size() == 1, "Core panel holds 1 Core")
	var rail := rm.find_child("RelicPlate", true, false)
	var has_cores_label := false
	for l in rail.find_children("*", "Label", true, false):
		if (l as Label).text.begins_with("Cores"):
			has_cores_label = true
		_check(not (l as Label).text.begins_with("Relics"), "rail has no 'Relics' label")
	_check(has_cores_label, "rail label reads 'Cores · N'")
	# Bonus Core offer (event chest / quest / shop / Dim Stone queue) must show too.
	_check(RunState._queue_core_pick(1), "queue a bonus Core pick")
	rm._finish_node()
	await _frames(8)
	_check(not RunState.pending_rewards.is_empty(), "bonus offer opened")
	_check(_cards(rm).size() >= 3, "bonus Core offer overlay is shown with >= 3 cards")
	rm._select_reward(0)
	await _frames(2)
	rm._take_selected_reward()
	await get_tree().create_timer(0.6).timeout
	await _frames(8)
	_check(RunState.pending_rewards.is_empty() and not rm._overlay_root.visible, "bonus offer closes back to the map")
	_check(RelicSlots.owned_cores(RunState.owned_relic_ids).size() == 2, "Core panel holds 2 Cores")
	print("=== t_core_overlay_flow: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	_guard.restore()
	if _fails.is_empty():
		print("t_core_overlay_flow: PASS")
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_core_overlay_flow: FAIL - " + f)
		get_tree().quit(1)
