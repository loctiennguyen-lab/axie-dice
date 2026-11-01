class_name LbRow
extends Ui5ListRow
## UI-05 S7a: one leaderboard row (.lbr, data-name Row / PinnedRow). A Ui5ListRow variant &"leader" (lb_row_l_h high, radius m,
## padding 0 / 16) whose content is the column grid of the HTML: cells share the width by ratio, so the layout never depends
## on how long a name is. Nothing is selected by default; grey (cached / locked board) = alpha 0.55 and still clickable.
## The pinned own row (.lbr.pin) is plate_raised with the selected ring and takes no clicks.

var pinned := false


## cells = ready-made Controls, one per column, built by the screen (LbRow.text_cell for text, a NameCell HBox for the
## name + "You" tag). Each carries meta "ratio" = its column's stretch ratio; setup_row lays them out in the "Cells" HBox.
func setup_row(node_name: String, cols: Array, cells: Array) -> void:
	setup("", "", "", &"leader")
	name = node_name
	var old := get_node("Row")
	remove_child(old)
	old.queue_free()
	title_label = null
	sub_label = null
	right_label = null
	var row := HBoxContainer.new()
	row.name = "Cells"
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	for i in cells.size():
		var c: Control = cells[i]
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_stretch_ratio = float(c.get_meta("ratio", 1.0))
		if c is Label:
			c.custom_minimum_size.x = 0
		row.add_child(c)
	UI3.attach_focus_ring(self)


func set_pinned() -> void:
	pinned = true
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("m"), 3,
		UI3Theme.color("selected"), Vector4(UI3Theme.space("16"), 0, UI3Theme.space("16"), 0)))


## Selected = ring; grey = alpha 0.55 (a selected grey row keeps both, like .lbr.is-on.grey).
func set_row_state(selected: bool, grey: bool) -> void:
	set_state(&"selected" if selected else &"normal")
	modulate = Color(1, 1, 1, 0.55) if grey else Color.WHITE


## A text cell: Label that trims with an ellipsis, centred vertically, ratio-sized.
static func text_cell(text: String, ratio: float, size_token := "text_title", color_token := "text", display := true, right := false) -> Label:
	var l := Ui5Text.label(text, size_token, color_token, display)
	l.set_meta("ratio", ratio)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	return l
