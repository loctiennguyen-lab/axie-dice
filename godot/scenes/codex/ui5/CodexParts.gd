class_name Ui5CodexParts
extends RefCounted
## UI-05 Codex pieces (ui05-meta3-screens.html, frames 29-codex*): header with the three doc tabs inside the title plate,
## plates, book tiles, search hit. Sizes and colours are tokens.
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const DOC := [["codex", "CodexTab", "Codex"], ["guides", "GuidesTab", "Guides"], ["unlocks", "UnlocksTab", "Unlocks"]]


## Moves the shell's tab host into the title plate and fills it with a Ui5TabBar (fit). Other tabs open their scene.
static func header(shell: Dictionary, current: String, hide_currencies := false) -> Ui5TabBar:
	(shell["back"] as Button).name = "BackButton"
	(shell["sub"] as Control).name = "SubLine"
	var hdr := (shell["col"] as Control).get_node("Header")
	if hide_currencies:
		var cur := hdr.find_child("Currencies", true, false)
		if cur != null:
			cur.visible = false
	var hr := shell["header_right"] as Control
	var trow := (shell["sub"] as Control).get_parent()
	hr.get_parent().remove_child(hr)
	hr.name = "Tabs"
	trow.add_child(hr)
	var bar := Ui5TabBar.new()
	var labels: Array = []
	var sel := 0
	for i in DOC.size():
		labels.append(DOC[i][2])
		if DOC[i][0] == current:
			sel = i
	bar.setup(labels, sel, true)
	bar.name = "TabBar"
	hr.add_child(bar)
	for i in DOC.size():
		var b := bar.get_child(i) as Button
		b.name = DOC[i][1]
		if DOC[i][0] != current:
			var id: String = DOC[i][0]
			b.pressed.connect(func() -> void: LandNav.open(StringName(id)))
	return bar


static func plate(node_name: String, pad_v: int, pad_h: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = node_name
	p.theme = UI3Theme.get_theme()
	var sb := PanelParts.plate_box("l", 0)
	sb.content_margin_left = pad_h
	sb.content_margin_right = pad_h
	sb.content_margin_top = pad_v
	sb.content_margin_bottom = pad_v
	p.add_theme_stylebox_override("panel", sb)
	return p


## `.btile`: raised cell, 4 px left edge in `edge`. Unmet = chip fill, rim edge, centred "?" + "Not met yet".
static func tile(node_name: String, met: bool, title: String, sub: String, edge: Color, icon: Texture2D = null, icon_col := Color.WHITE) -> Ui5CodexTile:
	var t := Ui5CodexTile.new()
	t.name = node_name
	t.theme = UI3Theme.get_theme()
	t.set_meta("seen", met)
	t.custom_minimum_size.y = UI3Theme.size_of("codex_tile_h")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = UI3Theme.color("plate_raised") if met else UI3Theme.color("chip")
	sb.set_corner_radius_all(UI3Theme.radius("m"))
	sb.border_width_left = 4
	sb.border_color = edge if met else UI3Theme.color("plate_rim")
	sb.content_margin_left = UI3Theme.space("12") + 4
	sb.content_margin_right = UI3Theme.space("12")
	sb.content_margin_top = UI3Theme.space("8")
	sb.content_margin_bottom = UI3Theme.space("8")
	t.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("4"))
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(v)
	var nm: Label
	if met:
		if icon != null:
			var h := HBoxContainer.new()
			h.name = "NameRow"
			h.add_theme_constant_override("separation", UI3Theme.space("8"))
			h.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ic := PanelParts.icon_rect(icon, UI3Theme.size_of("icon_m"))
			ic.modulate = icon_col
			h.add_child(ic)
			nm = Ui5Text.label(title, "text_key", "text", true)
			nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(nm)
			v.add_child(h)
		else:
			nm = Ui5Text.label(title, "text_key", "text", true)
			v.add_child(nm)
	else:
		nm = Ui5Text.label("?", "text_title", "text", true)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
	nm.name = "TileName"
	nm.clip_text = false
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var s := Ui5Text.label(sub if met and sub != "" else (TranslationServer.translate("Met") if met else TranslationServer.translate("Not met yet")), "text_body", "text_muted")
	s.name = "TileSub"
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not met:
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	return t


## `.hit`: raised cell, topic name (key) over one matching line; the matched word is marked (accent fill, ink text).
static func hit(topic_name: String, snippet: String, needle: String) -> Ui5CodexTile:
	var t := Ui5CodexTile.new()
	t.name = "SearchHit"
	t.theme = UI3Theme.get_theme()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_stylebox_override("panel", PanelParts.cell_box(UI3Theme.space("12"), UI3Theme.space("16"), "m"))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("4"))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.add_child(v)
	var l := Ui5Text.label(topic_name, "text_key", "text", true)
	l.name = "HitTopic"
	v.add_child(l)
	var r := RichTextLabel.new()
	r.name = "HitText"
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_override("normal_font", UI3Theme.font_body())
	r.add_theme_font_size_override("normal_font_size", UI3Theme.size_of("text_body"))
	r.add_theme_color_override("default_color", UI3Theme.color("text"))
	r.text = marked(snippet, needle)
	r.set_meta("plain", snippet)
	v.add_child(r)
	return t


static func marked(snippet: String, needle: String) -> String:
	var out := ""
	var low := snippet.to_lower()
	var n := needle.to_lower()
	var i := 0
	var open := "[bgcolor=#%s][color=#%s]" % [UI3Theme.color("accent").to_html(false), UI3Theme.color("text_ink").to_html(false)]
	while n != "":
		var j := low.find(n, i)
		if j < 0:
			break
		out += _esc(snippet.substr(i, j - i)) + open + _esc(snippet.substr(j, n.length())) + "[/color][/bgcolor]"
		i = j + n.length()
	return out + _esc(snippet.substr(i))


static func _esc(s: String) -> String:
	return s.replace("[", "[lb]")
