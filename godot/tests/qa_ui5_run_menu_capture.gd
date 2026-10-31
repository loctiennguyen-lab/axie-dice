extends Node
## QA-only, UI-05 b23 lane R6: shots of the menu--* frames (map-cores, combat-run, settings, save-quit-confirm,
## abandon). Scale is pinned from the window (1280 -> 2/3). Shots go to ADT_EVIDENCE_DIR.
##   ADT_EVIDENCE_DIR=production/qa/ui05-b23/r6 godot/tools/shot.sh res://tests/qa_ui5_run_menu_capture.tscn 1280x720
var _guard := SaveGuard.new()
var _dir := QaPaths.evidence_dir()


func _shot(frame: String, small: bool) -> void:
	for _i in 10:
		await get_tree().process_frame
	var path := "%s/%s%s.png" % [_dir, frame, "--1280" if small else ""]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui5_run_menu_capture: saved ", path)


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_dir)
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(780, team, "short", 0, false)
	RunState.owned_relic_ids.assign(["c_backline_glow", "c_bastion", "c_blood_sign", "r_ironvow"])
	RunState.shards_this_run = 40
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	for _i in 8:
		await get_tree().process_frame
	m.open_run_menu()
	await _shot("menu--map-cores", small)
	var pm := m.find_child("RunPauseMenu", true, false) as RunPauseMenu
	pm.show_side("settings")
	await _shot("menu--settings", small)
	pm.show_side("map")
	(pm.rows["SaveQuit"] as Button).pressed.emit()
	await _shot("menu--save-quit-confirm", small)
	(pm.find_child("CancelButton", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	MetaState.mission_escrow = {"stake": 60}
	(pm.rows["Abandon"] as Button).pressed.emit()
	await _shot("menu--abandon", small)
	MetaState.mission_escrow = {}
	m.queue_free()
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	var c: Node = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(c)
	for _i in 12:
		await get_tree().process_frame
	c.open_run_menu()
	(c.find_child("RunPauseMenu", true, false) as RunPauseMenu).show_side("map")
	await _shot("menu--combat-run", small)
	_guard.restore()
	get_tree().quit(0)
