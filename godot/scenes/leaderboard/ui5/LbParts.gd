class_name LbParts
extends RefCounted
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
## UI-05 S7a: small builders of the Leaderboard screen (CSS .lbh, .asc, .tag, .kv, .info-banner, .center-block).
## Sizes and colours are tokens; every text comes from the caller (board data), never from an example frame.


## A pill tag. kind: &"won" | &"lost" | &"you".
static func tag(text: String, kind: StringName, node_name := "") -> PanelContainer:
	var bg := "chip"
	var fg := "text"
	match kind:
		&"won":
			bg = "success_bg"
			fg = "success_text"
		&"lost":
			bg = "danger_bg"
			fg = "danger_text"
		&"you":
			bg = "text"
			fg = "text_ink"
	var p := PanelContainer.new()
	p.theme = UI3Theme.get_theme()
	if node_name != "":
		p.name = node_name
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.custom_minimum_size.y = UI3Theme.size_of("tag_h")
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color(bg), UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(UI3Theme.space("8"), UI3Theme.space("4"), UI3Theme.space("12"), UI3Theme.space("4"))))
	p.add_child(Ui5Text.label(text, "text_key", fg, true))
	return p


## .lbh: the column names, same ratios as the rows. cols = LeaderboardScreen.columns().
static func head_row(cols: Array) -> Control:
	var m := MarginContainer.new()
	m.name = "Head"
	m.add_theme_constant_override("margin_left", UI3Theme.space("16"))
	m.add_theme_constant_override("margin_right", UI3Theme.space("16"))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	m.add_child(h)
	for d in cols:
		var l := Ui5Text.label(String(d[1]), "text_key", "text_muted")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.size_flags_stretch_ratio = float(d[2])
		l.custom_minimum_size.x = 0
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if bool(d[3]) else HORIZONTAL_ALIGNMENT_LEFT
		h.add_child(l)
	return m


## The "Caption" plate: "A6 · Season" title, one muted line (cut with an ellipsis when long), last-updated on the right.
static func caption(title: String, line: String, updated: String) -> PanelContainer:
	var p := PanelParts.panel(UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("l"), UI3Theme.stroke("rim"),
		UI3Theme.color("plate_rim"), Vector4(UI3Theme.space("16"), UI3Theme.space("12"), UI3Theme.space("16"), UI3Theme.space("12")),
		PanelParts.lip(UI3Theme.color("plate_ink"))), "Caption")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(h)
	var t := Ui5Text.label(title, "text_title", "text", true)
	t.name = "CaptionTitle"
	h.add_child(t)
	var l := Ui5Text.label(line, "text_body", "text_muted")
	l.name = "CaptionLine"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = 0
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(l)
	var u := Ui5Text.label("Last updated %s" % updated if updated != "" else "", "text_body", "text_muted")
	u.name = "CaptionUpdated"
	u.visible = updated != ""
	h.add_child(u)
	return p


## .info-banner: ToneDisc + title + one body line + small buttons [{name, text, cb}].
static func banner(tone: StringName, title: String, body: String, buttons: Array) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Banner"
	p.theme = UI3Theme.get_theme()
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("l"), UI3Theme.stroke("rim"),
		UI3Theme.color("notice_warn"), Vector4(UI3Theme.space("16"), UI3Theme.space("12"), UI3Theme.space("16"), UI3Theme.space("12")),
		PanelParts.lip(UI3Theme.color("plate_ink"))))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(h)
	h.add_child(Ui5ToneDisc.make(tone))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var t := Ui5Text.label(title, "text_body", "text", true)
	t.name = "Title"
	v.add_child(t)
	var b := Ui5Text.label(body, "text_body", "text")
	b.name = "Body"
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(b)
	for d in buttons:
		var btn := UI3.button(String(d["text"]), &"secondary", &"S")
		btn.name = String(d["name"])
		btn.pressed.connect(d["cb"])
		h.add_child(btn)
	return p


## .center-block: optional ToneDisc, banner-size title, body, optional button row. Used for EmptyState and ErrorState.
static func center_block(node_name: String, title: String, body: String, tone := &"", buttons: Array = []) -> Control:
	var c := CenterContainer.new()
	c.name = node_name
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("12"))
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	if tone != &"":
		var d := Ui5ToneDisc.make(tone)
		d.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(d)
	var t := Ui5Text.label(title, "text_banner", "text", true)
	t.name = "Title"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var b := Ui5Text.label(body, "text_body", "text")
	b.name = "Body"
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.x = UI3Theme.size_of("lb_detail_w") * 1.2
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(b)
	if not buttons.is_empty():
		var row := HBoxContainer.new()
		row.name = "FootRow"
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", UI3Theme.space("16"))
		v.add_child(row)
		for d in buttons:
			var btn := UI3.button(String(d["text"]), &"secondary", &"M")
			btn.name = String(d["name"])
			btn.pressed.connect(d["cb"])
			row.add_child(btn)
	return c


## .kv: label left, value right, plate_raised, radius s.
static func kv_row(label: String, value: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Kv"
	p.theme = UI3Theme.get_theme()
	p.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("s"), 0,
		Color.TRANSPARENT, Vector4(UI3Theme.space("12"), UI3Theme.space("8"), UI3Theme.space("12"), UI3Theme.space("8"))))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(h)
	var k := Ui5Text.label(label, "text_body", "text")
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(k)
	var v := Ui5Text.label(value, "text_title", "text", true)
	v.name = "Value"
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(v)
	return p


## .asc chip: 11 of them share the row equally. State: normal / on (ring + plate_raised) / locked (chip fill, muted, lock icon).
static func asc_chip(a: int) -> Button:
	var b := Button.new()
	b.name = "AscChipA%d" % a
	b.theme = UI3Theme.get_theme()
	b.set_meta("asc", a)
	b.toggle_mode = false
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, UI3Theme.size_of("btn_s"))
	b.add_theme_font_override("font", UI3Theme.font_display())
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	b.clip_text = false
	# .asc: lock icon (locked only) + "A6", centred together (an HBox so the centring check can measure it)
	var h := HBoxContainer.new()
	h.name = "Content"
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", UI3Theme.space("4"))
	var ic := TextureRect.new()
	ic.name = "Lock"
	ic.texture = UI3.icon("ui_lock")
	ic.custom_minimum_size = Vector2(14, 14)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.modulate.a = 0.8
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.visible = false
	h.add_child(ic)
	var l := Ui5Text.label("A%d" % a, "text_body", "text", true)
	l.name = "Label"
	h.add_child(l)
	b.add_child(h)
	return b


static func style_asc_chip(b: Button, on: bool, locked: bool) -> void:
	var bg := "chip" if locked else ("plate_raised" if on else "btn_secondary")
	var sb := UI3Theme.flat(UI3Theme.color(bg), UI3Theme.radius("m"), 3 if on else 0, UI3Theme.color("selected"))
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(st, sb)
	var fc := UI3Theme.color("text_muted" if locked else "text")
	(b.get_node("Content/Label") as Label).add_theme_color_override("font_color", fc)
	(b.get_node("Content/Lock") as Control).visible = locked
	b.modulate = Color.WHITE
	b.tooltip_text = "Locked for you" if locked else ""
