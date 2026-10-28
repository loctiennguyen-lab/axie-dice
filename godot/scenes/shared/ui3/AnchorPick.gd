class_name AnchorPick
extends Control
## Anchor pick overlay (design/ux/anchor-mvp.md section 1): 3 face-up-after-flip cards, one primary "Take <Name>",
## no Skip, no Reroll. Reuses GachaReveal for the flip. UI only: the pick goes through AnchorAdapter.pick().
## Hosted inside RunMapController's overlay host (same one the Core pick uses).

signal picked(anchor_id: String)

## One plain line per Anchor, shown at the top of its card (UI-side wording; the exact rule stays below).
const SUMMARY := {
	"a_volley": "A matching group of 3+ dice also hits every enemy.",
	"a_gambler": "Safer rerolls (Gambles) that make your groups stronger.",
	"a_mana_mine": "Make a group on your first roll and get extra Mana.",
	"a_kin": "Same-class groups hit harder, mixed groups weaker.",
	"a_embers": "Keep 2 dice for next turn and they hit much harder.",
	"a_big_hand": "Groups of 4 or 5 dice hit harder, groups of 3 get nothing."}
## Jargon explained once, on the screen (SET etc. are never defined elsewhere before the first pick).
const GLOSSARY := "SET = 3+ dice that match and fire together. M = a die's damage multiplier. Cracked = a die broken by a risky reroll (Gamble). Held = a die you keep for next turn. Temp Face = a die that joins any SET for one turn. House Cores = the 5 Cores tied to an Anchor."

## Card and box sizes come from tokens (size.anchor_card 520x748, size.anchor_box_h rule/price/awakens).
const CARD_W := 480.0   ## legacy width, only for add_text_blocks (Codex detail); the pick screen uses the token (520)
const BADGE := 72.0
const HOUSE_CORE_COUNT := 5   ## "hold 2 of 5": each Anchor has 5 House Cores (t_anchor_pick_ui checks it)
const POP_W := 760.0

var terms_button: Button
var glossary_pop: PanelContainer

var cards: Array[PanelContainer] = []
var take_button: Button
var reveal: GachaReveal
var selected := -1
var _ids: Array = []
var _skipped_flip := false


func setup(ids: Array, first_time := true) -> void:
	_ids = ids
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := VBoxContainer.new()
	head.name = "AnchorHead"
	head.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	head.offset_top = 56
	head.offset_bottom = 156
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation", 8)
	add_child(head)
	var t := UI3.label(tr("Choose your Anchor"), "LabelScreenTitle")
	t.name = "AnchorTitle"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(t)
	var sub := UI3.label(tr("A rule that stays all run. Hold 2 of its 5 House Cores to awaken it."), "LabelMuted")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(sub)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.offset_top = 96   # keep the cards clear of the title + subtitle now that the glossary sits under the button
	add_child(center)
	var col := VBoxContainer.new()
	col.name = "AnchorColumn"
	col.add_theme_constant_override("separation", 24)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)
	var row := HBoxContainer.new()
	row.name = "AnchorRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 48)
	row.custom_minimum_size.y = _card_h()
	col.add_child(row)
	for i in ids.size():
		var c := _build_card(String(ids[i]), i)
		row.add_child(c)
		cards.append(c)
	var actions := HBoxContainer.new()
	actions.name = "AnchorFooter"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 24)
	col.add_child(actions)
	take_button = UI3.button(tr("Choose"), &"primary", &"L")
	take_button.name = "TakeAnchor"
	take_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	take_button.pressed.connect(_take)
	actions.add_child(take_button)
	var terms_row := HBoxContainer.new()
	terms_row.add_theme_constant_override("separation", 8)
	terms_row.alignment = BoxContainer.ALIGNMENT_CENTER
	terms_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	actions.add_child(terms_row)
	terms_button = UI3.button(tr("Terms"), &"quiet")
	terms_button.name = "TermsButton"
	terms_button.pressed.connect(_toggle_terms)
	terms_row.add_child(terms_button)
	var qcap := UI3.keycap("?")
	qcap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	terms_row.add_child(qcap)
	_build_glossary()
	_refresh_take()
	# Flip like the Core pick (no random tier: neutral moss look, first time = longer aura).
	reveal = GachaReveal.new()
	reveal.name = "GachaReveal"
	add_child(reveal)
	for c in cards:
		c.set_meta("gacha_tier", 0)
	reveal.start(cards, 0, first_time, false, col)
	reveal.finished.connect(func() -> void: if not cards.is_empty(): cards[0].grab_focus())


