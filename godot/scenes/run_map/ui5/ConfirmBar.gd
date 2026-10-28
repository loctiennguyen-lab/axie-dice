extends PanelContainer
## UI-05 ConfirmBar (31-reward--chaos-confirm): one pill plate that replaces the reward footer.
## "This lasts the whole run. Take it?" (Rowdies 24) + BackButton (secondary, gets focus) + TakeItButton (the one
## primary). Padding 16 16 16 24, gap 16. Esc = Back (the bar is a confirm; the owner decides what Back does).

signal back_pressed
signal confirmed

const PanelParts := preload("res://scenes/combat/ui5/PanelParts.gd")

var back_button: Button
var take_button: Button


func setup(question: String, back_text: String, take_text: String) -> void:
	theme = UI3Theme.get_theme()
	name = "ConfirmBar"
	var box := PanelParts.plate_box("pill")
	box.content_margin_left = UI3Theme.space("24")
	box.content_margin_right = UI3Theme.space("16")
	box.content_margin_top = UI3Theme.space("16")
	box.content_margin_bottom = UI3Theme.space("16")
	add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(row)
	var q := PanelParts.text(question, "text_title", "text", true)
	q.name = "Question"
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(q)
	back_button = PanelParts.button(back_text, &"secondary", &"M")
	back_button.name = "BackButton"
	back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(func() -> void: back_pressed.emit())
	row.add_child(back_button)
	take_button = UI3.button(take_text, &"primary", &"L")
	take_button.name = "TakeItButton"
	take_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	take_button.pressed.connect(func() -> void: confirmed.emit())
	row.add_child(take_button)
	# Focus stays inside the bar: Back <-> Take it.
	back_button.focus_neighbor_right = back_button.get_path_to(take_button)
	take_button.focus_neighbor_left = take_button.get_path_to(back_button)


func _ready() -> void:
	back_button.grab_focus.call_deferred()   # design: Back has focus, Take it is the one primary


func _unhandled_key_input(ev: InputEvent) -> void:
	if is_visible_in_tree() and ev.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_pressed.emit()
