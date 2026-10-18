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
	var scene := _open(6)
	await _shot(tag, "cards-a6")
	var view := scene.find_child("PactView", true, false) as PactView
	if view != null:
		await get_tree().process_frame
		view.select(1)
		view.accept_button.pressed.emit()
		await _shot(tag, "confirm")
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
