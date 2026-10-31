class_name RunMapShop
extends RefCounted
## Shop screen. Split out of RunMapController (UI-05 b23 lane 0b): code moved as-is, state stays on the controller (`ctrl`).
## The controller keeps a same-name forwarder for every method here.


const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const Parts := preload("res://scenes/run_map/ui5/RunMenuParts.gd")
const Plates := preload("res://scenes/land/ui5/LandPlates.gd")
const CoreCard := preload("res://scenes/run_map/ui5/ShopCoreCard.gd")
const Supply := preload("res://scenes/run_map/ui5/SupplyItem.gd")

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
	var root := VBoxContainer.new()
	root.name = "Shop"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", UI3Theme.space("24"))
	root.offset_top = UI3Theme.space("40")
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(root)

	# ---- Header: icon, Title, RowLabel, ShardPill
	var head := HBoxContainer.new()
	head.name = "Header"
	head.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	head.add_theme_constant_override("separation", UI3Theme.space("20"))
	root.add_child(head)
	head.add_child(PanelParts.icon_rect(UI3.icon("node_shop"), UI3Theme.size_of("node_icon"), "Icon"))
	var title := PanelParts.on_view(PanelParts.text(tr("Shop"), "text_banner", "text_on_viewport", true))
	title.name = "Title"
	head.add_child(title)
	var rowl := PanelParts.on_view(PanelParts.text(tr("Row %d") % maxi(ctrl._current_row(), 0), "text_title", "text_on_viewport", true))
	rowl.name = "RowLabel"
	head.add_child(rowl)
	head.add_child(_shard_pill(RunState.shards_this_run))

	var any_afford := false
	for it in RunState.shop_items:
		if not bool(it.get("bought", false)) and RunState.shards_this_run >= int(it.get("cost", 0)):
			any_afford = true
	if not any_afford and not RunState.shop_items.is_empty():
		var nbox := UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("pill"), UI3Theme.stroke("btn"),
			UI3Theme.color("attrition"), Vector4(UI3Theme.space("20"), UI3Theme.space("12"), UI3Theme.space("20"), UI3Theme.space("12")))
		var notice := PanelParts.panel(nbox, "Notice")
		notice.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		notice.add_child(PanelParts.text(tr("You can't afford anything here. Sell a Core or leave."), "text_title", "text", true))
		root.add_child(notice)

	# ---- Body: Cores + Supplies, Sell column
	var body := HBoxContainer.new()
	body.name = "ShopBody"
	body.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_theme_constant_override("separation", UI3Theme.space("32"))
	root.add_child(body)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", UI3Theme.space("12"))
	main.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	body.add_child(main)
	var first_buy: Button = null
	for g in [["relic", tr("Cores"), "CoreStock"], ["", tr("Supplies"), "SupplyStock"]]:
		var idxs: Array[int] = []
		for i in RunState.shop_items.size():
			var is_relic: bool = String(RunState.shop_items[i].get("kind", "")) == "relic"
			if (g[0] == "relic") == is_relic:
				idxs.append(i)
		if idxs.is_empty():
			continue
		main.add_child(PanelParts.on_view(PanelParts.text(g[1], "text_title", "text_on_viewport", true)))
		var stock := HBoxContainer.new()
		stock.name = g[2]
		stock.add_theme_constant_override("separation", UI3Theme.space("24"))
		main.add_child(stock)
		for i in idxs:
			var card := _add_shop_row(RunState.shop_items[i], i)
			stock.add_child(card, true)   # readable unique names: ShopCoreCard, ShopCoreCard2 ...
			var bb := card.find_child("BuyButton", true, false) as Button
			if first_buy == null and bb != null and not bb.disabled:
				first_buy = bb
	body.add_child(_sell_column())

	var leave := UI3.button(tr("Leave shop"), &"primary", &"L")
	leave.name = "LeaveButton"
	leave.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	leave.pressed.connect(func() -> void: ctrl._finish_node())
	root.add_child(leave)
	Plates.attach_space_cap(leave, UI3Theme.space("32"))
	# First build on a cold start: the cap can be placed before the font is ready; poke a re-sync two frames later.
	for _i in 2:
		ctrl.get_tree().process_frame.connect(func() -> void:
			if is_instance_valid(leave):
				leave.set_meta("cap_sig", "")
				leave.queue_redraw(), CONNECT_ONE_SHOT)

	if ctrl._shop_sel >= RunState.shop_items.size():
		ctrl._shop_sel = 0
	if first_buy != null:
		first_buy.grab_focus.call_deferred()
	else:
		leave.grab_focus.call_deferred()


