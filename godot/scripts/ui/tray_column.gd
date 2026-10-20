class_name TrayColumn
extends RefCounted
## One party card in the dice tray, UI-03 (screens/02-combat/spec.md): 152 w, UI3 card plate, a
## UI3.DieTile (96 slot, face word under it, "· used" second line), name + HP row, HP bar.
## Status icons live above the Axie's head now (StatusHeads), not on the card. The card is still a Button
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
	return {"button": btn, "root": root, "body": body, "plate": plate,
		"name_label": name_label, "hp": hp, "hp_label": hp_label, "lifted": false,
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

	# Card frame: selected / legal ally target = selected plate; focus ring on the button.
	var lit := selected or bool(d.get("legal_target", false))
	(content["plate"] as PanelContainer).theme_type_variation = "PanelCardSelected" if lit else "PanelCard"
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		btn.add_theme_stylebox_override(st, empty)
	btn.add_theme_stylebox_override("focus", UI3Theme.focus_style(12))
	body.modulate.a = 0.55 if not alive else 1.0
	# Depth v3 Hold: a HOLD chip on the card of a parked die (word, not colour alone).
	var held := bool(d.get("held", false))
	if held and not content.has("hold_chip"):
		var chip := UI3.chip("HOLD")
		chip.name = "HoldChip"
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.position = Vector2(W * 0.5 - 36.0, -8.0)
		body.add_child(chip)
		content["hold_chip"] = chip
	if content.has("hold_chip"):
		(content["hold_chip"] as Control).visible = held
	# Overcast (lane OC): an OVERCAST chip on the powered-up die (word, not colour alone).
	var oc := bool(d.get("overcast", false))
	if oc and not content.has("overcast_chip"):
		var ochip := UI3.chip("OVERCAST")
		ochip.name = "OvercastChip"
		ochip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ochip.position = Vector2(W * 0.5 - 52.0, -8.0)
		body.add_child(ochip)
		content["overcast_chip"] = ochip
	if content.has("overcast_chip"):
		(content["overcast_chip"] as Control).visible = oc
	_update_v4(content, d)
	_update_crack(content, d)
	UI3Tooltip.bind(btn, String(d.get("tip", "")))
	btn.set_meta("ui3_tip_side_of_row", true)


## Cosmetic dice skin on the 2D tile (47-tray-skin): an overlay trim (border + Epic+ corner caps) drawn over
## the tile, same rect, so it tilts, lifts and fades with the tile. Glyph, number and states are untouched.
static func _apply_skin(content: Dictionary, skin: String) -> void:
	if skin == "" or content["die"] == null:
		return
	var die: Control = content["die"]
	var node := DiceSkin.make_trim(skin, int(round(die.size.x)))
	if node == null:
		return
	die.add_child(node)
	content["skin_id"] = skin
	content["skin_node"] = node


## The DieTile lifts itself when selected (state "selected"); nothing to tween here.
static func set_lifted(_view: Node, content: Dictionary, lifted: bool, _instant: bool) -> void:
	content["lifted"] = lifted


## Depth v4 (combat-v4.md 1.1 / 1.3): the part chip (32x32, glyph + short word for grayscale) top-left, and the
## "5 -> 8" Set preview top-right. `d`: part_tex:Texture2D|null, part_text:String, pv:String ("" = none).
static func _update_v4(content: Dictionary, d: Dictionary) -> void:
	var body: Control = content["body"]
	var part_text := String(d.get("part_text", ""))
	if part_text != "" and not content.has("part_chip"):
		var chip := PanelContainer.new()
		chip.name = "PartChip"
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.theme = UI3Theme.get_theme()
		var sb := UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("s"), 2, UI3Theme.color("text_muted"))
		sb.content_margin_left = 2
		sb.content_margin_right = 2
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		chip.add_theme_stylebox_override("panel", sb)
		chip.custom_minimum_size = Vector2(32, 32)
		var tr := TextureRect.new()
		tr.name = "Glyph"
		tr.custom_minimum_size = Vector2(28, 28)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(tr)
		chip.position = Vector2(2, 2)
		body.add_child(chip)
		content["part_chip"] = chip
	if content.has("part_chip"):
		var chip2: Control = content["part_chip"]
		chip2.visible = part_text != ""
		var glyph: TextureRect = chip2.get_node("Glyph")
		glyph.texture = d.get("part_tex", null)
		chip2.set_meta("part_text", part_text)
		UI3Tooltip.bind(chip2, "%s. %s" % [part_text, TranslationServer.translate("3 dice of the same part make a SET")])
	var pv := String(d.get("pv", ""))
	if pv != "" and not content.has("pv_label"):
		var l := UI3.label("", "LabelDisplay")
		l.name = "SetPreview"
		l.add_theme_font_size_override("font_size", 18)
		l.add_theme_color_override("font_color", UI3Theme.color("accent"))
		l.add_theme_color_override("font_outline_color", UI3Theme.color("panel"))
		l.add_theme_constant_override("outline_size", 4)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(l)
		content["pv_label"] = l
	if content.has("pv_label"):
		var pl: Label = content["pv_label"]
		pl.visible = pv != ""
		pl.text = pv
		var w := pl.get_minimum_size().x + 2.0
		pl.position = Vector2(W - PAD - w, 4)
		pl.size = Vector2(w, 24)


## Depth v4 2.2 / 2.4: Crack (a zig-zag drawn on the tile + a "1/2" chip, no colour wash, card stays readable) and the
## reroll pick tick. `d`: cracked:bool, rr_tick:bool.
static func _update_crack(content: Dictionary, d: Dictionary) -> void:
	var body: Control = content["body"]
	var cracked := bool(d.get("cracked", false))
	if cracked and not content.has("crack_chip"):
		var chip := UI3.chip("1/2")
		chip.name = "CrackChip"
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.position = Vector2(W - 52.0, 34.0)
		body.add_child(chip)
		content["crack_chip"] = chip
		var line := Line2D.new()
		line.name = "CrackMark"
		line.width = 3.0
		line.default_color = UI3Theme.color("accent_text")
		line.points = PackedVector2Array([Vector2(52, 4), Vector2(62, 26), Vector2(50, 44), Vector2(64, 64), Vector2(54, 90)])
		body.add_child(line)
		content["crack_mark"] = line
	if content.has("crack_chip"):
		(content["crack_chip"] as Control).visible = cracked
		(content["crack_mark"] as CanvasItem).visible = cracked
	var wt := String(d.get("wild_text", ""))
	if wt != "" and not content.has("wild_chip"):
		var wc := UI3.chip("?")
		wc.name = "WildChip"
		wc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wc.position = Vector2(W * 0.5 - 40.0, -8.0)
		body.add_child(wc)
		content["wild_chip"] = wc
	if content.has("wild_chip"):
		var wch: Control = content["wild_chip"]
		wch.visible = wt != ""
		if wt != "":
			((wch.get_child(0)) as Label).text = "? " + wt
	var tick := bool(d.get("rr_tick", false))
	if tick and not content.has("rr_chip"):
		var rc := UI3.chip("REROLL")
		rc.name = "RerollChip"
		rc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rc.position = Vector2(W * 0.5 - 40.0, -8.0)
		body.add_child(rc)
		content["rr_chip"] = rc
	if content.has("rr_chip"):
		(content["rr_chip"] as Control).visible = tick
