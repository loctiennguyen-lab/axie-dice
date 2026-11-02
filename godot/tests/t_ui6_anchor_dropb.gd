extends Node
## UI-06 L3 (Drop B): 48-anchor-pick data-names, 49 awaken banner, ShopCoreCard emblem + shards, CardArt mapping.
## Liam's rules: nothing preselected, disabled Take says why, only Space shown, text >= 14 px real, labels centred on icons.
## 1920 and 1280 (UI3Theme.set_scale_override). Run: godot --headless --path godot res://tests/t_ui6_anchor_dropb.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const ShopCard := preload("res://scenes/run_map/ui5/ShopCoreCard.gd")
const CARD := ["HouseEmblem", "AnchorName", "HouseLine", "Tagline", "RuleBox", "AwakensBox", "AwakenMeter", "HouseCores", "HouseCoreChip"]
const FRAME := ["AnchorPick", "Header", "Title", "ShardPill", "SubLine", "CardRow", "Glossary", "Footer", "TakeButton"]
const AWAKEN := ["AwakenBanner", "AwakenEmblem", "AwakenKicker", "AwakenName", "AwakenText", "HouseCoresDone", "AwakenMeter",
	"ContinueHint", "CoreSlot", "FamilyEmblem", "TierShards", "HouseDot"]
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _text_sizes(n: Node, sc: float, acc: Array) -> void:
	if (n is Label or n is RichTextLabel) and (n as Control).is_visible_in_tree():
		var txt: String = (n as Label).text if n is Label else (n as RichTextLabel).get_parsed_text()
		if txt.strip_edges() != "":
			var fs: int = (n as Control).get_theme_font_size("font_size" if n is Label else "normal_font_size")
			acc.append([fs * sc, txt.left(20)])
	for c in n.get_children():
		_text_sizes(c, sc, acc)


func _pick_case(ids: Array, reasons: Dictionary, sc: float, tag: String) -> void:
	UI3Theme.set_scale_override(sc)
	AnchorAdapter.test_state = {"open": true, "offer": ids, "reasons": reasons, "picked": []}
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.theme = UI3Theme.get_theme()
	add_child(host)
	var v := AnchorPick.new()
	host.add_child(v)
	v.setup(ids, true)
	await get_tree().process_frame
	await get_tree().process_frame
	for nm in FRAME + CARD:
		_check(v.find_child(nm, true, false) != null or nm == "AnchorPick", "%s: node %s" % [tag, nm])
	var nchips := v.find_children("*HouseCoreChip*", "", true, false).size()
	_check(v.cards.size() == 3 and nchips == 15, "%s: 3 cards x 5 House Core chips (%d)" % [tag, nchips])
	_check(v.selected == -1, "%s: nothing preselected" % tag)
	_check(v.take_button.disabled and v.take_button.text == "Pick an Anchor", "%s: Take disabled and says why" % tag)
	var keys := v.find_children("KeyCap", "", true, false)
	for k in keys:
		_check(not (k as Control).visible or (k.find_child("Key", true, false) as Label).text == "Space", "%s: only Space is shown" % tag)
	for c in v.cards:
		var id := String(c.get("anchor_id"))
		var meter := c.find_child("AwakenMeter", true, false) as Control
		_check(meter != null and (meter.find_child("Count", true, false) as Label).text == "0 / 2", "%s: %s meter 0 / 2" % [tag, id])
		_check(meter.find_child("AwakenPips", true, false).get_child_count() == 2, "%s: %s two pips" % [tag, id])
		var he := c.find_child("HouseEmblem", true, false) as TextureRect
		_check(he != null and he.texture == UI6Assets.house(AnchorAdapter.house_id(id), he.custom_minimum_size.x), "%s: %s house emblem" % [tag, id])
		var tg := c.find_child("Tagline", true, false) as Label
		_check(tg != null and tg.get_theme_color("font_color").is_equal_approx(UI3Theme.color("core_headline")), "%s: %s tagline colour" % [tag, id])
		var rule := c.find_child("RuleText", true, false) as RichTextLabel
		_check(rule != null and rule.text.contains("bgcolor"), "%s: %s rule text has chips" % [tag, id])
		var chips := c.find_children("HouseCoreChip*", "", true, false)
		for ch in chips:
			_check(ch.find_child("FamilyEmblem", true, false) != null and ch.find_child("TierShards", true, false) != null, "%s: chip emblem + shards" % tag)
		var reason := AnchorAdapter.disabled_reason(id)
		var lr := c.find_child("LockedReason", true, false)
		_check((lr != null) == (reason != ""), "%s: %s LockedReason only when locked" % [tag, id])
		if lr != null:
			_check((lr.find_child("Reason", true, false) as Label).text == AnchorAdapter.reason_text(reason), "%s: game locked string" % tag)
			_check((lr.find_child("Reason", true, false) as Label).text.begins_with("Unlocks at stage"), "%s: Unlocks at stage text" % tag)
		_check(absf(c.size.x - UI3Theme.size_of("anchor_card_w")) < 1.0, "%s: card width token" % tag)
	_check(Align.pairs(v) > 0, "%s: align measured pairs" % tag)
	var probs := Align.check(v, 1.5, tag + " ")
	_check(probs.is_empty(), "%s: align %s" % [tag, str(probs)])
	var acc: Array = []
	_text_sizes(v, sc, acc)
	_check(acc.size() > 20, "%s: texts measured (%d)" % [tag, acc.size()])
	for t in acc:
		_check(float(t[0]) >= 13.9, "%s: '%s' is %.1f px" % [tag, t[1], t[0]])
	host.queue_free()
	await get_tree().process_frame