func _shard_pill(n: int) -> PanelContainer:
	var box := PanelParts.plate_box("pill")
	box.content_margin_left = UI3Theme.space("16")
	box.content_margin_right = UI3Theme.space("16")
	var chip := PanelParts.panel(box, "ShardPill")
	chip.custom_minimum_size = Vector2(0, UI3Theme.size_of("btn_m"))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", UI3Theme.space("8"))
	chip.add_child(r)
	var px := UI3Theme.size_of("icon_m")
	r.add_child(PanelParts.icon_rect(UI3.currency_icon("cur_shard", px), px))
	var v := PanelParts.text(UI3.fmt(n), "text_title", "text", true)
	v.name = "Value"
	v.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	r.add_child(v)
	return chip


## Why this card's Buy is off: "" (buyable), "Bought" (a Core), "Sold out", or "Need N Shards".
func _card_reason(it: Dictionary) -> String:
	var why := _shop_block_reason(it)
	if why == tr("Sold out") and String(it.get("kind", "")) == "relic":
		return tr("Bought")
	return why


## SellColumn: one SellRow (CoreSlot + SellButton "Name · +N") per sellable Core; price from RelicSlots.sell_price.
func _sell_column() -> PanelContainer:
	var sp := PanelParts.panel(PanelParts.plate_box("l", UI3Theme.space("20")), "SellColumn")
	sp.custom_minimum_size.x = UI3Theme.size_of("sell_w")
	sp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", UI3Theme.space("8"))
	sp.add_child(sv)
	sv.add_child(PanelParts.text(tr("Sell"), "text_title", "text", true))
	var sellable := 0
	for rid in RunState.owned_relic_ids:
		if RunState.relic_stickers.get(rid, "") == RelicSlots.STICKER_ETERNAL:
			continue
		var def = RelicRegistry.get_def(String(rid))
		var price := RelicSlots.sell_price(String(rid), RunState.ascension)
		var row := HBoxContainer.new()
		row.name = "SellRow"
		row.add_theme_constant_override("separation", UI3Theme.space("8"))
		sv.add_child(row)
		row.add_child(Parts.core_slot(def, false))
		var sb := UI3.button("%s · +%d" % [String(def.name) if def != null else String(rid), price], &"secondary", &"S")
		sb.name = "SellButton"
		sb.set_meta("relic_id", String(rid))
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
		sb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		sb.icon = UI3.icon("cur_shard")
		sb.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sb.expand_icon = true
		sb.add_theme_constant_override("icon_max_width", UI3Theme.size_of("icon_s"))
		sb.clip_text = true
		sb.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		sb.pressed.connect(_on_shop_sell.bind(String(rid)))
		row.add_child(sb)
		sellable += 1
	if sellable == 0:
		sv.add_child(PanelParts.text(tr("No Core to sell"), "text_body", "text_muted"))
	return sp


func _add_shop_row(raw: Dictionary, index: int) -> PanelContainer:
	var it: Dictionary = raw
	var why := _card_reason(it)
	var card: PanelContainer
	if String(it.get("kind", "")) == "relic":
		card = CoreCard.new()
	else:
		card = Supply.new()
	card.call("setup", it, index, why)
	ctrl._shop_cards.append(card)
	var bb := card.find_child("BuyButton", true, false) as Button
	if why == "" and bb != null:
		bb.pressed.connect(func() -> void: _on_shop_buy(index))
	return card


## Kept only because RunMapController still forwards `_shop_art` (typed call); nothing draws with it any more.
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


## Kept for the controller forwarder and tools/qa captures. No preselect any more (each card has its own Buy): just remembers the last index for the controller.
func _select_shop(index: int) -> void:
	ctrl._shop_sel = index


func _on_shop_sell(relic_id: String) -> void:
	if RunState.sell_relic(relic_id):
		_render_shop()


func _on_shop_buy(index: int) -> void:
	# `bought` is marked inside try_buy_shop_item() now. Marking it here meant a replay, which
	# has no screen, left every item buyable forever.
	var res: Dictionary = await RunState.request_buy_shop_item(index)
	if not is_instance_valid(ctrl):
		return   # the run map was freed while waiting (scene change); the old Node coroutine stopped here
	if not bool(res["ok"]) and String(res["code"]) not in ["illegal", "busy"]:
		NetNotice.show(ctrl, String(res["code"]), _on_shop_buy.bind(index))
	_render_shop()   # rebuild so shard total / afford/bought states stay in sync
