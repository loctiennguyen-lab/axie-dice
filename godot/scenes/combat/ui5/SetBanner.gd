class_name SetBanner
extends PanelContainer
## UI-05 b1 lane B: one pill per live SET in the SetBanners row above the dice tray (README "Update · DieCard parts and SETs",
## frames 02-combat--set-3 / --set-4, components--dice). In the SET's colour (set_a lemon, set_b mint):
##   part glyph · "SET OF 4" · ×2.2 chip · part word · OVERCAST mark while the SET is overcast.
## set_banner_h high, pill, hard lip. The ×M is the engine's group value (SetPreview.group_m100). Never blocks clicks
## (PASS: the tooltip shows; nothing under it needs the click).

var text := ""                       ## "SET OF 4 ×2.2 · Mouth" (tests, log)
var label := ""                      ## "SET OF 4 ×2.2" (V4Ui.set_label, the pre-UI-05 tray label)
var key := Vector3i(-1, 0, 0)        ## (part, size, m100)
var colour_key := "a"
var _glyph: TextureRect
var _size_label: Label
var _mult: PanelContainer
var _mult_label: Label
var _part_label: Label
var _oc_mark: PanelContainer


func _init() -> void:
	name = "SetBanner"
	theme = UI3Theme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size.y = UI3Theme.size_of("set_banner_h")
	var box := HBoxContainer.new()
	box.name = "Box"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", UI3Theme.space("8"))
	add_child(box)
	_glyph = TextureRect.new()
	_glyph.name = "Glyph"
	var g := UI3Theme.size_of("icon_m")
	_glyph.custom_minimum_size = Vector2(g, g)
	_glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_glyph)
	_size_label = _label("SizeLabel", "LabelDisplay", box)
	_mult = PanelContainer.new()
	_mult.name = "Mult"
	_mult.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mult.custom_minimum_size.y = UI3Theme.size_of("keycap_h")
	_mult.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(_mult)
	_mult_label = _label("MultLabel", "LabelDisplay", _mult)
	_part_label = _label("PartWord", "", box)
	_oc_mark = DieCard.make_mark(&"overcast", false)
	_oc_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_oc_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_oc_mark.visible = false
	box.add_child(_oc_mark)


func _label(nm: String, variation: String, parent: Control) -> Label:
	var l := UI3.label("", variation)
	l.name = nm
	l.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


## "SET OF 4 ×2.2 · Mouth".
static func text_for(n: int, m100: int, part_index: int) -> String:
	return "%s · %s" % [V4Ui.set_label(n, m100), part_word(part_index)]


## "Mouth" (the tray word, title case; the glyph colour carries the class).
static func part_word(part_index: int) -> String:
	return V4Ui.part_name(part_index).capitalize()


## Paints the banner for engine group (part, size) with group multiplier `m100`, colour key "a" / "b".
func setup(part_index: int, n: int, m100: int, ckey: String, tex: Texture2D, overcast: bool, tip := "") -> void:
	colour_key = ckey
	key = Vector3i(part_index, n, m100)
	label = V4Ui.set_label(n, m100)
	text = text_for(n, m100, part_index)
	var fill := UI3Theme.color(SetPreview.colour_token(ckey))
	var ink := UI3Theme.color("set_text")
	var sp := UI3Theme.space("8")
	var lip := DieCard._shadow_px("lip", 6)
	add_theme_stylebox_override("panel", UI3Theme.flat(fill, UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(sp, 0, UI3Theme.space("16"), 0), {"y": lip, "color": UI3Theme.color("plate_ink")}))
	_mult.add_theme_stylebox_override("panel", UI3Theme.flat(ink, UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(sp, 0, sp, 0)))
	var body := UI3Theme.size_of("text_body")   # re-applied every setup: the 1280 text floor follows a live resize
	for l in [_size_label, _mult_label, _part_label]:
		(l as Label).add_theme_font_size_override("font_size", body)
	DieCard.size_mark(_oc_mark)
	custom_minimum_size.y = UI3Theme.size_of("set_banner_h")
	_glyph.texture = tex
	_glyph.visible = tex != null
	_size_label.text = "%s %d" % [TranslationServer.translate("SET OF"), n]
	_size_label.add_theme_color_override("font_color", ink)
	_mult_label.text = V4Ui.mult_text(m100)
	_mult_label.add_theme_color_override("font_color", fill)
	_part_label.text = part_word(part_index)
	_part_label.add_theme_color_override("font_color", ink)
	_oc_mark.visible = overcast
	UI3Tooltip.bind(self, tip if tip != "" else text)