## Glossary behind the Terms button (round-2 tooltip look): one muted paragraph in an info plate above the footer.
func _build_glossary() -> void:
	glossary_pop = UI3.plate(&"info")
	glossary_pop.name = "AnchorGlossary"
	glossary_pop.visible = false
	glossary_pop.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	glossary_pop.grow_horizontal = Control.GROW_DIRECTION_BOTH
	glossary_pop.grow_vertical = Control.GROW_DIRECTION_BEGIN
	glossary_pop.offset_left = -POP_W * 0.5
	glossary_pop.offset_right = POP_W * 0.5
	glossary_pop.offset_bottom = -152
	glossary_pop.offset_top = -152
	glossary_pop.mouse_filter = Control.MOUSE_FILTER_STOP
	glossary_pop.z_index = 5
	var gl := UI3.label(tr(GLOSSARY), "LabelMuted")
	gl.name = "GlossaryText"
	gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gl.custom_minimum_size.x = POP_W - 48.0
	glossary_pop.add_child(gl)
	add_child(glossary_pop)


func _toggle_terms() -> void:
	glossary_pop.visible = not glossary_pop.visible


func _build_card(id: String, idx: int) -> PanelContainer:
	var house := AnchorAdapter.house_id(id)
	var reason := AnchorAdapter.disabled_reason(id)
	var card := UI3.plate(&"card")
	card.name = "AnchorCard%d" % idx
	card.set_meta("anchor_id", id)
	card.custom_minimum_size = Vector2(_card_w(), _card_h())
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.draw.connect(func() -> void:
		if card.has_focus():
			card.draw_style_box(UI3Theme.focus_style(UI3Theme.radius("l")), Rect2(Vector2.ZERO, card.size)))
	card.focus_entered.connect(card.queue_redraw)
	card.focus_exited.connect(card.queue_redraw)
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			select(idx)
			card.grab_focus()
		elif ev.is_action_pressed("ui_accept") and not ev.is_echo():
			select(idx))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card.add_child(col)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	var badge := PanelContainer.new()
	badge.name = "HouseBadge"
	badge.custom_minimum_size = Vector2(BADGE, BADGE)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel"), int(BADGE * 0.5), 3, AnchorAdapter.house_color(house), Vector4(8, 8, 8, 8)))
	var g := TextureRect.new()
	g.name = "HouseGlyph"
	g.texture = UI3.icon(AnchorAdapter.house_icon(house))
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	g.modulate = AnchorAdapter.house_color(house)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(g)
	top.add_child(badge)
	var names := VBoxContainer.new()
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	var nm := UI3.label(AnchorAdapter.name_of(id), "LabelScreenTitle")
	nm.name = "AnchorName"
	names.add_child(nm)
	var hn := UI3.label(tr("House %s") % AnchorAdapter.house_name(house), "LabelMuted")
	hn.name = "HouseName"
	hn.add_theme_color_override("font_color", AnchorAdapter.house_color(house))
	names.add_child(hn)
	top.add_child(names)
	col.add_child(top)
	if SUMMARY.has(id):
		var sm := UI3.label(tr(String(SUMMARY[id])), "LabelTitle")
		sm.name = "AnchorSummary"
		sm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sm.custom_minimum_size.x = _card_w() - 48.0
		col.add_child(sm)
	_add_boxes(col, id, house)
	var hcap := HBoxContainer.new()
	hcap.add_theme_constant_override("separation", 8)
	var hg := TextureRect.new()
	hg.name = "HouseCoresGlyph"
	hg.texture = UI3.icon(AnchorAdapter.house_icon(house))
	hg.custom_minimum_size = Vector2(16, 16)
	hg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hg.modulate = AnchorAdapter.house_color(house)
	hcap.add_child(hg)
	hcap.add_child(UI3.label(tr("House Cores"), "LabelMuted"))
	col.add_child(hcap)
	var hc := HFlowContainer.new()
	hc.name = "HouseCores"
	hc.add_theme_constant_override("h_separation", 8)
	hc.add_theme_constant_override("v_separation", 8)
	hc.custom_minimum_size.x = _card_w() - 48.0
	for cid in AnchorAdapter.house_cores(id):
		hc.add_child(_core_icon(String(cid)))
	col.add_child(hc)
	if reason != "":
		for ch in col.get_children():
			(ch as CanvasItem).modulate = Color(1, 1, 1, 0.55)   # dim the body only; the reason row below stays at alpha 1
		var why := UI3.label(AnchorAdapter.reason_text(reason), "LabelMuted")
		why.name = "DisabledReason"
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size.x = _card_w() - 48.0
		col.add_child(why)
	return card


