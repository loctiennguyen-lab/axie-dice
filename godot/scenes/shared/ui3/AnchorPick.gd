class_name AnchorPick
extends Control
## Anchor pick overlay (design/ux/anchor-mvp.md section 1): 3 face-up-after-flip cards, one primary "Take <Name>",
## no Skip, no Reroll. Reuses GachaReveal for the flip. UI only: the pick goes through AnchorAdapter.pick().
## Hosted inside RunMapController's overlay host (same one the Core pick uses).

signal picked(anchor_id: String)

const CARD_W := 480.0
const CARD_H := 560.0

var cards: Array[PanelContainer] = []
var take_button: Button
var reason_label: Label
var reveal: GachaReveal
var selected := -1
var _ids: Array = []
var _skipped_flip := false


func setup(ids: Array, first_time := true) -> void:
	_ids = ids
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var head := VBoxContainer.new()
	head.name = "AnchorHead"
	head.set_anchors_preset(Control.PRESET_TOP_WIDE)
	head.offset_top = 56
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_theme_constant_override("separation", 8)
	add_child(head)
	var t := UI3.label(tr("Choose your Anchor"), "LabelScreenTitle")
	t.name = "AnchorTitle"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(t)
	var sub := UI3.label(tr("This choice lasts the whole run. No reroll."), "LabelMuted")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(sub)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	row.custom_minimum_size.y = CARD_H
	col.add_child(row)
	for i in ids.size():
		var c := _build_card(String(ids[i]), i)
		row.add_child(c)
		cards.append(c)
	var actions := VBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	col.add_child(actions)
	take_button = UI3.button(tr("Take"), &"primary", &"L")
	take_button.name = "TakeAnchor"
	take_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	take_button.pressed.connect(_take)
	actions.add_child(take_button)
	reason_label = UI3.label("", "LabelMuted")
	reason_label.name = "TakeReason"
	reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	actions.add_child(reason_label)
	_refresh_take()
	# Flip like the Core pick (no random tier: neutral moss look, first time = longer aura).
	reveal = GachaReveal.new()
	reveal.name = "GachaReveal"
	add_child(reveal)
	for c in cards:
		c.set_meta("gacha_tier", 0)
	reveal.start(cards, 0, first_time, false, col)
	reveal.finished.connect(func() -> void: if not cards.is_empty(): cards[0].grab_focus())


func _build_card(id: String, idx: int) -> PanelContainer:
	var house := AnchorAdapter.house_id(id)
	var reason := AnchorAdapter.disabled_reason(id)
	var card := UI3.plate(&"card")
	card.name = "AnchorCard%d" % idx
	card.set_meta("anchor_id", id)
	card.custom_minimum_size = Vector2(CARD_W, CARD_H)
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
	var g := TextureRect.new()
	g.name = "HouseGlyph"
	g.texture = UI3.icon(AnchorAdapter.house_icon(house))
	g.custom_minimum_size = Vector2(64, 64)
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	g.modulate = AnchorAdapter.house_color(house)
	top.add_child(g)
	var names := VBoxContainer.new()
	var nm := UI3.label(AnchorAdapter.name_of(id), "LabelScreenTitle")
	nm.name = "AnchorName"
	names.add_child(nm)
	var hn := UI3.label(tr("House: %s") % AnchorAdapter.house_name(house), "LabelMuted")
	hn.name = "HouseName"
	hn.add_theme_color_override("font_color", AnchorAdapter.house_color(house))
	names.add_child(hn)
	top.add_child(names)
	col.add_child(top)
	_section(col, "RULE", "Rule", AnchorAdapter.rule_text(id), 3)
	_section(col, "PRICE", "Price", "− " + AnchorAdapter.price_text(id), 2)
	var aw := _section(col, "AWAKENS", "Awakens", "", 0)
	var an := UI3.label(AnchorAdapter.awaken_name(id), "LabelDisplay")
	an.name = "AwakenName"
	aw.add_child(an)
	var ar := UI3.label(AnchorAdapter.awaken_rule(id) + " " + tr("Hold 2 House Cores."), "LabelMuted")
	ar.name = "AwakenRule"
	ar.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ar.custom_minimum_size.x = CARD_W - 48.0
	aw.add_child(ar)
	var hc := HBoxContainer.new()
	hc.name = "HouseCores"
	hc.add_theme_constant_override("separation", 8)
	for cid in AnchorAdapter.house_cores(id):
		hc.add_child(_core_icon(String(cid)))
	col.add_child(hc)
	col.add_child(UI3.label(tr("House Cores"), "LabelMuted"))
	if reason != "":
		card.modulate = Color(1, 1, 1, 0.55)
		var why := UI3.label(AnchorAdapter.reason_text(reason), "LabelMuted")
		why.name = "DisabledReason"
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size.x = CARD_W - 48.0
		col.add_child(why)
	return card


## A small labelled block: muted caption, then the text. Returns the block (text label is "<cap>Text").
func _section(col: VBoxContainer, cap: String, _key: String, text: String, _lines: int) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.name = "Section" + cap.capitalize()
	b.add_theme_constant_override("separation", 2)
	b.add_child(UI3.label(tr(cap), "LabelMuted"))
	if text != "":
		var l := UI3.label(text, "LabelDisplay")
		l.name = cap.capitalize() + "Text"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = CARD_W - 48.0
		b.add_child(l)
	col.add_child(b)
	return b


func _core_icon(core_id: String) -> Control:
	var def = RelicRegistry.get_def(core_id)
	var p := PanelContainer.new()
	p.name = "HouseCore_%s" % core_id
	p.custom_minimum_size = Vector2(48, 48)
	p.modulate.a = 0.55
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.focus_mode = Control.FOCUS_ALL
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("s"), 2,
		UI3Theme.color("text_muted")))
	var ic := TextureRect.new()
	var axis := String(def.core_axis) if def != null else ""
	ic.texture = UI3.icon(String(CorePanel.AXIS_ICON.get(axis, "face_buff")))
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(ic)
	var tip := core_id
	if def != null:
		tip = "%s\n%s" % [UI3.title_case(UI3.player_text(String(def.name))), UI3.player_text(String(def.description))]
	UI3Tooltip.bind(p, tip)
	return p


func select(i: int) -> void:
	if reveal != null and reveal.running:
		return   # the click that skips the flip is not also a pick
	if i < 0 or i >= cards.size() or AnchorAdapter.disabled_reason(String(_ids[i])) != "":
		return
	selected = i
	for k in cards.size():
		UI3.set_card_selected(cards[k], k == i, false)
	_refresh_take()


func _refresh_take() -> void:
	if selected < 0:
		take_button.text = tr("Take")
		take_button.disabled = true
		UI3.set_disabled_reason(take_button, tr("Take"))
		reason_label.text = tr("Pick one Anchor.")
	else:
		UI3.clear_disabled_reason(take_button)
		take_button.disabled = false
		take_button.text = tr("Take %s") % AnchorAdapter.name_of(String(_ids[selected]))
		reason_label.text = ""


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
	if k in [KEY_1, KEY_2, KEY_3]:
		select(int(k - KEY_1))
		get_viewport().set_input_as_handled()
