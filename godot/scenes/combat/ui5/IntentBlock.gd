extends PanelContainer
class_name IntentBlock
## UI-05 b1 lane C: the "Next" column on the right of an EnemyPlate / BossPlate
## (design/handoffs/ui-05-figma/round-1, `.enemy-intent`).
##
## VBox("Next" t-body muted, GlyphRow(glyph icon_m + IntentValue text_banner), IntentVerb text_body Rowdies),
## `enemy_intent_w` wide, filled with `chip`, flush with the plate's right edge. States: a face (attack, shield, buff,
## weaken, ...), IDLE (intent_idle_bg, glyph at 70 %, "–"), NO MOVE, big hit (intent_bighit_bg).
## Pure view: the number comes from the engine (hud_state().enemy_next) through CombatView, never summed here.

## Face key -> colour token of the verb (the *_text tokens where a face has one, for contrast on `chip`).
const VERB_COLOR := {
	&"attack": "face_attack_text", &"shield": "face_shield", &"heal": "face_heal_text", &"poison": "face_poison",
	&"mana": "face_mana", &"buff": "face_buff", &"weaken": "face_weaken_text", &"summon": "face_summon",
	&"blank": "text_muted",
}

var next_label: Label        ## "Next"
var glyph: TextureRect
var value_label: Label       ## IntentValue
var verb_label: Label        ## IntentVerb
var _style: StyleBoxFlat
var _idle := false
var _big := false
var _boosted := false
var _face: StringName = &"blank"


func _init() -> void:
	name = "IntentBlock"
	theme = UI3Theme.get_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP   # hover = damage preview + tooltip; the plate forwards clicks
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style = UI3Theme.flat(UI3Theme.color("chip"), 0)
	add_theme_stylebox_override("panel", _style)
	var col := VBoxContainer.new()
	col.name = "IntentColumn"
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(col)
	next_label = _label("Next", false)
	next_label.name = "Next"
	next_label.add_theme_color_override("font_color", UI3Theme.color("text_muted"))
	col.add_child(next_label)
	var row := HBoxContainer.new()
	row.name = "GlyphRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	glyph = TextureRect.new()
	glyph.name = "Glyph"
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(glyph)
	value_label = _label("", true)
	value_label.name = "IntentValue"
	# text-shadow 0 3px 0 plate_ink: a hard drop under the number, no blur.
	value_label.add_theme_color_override("font_shadow_color", UI3Theme.color("plate_ink"))
	value_label.add_theme_constant_override("shadow_offset_x", 0)
	value_label.add_theme_constant_override("shadow_offset_y", 3)
	value_label.add_theme_constant_override("shadow_outline_size", 0)
	row.add_child(value_label)
	verb_label = _label("", true)
	verb_label.name = "IntentVerb"
	col.add_child(verb_label)
	apply_sizes()
	_paint()


func _label(text: String, display: bool) -> Label:
	var l := UI3.label(text, "LabelDisplay" if display else "LabelMuted")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Every size from tokens. Called again when the window scale changes (1280: the 14 px text floor).
func apply_sizes() -> void:
	custom_minimum_size = Vector2(UI3Theme.size_of("enemy_intent_w"), 0)
	var sp := float(UI3Theme.space("8"))
	_style.content_margin_top = sp
	_style.content_margin_bottom = sp
	var col := get_node("IntentColumn") as VBoxContainer
	col.add_theme_constant_override("separation", UI3Theme.space("4"))
	(col.get_node("GlyphRow") as HBoxContainer).add_theme_constant_override("separation", UI3Theme.space("4"))
	var ic := UI3Theme.size_of("icon_m")
	glyph.custom_minimum_size = Vector2(ic, ic)
	EnemyPlate.set_text_size(next_label, "text_body", false, 1.35)   # t-body
	EnemyPlate.set_text_size(value_label, "text_banner", true, 1.0)  # .num: Rowdies banner / 1
	EnemyPlate.set_text_size(verb_label, "text_body", true, 1.0)     # .verb: Rowdies body / 1


## Inner corners on the plate side are square; the outer right corners follow the plate (radius l minus its border),
## so the chip fill does not poke out of the rounded plate.
func set_outer_radius(r: int) -> void:
	_style.corner_radius_top_right = maxi(r, 0)
	_style.corner_radius_bottom_right = maxi(r, 0)


## Paint one intent. `show` false = NO MOVE; a blank face = IDLE. `face` is the game face type ("dmg", "debuff", ...).
func set_intent(show: bool, face_type: String, num: int, verb: String, big: bool, boosted: bool, acting: bool) -> void:
	_big = big
	_boosted = boosted
	_idle = (not show) or CombatLabels.is_blank_intent(face_type)
	_face = &"blank" if _idle else UI3.face_key(face_type)
	next_label.text = TranslationServer.translate("Next")
	if _idle:
		glyph.texture = UI3.icon("face_blank")
		value_label.text = "–"
		verb_label.text = "NO MOVE" if not show else "IDLE"
	else:
		glyph.texture = UI3.icon(String(UI3.FACE_ICON.get(_face, "face_blank")))
		value_label.text = str(num)
		verb_label.text = "ACTING" if acting else verb
	_paint()


func is_idle() -> bool:
	return _idle


func _paint() -> void:
	if _idle:
		_style.bg_color = UI3Theme.color("intent_idle_bg")
		glyph.modulate.a = 0.7
		value_label.add_theme_color_override("font_color", UI3Theme.color("category_chip"))
		verb_label.add_theme_color_override("font_color", UI3Theme.color("text_muted"))
		return
	_style.bg_color = UI3Theme.color("intent_bighit_bg") if _big else UI3Theme.color("chip")
	glyph.modulate.a = 1.0
	value_label.add_theme_color_override("font_color", UI3Theme.color("accent") if _boosted else UI3Theme.color("text"))
	verb_label.add_theme_color_override("font_color", UI3Theme.color(String(VERB_COLOR.get(_face, "text_muted"))))
