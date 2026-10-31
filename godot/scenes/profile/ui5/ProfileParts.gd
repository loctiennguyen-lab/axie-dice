class_name Ui5ProfileParts
extends RefCounted
## UI-05 Profile pieces (ui05-meta3-screens.html, frames 24-profile*): tag (.tag), StatTile (.stile3), kv row (.kv),
## RunRow (.run-row), plates, CosmeticTile button style (.ctile). Sizes and colours are tokens; nothing hardcoded.
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const RUN_COLS: Array[float] = [0.8, 1.6, 0.5, 0.6, 1.2, 0.6]


static func plate(node_name: String, pad_v: int, pad_h: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = node_name
	p.theme = UI3Theme.get_theme()
	var sb := PanelParts.plate_box("l", 0)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	p.add_theme_stylebox_override("panel", sb)
	return p


## `.tag`: pill, min-h tag_h, Rowdies text_key. `ring` alpha > 0 draws a 2 px outline. Label node is "Text".
static func tag(text: String, node_name := "Tag", fg := Color.TRANSPARENT, bg := Color.TRANSPARENT, icon_name := "", ring := Color.TRANSPARENT, no_fill := false) -> PanelContainer:
	var f := fg if fg.a > 0.0 else UI3Theme.color("text")
	var b := Color.TRANSPARENT if no_fill else (bg if bg.a > 0.0 else UI3Theme.color("chip"))
	var p := PanelContainer.new()
	p.name = node_name
	p.theme = UI3Theme.get_theme()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.custom_minimum_size.y = UI3Theme.size_of("tag_h")
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel", UI3Theme.flat(b, UI3Theme.radius("pill"), 2 if ring.a > 0.0 else 0, ring,
		Vector4(UI3Theme.space("8"), UI3Theme.space("4"), UI3Theme.space("12"), UI3Theme.space("4"))))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("4"))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	if icon_name != "":
		var ic := TextureRect.new()
		ic.name = "Icon"
		ic.texture = UI3.icon(icon_name)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_s")
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic.modulate = f
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(ic)
	var l := Ui5Text.label(text, "text_key", "text", true)
	l.name = "Text"
	l.add_theme_color_override("font_color", f)
	l.clip_text = false
	h.add_child(l)
	return p


static func won_tag(won: bool) -> PanelContainer:
	return tag("Won" if won else "Lost", "Result", UI3Theme.color("success_text" if won else "danger_text"),
		UI3Theme.color("success_bg" if won else "danger_bg"))


## `.stile3`: label / big value / sub line, centred vertically.
static func stat_tile(t: Dictionary) -> PanelContainer:
	var p := plate("StatTile_" + String(t["k"]).replace(" ", ""), UI3Theme.space("12"), UI3Theme.space("16"))
	p.custom_minimum_size.y = UI3Theme.size_of("stat_tile_h")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var k := Ui5Text.label(String(t["k"]), "text_body", "text_muted")
	k.name = "Key"
	k.clip_text = true
	v.add_child(k)
	var val := Ui5Text.label(String(t["v"]), "text_banner", "text", true)
	val.name = "Value"
	val.clip_text = true
	v.add_child(val)
	var s := Ui5Text.label(String(t["s"]), "text_body", "text_muted")
	s.name = "Sub"
	s.clip_text = true
	v.add_child(s)
	return p


## `.kv`: raised row, min-h btn_s, label left, value right (Rowdies text_title).
static func kv(label: String, value: String, node_name: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = node_name
	p.theme = UI3Theme.get_theme()
	p.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", PanelParts.cell_box(UI3Theme.space("8"), UI3Theme.space("12"), "s"))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(h)
	var a := Ui5Text.label(label, "text_body", "text")
	a.name = "Key"
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a)
	var b := Ui5Text.label(value, "text_title", "text", true)
	b.name = "Value"
	h.add_child(b)
	return p


static func _col(ratio: float, child: Control) -> Control:
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	child.size_flags_stretch_ratio = ratio
	return child


## `.run-row`: 6 columns date / mode / A# / Won|Lost / Aid / Pure.
static func run_row(i: int, date: String, mode: String, asc: String, won: bool, aid_text: String, pure: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "RunRow_%d" % i
	p.theme = UI3Theme.get_theme()
	p.custom_minimum_size.y = UI3Theme.size_of("run_row_h")
	p.add_theme_stylebox_override("panel", PanelParts.cell_box(0, UI3Theme.space("16"), "s"))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(h)
	var d := Ui5Text.label(date, "text_body", "text_muted")
	d.clip_text = true
	h.add_child(_col(RUN_COLS[0], d))
	var m := Ui5Text.label(mode, "text_body", "text")
	m.clip_text = true
	h.add_child(_col(RUN_COLS[1], m))
	var a := Ui5Text.label(asc, "text_body", "text", true)
	h.add_child(_col(RUN_COLS[2], a))
	var rc := HBoxContainer.new()
	rc.add_child(won_tag(won))
	h.add_child(_col(RUN_COLS[3], rc))
	var al := Ui5Text.label(aid_text, "text_body", "text_muted")
	al.name = "AidMark"
	al.clip_text = true
	h.add_child(_col(RUN_COLS[4], al))
	var pc := HBoxContainer.new()
	if pure:
		pc.add_child(tag("Pure", "PurePill", Color.TRANSPARENT, Color.TRANSPARENT, "", UI3Theme.color("text")))
	h.add_child(_col(RUN_COLS[5], pc))
	return p


## `.ctile` / `.ttile` button look: plate, rim; `on` = 3 px selected ring. min-h `h_token`.
static func tile_button(node_name: String, on: bool, h_token: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.theme = UI3Theme.get_theme()
	b.toggle_mode = true
	b.button_pressed = on
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size.y = UI3Theme.size_of(h_token)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_contents = true
	var rad := UI3Theme.radius("l")
	var rim := UI3Theme.stroke("rim")
	var base := UI3Theme.flat(UI3Theme.color("plate"), rad, rim, UI3Theme.color("plate_rim"))
	var hov := UI3Theme.flat(UI3Theme.color("plate_raised"), rad, rim, UI3Theme.color("plate_rim"))
	var sel := UI3Theme.flat(UI3Theme.color("plate"), rad, UI3Theme.stroke("selected"), UI3Theme.color("selected"))
	b.add_theme_stylebox_override("normal", base)
	b.add_theme_stylebox_override("disabled", base)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_stylebox_override("pressed", sel)
	b.add_theme_stylebox_override("hover_pressed", sel)
	b.add_theme_stylebox_override("focus", UI3Theme.focus_style(rad))
	return b


## Round tick disc (`.eq`, keycap_h): success_text fill, ink tick.
static func equipped_disc() -> Panel:
	var d := UI3Theme.size_of("keycap_h")
	var disc := Panel.new()
	disc.name = "EquippedDisc"
	disc.custom_minimum_size = Vector2(d, d)
	disc.size = Vector2(d, d)
	disc.pivot_offset = Vector2(d, d) * 0.5
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("success_text"), UI3Theme.radius("pill")))
	var ic := TextureRect.new()
	ic.texture = UI3.icon("ui_check")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, int(d * 0.15))
	ic.modulate = UI3Theme.color("text_ink")
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.add_child(ic)
	return disc
