extends Node
## UI-03 43 tooltip capture (lane C): relic / active / die face, hover and keyboard focus, 1920x1080 + 1280x720.
## Not headless: godot/tools/with_lock.sh godot/tools/shot.sh res://tests/qa_ui3_tooltip_capture.tscn
## Writes production/qa/evidence/ui3-tooltip-<owner>-<hover|focus>-<w>x<h>.png.

var _guard := SaveGuard.new()
var _out := ""


func _ready() -> void:
	_guard.capture()
	_out = OS.get_environment("ADT_EVIDENCE_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
	RunState._grant_relic("a_bloom", "qa")
	RunState._grant_relic("r_amberdie", "qa")
	RunState._grant_relic("r_alphafang", "qa")
	await get_tree().process_frame
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().size = size
		for _i in 5:
			await get_tree().process_frame
		await _run(size)
	_guard.restore()
	get_tree().quit(0)


func _shot(name: String, size: Vector2i) -> void:
	for _i in 12:
		await get_tree().process_frame
	var img := get_tree().root.get_texture().get_image()
	img.save_png("%s/ui3-tooltip-%s-%dx%d.png" % [_out, name, size.x, size.y])
	print("QA: saved ui3-tooltip-%s-%dx%d plate=%s" % [name, size.x, size.y, UI3Tooltip.shown_plate(get_tree()) != null])


func _owner(scene: Node, kind: String) -> Control:
	for n in scene.find_children("*", "Control", true, false):
		if not n.has_meta("ui3_tip") or not (n as Control).is_visible_in_tree():
			continue
		match kind:
			"relic":
				if n is PanelContainer and n.get_parent() is HBoxContainer and not (n is Button) and n.get_parent() == scene._relic_strip:
					return n
			"active":
				if n is Button and n.get_parent() == scene._actives_row:
					return n
			"die":
				if n is Button and n.get_parent() != scene._actives_row:
					return n
	return null


func _run(size: Vector2i) -> void:
	RunState.enter_node("r4_c0", "battle")
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 90:
		await get_tree().process_frame
	scene._land_dice_now()
	for _i in 10:
		await get_tree().process_frame
	for kind in ["relic", "active", "die"]:
		var c := _owner(scene, kind)
		if c == null:
			print("QA: no owner for ", kind)
			continue
		c.grab_focus()
		await _shot("%s-focus" % kind, size)
		c.release_focus()
		await get_tree().process_frame
		var at := c.get_global_rect().get_center()
		get_window().warp_mouse(at) if false else null
		c.mouse_entered.emit()
		await get_tree().create_timer(0.8).timeout
		UI3Tooltip._show(c)
		await _shot("%s-hover" % kind, size)
		UI3Tooltip.hide_for(c)
	scene.queue_free()
	await get_tree().process_frame
