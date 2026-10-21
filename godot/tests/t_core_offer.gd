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
	# gacha C5: at most one meme Core per offer; hidden in the account's first run; they do show up from run 2
	var meme_seen := 0
	for sd in 400:
		var o := CoreOffer.build_offer(Rng.new(sd), 0, CoreTestUtil.ctx([], [], ["plant1", "beast1", "aqua1", "reptile1", "bug1"], 1), 3)
		var mc := 0
		for card in o:
			if bool((card as Dictionary).get("meme", false)):
				mc += 1
		_assert(mc <= 1, "seed %d: at most 1 meme Core per offer (got %d)" % [sd, mc])
		meme_seen += mc
		var o1 := CoreOffer.build_offer(Rng.new(sd), 0, CoreTestUtil.ctx([], [], ["plant1", "beast1", "aqua1", "reptile1", "bug1"], 1, true), 3)
		for card in o1:
			_assert(not bool((card as Dictionary).get("meme", false)), "first run: no meme Core")
	_assert(meme_seen > 0, "memes appear in Moss offers from run 2 (saw %d)" % meme_seen)
	# 3 cards, same tier, different axes, deterministic
	for tier in 3:
		for sd in 40:
			var ctx := CoreTestUtil.ctx([], [], ["plant1", "beast1", "aqua1", "reptile1", "bug1"], 1)
			var a := CoreOffer.build_offer(Rng.new(sd), tier, ctx, 3)
			var b := CoreOffer.build_offer(Rng.new(sd), tier, ctx, 3)
			_assert(a.size() == 3, "tier %d seed %d: 3 cards (got %d)" % [tier, sd, a.size()])
			_assert(a == b, "same seed -> same offer")
			var ax := _axes(a)
			var uniq: Dictionary = {}
			for x in ax:
				uniq[x] = true
			_assert(uniq.size() == ax.size(), "distinct axes %s" % str(ax))
			for c in a:
				_assert(absi(int(c["tier"]) - tier) <= 1 or String(c["axis"]) == "stat", "tier %d card tier %d (%s)" % [tier, int(c["tier"]), c["key"]])
				_assert(bool(c["core"]) and String(c["t"]) == "relic", "card shape")
	# stat only at moss, at most one stat
	for sd in 60:
		var o := CoreOffer.build_offer(Rng.new(sd), 0, CoreTestUtil.ctx(), 3)
		_assert(_axes(o).count("stat") <= 1, "max one stat card")
	# first card follows an owned axis
	var hits := 0
	for sd in 40:
		var o2 := CoreOffer.build_offer(Rng.new(sd), 1, CoreTestUtil.ctx(["c_test_pos_moss_a"]), 3)
		if _axes(o2)[0] == "pos" or not _axes(o2).has("pos"):
			hits += 1
	_assert(hits >= 36, "card 1 follows the owned axis when the pool has it (%d/40)" % hits)
	# RunState: first offer opens at run start, before any node
	_start(1)
	_assert(RunState.phase == RunState.RunPhase.REWARD and RunState.pending_rewards.size() == 3, "pick 1 opens at start with 3 cards")
	_assert(int(RunState.pending_rewards[0]["tier"]) == 0 or String(RunState.pending_rewards[0]["axis"]) == "stat", "pick 1 is moss")
	_assert(RunState.core_pick_index == 1, "one pick opened")
	var first: Dictionary = RunState.pending_rewards[0]
	_assert(RunState.apply_chosen_reward(first), "pick taken")
	_assert(RunState.owned_relic_ids.has(String(first["key"])), "core owned")
	RunState.after_node()
	_assert(RunState.phase == RunState.RunPhase.MAP and RunState.power_level == 0, "after the pick: map, no node counted")
	_assert(RunState.action_log.entries.size() == 1 and String(RunState.action_log.entries[0]["fn"]) == "take_reward", "take_reward logged")
	# perk -> 4th card on pick 1 only
	_start(2, {"bonuses": {"start_relic_max_rarity": 0}})
	_assert(RunState.pending_rewards.size() == 4 and RunState.owned_relic_ids.is_empty(), "perk: 4 cards, no relic")
	# milestones: row 5 node closes -> pick 2
	_start(3)
	RunState.apply_chosen_reward(RunState.pending_rewards[0]); RunState.after_node()
	var graph := RunMapGraph.from_data(RunState.map_graph)
	var node5 = null
	node5 = graph.get_row(5)[0]
	RunState.current_node_id = node5.id
	RunState.after_node()
	_assert(RunState.phase == RunState.RunPhase.REWARD and RunState.core_pick_index == 2 and RunState.pending_rewards.size() == 3, "row 5 opens pick 2")
	_assert(RunState.power_level == 1, "node counted once")
	RunState.apply_chosen_reward(RunState.pending_rewards[1]); RunState.after_node()
	_assert(RunState.phase == RunState.RunPhase.MAP and RunState.power_level == 1, "pick 2 closes without recounting")
	var not5 = null
	not5 = graph.get_row(4)[0]
	RunState.current_node_id = not5.id
	RunState.after_node()
	_assert(RunState.phase == RunState.RunPhase.MAP, "row 4 opens nothing")
	# full slots: sell required, logged as take_reward [idx, sell_id]
	_start(4)
	var owned_six := ["c_test_dice_moss_a", "c_test_dice_moss_b", "c_test_pos_moss_a", "c_test_pos_moss_b", "c_test_mana_moss_a", "c_test_mana_moss_b"]
	for id in owned_six:
		RunState.owned_relic_ids.append(id)
	var card: Dictionary = RunState.pending_rewards[0]
	if owned_six.has(String(card["key"])):
		card = RunState.pending_rewards[1]
	var chk := RelicSlots.check_add(RunState.owned_relic_ids, {}, String(card["key"]), 0, false)
	_assert(bool(chk["needs_sell"]), "7th Core needs a sale")
	_assert(not RunState.apply_chosen_reward(card), "no sale -> refused")
	_assert(RunState.apply_chosen_reward(card, "c_test_dice_moss_a") and not RunState.owned_relic_ids.has("c_test_dice_moss_a"), "sale accepted")
	var last: Dictionary = RunState.action_log.entries[RunState.action_log.entries.size() - 1]
	_assert(last["fn"] == "take_reward" and (last["args"] as Array).size() == 2, "log carries the sold id")
	_done("t_core_offer")
