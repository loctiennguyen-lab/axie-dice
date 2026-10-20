class_name RerollBar
extends Control
## Depth v4 2.2: the Gamble / Safe pair that replaces the Reroll button while the player picks dice (stage >= 2,
## no free reroll left). Two secondary buttons side by side, a % line above. No confirm box.
## CombatView feeds it through update(); it only emits which mode was pressed (rmode 0 = Gamble, 1 = Safe).

signal chosen(rmode: int)

const BTN_W := 176.0
const GAP := 12.0
const ROW_H := 48.0
const LINE_H := 48.0
const TOTAL_W := BTN_W * 2.0 + GAP

var line: Label
var reason: Label
var gamble_button: Button
var safe_button: Button


func _init() -> void:
	name = "RerollBar"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	line = UI3.label("", "LabelMuted")
	line.name = "Line"
	line.add_theme_color_override("font_color", UI3Theme.color("text"))
	line.add_theme_color_override("font_outline_color", UI3Theme.color("panel"))
	line.add_theme_constant_override("outline_size", 4)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line)
	gamble_button = UI3.button("Gamble", &"secondary", &"S")
	gamble_button.name = "GambleButton"
	safe_button = UI3.button("Safe", &"secondary", &"S")
	safe_button.name = "SafeButton"
	for b in [gamble_button, safe_button]:
		b.add_theme_font_size_override("font_size", 18)
		b.clip_text = true
		b.size = Vector2(BTN_W, ROW_H)
		add_child(b)
	gamble_button.pressed.connect(func(): chosen.emit(0))
	safe_button.pressed.connect(func(): chosen.emit(1))
	size = Vector2(TOTAL_W, LINE_H + 8.0 + ROW_H)
	line.position = Vector2(0, 0)
	line.size = Vector2(TOTAL_W, LINE_H)
	gamble_button.position = Vector2(0, LINE_H + 8.0)
	safe_button.position = Vector2(BTN_W + GAP, LINE_H + 8.0)


## d: gamble_ok, gamble_text, gamble_why, safe_ok, safe_text, safe_why, line (the % / pin / reason text).
func update(d: Dictionary) -> void:
	gamble_button.disabled = not bool(d.get("gamble_ok", false))
	gamble_button.text = String(d.get("gamble_text", "Gamble"))
	gamble_button.tooltip_text = String(d.get("gamble_tip", ""))
	safe_button.disabled = not bool(d.get("safe_ok", false))
	safe_button.text = String(d.get("safe_text", "Safe"))
	safe_button.tooltip_text = String(d.get("safe_tip", ""))
	line.text = String(d.get("line", ""))
	gamble_button.visible = bool(d.get("show_gamble", true))
	if not gamble_button.visible:
		safe_button.position.x = BTN_W + GAP


## Right-aligns the bar to x_right with its button row on `row_y`.
func place(x_right: float, row_y: float) -> void:
	position = Vector2(x_right - TOTAL_W, row_y - LINE_H - 8.0)
