class_name TrayColumn
extends RefCounted
## One party card in the dice tray, UI-03 (screens/02-combat/spec.md): 152 w, UI3 card plate, a
## UI3.DieTile (96 slot, face word under it, "· used" second line), name + HP row, HP bar.
## Status chips (UI3.status_chip / UI3.chip) float above the card. The card is still a Button
## (toggle) so `%DieSlot0`, focus, keys and the tests keep working; the DieTile is click-through.
## The card is bottom-anchored in a fixed 164 px button: "used" is a stamp on the tile, the word stays one line, so the tray top never moves.

const W := 152.0
const H := 164.0
const PAD := 6.0
const TILE_Y := 4.0
const HOLDER_H := 88.0     # DieTile's holder is 100 high for its shadow; 88 + the 6 px gap is enough
const BODY_NORMAL := 164.0
const BODY_USED := 164.0

## Game face type -> UI3 face name.
const _FACE := {"dmg": &"attack", "debuff": &"weaken"}
const _STATUS_ICON := {"poison": "status_poison", "vulnerable": "status_vuln"}


static func ui3_face(game_type: String) -> StringName:
	var f := StringName(_FACE.get(game_type, game_type))
	return f if f in UI3.FACE_TYPES else &"blank"


static func build(btn: Button) -> Dictionary:
	btn.custom_minimum_size = Vector2(W, H)
	btn.clip_contents = false
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(root)
	var body := Control.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(body)
	var plate := UI3.plate(&"card")
	plate.name = "Plate"
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.add_child(plate)
	var name_label := UI3.label("")
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", UI3Theme.color("text"))
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(name_label)
	var hp_label := UI3.label("", "LabelDisplay")
	hp_label.add_theme_font_size_override("font_size", 18)
	hp_label.add_theme_color_override("font_color", UI3Theme.color("text"))
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(hp_label)
	var hp := HPBar.new()
	hp.ui3_look = true
	hp.set_kind(HPBar.Kind.PARTY, 10, 5, 12)
	hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(hp)
	var chips := HBoxContainer.new()
	chips.name = "Chips"
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips.add_theme_constant_override("separation", 4)
	root.add_child(chips)
	var overlay := PanelContainer.new()
	overlay.name = "RerollOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	overlay.theme = UI3Theme.get_theme()
	overlay.theme_type_variation = "PanelCard"
	var oi := TextureRect.new()
	oi.texture = UI3.icon("ui_reroll")
	oi.custom_minimum_size = Vector2(40, 40)
	oi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	oi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	oi.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	oi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	oi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(oi)
	btn.add_child(overlay)
	return {"button": btn, "root": root, "body": body, "plate": plate, "chips": chips,
		"name_label": name_label, "hp": hp, "hp_label": hp_label, "reroll_overlay": overlay, "lifted": false,
		"skin_id": "", "skin_node": null, "tile": null, "tile_key": "", "die": null,
		"die_num": Label.new(), "holder": body, "panel_style": null}


