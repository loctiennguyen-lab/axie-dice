class_name Ui5StoreParts
extends RefCounted
## UI-05 Store pieces (ui05-meta2-screens.html, frames 19-store*): StoreTile button (.stile), art box, wide GemCost,
## OwnedButton, GiftStrip plate, Gem-icon cluster for a secondary button. Sizes / colours are tokens; no prices here.
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


## `.stile`: toggle button styled as a plate, selected = ring. Content goes into the returned button's "Col" VBox.
static func tile(node_name: String, on: bool, strip: Color) -> Button:
	var b := Button.new()
	b.name = node_name
	b.theme = UI3Theme.get_theme()
	b.toggle_mode = true
	b.button_pressed = on
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size.y = UI3Theme.size_of("store_tile_h")
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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
	var v := VBoxContainer.new()
	v.name = "Col"
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = UI3Theme.space("16")
	v.offset_right = -UI3Theme.space("16")
	v.offset_top = UI3Theme.space("12")
	v.offset_bottom = -UI3Theme.space("16")
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	b.add_child(v)
	var s := ColorRect.new()
	s.name = "Strip"
	s.custom_minimum_size.y = 4
	s.color = strip
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(s)
	return b


## Chip-coloured art box that grows; `art` (may be null) is centred in it.
static func art_box(art: Control, min_h := 0) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "ArtBox"
	p.theme = UI3Theme.get_theme()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.clip_contents = true
	p.custom_minimum_size.y = min_h
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("m")))
	if art != null:
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		p.add_child(art)
	return p


static func gem_art(px: int) -> TextureRect:
	var t := PanelParts.icon_rect(UI3.currency_icon("cur_gem", px), px, "GemArt")
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## GemCost chip stretched to the tile width, btn_s high, radius m (.gem-cost).
static func gem_cost_wide(amount: int) -> PanelContainer:
	var c := Ui5GemCost.make(amount)
	c.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := c.get_theme_stylebox("panel") as StyleBoxFlat
	if sb != null:
		var d := sb.duplicate() as StyleBoxFlat
		var r := UI3Theme.radius("m")
		d.set_corner_radius_all(r)
		c.add_theme_stylebox_override("panel", d)
	return c


## Disabled secondary S "Owned" at the foot of a tile (mouse passes through so the tile still selects).
static func owned_button() -> Button:
	var b := UI3.button("Owned", &"secondary", &"S")
	b.name = "OwnedButton"
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


## `.gift-strip`: plate holding the one-line text (+ optional muted note) and the gift button on the right.
static func gift_strip(text: String, note: String, button: Button) -> PanelContainer:
	var pad := Vector4(UI3Theme.space("16"), UI3Theme.space("12"), UI3Theme.space("12"), UI3Theme.space("12"))
	var p := PanelParts.panel(UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("l"), UI3Theme.stroke("rim"),
		UI3Theme.color("plate_rim"), pad, PanelParts.lip(UI3Theme.color("plate_ink"))), "GiftStrip")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(h)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(v)
	var l := Ui5Text.label(text, "text_body", "text")
	l.name = "GiftText"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	if note != "":
		var n := Ui5Text.label(note, "text_body", "text_muted")
		n.name = "GiftNote"
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(n)
	h.add_child(button)
	return p


## [Gem icon][text] as one centred HBox over a secondary button (Button.icon would overlap the centred text).
static func gem_cluster(b: Button) -> void:
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(c, Color.TRANSPARENT)
	var h := HBoxContainer.new()
	h.name = "GemCluster"
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	var ic := PanelParts.icon_rect(UI3.currency_icon("cur_gem", UI3Theme.size_of("icon_s")), UI3Theme.size_of("icon_s"))
	ic.name = "GemIcon"
	h.add_child(ic)
	var l := Ui5Text.label(b.text, "text_body", "text", true)
	l.name = "GemText"
	h.add_child(l)
	b.add_child(h)
