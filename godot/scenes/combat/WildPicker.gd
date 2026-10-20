class_name WildPicker
extends Control
## Depth v4 3 (Mat Tam / Wild face): the 6 part chips shown under the pick. Fixed SLOT_ORDER, never re-sorted.
## Each chip: part word + the engine's own preview ("-> SET OF 3 x1.4" / "no change"). The best result gets a star.
## One click confirms; no second box. CombatView feeds it from CombatEngine.preview_wild().

signal picked(slot: int)

const CHIP_W := 168.0
const CHIP_H := 64.0
const GAP := 8.0

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
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	for i in 6:
		var b := UI3.button("", &"secondary", &"S")
		b.name = "Chip%d" % i
		b.add_theme_font_size_override("font_size", 18)
		b.custom_minimum_size = Vector2(CHIP_W, CHIP_H)
		b.size = Vector2(CHIP_W, CHIP_H)
		b.position = Vector2(i * (CHIP_W + GAP), 28.0)
		var slot := i
		b.pressed.connect(func(): picked.emit(slot))
		add_child(b)
		chips.append(b)
	size = Vector2(6 * CHIP_W + 5 * GAP, 28.0 + CHIP_H)
	hint.position = Vector2(0, 0)
	hint.size = Vector2(size.x, 26.0)


## rows: 6 x {ok:bool, label:String ("→ SET OF 3 ×1.4" / "no change" / reason), best:bool}.
func update(rows: Array) -> void:
	for i in 6:
		var r: Dictionary = rows[i]
		var b := chips[i]
		b.text = "%s%s\n%s" % ["★ " if bool(r.get("best", false)) else "", V4Ui.part_name(i), String(r.get("label", ""))]
		b.disabled = not bool(r.get("ok", false))
		b.tooltip_text = String(r.get("label", ""))
