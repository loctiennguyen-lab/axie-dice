extends Node
## UI-05 b23 lane S14: Settings frames at 1920x1080 and 1280x720 (scale pinned). Not headless:
## godot/tools/shot.sh res://tests/qa_ui5_settings_capture.tscn
## Writes production/qa/ui05-b23/s14/26-settings--<state>[--1280].png (or $UI5_SHOT_DIR).

var _guard := SaveGuard.new()
var _out := ""


func _ready() -> void:
	_guard.capture()
	_out = OS.get_environment("UI5_SHOT_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b23/s14").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	await get_tree().process_frame
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		UI3Theme.set_scale_override(1.0 if size.x >= 1920 else 2.0 / 3.0)
		get_window().size = size
		var suffix := "" if size.x >= 1920 else "--1280"
		RunState.clear_saved_run()
		await _frame("audio", suffix, "")
		await _frame("controls", suffix, "Controls")
		await _frame("key-capture", suffix, "capture")
		await _frame("controls-combat", suffix, "combat")
		RunState.start_new_run(4242, ["plant1", "beast1", "aqua1", "reptile1", "bird1"], "short", 0, false)
		RunState.save_run({})
		await _frame("run", suffix, "Run")
		await _frame("abandon-armed", suffix, "armed")
		RunState.clear_saved_run()
		await _frame("account-out", suffix, "Account")
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)


func _frame(state: String, suffix: String, mode: String) -> void:
	var v: Node = (load("res://scenes/settings/Settings.tscn") as PackedScene).instantiate()
	add_child(v)
	for _i in 8:
		await get_tree().process_frame
	var sc: ScrollContainer = v._scroll
	match mode:
		"Controls", "Run", "Account":
			sc.scroll_vertical = int((v._sections[mode] as Control).global_position.y - v._content.global_position.y)
		"capture":
			sc.scroll_vertical = int((v._sections["Controls"] as Control).global_position.y - v._content.global_position.y)
			(v._key_buttons[&"land_run"] as Button).pressed.emit()
		"combat":
			var b := v._key_buttons[&"combat_end_turn"] as Control
			sc.scroll_vertical = int(b.global_position.y - v._content.global_position.y) - 120
		"armed":
			sc.scroll_vertical = int((v._sections["Run"] as Control).global_position.y - v._content.global_position.y)
			(v.abandon_check as CheckBox).button_pressed = true
	for _i in 10:
		await get_tree().process_frame
	var img := get_tree().root.get_texture().get_image()
	img.save_png("%s/26-settings--%s%s.png" % [_out, state, suffix])
	print("QA: saved 26-settings--%s%s (%dx%d)" % [state, suffix, img.get_width(), img.get_height()])
	v.queue_free()
	await get_tree().process_frame
