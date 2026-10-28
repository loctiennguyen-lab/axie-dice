extends Node
## UI-05 b1 lane B capture (run NOT headless, once per size):
##   godot/tools/shot.sh res://tests/qa_ui5_dice_capture.tscn 1920x1080   (and 1280x720)
## Writes the HTML frame ids to $ADT_EVIDENCE_DIR: 02-combat--set-3, 02-combat--set-4, 02-combat--die-picked, components--dice
## (suffix --1280 at 1280x720). Same states as ui05-combat-screens.html: SET of 3 Horn, SET of 4 Mouth with a Temp Face and a
## Held die outside the SET, a picked die, and every DieCard state plus the SetBanner.
var _guard := SaveGuard.new()
var _out := ""
var _suffix := ""


func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	_out = OS.get_environment("ADT_EVIDENCE_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b1/b").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	for _i in 5:
		await get_tree().process_frame
	# Canvas scale without the screen DPR: lane 0 current_scale() divides by DisplayServer.screen_get_scale(), which is 2 on a
	# Retina Mac, so 1920x1080 would read as 0.5 (reported to the lead). Force the real canvas scale for these shots.
	var win := Vector2(get_window().size)
	UI3Theme.set_scale_override(minf(win.x / 1920.0, win.y / 1080.0))
	_suffix = "--1280" if get_window().size.x <= 1300 else ""
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	var s: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(s)
	for _i in 90:
		await get_tree().process_frame
	s._land_dice_now()
	await _combat_frames(s)
	s.queue_free()
	await get_tree().process_frame
	await _components()
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)


func _face(ft: String, val: int, slot: int) -> Dictionary:
	return {"type": ft, "value": val, "keywords": [], "name": "t", "part": String(V4Ui.SLOT_ORDER[slot])}


func _lay(s: Node, layout: Array) -> void:
	var c: CombatEngine = s._combat
	var units: Array = s._party_dice_units()
	for i in units.size():
		var u: Unit = units[i]
		var row: Array = layout[i]
		u.die[int(row[0])] = _face(String(row[1]), int(row[2]), int(row[0]))
		u.set_roll(int(row[0]), false)
		u.wild_slot = -1
		u.held = false
		u.status.clear()
		u.shield = 0
	c._snap_bo()
	s._rebuild_all()


func _combat_frames(s: Node) -> void:
	var c: CombatEngine = s._combat
	c.depth_stage = 3
	var units: Array = s._party_dice_units()
	# set-3: three Horn attacks 4 / 2 / 3 (×1.3 -> 6 / 3 / 4); the rest on other parts.
	_lay(s, [[1, "dmg", 4], [0, "dmg", 2], [4, "heal", 3], [1, "dmg", 2], [1, "dmg", 3]])
	await _shot("02-combat--set-3")
	# set-4: Mouth ×2.2, die 2 is a Wild Temp Face (counts as Mouth), die 3 Held on Back, outside the SET.
	_lay(s, [[0, "dmg", 2], [0, "dmg", 3], [4, "dmg", 2], [2, "shield", 4], [0, "dmg", 4]])
	(units[2] as Unit).wild_slot = 0
	(units[3] as Unit).held = true
	c._snap_bo()
	s._rebuild_all()
	await _shot("02-combat--set-4")
	# die-picked: no SET, die 1 picked (lifts 10 px, cream ring).
	_lay(s, [[2, "shield", 2], [0, "dmg", 2], [4, "heal", 3], [3, "shield", 4], [5, "dmg", 3]])
	s._selected_die_uid = (units[1] as Unit).uid
	s._rebuild_all()
	await _shot("02-combat--die-picked")
	s._selected_die_uid = -1


