class_name RunMapShop
extends RefCounted
## Shop screen. Split out of RunMapController (UI-05 b23 lane 0b): code moved as-is, state stays on the controller (`ctrl`).
## The controller keeps a same-name forwarder for every method here.


var ctrl: RunMapController


func _init(owner_ctrl: RunMapController) -> void:
	ctrl = owner_ctrl

## Shop node: src/data.js genShop()/shopBuy() ported subset. The offer was built by
## RunState.enter_node(); this screen does not generate goods.
func _on_shop_node(_node_id: String) -> void:
	_render_shop()


func _shop_rarity(it: Dictionary) -> int:
	if String(it.get("kind", "")) == "relic":
		var def = RelicRegistry.get_def(String(it.get("key", "")))
		if def != null:
			return int(def.rarity)
	return int(it.get("rar", 0))


## Why item `i` cannot be bought right now, or "".
func _shop_block_reason(it: Dictionary) -> String:
	if bool(it.get("bought", false)):
		return tr("Sold out")
	var cost := int(it.get("cost", 0))
	if RunState.shards_this_run < cost:
		return tr("Need %d Shards") % cost
	return ""


func _render_shop() -> void:
	# Re-rendered after every purchase/sale, so this doubles as the shop's save point.
	ctrl._save_map_progress()
	var host := ctrl._open_ui3_screen()
	ctrl._shop_cards.clear()
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(margin)
	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 24)
	margin.add_child(root)

	# ---- Left: shop plate + Sell plate
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 384
	left.add_theme_constant_override("separation", 16)
	root.add_child(left)
	var hp := UI3.plate(&"plate")
	hp.name = "ShopHeader"
	left.add_child(hp)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 16)
	hp.add_child(hv)
	var hrow := HBoxContainer.new()
	hrow.add_theme_constant_override("separation", 16)
	hv.add_child(hrow)
	var ic := TextureRect.new()
	ic.texture = UI3.icon("node_shop")
	ic.custom_minimum_size = Vector2(48, 48)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hrow.add_child(ic)
	var tcol := VBoxContainer.new()
	hrow.add_child(tcol)
	tcol.add_child(UI3.label(tr("Shop"), "LabelScreenTitle"))
	tcol.add_child(UI3.label(tr("Row %d") % maxi(ctrl._current_row(), 0), "LabelMuted"))
	var pill := UI3.currency_pill([{"icon": "cur_shard", "value": str(RunState.shards_this_run)}])
	pill.name = "ShardsPill"
	hv.add_child(pill)

	var sp := UI3.plate(&"plate")
	sp.name = "SellPlate"
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(sp)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 8)
	sp.add_child(sv)
	sv.add_child(UI3.label(tr("Sell"), "LabelTitle"))
	var sscroll := ScrollContainer.new()
	sscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sv.add_child(sscroll)
	var slist := VBoxContainer.new()
	slist.name = "SellList"
	slist.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slist.add_theme_constant_override("separation", 8)
	sscroll.add_child(slist)
	var sellable := 0
	for rid in RunState.owned_relic_ids:
		if RunState.relic_stickers.get(rid, "") == RelicSlots.STICKER_ETERNAL:
			continue
		var def = RelicRegistry.get_def(String(rid))
		var price := RelicSlots.sell_price(String(rid), RunState.ascension)
		var sb := UI3.button("%s · +%d" % [String(def.name) if def != null else String(rid), price], &"secondary", &"S")
		sb.name = "Sell_%s" % rid
		sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		sb.clip_text = true
		sb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		sb.pressed.connect(_on_shop_sell.bind(String(rid)))
		slist.add_child(sb)
		sellable += 1
	if sellable == 0:
		slist.add_child(UI3.label(tr("No Core to sell"), "LabelMuted"))

	# ---- Middle: goods
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 16)
	root.add_child(mid)
	var any_afford := false
	for it in RunState.shop_items:
		if not bool(it.get("bought", false)) and RunState.shards_this_run >= int(it.get("cost", 0)):
			any_afford = true
	if not any_afford and not RunState.shop_items.is_empty():
		var notice := UI3.plate(&"plate")
		notice.name = "NothingAffordable"
		notice.add_child(UI3.label(tr("You can't afford anything here. Sell a Core or leave."), "LabelTitle"))
		(notice.get_child(0) as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mid.add_child(notice)
	var groups := [["relic", tr("Cores")], ["", tr("Supplies")]]
	var idx_in_group := {}
	for g in groups:
		var idxs: Array[int] = []
		for i in RunState.shop_items.size():
			var is_relic: bool = String(RunState.shop_items[i].get("kind", "")) == "relic"
			if (g[0] == "relic") == is_relic:
				idxs.append(i)
		if idxs.is_empty():
			continue
		mid.add_child(UI3.label(g[1], "LabelScreenTitle"))
		var grid := GridContainer.new()
		grid.name = "ShopGrid_%s" % ("relic" if g[0] == "relic" else "supplies")
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 16)
		mid.add_child(grid)
		for i in idxs:
			grid.add_child(_add_shop_row(RunState.shop_items[i], i))

	# ---- Right: detail + Leave
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 416
	right.add_theme_constant_override("separation", 16)
	root.add_child(right)
	var dp := UI3.plate(&"plate")
	dp.name = "ShopDetail"
	dp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(dp)
	var dv := VBoxContainer.new()
	dv.name = "DetailCol"
	dv.add_theme_constant_override("separation", 16)
	dp.add_child(dv)
	var leave := UI3.button(tr("Leave shop"), &"secondary", &"M")
	leave.name = "LeaveShop"
	leave.pressed.connect(func() -> void: ctrl._finish_node())
	right.add_child(leave)

	if ctrl._shop_sel >= RunState.shop_items.size():
		ctrl._shop_sel = 0
	_select_shop(ctrl._shop_sel)
	if not any_afford or ctrl._shop_cards.is_empty():
		leave.grab_focus.call_deferred()
	elif ctrl._shop_sel < ctrl._shop_cards.size():
		ctrl._shop_cards[ctrl._shop_sel].grab_focus.call_deferred()