## Paints the card. `d`:
##   name, hp, max_hp, shield, status:Dictionary, incoming, faces:Array[{type, value}],
##   rolled:int (-1 = not rolled), alive, spent, selected, legal_target, skin, tip, status_tip:Callable
static func update(content: Dictionary, d: Dictionary) -> void:
	var btn: Button = content["button"]
	var alive := bool(d.get("alive", true))
	var spent := bool(d.get("spent", false))
	var selected := bool(d.get("selected", false))
	var rolled := int(d.get("rolled", -1))
	var faces: Array = d.get("faces", [])
	var show_face := alive and rolled >= 0 and rolled < faces.size()
	var ftype := &"blank"
	var fval := 0
	if show_face:
		ftype = ui3_face(String((faces[rolled] as Dictionary).get("type", "")))
		fval = int((faces[rolled] as Dictionary).get("value", 0))
	var state: StringName = &"normal"
	if not show_face:
		state = &"disabled"
	elif spent:
		state = &"used"
	elif selected:
		state = &"selected"
	var two_lines := state == &"used"
	var body_h := BODY_USED if two_lines else BODY_NORMAL
	var body: Control = content["body"]
	body.position = Vector2(0, H - body_h)
	body.size = Vector2(W, body_h)

	# Die tile (rebuilt only when what it shows changes).
	var skin := String(d.get("skin", ""))
	var key := "%s|%d|%s|%s|%s" % [ftype, fval, state, skin, "" if show_face else ("KO" if not alive else "-")]
	if key != String(content["tile_key"]):
		content["tile_key"] = key
		var old: Variant = content["tile"]
		if old != null and is_instance_valid(old):
			(old as Node).queue_free()
		var tile := UI3.die_tile(ftype, fval, &"axie", state, 0.0, true)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.focus_mode = Control.FOCUS_NONE
		var holder: Control = tile.get_node("Holder")
		holder.custom_minimum_size.y = HOLDER_H
		tile.position = Vector2((W - 96.0) * 0.5, TILE_Y)
		tile.size = Vector2(96.0, 0)
		body.add_child(tile)
		content["tile"] = tile
		content["die"] = tile.tile
		var col_box: Node = tile.tile.get_child(0)
		var num: Label = col_box.get_child(1)
		if not alive:
			num.text = "KO"
		elif not show_face:
			num.text = "-"
		content["die_num"] = num
		content["skin_id"] = ""
		content["skin_node"] = null
		_apply_skin(content, skin)

	var row_y := TILE_Y + HOLDER_H + 6.0 + 22.0 + 2.0
	var hp_now := int(d.get("hp", 0))
	var hp_max := int(d.get("max_hp", 1))
	var hl: Label = content["hp_label"]
	hl.text = "%d/%d" % [maxi(hp_now, 0), hp_max]
	var hw := hl.get_minimum_size().x + 2.0
	hl.position = Vector2(W - PAD - hw, row_y - 2.0)
	hl.size = Vector2(hw, 24)
	var nl: Label = content["name_label"]
	nl.text = String(d.get("name", ""))
	nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nl.position = Vector2(PAD, row_y - 2.0)
	nl.size = Vector2(W - PAD * 2.0 - hw - 4.0, 24)
	var hp: HPBar = content["hp"]
	hp.set_stats(hp_now, hp_max)
	hp.set_at_risk(mini(hp_now, maxi(0, int(d.get("incoming", 0)) - int(d.get("shield", 0)))))
	hp.position = Vector2(PAD, row_y + 26.0)
	hp.size = Vector2(W - PAD * 2.0, 10)

	_fill_chips(content["chips"], d.get("status", {}), int(d.get("shield", 0)), d.get("status_tip", Callable()))

	# Card frame: selected / legal ally target = selected plate; focus ring on the button.
	var lit := selected or bool(d.get("legal_target", false))
	(content["plate"] as PanelContainer).theme_type_variation = "PanelCardSelected" if lit else "PanelCard"
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		btn.add_theme_stylebox_override(st, empty)
	btn.add_theme_stylebox_override("focus", UI3Theme.focus_style(12))
	body.modulate.a = 0.55 if not alive else 1.0
	UI3Tooltip.bind(btn, String(d.get("tip", "")))
	btn.set_meta("ui3_tip_side_of_row", true)


static func _fill_chips(row: HBoxContainer, status: Dictionary, shield: int, tip_fn: Callable) -> void:
	for c in row.get_children():
		row.remove_child(c)
		c.queue_free()
	var items: Array = []
	if shield > 0:
		items.append(["shield", shield, UI3.status_chip("face_shield", shield, UI3Theme.color("shield"))])
	for k in status:
		var v := int(status[k])
		if v <= 0:
			continue
		if _STATUS_ICON.has(k):
			var tint := UI3Theme.color("poison") if k == "poison" else UI3Theme.color("text")
			items.append([k, v, UI3.status_chip(String(_STATUS_ICON[k]), v, tint)])
		else:
			items.append([k, v, UI3.status_label_chip(String(k), v)])
	var shown := mini(items.size(), 3 if items.size() > 3 else items.size())
	for i in shown:
		var it: Array = items[i]
		var chip: Control = it[2]
		if tip_fn.is_valid():
			UI3Tooltip.bind(chip, String(tip_fn.call(it[0], it[1])))
			chip.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(chip)
	if items.size() > shown:
		var more := UI3.plate(&"info")
		more.theme_type_variation = "PanelInfo"
		var ml := UI3.label("+%d" % (items.size() - shown), "LabelDisplay")
		ml.add_theme_font_size_override("font_size", 20)
		more.add_child(ml)
		row.add_child(more)
	for i in range(shown, items.size()):
		(items[i][2] as Node).queue_free()


## B12 cosmetic dice skin: art under the face glyph + number, inside the DieTile's panel. Visual only.
static func _apply_skin(content: Dictionary, skin: String) -> void:
	if skin == "" or content["die"] == null:
		return
	var node := CosmeticArt.make_node(skin, 88.0)
	if node == null:
		return
	node.name = "Skin"
	node.clip_contents = true
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var die: Control = content["die"]
	die.add_child(node)
	die.move_child(node, 0)
	content["skin_id"] = skin
	content["skin_node"] = node


## The DieTile lifts itself when selected (state "selected"); nothing to tween here.
static func set_lifted(_view: Node, content: Dictionary, lifted: bool, _instant: bool) -> void:
	content["lifted"] = lifted