static func _card_w() -> float:
	return UI3Theme.size_dict("anchor_card").x


static func _card_h() -> float:
	return UI3Theme.size_dict("anchor_card").y


static func _box_h(key: String) -> float:
	return float(((UI3Theme.tokens().get("size", {}) as Dictionary).get("anchor_box_h", {}) as Dictionary).get(key, 96))


## Fixed-height box (so the RULE / PRICE / AWAKENS rows line up across the three cards). `dashed` = the empty "No price" box.
static func _box(col: VBoxContainer, cap: String, h: float, dashed := false) -> VBoxContainer:
	var p := PanelContainer.new()
	p.name = "Box" + cap.capitalize()
	p.custom_minimum_size = Vector2(0, h)
	p.clip_contents = true
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := UI3Theme.color("text_muted")
	var sb := UI3Theme.flat(UI3Theme.color("panel"), UI3Theme.radius("s"), 0 if dashed else 2, UI3Theme.color("disabled_border"), Vector4(12, 8, 12, 8))
	p.add_theme_stylebox_override("panel", sb)
	if dashed:
		p.draw.connect(func() -> void:
			var r := Rect2(Vector2.ZERO, p.size).grow(-1.0)
			var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
			for i in 4:
				p.draw_dashed_line(pts[i], pts[i + 1], line, 2.0, 8.0))
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", 2)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(UI3.label(TranslationServer.translate(cap), "LabelMuted"))
	p.add_child(b)
	col.add_child(p)
	return b


## RULE 120 / PRICE 96 (dashed "No price" when the Anchor has none) / AWAKENS 176 (pips + "hold 2 of 5").
static func _add_boxes(col: VBoxContainer, id: String, house: String) -> void:
	var w := _card_w() - 48.0 - 24.0
	var rb := _box(col, "RULE", _box_h("rule"))
	var rt := UI3.label(AnchorAdapter.rule_text(id), "LabelDisplay")
	rt.name = "RuleText"
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.custom_minimum_size.x = w
	rb.add_child(rt)
	var has_price := AnchorAdapter.price_text(id) != ""
	var pb := _box(col, "PRICE", _box_h("price"), not has_price)
	if has_price:
		var pt := UI3.label("\u2212 " + AnchorAdapter.price_text(id), "LabelDisplay")
		pt.name = "PriceText"
		pt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pt.custom_minimum_size.x = w
		pt.add_theme_color_override("font_color", UI3Theme.color("anchor_price"))
		pb.add_child(pt)
	else:
		var np := UI3.label(TranslationServer.translate("No price"), "LabelMuted")
		np.name = "NoPrice"
		pb.add_child(np)
	var ab := _box(col, "AWAKENS", _box_h("awakens"))
	var an := UI3.label(AnchorAdapter.awaken_name(id), "LabelDisplay")
	an.name = "AwakenName"
	ab.add_child(an)
	var ar := UI3.label(AnchorAdapter.awaken_rule(id), "LabelMuted")
	ar.name = "AwakenRule"
	ar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ar.custom_minimum_size.x = w
	ab.add_child(ar)
	var pr := HBoxContainer.new()
	pr.name = "AwakenPips"
	pr.add_theme_constant_override("separation", 8)
	pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gold := UI3Theme.color("anchor_awake")
	var pip_px := UI3Theme.size_of("house_pip")
	for i in HOUSE_CORE_COUNT:
		var d := Panel.new()
		d.custom_minimum_size = Vector2(pip_px, pip_px)
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		d.add_theme_stylebox_override("panel", UI3Theme.flat(gold if i < Anchors.AWAKEN_NEED else Color.TRANSPARENT, pip_px / 2, 2, gold))
		pr.add_child(d)
	var cond := UI3.label(TranslationServer.translate("hold %d of %d") % [Anchors.AWAKEN_NEED, HOUSE_CORE_COUNT], "LabelMuted")
	cond.name = "AwakenCondition"
	cond.add_theme_color_override("font_color", gold)
	pr.add_child(cond)
	ab.add_child(pr)