func _add_shop_row(raw: Dictionary, index: int) -> PanelContainer:
	var it: Dictionary = raw
	var rar := _shop_rarity(it)
	var accent := ctrl._rarity_color(rar)
	var bought := bool(it.get("bought", false))
	var cost := int(it.get("cost", 0))
	var afford := RunState.shards_this_run >= cost

	var card := UI3.plate(&"card")
	card.name = "ShopRow%d" % index
	card.custom_minimum_size = Vector2(0, ctrl._SHOP_ROW_H)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.draw.connect(func() -> void:
		if card.has_focus():
			card.draw_style_box(UI3Theme.focus_style(UI3Theme.radius("l")), Rect2(Vector2.ZERO, card.size)))
	card.focus_entered.connect(card.queue_redraw)
	card.focus_exited.connect(card.queue_redraw)
	card.focus_entered.connect(_select_shop.bind(index))
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			card.grab_focus()
			_select_shop(index)
		elif ev.is_action_pressed("ui_accept") and not ev.is_echo():
			_select_shop(index)
			var bb := ctrl._overlay_root.find_child("BuyButton", true, false) as Button
			if bb != null:
				bb.grab_focus())
	ctrl._shop_cards.append(card)
	card.set_meta("shop_index", index)
	if bought:
		card.modulate.a = 0.4

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	row.add_child(_shop_art(it, ctrl._SHOP_ART, accent))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	row.add_child(col)
	var nm := UI3.label(String(it.get("title", "")), "LabelTitle")
	nm.name = "ItemName"
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(nm)
	var rl := UI3.label(ctrl._rarity_name(rar))
	rl.name = "RarityLabel"
	rl.add_theme_color_override("font_color", accent)
	col.add_child(rl)
	var price := HBoxContainer.new()
	price.add_theme_constant_override("separation", 8)
	col.add_child(price)
	if bought:
		price.add_child(UI3.label(tr("Bought")))
	else:
		var si := TextureRect.new()
		si.texture = UI3.icon("cur_shard")
		si.custom_minimum_size = Vector2(28, 28)
		si.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		si.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		price.add_child(si)
		var pl := UI3.label(str(cost), "LabelTitle")
		pl.name = "Price"
		if not afford:
			pl.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
		price.add_child(pl)
	return card


func _shop_art(it: Dictionary, px: float, accent: Color) -> Control:
	var art := Panel.new()
	art.name = "Art"
	art.custom_minimum_size = Vector2(px, px)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = UI3Theme.color("panel_raised")
	sb.border_color = accent
	sb.set_border_width_all(UI3Theme.stroke("selected"))
	sb.set_corner_radius_all(UI3Theme.radius("m"))
	art.add_theme_stylebox_override("panel", sb)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(c)
	var t := TextureRect.new()
	t.texture = CardArt.texture_for_shop(String(it.get("kind", "")), _shop_rarity(it))
	t.custom_minimum_size = Vector2(px * 0.7, px * 0.7)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(t)
	return art


func _select_shop(index: int) -> void:
	if ctrl._overlay_root == null or RunState.shop_items.is_empty():
		return
	ctrl._shop_sel = index
	for c in ctrl._shop_cards:
		c.theme_type_variation = "PanelCardSelected" if int(c.get_meta("shop_index")) == index else "PanelCard"   # no lift: it overlaps the grid heading
	var dv := ctrl._overlay_root.find_child("DetailCol", true, false) as VBoxContainer
	if dv == null or index >= RunState.shop_items.size():
		return
	for ch in dv.get_children():
		dv.remove_child(ch)
		ch.queue_free()
	var it: Dictionary = RunState.shop_items[index]
	var rar := _shop_rarity(it)
	var accent := ctrl._rarity_color(rar)
	var art := _shop_art(it, 200.0, accent)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dv.add_child(art)
	var nm := UI3.label(String(it.get("title", "")), "LabelScreenTitle")
	nm.name = "DetailName"
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dv.add_child(nm)
	var rl := UI3.label(ctrl._rarity_name(rar))
	rl.add_theme_color_override("font_color", accent)
	dv.add_child(rl)
	var dsc := UI3.describe(String(it.get("desc", "")))
	var desc := UI3.label(("MP %d · " % int(dsc["mp"]) if int(dsc["mp"]) >= 0 else "") + String(dsc["text"]))
	desc.name = "DetailDesc"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dv.add_child(desc)
	var why := _shop_block_reason(it)
	var buy := UI3.button(tr("Buy · %d Shards") % int(it.get("cost", 0)), &"primary", &"L")
	buy.name = "BuyButton"
	if why == "":
		buy.pressed.connect(func() -> void: _on_shop_buy(index))
	else:
		UI3.set_disabled_reason(buy, why)
	dv.add_child(buy)


func _on_shop_sell(relic_id: String) -> void:
	if RunState.sell_relic(relic_id):
		_render_shop()


func _on_shop_buy(index: int) -> void:
	# `bought` is marked inside try_buy_shop_item() now. Marking it here meant a replay, which
	# has no screen, left every item buyable forever.
	var res: Dictionary = await RunState.request_buy_shop_item(index)
	if not bool(res["ok"]) and String(res["code"]) not in ["illegal", "busy"]:
		NetNotice.show(ctrl, String(res["code"]), _on_shop_buy.bind(index))
	_render_shop()   # rebuild so shard total / afford/bought states stay in sync
