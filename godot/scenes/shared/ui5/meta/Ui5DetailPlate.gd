class_name Ui5DetailPlate
extends PanelContainer
## UI-05 DetailPlate (data-name "DetailPlate", meta1 .detail): right-hand plate of a list screen. Padding space-16, gap 8.
## Col = DetailScroll (Title + Body, scrolls) over Footer (outside the scroll, pinned to the bottom, holds the primary).
## Empty state (nothing picked): Title "Pick a …" top-left (Rowdies text_screen_title), Body muted and growing, then the wide
## primary DISABLED with its reason. Item state: show_item(title), add_line(), set_primary(text, reason).
## Width = the screen's *_detail_w token: var d := Ui5DetailPlate.new(); d.setup("mission_detail_w", tr("Pick a tier"), tr("..."), tr("Pick a tier first"))

var title: Label
var body: VBoxContainer
var scroll: ScrollContainer
var footer: VBoxContainer
var primary: Button = null
var _w_token := ""
var _empty := true
var _empty_title := ""
var _empty_body := ""
var _empty_reason := ""


func setup(width_token: String, empty_title: String, empty_body := "", empty_reason := "") -> void:
	name = "DetailPlate"
	theme = UI3Theme.get_theme()
	_w_token = width_token
	_empty_title = empty_title
	_empty_body = empty_body
	_empty_reason = empty_reason
	add_theme_stylebox_override("panel", Ui5PlateBox.plate(UI3Theme.space("16")))
	var col := VBoxContainer.new()
	col.name = "Col"
	col.add_theme_constant_override("separation", UI3Theme.space("8"))
	add_child(col)
	scroll = ScrollContainer.new()
	scroll.name = "DetailScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.name = "ScrollCol"
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", UI3Theme.space("8"))
	scroll.add_child(inner)
	title = Ui5Text.label("", "text_screen_title", "text", true)
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	inner.add_child(title)
	body = VBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override("separation", UI3Theme.space("8"))
	inner.add_child(body)
	footer = VBoxContainer.new()
	footer.name = "Footer"
	footer.add_theme_constant_override("separation", UI3Theme.space("8"))
	col.add_child(footer)
	refresh()
	show_empty()


func refresh() -> void:
	custom_minimum_size = Vector2(UI3Theme.size_of(_w_token), 0)


func is_empty() -> bool:
	return _empty


## Nothing picked. Empty args fall back to the texts given in setup().
func show_empty(t := "", b := "", reason := "") -> void:
	_empty = true
	_reset(t if t != "" else _empty_title)
	var bl := add_line(b if b != "" else _empty_body, "text_muted")
	bl.visible = bl.text != ""
	var r := reason if reason != "" else _empty_reason
	if r != "":
		set_primary(r, r)


## Something picked: title set, body and footer emptied (fill them next).
func show_item(title_text: String) -> void:
	_empty = false
	_reset(title_text)


## A body line (text_body, wraps). Returns the Label.
func add_line(t: String, color_token := "text") -> Label:
	var l := Ui5Text.label(t, "text_body", color_token)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(l)
	return l


## The wide primary at the foot (min-h btn_l, text_title, wraps, padding 8 / 16). reason != "" = disabled and says why.
func set_primary(text: String, reason := "") -> Button:
	for c in footer.get_children():
		footer.remove_child(c)
		c.queue_free()
	var b := UI3.button(text, &"primary", &"L")
	b.name = "PrimaryButton"
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_title"))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = UI3Theme.size_of("btn_l")
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := b.get_theme_stylebox(st) as StyleBoxFlat
		if sb != null:
			var d := sb.duplicate() as StyleBoxFlat
			d.content_margin_left = UI3Theme.space("16")
			d.content_margin_right = UI3Theme.space("16")
			d.content_margin_top = UI3Theme.space("8")
			d.content_margin_bottom = UI3Theme.space("8")
			b.add_theme_stylebox_override(st, d)
	footer.add_child(b)
	primary = b
	if reason != "":
		Ui5DisabledReason.apply(b, reason)
	return b


func _reset(t: String) -> void:
	title.text = t
	primary = null
	for n in [body, footer]:
		for c in n.get_children():
			n.remove_child(c)
			c.queue_free()
