extends PanelContainer
## UI-05 AnchorCard (48-anchor-pick): fixed anchor_card_w x anchor_card_h plate, padding 20, gap 12, radius xl.
## Tree (data-names): AnchorCard > Column > [LockedReason?, Head(HouseEmblem, Names(AnchorName, HouseLine)), Tagline,
## RuleBox, PriceBox?, AwakensBox(AwakenMeter), HouseCap, HouseCores(HouseCoreChip x5)]. The Column is child 0 (GachaReveal needs it).
## Selected = 4 px cream ring outside the card + 12 px lift (applied by the row); focus = sky ring outside that.
## Locked = body dimmed to .45, the LockedReason strip stays at full alpha. Colours: house_* tokens via AnchorAdapter.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")

var column: VBoxContainer
var anchor_id := ""
var selected := false
## Polish 3/11 #9: only the selected card shows the full Awakens + House Cores blocks; the others show one summary line.
var _full: Array[Control] = []
var _short: Control


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
	var pbx := PanelParts.plate_box("xl", pad)
	pbx.set_border_width_all(3)   # html .a6: 3 px house edge
	pbx.border_color = hcol
	add_theme_stylebox_override("panel", pbx)
	# p5-ui 5/11: height follows the content (no dead half-card); the row stretches all cards to the tallest one.
	custom_minimum_size = Vector2(w, 0)
	size_flags_vertical = Control.SIZE_FILL
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
		sr.add_child(PanelParts.icon_rect(UI3.icon("ui_lock", UI3Theme.size_of("icon_s")), UI3Theme.size_of("icon_s"), "LockIcon"))
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
	head.add_theme_constant_override("separation", UI3Theme.space("12"))
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(head)
	var disc_px := UI3Theme.size_of("house_disc")
	var em := PanelParts.icon_rect(UI6Assets.house(house, disc_px), disc_px, "HouseEmblem")
	em.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(em)
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
		var sm := PanelParts.text(tr(summary), "text_body", "core_headline")
		sm.name = "Tagline"
		sm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sm.custom_minimum_size.x = inner
		body.add_child(sm)
	var rb := _box("RuleBox", "Rule", inner)
	rb.add_child(rich("RuleText", AnchorAdapter.rule_text(id), inner - 24))
	body.add_child(rb.get_parent())
	if AnchorAdapter.price_text(id) != "":
		var pb := _box("PriceBox", "Price", inner)
		pb.add_child(rich("PriceText", "− " + AnchorAdapter.price_text(id), inner - 24))
		body.add_child(pb.get_parent())
	var short := PanelParts.text("%s · %s   ·   %s · %d" % [tr("Awakens"), AnchorAdapter.awaken_name(id), tr("House Cores"),
		AnchorAdapter.house_cores(id).size()], "text_key", "anchor_awake", true)
	short.name = "CollapsedLine"
	short.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	short.custom_minimum_size.x = inner
	short.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(short)
	_short = short
	var ab := _box("AwakensBox", "", inner)
	var awc := UI3Theme.color("anchor_awake")
	var ah := HBoxContainer.new()
	ah.name = "AwakensHead"
	ah.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var acap := PanelParts.text(tr("Awakens") + " ·", "text_key", "anchor_awake", true)
	acap.name = "AwakensCap"
	ah.add_child(acap)
	var an := PanelParts.text(AnchorAdapter.awaken_name(id), "text_key", "anchor_awake", true)
	an.name = "AwakenName"
	an.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	an.clip_text = true
	an.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ah.add_child(an)
	ah.add_child(_meter(id, awc))
	ab.add_child(ah)
	ab.add_child(rich("AwakenRule", AnchorAdapter.awaken_rule(id), inner - 24))
	body.add_child(ab.get_parent())
	var cap := PanelParts.text(tr("House Cores · hold 2 of 5"), "text_key", "text_muted", true)
	cap.name = "HouseCap"
	body.add_child(cap)
	var hc := HFlowContainer.new()
	hc.name = "HouseCores"
	hc.add_theme_constant_override("h_separation", UI3Theme.space("4"))
	hc.add_theme_constant_override("v_separation", UI3Theme.space("4"))
	hc.custom_minimum_size.x = inner
	hc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for cid in AnchorAdapter.house_cores(id):
		hc.add_child(_core_chip(String(cid), hcol), true)   # readable names: HouseCoreChip, HouseCoreChip2 ...
	body.add_child(hc)
	_full = [ab.get_parent(), cap, hc]
	_apply_expanded()
	UI3Tooltip.bind(self, tr(AnchorPick.GLOSSARY))
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
	if cap_word != "":
		var c := PanelParts.text(TranslationServer.translate(cap_word), "text_key", "text_muted", true)
		c.name = "Cap"
		v.add_child(c)
	return v


