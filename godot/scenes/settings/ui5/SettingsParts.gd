class_name Ui5SettingsParts
extends RefCounted
## UI-05 Settings pieces (ui05-meta3-screens.html, frames 26-settings*): SectionIndex + IndexRow, Section plates, SettingRow,
## ShortcutRow + KeyButton, switch / slider cells, the account avatar. Sizes and colours are tokens (settings_index_w,
## settings_row_h, key_btn_w, btn_m ...). Repeated data-names are added with a readable unique name (ShortcutRow2 ...).
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")

const SECTION_NAMES := {"Audio": "SectionAudio", "Accessibility": "SectionAccessibility", "Controls": "SectionControls",
	"Aid and spending": "SectionAidAndSpending", "How to play": "SectionHowToPlay", "Run": "SectionRun", "Account": "SectionAccount"}


## `.s-index`: plate, padding 12, gap 4, settings_index_w wide, top aligned. Returns {plate, rows (VBox)}.
static func index_plate() -> Dictionary:
	var p := PanelContainer.new()
	p.name = "SectionIndex"
	p.theme = UI3Theme.get_theme()
	var sb := PanelParts.plate_box("l", 0)
	for m in ["left", "right", "top", "bottom"]:
		sb.set("content_margin_" + m, UI3Theme.space("12"))
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size.x = UI3Theme.size_of("settings_index_w")
	p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("4"))
	p.add_child(v)
	return {"plate": p, "rows": v}


## `.topic`: min-h btn_s, padding 8 / 12, radius s, Rowdies text_key. Selected = btn_secondary + selected ring.
static func index_row(text: String) -> Button:
	var b := Button.new()
	b.name = "IndexRow"
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	b.clip_text = false
	var f := UI3Theme.get_theme().get_font("font", "LabelDisplay")
	if f != null:
		b.add_theme_font_override("font", f)
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_key"))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, UI3Theme.color("text"))
	style_index_row(b, false)
	return b


static func style_index_row(b: Button, selected: bool) -> void:
	var bg := UI3Theme.color("btn_secondary") if selected else Color.TRANSPARENT
	var ring := UI3Theme.stroke("selected") if selected else 0
	var m := Vector4(UI3Theme.space("12"), UI3Theme.space("8"), UI3Theme.space("12"), UI3Theme.space("8"))
	var sb := UI3Theme.flat(bg, UI3Theme.radius("s"), ring, UI3Theme.color("selected"), m)
	var hover := UI3Theme.flat(bg if selected else UI3Theme.color("plate_raised"), UI3Theme.radius("s"), ring, UI3Theme.color("selected"), m)
	for st in ["normal", "pressed"]:
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", UI3Theme.flat(Color.TRANSPARENT, UI3Theme.radius("s"), UI3Theme.stroke("focus"),
		UI3Theme.color("focus_ring"), m))
	b.set_meta("selected", selected)


## `.plate.s-sec`: padding 16 / 20, gap 8, a t_title heading. Returns {plate, body (VBox)}.
static func section(title: String) -> Dictionary:
	var p := PanelContainer.new()
	p.name = SECTION_NAMES.get(title, "Section" + title.replace(" ", ""))
	p.theme = UI3Theme.get_theme()
	var sb := PanelParts.plate_box("l", 0)
	sb.content_margin_left = UI3Theme.space("20")
	sb.content_margin_right = UI3Theme.space("20")
	sb.content_margin_top = UI3Theme.space("16")
	sb.content_margin_bottom = UI3Theme.space("16")
	p.add_theme_stylebox_override("panel", sb)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	p.add_child(v)
	var t := Ui5Text.label(title, "text_title", "text", true)
	t.name = "Heading"
	v.add_child(t)
	return {"plate": p, "body": v}


