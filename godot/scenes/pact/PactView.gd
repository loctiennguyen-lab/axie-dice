class_name PactView
extends Control
## Boss Pact screen, UI-03 12 (relic-set-v2 §4.4; ascension-v2 A6 first boss / A10 every boss = required).
## Pure view: RunState.pact_cards() in, `picked(index, sell_id)` / `skipped` out. RunMapController hosts it.
## Pick a card (click / arrows), then Accept; a confirm dialog repeats only the drawback. Full slots open the
## SlotSwapSheet (32): a forced pact has no "Leave it". Esc asks the host for the in-run menu.

signal picked(index: int, sell_id: String)
signal skipped
## Aid R5: the player asked to swap card `index`. The host buys it and calls setup() again.
signal swap_requested(index: int)
## Esc: the host opens the in-run menu.
signal menu_requested

const CARD_W := 416.0
const ART_H := 144.0

var cards: Array = []
var can_skip: bool = true
var card_panels: Array[PanelContainer] = []
var swap_buttons: Array[Button] = []
## AidPurchase.pact_swap_offer() result ({} = no swap UI). {show, enabled, price, reason, used, cap}.
var swap_offer: Dictionary = {}
var skip_button: Button = null
var accept_button: Button = null
var selected := 0


func setup(p_cards: Array, p_can_skip: bool, p_swap_offer: Dictionary = {}) -> void:
	cards = p_cards
	swap_offer = p_swap_offer
	can_skip = p_can_skip
	swap_buttons.clear()
	card_panels.clear()
	skip_button = null
	for c in get_children():
		remove_child(c)
		c.queue_free()
	theme = UI3Theme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.name = "PactColumn"
	col.add_theme_constant_override("separation", 40)
	center.add_child(col)
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)
	var title := UI3.label(tr("Boss Pact"), "LabelScreenTitle")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(title)
	var sub := UI3.label(tr("Required: take one pact to go on.") if not can_skip
		else tr("Each pact has a benefit and a drawback. Take one, or skip."), "LabelMuted")
	sub.name = "PactSub"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(sub)
	var row := HBoxContainer.new()
	row.name = "PactRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 32)
	col.add_child(row)
	for i in cards.size():
		row.add_child(_card(i, cards[i] as Dictionary))
	var acts := HBoxContainer.new()
	acts.alignment = BoxContainer.ALIGNMENT_CENTER
	acts.add_theme_constant_override("separation", 16)
	col.add_child(acts)
	if can_skip:
		skip_button = UI3.button(tr("Skip pact"), &"secondary", &"M")
		skip_button.name = "SkipPact"
		skip_button.pressed.connect(func() -> void: skipped.emit())
		acts.add_child(skip_button)
	accept_button = UI3.button(tr("Accept"), &"primary", &"L")
	accept_button.name = "AcceptPact"
	accept_button.pressed.connect(_on_accept)
	acts.add_child(accept_button)
	select(clampi(selected, 0, maxi(cards.size() - 1, 0)))
	if not card_panels.is_empty() and is_inside_tree():
		card_panels[selected].grab_focus.call_deferred()


## Selects card `i` (cream outline + lift) and sets Accept for it.
func select(i: int) -> void:
	selected = i
	for k in card_panels.size():
		UI3.set_card_selected(card_panels[k], k == i, false)
	if accept_button == null or i < 0 or i >= cards.size():
		return
	if bool((cards[i] as Dictionary).get("ok", false)):
		UI3.clear_disabled_reason(accept_button)
	else:
		UI3.set_disabled_reason(accept_button, tr("No free slot"))


## "PACT. <gain>. Drawback: <cost>." -> {gain, cost} in player text.
static func split_description(raw: String) -> Dictionary:
	var parts := raw.split("Drawback:", true, 1)
	var gain := UI3.player_text(String(parts[0]).strip_edges().trim_suffix("."))
	var cost := ""
	if parts.size() > 1:
		cost = String(parts[1]).strip_edges()
		if cost != "":
			cost = cost[0].to_upper() + cost.substr(1)
	return {"gain": gain, "cost": cost}


func _card(i: int, c: Dictionary) -> Control:
	var card := UI3.plate(&"card")
	card.name = "PactCard%d" % i
	card.custom_minimum_size.x = CARD_W
	card.size_flags_vertical = Control.SIZE_FILL
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.draw.connect(func() -> void:
		if card.has_focus():
			card.draw_style_box(UI3Theme.focus_style(UI3Theme.radius("l")), Rect2(Vector2.ZERO, card.size)))
	card.focus_entered.connect(card.queue_redraw)
	card.focus_exited.connect(card.queue_redraw)
	card.focus_entered.connect(select.bind(i))
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			select(i)
			card.grab_focus()
		elif ev.is_action_pressed("ui_accept") and not ev.is_echo():
			select(i)
			accept_button.grab_focus())
	card_panels.append(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	card.add_child(v)
	v.add_child(UI3.label("%s · %s" % [tr("Pact"), tr(String(c.get("group", "")).capitalize())], "LabelMuted"))
	var rar := int(c.get("rarity", 0))
	var accent := UI3Theme.color(["rarity_common", "mana", "rarity_rare", "rarity_epic", "rarity_legendary"][clampi(rar, 0, 4)])
	var art := Panel.new()
	art.custom_minimum_size = Vector2(0, ART_H)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("panel_raised"), UI3Theme.radius("m"),
		UI3Theme.stroke("selected"), accent))
	var icon := TextureRect.new()
	icon.texture = UI3.icon("ui_mooncard")
	icon.set_anchors_preset(Control.PRESET_CENTER)
	icon.offset_left = -48
	icon.offset_right = 48
	icon.offset_top = -48
	icon.offset_bottom = 48
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(icon)
	v.add_child(art)
	var nm := UI3.label(UI3.title_case(UI3.player_text(String(c.get("name", "")))), "LabelTitle")
	nm.name = "PactName"
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(nm)
	var rl := UI3.label(["Common", "Uncommon", "Rare", "Epic", "Legendary"][clampi(rar, 0, 4)])
	rl.add_theme_color_override("font_color", UI3Theme.color("text_muted") if rar == 0 else accent)
	v.add_child(rl)
	var sp := split_description(String(c.get("description", "")))
	v.add_child(UI3.trade_box(&"gain", String(sp["gain"])))
	if String(sp["cost"]) != "":
		v.add_child(UI3.trade_box(&"cost", String(sp["cost"])))
	if bool(swap_offer.get("show", false)):
		v.add_child(_swap_row(i, c))
	return card


