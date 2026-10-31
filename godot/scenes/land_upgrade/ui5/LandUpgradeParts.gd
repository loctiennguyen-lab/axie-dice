extends RefCounted
## UI-05 b23 lane S2: Land upgrade pieces (round-3 ui05-land-screens.html .meta-head / .tier-row / .detail / .kv / .tag).
## Static builders; LandUpgradeScreen owns the state. Sizes and colours are tokens. Use through
## `const Parts := preload("res://scenes/land_upgrade/ui5/LandUpgradeParts.gd")`.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const LAND_COLOR := ["land_savannah", "land_forest", "land_arctic", "land_mystic", "land_genesis", "land_luna"]


static func tint(tier: int) -> Color:
	return UI3Theme.color(LAND_COLOR[clampi(tier, 1, 6) - 1])


## Header plate (.meta-head): BackButton + Title + StoneChip. Takes the UI3Meta shell and rewires it: the right-hand
## currency plate goes (the chip is the only Stone readout on this screen).
static func header(shell: Dictionary, stone: int) -> Label:
	var col: VBoxContainer = shell["col"]
	var row := col.get_node("Header") as HBoxContainer
	row.name = "HeaderRow"
	for n in ["HeaderRight", "Currencies"]:
		var c := row.find_child(n, false, false)
		if c != null:
			row.remove_child(c)
			c.queue_free()
	var tp := row.get_node("TitlePlate") as PanelContainer
	tp.name = "Header"
	var s12 := UI3Theme.space("12")
	tp.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("l"), UI3Theme.stroke("rim"),
		UI3Theme.color("plate_rim"), Vector4(s12, s12, UI3Theme.space("24"), s12), PanelParts.lip(UI3Theme.color("plate_ink"))))
	var trow := tp.get_child(0) as HBoxContainer
	var back := shell["back"] as Button
	back.name = "BackButton"
	back.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("btn_m")
	(shell["sub"] as Control).queue_free()
	var chip := PanelParts.panel(UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(s12, 0, s12, 0)), "StoneChip")
	chip.custom_minimum_size.y = UI3Theme.size_of("chip_h")
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("8"))
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	chip.add_child(h)
	h.add_child(PanelParts.icon_rect(UI3.currency_icon("cur_stone", UI3Theme.size_of("icon_m")), UI3Theme.size_of("icon_m")))
	var v := Ui5Text.label(UI3.fmt(stone), "text_body", "text", true)
	v.name = "Value"
	h.add_child(v)
	var gap := Control.new()
	gap.custom_minimum_size.x = UI3Theme.space("16")
	trow.add_child(gap)
	trow.add_child(chip)
	return v


## TierHeader plate: title line, StoneBar, progress line (text may be "" at the top tier's second line).
static func tier_header(title: String, value: float, maxv: float, line: String) -> PanelContainer:
	var p := PanelParts.panel(PanelParts.plate_box("l", UI3Theme.space("16")), "TierHeader")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	p.add_child(v)
	var t := Ui5Text.label(title, "text_title", "text", true)
	t.name = "TierTitle"
	v.add_child(t)
	var bar := ProgressBar.new()
	bar.name = "StoneBar"
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = maxf(maxv, 1)
	bar.value = clampf(value, 0, maxf(maxv, 1))
	bar.custom_minimum_size.y = UI3Theme.size_of("hp_bar_l")
	v.add_child(bar)
	var l := Ui5Text.label(line, "text_body", "text_muted")
	l.name = "StoneLine"
	v.add_child(l)
	return p


## TierRowN (.tier-row): plate, padding 12 16 12 12, min-h tier_row_h. `ring` = the row shown in the detail plate.
static func tier_row(n: int, name_txt: String, adds: String, cost: String, cum: String, btn: Button, ring: bool, owned: bool) -> PanelContainer:
	var s12 := UI3Theme.space("12")
	var box := PanelParts.plate_box("l", 0)
	box.content_margin_left = s12
	box.content_margin_top = s12
	box.content_margin_right = UI3Theme.space("16")
	box.content_margin_bottom = s12
	if ring:
		box.border_color = UI3Theme.color("selected")
		box.set_border_width_all(UI3Theme.stroke("selected"))
	var p := PanelParts.panel(box, "TierRow%d" % n)
	p.custom_minimum_size.y = UI3Theme.size_of("tier_row_h")
	p.focus_mode = Control.FOCUS_ALL
	if owned:
		p.modulate.a = 0.75
	var h := HBoxContainer.new()
	h.name = "Row"
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(h)
	var sw := Panel.new()
	sw.name = "TierSwatch"
	sw.custom_minimum_size = Vector2(UI3Theme.size_of("land_swatch_w"), UI3Theme.size_of("land_swatch_h"))
	sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sw.add_theme_stylebox_override("panel", UI3Theme.flat(tint(n), UI3Theme.radius("s")))
	h.add_child(sw)
	var mid := VBoxContainer.new()
	mid.name = "Info"
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid.add_theme_constant_override("separation", UI3Theme.space("4"))
	h.add_child(mid)
	var nl := Ui5Text.label(name_txt, "text_title", "text", true)
	nl.name = "Name"
	mid.add_child(nl)
	var al := Ui5Text.label(adds, "text_body", "text_muted")
	al.name = "Adds"
	al.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(al)
	if cost != "":
		var cc := VBoxContainer.new()
		cc.name = "CostCol"
		cc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var c := Ui5Text.label(cost, "text_title", "text", true)
		c.name = "Cost"
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cc.add_child(c)
		if cum != "":
			var u := Ui5Text.label(cum, "text_body", "text_muted")
			u.name = "Cumulative"
			u.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			cc.add_child(u)
		h.add_child(cc)
	btn.name = "RowButton"
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(btn)
	return p


## StateTag (.tag.next): cream pill, ink text.
static func state_tag(text: String) -> PanelContainer:
	var p := PanelParts.panel(UI3Theme.flat(UI3Theme.color("text"), UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(UI3Theme.space("12"), UI3Theme.space("4"), UI3Theme.space("12"), UI3Theme.space("4"))), "StateTag")
	p.custom_minimum_size.y = UI3Theme.size_of("tag_h")
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(Ui5Text.label(text, "text_key", "text_ink", true))
	return p


## `.kv` row: plate_raised, radius s, padding 8 12, min-h btn_s, label left and value (Rowdies title) right.
static func kv(node_name: String, k: String, val: String) -> PanelContainer:
	var p := PanelParts.panel(PanelParts.cell_box(UI3Theme.space("8"), UI3Theme.space("12"), "s"), node_name)
	p.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(h)
	var a := Ui5Text.label(k, "text_body", "text")
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a)
	var b := Ui5Text.label(val, "text_title", "text", true)
	b.name = "Value"
	h.add_child(b)
	return p
