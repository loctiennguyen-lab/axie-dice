extends Button
## UI-05 ContinueButton (30-defeat): primary L button whose caption and CostChip sit together in the middle,
## gap 12 ("the price appears once, inside Continue"). The Button's own `text` stays empty while the caption row
## shows; `show_reason()` turns it into a plain disabled button that says why ("Need 90 Gem"), without the chip.
## Build: `var b := CostButton.new(); b.setup("Continue", &"gem", 90)`.

const PanelParts := preload("res://scenes/combat/ui5/PanelParts.gd")

var caption := ""
var reason := ""
var chip: PanelContainer = null
var _row: HBoxContainer = null
var _cap: Label = null


## kind: &"gem" (price in Gem, violet chip) or &"free" (the word Free on dark ink). amount ignored for free.
func setup(cap: String, kind: StringName, amount: int) -> void:
	theme = UI3Theme.get_theme()
	theme_type_variation = "ButtonPrimaryL"
	var min_h := get_theme_constant("min_height", theme_type_variation)
	custom_minimum_size = Vector2(UI3Theme.size_of("hit_min"), maxi(min_h, UI3Theme.size_of("btn_l")))
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	text = ""
	_row = HBoxContainer.new()
	_row.name = "CaptionRow"
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", UI3Theme.space("12"))
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	_cap = PanelParts.text("", "text_screen_title", "accent_text", true)
	_cap.name = "Caption"
	_cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(_cap)
	chip = PanelParts.cost_chip(kind, amount)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(chip)
	set_caption(cap)
	# The pressed style drops the box by (lip - lip_pressed); move the caption row with it.
	button_down.connect(func() -> void: _row.position.y = _press_drop())
	button_up.connect(func() -> void: _row.position.y = 0.0)


## Caption next to the chip ("Continue", "Reviving…").
func set_caption(cap: String) -> void:
	caption = cap
	if _cap != null:
		_cap.text = cap


## Disabled, the label says why, no chip (design: "Need 90 Gem").
func show_reason(why: String) -> void:
	reason = why
	disabled = true
	text = why
	if _row != null:
		_row.visible = false


func _press_drop() -> float:
	var sb := get_theme_stylebox("pressed") as StyleBoxFlat
	return sb.expand_margin_bottom if sb != null else 0.0
