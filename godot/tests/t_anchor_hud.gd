extends Node
## Lane AU2 job 2: Anchor tile (56 px, head of CoreSlots), x/2 chip out of combat, x/2 badge in combat -> xN when awakened,
## house ring + glyph on house Cores, "1/2 -> AWAKEN" chip on the card that would awaken (and nothing about the next pick).

var _fail := 0
var _checks := 0
var _guard := SaveGuard.new()
var RMC = load("res://scenes/run_map/RunMapController.gd")


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail += 1
		print("FAIL: ", msg)


func _ready() -> void:
	print("=== t_anchor_hud: start ===")
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	var host := Control.new()
	host.theme = UI3Theme.get_theme()
	add_child(host)
	# no Anchor: nothing new in the panel
	AnchorAdapter.test_state = {"anchor_id": ""}
	var p := CorePanel.new()
	host.add_child(p)
	p.refresh()
	_ok(p.anchor_slot == null and p.find_child("AnchorSlot", true, false) == null and p.find_child("HouseChip", true, false) == null, "no Anchor, no tile, no chip")
	# Anchor, 0 house Cores
	var st := {"anchor_id": "a_volley", "owned": [], "awakened": false}
	AnchorAdapter.test_state = st
	RunState.owned_relic_ids.clear()
	_ok(p.refresh() and p.anchor_slot != null, "panel shows with only an Anchor")
	var slots := p.find_child("CoreSlots", true, false)
	_ok(slots.get_child(0) == p.anchor_slot and p.anchor_slot.custom_minimum_size == Vector2(56, 56), "Anchor tile first, 56 px")
	_ok(slots.get_child(1) is VSeparator, "thin divider after the tile")
	var chip := p.find_child("HouseChip", true, false)
	_ok(chip != null and (chip.find_child("Text", true, false) as Label).text.contains("House Cores 0/2 · awakens "), "chip out of combat: House Cores 0/2")
	_ok(p.find_children("CoreSlot_*", "PanelContainer", true, false).size() == 6, "the 6 Core slots keep their count")
	# 1 house Core -> ring + glyph on that slot only
	RunState.owned_relic_ids.append("c_sonic_shield")
	RunState.owned_relic_ids.append("c_mana_pool")
	st["owned"] = ["c_sonic_shield", "c_mana_pool"]
	p.refresh()
	_ok((p.find_child("HouseChip", true, false).find_child("Text", true, false) as Label).text.contains("House Cores 1/2 · awakens "), "chip counts 1/2")
	var marked := 0
	for s in p.find_children("CoreSlot_*", "PanelContainer", true, false):
		if s.find_child("HouseRing", true, false) != null:
			marked += 1
			_ok(s.find_child("HouseGlyph", true, false) != null and str(s.get_meta("ui3_tip", "")).contains("House Core of Volley"), "marked slot has glyph + tooltip line")
	_ok(marked == 1, "only the house Core is ringed")
	_ok(str(p.anchor_slot.get_meta("ui3_tip", "")).contains("Awakens:") and str(p.anchor_slot.get_meta("ui3_tip", "")).contains("1/2"), "tile tooltip: awaken + count")
	# combat HUD: no chip row, badge x/2, then xN
	var cp := CorePanel.new()
	cp.show_counts = true
	host.add_child(cp)
	cp.refresh()
	_ok(cp.find_child("HouseChip", true, false) == null, "combat: no chip row")
	var badge := cp.anchor_slot.find_child("AnchorBadge", true, false) as Label
	_ok(badge.visible and badge.text == "1/2", "combat badge shows 1/2")
	# awakened
	st["awakened"] = true
	st["owned"] = ["c_sonic_shield", "c_mana_pool", "c_thorn_shield"]
	RunState.owned_relic_ids.append("c_thorn_shield")
	cp.refresh()
	badge = cp.anchor_slot.find_child("AnchorBadge", true, false) as Label
	_ok(cp.anchor_slot.find_child("AwakeInnerFrame", true, false) != null and cp.anchor_slot.find_child("AwakenGlyph", true, false) != null, "awakened: double frame + glyph")
	_ok(not badge.visible, "awakened and 0 fires: no badge (never two badges)")
	EventBus.core_fired.emit("a_volley", 1, 3, "anchor")
	EventBus.core_fired.emit("a_volley", 1, 3, "awaken")
	badge = cp.anchor_slot.find_child("AnchorBadge", true, false) as Label
	_ok(badge.visible and badge.text == "x2", "awakened badge counts fires: x2")
	p.refresh()
	_ok(p.find_child("HouseChip", true, false).get_meta("state") == "awakened", "out of combat: chip becomes Awakened")
	# card chip
	st["awakened"] = false
	st["owned"] = ["c_sonic_shield"]
	var card := PanelContainer.new()
	host.add_child(card)
	var chips := HFlowContainer.new()
	card.add_child(chips)
	RMC._add_house_chip(card, chips, "c_thorn_shield")
	var ac := chips.find_child("AwakenChip", true, false)
	_ok(ac != null and (ac.find_child("Text", true, false) as Label).text == "1/2 → AWAKEN", "card that awakens: 1/2 -> AWAKEN")
	_ok(card.find_child("AwakenEdge", true, false) != null, "card gets the 2 px edge")
	var card2 := PanelContainer.new()
	host.add_child(card2)
	var chips2 := HFlowContainer.new()
	card2.add_child(chips2)
	RMC._add_house_chip(card2, chips2, "c_sonic_shield")   # already owned: not a new Core
	_ok(chips2.find_child("AwakenChip", true, false) == null, "an owned Core does not promise awaken")
	var card3 := PanelContainer.new()
	host.add_child(card3)
	var chips3 := HFlowContainer.new()
	card3.add_child(chips3)
	RMC._add_house_chip(card3, chips3, "c_living_wall")
	_ok(chips3.find_child("AwakenChip", true, false) != null, "other house Core at 1/2 awakens too")
	var card4 := PanelContainer.new()
	host.add_child(card4)
	var chips4 := HFlowContainer.new()
	card4.add_child(chips4)
	RMC._add_house_chip(card4, chips4, "c_mana_pool")   # not a Volley house Core
	_ok(chips4.get_child_count() == 0, "non-house Core: nothing added")
	st["owned"] = []
	var card5 := PanelContainer.new()
	host.add_child(card5)
	var chips5 := HFlowContainer.new()
	card5.add_child(chips5)
	RMC._add_house_chip(card5, chips5, "c_living_wall")
	_ok(chips5.find_child("AwakenChip", true, false) == null and chips5.find_child("HouseChip", true, false) != null, "at 0/2: plain House chip")
	for n in chips5.get_children():
		for l in n.find_children("*", "Label", true, false):
			_ok(not (l as Label).text.to_lower().contains("tier"), "no word about the next pick tier")
	# the three newer Anchors: tile glyph/colour from data, house Core ring + tooltip with the house name
	for aid in ["a_kin", "a_embers", "a_big_hand"]:
		var hc: Array = AnchorAdapter.house_cores(aid)
		var st2 := {"anchor_id": aid, "owned": [hc[0]], "awakened": false}
		AnchorAdapter.test_state = st2
		RunState.owned_relic_ids.clear()
		RunState.owned_relic_ids.append(String(hc[0]))
		var p2 := CorePanel.new()
		host.add_child(p2)
		p2.refresh()
		_ok(p2.anchor_slot != null, "%s tile shown" % aid)
		var house := AnchorAdapter.house_id(aid)
		_ok(p2.anchor_slot.find_child("HouseGlyph", true, false) != null or p2.anchor_slot.find_children("*", "TextureRect", true, false).size() > 0, "%s tile has a glyph" % aid)
		_ok((p2.find_child("HouseChip", true, false).find_child("Text", true, false) as Label).text.contains("House Cores 1/2"), "%s chip 1/2" % aid)
		var ring := 0
		for s2 in p2.find_children("CoreSlot_*", "PanelContainer", true, false):
			if s2.find_child("HouseRing", true, false) != null:
				ring += 1
				_ok(str(s2.get_meta("ui3_tip", "")).contains("House Core of " + AnchorAdapter.house_name(house)), "%s ring tooltip names the house" % aid)
		_ok(ring == 1, "%s one ringed Core" % aid)
		st2["awakened"] = true
		p2.refresh()
		_ok(p2.anchor_slot.find_child("AwakeInnerFrame", true, false) != null, "%s awakened frame" % aid)
	AnchorAdapter.test_state = null
	_guard.restore()
	print("=== t_anchor_hud: %d checks, %d failure(s) ===" % [_checks, _fail])
	if _fail == 0:
		print("t_anchor_hud: PASS")
	get_tree().quit(1 if _fail > 0 else 0)
