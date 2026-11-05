extends Node
## Polish 3/11 #2b: a REAL Core offer card (core:true) with the 6 Core slots full. Selling in the make-room sheet must take
## the Core exactly once (logged as take_reward [idx, sell_id]) and leave the offer closed. Before the fix the sheet granted the
## Core through acquire_relic (swap_on_full) and apply_chosen_reward then failed with already_owned: the run was stuck on the
## offer (seed 7 + Anchor, c_cascade after the row-14 event).
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
	_guard.capture()
	RelicRegistry.legacy_unhide_for_tests()
	var ids: Array[String] = []
	for f in DirAccess.get_files_at("res://resources/relics"):
		if f.begins_with("c_") and f.ends_with(".tres"):
			var d = RelicRegistry.get_def(f.get_basename())
			if d != null and String(d.core_axis) != "" and String(d.core_axis) != "run_rule":
				ids.append(f.get_basename())
	var slots := RelicSlots.tuning().core_slots
	ids.erase("c_cascade")
	RunState.start_new_run(7, RunBot.DEFAULT_TEAM, "short", 0, true)
	RunState.owned_relic_ids.assign(ids.slice(0, slots))
	RunState.relic_stickers = {}
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	await _frames(6)
	var card := CoreOffer.card_of(RelicRegistry.get_def("c_cascade"), 0)
	RunState.pending_rewards = [card]
	RunState._core_offer_active = true
	m.call("_show_reward_overlay", "CHOOSE A CORE")
	await _frames(2)
	m.call("_select_reward", 0)
	m.call("_take_selected_reward")
	await _frames(4)
	var sheet := m.find_child("SlotSwapSheet", true, false)
	_ok(sheet != null, "sheet opens for a Core card with 6 Cores")
	if sheet != null:
		var sell_id := String(ids[0])
		var btn := sheet.find_child("SellButton", true, false) as Button
		_ok(btn != null, "sell button exists")
		if btn != null:
			btn.pressed.emit()
			await _frames(6)
		_ok(RunState.owned_relic_ids.has("c_cascade"), "Cascade taken")
		_ok(RunState.pending_rewards.is_empty(), "offer closed (not stuck)")
		_ok(not RunState._core_offer_active, "core offer inactive")
		var n_take := 0
		var n_swap := 0
		for e in RunState.action_log.entries:
			if String(e["fn"]) == "take_reward":
				n_take += 1
			if String(e["fn"]) == "swap_on_full":
				n_swap += 1
		_ok(n_take == 1 and n_swap == 0, "one take_reward with the sale, no swap_on_full (take %d swap %d)" % [n_take, n_swap])
		_ok(RunState.owned_relic_ids.size() == slots, "still %d Cores owned (one sold)" % slots)
	# Esc on the sheet: leave with nothing taken, offer still open, can take again.
	m = await _reset_offer(m, ids, slots, 0)
	var sh2 := m.find_child("SlotSwapSheet", true, false)
	_ok(sh2 != null, "Esc case: sheet open")
	if sh2 != null:
		sh2.cancelled.emit()
		await _frames(3)
		_ok(m.find_child("SlotSwapSheet", true, false) == null, "Esc closes the sheet")
		_ok(not RunState.owned_relic_ids.has("c_cascade") and RunState.pending_rewards.size() == 1, "Esc: nothing taken, offer still open")
		_ok(not bool(m.get("_taking")), "Esc: not stuck in taking")
	# Eternal (the run gives at most 2): those two Sell buttons are disabled, the rest still work.
	m = await _reset_offer(m, ids, slots, 2)
	var sh3 := m.find_child("SlotSwapSheet", true, false)
	_ok(sh3 != null, "Eternal case: sheet open")
	if sh3 != null:
		var sells := sh3.find_children("SellButton", "Button", true, false)
		var off := 0
		for b in sells:
			if (b as Button).disabled:
				off += 1
		_ok(sells.size() == slots and off == 2, "Eternal: 2 of %d Sell buttons disabled (got %d)" % [slots, off])
		(sells[0] as Button).pressed.emit()
		await _frames(3)
		_ok(not RunState.owned_relic_ids.has(ids[0]) or RunState.relic_stickers.has(ids[0]), "Eternal: a disabled Sell sells nothing")
		_ok(RunState.owned_relic_ids.size() == slots, "Eternal: bar size unchanged")
		sh3.cancelled.emit()
		await _frames(2)
	# Every Core Eternal (cannot happen in a real run, eternal_max is 2): Take is blocked with a reason, no sheet, no hang.
	m = await _reset_offer(m, ids, slots, slots)
	_ok(m.find_child("SlotSwapSheet", true, false) == null, "all Eternal: no sheet")
	_ok(String(m.get("_offers").reward_block_reason(RunState.pending_rewards[0])) != "", "all Eternal: Take blocked with a reason")
	_ok(not RunState.owned_relic_ids.has("c_cascade") and not bool(m.get("_taking")), "all Eternal: nothing taken, not stuck")
	# A refused take (reward not in the offer) must not close the screen or leave it stuck.
	RunState.pending_rewards = [CoreOffer.card_of(RelicRegistry.get_def("c_cascade"), 0)]
	var ghost := CoreOffer.card_of(RelicRegistry.get_def("c_cascade"), 0)
	ghost["key"] = "c_cascade_ghost"
	var log_n := RunState.action_log.entries.size()
	m.call("_apply_and_finish", ghost)
	await _frames(3)
	_ok(not bool(m.get("_taking")), "refused take: _taking cleared")
	_ok(RunState.pending_rewards.size() == 1 and RunState.action_log.entries.size() == log_n, "refused take: offer and log untouched")
	m.queue_free()
	await _frames(2)
	_verifier_case()
	_guard.restore()
	print("t_ui5_core_swap_take: %d checks, %d failure(s)" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_core_swap_take: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_ui5_core_swap_take: FAIL — %s" % f)
	get_tree().quit(1)


func _reset_offer(old: Node, ids: Array[String], slots: int, eternal_n: int) -> Node:
	old.queue_free()
	await _frames(2)
	RunState.start_new_run(7, RunBot.DEFAULT_TEAM, "short", 0, true)
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	await _frames(6)
	var held: Array[String] = []
	held.assign(ids.slice(0, slots))
	RunState.owned_relic_ids.assign(held)
	RunState.relic_stickers = {}
	for i in mini(eternal_n, held.size()):
		RunState.relic_stickers[held[i]] = RelicSlots.STICKER_ETERNAL
	RunState.pending_rewards = [CoreOffer.card_of(RelicRegistry.get_def("c_cascade"), 0)]
	RunState._core_offer_active = true
	m.call("_show_reward_overlay", "CHOOSE A CORE")
	await _frames(2)
	m.call("_select_reward", 0)
	m.call("_take_selected_reward")
	await _frames(4)
	return m


## A real run where the bot sells a Core on a full bar replays to the same result through RunVerifier.
func _verifier_case() -> void:
	MetaState.unlocks.clear()
	MetaState.perks = {}
	MetaState.runs_with_battle = 0
	RunBot.core_script = true
	var found := false
	for sd in range(1, 41):
		var r := RunBot.play_run(sd, RunBot.DEFAULT_TEAM, "full", 0)
		var sold := false
		for e in (r["log"] as ActionLog).entries:
			if String(e["fn"]) == "take_reward" and (e["args"] as Array).size() > 1:
				sold = true
		if not sold:
			continue
		found = true
		var v := RunVerifier.verify(r["log"], r["tape"])
		_ok(bool(v["ok"]), "run with a Core sale verifies (seed %d): %s" % [sd, str(v.get("error", ""))])
		break
	RunBot.core_script = false
	_ok(found, "a bot run sold a Core on a full bar (verifier case ran)")
