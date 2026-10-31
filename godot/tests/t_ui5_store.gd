extends Node
## UI-05 b23 lane S11b: Store against 19-store--* (ui05-meta2-screens.html). Names, tabs, nothing picked at first, Buy
## disabled with a reason (USD off in the playtest), BuyConfirm focus on Not now, Owned, gift button variants (amber
## primary / secondary with a non-overlapping Gem cluster), offline / guest, 1920 + 1280, inside the frame, align pairs
## > 0, text >= 14 real px, no illustrative strings.
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
	print("=== t_ui5_store: start ===")
	_guard.capture()
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc)
	UI3Theme.set_scale_override(1.0)
	_guard.restore()
	print("=== t_ui5_store: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_store: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)


func _screen(state := "normal", remote := false) -> StoreScreen:
	var s: StoreScreen = load("res://scenes/store/StoreScreen.tscn").instantiate()
	s.use_account = false
	s.state = state
	s.remote_on = remote
	s.no_scene_change = true
	s.test_mode = true
	add_child(s)
	return s


func _btn(r: Node, n: String) -> Button:
	return r.find_child(n, true, false) as Button


func _small(root: Node, tag: String, sc: float) -> void:
	var bad := []
	for n in root.find_children("*", "", true, false):
		if (n is Label or n is Button) and (n as Control).is_visible_in_tree() and String(n.text) != "" \
				and float(n.get_theme_font_size("font_size")) * sc < 13.99:
			bad.append(String(n.text))
	_ok(bad.is_empty(), "%s: text >= 14 real px (%s)" % [tag, str(bad)])


func _inside(r: Node, names: Array, tag: String) -> void:
	var vp := get_viewport().get_visible_rect().grow(1.0)
	for n in names:
		var c := r.find_child(n, true, false) as Control
		if c != null:
			_ok(vp.encloses(c.get_global_rect()), "%s: %s inside the frame %s" % [tag, n, str(c.get_global_rect())])


func _pass(sc: float) -> void:
	var tag := "scale %.2f" % sc
	var gem: Dictionary = (load("res://scripts/meta/economy_db.gd") as Script).get_table("gem")
	MetaState.gems_cache = 400
	MetaState.gem_gift_day = ""
	MetaState.cosmetics_owned.clear()
	var s := _screen()
	await _frames(6)
	for n in ["Header", "BackButton", "Title", "SubLine", "GemPacksTab", "CosmeticsTab", "TicketsTab", "MoonCardTab", "Body", "GiftStrip",
			"GiftButton", "Grid", "DetailPlate", "BuyButton"]:
		_ok(s.find_child(n, true, false) != null, "%s: node %s" % [tag, n])
	_ok(s.find_children("GemPackTile*", "", true, false).size() == (gem.store.gem_packs as Array).size(), "%s: pack tiles from data" % tag)
	_ok(get_viewport().gui_get_focus_owner() == _btn(s, "GemPacksTab"), "%s: initial focus on the open tab" % tag)
	_ok(_btn(s, "BuyButton").disabled and _btn(s, "BuyButton").text == "Pick an item", "%s: nothing picked, Buy says Pick an item" % tag)
	_ok(s.selected == "" and s.find_children("GemPackTile*", "Button", true, false).all(func(b: Button) -> bool: return not b.button_pressed), "%s: no tile preselected" % tag)
	var gb := _btn(s, "GiftButton")
	_ok(gb.theme_type_variation == "ButtonPrimary" or gb.theme_type_variation.begins_with("ButtonPrimary"), "%s: gift is an amber primary while no Buy is live" % tag)
	_ok(gb.text == "Claim %d Gem" % int(gem.gift.per_day), "%s: gift amount from data" % tag)
	_ok(Ui5Keycap.all_under(s).is_empty(), "%s: no keycap on the screen" % tag)
	_inside(s, ["Header", "GiftStrip", "DetailPlate"], tag)
	_small(s, tag + " packs", sc)
	_ok(Align.pairs(s) > 0, "%s: align pairs (%d)" % [tag, Align.pairs(s)])
	_ok(Align.check(s).is_empty(), "%s: icon/label centred %s" % [tag, str(Align.check(s))])
	# pick a pack: USD off in the playtest, says why
	var pk: Dictionary = (gem.store.gem_packs as Array)[1]
	_btn(s, "GemPackTile_%d" % int(pk.gems)).pressed.emit()
	await _frames(3)
	_ok(_btn(s, "BuyButton").disabled and _btn(s, "BuyButton").text == StoreScreen.USD_REASON, "%s: USD Buy disabled with the playtest reason" % tag)
	_ok(_btn(s, "GiftButton").theme_type_variation.begins_with("ButtonPrimary"), "%s: gift stays primary while Buy is disabled" % tag)
	# tickets: pick, live Buy -> gift turns secondary with a Gem cluster
	_btn(s, "TicketsTab").pressed.emit()
	await _frames(3)
	var b0: Dictionary = (gem.store.ticket_bundles as Array)[1]
	_ok(s.find_children("TicketTile*", "Button", true, false).size() == (gem.store.ticket_bundles as Array).size(), "%s: ticket tiles" % tag)
	_ok(s.find_children("GemCost", "", true, false).size() == (gem.store.ticket_bundles as Array).size(), "%s: GemCost on each ticket tile" % tag)
	_btn(s, "TicketTile_%d" % int(b0.tickets)).pressed.emit()
	await _frames(3)
	var buy := _btn(s, "BuyButton")
	_ok(not buy.disabled and buy.text == "Buy for %s Gem" % UI3.fmt(int(b0.gems)), "%s: live Buy from data (%s)" % [tag, buy.text])
	_ok(buy.theme_type_variation.begins_with("ButtonPrimary"), "%s: Buy is the amber primary" % tag)
	_ok(_btn(s, "TicketTile_%d" % int(b0.tickets)).button_pressed, "%s: picked ticket tile is pressed" % tag)
	gb = _btn(s, "GiftButton")
	_ok(gb.theme_type_variation.begins_with("ButtonSecondary") and gb.icon == null, "%s: gift secondary while Buy is live" % tag)
	var gi := gb.find_child("GemIcon", true, false) as Control
	var gt := gb.find_child("GemText", true, false) as Control
	_ok(gi != null and gt != null, "%s: Gem cluster present" % tag)
	if gi != null and gt != null:
		var ri := Rect2(gi.global_position, gi.size)
		var rt := Rect2(gt.global_position, gt.size)
		_ok(ri.end.x <= rt.position.x + 0.5 and not ri.intersects(rt), "%s: Gem icon does not overlap the text" % tag)
	_ok(Align.check(s).is_empty(), "%s: tickets centred %s" % [tag, str(Align.check(s))])
	_small(s, tag + " tickets", sc)
	# BuyConfirm
	buy.pressed.emit()
	await _frames(4)
	for n in ["BuyConfirm", "Title", "Body", "CostRow", "Footer", "NotNowButton", "KeyCap", "Scrim"]:
		_ok(s.find_child(n, true, false) != null, "%s: confirm node %s" % [tag, n])
	_ok(get_viewport().gui_get_focus_owner() == _btn(s, "NotNowButton"), "%s: confirm focus on Not now" % tag)
	_ok(Ui5Keycap.all_under(_btn(s, "NotNowButton")).size() == 1 and Ui5Keycap.text_of(Ui5Keycap.all_under(_btn(s, "NotNowButton"))[0] as PanelContainer) == "Space", "%s: Space cap on Not now only" % tag)
	_inside(s, ["BuyConfirm"], tag)
	_small(s, tag + " confirm", sc)
	var held := MetaState.gem_wallet().balance()
	s.close_modal()
	await _frames(2)
	_ok(MetaState.gem_wallet().balance() == held and s.find_child("BuyConfirm", true, false) == null, "%s: Not now spends nothing" % tag)
	# cosmetics: pick, buy, Owned
	_btn(s, "CosmeticsTab").pressed.emit()
	await _frames(3)
	var items := s.cosmetic_items()
	_ok(s.find_children("CosmeticTile*", "Button", true, false).size() == items.size(), "%s: cosmetic tiles" % tag)
	var it: Dictionary = items[0]
	MetaState.gems_cache = 5000
	_btn(s, "CosmeticTile_" + String(it.id)).pressed.emit()
	await _frames(3)
	_ok(_btn(s, "CosmeticTile_" + String(it.id)).button_pressed, "%s: picked cosmetic tile is pressed" % tag)
	for ci in items:
		var nl := _btn(s, "CosmeticTile_" + String(ci.id)).get_node("Col").get_child(2) as Label
		var dn := CosmeticTile.display_name(String(ci.id))
		_ok(nl.text == (dn if dn != "" else String(ci.id)), "%s: tile name = manifest name (%s)" % [tag, nl.text])
	_ok(not _btn(s, "BuyButton").disabled and _btn(s, "BuyButton").text == "Buy for %s Gem" % UI3.fmt(int(it.price)), "%s: cosmetic Buy price from data" % tag)
	_ok(s.buy_cosmetic(String(it.id), String(it.rarity)) == "", "%s: cosmetic bought" % tag)
	await _frames(3)
	_ok(_btn(s, "OwnedButton") != null and _btn(s, "OwnedButton").disabled, "%s: tile OwnedButton" % tag)
	_ok(_btn(s, "BuyButton").disabled and _btn(s, "BuyButton").text == "Owned", "%s: Buy says Owned" % tag)
	_ok(s.find_child("ResultLine", true, false) != null and s.find_child("ToneDisc", true, false) != null, "%s: result line with ToneDisc" % tag)
	# short of Gem
	MetaState.gems_cache = 10
	var it2: Dictionary = items[items.size() - 1]
	s.select("cos_" + String(it2.id))
	await _frames(3)
	_ok(_btn(s, "BuyButton").disabled and _btn(s, "BuyButton").text == "Buy · need %d more Gem" % (int(it2.price) - 10), "%s: short of Gem says how many (%s)" % [tag, _btn(s, "BuyButton").text])
	_small(s, tag + " cosmetics", sc)
	_ok(Align.check(s).is_empty(), "%s: cosmetics centred %s" % [tag, str(Align.check(s))])
	# moon card
	_btn(s, "MoonCardTab").pressed.emit()
	await _frames(3)
	_ok(s.find_child("MoonCardTile", true, false) != null, "%s: MoonCardTile" % tag)
	_ok(_btn(s, "BuyButton").disabled and _btn(s, "BuyButton").text == "Buy Moon Card · Coming soon", "%s: Moon Buy disabled, Coming soon" % tag)
	# gift claimed / full
	MetaState.gems_cache = 0
	MetaState.gem_gift_day = ""
	s.set_tab("tickets")
	s.claim_gift()
	await _frames(3)
	_ok(_btn(s, "GiftButton").disabled and _btn(s, "GiftButton").text == "Claim %d Gem · Already claimed today" % int(gem.gift.per_day), "%s: gift claimed says why" % tag)
	MetaState.gem_gift_day = ""
	MetaState.gems_cache = int(gem.gift.balance_cap)
	s._refresh()
	await _frames(2)
	_ok(_btn(s, "GiftButton").text.ends_with("Gem full"), "%s: gift Gem full" % tag)
	s.queue_free()
	await _frames(2)
	# offline / guest
	MetaState.gems_cache = 400
	MetaState.gem_gift_day = ""
	var o := _screen("offline", true)
	await _frames(5)
	_ok(o.find_child("Banner", true, false) != null and _btn(o, "GiftButton").text.ends_with("Needs a connection"), "%s: offline banner + gift reason" % tag)
	o.set_tab("tickets")
	o.select("ticket_%d" % int(b0.tickets))
	await _frames(3)
	_ok(_btn(o, "BuyButton").disabled and _btn(o, "BuyButton").text == "Needs a connection", "%s: offline Buy reason" % tag)
	_inside(o, ["Banner", "GiftStrip", "DetailPlate"], tag + " offline")
	o.queue_free()
	await _frames(2)
	var g := _screen("guest", true)
	await _frames(5)
	_ok(_btn(g, "SignInButton") != null, "%s: guest SignInButton" % tag)
	_btn(g, "SignInButton").pressed.emit()
	_ok(g.sign_in_calls == 1, "%s: Sign in hook" % tag)
	g.set_tab("tickets")
	g.select("ticket_%d" % int(b0.tickets))
	await _frames(3)
	_ok(_btn(g, "BuyButton").text == "Sign in to spend Gem" and _btn(g, "GiftButton").text.ends_with("Sign in to claim"), "%s: guest reasons" % tag)
	_small(g, tag + " guest", sc)
	var txt := ""
	for n in g.find_children("*", "", true, false):
		if n is Label:
			txt += (n as Label).text + "\n"
	for bad in ["Jade Sprout", "Luna Heart Crown", "Next claim Fri", "need 320"]:
		_ok(not txt.contains(bad), "%s: no illustrative string %s" % [tag, bad])
	g.queue_free()
	await _frames(2)
