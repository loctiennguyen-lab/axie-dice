class_name Ui5ListRow
extends PanelContainer
## UI-05 ListRow: one selectable row of a list (mission tier, pass level, leaderboard line). Left column = title + optional
## sub line, right = optional text. States: &"normal", &"selected" (selected ring, 3 px), &"locked" (dimmed, still clickable
## so the detail plate can say why). Nothing is selected by default. Signal pressed fires on click / Space / Enter.
## Height = the screen's row token (`h_token`, e.g. mission_row_h) with a fallback value.

signal pressed

var state := &"normal"
var title_label: Label
var sub_label: Label
var right_label: Label
var _h_token := "row"
var _h := 48


func setup(title: String, sub := "", right := "", h_token := "row", h1920 := 48) -> void:
	name = "ListRow"
	theme = UI3Theme.get_theme()
	_h_token = h_token
	_h = h1920
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var col := VBoxContainer.new()
	col.name = "Col"
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	title_label = Ui5MetaTok.text(title, "text_title", "text", true)
	title_label.name = "Title"
	title_label.clip_text = true
	col.add_child(title_label)
	sub_label = Ui5MetaTok.text(sub, "text_body", "text_muted")
	sub_label.name = "Sub"
	sub_label.visible = sub != ""
	col.add_child(sub_label)
	right_label = Ui5MetaTok.text(right, "text_body", "text_muted")
	right_label.name = "Right"
	right_label.visible = right != ""
	row.add_child(right_label)
	refresh()
	set_state(&"normal")


func refresh() -> void:
	custom_minimum_size = Vector2(0, Ui5MetaTok.px(_h_token, _h))


func set_state(s: StringName) -> void:
	state = s
	var border := UI3Theme.stroke("btn") if s == &"selected" else 0
	add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("m"), border,
		UI3Theme.color("selected_outline"), Vector4(UI3Theme.space("16"), UI3Theme.space("8"), UI3Theme.space("16"), UI3Theme.space("8"))))
	modulate = Color(1, 1, 1, 0.6) if s == &"locked" else Color.WHITE


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
	elif e is InputEventKey and e.pressed and (e.keycode == KEY_SPACE or e.keycode == KEY_ENTER):
		pressed.emit()
		accept_event()
