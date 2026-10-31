extends Node
## UI-05 b23 lane R5a: the Shop against shop--stock / --sold-out / --cant-afford (round-2 ui05-run-screens.html).
## Names, stock / bought / sold-out / can't-afford states, sell prices = RelicSlots.sell_price at A0 and A1, 1920 + 1280,
## align check (> 0 pairs), real text >= 14 px at 1280, initial focus, Space cap only on the enabled Leave button.
const Align := preload("res://tests/ui5_align_check.gd")
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _frames(n := 4) -> void:
	for _i in n:
		await get_tree().process_frame


func _ready() -> void:
	print("=== t_ui5_shop: start ===")
	_guard.capture()
	await _frames(1)
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(795, team, "short", 0, false)
	for asc in [0, 1]:
		for sc in [1.0, 2.0 / 3.0]:
			UI3Theme.set_scale_override(sc)
			RunState.ascension = asc
			await _pass(sc, asc)
	UI3Theme.set_scale_override(1.0)
	_guard.restore()
	print("=== t_ui5_shop: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_shop: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)


func _item(key: String, bought: bool) -> Dictionary:
	var def = RelicRegistry.get_def(key)
	return {"kind": "relic", "key": key, "title": String(def.name), "desc": RewardGenerator.relic_desc(def),
		"rar": def.rarity, "cost": RewardGenerator.RELIC_SHOP_COST[clampi(int(def.rarity), 0, 4)], "bought": bought}


func _supplies(sold_core := false) -> Array:
	return [
		{"kind": "heal", "title": "Serum", "desc": "One Axie gains 10 Max HP", "cost": RewardGenerator.HEAL_ITEM_COST, "bought": false, "rar": 0},
		{"kind": "reroll", "title": "Instinct", "desc": "1 extra maximum Reroll", "cost": RewardGenerator.REROLL_ITEM_COST, "bought": false, "rar": 0},
		{"kind": "core", "tier": 0, "title": "Core Pick", "desc": "Choose 1 of 3 Moss Cores (after you leave the shop)", "cost": 60, "bought": sold_core, "rar": 0},
	]


func _small(root: Node, tag: String, sc: float) -> void:
	var bad := []
	for n in root.find_children("*", "", true, false):
		if n is Label and (n as Label).is_visible_in_tree() and (n as Label).text != "" \
				and float((n as Label).get_theme_font_size("font_size")) * sc < 13.99:
			bad.append((n as Label).text)
		elif n is Button and (n as Button).is_visible_in_tree() and (n as Button).text != "" \
				and float((n as Button).get_theme_font_size("font_size")) * sc < 13.99:
			bad.append((n as Button).text)
	_ok(bad.is_empty(), "%s: text >= 14 real px (%s)" % [tag, str(bad)])


func _pass(sc: float, asc: int) -> void:
	var tag := "scale %.2f A%d" % [sc, asc]
	RunState.owned_relic_ids.assign(["c_bastion", "c_backline_glow", "r_ironvow"])
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	await _frames(6)
	# --- stock: 100 shards, two affordable Cores
	RunState.shards_this_run = 100
	var items: Array[Dictionary] = []
	items.append_array([_item("c_bastion", false), _item("c_backline_glow", false)])
	items.append_array(_supplies())
	RunState.shop_items.assign(items)
	m.call("_render_shop")
	await _frames()
	for n in ["Shop", "Header", "Title", "RowLabel", "ShardPill", "CoreStock", "ShopCoreCard", "CoreName", "TierChip", "CategoryChip",
			"RuleText", "BuyButton", "SupplyStock", "SupplyItem", "SellColumn", "SellRow", "CoreSlot", "SellButton", "LeaveButton", "KeyCap"]:
		_ok(m.find_child(n, true, false) != null, "%s: node %s" % [tag, n])
	_ok(m.find_child("Notice", true, false) == null, "%s: no notice while something is affordable" % tag)
	_ok(m.find_children("ShopCoreCard*", "", true, false).size() == 2 and m.find_children("SupplyItem*", "", true, false).size() == 3, "%s: 2 Core cards + 3 supplies" % tag)
	var first := (m.find_children("BuyButton", "Button", true, false)[0]) as Button
	_ok(not first.disabled and first.text == "Buy · %d Shards" % int(items[0]["cost"]), "%s: first Buy shows the data price (%s)" % [tag, first.text])
	_ok(get_viewport().gui_get_focus_owner() == first, "%s: initial focus on the first enabled Buy" % tag)
	_ok(Ui5Keycap.all_under(m).size() == 1, "%s: one keycap (Space on Leave)" % tag)
	var sells := m.find_children("SellButton", "Button", true, false)
	_ok(sells.size() == 3, "%s: 3 sell rows" % tag)
	for sb in sells:
		var rid := String((sb as Button).get_meta("relic_id"))
		var want := "%s · +%d" % [String(RelicRegistry.get_def(rid).name), RelicSlots.sell_price(rid, asc)]
		_ok((sb as Button).text == want, "%s: sell text '%s' == '%s'" % [tag, (sb as Button).text, want])
	_small(m, tag + " stock", sc)
	_ok(Align.pairs(m) > 0, "%s: align check measured pairs (%d)" % [tag, Align.pairs(m)])
	_ok(Align.check(m).is_empty(), "%s: icon/label centred %s" % [tag, str(Align.check(m))])
	# --- sold out + short on shards
	RunState.shards_this_run = 25
	items = [_item("c_bastion", true), _item("c_backline_glow", false)]
	items.append_array(_supplies(true))
	RunState.shop_items.assign(items)
	m.call("_render_shop")
	await _frames()
	var bbs := m.find_children("BuyButton", "Button", true, false)
	_ok((bbs[0] as Button).text == "Bought" and (bbs[0] as Button).disabled, "%s: bought Core says Bought" % tag)
	_ok((bbs[1] as Button).text == "Need %d Shards" % int(items[1]["cost"]) and (bbs[1] as Button).disabled, "%s: short on shards says Need N" % tag)
	_ok((bbs[4] as Button).text == "Sold out" and (bbs[4] as Button).disabled, "%s: sold-out supply" % tag)
	_ok(Ui5Keycap.all_under(m).size() == 1, "%s: still only the Leave keycap (none on disabled buys)" % tag)
	# --- nothing affordable: notice, focus on Leave
	RunState.shards_this_run = 0
	m.call("_render_shop")
	await _frames()
	_ok(m.find_child("Notice", true, false) != null, "%s: notice when nothing is affordable" % tag)
	_ok(get_viewport().gui_get_focus_owner() == m.find_child("LeaveButton", true, false), "%s: focus falls to Leave" % tag)
	_small(m, tag + " cant-afford", sc)
	m.queue_free()
	await _frames(2)
