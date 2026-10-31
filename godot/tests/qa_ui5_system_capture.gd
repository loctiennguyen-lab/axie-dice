extends Node
## UI-05 b23 lane S8b: 18-netnotice--* and 18-update--* at 1920 and 1280 (scale pinned). Not headless:
## godot/tools/shot.sh res://tests/qa_ui5_system_capture.tscn  -> production/qa/ui05-b23/s8b/ (or $UI5_SHOT_DIR)
## The screen under the notice is a plain stand-in (green, like the frames' 3D placeholder).
const NOTICES := [["offline", "offline", ""], ["timeout", "timeout", ""], ["busy", "busy", ""], ["rejected", "rejected", ""],
	["server-error", "server_error", ""], ["expired", "expired", ""], ["run-gone", "run_gone", ""], ["action-lead", "offline", "Could not send your turn"]]
var _guard := SaveGuard.new()
var _out := ""


func _ready() -> void:
	_guard.capture()
	_out = OS.get_environment("UI5_SHOT_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b23/s8b").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	await get_tree().process_frame
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		UI3Theme.set_scale_override(1.0 if size.x >= 1920 else 2.0 / 3.0)
		get_window().size = size
		var sfx := "" if size.x >= 1920 else "--1280"
		for n in NOTICES:
			var h := _host()
			NetNotice.show(h, n[1], func() -> void: pass, n[2])
			await _save("18-netnotice--%s%s" % [n[0], sfx], h)
		for u in [["modal-web", 1, "version"], ["modal-desktop", 0, "version"], ["missions", 1, "mission_needs_update"]]:
			UpdateRequired.web_override = u[1]
			var h := _host()
			UpdateRequired.show(h, u[2])
			await _save("18-update--%s%s" % [u[0], sfx], h)
			var b := get_tree().root.get_node_or_null(UpdateRequired.BAR_NAME)
			if b != null:
				b.free()
		for u in [["bar-web", 1], ["bar-desktop", 0]]:
			UpdateRequired.web_override = u[1]
			var h := _host()
			var bar := UpdateRequired.show_bar(get_tree())
			await _save("18-update--%s%s" % [u[0], sfx], h)
			bar.free()
	UpdateRequired.web_override = -1
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)


func _host() -> Control:
	var h := Control.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("3d6b3a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.add_child(bg)
	add_child(h)
	return h


func _save(name: String, h: Node) -> void:
	for _i in 10:
		await get_tree().process_frame
	var img := get_tree().root.get_texture().get_image()
	img.save_png("%s/%s.png" % [_out, name])
	print("QA: saved %s (%dx%d)" % [name, img.get_width(), img.get_height()])
	h.queue_free()
	await get_tree().process_frame
