class_name Ui5RunPickerParts
extends RefCounted
## UI-05 b23 lane S3b: parts of the Run setup modals (round-3 ui05-land-screens.html, frames 06-run-setup--picker,
## picker-empty, presets-load, presets-save, lb-*). Sizes are tokens; the 1280 frames are the 1920 ones scaled.
## Names repeated on purpose (AxieTile, Row, TeamButton, Skeleton) are added with add_child(x, true) by the caller.


## Modal layer + centred dialog plate. Closes any open modal first. Returns {root, dialog, v}.
static func modal(s: RunSetup, kind: StringName, dialog_name: String, width_token: String) -> Dictionary:
	s.close_modal()
	var c := Ui5PresetParts.modal_root(s._modal_layer, kind)
	var d := UI3.plate(&"dialog")
	d.name = dialog_name
	d.custom_minimum_size.x = UI3Theme.size_of(width_token)
	c.add_child(d)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("20"))
	d.add_child(v)
	return {"root": c.get_parent(), "dialog": d, "v": v}


static func title(text: String) -> Label:
	var t := Ui5Text.label(text, "text_banner", "text", true)
	t.name = "Title"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return t


## .tab: plate_raised, selected = btn_secondary + 3 px ring. h_token = btn_m or btn_s.
static func tab(text: String, on: bool, h_token: String, node_name: String, expand := false) -> Button:
	var b := Button.new()
	b.name = node_name
	b.theme = UI3Theme.get_theme()
	b.text = text
	b.toggle_mode = true
	b.button_pressed = on
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size.y = UI3Theme.size_of(h_token)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL if expand else Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_override("font", UI3Theme.font_display())
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	var pad := UI3Theme.space("20")
	var off := UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("m"), 0, Color.TRANSPARENT, Vector4(pad, 0, pad, 0))
	var onb := UI3Theme.flat(UI3Theme.color("btn_secondary"), UI3Theme.radius("m"), 3, UI3Theme.color("selected"), Vector4(pad, 0, pad, 0))
	for st in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(st, off)
	for st in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, onb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, UI3Theme.color("text"))
	return b


## Space keycap on the safe / focused button.
static func cap(b: Button) -> void:
	Ui5PresetParts.attach_space_cap(b)


## Drops the keycap again (focus moved elsewhere) and gives the right padding back.
static func uncap(b: Button) -> void:
	for c in b.get_children():
		if c.has_meta("ui5_keycap"):
			b.remove_child(c)
			c.queue_free()
	Ui5HudStyle.reserve_trailing(b, null, maxi(int(b.get_theme_stylebox("normal").content_margin_left), UI3Theme.space("20")))


## Side of the square portrait of an AxieTile (6 columns inside the picker plate).
static func tile_portrait_px() -> int:
	var inner := UI3Theme.size_of("picker_w") - 2 * UI3Theme.space("32") - 5 * UI3Theme.space("12")
	return int(floor(inner / 6.0)) - 2 * UI3Theme.space("8")


## AxieTile: square portrait, name, "Class · HP n". Nothing is picked here; the caller marks the pick.
static func axie_tile(key: String, def: Dictionary, taken: bool, party_slot: int) -> Button:
	var b := Button.new()
	b.name = "AxieTile"
	b.theme = UI3Theme.get_theme()
	b.set_meta("hero_key", key)
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pad := UI3Theme.space("8")
	var px := tile_portrait_px()
	var line := int(ceil(UI3Theme.size_of("text_body") * 1.35))
	b.custom_minimum_size = Vector2(0, px + 2 * pad + UI3Theme.space("4") * 2 + 2 * line)
	var base := UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("m"))
	var ring := UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("m"), 2, UI3Theme.color("selected"))
	b.add_theme_stylebox_override("normal", base)
	b.add_theme_stylebox_override("pressed", base)
	b.add_theme_stylebox_override("disabled", base)
	b.add_theme_stylebox_override("hover", ring)
	b.add_theme_stylebox_override("hover_pressed", ring)
	b.add_theme_stylebox_override("focus", ring)
	var col := VBoxContainer.new()
	col.name = "Col"
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = pad
	col.offset_top = pad
	col.offset_right = -pad
	col.offset_bottom = -pad
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", UI3Theme.space("4"))
	b.add_child(col)
	var cls := String(def.get("cls", ""))
	var por := Ui5PresetParts.portrait(key, px)
	por.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(por)
	var nm := Ui5Text.label("", "text_body", "text", true)
	nm.name = "HeroName"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	col.add_child(nm)
	Ui5Ellipsis.set_text(nm, String(def.get("n", key)))
	var sub := Ui5Text.label("%s · %s %d" % [cls.capitalize(), "HP", int(def.get("max_hp", 0))], "text_body", "text_muted")
	sub.name = "HeroSub"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.clip_text = true
	col.add_child(sub)
	if taken:
		b.modulate.a = 0.6
	return b