## components--dice: every DieCard state on the bg, then the SetBanners.
func _components() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UI3Theme.get_theme()
	get_tree().root.add_child(root)
	var bg := ColorRect.new()
	bg.color = UI3Theme.color("bg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var col := VBoxContainer.new()
	col.position = Vector2(48, 32)
	col.add_theme_constant_override("separation", 28)
	root.add_child(col)
	var tex_mouth := load("res://assets/icons/web/part/mouth_aqua.svg") as Texture2D
	var tex_horn := load("res://assets/icons/web/part/horn_beast.svg") as Texture2D
	var tex_back := load("res://assets/icons/web/part/back_plant.svg") as Texture2D
	var base := {"name": "Olek", "hp": 17, "max_hp": 17, "faces": [{"type": "shield", "value": 2}], "rolled": 0, "alive": true,
		"part_text": "HORN", "part_word": "Horn", "part_tex": tex_horn}
	var atk := {"faces": [{"type": "dmg", "value": 4}]}
	var rows := [
		["DieCard · states", [["default", {}], ["selected", {"selected": true, "name": "Buba", "part_word": "Mouth", "part_tex": tex_mouth}],
			["used", {"spent": true, "name": "Puffy", "faces": [{"type": "heal", "value": 3}]}], ["waiting", {"_dim": true, "name": "Machito"}]]],
		["DieCard · SET and special dice", [["in SET", atk.merged({"set_key": "a", "set_before": 4, "set_after": 6, "set_show": true})],
			["in SET + selected", atk.merged({"set_key": "a", "set_before": 3, "set_after": 4, "set_show": true, "selected": true, "name": "Pomodor"})],
			["second SET colour", atk.merged({"set_key": "b", "set_before": 2, "set_after": 3, "set_show": true, "name": "Machito"})],
			["Temp Face (Wild)", {"faces": [{"type": "dmg", "value": 5}], "set_key": "a", "set_before": 2, "set_after": 5, "set_show": true,
				"wild_text": "MOUTH", "part_text": "MOUTH", "part_word": "Mouth", "part_tex": tex_mouth, "name": "Puffy"}],
			["Held", {"faces": [{"type": "shield", "value": 4}], "held": true, "part_text": "BACK", "part_word": "Back", "part_tex": tex_back, "name": "Machito"}],
			["Overcast", {"faces": [{"type": "dmg", "value": 6}], "overcast": true, "set_key": "a", "set_before": 2, "set_after": 6, "set_show": true,
				"part_text": "MOUTH", "part_word": "Mouth", "part_tex": tex_mouth}]]],
	]
	for r in rows:
		col.add_child(_caption(String(r[0]), true))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 40)
		col.add_child(hb)
		for st in r[1]:
			var cell := VBoxContainer.new()
			cell.add_theme_constant_override("separation", 20)
			hb.add_child(cell)
			var holder := Control.new()
			holder.custom_minimum_size = Vector2(TrayColumn.card_w() + 16, TrayColumn.card_h() + 16)
			cell.add_child(holder)
			var btn := Button.new()
			btn.toggle_mode = true
			holder.add_child(btn)
			btn.position = Vector2(8, 8)
			btn.size = Vector2(TrayColumn.card_w(), TrayColumn.card_h())
			var content := TrayColumn.build(btn)
			var d: Dictionary = base.merged(st[1], true)
			TrayColumn.update(content, d)
			if bool(d.get("_dim", false)):
				btn.modulate.a = 0.4
			cell.add_child(_caption(String(st[0]), false))
	col.add_child(_caption("SetBanner", true))
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 16)
	col.add_child(bh)
	for b in [[1, 3, 130, "a", tex_horn, false], [0, 4, 220, "b", tex_mouth, false], [3, 5, 260, "a", load("res://assets/icons/web/part/tail_aqua.svg"), true]]:
		var sb := SetBanner.new()
		bh.add_child(sb)
		sb.setup(int(b[0]), int(b[1]), int(b[2]), String(b[3]), b[4], bool(b[5]))
	await _shot("components--dice")
	root.queue_free()


func _caption(t: String, head: bool) -> Label:
	var l := UI3.label(t, "LabelDisplay" if head else "")
	l.add_theme_font_size_override("font_size", UI3Theme.size_of("text_title" if head else "text_body"))
	l.add_theme_color_override("font_color", UI3Theme.color("text" if head else "text_muted"))
	return l


func _shot(frame_id: String) -> void:
	for _i in 30:
		await get_tree().process_frame
	var path := "%s/%s%s.png" % [_out, frame_id, _suffix]
	get_tree().root.get_texture().get_image().save_png(path)
	print("QA: saved ", path)
