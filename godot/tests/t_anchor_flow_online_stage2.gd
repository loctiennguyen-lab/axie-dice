extends Node
## Real flow (Liam 22/10): Anchor opens for a normal ONLINE-style run (non-local epoch source) from depth stage 2.
## RunMap overlay -> Anchor pick screen -> Mana Mine locked with its reason -> Volley -> Take -> first Core offer; action log has pick_anchor [index].
## Also: stage 1 and ranked runs get no Anchor screen.

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


func _start(seed: int, stage: int, ranked: bool) -> void:
	var params := {"team_keys": TEAM, "mode": "short", "ascension": 0, "ranked": ranked, "kind": "ranked" if ranked else "normal",
		"anchor": true, "depth_stage": stage, "loadout": {"rules_on": false}}
	RunState.start_run_with_epoch(LocalEpochSource.new(PackedByteArray(), seed), params, seed)
	RunState.epoch = TapeEpochSource.new([])   # online-style (non-local) source from here on
	RunState.depth_stage = stage


func _map() -> Node:
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)
	return rm


func _ready() -> void:
	print("=== t_anchor_flow_online_stage2: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Gacha.instant_override = 1
	AnchorAdapter.test_state = null
	# ---- stage 2, online-style source, normal
	# The offer is 3 of 6 Anchors by seed, so scan for a seed whose offer holds Mana Mine and Volley/Gambler.
	for sd in range(501, 701):
		_start(sd, 2, false)
		RunState.anchor_offer_open()
		var offer: Array = RunState.anchor_offer
		if offer.has("a_mana_mine") and (offer.has("a_volley") or offer.has("a_gambler")):
			break
	_ok(not (RunState.epoch is LocalEpochSource), "epoch source is non-local")
	_ok(RunState.anchor_gate_reason() == "", "gate open: " + RunState.anchor_gate_reason())
	var rm: Node = await _map()
	_ok(RunState._anchor_waiting and RunState.pending_rewards.is_empty(), "engine waits for the Anchor")
	var pick := rm.find_child("AnchorPick", true, false) as AnchorPick
	_ok(pick != null and pick.cards.size() == 3, "pick screen shows 3 cards")
	if pick != null:
		var mana := -1
		var other := -1
		for i in pick.cards.size():
			var id := String(pick.cards[i].get_meta("anchor_id"))
			if id == "a_mana_mine":
				mana = i
			elif other < 0 and (id == "a_volley" or id == "a_gambler"):
				other = i
		_ok(mana >= 0 and other >= 0, "offer has Mana Mine and Volley/Gambler")
		var why := pick.cards[mana].find_child("DisabledReason", true, false) as Label
		_ok(why != null and why.text == "Unlocks at stage 3 (needs Overcast).", "Mana Mine reason line: " + (why.text if why != null else "<none>"))
		_ok(RunState.anchor_disabled_reason("a_mana_mine") == "stage_locked", "engine reason stage_locked")
		pick.select(mana)
		await _frames(2)
		_ok(pick.take_button.disabled, "locked card cannot be selected: Take stays disabled")
		_ok(pick.cards[other].find_child("DisabledReason", true, false) == null, "pickable card has no reason line")
		pick.select(other)
		var id2 := String(pick.cards[other].get_meta("anchor_id"))
		var idx := RunState.anchor_offer.find(id2)
		var logged := RunState.action_log.entries.size()
		pick.take_button.pressed.emit()
		await _frames(10)
		_ok(RunState.anchor_id == id2, "engine holds the chosen Anchor")
		var found := false
		for e in RunState.action_log.entries.slice(logged):
			if String(e["fn"]) == "pick_anchor" and (e["args"] as Array).size() == 1 and int((e["args"] as Array)[0]) == idx:
				found = true
		_ok(found and idx >= 0, "action_log has pick_anchor [%d]" % idx)
		_ok(RunState.action_log.is_complete(), "action log complete")
		_ok(rm.find_child("AnchorPick", true, false) == null or not (rm.find_child("AnchorPick", true, false) as Control).visible, "pick screen gone")
		_ok(not RunState.pending_rewards.is_empty() or RunState.phase == RunState.RunPhase.MAP, "first Core offer or map after the pick")
		_ok(RunState.power_level == 0 and not RunState.visited_node_ids.has(""), "no phantom node from the Anchor wait (power_level %d)" % RunState.power_level)
	rm.queue_free()
	await _frames(2)
	# ---- stage 1: no screen
	_start(504, 1, false)
	var rm1: Node = await _map()
	_ok(RunState.anchor_gate_reason() == "stage" and not RunState._anchor_waiting and RunState.anchor_id == "", "stage 1: gate shut")
	_ok(rm1.find_child("AnchorPick", true, false) == null, "stage 1: no Anchor screen")
	rm1.queue_free()
	await _frames(2)
	# ---- ranked: no screen
	_start(503, 3, true)
	var rm3: Node = await _map()
	_ok(RunState.anchor_gate_reason() == "ranked" and not RunState._anchor_waiting, "ranked: gate shut")
	_ok(rm3.find_child("AnchorPick", true, false) == null, "ranked: no Anchor screen")
	rm3.queue_free()
	await _frames(2)
	UI3Gacha.instant_override = -1
	print("=== t_anchor_flow_online_stage2: %d checks, %d failure(s) ===" % [_checks, _fail])
	_guard.restore()
	if _fail == 0:
		print("t_anchor_flow_online_stage2: PASS")
		get_tree().quit(0)
	else:
		get_tree().quit(1)