## RULE / PRICE (amber, only when the Anchor has one) / AWAKENS blocks. Shared with the Codex detail so both read the same.
static func add_text_blocks(col: VBoxContainer, id: String) -> void:
	_section(col, "RULE", "Rule", AnchorAdapter.rule_text(id), 3)
	if AnchorAdapter.price_text(id) != "":   # an Anchor with no price shows no PRICE block (no fake cost line)
		var pr := _section(col, "PRICE", "Price", "− " + AnchorAdapter.price_text(id), 2)
		(pr.find_child("PriceText", true, false) as Label).add_theme_color_override("font_color", UI3Theme.color("anchor_price"))
	var aw := _section(col, "AWAKENS", "Awakens", "", 0)
	var an := UI3.label(AnchorAdapter.awaken_name(id), "LabelDisplay")
	an.name = "AwakenName"
	aw.add_child(an)
	var ar := UI3.label(AnchorAdapter.awaken_rule(id), "LabelMuted")
	ar.name = "AwakenRule"
	ar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ar.custom_minimum_size.x = CARD_W - 48.0
	aw.add_child(ar)
	var cond := UI3.label(TranslationServer.translate("Awakens when you hold 2 of these 5 Cores"), "LabelMuted")
	cond.name = "AwakenCondition"
	cond.add_theme_color_override("font_color", UI3Theme.color("anchor_awake"))
	cond.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cond.custom_minimum_size.x = CARD_W - 48.0
	aw.add_child(cond)


## A small labelled block: muted caption, then the text. Returns the block (text label is "<cap>Text").
static func _section(col: VBoxContainer, cap: String, _key: String, text: String, _lines: int) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.name = "Section" + cap.capitalize()
	b.add_theme_constant_override("separation", 2)
	b.add_child(UI3.label(TranslationServer.translate(cap), "LabelMuted"))
	if text != "":
		var l := UI3.label(text, "LabelDisplay")
		l.name = cap.capitalize() + "Text"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = CARD_W - 48.0
		b.add_child(l)
	col.add_child(b)
	return b


## House Core chip: the name only (no icon), hover/focus shows the Core text.
func _core_icon(core_id: String) -> Control:
	var def = RelicRegistry.get_def(core_id)
	var p := PanelContainer.new()
	p.name = "HouseCore_%s" % core_id
	p.custom_minimum_size = Vector2(UI3Theme.size_of("hit_min"), UI3Theme.size_of("hit_min"))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.focus_mode = Control.FOCUS_ALL
	var sb := UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("s"), 2, UI3Theme.color("text_muted"), Vector4(12, 4, 12, 4))
	p.add_theme_stylebox_override("panel", sb)
	var title := core_id
	var tip := core_id
	if def != null:
		title = UI3.title_case(UI3.player_text(String(def.name)))
		tip = "%s\n%s" % [title, UI3.player_text(String(def.description))]
	var nl := UI3.label(title, "LabelMuted")
	nl.name = "CoreName"
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(nl)
	UI3Tooltip.bind(p, tip)
	return p


func select(i: int) -> void:
	if reveal != null and reveal.running:
		return   # the click that skips the flip is not also a pick
	if i < 0 or i >= cards.size() or AnchorAdapter.disabled_reason(String(_ids[i])) != "":
		return
	selected = i
	for k in cards.size():
		UI3.set_card_selected(cards[k], k == i)
	_refresh_take()


func _refresh_take() -> void:
	if selected < 0:
		take_button.text = tr("Choose")
		UI3.set_disabled_reason(take_button, tr("Pick a card first"))
	else:
		UI3.clear_disabled_reason(take_button)
		take_button.disabled = false
		take_button.text = tr("Choose %s") % AnchorAdapter.name_of(String(_ids[selected]))


func _take() -> void:
	if selected < 0 or (reveal != null and reveal.running):
		return
	var id := String(_ids[selected])
	if AnchorAdapter.pick(id):
		picked.emit(id)


func _unhandled_key_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	var k := (ev as InputEventKey).keycode
	if k == KEY_QUESTION or (k == KEY_SLASH and (ev as InputEventKey).shift_pressed):
		_toggle_terms()
		get_viewport().set_input_as_handled()
		return
	if k == KEY_ESCAPE and glossary_pop != null and glossary_pop.visible:
		glossary_pop.visible = false   # Esc: closes Terms; otherwise nothing (the pick has no way back)
		get_viewport().set_input_as_handled()
		return
	if k in [KEY_1, KEY_2, KEY_3]:
		select(int(k - KEY_1))
		get_viewport().set_input_as_handled()
