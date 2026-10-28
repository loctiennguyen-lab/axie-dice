extends Node
## QA plan T-02, real flow: Core overlay picks drive the House chip. house 1 -> 1/2; non-house -> still 1/2;
## house 2 -> Awakened (chip state + AnchorFx plays once); house 3 -> still Awakened.
## Offers are forced by replacing the cards of a real bonus Core offer (same overlay, same take path).

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
var _fail := 0
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail += 1
		print("FAIL: ", msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _chip(rm: Node) -> Node:
	for cp in rm.find_children("*", "CorePanel", true, false):
		var c := cp.find_child("HouseChip", true, false)
		if c != null:
			return c
	return null


func _chip_text(rm: Node) -> String:
	var c := _chip(rm)
	if c == null:
		return "<no chip>"
	# UI-04 HouseChip: the count lives in its own "Count" label ("1/2"), no "House Cores" prefix any more.
	var l := c.find_child("Count", true, false) as Label
	return l.text if l != null else "<no text>"


## Opens a real bonus Core offer, swaps its first card for `core_id`, takes it through the overlay.
func _take_forced(rm: Node, core_id: String) -> void:
	RunState._queue_core_pick(1)
	rm._finish_node()
	await _frames(8)
	var cards: Array[Dictionary] = []
	cards.append(CoreOffer.card_of(RelicRegistry.get_def(core_id), 0))
	for i in range(1, RunState.pending_rewards.size()):
		cards.append(RunState.pending_rewards[i])
	RunState.pending_rewards = cards
	rm._maybe_show_pending_reward()
	await _frames(8)
	rm._select_reward(0)
	await _frames(2)
	rm._take_selected_reward()
	await _frames(14)


func _ready() -> void:
	print("=== t_anchor_flow_gut_progress: start ===")
	_guard.capture()
	CombatView.disable_juice_for_tests = true
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Gacha.instant_override = 1
	AnchorAdapter.test_state = null
	AnchorFx.pending = ""
	AnchorFx.played_run = ""
	AnchorFx.log.clear()
	# The Anchor offer is 3 of 6 by seed and the seed epoch changes with RULES_VERSION, so scan for a seed whose offer holds a_volley.
	var found_seed := -1
	for sd in range(601, 801):
		RunState.start_run_with_epoch(LocalEpochSource.new(PackedByteArray(), sd), {"team_keys": TEAM, "mode": "short",
			"ascension": 0, "ranked": false, "anchor": true, "depth_stage": 3, "loadout": {"rules_on": false}}, sd)
		RunState.anchor_offer_open()
		if RunState.anchor_offer.has("a_volley"):
			found_seed = sd
			break
	_ok(found_seed >= 0, "found a seed whose Anchor offer holds a_volley")
	RunState.depth_stage = 3
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)
	var pick := rm.find_child("AnchorPick", true, false) as AnchorPick
	_ok(pick != null, "pick screen up")
	if pick == null:
		print("t_anchor_flow_gut_progress: FAIL")
		get_tree().quit(1)
		return
	var vi := -1
	for i in pick.cards.size():
		if String(pick.cards[i].get_meta("anchor_id")) == "a_volley":
			vi = i
	_ok(vi >= 0, "Volley offered")
	pick.select(vi)
	pick.take_button.pressed.emit()
	await _frames(10)
	_ok(RunState.anchor_id == "a_volley", "Volley chosen")
	var house := AnchorAdapter.house_cores("a_volley")
	var non_house := ""
	for c in ["c_mana_pool", "c_thorn_shield", "c_sonic_shield", "c_living_wall"]:
		if not house.has(c) and RelicRegistry.get_def(c) != null:
			non_house = c
			break
	_ok(non_house != "" and house.size() >= 3, "have 3 house Cores and a non-house Core")
	# first Core offer is open now: finish it with a house Core
	var cards: Array[Dictionary] = []
	cards.append(CoreOffer.card_of(RelicRegistry.get_def(String(house[0])), 0))
	for i in range(1, RunState.pending_rewards.size()):
		cards.append(RunState.pending_rewards[i])
	RunState.pending_rewards = cards
	rm._maybe_show_pending_reward()
	await _frames(8)
	rm._select_reward(0)
	await _frames(2)
	rm._take_selected_reward()
	await _frames(14)
	_ok(RunState.owned_relic_ids.has(String(house[0])), "house Core 1 owned")
	_ok(_chip_text(rm).contains("1/2"), "after house 1: " + _chip_text(rm))
	_ok(not RunState.anchor_awakened, "not awakened at 1")
	await _take_forced(rm, non_house)
	_ok(RunState.owned_relic_ids.has(non_house), "non-house Core owned")
	_ok(_chip_text(rm).contains("1/2"), "after non-house: " + _chip_text(rm))
	_ok(not RunState.anchor_awakened and not AnchorFx.log.has("play"), "still not awakened, no moment")
	await _take_forced(rm, String(house[1]))
	_ok(RunState.owned_relic_ids.has(String(house[1])), "house Core 2 owned")
	_ok(RunState.anchor_awakened, "awakened at 2")
	var ch := _chip(rm)
	_ok(ch != null and ch.get_meta("state", "") == "awakened", "chip state Awakened")
	var plays := AnchorFx.log.count("play")
	_ok(plays == 1, "AnchorFx played once (%d)" % plays)
	await _take_forced(rm, String(house[2]))
	_ok(RunState.owned_relic_ids.has(String(house[2])), "house Core 3 owned")
	_ok(RunState.anchor_awakened, "still awakened at 3")
	ch = _chip(rm)
	_ok(ch != null and ch.get_meta("state", "") == "awakened", "chip still Awakened at 3")
	_ok(AnchorFx.log.count("play") == 1, "no second awaken moment")
	rm.free()
	UI3Gacha.instant_override = -1
	CombatView.disable_juice_for_tests = false
	_guard.restore()
	print("=== t_anchor_flow_gut_progress: %d checks, %d failure(s) ===" % [_checks, _fail])
	if _fail == 0:
		print("t_anchor_flow_gut_progress: PASS")
		get_tree().quit(0)
	else:
		get_tree().quit(1)
