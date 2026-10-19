extends Node
## Manual visual QA: Land hub (no P/L/C chips) and Settings > Controls. Run non-headless:
## godot/tools/shot.sh res://tests/qa_keys_capture.tscn 1920x1080

var _dir := QaPaths.evidence_dir()
var _guard := SaveGuard.new()


func _shot(label: String) -> void:
	for _i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var sz := get_tree().root.get_visible_rect().size
	var path := "%s/keys_%s_%dx%d.png" % [_dir, label, int(sz.x), int(sz.y)]
	get_tree().root.get_texture().get_image().save_png(path)
	print("saved ", path)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(_dir)
	await get_tree().process_frame
	_guard.capture()
	MetaState.tutorial_seen = true
	LandNav.dry_run = true
	LandHub.qa = {"guest": false, "offline": false}
	var hub := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate()
	add_child(hub)
	await _shot("land")
	hub.queue_free()
	await get_tree().process_frame
	var st := (load("res://scenes/settings/Settings.tscn") as PackedScene).instantiate()
	add_child(st)
	for _i in 4:
		await get_tree().process_frame
	(st.find_child("Index_Controls", true, false) as Button).pressed.emit()
	await _shot("settings_controls")
	(st.find_child("Key_combat_reroll", true, false) as Button).pressed.emit()
	await _shot("settings_capturing")
	st.queue_free()
	_guard.restore()
	get_tree().quit(0)
