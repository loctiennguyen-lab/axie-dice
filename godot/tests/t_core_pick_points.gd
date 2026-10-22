extends Node
## Core pick points (Liam 22/10): a Short run has 6 Core picks = 4 milestones + 1 after the first won Elite that is not a
## milestone node + 1 after the core.extra_pick_nodes-th node. Extra tiers come from core_extra_tiers_short (own Rng).
var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _assert(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)


func _start(sd: int, mode: String = "short") -> void:
	RunState.reset()
	RunState.start_new_run_seeded(sd, {"team_keys": TEAM, "mode": mode, "ascension": 0, "ranked": false, "bonuses": {},
		"loadout": {"rules_on": false}})
	RunBot.drain_core_offers()


func _elite_node() -> String:
	var g := RunMapGraph.from_data(RunState.map_graph)
	for r in range(1, 19):
		for n in g.get_row(r):
			if n.node_type == "elite" and g.boss_rows.find(n.row) < 0 and n.row != int((RelicSlots.tuning().core_triggers_short as Array)[0][1]):
				return String(n.id)
	return ""


func _ready() -> void:
	_guard.capture()
	var t := RelicSlots.tuning()
	_assert(t.core_picks_short + 2 == 6, "4 milestones + 2 extras = 6 picks")
	# determinism + tier table
	var a := CoreOffer.draw_extra_tiers(777, "short")
	_assert(a.size() == 2 and a == CoreOffer.draw_extra_tiers(777, "short"), "extra tiers deterministic")
	_assert(CoreOffer.draw_extra_tiers(777, "full").is_empty(), "full mode has no extra picks")
	var rows := {}
	for sd in 200:
		var x := CoreOffer.draw_extra_tiers(sd, "short")
		rows[str(x)] = true
		_assert(x[0] >= 0 and x[0] <= 2 and x[1] >= 0 and x[1] <= 2, "tier in 0..2")
	var allowed := {}
	for r in t.core_extra_tiers_short:
		allowed[str(((r as Array)[0] as Array).map(func(v): return int(v)))] = true
	for k in rows:
		_assert(allowed.has(k), "drawn pair %s is in the table" % k)
	# chain of milestones is untouched
	_assert(CoreOffer.draw_tier_chain(777, "short").size() == 4, "milestone chain still 4")
	# mid pick: opens after the Nth finished node, once; tier from the table
	_start(31)
	var pi0 := RunState.core_pick_index
	var tiers := RunState.core_extra_tiers.duplicate()
	_assert(tiers.size() == 2, "run holds 2 extra tiers")
	RunState.visited_node_ids.clear()
	for i in t.core_extra_pick_nodes - 1:
		RunState.visited_node_ids.append("fake_%d" % i)
	var g := RunMapGraph.from_data(RunState.map_graph)
	RunState.current_node_id = String(g.get_row(1)[0].id)
	RunState.phase = RunState.RunPhase.MAP
	RunState.after_node()
	_assert(RunState.core_extra_mid_done, "mid pick flagged after node %d" % t.core_extra_pick_nodes)
	_assert(RunState.phase == RunState.RunPhase.REWARD and not RunState.pending_rewards.is_empty(), "mid pick opens a Core offer")
	_assert(RunState.core_pick_index == pi0, "milestone index not shifted by the extra pick")
	# save/load in the middle of the extra offer
	var d := RunState.to_data()
	var pend := str(RunState.pending_rewards.map(func(c): return c["key"]))
	RunState.from_data(JSON.parse_string(JSON.stringify(d)))
	_assert(RunState.core_extra_mid_done and RunState.core_extra_tiers == tiers, "extra state survives save/load")
	_assert(str(RunState.pending_rewards.map(func(c): return c["key"])) == pend, "open extra offer survives save/load")
	# mid pick fires only once
	RunState.pending_rewards = []
	RunState._core_offer_active = false
	RunState._core_close_pending = false
	RunState.core_bonus_queue.clear()
	RunState.phase = RunState.RunPhase.MAP
	RunState.after_node()
	_assert(RunState.core_bonus_queue.is_empty(), "mid pick is not queued twice")
	# elite pick: a won non-milestone Elite queues exactly one pick, the second Elite none
	_start(31)
	var en := _elite_node()
	_assert(en != "", "map has a non-milestone Elite")
	RunState.current_node_id = en
	var q0 := RunState.core_bonus_queue.size()
	RunState._note_extra_elite()
	_assert(RunState.core_bonus_queue.size() == q0 + 1 and RunState.core_bonus_queue.back() == RunState.core_extra_tiers[0], "elite pick queued with the elite tier")
	RunState._note_extra_elite()
	_assert(RunState.core_bonus_queue.size() == q0 + 1, "only core_extra_elite_max Elite picks")
	# elite on a milestone node gives no extra
	_start(32)
	var trig_row := int((t.core_triggers_short as Array)[0][1])
	RunState.core_pick_index = 1
	RunState.current_node_id = String(RunMapGraph.from_data(RunState.map_graph).get_row(trig_row)[0].id)
	var q1 := RunState.core_bonus_queue.size()
	RunState._note_extra_elite()
	_assert(RunState.core_bonus_queue.size() == q1 and RunState.core_extra_elite_done == 0, "milestone node Elite gives no extra pick")
	# knobs off
	var oldn := t.core_extra_pick_nodes
	t.core_extra_pick_nodes = 0
	_start(33)
	RunState.visited_node_ids.clear()
	for i in 20:
		RunState.visited_node_ids.append("f%d" % i)
	RunState._note_extra_mid()
	_assert(not RunState.core_extra_mid_done, "extra_pick_nodes 0 disables the mid pick")
	t.core_extra_pick_nodes = oldn
	# whole runs: replay accepts, counts add up
	CoreTestUtil.enable()
	MetaState.runs = 1
	var full_ok := 0
	var seen_both := false
	for sd in [991237, 4242, 7001, 12345, 5150, 8080, 3141, 99, 100, 101, 102, 103]:
		var p: Dictionary = RunBot.play_run(sd, TEAM)
		var l: ActionLog = p["log"]
		var cs: Dictionary = (p["state"] as Dictionary).get("core", {})
		if bool(cs.get("extra_mid_done", false)):
			seen_both = true
			_assert(int(cs.get("bonus_count", 0)) >= 1, "mid extra pick opened (seed %d)" % sd)
		var v := RunVerifier.verify(l, p["tape"])
		_assert(bool(v["ok"]), "replay accepts seed %d: %s" % [sd, str(v["message"])])
		if bool(v["ok"]):
			full_ok += 1
			_assert(JSON.stringify((v["state"] as Dictionary).get("core", {})) == JSON.stringify(cs), "same core state after replay (seed %d)" % sd)
	_assert(full_ok > 0, "at least one run replayed")
	_assert(seen_both, "some whole run opened the mid extra pick (the test bot dies before an Elite win)")
	_guard.restore()
	for f in _failures:
		print("FAIL: ", f)
	if _failures.is_empty():
		print("t_core_pick_points: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _failures.is_empty() else 1)
