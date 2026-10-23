extends Node
## Anchor pick overlay (lane AU2, design/ux/anchor-mvp.md section 1): 3 cards with RULE / PRICE / Awakens / 5 House Cores,
## Take disabled with a reason until a pick, no Reroll / Skip, the flip-skip click is not a pick, 1/2/3 select, G6 disabled card.

var _fail := 0
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail += 1
		print("FAIL: ", msg)


func _ready() -> void:
	print("=== t_anchor_pick_ui: start ===")
	_guard.capture()
	UI3Gacha.instant_override = 1
	var st := {"open": true, "offer": ["a_volley", "a_gambler", "a_mana_mine"], "reasons": {"a_gambler": "rule_too_few_house_cores"},
		"picked": []}
	AnchorAdapter.test_state = st
	_ok(AnchorAdapter.offer_open() and AnchorAdapter.offer().size() == 3, "adapter reads the offer")
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.theme = UI3Theme.get_theme()
	add_child(host)
	var v := AnchorPick.new()
	host.add_child(v)
	v.setup(AnchorAdapter.offer(), true)
	await get_tree().process_frame
	_ok(v.cards.size() == 3, "3 cards")
	_ok(v.find_child("RerollButton", true, false) == null and v.find_child("SkipButton", true, false) == null, "no Reroll / Skip")
	_ok(v.take_button.disabled and v.take_button.text == "Pick one Anchor.", "Take disabled with a reason before a pick")
	for c in v.cards:
		var id := String(c.get_meta("anchor_id"))
		_ok(c.find_child("RuleText", true, false) != null and (c.find_child("RuleText", true, false) as Label).text != "", "%s RULE" % id)
		_ok((c.find_child("PriceText", true, false) != null) == (AnchorAdapter.price_text(id) != ""), "%s PRICE shown only when the Anchor has a price" % id)
		_ok((c.find_child("AwakenCondition", true, false) as Label).text.contains("hold 2 of these 5 Cores"), "%s Awakens rule + hold 2" % id)
		_ok(c.find_child("AwakenName", true, false) != null and (c.find_child("AwakenName", true, false) as Label).text != "", "%s awaken name" % id)
		var hc := c.find_child("HouseCores", true, false)
		_ok(hc != null and hc.get_child_count() == 5, "%s has 5 House Core icons" % id)
		for ic in hc.get_children():
			_ok((ic as Control).custom_minimum_size.x >= 44.0, "icon hit area >= 44")
	_ok(v.cards[1].find_child("DisabledReason", true, false) != null, "G6: disabled card says why")
	v.select(1)
	_ok(v.selected == -1, "a disabled card cannot be selected")
	v.select(0)
	_ok(v.selected == 0 and v.take_button.text == "Take Volley" and not v.take_button.disabled, "pick marks card, Take names it")
	v.select(0)
	_ok(v.selected == 0, "clicking the chosen card again keeps it")
	v.take_button.pressed.emit()
	_ok((st["picked"] as Array) == ["a_volley"], "Take goes through AnchorAdapter.pick")
	# the click that skips the flip is not a pick
	UI3Gacha.instant_override = -1
	var v2 := AnchorPick.new()
	host.add_child(v2)
	v2.setup(AnchorAdapter.offer(), true)
	v2.reveal.running = true
	v2.select(0)
	_ok(v2.selected == -1, "no pick while the flip is running")
	v2.reveal.running = false
	var key := InputEventKey.new()
	key.keycode = KEY_3
	key.pressed = true
	v2.reveal.skip()
	v2._unhandled_key_input(key)
	_ok(v2.selected == 2, "key 3 selects the third card")
	# the three newer Anchors: house glyph + colour + rule text all come from data
	UI3Gacha.instant_override = 1
	AnchorAdapter.test_state = {"open": true, "offer": ["a_kin", "a_embers", "a_big_hand"], "reasons": {}, "picked": []}
	var v3 := AnchorPick.new()
	host.add_child(v3)
	v3.setup(AnchorAdapter.offer(), true)
	await get_tree().process_frame
	_ok(v3.cards.size() == 3, "new Anchors: 3 cards")
	var seen_col := {}
	for c in v3.cards:
		var id3 := String(c.get_meta("anchor_id"))
		var h := AnchorAdapter.house_id(id3)
		_ok(h != "" and AnchorAdapter.house_icon(h) != "ui_mooncard", "%s has its own house glyph" % id3)
		_ok(AnchorAdapter.house_color(h) != UI3Theme.color("text_muted"), "%s has a house colour token" % id3)
		seen_col[AnchorAdapter.house_color(h).to_html()] = true
		_ok((c.find_child("RuleText", true, false) as Label).text == AnchorAdapter.rule_text(id3) and AnchorAdapter.rule_text(id3) != "", "%s rule text" % id3)
		_ok((c.find_child("PriceText", true, false) != null) == (AnchorAdapter.price_text(id3) != ""), "%s price" % id3)
		_ok((c.find_child("AwakenName", true, false) as Label).text == AnchorAdapter.awaken_name(id3), "%s awaken name" % id3)
		_ok(c.find_child("HouseCores", true, false).get_child_count() == 5, "%s 5 house cores" % id3)
	_ok(seen_col.size() == 3, "3 distinct house colours")
	AnchorAdapter.test_state = null
	UI3Gacha.instant_override = -1
	_guard.restore()
	print("=== t_anchor_pick_ui: %d checks, %d failure(s) ===" % [_checks, _fail])
	if _fail == 0:
		print("t_anchor_pick_ui: PASS")
	get_tree().quit(1 if _fail > 0 else 0)
