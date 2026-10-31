class_name Ui5RaidParts
extends RefCounted
## UI-05 Raid pieces (ui05-meta1-screens.html, frames r01-r10): TopPlate (.raid-top), GhostRow (.ghost-row), the
## centred block of EmptyState / FailedState (.center-block) and the InfoLine (.info-line, ToneDisc + text).
## Every size, colour and gap is a token; no text length can move a column (labels are clipped with an ellipsis).
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


## `.raid-top`: plate, padding 16, row gap 16, children top-aligned. Returns {plate, row, txt}: `txt` is the
## expanding text column (PointsLine, RuleLine, InfoLine), buttons are added to `row` after it.
static func top_plate() -> Dictionary:
	var p := PanelParts.panel(PanelParts.plate_box("l", UI3Theme.space("16")), "TopPlate")
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(row)
	var txt := VBoxContainer.new()
	txt.name = "Txt"
	txt.add_theme_constant_override("separation", UI3Theme.space("8"))
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	txt.custom_minimum_size.x = 0
	row.add_child(txt)
	return {"plate": p, "row": row, "txt": txt}


## A wrapping text line in the Txt column (min width 0, so the column width never depends on the text).
static func wrap_label(node_name: String, t: String, size_token: String, color_token: String, display := false) -> Label:
	var l := Ui5Text.label(t, size_token, color_token, display)
	l.name = node_name
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = 0
	return l


## `.info-line`: [ToneDisc] text, gap 8, centred on the disc. Returns the HBox named InfoLine; the label is "InfoText".
static func info_line() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.name = "InfoLine"
	h.add_theme_constant_override("separation", UI3Theme.space("8"))
	h.visible = false
	var t := Ui5Text.label("", "text_body", "text")
	t.name = "InfoText"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.custom_minimum_size.x = 0
	h.add_child(t)
	return h


## Shows `text` on an InfoLine with a fresh ToneDisc of `tone`; empty text hides the line.
static func set_info(line: HBoxContainer, text: String, tone: StringName) -> void:
	var old := line.get_node_or_null("ToneDisc")
	if old != null:
		line.remove_child(old)
		old.queue_free()
	(line.get_node("InfoText") as Label).text = text
	line.visible = text != ""
	if text != "":
		var d := Ui5ToneDisc.make(tone)
		line.add_child(d)
		line.move_child(d, 0)


## `.ghost-row`: raised row, min height raid_row_h, padding 8 8 8 16, gap 16, columns 1.2fr / 3fr / auto.
## Returns {row, name, team, fight}. Both text columns are clipped with an ellipsis, never wider than their share.
static func ghost_row(title: String, team: String) -> Dictionary:
	var box := UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("m"), 0, Color.TRANSPARENT,
		Vector4(UI3Theme.space("16"), UI3Theme.space("8"), UI3Theme.space("8"), UI3Theme.space("8")))
	var p := PanelParts.panel(box, "GhostRow")
	p.custom_minimum_size.y = UI3Theme.size_of("raid_row_h")
	var h := HBoxContainer.new()
	h.name = "Cols"
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(h)
	var nl := Ui5Text.label("", "text_title", "text", true)
	nl.name = "GhostName"
	_column(nl, 1.2)
	h.add_child(nl)
	Ui5Ellipsis.set_text(nl, title)
	var tl := Ui5Text.label("", "text_body", "text_muted")
	tl.name = "GhostTeam"
	_column(tl, 3.0)
	h.add_child(tl)
	Ui5Ellipsis.set_text(tl, team)
	var b := UI3.button("Fight", &"secondary", &"S")
	b.name = "FightButton"
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	b.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	return {"row": p, "name": nl, "team": tl, "fight": b}


static func _column(l: Label, ratio: float) -> void:
	l.clip_text = true
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_stretch_ratio = ratio
	l.custom_minimum_size.x = 0


## `.center-block`: column centred both ways, gap 12, padding 32. Returns {block, col}; `disc` (optional) goes first,
## then the text, then whatever the caller adds (a Retry button).
static func center_block(node_name: String, text: String, tone := &"", with_disc := false) -> Dictionary:
	var box := UI3Theme.flat(Color.TRANSPARENT, 0, 0, Color.TRANSPARENT, Vector4.ONE * UI3Theme.space("32"))
	var p := PanelParts.panel(box, node_name)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.name = "Col"
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(v)
	if with_disc:
		var d := Ui5ToneDisc.make(tone)
		d.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(d)
	var l := Ui5Text.label(text, "text_body", "text")
	l.name = "Text"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 0
	l.size_flags_horizontal = Control.SIZE_FILL
	v.add_child(l)
	return {"block": p, "col": v, "text": l}
