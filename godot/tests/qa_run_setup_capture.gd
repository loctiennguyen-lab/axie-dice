extends Node
## Screenshot of M1 Run Setup -> production/qa/evidence/l1-m1-run-setup.png (run without --headless).
var _guard := SaveGuard.new()
func _ready() -> void:
	_guard.capture()
	MetaState.asc_max = 6
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	var _res := "1280x720"
	var _stage := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--res="):
			_res = a.get_slice("=", 1)
		elif a.begins_with("--stage="):
			_stage = int(a.get_slice("=", 1))
	var _w := int(_res.get_slice("x", 0))
	var _h := int(_res.get_slice("x", 1))
	DisplayServer.window_set_size(Vector2i(_w, _h))
	if _stage == 3:
		MetaState.runs_completed = 9
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.no_scene_change = true
	s.ascension = 6
	add_child(s)
	for i in 20:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://../production/qa/evidence/l1-m1-run-setup-%dx%d-s%d.png" % [_w, _h, _stage]))
	_guard.restore()
	get_tree().quit(0)
