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
	m.queue_free()
	await _frames(2)
	print("t_ui5_core_swap_take: %d checks, %d failure(s)" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_core_swap_take: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_ui5_core_swap_take: FAIL — %s" % f)
	get_tree().quit(1)
