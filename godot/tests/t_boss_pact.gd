extends Node
## C1: boss Pact phase (relic-set-v2 §4.4, ascension-v2 A6/A10). Offer after a non-final boss win, forced vs
## optional, take / skip, sell-on-full, save/resume mid-phase, replay through the action log.

var _failures: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
const REPLAY_TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _ready() -> void:
	_guard.capture()
	print("=== t_boss_pact: start ===")
	test_offer_and_forced_rules()
	test_take_and_skip()
	test_sell_on_full()
	test_swap_one_card()
	test_swap_in_a_full_run_replays()
	test_save_resume()
	await test_log_and_view()
	test_verifier_refusals()
	_guard.restore()
	print("=== t_boss_pact: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_boss_pact: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_boss_pact: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


## Fresh run, then a won non-final boss: the Pact phase should open before the reward cards.
func _boss_win(asc: int, boss_started: int = 1, kind: String = "boss") -> void:
	RunState.start_new_run(777, TEAM, "full", asc, false)
	RunState.current_node_id = "r3_c0"
	RunState.bosses_started = boss_started
	RunState.apply_combat_result({"won": true, "kind": kind, "pw": 5, "shards_earned": 0})


func test_offer_and_forced_rules() -> void:
	_boss_win(0)
	_assert(RunState.phase == RunState.RunPhase.PACT, "boss win opens PACT phase")
	_assert(RunState.pending_pact.size() == 3, "three pacts offered, got %d" % RunState.pending_pact.size())
	_assert(not RunState.pending_rewards.is_empty(), "reward cards wait behind the pact")
	for id in RunState.pending_pact:
		_assert(RelicSlots.is_pact(id), "%s is a pact" % id)
	var first := RunState.pending_pact.duplicate()
	_boss_win(0)
	_assert(RunState.pending_pact == first, "same seed -> same offer")
	_boss_win(0, 1, "elite")
	_assert(RunState.phase == RunState.RunPhase.REWARD and RunState.pending_pact.is_empty(), "elite win: no pact")
	# [asc, boss_index(0-based), forced]
	for row in [[5, 0, false], [6, 0, true], [6, 1, false], [9, 0, true], [9, 1, false], [10, 0, true], [10, 2, true]]:
		_boss_win(int(row[0]), int(row[1]) + 1)
		_assert(RunState.phase == RunState.RunPhase.PACT, "A%d boss %d opens pact" % [row[0], row[1]])
		_assert(RunState.pending_pact_forced == bool(row[2]), "A%d boss %d forced=%s" % [row[0], row[1], row[2]])
		_assert(RunState.pact_can_skip() == not bool(row[2]), "A%d boss %d can_skip" % [row[0], row[1]])


func test_take_and_skip() -> void:
	_boss_win(6)
	_assert(not RunState.skip_pact(), "forced pact cannot be skipped")
	_assert(RunState.phase == RunState.RunPhase.PACT, "still in PACT after refused skip")
	var id := RunState.pending_pact[0]
	_assert(RunState.take_pact(0), "take pact 0")
	_assert(RunState.owned_relic_ids.has(id) and RunState.pacts_taken.has(id), "pact owned + recorded")
	_assert(RunState.phase == RunState.RunPhase.REWARD, "reward cards follow")
	_assert(RunState.pending_pact.is_empty(), "offer cleared")
	_boss_win(0)
	_assert(RunState.skip_pact(), "optional pact can be skipped")
	_assert(RunState.pacts_taken.is_empty() and RunState.phase == RunState.RunPhase.REWARD, "skip takes nothing")
	_assert(not RunState.take_pact(0), "no take outside PACT phase")


func test_sell_on_full() -> void:
	_boss_win(6)
	var cap := int(RelicSlots.capacity(6, [])["passive"])
	var filler: Array[String] = []
	for d in RelicRegistry.all_defs_sorted():
		if filler.size() >= cap:
			break
		if String(d.mult_axis) == "" and String(d.pact_group) == "" and d.act_cost == 0 and not String(d.id).begins_with("__") \
				and String(d.requires_class) == "":
			filler.append(String(d.id))
	RunState.owned_relic_ids.assign(filler)
	var card: Dictionary = RunState.pact_cards()[0]
	_assert(bool(card["needs_sell"]) and bool(card["ok"]), "full slots: pact needs a sale")
	_assert(not RunState.take_pact(0), "full slots: no sell id, refused")
	_assert(not RunState.take_pact(0, "not_owned"), "full slots: bad sell id refused")
	var sell: String = (card["sell_from"] as Array)[0]
	_assert(RunState.take_pact(0, sell), "sell + take")
	_assert(not RunState.owned_relic_ids.has(sell) and RunState.owned_relic_ids.has(String(card["id"])), "sold one, got pact")


func test_swap_one_card() -> void:
	_boss_win(6)
	var before := RunState.pending_pact.duplicate()
	_assert(not RunState.reroll_pact_slot(3) and not RunState.reroll_pact_slot(-1), "bad slot refused")
	_assert(RunState.reroll_pact_slot(1), "swap slot 1")
	var after := RunState.pending_pact.duplicate()
	_assert(after.size() == 3 and after[0] == before[0] and after[2] == before[2], "other two cards untouched")
	_assert(after[1] != before[1] and not before.has(after[1]), "new card differs from all earlier cards")
	_assert(RelicSlots.is_pact(String(after[1])), "new card is a pact")
	var g_old := String(RelicRegistry.get_def(before[1]).pact_group)
	var g_new := String(RelicRegistry.get_def(after[1]).pact_group)
	_assert(g_old == g_new, "same drawback group when the pool allows (%s -> %s)" % [g_old, g_new])
	var last: Dictionary = RunState.action_log.entries[RunState.action_log.entries.size() - 1]
	_assert(String(last["fn"]) == "pact_reroll" and (last["args"] as Array)[0] == 1 and RunState.action_log.is_complete(),
		"logged as pact_reroll [slot, n]")
	_boss_win(6)
	RunState.reroll_pact_slot(1)
	_assert(RunState.pending_pact == after, "same run + same request -> same swap")
	var data := RunState.to_data()
	RunState.reset()
	RunState.from_data(JSON.parse_string(JSON.stringify(data)) as Dictionary)
	_assert(RunState.pending_pact == after and RunState.pending_pact_swaps == 1, "swapped offer + count survive a save")
	_assert(RunState.take_pact(1), "can take the swapped-in card")
	_assert(not RunState.reroll_pact_slot(0), "no swap outside the PACT phase")
	_boss_win(0)
	var v := PactView.new()
	add_child(v)
	v.setup(RunState.pact_cards(), true, {"show": true, "enabled": true, "price": 15, "reason": ""})
	_assert(v.swap_buttons.size() == 3 and v.find_child("CostChip", true, false) != null, "a Swap button + gem CostChip on each card")
	var got := [-1]
	v.swap_requested.connect(func(i: int): got[0] = i)
	v.swap_buttons[2].pressed.emit()
	_assert(got[0] == 2, "swap button reports its card")
	v.setup(RunState.pact_cards(), true, {})
	_assert(v.swap_buttons.is_empty(), "no offer (newcomer / below A6): no Swap buttons")
	v.queue_free()


## Full run recorded with one paid swap: the referee accepts it, then each tamper is refused or changes the outcome.
func test_swap_in_a_full_run_replays() -> void:
	RunBot.swap_pact_slot = 1
	var played := _bot_run_with_pact(0)
	RunBot.swap_pact_slot = -1
	var log: ActionLog = played["log"]
	var si := -1
	for i in log.entries.size():
		if String((log.entries[i] as Dictionary).get("fn", "")) == "pact_reroll":
			si = i
			break
	_assert(si >= 0, "bot run recorded a pact_reroll")
	if si < 0:
		return
	var ok := RunVerifier.verify(log, played["tape"])
	_assert(bool(ok["ok"]) and int(ok["score"]) == int(played["score"]), "honest run with a swap verifies: %s" % str(ok["message"]))
	var t := _clone(log)
	t.entries.insert(si + 1, {"fn": "pact_reroll", "args": [1, 2]})
	var extra := RunVerifier.verify(t, played["tape"])
	# The referee cannot see the price; an extra swap has no tape seed so the replay must refuse or diverge.
	_assert(not bool(extra["ok"]) or int(extra["score"]) != int(ok["score"]) or _run_swapped_id(extra) != _run_swapped_id(ok),
		"an extra swap changes something the referee can see")
	t = _clone(log)
	t.entries[si]["args"] = [7, 1]
	_refused(t, played["tape"], "swap of a slot outside the offer")
	t = _clone(log)
	t.entries.remove_at(si)
	var gone := RunVerifier.verify(t, played["tape"])
	_assert(not bool(gone["ok"]) or _run_swapped_id(gone) != _run_swapped_id(ok),
		"deleting the swap changes which pact card pick 0 takes (or is refused)")


func _run_swapped_id(v: Dictionary) -> String:
	return str(((v.get("state", {}) as Dictionary).get("pacts_taken", [])))


func test_save_resume() -> void:
	_boss_win(10)
	var offer := RunState.pending_pact.duplicate()
	var data := RunState.to_data()
	RunState.reset()
	RunState.from_data(JSON.parse_string(JSON.stringify(data)) as Dictionary)
	_assert(RunState.phase == RunState.RunPhase.PACT, "resumed in PACT phase")
	_assert(RunState.pending_pact == offer and RunState.pending_pact_forced, "offer + forced flag survive")
	_assert(RunState.take_pact(1), "can take after resume")


func test_log_and_view() -> void:
	_boss_win(0)
	RunState.skip_pact()
	var last: Dictionary = RunState.action_log.entries[RunState.action_log.entries.size() - 1]
	_assert(String(last["fn"]) == "pact_pick" and int((last["args"] as Array)[0]) == -1, "skip logged as pact_pick -1")
	_assert(RunState.action_log.is_complete(), "log complete")
	_boss_win(10)
	var v := PactView.new()
	add_child(v)
	v.setup(RunState.pact_cards(), RunState.pact_can_skip())
	_assert(v.skip_button == null and v.card_panels.size() == 3 and v.accept_button != null, "forced view: no skip button, 3 cards + Accept")
	var got := [0]
	var menu := [0]
	v.skipped.connect(func(): got[0] += 1)
	v.menu_requested.connect(func(): menu[0] += 1)
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	v._unhandled_input(esc)
	_assert(got[0] == 0 and menu[0] == 1, "Esc never skips a forced pact; it asks for the in-run menu")
	v.queue_free()
	_boss_win(0)
	var v2 := PactView.new()
	add_child(v2)
	v2.setup(RunState.pact_cards(), RunState.pact_can_skip())
	v2.skipped.connect(func(): got[0] += 1)
	v2._unhandled_input(esc)
	_assert(v2.skip_button != null and got[0] == 0, "optional view: skip button, Esc does not skip (menu instead)")
	v2.skip_button.pressed.emit()
	_assert(got[0] == 1, "Skip pact button skips")
	# UI-03 12: select + Accept -> confirm repeats the drawback -> Make pact picks; Back picks nothing.
	var picks: Array = []
	v2.picked.connect(func(i: int, sid: String): picks.append([i, sid]))
	await get_tree().process_frame   # the deferred first-focus lands on card 0
	v2.select(1)
	v2.accept_button.pressed.emit()
	await get_tree().process_frame
	var dlg := v2.find_child("PactConfirm", true, false)
	_assert(dlg != null, "Accept opens the confirm")
	_assert(dlg.find_children("*", "Label", true, false).any(func(l): return (l as Label).text.begins_with("Drawback")), "confirm shows the drawback line")
	(v2.find_child("PactBack", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_assert(picks.is_empty() and v2.find_child("PactConfirm", true, false) == null, "Back picks nothing")
	v2.accept_button.pressed.emit()
	await get_tree().process_frame
	(v2.find_child("PactMake", true, false) as Button).pressed.emit()
	_assert(picks.size() == 1 and int(picks[0][0]) == 1 and String(picks[0][1]) == "", "Make pact picks the selected card %s" % [picks])
	v2.queue_free()


# --- verifier refusals (RunVerifier replays the log; a tampered pact step must not score) ---------------
func _clone(source: ActionLog) -> ActionLog:
	return ActionLog.from_data(JSON.parse_string(JSON.stringify(source.to_data())) as Dictionary)


func _pact_index(log: ActionLog) -> int:
	for i in log.entries.size():
		if String((log.entries[i] as Dictionary).get("fn", "")) == "pact_pick":
			return i
	return -1


func _refused(log: ActionLog, tape: Array, what: String) -> void:
	var v := RunVerifier.verify(log, tape)
	_assert(not bool(v["ok"]) and String(v["error"]) == RunVerifier.ERR_REJECTED, "%s: refused (got %s)" % [what, str(v["error"])])


## Bot run that reaches a boss pact. A bot can die before the boss depending on meta state (unlocks, perks)
## that lives in the user dir, so meta is blanked first and a handful of seeds are tried; the seeds are fixed.
func _bot_run_with_pact(asc: int) -> Dictionary:
	MetaState.unlocks.clear()
	MetaState.perks = {}
	MetaState.runs_with_battle = 0
	for sd in [991237, 991238, 991239, 4242, 4243, 4244, 7001, 7002, 7003, 12345]:
		var r := RunBot.play_run(sd, REPLAY_TEAM, "short", asc)
		if _pact_index(r["log"]) >= 0:
			return r
	return RunBot.play_run(991237, REPLAY_TEAM, "short", asc)


func test_verifier_refusals() -> void:
	var played := _bot_run_with_pact(0)
	var log: ActionLog = played["log"]
	var pi := _pact_index(log)
	_assert(pi >= 0, "bot run recorded a pact_pick")
	if pi < 0:
		return
	_assert(bool(RunVerifier.verify(log, played["tape"])["ok"]), "honest run with a pact verifies")
	var t := _clone(log)
	t.entries[pi]["args"] = [9]
	_refused(t, played["tape"], "out-of-range index")
	t = _clone(log)
	t.entries[pi]["args"] = [0, "r_notowned"]
	_refused(t, played["tape"], "selling an unowned relic")
	t = _clone(log)
	t.entries.remove_at(pi)
	_refused(t, played["tape"], "take_reward before the pact is settled")
	t = _clone(log)
	t.entries.remove_at(pi)
	t.entries.remove_at(pi)   # the take_reward behind it: next entry is the following enter_node
	_refused(t, played["tape"], "enter_node while a pact is pending")
	t = _clone(log)
	t.entries[pi] = {"fn": "reroll_rewards", "args": []}
	_refused(t, played["tape"], "reroll_rewards while a pact is pending")
	# Forced skip: a run at A6 whose first boss pact was edited into a skip.
	var p6 := _bot_run_with_pact(6)
	var l6: ActionLog = p6["log"]
	var p6i := _pact_index(l6)
	_assert(p6i >= 0, "A6 bot run reached a boss pact")
	if p6i >= 0:
		t = _clone(l6)
		t.entries[p6i]["args"] = [-1]
		_refused(t, p6["tape"], "forced pact skipped")
