class_name Ui5ListRow
extends PanelContainer
## UI-05 ListRow (meta1 .mrow / .lbr): bg btn_secondary, radius l, padding 8 / 16, min-h = mission_row_h. Variant &"leader"
## (.lbr, leaderboard): radius m, padding 0 / 16, min-h lb_row_l_h. Selected = ring of stroke("selected") in `selected`;
## locked = alpha 0.55 (still clickable so the detail plate can say why). Nothing selected by default. Signal pressed on
## click / Space / Enter.
## Build: var r := Ui5ListRow.new(); r.setup(title, sub, right, &"mission")

signal pressed

var state := &"normal"
var variant := &"mission"
var title_label: Label
var sub_label: Label
var right_label: Label


func setup(title: String, sub := "", right := "", row_variant := &"mission") -> void:
	name = "ListRow"
	theme = UI3Theme.get_theme()
	variant = row_variant
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
	title_label = Ui5Text.label(title, "text_title", "text", true)
	title_label.name = "Title"
	title_label.clip_text = true
	col.add_child(title_label)
	sub_label = Ui5Text.label(sub, "text_body", "text_muted")
	sub_label.name = "Sub"
	sub_label.visible = sub != ""
	col.add_child(sub_label)
	right_label = Ui5Text.label(right, "text_body", "text_muted")
	right_label.name = "Right"
	right_label.visible = right != ""
	row.add_child(right_label)
	refresh()
	set_state(&"normal")


func refresh() -> void:
	custom_minimum_size = Vector2(0, UI3Theme.size_of("lb_row_l_h" if variant == &"leader" else "mission_row_h"))


func set_state(s: StringName) -> void:
	state = s
	var leader := variant == &"leader"
	var ring := (3 if leader else UI3Theme.stroke("selected")) if s == &"selected" else 0
	var pv := 0 if leader else UI3Theme.space("8")
	add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("btn_secondary"), UI3Theme.radius("m" if leader else "l"), ring,
		UI3Theme.color("selected"), Vector4(UI3Theme.space("16"), pv, UI3Theme.space("16"), pv)))
	modulate = Color(1, 1, 1, 0.55) if s == &"locked" else Color.WHITE


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
	elif e is InputEventKey and e.pressed and (e.keycode == KEY_SPACE or e.keycode == KEY_ENTER):
		pressed.emit()
		accept_event()
