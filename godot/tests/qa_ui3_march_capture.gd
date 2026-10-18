extends Node
## UI-03 45 victory march capture (lane C). Not headless: godot/tools/with_lock.sh godot/tools/shot.sh res://tests/qa_ui3_march_capture.tscn
## Writes production/qa/evidence/ui3-march-playing-<w>x<h>.png and ui3-march-skipped-<w>x<h>.png.

var _guard := SaveGuard.new()
var _out := ""


func _ready() -> void:
	_guard.capture()
	_out = OS.get_environment("ADT_EVIDENCE_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
	await get_tree().process_frame
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().size = size
		for _i in 5:
			await get_tree().process_frame
		RunState.enter_node("r4_c0", "battle")
		var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(scene)
		for _i in 90:
			await get_tree().process_frame
		scene._land_dice_now()
		scene._play_victory_march()
		await get_tree().create_timer(0.5).timeout
		_shot("playing", size)
		var ui := scene.get_node_or_null("VictoryMarchUI")
		print("QA: ui=", ui != null, " focus=", get_viewport().gui_get_focus_owner())
		var esc := InputEventKey.new()
		esc.keycode = KEY_ESCAPE
		esc.pressed = true
		Input.parse_input_event(esc)
		for _i in 20:
			await get_tree().process_frame
		print("QA: after esc ui=", scene.get_node_or_null("VictoryMarchUI") != null, " running=", scene._exit_running)
		_shot("skipped", size)
		scene.queue_free()
		await get_tree().process_frame
	_guard.restore()
	get_tree().quit(0)


func _shot(state: String, size: Vector2i) -> void:
	var img := get_tree().root.get_texture().get_image()
	img.save_png("%s/ui3-march-%s-%dx%d.png" % [_out, state, size.x, size.y])
	print("QA: saved ui3-march-%s-%dx%d" % [state, size.x, size.y])