## Body text with number / keyword chips (Chipify). RichTextLabel, text_body size, wraps at `w`.
static func rich(node_name: String, t: String, w: float) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.name = node_name
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := UI3Theme.size_of("text_body")
	var f := UI3Theme.get_theme().get_font("font", "Label")
	for k in ["normal_font_size", "bold_font_size", "italics_font_size", "mono_font_size", "bold_italics_font_size"]:
		r.add_theme_font_size_override(k, fs)
	if f != null:
		r.add_theme_font_override("normal_font", f)
	r.add_theme_color_override("default_color", UI3Theme.color("text"))
	r.add_theme_constant_override("line_separation", 2)
	r.custom_minimum_size.x = w
	r.text = Chipify.bbcode(t)
	return r


## AwakenMeter: two pips + "n / 2" (n from AwakenProgress; this card is not the owned Anchor before the pick, so 0).
static func _meter(id: String, col: Color) -> HBoxContainer:
	var n := 0
	if AnchorAdapter.current_id() == id:
		n = AwakenProgress.need() if AnchorAdapter.awakened() else AwakenProgress.count()
	var m := HBoxContainer.new()
	m.name = "AwakenMeter"
	m.add_theme_constant_override("separation", UI3Theme.space("4"))
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	m.add_child(AwakenProgress.pips(n, col, 12))
	var l := PanelParts.text("%d / %d" % [n, AwakenProgress.need()], "text_key", "text")
	l.name = "Count"
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	m.add_child(l)
	m.set_meta("n", n)
	return m


## HouseCoreChip: family emblem + name + TierShards. Owned Cores get a 2 px ring in the house colour. Tooltip = Core text.
static func _core_chip(core_id: String, house_col: Color) -> PanelContainer:
	var def = RelicRegistry.get_def(core_id)
	var owned := AnchorAdapter.owned().has(core_id)
	var chip := PanelParts.panel(UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("s"), 2 if owned else 0,
		house_col, Vector4(4, 0, 8, 0)), "HouseCoreChip")
	chip.custom_minimum_size = Vector2(0, UI3Theme.size_of("tag_h"))
	chip.mouse_filter = Control.MOUSE_FILTER_PASS   # tooltip only; a click still reaches the card
	chip.focus_mode = Control.FOCUS_ALL
	chip.set_meta("owned", owned)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", UI3Theme.space("4"))
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(hb)
	var axis := String(def.core_axis) if def != null else "stat"
	var ic := PanelParts.icon_rect(CoreVisuals.family_texture(axis, 24), 24, "FamilyEmblem")
	hb.add_child(ic)
	var title := core_id
	var tip := core_id
	var tier := 0
	if def != null:
		title = UI3.title_case(UI3.player_text(String(def.name)))
		tip = "%s\n%s" % [title, UI3.player_text(String(def.description))]
		tier = clampi(int(def.rarity), 0, 2)
	var nl := PanelParts.text(title, "text_key", "text")
	nl.name = "CoreName"
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(nl)
	var sh := TierShards.new().setup(tier, 16)
	hb.add_child(sh)
	UI3Tooltip.bind(chip, tip)
	return chip


func _apply_expanded() -> void:
	# p5-ui 5/11: every card shows its Awakens block and House Cores (real data); selection is the ring + lift only.
	for n in _full:
		n.visible = true
	if _short != null:
		_short.visible = false


func set_selected(on: bool) -> void:
	selected = on
	_apply_expanded()
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