## `.s-row`: min-h settings_row_h, padding 8 / 16, radius m, plate_raised, gap 16. `txt` is the left VBox (label + muted
## body, wraps). Returns {row, h (HBox), txt (VBox), title (Label), desc (Label or null)}.
static func row(node_name: String, title := "", desc := "") -> Dictionary:
	var p := PanelContainer.new()
	p.name = node_name
	p.theme = UI3Theme.get_theme()
	p.add_theme_stylebox_override("panel", PanelParts.cell_box(UI3Theme.space("8"), UI3Theme.space("16"), "m"))
	p.custom_minimum_size.y = UI3Theme.size_of("settings_row_h")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(h)
	var txt := VBoxContainer.new()
	txt.name = "Txt"
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	txt.add_theme_constant_override("separation", 0)
	h.add_child(txt)
	var tl: Label = null
	var dl: Label = null
	if title != "":
		tl = Ui5Text.label(title, "text_body", "text", true)
		tl.name = "Label"
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.add_child(tl)
	if desc != "":
		dl = Ui5Text.label(desc, "text_body", "text_muted")
		dl.name = "Desc"
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		txt.add_child(dl)
	return {"row": p, "h": h, "txt": txt, "title": tl, "desc": dl}


## `.key-btn`: min-w key_btn_w (grows to fit the text, never clipped), h btn_m, radius m, chip fill, 2 px plate_rim ring.
## `on` (waiting for a key) = 3 px accent ring and accent text.
static func key_button(text: String) -> Button:
	var b := Button.new()
	b.name = "KeyButton"
	b.text = text
	b.clip_text = false
	b.theme = UI3Theme.get_theme()
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	var f := UI3Theme.get_theme().get_font("font", "LabelDisplay")
	if f != null:
		b.add_theme_font_override("font", f)
	set_key_on(b, false)
	return b


static func set_key_on(b: Button, on: bool) -> void:
	b.custom_minimum_size = Vector2(UI3Theme.size_of("key_btn_w"), UI3Theme.size_of("btn_m"))
	var col := UI3Theme.color("accent") if on else UI3Theme.color("text")
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, col)
	var ring := 3 if on else UI3Theme.stroke("hairline")
	var m := Vector4(UI3Theme.space("16"), 0, UI3Theme.space("16"), 0)
	var rc := UI3Theme.color("accent") if on else UI3Theme.color("plate_rim")
	for st in ["normal", "pressed", "hover"]:
		b.add_theme_stylebox_override(st, UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("m"), ring, rc, m))
	b.add_theme_stylebox_override("focus", UI3Theme.flat(Color.TRANSPARENT, UI3Theme.radius("m"), UI3Theme.stroke("focus"),
		UI3Theme.color("focus_ring"), m))
	b.set_meta("capturing", on)


## Group heading in the shortcut list (`.key-grp`): text_key Rowdies, tracking, muted.
static func group_label(text: String) -> Label:
	var l := Ui5Text.label(text.to_upper(), "text_key", "text_muted", true)
	l.name = "KeyGroup"
	return l


## Right-hand cell: "On" / "Off" word + Ui5Switch (the word is part of the setting, not decoration).
static func switch_cell(on: bool) -> Dictionary:
	var h := HBoxContainer.new()
	h.name = "SwitchCell"
	h.add_theme_constant_override("separation", UI3Theme.space("8"))
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var word := Ui5Text.label("On" if on else "Off", "text_body", "text", true)
	word.name = "State"
	h.add_child(word)
	var sw := Ui5Switch.new()
	sw.setup(on)
	h.add_child(sw)
	sw.toggled.connect(func(v: bool) -> void: word.text = "On" if v else "Off")
	return {"cell": h, "switch": sw, "word": word}


## Right-hand cell: Ui5Slider (300, HTML .s-row .slider) + "80%" value (56 wide, right aligned).
static func slider_cell(value: float) -> Dictionary:
	var h := HBoxContainer.new()
	h.name = "SliderCell"
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sl := Ui5Slider.new()
	sl.setup(value, 0.0, 1.0, 0.05, 300)
	h.add_child(sl)
	var v := Ui5Text.label("%d%%" % roundi(value * 100.0), "text_body", "text", true)
	v.name = "Value"
	v.custom_minimum_size.x = 56
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	h.add_child(v)
	sl.value_changed.connect(func(x: float) -> void: v.text = "%d%%" % roundi(x * 100.0))
	return {"cell": h, "slider": sl, "value": v}


## Round avatar with the first letter of the account name (`.avatar`).
static func avatar(letter: String) -> PanelContainer:
	var d := UI3Theme.size_of("btn_m")
	var p := PanelContainer.new()
	p.name = "Avatar"
	p.custom_minimum_size = Vector2(d, d)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("accent"), UI3Theme.radius("pill")))
	var l := Ui5Text.label(letter.substr(0, 1).to_upper(), "text_title", "text_ink", true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p
