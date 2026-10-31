extends PanelContainer
## UI-05 AnchorCard (48-anchor-pick): fixed anchor_card_w x anchor_card_h plate, padding 20, gap 12, radius xl.
## Tree (data-names): AnchorCard > Column > [LockedReason?, Head(HouseGlyph, Names(AnchorName, HouseLine)), Summary,
## RuleBox, PriceBox?, AwakensBox, HouseCap, HouseCores(HouseCoreChip x5)]. The Column is child 0 (GachaReveal needs it).
## Selected = 4 px cream ring outside the card + 12 px lift (applied by the row); focus = sky ring outside that.
## Locked = body dimmed to .45, the LockedReason strip stays at full alpha. Colours: house_* tokens via AnchorAdapter.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")

var column: VBoxContainer
var anchor_id := ""
var selected := false


func setup(id: String) -> void:
	anchor_id = id
	theme = UI3Theme.get_theme()
	name = "AnchorCard"
	set_meta("anchor_id", id)
	var house := AnchorAdapter.house_id(id)
	var hcol := AnchorAdapter.house_color(house)
	var reason := AnchorAdapter.disabled_reason(id)
	var pad := UI3Theme.space("20")
	var w := UI3Theme.size_of("anchor_card_w")
	add_theme_stylebox_override("panel", PanelParts.plate_box("xl", pad))
	custom_minimum_size = Vector2(w, UI3Theme.size_of("anchor_card_h"))
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var inner := w - 2 * pad
	column = VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", UI3Theme.space("12"))
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	if reason != "":
		var strip := PanelParts.panel(UI3Theme.flat(UI3Theme.color("disabled"), UI3Theme.radius("s"), UI3Theme.stroke("hairline"),
			UI3Theme.color("disabled_rim"), Vector4(12, 8, 12, 8)), "LockedReason")
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sr := HBoxContainer.new()
		sr.add_theme_constant_override("separation", UI3Theme.space("8"))
		sr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_child(sr)
		sr.add_child(PanelParts.icon_rect(UI3.icon("ui_lock"), UI3Theme.size_of("icon_s"), "LockIcon"))
		var why := PanelParts.text(AnchorAdapter.reason_text(reason), "text_body", "disabled_text")
		why.name = "Reason"
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size.x = inner - 24 - UI3Theme.size_of("icon_s") - 8
		why.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sr.add_child(why)
		column.add_child(strip)
	var body := VBoxContainer.new()
	body.name = "Body"
	# Deviation: at 1280 (text floor 14 px real) the longest card (Big Hand) is 13 px over anchor_card_h with gap 12: gap 8 there.
	body.add_theme_constant_override("separation", UI3Theme.space("12") if UI3Theme.layout_scale() >= 1.0 else UI3Theme.space("8"))
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if reason != "":
		body.modulate = Color(1, 1, 1, 0.45)
	column.add_child(body)

	var head := HBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", UI3Theme.space("16"))
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(head)
	var disc_px := UI3Theme.size_of("house_disc")
	var disc := PanelParts.panel(UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("pill"), UI3Theme.stroke("btn"), hcol), "HouseGlyph")
	disc.custom_minimum_size = Vector2(disc_px, disc_px)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gl := PanelParts.icon_rect(UI3.icon(AnchorAdapter.house_icon(house)), 44, "Glyph")
	gl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	gl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gl.modulate = hcol
	disc.add_child(gl)
	head.add_child(disc)
	var names := VBoxContainer.new()
	names.name = "Names"
	names.add_theme_constant_override("separation", 2)
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(names)
	var nm := PanelParts.text(AnchorAdapter.name_of(id), "text_screen_title", "text", true)
	nm.name = "AnchorName"
	names.add_child(nm)
	var hl := PanelParts.text(tr("House: %s") % AnchorAdapter.house_name(house), "text_body", "text")
	hl.name = "HouseLine"
	hl.add_theme_color_override("font_color", hcol)
	names.add_child(hl)

	var summary := String(AnchorPick.SUMMARY.get(id, ""))
	if summary != "":
		var sm := PanelParts.text(tr(summary), "text_body", "text", true)
		sm.name = "Summary"
		sm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sm.custom_minimum_size.x = inner
		body.add_child(sm)
	var rb := _box("RuleBox", "Rule", inner)
	rb.add_child(_wrapped("RuleText", AnchorAdapter.rule_text(id), "text", inner - 24))
	body.add_child(rb.get_parent())
	if AnchorAdapter.price_text(id) != "":
		var pb := _box("PriceBox", "Price", inner)
		pb.add_child(_wrapped("PriceText", "− " + AnchorAdapter.price_text(id), "anchor_price", inner - 24, true))
		body.add_child(pb.get_parent())
	var ab := _box("AwakensBox", "Awakens", inner)
	var an := PanelParts.text(AnchorAdapter.awaken_name(id), "text_body", "anchor_awake", true)
	an.name = "AwakenName"
	ab.add_child(an)
	ab.add_child(_wrapped("AwakenRule", AnchorAdapter.awaken_rule(id), "text", inner - 24))
	ab.add_child(_wrapped("AwakenCondition", TranslationServer.translate("Awakens when you hold 2 of these 5 Cores"), "text_muted", inner - 24))
	body.add_child(ab.get_parent())
	var cap := PanelParts.text(tr("House Cores"), "text_key", "text_muted", true)
	cap.name = "HouseCap"
	body.add_child(cap)
	var hc := HFlowContainer.new()
	hc.name = "HouseCores"
	hc.add_theme_constant_override("h_separation", UI3Theme.space("4"))
	hc.add_theme_constant_override("v_separation", UI3Theme.space("4"))
	hc.custom_minimum_size.x = inner
	hc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for cid in AnchorAdapter.house_cores(id):
		hc.add_child(_core_chip(String(cid)))
	body.add_child(hc)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


