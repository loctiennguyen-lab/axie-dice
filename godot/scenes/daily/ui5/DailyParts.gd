class_name Ui5DailyParts
extends RefCounted
## UI-05 Daily pieces (ui05-meta2-screens.html, frames 41-daily*): DailyCard / WeeklyCard / GemGiftCard shell, the
## reward row (.kv), DayChip, result line (ToneDisc + text), Banner, the combo StatusChip. Sizes / colours are tokens.
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


## `.dcard`: plate, padding 20, gap 12, daily_card_w wide. Returns {plate, col}. gem = violet border (paid-currency card).
static func card(node_name: String, gem := false) -> Dictionary:
	var pad := UI3Theme.space("20")
	var box := PanelParts.plate_box("l", pad)
	if gem:
		box.set_border_width_all(UI3Theme.stroke("rim"))
		box.border_color = UI3Theme.color("gem_border")
	var p := PanelParts.panel(box, node_name)
	p.custom_minimum_size.x = UI3Theme.size_of("daily_card_w")
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.name = "Col"
	v.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(v)
	return {"plate": p, "col": v}


static func title(t: String) -> Label:
	var l := Ui5Text.label(t, "text_title", "text", true)
	l.name = "CardTitle"
	return l


static func note(t: String) -> Label:
	var l := Ui5Text.label(t, "text_body", "text_muted")
	l.name = "Note"
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## `.kv`: raised row, [icon] label ... value. `icon` null = the XP badge.
static func kv(icon: Texture2D, label: String, value: String) -> PanelContainer:
	var c := PanelParts.panel(UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("s"), 0, Color.TRANSPARENT,
		Vector4(UI3Theme.space("12"), UI3Theme.space("8"), UI3Theme.space("12"), UI3Theme.space("8"))), "Row")
	c.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	c.add_child(h)
	var left := HBoxContainer.new()
	left.add_theme_constant_override("separation", UI3Theme.space("8"))
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(left)
	var px := UI3Theme.size_of("icon_m")
	if icon != null:
		left.add_child(PanelParts.icon_rect(icon, px))
	else:
		var b := PanelParts.panel(UI3Theme.flat(UI3Theme.color("accent"), UI3Theme.radius("s")), "XpBadge")
		b.custom_minimum_size = Vector2(px, px)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var x := Ui5Text.label("XP", "text_key", "text_ink", true)
		x.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_child(x)
		left.add_child(b)
	left.add_child(Ui5Text.label(label, "text_body", "text"))
	var val := Ui5Text.label(value, "text_title", "text", true)
	val.name = "Value"
	h.add_child(val)
	return c


## `.day-chip`: pill, claimed = amber + tick, not yet = outlined, muted text (the word says it, never colour alone).
static func day_chip(text: String, done: bool, node_name := "DayChip") -> PanelContainer:
	var pad := UI3Theme.space("12")
	var box: StyleBoxFlat
	if done:
		box = UI3Theme.flat(UI3Theme.color("accent"), UI3Theme.radius("pill"), 0, Color.TRANSPARENT, Vector4(pad, 0, pad, 0))
	else:
		box = UI3Theme.flat(Color.TRANSPARENT, UI3Theme.radius("pill"), UI3Theme.stroke("rim"), UI3Theme.color("plate_rim"),
			Vector4(pad, 0, pad, 0))
	var c := PanelParts.panel(box, node_name)
	c.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", UI3Theme.space("4"))
	c.add_child(h)
	if done:
		var ic := PanelParts.icon_rect(UI3.icon("ui_check", UI3Theme.size_of("icon_s")), UI3Theme.size_of("icon_s"))
		ic.modulate = UI3Theme.color("text_ink")
		h.add_child(ic)
	h.add_child(Ui5Text.label(text, "text_key", "text_ink" if done else "text_muted", true))
	return c


## `.result-line`: ToneDisc + text (what a claim just paid, or why it failed).
static func result_line(text: String, tone: StringName) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = "ResultLine"
	h.add_theme_constant_override("separation", UI3Theme.space("8"))
	h.add_child(Ui5ToneDisc.make(tone))
	var l := Ui5Text.label(text, "text_body", "text")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	return h


## `.info-banner`: ToneDisc + title + body (+ SignInButton).
static func banner(tone: StringName, msg: String, detail: String, sign_in: Callable = Callable()) -> PanelContainer:
	var pad := Vector4(UI3Theme.space("16"), UI3Theme.space("12"), UI3Theme.space("16"), UI3Theme.space("12"))
	var p := PanelParts.panel(UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("l"), UI3Theme.stroke("rim"),
		UI3Theme.color("notice_warn"), pad, PanelParts.lip(UI3Theme.color("plate_ink"))), "Banner")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(h)
	h.add_child(Ui5ToneDisc.make(tone))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var t := Ui5Text.label(msg, "text_body", "text", true)
	t.name = "Title"
	v.add_child(t)
	var d := Ui5Text.label(detail, "text_body", "text")
	d.name = "Detail"
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	if sign_in.is_valid():
		var b := UI3.button("Sign in", &"secondary", &"S")
		b.name = "SignInButton"
		b.pressed.connect(sign_in)
		h.add_child(b)
	return p


## Combo StatusChip: Done = amber + tick, Not yet = outlined.
static func status_chip(done: bool) -> PanelContainer:
	var c := day_chip("Done" if done else "Not yet", done, "StatusChip")
	c.size_flags_horizontal = Control.SIZE_SHRINK_END
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c
