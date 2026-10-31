class_name Ui5Text
extends RefCounted
## UI-05 meta kit: label helper. Size and colour are tokens (UI3Theme), Rowdies when `display`, vertically centred, mouse ignored.

static func label(t: String, size_token := "text_body", color_token := "text", display := false) -> Label:
	var l := UI3.label(t, "LabelDisplay" if display else "")
	l.add_theme_font_size_override("font_size", UI3Theme.size_of(size_token))
	l.add_theme_color_override("font_color", UI3Theme.color(color_token))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