## Hover tip over a modal (.tooltip): body text on a plate, never blocks the mouse.
static func tip(text: String) -> PanelContainer:
	var p := UI3.plate(&"plate")
	p.name = "InPartyTooltip"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.visible = false
	p.add_child(Ui5Text.label(text, "text_body", "text"))
	return p


## Centred block with a message (EmptyState / empty board).
static func center_block(text: String, node_name := "EmptyState") -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = node_name
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", UI3Theme.space("12"))
	var l := Ui5Text.label(text, "text_body", "text")
	l.name = "Msg"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	return v


static func skeleton() -> Panel:
	var p := Panel.new()
	p.name = "Skeleton"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.custom_minimum_size.y = UI3Theme.size_of("lb_row_h")
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("skeleton"), UI3Theme.radius("m")))
	return p


## .lb-row: rank, name (cut with "…"), "You" tag on the own row, score. Own row = 3 px ring.
static func lb_row(rank: int, who: String, score: String, own: bool, you: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Row"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_meta("own", own)
	p.custom_minimum_size.y = UI3Theme.size_of("lb_row_h")
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("s"),
		3 if own else 0, UI3Theme.color("selected"), Vector4(UI3Theme.space("16"), 0, UI3Theme.space("16"), 0)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(h)
	var rk := Ui5Text.label("#%d" % rank, "text_body", "text", true)
	rk.name = "Rank"
	rk.custom_minimum_size.x = int(56.0 * float(UI3Theme.size_of("btn_m")) / 56.0)
	h.add_child(rk)
	var nm := Ui5Text.label("", "text_body", "text")
	nm.name = "Who"
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	h.add_child(nm)
	Ui5Ellipsis.set_text(nm, who)
	if own:
		var tg := PanelContainer.new()
		tg.name = "YouTag"
		tg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tg.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("text"), UI3Theme.radius("s"), 0, Color.TRANSPARENT,
			Vector4(UI3Theme.space("8"), UI3Theme.space("4"), UI3Theme.space("8"), UI3Theme.space("4"))))
		tg.add_child(Ui5Text.label(you, "text_body", "text_ink", true))
		h.add_child(tg)
	var sc := Ui5Text.label(score, "text_body", "text", true)
	sc.name = "Score"
	h.add_child(sc)
	return p


## NameField: field_bg, 3 px accent border, radius m, field_h high.
static func name_field(text: String, max_len: int) -> LineEdit:
	var e := LineEdit.new()
	e.name = "NameField"
	e.theme = UI3Theme.get_theme()
	e.max_length = max_len
	e.text = text
	e.custom_minimum_size.y = UI3Theme.size_of("field_h")
	var sb := UI3Theme.flat(UI3Theme.color("field_bg"), UI3Theme.radius("m"), 3, UI3Theme.color("accent"), Vector4(UI3Theme.space("16"), 0, UI3Theme.space("16"), 0))
	for st in ["normal", "focus", "read_only"]:
		e.add_theme_stylebox_override(st, sb)
	e.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	e.add_theme_color_override("font_color", UI3Theme.color("text"))
	e.add_theme_color_override("caret_color", UI3Theme.color("text"))
	return e


## TeamButton: btn_m high row, plate_raised, label left. Selected = ring.
static func team_button(text: String) -> Button:
	var b := Button.new()
	b.name = "TeamButton"
	b.theme = UI3Theme.get_theme()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size.y = UI3Theme.size_of("btn_m")
	b.add_theme_font_override("font", UI3Theme.font_display())
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	set_team_on(b, false)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, UI3Theme.color("text"))
	return b


static func set_team_on(b: Button, on: bool) -> void:
	var m := Vector4(UI3Theme.space("16"), UI3Theme.space("8"), UI3Theme.space("16"), UI3Theme.space("8"))
	var sb := UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("m"), 3 if on else 0, UI3Theme.color("selected"), m)
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(st, sb)
	b.set_meta("picked", on)