## `.ac-box`: plate_raised cell, radius m, padding 8 12, gap 2; first child is the muted cap word. Returns the inner VBox
## (its parent is the named box, the one to add to the card).
static func _box(node_name: String, cap_word: String, inner: float) -> VBoxContainer:
	var box := PanelParts.panel(PanelParts.cell_box(UI3Theme.space("8"), UI3Theme.space("12")), node_name)
	box.custom_minimum_size.x = inner
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(v)
	var c := PanelParts.text(TranslationServer.translate(cap_word), "text_key", "text_muted", true)
	c.name = "Cap"
	v.add_child(c)
	return v


static func _wrapped(node_name: String, t: String, col: String, w: float, display := false) -> Label:
	var l := PanelParts.text(t, "text_body", col, display)
	l.name = node_name
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = w
	return l


## `.core-chip`: tag_h high, chip fill, 2 px plate_rim, 18 px axis icon + name (Work Sans 16). Tooltip = Core text.
static func _core_chip(core_id: String) -> PanelContainer:
	var def = RelicRegistry.get_def(core_id)
	var chip := PanelParts.panel(UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("s"), UI3Theme.stroke("rim"),
		UI3Theme.color("plate_rim"), Vector4(4, 0, 8, 0)), "HouseCoreChip")
	chip.custom_minimum_size = Vector2(0, UI3Theme.size_of("tag_h"))
	chip.mouse_filter = Control.MOUSE_FILTER_PASS   # tooltip only; a click still reaches the card
	chip.focus_mode = Control.FOCUS_ALL
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", UI3Theme.space("4"))
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(hb)
	var axis := String(def.core_axis) if def != null else ""
	var ic := PanelParts.icon_rect(UI3.icon(String(CorePanel.AXIS_ICON.get(axis, "face_buff"))), 18)
	hb.add_child(ic)
	var title := core_id
	var tip := core_id
	if def != null:
		title = UI3.title_case(UI3.player_text(String(def.name)))
		tip = "%s\n%s" % [title, UI3.player_text(String(def.description))]
	var nl := PanelParts.text(title, "text_key", "text")
	nl.name = "CoreName"
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(nl)
	UI3Tooltip.bind(chip, tip)
	return chip


func set_selected(on: bool) -> void:
	selected = on
	queue_redraw()


func lift_px() -> float:
	return float(UI3Theme.space("12")) if selected else 0.0


func _draw() -> void:
	var rad := UI3Theme.radius("xl")
	var r := Rect2(Vector2.ZERO, size)
	var sel_w := UI3Theme.stroke("selected")
	if selected:
		# html .is-selected: cream ring + a hard dark lip under it (shadow.lip)
		draw_style_box(PanelParts.ring_style(UI3Theme.color("plate_ink"), sel_w, 0, rad), Rect2(Vector2(0, PanelParts.lip(Color.BLACK)["y"]), size))
		draw_style_box(PanelParts.ring_style(UI3Theme.color("selected"), sel_w, 0, rad), r)
	if has_focus():
		var gap := UI3Theme.stroke("focus_gap") + (sel_w if selected else 0)
		draw_style_box(PanelParts.ring_style(UI3Theme.color("focus_ring"), UI3Theme.stroke("focus"), gap, rad), r)
