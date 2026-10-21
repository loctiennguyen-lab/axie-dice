class_name WildPicker
extends Control
## Depth v4 3 (Mat Tam / Wild face): the 6 part chips shown under the pick. Fixed SLOT_ORDER, never re-sorted.
## Each chip: part word + the engine's own preview ("-> SET OF 3 x1.4" / "no change"). The best result gets a star.
## One click confirms; no second box. CombatView feeds it from CombatEngine.preview_wild().

signal picked(slot: int)

const CHIP_W := 236.0
const CHIP_H := 72.0
const GAP := 16.0
const GLYPH := 36.0

var chips: Array[Button] = []
var hint: Label


func _init() -> void:
	name = "WildPicker"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint = UI3.label(TranslationServer.translate("Pick a part for this die"), "LabelMuted")
	hint.name = "Hint"
	hint.add_theme_color_override("font_color", UI3Theme.color("text"))
	hint.add_theme_color_override("font_outline_color", UI3Theme.color("panel"))
	hint.add_theme_constant_override("outline_size", 4)
	hint.add_theme_font_size_override("font_size", 18)
	var hbg := UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("s"))
	hbg.bg_color.a = 0.94
	hint.add_theme_stylebox_override("normal", hbg)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	for i in 6:
		var b := UI3.button("", &"secondary", &"S")
		b.name = "Chip%d" % i
		b.add_theme_font_size_override("font_size", 18)
		b.custom_minimum_size = Vector2(CHIP_W, CHIP_H)
		b.size = Vector2(CHIP_W, CHIP_H)
		b.position = Vector2(i * (CHIP_W + GAP), 32.0)
		for st in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			var sbx := UI3Theme.get_theme().get_stylebox(st, "ButtonSecondaryS")
			if sbx != null:
				var d := sbx.duplicate() as StyleBox
				d.content_margin_left = GLYPH + 16.0   # room for the part glyph
				b.add_theme_stylebox_override(st, d)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true   # a long reason never widens the chip over its neighbour
		var gl := TextureRect.new()
		gl.name = "PartGlyph"
		gl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gl.position = Vector2(8.0, (CHIP_H - GLYPH) * 0.5)
		gl.size = Vector2(GLYPH, GLYPH)
		b.add_child(gl)
		var slot := i
		b.pressed.connect(func(): picked.emit(slot))
		add_child(b)
		chips.append(b)
	size = Vector2(6 * CHIP_W + 5 * GAP, 32.0 + CHIP_H)
	hint.position = Vector2(0, 0)
	hint.size = Vector2(size.x, 28.0)
	hint.size_flags_horizontal = 0


## rows: 6 x {ok:bool, label:String ("→ SET OF 3 ×1.4" / "no change" / reason), best:bool}.
func update(rows: Array) -> void:
	for i in 6:
		var r: Dictionary = rows[i]
		var b := chips[i]
		b.text = "%s%s\n%s" % ["★ " if bool(r.get("best", false)) else "", V4Ui.part_name(i), String(r.get("label", ""))]
		b.disabled = not bool(r.get("ok", false))
		b.tooltip_text = String(r.get("label", ""))
		var gl: TextureRect = b.get_node("PartGlyph")
		gl.texture = r.get("tex", null)
		gl.modulate.a = 0.5 if b.disabled else 1.0