## Swap states (spec 12 R5): available (button + gem chip), used (cap_type), not enough Gem (chip tinted, "Need n more"),
## "No other pact" (nothing left in the pool), anything else shows AidPurchase.reason_text. Price comes from the offer.
func _swap_row(i: int, c: Dictionary) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var offered := bool(swap_offer.get("enabled", false))
	var reason := String(swap_offer.get("reason", ""))
	var price := int(swap_offer.get("price", 0))
	var sw := UI3.button(tr("Swap"), &"secondary", &"S")
	sw.name = "SwapPact%d" % i
	if offered and bool(c.get("swap_ok", true)):
		sw.pressed.connect(func() -> void: swap_requested.emit(i))
		h.add_child(sw)
		h.add_child(UI3.cost_chip(&"gem", price))
	elif offered:
		UI3.set_disabled_reason(sw, tr("No other pact"))
		h.add_child(sw)
	elif reason == "no_gems":
		var have := MetaState.gem_wallet().balance()
		UI3.set_disabled_reason(sw, tr("Need %d more Gem") % maxi(price - have, 1))
		h.add_child(sw)
		h.add_child(UI3.cost_chip(&"gem", price, true))
	elif reason == "cap_type":
		UI3.set_disabled_reason(sw, tr("Swap used"))
		h.add_child(sw)
	else:
		UI3.set_disabled_reason(sw, AidPurchase.reason_text(reason))
		h.add_child(sw)
	swap_buttons.append(sw)
	return h


func _on_accept() -> void:
	if selected < 0 or selected >= cards.size():
		return
	var c := cards[selected] as Dictionary
	if not bool(c.get("ok", false)):
		return
	var sp := split_description(String(c.get("description", "")))
	var back := UI3.button(tr("Back"), &"secondary", &"M")
	back.name = "PactBack"
	var make := UI3.button(tr("Make pact"), &"primary", &"M")
	make.name = "PactMake"
	var body := String(sp["cost"]) if String(sp["cost"]) != "" else tr("This pact has no drawback.")
	var dlg := UI3.modal(tr("Make this pact?"), "%s: %s" % [tr("Drawback"), body], [back, make], 0)
	dlg.name = "PactConfirm"
	add_child(dlg)
	var idx := selected
	var close := func() -> void:
		remove_child(dlg)
		dlg.queue_free()
		if is_instance_valid(accept_button) and accept_button.is_inside_tree():
			accept_button.grab_focus()
	back.pressed.connect(close)
	dlg.cancelled.connect(close)
	make.pressed.connect(func() -> void:
		close.call()
		_commit(idx))


func _commit(i: int) -> void:
	var c := cards[i] as Dictionary
	if not bool(c.get("needs_sell", false)):
		picked.emit(i, "")
		return
	var nd = RelicRegistry.get_def(String(c.get("id", "")))
	var cells: Array = []
	var sell_from: Array = c.get("sell_from", [])
	for oid in RunState.owned_relic_ids:
		var id := String(oid)
		var od = RelicRegistry.get_def(id)
		if od == null or id.begins_with("__"):
			continue
		var eternal := String(RunState.relic_stickers.get(id, "")) == RelicSlots.STICKER_ETERNAL
		if not sell_from.has(id) and not eternal:
			continue
		cells.append({"id": id, "name": UI3.title_case(UI3.player_text(String(od.name))),
			"kind": tr("Active") if RelicSlots._is_active(od) else tr("Passive"),
			"sell": RelicSlots.sell_price(id, RunState.ascension), "eternal": eternal})
	var active: bool = nd != null and RelicSlots._is_active(nd)
	var forced := not can_skip
	var sheet := UI3.slot_swap_sheet(tr("Make room"), UI3.title_case(UI3.player_text(String(c.get("name", "")))),
		tr("Forced pact: you cannot cancel.") if forced else String(split_description(String(c.get("description", "")))["gain"]),
		tr("Slots are full. Sell one relic to take this pact."), cells, forced,
		func(sell_id: String) -> void:
			_close_sheet()
			picked.emit(i, sell_id),
		_close_sheet, 3 if active else 4)
	sheet.name = "SlotSwapSheet"
	add_child(sheet)


func _close_sheet() -> void:
	var sh := find_child("SlotSwapSheet", true, false)
	if sh != null:
		sh.get_parent().remove_child(sh)
		sh.queue_free()


## Esc asks the host for the in-run menu (spec 12). It never skips, so a pact cannot be dodged by accident.
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		menu_requested.emit()
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()
