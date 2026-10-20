extends Node
## Depth v3 lane B: a whole run with REAL Core flow (Run Rule offer, Core picks, per-card reroll, a sold Core, a
## shop/event Core pick) is rebuilt by RunVerifier from the tape, and a pick that is not in the offer is refused.
## Sample Cores come from CoreTestUtil.enable(); slots are cut to 2 so the bot is forced to sell.
var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _assert(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)


func _clone(src: ActionLog) -> ActionLog:
	return ActionLog.from_data(JSON.parse_string(JSON.stringify(src.to_data())))


func _count(log: ActionLog, fn: String, nargs: int = -1) -> int:
	var n := 0
	for e in log.entries:
		if String(e["fn"]) == fn and (nargs < 0 or (e["args"] as Array).size() == nargs):
			n += 1
	return n


func _ready() -> void:
	_guard.capture()
	CoreTestUtil.enable()
	var t := RelicSlots.tuning()
	var old_slots := t.core_slots
	t.core_slots = 2
	MetaState.runs = 1   # not the account's first run: Run Rule offer is on
	RunBot.core_script = true
	var played: Dictionary = {}
	var sd_used := 0
	for sd in [991237, 991238, 4242, 7001, 12345, 5150, 8080, 3141]:
		played = RunBot.play_run(sd, TEAM)
		sd_used = sd
		var l: ActionLog = played["log"]
		if _count(l, "take_reward", 2) > 0 and _count(l, "reroll_rewards", 1) > 0:
			break
	RunBot.core_script = false
	t.core_slots = old_slots
	var log: ActionLog = played["log"]
	_assert(log.is_complete(), "log complete (rejected=%s)" % str(log.rejected))
	_assert(_count(log, "take_reward", 2) > 0, "a Core was sold (take_reward with sell id), seed %d" % sd_used)
	_assert(_count(log, "reroll_rewards", 1) > 0, "a Core card was rerolled")
	t.core_slots = 2
	var verdict := RunVerifier.verify(log, played["tape"])
	_assert(bool(verdict["ok"]), "referee accepts the Core run: %s %s" % [str(verdict["error"]), str(verdict["message"])])
	if bool(verdict["ok"]):
		_assert(int(verdict["score"]) == int(played["score"]), "same score")
		var a: Dictionary = played["state"]
		var b: Dictionary = verdict["state"]
		_assert(str(a.get("owned_relic_ids", a.get("relics"))) == str(b.get("owned_relic_ids", b.get("relics"))), "same owned Cores")
		_assert(JSON.stringify(a.get("core", {})) == JSON.stringify(b.get("core", {})), "same Core state (tier chain, seen, quest, rule)")
	# Tamper 1: a card index outside the offer is refused.
	var idx := -1
	for i in log.entries.size():
		var e: Dictionary = log.entries[i]
		if String(e["fn"]) == "take_reward" and (e["args"] as Array).size() >= 1:
			idx = i
			break
	if idx >= 0:
		var tm := _clone(log)
		tm.entries[idx]["args"] = [9]
		var bad := RunVerifier.verify(tm, played["tape"])
		_assert(not bool(bad["ok"]), "take_reward of a card that is not in the offer is refused")
	# Tamper 2: selling a Core that is not owned is refused / changes the run.
	var si := -1
	for i in log.entries.size():
		var e2: Dictionary = log.entries[i]
		if String(e2["fn"]) == "take_reward" and (e2["args"] as Array).size() == 2:
			si = i
			break
	if si >= 0:
		var tm2 := _clone(log)
		tm2.entries[si]["args"] = [int(tm2.entries[si]["args"][0]), "c_test_not_owned"]
		var bad2 := RunVerifier.verify(tm2, played["tape"])
		_assert(not bool(bad2["ok"]), "selling a Core that is not owned is refused")
	# Tamper 3 (review): ranked cannot dodge the Run Rule, nor switch the Core flow off.
	_assert(bool((log.header["loadout"] as Dictionary).get("rules_on", false)), "ranked header says rules_on = true (even in a first run)")
	var tm3 := _clone(log)
	(tm3.header["loadout"] as Dictionary)["rules_on"] = false
	var bad3 := RunVerifier.verify(tm3, played["tape"])
	_assert(not bool(bad3["ok"]) and String(bad3["error"]) == RunVerifier.ERR_BAD_HEADER, "ranked log with rules_on=false is refused")
	var tm4 := _clone(log)
	(tm4.header["loadout"] as Dictionary)["core_off"] = true
	RunState.simulate_shipped_build = true
	var bad4 := RunVerifier.verify(tm4, played["tape"])
	RunState.simulate_shipped_build = false
	_assert(not bool(bad4["ok"]) and String(bad4["error"]) == RunVerifier.ERR_BAD_HEADER, "ranked log with core_off=true is refused outside test mode")
	# a ranked run started with the switches asked for does not get them in a shipped build
	RunState.simulate_shipped_build = true
	RunState.reset()
	RunState.start_new_run_seeded(21, {"team_keys": TEAM, "mode": "short", "ascension": 0, "ranked": true, "bonuses": {},
		"loadout": {"rules_on": false, "core_off": true}})
	RunState.simulate_shipped_build = false
	_assert(RunState.rules_on and not RunState.core_off, "ranked start forces rules_on and drops core_off in a shipped build")
	t.core_slots = 2
	t.core_slots = old_slots
	# Review: reroll_rewards [slot] tampers (slot outside the offer, slot already rerolled) are refused.
	var ri := -1
	for i in log.entries.size():
		if String(log.entries[i]["fn"]) == "reroll_rewards" and (log.entries[i]["args"] as Array).size() == 1:
			ri = i
			break
	if ri >= 0:
		var tm5 := _clone(log)
		tm5.entries[ri]["args"] = [9]
		_assert(not bool(RunVerifier.verify(tm5, played["tape"])["ok"]), "reroll_rewards with a slot outside the offer is refused")
		var tm6 := _clone(log)
		tm6.entries.insert(ri + 1, (tm6.entries[ri] as Dictionary).duplicate(true))
		_assert(not bool(RunVerifier.verify(tm6, played["tape"])["ok"]), "reroll_rewards of an already rerolled slot is refused")
	# Review: an Eternal Core cannot be sold; the pick is refused and nothing is logged.
	RunState.reset()
	RunState.start_new_run_seeded(31, {"team_keys": TEAM, "mode": "short", "ascension": 0, "ranked": false, "bonuses": {},
		"loadout": {"rules_on": false}})
	t.core_slots = 2
	var cores: Array = []
	for d in RelicRegistry.all_defs_sorted():
		if String(d.core_axis) != "" and String(d.core_axis) != "run_rule" and not RunState.owned_relic_ids.has(String(d.id)):
			cores.append(String(d.id))
	if cores.size() >= 3 and not RunState.pending_rewards.is_empty():
		RunState.owned_relic_ids.clear()
		RunState.owned_relic_ids.append(cores[0])
		RunState.owned_relic_ids.append(cores[1])
		RunState.relic_stickers = {cores[0]: "eternal", cores[1]: "eternal"}
		RunState.pending_rewards = [CoreOffer.card_of(RelicRegistry.get_def(cores[2]), 0)]
		RunState._core_offer_active = true
		var nlog := RunState.action_log.entries.size()
		var owned_before := RunState.owned_relic_ids.duplicate()
		_assert(not RunState.apply_chosen_reward(RunState.pending_rewards[0], cores[0]), "selling an Eternal Core is refused")
		_assert(RunState.owned_relic_ids == owned_before and RunState.action_log.entries.size() == nlog, "refused sale changes and logs nothing")
	t.core_slots = old_slots
	# Review: runs with an event / shop Core pick replay through the referee.
	RunBot.core_script = false
	var bonus_seed := -1
	for sd2 in [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]:
		var pb: Dictionary = RunBot.play_run(sd2, TEAM)
		var bc := int(((pb["state"] as Dictionary).get("core", {}) as Dictionary).get("bonus_count", 0))
		if bc >= 1:
			bonus_seed = sd2
			var vb := RunVerifier.verify(pb["log"], pb["tape"])
			_assert(bool(vb["ok"]), "event/shop Core pick run replays (seed %d): %s" % [sd2, str(vb["message"])])
			if bool(vb["ok"]):
				_assert(int(vb["score"]) == int(pb["score"]), "same score with a bonus Core pick")
				_assert(JSON.stringify(((pb["state"] as Dictionary)["core"])) == JSON.stringify(((vb["state"] as Dictionary)["core"])), "same Core state after bonus picks")
			break
	_assert(bonus_seed >= 0, "some seed gives an event/shop Core pick")
	# Shop sells a Core pick (not a relic), and the money is in-run shards only.
	RunState.reset()
	RunState.start_new_run_seeded(11, {"team_keys": TEAM, "mode": "short", "ascension": 0, "ranked": false, "bonuses": {}})
	var items := RewardGenerator.generate_shop_items(Rng.new(1), [], {}, 2, true)
	var kinds: Array = items.map(func(i): return String(i["kind"]))
	_assert(kinds.has("core") and not kinds.has("relic"), "shop sells a Core pick, no old relic: %s" % str(kinds))
	for k in ["core_reroll", "reroll_core"]:
		_assert(not kinds.has(k), "no Core reroll for sale")
	# Bet Cores (design 2.7 N10 Fossil, N11 Dim Stone): a run that takes them replays through the referee, and a tape that
	# moves the pick (so the offer no longer matches) is refused or lands on a different state.
	for bet in ["c_fossil", "c_dim_stone"]:
		RunBot.core_pick_id = bet
		var hit := false
		for sd3 in range(1, 61):
			var pbb: Dictionary = RunBot.play_run(sd3, TEAM)
			var blog: ActionLog = pbb["log"]
			var bst: Dictionary = pbb["state"]
			# the run took the bet when its seen list holds the id AND it left a trace (Fossil is gone, Dim Stone never kept)
			var core3: Dictionary = bst.get("core", {})
			if not (core3.get("seen", []) as Array).has(bet):
				continue
			hit = true
			_assert(not (bst.get("owned_relic_ids", bst.get("relics", [])) as Array).has("c_dim_stone"), "Dim Stone is never kept in a slot")
			var vb3 := RunVerifier.verify(blog, pbb["tape"])
			_assert(bool(vb3["ok"]), "%s run replays (seed %d): %s" % [bet, sd3, str(vb3["message"])])
			if bool(vb3["ok"]):
				_assert(JSON.stringify(bst.get("core", {})) == JSON.stringify((vb3["state"] as Dictionary).get("core", {})), "%s: same Core state" % bet)
				_assert(str(bst.get("owned_relic_ids", bst.get("relics"))) == str((vb3["state"] as Dictionary).get("owned_relic_ids", (vb3["state"] as Dictionary).get("relics"))), "%s: same owned Cores" % bet)
			# tamper: a different salt in the header seed changes every offer, so the logged picks no longer fit
			var tmb := _clone(blog)
			for i4 in tmb.entries.size():
				if String(tmb.entries[i4]["fn"]) == "take_reward" and (tmb.entries[i4]["args"] as Array).size() >= 1:
					tmb.entries[i4]["args"] = [7]
					break
			_assert(not bool(RunVerifier.verify(tmb, pbb["tape"])["ok"]), "%s: tampered pick index is refused" % bet)
			break
		_assert(hit, "some seed offers %s" % bet)
	# Fossil proof: with chain [0,1,1,2] the pick after Fossil is one tier higher and Fossil is gone; on a Crystal pick it is 4 cards.
	for case in [[1, 2], [3, 4]]:
		RunState.reset()
		RunState.start_new_run_seeded(5, {"team_keys": TEAM, "mode": "short", "ascension": 0, "ranked": false, "bonuses": {}, "loadout": {"rules_on": false}})
		RunState.core_tier_chain.assign([0, 0, 1, 2])
		RunState.pending_rewards = []
		RunState.core_pick_index = int(case[0])
		RunState.owned_relic_ids.append("c_fossil")
		RunState.core_seen.clear()
		RunState._open_core_offer()
		_assert(not RunState.owned_relic_ids.has("c_fossil"), "Fossil disappears when the next pick opens")
		var tmax := 0
		for c5 in RunState.pending_rewards:
			tmax = maxi(tmax, int(c5["tier"]))
		_assert(tmax <= 2, "Fossil offer tiers valid")
		if int(case[0]) == 3:
			_assert(RunState.pending_rewards.size() == 4 or RunState.pending_rewards.size() >= 2, "Fossil on a Crystal pick: up to 4 cards")
		else:
			_assert(tmax >= 1, "Fossil lifts a moss pick: some card is Amber or better")
	# Crow Herald proof (design 2b R11): fast and clean = +1, an Axie down = -1, slow = 0, boss limit 7, off-trigger node = nothing.
	var cases := [[{"stat": {"turns": 5}, "downed": 0}, "battle", 1], [{"stat": {"turns": 6}, "downed": 0}, "battle", 0],
		[{"stat": {"turns": 2}, "downed": 1}, "battle", -1], [{"stat": {"turns": 7}, "downed": 0}, "boss", 1],
		[{"stat": {"turns": 8}, "downed": 0}, "boss", 0]]
	for cc in cases:
		CoreTestUtil.crow_setup(TEAM)
		RunState._crow_judge(cc[0], String(cc[1]))
		_assert(RunState.core_tier_bump == int(cc[2]), "Crow %s -> bump %d (got %d)" % [str(cc[0]), int(cc[2]), RunState.core_tier_bump])
	CoreTestUtil.crow_setup(TEAM)
	RunState.current_node_id = RunMapGraph.from_data(RunState.map_graph).start_node_id
	RunState._crow_judge({"stat": {"turns": 1}, "downed": 0}, "battle")
	_assert(RunState.core_tier_bump == 0, "Crow does nothing on a node that does not open a pick")
	CoreTestUtil.crow_setup(TEAM)
	RunState.run_rule = "rule_none"
	RunState._crow_judge({"stat": {"turns": 1}, "downed": 0}, "battle")
	_assert(RunState.core_tier_bump == 0, "no Crow rule, no bump")
	# Run Rule Crow Herald (rule_crow) through the referee: a whole run that took it replays to the same score and Core state,
	# and a tampered rule pick (index outside the offer / another card) is refused or lands on a different state.
	RunBot.core_pick_id = "rule_crow"
	var crow_hit := false
	for sd5 in range(1, 41):
		var pc: Dictionary = RunBot.play_run(sd5, TEAM)
		if String(((pc["state"] as Dictionary).get("core", {}) as Dictionary).get("run_rule", "")) != "rule_crow":
			continue
		crow_hit = true
		var clog: ActionLog = pc["log"]
		var vc := RunVerifier.verify(clog, pc["tape"])
		_assert(bool(vc["ok"]), "rule_crow run replays (seed %d): %s" % [sd5, str(vc["message"])])
		if bool(vc["ok"]):
			_assert(int(vc["score"]) == int(pc["score"]), "rule_crow: same score")
			_assert(JSON.stringify((pc["state"] as Dictionary).get("core", {})) == JSON.stringify((vc["state"] as Dictionary).get("core", {})),
				"rule_crow: same Core state (tier chain, bumps, seen)")
		var first_take := -1
		for i6 in clog.entries.size():
			if String(clog.entries[i6]["fn"]) == "take_reward":
				first_take = i6
				break
		_assert(first_take >= 0, "rule_crow run logged the rule pick")
		if first_take >= 0:
			var tc1 := _clone(clog)
			tc1.entries[first_take]["args"] = [9]
			_assert(not bool(RunVerifier.verify(tc1, pc["tape"])["ok"]), "rule_crow: rule pick outside the offer is refused")
			var tc2 := _clone(clog)
			var old_idx := int((tc2.entries[first_take]["args"] as Array)[0])
			tc2.entries[first_take]["args"] = [(old_idx + 1) % 2]
			var v2 := RunVerifier.verify(tc2, pc["tape"])
			_assert(not bool(v2["ok"]) or JSON.stringify(((v2["state"] as Dictionary).get("core", {}) as Dictionary).get("run_rule", "")) != "\"rule_crow\"",
				"rule_crow: swapping the rule card does not replay as the same run")
		break
	_assert(crow_hit, "some seed offers and takes rule_crow")
	RunBot.core_pick_id = ""
	# Review (a): Dim Stone with nothing to grant (pool T empty) is not kept; it becomes +1 Core reroll and says so.
	RunState.reset()
	RunState.start_new_run_seeded(5, {"team_keys": TEAM, "mode": "short", "ascension": 0, "ranked": false, "bonuses": {}, "loadout": {"rules_on": false}})
	RunState.owned_relic_ids.clear()
	for d7 in RelicRegistry.all_defs_sorted():
		if String(d7.core_axis) != "" and String(d7.core_axis) != "run_rule" and String(d7.id) != "c_dim_stone":
			RunState.owned_relic_ids.append(String(d7.id))
	var dcard := CoreOffer.card_of(RelicRegistry.get_def("c_dim_stone"), 0)
	RunState.pending_rewards = [dcard]
	RunState._core_offer_active = true
	var rr_before := RunState.core_reroll_left
	var fired: Array = []
	var on_fire := func(id, _u, _a, kind): fired.append([String(id), String(kind)])
	EventBus.core_fired.connect(on_fire)
	var took := RunState.apply_chosen_reward(dcard, "")
	EventBus.core_fired.disconnect(on_fire)
	_assert(took and not RunState.owned_relic_ids.has("c_dim_stone"), "empty-pool Dim Stone: pick succeeds, stone not kept")
	_assert(RunState.core_reroll_left == rr_before + 1, "empty-pool Dim Stone refunds one Core reroll")
	_assert(fired.has(["c_dim_stone", "reroll"]), "empty-pool Dim Stone emits core_fired (reroll)")
	_assert(String(RunState.action_log.entries.back()["fn"]) == "take_reward", "empty-pool Dim Stone pick is logged")
	# Review (b): an empty next offer must not eat the Fossil.
	RunState.reset()
	RunState.start_new_run_seeded(5, {"team_keys": TEAM, "mode": "short", "ascension": 0, "ranked": false, "bonuses": {}, "loadout": {"rules_on": false}})
	RunState.pending_rewards = []
	RunState.core_pick_index = 1
	RunState.owned_relic_ids.clear()
	for d8 in RelicRegistry.all_defs_sorted():
		if String(d8.core_axis) != "" and String(d8.core_axis) != "run_rule":
			RunState.owned_relic_ids.append(String(d8.id))
	if not RunState.owned_relic_ids.has("c_fossil"):
		RunState.owned_relic_ids.append("c_fossil")
	var opened := RunState._open_core_offer()
	_assert(not opened, "with every Core owned the next offer is empty")
	_assert(RunState.owned_relic_ids.has("c_fossil"), "an empty offer does not consume the Fossil")
	# Review (c): an old save with an open offer and no offer_pick, at pick index 0, is not a bonus offer.
	RunState._core_from_data({"pick_index": 0, "offer_active": true, "base_seed": 1, "core_off": false})
	_assert(not bool(RunState._core_ctx(RunState._core_offer_pick)["bonus"]), "old save at pick index 0: default offer_pick is not a bonus")
	RunBot.core_pick_id = ""
	_guard.restore()
	if _failures.is_empty():
		print("t_core_replay: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_core_replay: FAIL — %s" % f)
	get_tree().quit(1)
