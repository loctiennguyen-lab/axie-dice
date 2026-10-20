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
	_start(11)
	var before: Array = RunState.pending_rewards.duplicate(true)
	_assert(RunState.core_reroll_left == 2 and RunState.reward_reroll_charges == 2, "2 Core rerolls per run")
	var old_key := String(before[1]["key"])
	var ok := RunState.reroll_pending_rewards(777, 1)
	_assert(ok, "card reroll works")
	var after: Array = RunState.pending_rewards
	_assert(after[0] == before[0] and after[2] == before[2], "the other cards stay")
	_assert(String(after[1]["key"]) != old_key, "card replaced")
	_assert(int(after[1]["tier"]) == int(before[1]["tier"]), "same tier")
	_assert(RunState.core_seen.has(old_key) and RunState.core_seen.has(String(after[1]["key"])), "both ids in core_seen")
	_assert(RunState.core_reroll_left == 1 and RunState.reward_reroll_charges == 1, "one left")
	_assert(not RunState.reroll_pending_rewards(778, 1), "same slot only once per offer")
	var last: Dictionary = RunState.action_log.entries[RunState.action_log.entries.size() - 1]
	_assert(last["fn"] == "reroll_rewards" and last["args"] == [1], "logged reroll_rewards [slot]")
	_assert(RunState.reroll_pending_rewards(779, 0), "second reroll, other slot")
	_assert(RunState.core_reroll_left == 0 and not RunState.reroll_pending_rewards(780, 2), "none left for the run")
	# the replaced card never comes back, in this offer or later
	for sd in 30:
		var ctx := CoreTestUtil.ctx([], RunState.core_seen.duplicate())
		var o := CoreOffer.build_offer(Rng.new(sd), 0, ctx, 3)
		for c in o:
			_assert(not RunState.core_seen.has(String(c["key"])), "seen cards never offered again")
	# same-axis preference: an axis with a spare card of that tier keeps its axis
	var offer := CoreOffer.build_offer(Rng.new(3), 1, CoreTestUtil.ctx(), 3)
	var ctx2 := CoreTestUtil.ctx([], [])
	for c in offer:
		ctx2["seen"].append(String(c["key"]))
	var axis0 := String(offer[0]["axis"])
	var nc := CoreOffer.reroll_card(Rng.new(5), offer, 0, ctx2)
	_assert(not nc.is_empty() and int(nc["tier"]) == 1, "amber stays amber")
	_assert(String(nc["axis"]) == axis0 or CoreOffer._same_tier(CoreOffer.valid_pool(ctx2), axis0, 1, []).is_empty(), "same axis while the pool has one")
	# whole-run: a later offer gets its own slots back
	_start(12)
	RunState.reroll_pending_rewards(1, 0)
	RunState.apply_chosen_reward(RunState.pending_rewards[0]); RunState.after_node()
	RunState.add_core_tier_bump(0)
	var g := RunMapGraph.from_data(RunState.map_graph)
	RunState.current_node_id = g.get_row(5)[0].id
	RunState.after_node()
	_assert(RunState.core_rerolled_slots.is_empty() and RunState.core_reroll_left == 1, "new offer: slots free, run budget 1 left")
	# review fix 1: a reroll uses the pick index of its own offer. Pick 1 (index 0) never shows a quest Core, rerolled or not.
	for sd in 40:
		_start(100 + sd)
		_assert(RunState._core_offer_pick == 0 and RunState.core_pick_index == 1, "offer 1 remembers pick index 0")
		RunState.reroll_pending_rewards(sd, sd % 3)
		for c in RunState.pending_rewards:
			_assert(String(c["axis"]) != "quest", "first pick: reroll never gives a quest Core (seed %d)" % sd)
	# review fix 1: the per-offer caps hold for the replacement, same axis and other axis
	var cx := CoreTestUtil.ctx([], [], ["plant1", "beast1", "aqua1", "reptile1", "bug1"], 1)
	var pool := CoreOffer.valid_pool(cx)
	var q = null
	var st: Array = []
	for d in pool:
		if String(d.core_axis) == "quest" and q == null:
			q = d
		if String(d.core_axis) == "stat" and int(d.rarity) == 0:
			st.append(d)
	if q != null:
		var other = null
		for d in pool:
			if String(d.core_axis) != "quest" and String(d.core_axis) != "stat":
				other = d
				break
		if other != null:
			var o2: Array = [CoreOffer.card_of(other, 0), CoreOffer.card_of(q, 1), CoreOffer.card_of(st[0], 2)]
			o2[0]["tier"] = int(q.rarity)
			for sd in 40:
				var rc := CoreOffer.reroll_card(Rng.new(sd), o2, 0, cx)
				_assert(rc.is_empty() or String(rc["axis"]) != "quest", "quest cap: no 2nd quest card from a reroll")
	if st.size() >= 3:
		var o3: Array = [CoreOffer.card_of(st[0], 0), CoreOffer.card_of(st[1], 1), CoreOffer.card_of(st[2], 2)]
		for sd in 20:
			var cap := CoreOffer.tuning().core_stat_max_per_offer
			var o4: Array = o3.duplicate(true)
			var rr := CoreOffer.reroll_card(Rng.new(sd), o4, 0, cx)
			# The two cards that stay are already stat: the replacement may be stat only if two more still fit.
			var adds_stat: bool = not rr.is_empty() and String(rr["axis"]) == "stat"
			_assert(not adds_stat or 2 < cap, "stat cap holds for the replacement")
	_done("t_core_reroll_card")
