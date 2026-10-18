extends Node
## UI-03 18-system capture: confirm / destructive dialog, toasts, network notice (+ reconnecting), skeleton,
## on a Land-coloured backdrop. Not headless: godot/tools/with_lock.sh godot/tools/shot.sh res://tests/qa_ui3_system_capture.tscn 1280x720

var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	var layer := CanvasLayer.new()
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = UI3Theme.color("bg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var root := Control.new()
	root.theme = UI3Theme.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var cols := HBoxContainer.new()
	cols.position = Vector2(40, 40)
	cols.add_theme_constant_override("separation", 40)
	root.add_child(cols)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 24)
	cols.add_child(left)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(700, 0)
	right.add_theme_constant_override("separation", 16)
	cols.add_child(right)
	left.add_child(_dialog("Start a new run?", "Your current run ends now and cannot be continued.",
		[UI3.button("Cancel", &"secondary"), UI3.button("Start new run")]))
	var loss := UI3.plate(&"row")
	loss.add_child(UI3.label("You lose the 300 Shard stake", "LabelDisplay"))
	left.add_child(_dialog("Abandon this mission?", "The mission counts as a loss.",
		[UI3.button("Keep playing", &"secondary"), UI3.button("Abandon", &"danger")], loss))
	right.add_child(UI3.label("TOAST", "LabelKeyHint"))
	right.add_child(UI3.toast("Saved", &"ok"))
	right.add_child(UI3.toast("Still offline", &"error"))
	right.add_child(UI3.label("NETWORK NOTICE", "LabelKeyHint"))
	right.add_child(UI3.net_notice("Connection lost. Check your network and try again.", "Retry", Callable()))
	right.add_child(UI3.net_notice("Reconnecting...", "Retry", Callable(), true))
	right.add_child(UI3.label("SKELETON", "LabelKeyHint"))
	for _i in 3:
		right.add_child(UI3.skeleton_row())
	for _i in 10:
		await get_tree().process_frame
	_save("system")
	# a real modal with its scrim over the lot
	var m := UI3.modal("Quit the run?", "Progress up to now is saved.",
		[UI3.button("Cancel", &"secondary"), UI3.button("Quit", &"danger")], 0)
	root.add_child(m)
	for _i in 10:
		await get_tree().process_frame
	_save("system-scrim")
	_guard.restore()
	get_tree().quit(0)


func _dialog(title: String, body: String, actions: Array, extra: Control = null) -> Control:
	var m := UI3.modal(title, body, actions, 0)
	var dlg := m.find_child("Dialog", true, false) as Control
	if extra != null:
		var row: Node = (actions[0] as Node).get_parent()
		row.get_parent().add_child(extra)
		row.get_parent().move_child(extra, row.get_index())
	dlg.get_parent().remove_child(dlg)
	m.free()
	return dlg


func _save(tag: String) -> void:
	var sz := get_tree().root.get_texture().get_image().get_size()
	var path := QaPaths.evidence_dir() + "/ui3-%s-%dx%d.png" % [tag, sz.x, sz.y]
	get_tree().root.get_texture().get_image().save_png(path)
	print("QA: saved ", path)
