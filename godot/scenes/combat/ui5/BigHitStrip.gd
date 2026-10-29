extends PanelContainer
class_name BigHitStrip
## UI-05 b1 lane C: "Can knock out an Axie" pill under an enemy plate (`.bighit-strip`).
## bighit_strip_h high, radius pill, intent_bighit_bg fill, 2 px intent_bighit_border edge, padding 0 16, gap 8,
## lethal glyph icon_m + t-body text in bighit_text. Hangs under the plate, right-aligned, 8 below it.

var text_label: Label
var _icon: TextureRect
var _style: StyleBoxFlat


func _init() -> void:
	name = "BigHitStrip"
	theme = UI3Theme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = UI3Theme.flat(UI3Theme.color("intent_bighit_bg"), UI3Theme.radius("pill"), UI3Theme.stroke("hairline"),
		UI3Theme.color("intent_bighit_border"))
	add_theme_stylebox_override("panel", _style)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	_icon = HudKit.tex_rect(HudKit.icon("lethal"), UI3Theme.size_of("icon_m"))
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_icon)
	text_label = UI3.label(TranslationServer.translate("Can knock out an Axie"))
	text_label.name = "Text"
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.add_theme_color_override("font_color", UI3Theme.color("bighit_text"))
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_label)
	apply_sizes()


func apply_sizes() -> void:
	var pad := float(UI3Theme.space("16"))
	_style.content_margin_left = pad
	_style.content_margin_right = pad
	custom_minimum_size = Vector2(0, UI3Theme.size_of("bighit_strip_h"))
	(get_node("Row") as HBoxContainer).add_theme_constant_override("separation", UI3Theme.space("8"))
	var ic := UI3Theme.size_of("icon_m")
	_icon.custom_minimum_size = Vector2(ic, ic)
	text_label.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
