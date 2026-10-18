extends Node
## Manual visual QA for UI-03 12 (Boss Pact). Run non-headless via tools/shot.sh.
var _EVIDENCE_DIR := QaPaths.evidence_dir()
var _guard := SaveGuard.new()
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _shot(tag: String, name: String) -> void:
	for i in 10:
		await get_tree().process_frame
	var path := "%s/ui3-pact-%s-%s.png" % [_EVIDENCE_DIR, name, tag]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui3_pact_capture: saved %s" % path)


func _open(asc: int) -> Node:
	RunState.start_new_run(777, TEAM, "full", asc, false)
	RunState.current_node_id = "r3_c0"
	RunState.bosses_started = 1
	RunState.apply_combat_result({"won": true, "kind": "boss", "pw": 5, "shards_earned": 0})
	var scene: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(scene)
	return scene


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	var tag := "%dx%d" % [int(DisplayServer.window_get_size().x), int(DisplayServer.window_get_size().y)]
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	var scene := _open(6)
	await _shot(tag, "cards-a6")
	var view := scene.find_child("PactView", true, false) as PactView
	if view != null:
		await get_tree().process_frame
		view.select(1)
		view.accept_button.pressed.emit()
		await _shot(tag, "confirm")
	# paid swap states (R5): price from the real offer; MetaState is non-newcomer so the offer shows
	view.queue_free()
	await get_tree().process_frame
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	var base := AidPurchase.pact_swap_offer()
	print("pact swap offer: ", base)
	var cards: Array = RunState.pact_cards()
	var states := {
		"swap-available": [dict_with(base, true, ""), cards],
		"swap-used": [dict_with(base, false, "cap_type"), cards],
		"swap-no-gem": [dict_with(base, false, "no_gems"), cards],
		"swap-no-other": [dict_with(base, true, ""), cards.map(func(c): var d: Dictionary = (c as Dictionary).duplicate(); d["swap_ok"] = false; return d)],
	}
	for k in states:
		var v2 := PactView.new()
		scene.find_child("ScreenContent", true, false).add_child(v2)
		v2.setup(states[k][1], true, states[k][0])
		await _shot(tag, k)
		v2.queue_free()
		await get_tree().process_frame
	scene.queue_free()
	await get_tree().process_frame
	# full passive slots: Accept leads to the swap sheet (forced at A6 first boss)
	RunState.start_new_run(777, TEAM, "full", 6, false)
	RunState.owned_relic_ids.assign(["r_claw", "r_carapace", "r_pierceall", "r_cleaveall", "r_bloodmouth", "r_gorehook", "r_barbedhide", "r_heart"])
	RunState.current_node_id = "r3_c0"
	RunState.bosses_started = 1
	RunState.apply_combat_result({"won": true, "kind": "boss", "pw": 5, "shards_earned": 0})
	scene = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	view = scene.find_child("PactView", true, false) as PactView
	if view != null:
		await get_tree().process_frame
		view._commit(0)
		await _shot(tag, "sell-forced")
	scene.queue_free()
	_guard.restore()
	get_tree().quit(0)


func dict_with(base: Dictionary, enabled: bool, reason: String) -> Dictionary:
	var d := base.duplicate()
	d["show"] = true
	d["enabled"] = enabled
	d["reason"] = reason
	return d
