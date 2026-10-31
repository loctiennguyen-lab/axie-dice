class_name Ui5SaveCard
extends PanelContainer
## UI-05 SaveCard (Choose save / Move progress): title, stat rows (label muted left, value right) and a "Saved …" line.
## Values come from the save summary, never literals. set_picked() draws the selected ring. Signal pressed on click.

signal pressed

var picked := false


## stats: Array of [label, value] strings. saved: "Saved 3 hours ago" (already built by the caller).
func setup(title: String, stats: Array, saved: String) -> void:
	name = "SaveCard"
	theme = UI3Theme.get_theme()
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var col := VBoxContainer.new()
	col.name = "Col"
	col.add_theme_constant_override("separation", UI3Theme.space("8"))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var t := Ui5MetaTok.text(title, "text_title", "text", true)
	t.name = "Title"
	col.add_child(t)
	for s in stats:
		var r := HBoxContainer.new()
		r.name = "Stat"
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var k := Ui5MetaTok.text(String(s[0]), "text_body", "text_muted")
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(k)
		var v := Ui5MetaTok.text(String(s[1]), "text_body", "text", true)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.add_child(v)
		col.add_child(r)
	var sv := Ui5MetaTok.text(saved, "text_body", "text_muted")
	sv.name = "Saved"
	col.add_child(sv)
	set_picked(false)


func set_picked(on: bool) -> void:
	picked = on
	var p := UI3Theme.space("16")
	add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("l"),
		UI3Theme.stroke("selected") if on else UI3Theme.stroke("rim"),
		UI3Theme.color("selected_outline") if on else UI3Theme.color("plate_rim"), Vector4(p, p, p, p)))


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
	elif e is InputEventKey and e.pressed and (e.keycode == KEY_SPACE or e.keycode == KEY_ENTER):
		pressed.emit()
		accept_event()
