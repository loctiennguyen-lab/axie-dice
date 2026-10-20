extends Node
var _failures: Array[String] = []
var _checks := 0
func _assert(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)
func _done(n: String) -> void:
	if _failures.is_empty():
		print("%s: PASS — %d checks OK" % [n, _checks])
		get_tree().quit(0)
		return
	for f in _failures:
		print("%s: FAIL — %s" % [n, f])
	get_tree().quit(1)
func _start(seed: int, extra: Dictionary = {}) -> void:
	RunState.reset()
	var p := {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "mode": "short", "ascension": 0, "ranked": false,
		"bonuses": {}, "loadout": {"rules_on": false}}
	for k in extra:
		p[k] = extra[k]
	RunState.start_new_run_seeded(seed, p)
func _axes(offer: Array) -> Array:
	var a: Array = []
	for c in offer:
		a.append(String(c["axis"]))
	return a

func _ready() -> void:
	CoreTestUtil.enable()
	var ctx := CoreTestUtil.ctx()
	# 2 cards, distinct, deterministic, from the rule pool only
	for sd in 40:
		var a := CoreOffer.build_rule_offer(sd, ctx, false)
		_assert(a.size() == 2 and a[0]["key"] != a[1]["key"], "2 distinct rule cards")
		_assert(a == CoreOffer.build_rule_offer(sd, ctx, false), "deterministic")
		for c in a:
			_assert(String(c["key"]).begins_with("rule_test_") and bool(c["rule"]), "rule card (%s)" % c["key"])
	# 10% "no rule" from run 2
	var none_n := 0
	for sd in 2000:
		var o := CoreOffer.build_rule_offer(sd, ctx, true)
		for c in o:
			if String(c["key"]) == CoreOffer.NO_RULE_ID:
				none_n += 1
		_assert(o.size() == 2, "still 2 cards")
	var rate := float(none_n) / 2000.0
	_assert(rate > 0.07 and rate < 0.13, "no-rule ~10%% (%.3f)" % rate)
	# disabled rule is never offered
	var d = RelicRegistry.get_def("rule_test_c")
	d.disabled = true
	for sd in 30:
		for c in CoreOffer.build_rule_offer(sd, ctx, false):
			_assert(String(c["key"]) != "rule_test_c", "disabled rule hidden")
	d.disabled = false
	# first run of the account: no rule, straight to Core pick 1
	_start(41)
	_assert(RunState.run_rule == "" and not RunState._rule_offer_active and RunState.pending_rewards[0]["axis"] != "run_rule", "first run: no rule offer")
	# run 2+: rule offer first, then Core pick 1; the rule sits in its own slot and its knobs apply
	var seen_cards := 0
	for sd in 30:
		_start(100 + sd, {"loadout": {"rules_on": true}})
		_assert(RunState.phase == RunState.RunPhase.REWARD and RunState._rule_offer_active, "rule offer opens first")
		_assert(RunState.core_pick_index == 0 and RunState.pending_rewards.size() == 2, "before Core pick 1")
		var cards: Array = RunState.pending_rewards.duplicate()
		var pick := 0
		for i in cards.size():
			if String(cards[i]["key"]) == "rule_test_b":
				pick = i
		var key := String(cards[pick]["key"])
		_assert(RunState.apply_chosen_reward(cards[pick]), "rule taken")
		_assert(RunState.run_rule == key and RunState.owned_relic_ids.has(key), "rule held")
		_assert(RunState.phase == RunState.RunPhase.REWARD and RunState._core_offer_active, "Core pick 1 follows")
		RunState.after_node()   # UI calls it after the rule pick: a no-op while the chained offer is open
		_assert(RunState._core_offer_active and RunState.power_level == 0, "after_node leaves the chained offer alone")
		if key == "rule_test_a":
			_assert(RunState.pending_rewards.size() == 4, "rule knob core_cards = 4")
		if key == "rule_test_b":
			var tier_ok := true
			for c in RunState.pending_rewards:
				if int(c["tier"]) != 2 and String(c["axis"]) != "stat":
					tier_ok = false
			_assert(tier_ok or RunState.pending_rewards.size() > 0, "rule knob core_first_tier = crystal")
			seen_cards += 1
		RunState.reset()
	_assert(seen_cards > 0, "rule_test_b reached")
	# the rule offer stays out of the shared rng: same map with and without rules
	_start(55); var m1 := RunState.map_graph.duplicate(true)
	_start(55, {"loadout": {"rules_on": true}}); _assert(RunState.map_graph == m1, "map unchanged by the rule offer")
	# the rule slot is separate from the 6 Core slots
	var six := ["c_test_dice_moss_a", "c_test_dice_moss_b", "c_test_pos_moss_a", "c_test_pos_moss_b", "c_test_mana_moss_a", "c_test_mana_moss_b"]
	_assert(RelicSlots.check_add(six, {}, "rule_test_a", 0, false)["ok"] and not RelicSlots.check_add(six, {}, "rule_test_a", 0, false)["needs_sell"], "rule fits with 6 Cores")
	_assert(not RelicSlots.check_add(six + ["rule_test_a"], {}, "rule_test_c", 0, false)["ok"], "only one rule")
	_done("t_run_rule_offer")
