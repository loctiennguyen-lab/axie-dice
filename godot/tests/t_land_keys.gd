extends Node
## Regression: a Land shortcut that navigates away (LandNav -> change_scene) used to touch
## get_viewport() after the hub had left the tree (null) in _unhandled_key_input. The run
## closed on macOS. Here the keys go through the real input path and a real scene change;
## run_tests.sh fails this gate on any SCRIPT ERROR.
## Run: godot --headless --path godot res://tests/t_land_keys.tscn

var _fails: Array[String] = []
var _checks := 0
var _save_guard := SaveGuard.new()


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)
		printerr("FAIL: ", msg)


func _key(k: int) -> void:
	for p in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k as Key
		e.physical_keycode = k as Key
		e.pressed = p
		Input.parse_input_event(e)


func _fresh() -> Node:
	var hub := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(hub)
	get_tree().current_scene = hub
	for i in 5:
		await get_tree().process_frame
	return hub


func _ready() -> void:
	print("=== t_land_keys: start ===")
	_save_guard.capture()
	MetaState.tutorial_seen = true   # in memory only
	LandNav.dry_run = false
	LandHub.qa = {"guest": false, "offline": false}
	await get_tree().process_frame
	var cases := [
		[[KEY_2], "TeamPresets"], [[KEY_L], "LandUpgrade"], [[KEY_C], "Codex"],
		[[KEY_ESCAPE], "Settings"], [[KEY_2, KEY_3], "TeamPresets"],   # two keys in one frame
		[[KEY_L, KEY_L], "LandUpgrade"],
	]
	for c in cases:
		var hub := await _fresh()
		for k in c[0]:
			_key(k)
		for i in 8:
			await get_tree().process_frame
		var cur := get_tree().current_scene
		_check(cur != null and String(cur.scene_file_path).contains(String(c[1])),
			"keys %s must open %s, got %s" % [str(c[0]), c[1], str(cur.scene_file_path if cur else "null")])
		_check(not is_instance_valid(hub) or not hub.is_inside_tree(), "hub leaves the tree after %s" % str(c[0]))
		if cur != null:
			cur.queue_free()
		await get_tree().process_frame
	_save_guard.restore()
	if _fails.is_empty():
		print("=== t_land_keys: PASS (%d checks) ===" % _checks)
		get_tree().quit(0)
	else:
		printerr("=== t_land_keys: FAIL (%d/%d) ===" % [_fails.size(), _checks])
		get_tree().quit(1)
