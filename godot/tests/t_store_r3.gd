extends Node
## M7 Store + M8 Daily R3: gem goods buy through StoreCatalog/GemWallet, can't overspend, USD buttons
## disabled, Gem gift and daily reward claim once, offline/guest only block with the remote flag.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _ready() -> void:
	print("=== t_store_r3: start ===")
	_guard.capture()
	var econ := load("res://scripts/meta/economy_db.gd") as Script
	var gem: Dictionary = econ.get_table("gem")
	var bundles: Array = gem.store.ticket_bundles
	MetaState.gems_cache = 0
	MetaState.gem_gift_day = ""
	MetaState.tickets["normal"] = 0
	var s: StoreScreen = load("res://scenes/store/StoreScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	add_child(s)
	await get_tree().process_frame
	# M7a main state: gift strip, USD buttons disabled
	_ok((s.find_child("ClaimGift", true, false) as Button).text == "Claim %d Gem" % int(gem.gift.per_day), "gift button from data")
	_ok(not (s.find_child("ClaimGift", true, false) as Button).disabled, "gift claimable when empty")
	MetaState.gems_cache = 1000
	s._refresh()
	_ok((s.find_child("ClaimGift", true, false) as Button).disabled, "gift disabled when full, says why")
	var db := s.find_child("DetailBuy", true, false) as Button
	_ok(db.disabled and db.text == StoreScreen.USD_REASON, "USD buy disabled once, in the detail plate, with reason")
	var packs: Array = gem.store.gem_packs
	_ok(packs.size() == 6, "6 packs from gem.json")
	for pk in packs:
		var b := s.find_child("Usd_%d" % int(pk.gems), true, false) as Button
		_ok(b != null and b.text == "", "USD pack %d tile selects" % int(pk.gems))
		s.select("usd_%d" % int(pk.gems))
		db = s.find_child("DetailBuy", true, false) as Button
		_ok(db.disabled and db.text == StoreScreen.USD_REASON, "USD pack %d buy disabled with reason" % int(pk.gems))
	_ok(s.find_child("Tab_moon", true, false) != null and s.find_child("Tab_cosmetics", true, false) != null, "tabs")
	_ok(s.find_child("Currencies", true, false) != null, "currency plate")
	# tickets tab: prices from data, purchase through the wallet
	s.set_tab("tickets")
	await get_tree().process_frame
	for bd in bundles:
		_ok(s.find_child("Ticket_%d" % int(bd.tickets), true, false) != null, "bundle %d shown" % int(bd.tickets))
	var b6: Dictionary = bundles[0]
	_ok(s.buy_bundle(int(b6.tickets)) == "", "buy bundle ok")
	_ok(MetaState.gem_wallet().balance() == 1000 - int(b6.gems) and int(MetaState.tickets.normal) == int(b6.tickets), "gems spent, tickets granted")
	# cannot overspend
	var big: Dictionary = bundles[bundles.size() - 1]
	MetaState.gems_cache = int(big.gems) - 10
	var before := int(MetaState.tickets.normal)
	_ok(s.buy_bundle(int(big.tickets)) == "need 10 more Gem", "short: shows missing amount")
	_ok(int(MetaState.tickets.normal) == before and MetaState.gem_wallet().balance() == int(big.gems) - 10, "short: nothing changed")
	s._refresh()
	s.select("ticket_%d" % int(big.tickets))
	var bb := s.find_child("DetailBuy", true, false) as Button
	_ok(bb.disabled and bb.text == "need 10 more Gem", "short bundle greyed with reason")
	# confirm modal focuses Not now
	MetaState.gems_cache = 5000
	s.open_confirm("x", "y", 10, func() -> void: pass)
	await get_tree().process_frame
	_ok((s.find_child("NotNow", true, false) as Button).has_focus(), "confirm focus on Not now")
	var primaries := 0
	for n in s.find_children("*", "Button", true, false):
		if (n as Button).theme_type_variation.begins_with("ButtonPrimary") and (n as Button).is_visible_in_tree():
			primaries += 1
	_ok(primaries == 2, "one primary on the screen + the open dialog's own")
	s.close_modal()
	# cosmetics
	s.set_tab("cosmetics")
	var items: Array = s.cosmetic_items()
	_ok(items.size() == 8, "4 x 2 cosmetics")
	var it: Dictionary = items[0]
	var g0 := MetaState.gem_wallet().balance()
	_ok(s.buy_cosmetic(it.id, it.rarity) == "", "buy cosmetic")
	s._refresh()
	s.select("cos_" + String(it.id))
	var ob := s.find_child("DetailBuy", true, false) as Button
	_ok(ob.disabled and ob.text == "Owned", "owned cosmetic says Owned")
	_ok(MetaState.cosmetics_owned.has(it.id) and MetaState.gem_wallet().balance() == g0 - int(it.price), "owned, price from data")
	_ok(s.buy_cosmetic(it.id, it.rarity) == "owned" and MetaState.gem_wallet().balance() == g0 - int(it.price), "no double buy")
	# moon card disabled
	s.set_tab("moon")
	await get_tree().process_frame
	var mb := s.find_child("MoonBuy", true, false) as Button
	_ok(mb.disabled and mb.text == "Coming soon", "Moon Card buy disabled, says Coming soon")
	# gift claim once
	MetaState.gem_gift_day = ""
	MetaState.gems_cache = 0
	var c1 := s.claim_gift()
	var c2 := s.claim_gift()
	_ok(bool(c1.ok) and not bool(c2.ok) and MetaState.gem_wallet().balance() == int(gem.gift.per_day), "gift claims once")
	# offline blocks with remote flag, info only without
	s.set_state("offline")
	_ok(s.block_reason(1) != "" and s.find_child("Banner", true, false) != null, "remote: offline blocks spending")
	s.remote_on = false
	s.set_state("guest")
	_ok(s.block_reason(1) == "" and s.find_child("Banner", true, false) != null, "local: guest banner only")
	s.set_state("loading")
	_ok(s.find_child("Result", true, false) == null, "loading renders")
	s.queue_free()
	# Daily
	var d: DailyScreen = load("res://scenes/daily/DailyScreen.tscn").instantiate()
	d.use_account = false
	d.remote_on = true
	d.no_scene_change = true
	d.day_override = MetaState.today_utc()
	MetaState.daily_date = ""
	MetaState.gem_gift_day = ""
	MetaState.gems_cache = 0
	add_child(d)
	await get_tree().process_frame
	var shards := MetaState.shard_pool
	_ok(not (d.find_child("ClaimDaily", true, false) as Button).disabled, "daily claimable")
	_ok(d.claim_daily() and MetaState.shard_pool > shards, "daily claim grants")
	var after := MetaState.shard_pool
	_ok(not d.claim_daily() and MetaState.shard_pool == after, "daily claims once")
	_ok((d.find_child("ClaimDaily", true, false) as Button).disabled, "daily button disabled after claim")
	_ok(bool(d.claim_gift().ok) and not bool(d.claim_gift().ok), "daily gem gift once")
	MetaState.gems_cache = 900
	MetaState.gem_gift_day = ""
	d._refresh()
	_ok(d.gift_state() == "cap" and (d.find_child("ClaimGift", true, false) as Button).disabled, "gift at cap: nothing to claim")
	MetaState.daily_date = ""
	d.set_state("guest")
	_ok(not d.claim_daily() and MetaState.daily_date == "", "remote guest cannot claim")
	d.queue_free()
	_guard.restore()
	if _fail.is_empty():
		print("t_store_r3: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_store_r3: FAIL")
		get_tree().quit(1)