func _owned_ring_case(sc: float, tag: String) -> void:
	UI3Theme.set_scale_override(sc)
	var hc: Array = AnchorAdapter.house_cores("a_volley")
	AnchorAdapter.test_state = {"open": true, "offer": ["a_volley", "a_gambler", "a_kin"], "reasons": {}, "picked": [], "owned": [hc[0]]}
	var card: PanelContainer = preload("res://scenes/run_map/ui5/AnchorCard.gd").new()
	add_child(card)
	card.setup("a_volley")
	var rings := 0
	for ch in card.find_children("HouseCoreChip*", "", true, false):
		if bool(ch.get_meta("owned", false)):
			rings += 1
			_check((ch.get_theme_stylebox("panel") as StyleBoxFlat).border_width_left == 2, "%s: owned chip has the house ring" % tag)
	_check(rings == 1, "%s: exactly the owned Core is ringed (%d)" % [tag, rings])
	card.queue_free()
	await get_tree().process_frame


## 49-anchor-awaken--after: AnchorChip "<House> Awakened" + ui_awaken mark; AnchorTile double frame + AwakenGlyph (the one CorePanel strip
## feeds both the map and the combat HUD, so slot_px 40 = map and 44 = combat are both checked).
func _after_case(sc: float, tag: String) -> void:
	UI3Theme.set_scale_override(sc)
	var hc: Array = AnchorAdapter.house_cores("a_volley")
	for awake in [false, true]:
		AnchorAdapter.test_state = {"anchor_id": "a_volley", "awakened": awake, "owned": [hc[1], hc[2]] if awake else [hc[1]]}
		var chip := CorePanel.house_chip(true, UI3Theme.size_of("anchor_chip_h"))
		add_child(chip)
		var txt := ""
		for l in chip.find_children("*", "Label", true, false):
			txt += (l as Label).text + " "
		_check(chip.find_child("AwakenMark", true, false) != null == awake, "%s after: chip mark only when awakened (%s)" % [tag, str(awake)])
		if awake:
			_check(txt.contains("Awakened") and not txt.contains("·"), "%s after: chip text '%s'" % [tag, txt])
		for px in [40, 44]:
			var host := Control.new()
			host.theme = UI3Theme.get_theme()
			add_child(host)
			var p := CorePanel.new()
			p.slot_px = px
			host.add_child(p)
			p.refresh()
			await get_tree().process_frame
			var tile := p.find_child("AnchorTile", true, false)
			_check(tile != null, "%s after: AnchorTile at %d" % [tag, px])
			if tile != null:
				_check((tile.find_child("AwakenGlyph", true, false) != null) == awake, "%s after: AwakenGlyph %s at %d" % [tag, str(awake), px])
				_check((tile.find_child("AwakeInnerFrame", true, false) != null) == awake, "%s after: double frame %s at %d" % [tag, str(awake), px])
			host.queue_free()
		chip.queue_free()


