class_name Ui5Toast
extends RefCounted
## UI-05 Toast (components-land--sheet): pill plate with a ToneDisc and one line (text_body). Max width toast_max_w
## (the text wraps beyond it). While the offline banner is up the toast stack starts at `top_y(true)` (toast_under_banner)
## instead of the screen margin. Text comes from the caller (already localized).

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


static func make(text: String, tone := &"ok") -> PanelContainer:
	var pad := UI3Theme.space("8")
	var box := UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("pill"), UI3Theme.stroke("rim"),
		UI3Theme.color("plate_rim"), Vector4(pad, pad, UI3Theme.space("24"), pad), PanelParts.lip(UI3Theme.color("plate_ink")))
	var p := PanelParts.panel(box, "Toast")
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(row)
	row.add_child(Ui5ToneDisc.make(tone))
	var l := Ui5MetaTok.text(text, "text_body", "text")
	l.name = "Text"
	var f := l.get_theme_font("font")
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI3Theme.size_of("text_body")).x
	var avail := float(Ui5MetaTok.px("toast_max_w", 860, 860) - Ui5ToneDisc.diameter() - 2 * pad - UI3Theme.space("24") - UI3Theme.space("12"))
	if w > avail:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = avail
	row.add_child(l)
	return p


## Top of the toast stack: the screen margin, or toast_under_banner while the offline banner shows.
static func top_y(banner_up: bool) -> int:
	if banner_up:
		return Ui5MetaTok.px("toast_under_banner", 140, 192)
	return UI3Theme.space("screen_margin")
