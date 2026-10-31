class_name Ui5SaveCard
extends PanelContainer
## UI-05 SaveCard (meta1 .save-card): bg plate_raised, radius l, padding 16, gap 8. Children in order: Title (Rowdies), Sub
## (muted line right after it, e.g. "On this browser"), then kv rows (bg chip, min-h btn_s, padding 8 / 12, radius s, label
## text_body, value Rowdies). Values come from the save summary, never literals. set_picked() draws the selected ring.

signal pressed

var picked := false


## stats: Array of [label, value] strings.
func setup(title: String, sub: String, stats: Array) -> void:
	name = "SaveCard"
	theme = UI3Theme.get_theme()
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var col := VBoxContainer.new()
	col.name = "Col"
	col.add_theme_constant_override("separation", UI3Theme.space("8"))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var t := Ui5Text.label(title, "text_title", "text", true)
	t.name = "Title"
	col.add_child(t)
	var sv := Ui5Text.label(sub, "text_body", "text_muted")
	sv.name = "Sub"
	col.add_child(sv)
	for s in stats:
		var kv := PanelContainer.new()
		kv.name = "Kv"
		kv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kv.custom_minimum_size.y = UI3Theme.size_of("btn_s")
		kv.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("s"), 0, Color.TRANSPARENT,
			Vector4(UI3Theme.space("12"), UI3Theme.space("8"), UI3Theme.space("12"), UI3Theme.space("8"))))
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", UI3Theme.space("12"))
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		kv.add_child(r)
		var k := Ui5Text.label(String(s[0]), "text_body", "text")
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(k)
		var v := Ui5Text.label(String(s[1]), "text_body", "text", true)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.add_child(v)
		col.add_child(kv)
	set_picked(false)


func set_picked(on: bool) -> void:
	picked = on
	var p := UI3Theme.space("16")
	add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("l"),
		UI3Theme.stroke("selected") if on else 0, UI3Theme.color("selected"), Vector4(p, p, p, p)))


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
	elif e is InputEventKey and e.pressed and (e.keycode == KEY_SPACE or e.keycode == KEY_ENTER):
		pressed.emit()
		accept_event()