func _awaken_case(sc: float, tag: String) -> void:
	UI3Theme.set_scale_override(sc)
	var hc: Array = AnchorAdapter.house_cores("a_volley")
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "awakened": true, "owned": [hc[1], hc[2]]}
	var host := Control.new()
	add_child(host)
	UI3Gacha.instant_override = 0   # instant mode frees the node at once
	CombatView.disable_juice_for_tests = false
	var fx := AnchorFx.play(host, "a_volley")
	await get_tree().process_frame
	await get_tree().process_frame
	for nm in AWAKEN:
		_check(fx.find_child(nm, true, false) != null, "%s awaken: node %s" % [tag, nm])
	_check((fx.find_child("AwakenKicker", true, false) as Label).text == "Volley awakens", "%s awaken: kicker text" % tag)
	_check(fx.find_children("CoreSlot*", "", true, false).size() == 2, "%s awaken: the two House Cores" % tag)
	_check((fx.find_child("AwakenMeter", true, false).find_child("Count", true, false) as Label).text == "2 / 2", "%s awaken: meter 2 / 2" % tag)
	var acc: Array = []
	_text_sizes(fx, sc, acc)
	for t in acc:
		_check(float(t[0]) >= 13.9, "%s awaken: '%s' is %.1f px" % [tag, t[1], t[0]])
	_check(Align.pairs(fx) >= 0, "%s awaken: align ran" % tag)
	var probs := Align.check(fx, 1.5, tag + " awaken ")
	_check(probs.is_empty(), "%s awaken: align %s" % [tag, str(probs)])
	fx.skip()
	UI3Gacha.instant_override = 1
	await get_tree().process_frame
	host.queue_free()
	await get_tree().process_frame


func _shop_case(sc: float, tag: String) -> void:
	UI3Theme.set_scale_override(sc)
	var core := ""
	var defs := RelicRegistry.offerable_defs_sorted()
	if not defs.is_empty():
		core = String(defs[0].id)
	var card: PanelContainer = ShopCard.new()
	add_child(card)
	var it := {"key": core, "title": "Test Core", "desc": "Gain 2 Mana.", "cost": 40, "kind": "relic", "rar": 1}
	card.setup(it, 0, "Need 40 Shards")
	_check(card.find_child("FamilyEmblem", true, false) != null and card.find_child("TierShards", true, false) != null, "%s shop: emblem + shards (no relic art)" % tag)
	var bb := card.find_child("BuyButton", true, false) as Button
	_check(bb != null and bb.disabled and bb.text.contains("Shards"), "%s shop: Buy disabled with a reason" % tag)
	card.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	print("=== t_ui6_anchor_dropb: start ===")
	_guard.capture()
	UI3Gacha.instant_override = 1
	for sc in [1.0, 2.0 / 3.0]:
		var tg := "1920" if sc == 1.0 else "1280"
		await _pick_case(["a_volley", "a_gambler", "a_kin"], {}, sc, tg + " none")
		await _pick_case(["a_volley", "a_gambler", "a_mana_mine"], {"a_mana_mine": "stage_locked"}, sc, tg + " locked")
		await _owned_ring_case(sc, tg)
		await _awaken_case(sc, tg)
		await _after_case(sc, tg)
		await _shop_case(sc, tg)
	# art mapping: Serum = shop_heal, Core pick = shop_relic, relics by rarity r0..r4
	_check(CardArt.SHOP_ART["heal"] == "shop_heal" and CardArt.SHOP_ART["core"] == "shop_relic", "CardArt: Serum shop_heal, Core pick shop_relic")
	_check(CardArt.RELIC_ART_BY_RARITY.size() == 5 and CardArt.texture_for_shop("heal") != null and CardArt.texture_for_shop("relic", 4) != null, "CardArt textures load")
	_check(UI6Assets.illustration("node_treasure") != null and UI6Assets.illustration("node_event") != null, "treasure / event paintings load")
	AnchorAdapter.test_state = null
	UI3Theme.set_scale_override(-1.0)
	UI3Gacha.instant_override = -1
	_guard.restore()
	_check(_checks > 150, "the cases really ran (%d checks)" % _checks)
	print("=== t_ui6_anchor_dropb: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	for f in _fails:
		print("FAIL: ", f)
	if _fails.is_empty():
		print("t_ui6_anchor_dropb: PASS")
	get_tree().quit(1 if not _fails.is_empty() else 0)
