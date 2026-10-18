extends Node
## Manual visual QA for UI-03 14 (in-run menu). Run non-headless via tools/shot.sh.
var _EVIDENCE_DIR := QaPaths.evidence_dir()
var _guard := SaveGuard.new()


func _shot(tag: String, name: String) -> void:
	for i in 8:
		await get_tree().process_frame
	var path := "%s/ui3-runmenu-%s-%s.png" % [_EVIDENCE_DIR, name, tag]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui3_runmenu_capture: saved %s" % path)


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	var tag := "%dx%d" % [int(DisplayServer.window_get_size().x), int(DisplayServer.window_get_size().y)]
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(780, team, "short", 0, false)
	RunState.owned_relic_ids.assign(["r_claw", "r_carapace", "r_pierceall", "r_bloodmouth", "r_heart"])
	RunState.shards_this_run = 64
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	for i in 8:
		await get_tree().process_frame
	m.open_run_menu()
	await _shot(tag, "relics")
	var pm := m.find_child("RunPauseMenu", true, false) as RunPauseMenu
	pm.show_side("map")
	await _shot(tag, "map")
	pm.show_side("settings")
	await _shot(tag, "settings")
	(pm.rows["SaveQuit"] as Button).pressed.emit()
	await _shot(tag, "save-quit")
	(pm.find_child("ConfirmKeep", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	(pm.rows["Abandon"] as Button).pressed.emit()
	await _shot(tag, "abandon")
	(pm.find_child("ConfirmKeep", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	MetaState.mission_escrow = {"stake": 25}
	(pm.rows["Abandon"] as Button).pressed.emit()
	await _shot(tag, "abandon-mission")
	_guard.restore()
	get_tree().quit(0)
