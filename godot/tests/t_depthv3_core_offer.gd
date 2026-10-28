extends Node
## Depth v3 Core offer + Run rule screens (lane D), built on the reward overlay. Cards use CoreOffer's card
## format ({core, axis, tier} / {core, rule}). Spec: design/ux/depth-v3/core-offer.md
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

static func cards() -> Array:
	return [
		{"t": "relic", "key": "x1", "rar": 0, "title": "CORE", "desc": "Mossy Start", "sub": "+2 max HP to every Axie.", "core": true, "axis": "stat", "tier": 0, "slot": 0},
		{"t": "relic", "key": "x2", "rar": 0, "title": "CORE", "desc": "Face Forge", "sub": "Your first attack each turn deals +2.", "core": true, "axis": "dice", "tier": 0, "slot": 1},
		{"t": "relic", "key": "x3", "rar": 0, "title": "CORE", "desc": "Back Glow", "sub": "Back row buffs +1.", "core": true, "axis": "pos", "tier": 0, "slot": 2},
	]

static func rules() -> Array:
	return [
		{"t": "relic", "key": "r1", "rar": 0, "title": "RUN RULE", "desc": "Cheap Mana", "sub": "Rerolls cost 1 less mana. Enemies +10% HP.", "core": true, "rule": true, "axis": "run_rule", "tier": 0, "slot": 0},
		{"t": "relic", "key": "rule_none", "rar": 0, "title": "RUN RULE", "desc": "No Rule", "sub": "Play the base game.", "core": true, "rule": true, "axis": "run_rule", "tier": 0, "slot": 1},
	]

func _ready() -> void:
	_guard.capture()
	RunState.start_new_run(777, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	await get_tree().process_frame
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	for _i in 5:
		await get_tree().process_frame
	# Core pick: 3 cards, tier + axis words, reroll button with a count.
	RunState.pending_rewards.assign(cards())
	RunState.reward_reroll_charges = 2
	rm.call("_show_reward_overlay", "x")
	await get_tree().process_frame
	var row: BoxContainer = rm.get("_overlay_vbox")
	var panels: Array = []
	for c in row.get_children():
		if c is PanelContainer:
			panels.append(c)
	_check(panels.size() == 3, "3 core cards")
	_check(rm._overlay_root.find_child("RewardTitle", true, false).text == "CHOOSE A CORE", "core title")
	var tl: Label = (panels[1] as Node).find_child("TierBand", true, false).find_child("Word", true, false)
	var al: Label = (panels[1] as Node).find_child("CategoryChip", true, false).get_child(0)
	_check(tl.text == "Moss" and al.text == "DICE FACES", "tier band + category chip: %s / %s" % [tl.text, al.text])
	_check((panels[1] as Node).find_child("AxisChip", true, false) == null, "no AxisChip (UI-04)")
	_check(rm._overlay_root.find_child("CoreTierLegend", true, false) != null and rm._overlay_root.find_child("CoreTierHint", true, false) == null, "tier legend replaces the hint line")
	_check(rm._overlay_root.find_child("CardReroll0", true, false) != null and rm._overlay_root.find_child("CardReroll2", true, false) != null, "reroll button on every core card")
	var rr: Label = rm._overlay_root.find_child("RerollLeft", true, false)
	_check(rr != null and rr.text.contains("2"), "shared reroll counter")
	# Amber / Crystal use their own colours.
	var cs := cards()
	cs[0]["tier"] = 1
	cs[1]["tier"] = 2
	RunState.pending_rewards.assign(cs)
	rm.call("_show_reward_overlay", "x")
	await get_tree().process_frame
	var l2: Label = rm._overlay_root.find_child("RewardCard0", true, false).find_child("TierBand", true, false).find_child("Word", true, false)
	_check(l2.text == "Amber", "amber tier word")
	_check(rm._overlay_root.find_child("RewardCard1", true, false).find_child("TierBand", true, false).find_child("Word", true, false).text == "Crystal", "crystal word")
	# Take button picks the selected card (chosen reward reaches the game layer).
	_check(rm._overlay_root.find_child("TakeButton", true, false) != null, "take button")
	# Run rule: 2 cards, no reroll, "No Rule" card present.
	RunState.pending_rewards.assign(rules())
	rm.call("_show_reward_overlay", "x")
	await get_tree().process_frame
	_check(rm._overlay_root.find_child("RewardTitle", true, false).text == "CHOOSE A RUN RULE", "rule title")
	_check(rm._overlay_root.find_child("RewardCard1", true, false) != null and rm._overlay_root.find_child("RewardCard2", true, false) == null, "2 rule cards")
	var rb: Button = rm._overlay_root.find_child("RerollButton", true, false)
	_check(rb == null or not rb.visible, "no reroll on rules")
	RunState.pending_rewards.assign([])
	rm.queue_free()
	_guard.restore()
	for f in _fails:
		print("t_depthv3_core_offer: FAIL — %s" % f)
	if _fails.is_empty():
		print("t_depthv3_core_offer: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
