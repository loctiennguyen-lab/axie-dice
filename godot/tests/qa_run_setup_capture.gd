extends Node
## Screenshot of M1 Run Setup -> production/qa/evidence/l1-m1-run-setup.png (run without --headless).
var _guard := SaveGuard.new()
func _ready() -> void:
	_guard.capture()
	MetaState.asc_max = 6
	MetaState.runs = 9
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.no_scene_change = true
	s.ascension = 6
	add_child(s)
	for i in 20:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/l1-m1-run-setup.png"))
	_guard.restore()
	get_tree().quit(0)
