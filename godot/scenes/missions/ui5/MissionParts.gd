class_name MissionParts
extends RefCounted
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
## UI-05 S5: small builders of the Missions screen (CSS .kv, .loss, .warn, .tag, .info-banner, .mhead). Sizes and colours
## are tokens; texts come from the caller (game data), never literals of an example frame.


static func head_row() -> Control:
	var m := MarginContainer.new()
	m.name = "Head"
	m.add_theme_constant_override("margin_left", UI3Theme.space("16"))
	m.add_theme_constant_override("margin_right", UI3Theme.space("16"))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	m.add_child(h)
	var names := ["TIER", "MODE", "STAKE", "WIN BACK", "STONE", "RULES"]
	for i in 6:
		var l := Ui5Text.label(names[i], "text_key", "text_muted")
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.size_flags_stretch_ratio = MissionTierRow.RATIOS[i]
		l.custom_minimum_size.x = 0
		if i in [2, 3, 4]:
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(l)
	return m


static func kv_row(label: String, value: String, node_name: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = node_name
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
	v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_stretch_ratio = 2.0
	h.add_child(v)
	return p


## LoseBox: danger_bg box, "Lose or abandon" label + sentence.
static func lose_box(title: String, text: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "LoseBox"
	p.theme = UI3Theme.get_theme()
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("danger_bg"), UI3Theme.radius("l"), 0,
		Color.TRANSPARENT, Vector4(UI3Theme.space("20"), UI3Theme.space("16"), UI3Theme.space("20"), UI3Theme.space("16"))))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("4"))
	p.add_child(v)
	if title != "":
		var t := Ui5Text.label(title, "text_body", "danger_text", true)
		t.name = "LoseTitle"
		v.add_child(t)
	var b := Ui5Text.label(text, "text_body", "text")
	b.name = "LoseText"
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(b)
	return p


## Warning: ToneDisc "!" + orange text, top aligned.
static func warning(text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = "Warning"
	h.add_theme_constant_override("separation", UI3Theme.space("8"))
	var d := Ui5ToneDisc.make(&"warn")
	d.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(d)
	var l := Ui5Text.label(text, "text_body", "warn_text")
	l.name = "WarningText"
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return h


## LockedTag: pill chip with the lock icon and "Locked".
static func locked_tag() -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "LockedTag"
	p.theme = UI3Theme.get_theme()
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.custom_minimum_size.y = UI3Theme.size_of("tag_h")
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(UI3Theme.space("8"), UI3Theme.space("4"), UI3Theme.space("12"), UI3Theme.space("4"))))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("4"))
	p.add_child(h)
	var ic := TextureRect.new()
	ic.texture = UI3.icon("ui_lock")
	ic.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_s")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(ic)
	h.add_child(Ui5Text.label("Locked", "text_key", "text", true))
	return p


## Banner: ToneDisc + Title + Body (+ optional SignInButton). tone &"ok"/&"warn"/&"error"/&"info".
static func banner(tone: StringName, title: String, body: String, sign_in: Callable = Callable(), retry: Callable = Callable()) -> PanelContainer:
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
	if sign_in.is_valid():
		var btn := UI3.button("Sign in", &"secondary", &"S")
		btn.name = "SignInButton"
		btn.pressed.connect(sign_in)
		h.add_child(btn)
	if retry.is_valid():   # kept on purpose: the frames draw no Retry, but offline / start errors need a way to try again
		var rb := UI3.button("Retry", &"secondary", &"S")
		rb.name = "RetryButton"
		rb.pressed.connect(retry)
		h.add_child(rb)
	return p
