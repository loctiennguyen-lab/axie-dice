extends Node
## QA (not headless): round-3 frames 06-run-setup--{stage1,stage3,a5,full-locked,newcomer,daily,ranked} at the window size.
##   UI5_SHOT_DIR=.../production/qa/ui05-b23/s3a1 godot/tools/shot.sh res://tests/qa_ui5_run_setup_capture.tscn 1280x720
const Util := preload("res://tests/qa_ui5_util.gd")
const Fx := preload("res://tests/ui5_run_setup_fixture.gd")
var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	for id in Fx.IDS:
		var s := Fx.make(id)
		add_child(s)
		for i in 8:
			await get_tree().process_frame
		Fx.apply_kind(s)
		for i in 8:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		Util.save(get_viewport(), "06-run-setup--" + id + ("--1280" if small else ""))
		s.queue_free()
		await get_tree().process_frame
	_guard.restore()
	get_tree().quit(0)
