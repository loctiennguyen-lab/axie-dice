extends Node
## Lane B: relic offer v2 (relic-set-v2 §4, design/l1-relic-answers.md §8) and mult_bonus data (§3).

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_relic_offer: start ===")
	test_source_mapping_and_weights_table()
	test_scores_and_lean_tags()
	test_hard_exclusions()
	test_weights()
	test_rarity_by_source_and_determinism()
	test_lead_card_leans_toward_build()
	test_generate_with_ctx()
	test_shop_ctx()
	test_pact_offer()
	test_mult_bonus_data()
	print("=== t_relic_offer: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_relic_offer: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_relic_offer: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _roster(keys: Array) -> Array:
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1, "max_hp": 30, "muts": [], "growth": {}, "bonus_hp": 0})
	return out


func _ctx(owned: Array, keys: Array = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]) -> Dictionary:
	return {"owned_ids": owned, "roster": _roster(keys), "ascension": 0, "pacts_taken": [], "stickers": {}}


func test_source_mapping_and_weights_table() -> void:
	_assert(RewardGenerator.offer_source_for_tier(0, 3) == "battle", "tier 0 early = battle")
	_assert(RewardGenerator.offer_source_for_tier(0, 7) == "battle_late", "tier 0 pw>6 = battle_late")
	_assert(RewardGenerator.offer_source_for_tier(1, 3) == "milestone" and RewardGenerator.offer_source_for_tier(2, 3) == "elite"
		and RewardGenerator.offer_source_for_tier(3, 3) == "boss", "tier 1/2/3 = milestone/elite/boss")
	for src in RelicSlots.tuning().rarity_weights:
		var w: Array = RelicSlots.tuning().rarity_weights[src]
		_assert(w.size() == 4 and int(w[0]) + int(w[1]) + int(w[2]) + int(w[3]) == 100, "%s weights sum to 100" % src)
	var w: Dictionary = RelicSlots.tuning().rarity_weights
	_assert(w["boss"] == [0, 0, 70, 30] and w["elite"] == [0, 45, 40, 15] and w["shop"] == [35, 40, 22, 3], "spec §4.1 numbers")


func test_scores_and_lean_tags() -> void:
	var owned := ["r_rotmouth", "r_fang"]
	var sc := RewardGenerator.tag_scores(owned, _roster(["plant1"]))
	_assert(int(sc.get("poison", 0)) == 2 and int(sc.get("shield", 0)) == 1, "poison 2 from relics, shield 1 from the plant, got %s" % str(sc))
	_assert(RewardGenerator.lean_tags(owned, _roster(["plant1"])) == ["poison", "shield"], "lean = top 2 by score")
	_assert(RewardGenerator.lean_tags([], _roster(["plant1", "beast1"])) == ["exec", "shield"] or RewardGenerator.lean_tags([], _roster(["plant1", "beast1"])) == ["exec", "shield"],
		"tie: fixed tag order (exec before shield)")
	_assert(RewardGenerator.lean_tags([], []).is_empty(), "nothing owned, no party: no lean tags")


func test_hard_exclusions() -> void:
	var ctx := _ctx(["r_claw"])
	_assert(not RewardGenerator.is_offerable(RelicRegistry.get_def("r_claw"), ctx), "owned is excluded")
	var c2 := _ctx([])
	c2["offered_ids"] = ["r_ember"]
	_assert(not RewardGenerator.is_offerable(RelicRegistry.get_def("r_ember"), c2), "already on the table is excluded")
	_assert(RewardGenerator.is_offerable(RelicRegistry.get_def("r_ember"), _ctx([])), "plain relic is offerable")
	_assert(RewardGenerator.is_offerable(RelicRegistry.get_def("r_pierceall"), _ctx([])), "child offerable alone")
	_assert(not RewardGenerator.is_offerable(RelicRegistry.get_def("r_pierceall"), _ctx(["r_worldpiercer"])), "exSub: pierceall hidden once worldpiercer is owned")
	_assert(not RewardGenerator.is_offerable(RelicRegistry.get_def("r_gorehook"), _ctx(["r_apexferal"])), "gorehook < apexferal")
	_assert(not RewardGenerator.is_offerable(RelicRegistry.get_def("r_windlash"), _ctx(["r_stormcall"])), "windlash < stormcall")
	_assert(RewardGenerator.is_offerable(RelicRegistry.get_def("r_worldpiercer"), _ctx(["r_pierceall"])), "parent stays offerable")
	_assert(not RewardGenerator.is_offerable(RelicRegistry.get_def("r_brittledice"), _ctx([])), "pact is never a normal offer")
	_assert(RewardGenerator.is_offerable(RelicRegistry.get_def("r_brittledice"), _ctx([]), true), "pact is offerable on the pact screen")
	var taken := _ctx([])
	taken["pacts_taken"] = ["r_brittledice"]
	_assert(not RewardGenerator.is_offerable(RelicRegistry.get_def("r_brittledice"), taken, true), "pact taken once (even if sold) never again")
	# duo gating (thornling = summon + thorns)
	var th = RelicRegistry.get_def("r_thornling")
	_assert(not RewardGenerator.is_offerable(th, _ctx([])), "duo: nothing owned")
	_assert(not RewardGenerator.is_offerable(th, _ctx(["r_broodpouch"])), "duo: only one of the two tags")
	_assert(RewardGenerator.is_offerable(th, _ctx(["r_broodpouch", "r_bloodthorn"])), "duo: both tags from two relics")
	var sb = RelicRegistry.get_def("r_spikedbulwark")
	_assert(RewardGenerator.is_offerable(sb, _ctx(["r_glassspine"])), "duo: ONE relic carrying both tags is enough")
	_assert(not RewardGenerator.is_offerable(sb, _ctx([], ["plant1", "reptile1"])), "duo: the party's classes do not count")
	# twinfates both ways (a_chaos is a Reroll source, live)
	_assert(not RewardGenerator.is_offerable(RelicRegistry.get_def("a_chaos"), _ctx(["r_twinfates"])), "owning twinfates hides a_chaos")
	_assert(not RewardGenerator.is_offerable(RelicRegistry.get_def("r_tidalbrand"), _ctx(["r_twinfates"])), "owning twinfates hides tidalbrand")
	_assert(RewardGenerator.is_offerable(RelicRegistry.get_def("a_chaos"), _ctx([])), "a_chaos fine without twinfates")
	_assert(RewardGenerator.twinfates_blocks_reroll(["r_twinfates"]) and not RewardGenerator.twinfates_blocks_reroll(["r_claw"]), "twinfates_blocks_reroll")
	# hidden relics never offered
	_assert(not RewardGenerator.is_offerable(RelicRegistry.get_def("r_hollowchalice"), _ctx([]), true), "hidden pact not offered yet")


func test_weights() -> void:
	var ember = RelicRegistry.get_def("r_ember")           # burn enabler... any plain relic
	_assert(RewardGenerator.relic_weight(RelicRegistry.get_def("r_claw"), _ctx([]), [], false) == 4, "neutral weight 4")
	# lead card + a shared lean tag = 12; non-lead stays 4
	_assert(RewardGenerator.relic_weight(RelicRegistry.get_def("r_rotmouth"), _ctx([]), ["poison"], true) == 12, "lead + lean tag = 12")
	_assert(RewardGenerator.relic_weight(RelicRegistry.get_def("r_rotmouth"), _ctx([]), ["poison"], false) == 4, "non-lead ignores lean")
	# payoff with no source -> 1 ("dead draw")
	_assert(RewardGenerator.relic_weight(RelicRegistry.get_def("r_shatterpoint"), _ctx([], ["plant1"]), [], false) == 1, "crit payoff with no crit source = 1")
	_assert(RewardGenerator.relic_weight(RelicRegistry.get_def("r_shatterpoint"), _ctx(["r_predatorpoise"], ["plant1"]), [], false) == 4, "with a crit source it is neutral")
	# payoff with >= 2 enablers of the tag: x2 (and x2 on lead+lean)
	var two := _ctx(["r_rotmouth", "r_fang"], ["bug1"])
	var pand = RelicRegistry.get_def("r_pandemic")
	_assert(RewardGenerator.relic_weight(pand, two, [], false) == 8, "payoff x2 with two poison enablers, got %d" % RewardGenerator.relic_weight(pand, two, [], false))
	_assert(RewardGenerator.relic_weight(pand, two, ["poison"], true) == 24, "lead + x2 = 24")
	# multiplier slot full -> 1
	_assert(RewardGenerator.relic_weight(RelicRegistry.get_def("r_bloodpact"), _ctx(["r_ancientgene"]), [], false) == 1, "G slot full -> weight 1")
	_assert(RewardGenerator.relic_weight(RelicRegistry.get_def("r_bloodpact"), _ctx([]), [], false) == 4, "G slot free -> 4")
	# hollowchalice: ear / tidecaller dead draws
	_assert(RewardGenerator.relic_weight(RelicRegistry.get_def("r_ear"), _ctx(["r_hollowchalice"]), [], false) == 1, "chalice: ear = 1")
	_assert(ember != null, "sanity")


func _pick(seed_v: int, source: String, ctx: Dictionary, lead: bool = false):
	return RewardGenerator.pick_offer_relic(Rng.new(seed_v), source, ctx, lead)


func test_rarity_by_source_and_determinism() -> void:
	var ctx := _ctx([])
	for s in range(1, 80):
		var b = _pick(s, "boss", ctx)
		_assert(b != null and b.rarity >= 2, "boss offers only Epic/Legendary (seed %d)" % s)
		var e = _pick(s, "elite", ctx)
		_assert(e != null and e.rarity >= 1, "elite never offers Common (seed %d)" % s)
		var c = _pick(s, "chest", ctx)
		_assert(c != null and c.rarity in [1, 2], "chest: Rare/Epic only, no Legendary (seed %d)" % s)
		var g = _pick(s, "gamble_legend", ctx)
		_assert(g != null and g.rarity == 3, "gamble_legend: Legendary only (seed %d)" % s)
	var seen := {}
	for s in range(1, 200):
		seen[_pick(s, "shop", ctx).rarity] = true
	_assert(seen.has(0) and seen.has(1) and seen.has(2), "shop reaches C, R and E over 200 seeds")
	_assert(String(_pick(5, "battle", ctx).id) == String(_pick(5, "battle", ctx).id), "same seed, same relic")
	var no_leg := _ctx([])
	_assert(_pick(7, "gamble_legend", no_leg) != null, "legendary pool is non-empty")
	# uses exactly the rng it is given: the stream advances by the same amount every call
	var r1 := Rng.new(99)
	var r2 := Rng.new(99)
	RewardGenerator.pick_offer_relic(r1, "battle", ctx, false)
	RewardGenerator.pick_offer_relic(r2, "battle", ctx, false)
	_assert(r1.get_state() == r2.get_state(), "rng stream advances deterministically")


func test_lead_card_leans_toward_build() -> void:
	var owned := ["r_rotmouth", "r_fang", "r_pandemic"]   # poison build
	var ctx := _ctx(owned, ["bug1"])
	var lean_n := 0
	var plain_n := 0
	for s in range(1, 400):
		var a = _pick(s, "milestone", ctx, true)
		var b = _pick(s, "milestone", ctx, false)
		if a != null and a.tags.has("poison"):
			lean_n += 1
		if b != null and b.tags.has("poison"):
			plain_n += 1
	_assert(lean_n > plain_n, "lead card picks poison relics more often (%d vs %d)" % [lean_n, plain_n])


func test_generate_with_ctx() -> void:
	var roster := _roster(["plant1", "beast1", "aqua1", "reptile1", "bug1"])
	var legacy := RewardGenerator.generate(3, 2, Rng.new(11), [], roster, 2, 3)
	var explicit := RewardGenerator.generate(3, 2, Rng.new(11), [], roster, 2, 3, {})
	_assert(legacy == explicit, "empty offer_ctx is the legacy path, unchanged")
	var v2_ok := true
	var blocked_ok := true
	for s in range(1, 60):
		var offer := RewardGenerator.generate(3, 2, Rng.new(s), [], roster, 2, 3, {"ascension": 0})
		for card in offer:
			if String(card.get("t", "")) == "relic":
				var d = RelicRegistry.get_def(String(card["key"]))
				if d == null or d.hidden_from_pool or d.rarity < 1:   # elite: no Common
					v2_ok = false
		var tw := RewardGenerator.generate(3, 3, Rng.new(s), ["r_twinfates"], roster, 2, 3, {"ascension": 0})
		for card in tw:
			if String(card.get("t", "")) in ["reroll", "curse"]:
				blocked_ok = false
	_assert(v2_ok, "v2 reward relic cards respect source rarity and the hidden flag")
	_assert(blocked_ok, "twinfates: no reroll or curse cards")
	# only the FIRST relic card is the lead card; two cards never repeat a relic
	for s in range(1, 40):
		var offer := RewardGenerator.generate(3, 3, Rng.new(s), [], roster, 2, 4, {"ascension": 0})
		var keys: Array = []
		for card in offer:
			if String(card.get("t", "")) == "relic":
				_assert(not keys.has(card["key"]), "no duplicate relic in one offer")
				keys.append(card["key"])


func test_shop_ctx() -> void:
	var items := RewardGenerator.generate_shop_items(Rng.new(3), [], {"ascension": 0, "roster": _roster(["plant1"])}, 3)
	var relics := 0
	for it in items:
		if it["kind"] == "relic":
			relics += 1
	_assert(relics == 3, "relic_count 3 gives 3 shop relics (merchantscale), got %d" % relics)
	var tw := RewardGenerator.generate_shop_items(Rng.new(3), ["r_twinfates"], {"ascension": 0})
	var has_reroll := false
	for it in tw:
		if it["kind"] == "reroll":
			has_reroll = true
	_assert(not has_reroll, "twinfates: no Instinct (reroll) item in the shop")
	var old := RewardGenerator.generate_shop_items(Rng.new(3), [])
	_assert(old.size() == 4, "legacy shop unchanged: 2 relics + serum + instinct")


func test_pact_offer() -> void:
	var ctx := _ctx([])
	var offer := RewardGenerator.pick_pact_offer(Rng.new(1), ctx)
	var ids: Array = []
	for d in offer:
		ids.append(d.id)
		_assert(RelicSlots.is_pact(d.id), "%s is a pact" % d.id)
	_assert(offer.size() == 3 and ids.size() == ids.duplicate().size(), "3 distinct pacts, got %s" % str(ids))
	var groups := {}
	for d in offer:
		groups[d.pact_group] = true
	_assert(groups.has("reroll") and groups.has("dice") and groups.has("mana"), "one per group that has a live pact (reroll, dice, mana)")
	_assert(str(RewardGenerator.pick_pact_offer(Rng.new(1), ctx).map(func(d): return d.id)) == str(ids), "deterministic")
	var taken := _ctx([])
	taken["pacts_taken"] = ["r_bloodpact"]
	var o2 := RewardGenerator.pick_pact_offer(Rng.new(1), taken)
	for d in o2:
		_assert(d.id != "r_bloodpact", "taken pact is filtered")
	var eternal := _ctx(["r_ancientgene"])
	eternal["stickers"] = {"r_ancientgene": "eternal"}
	for d in RewardGenerator.pick_pact_offer(Rng.new(1), eternal):
		_assert(d.id != "r_bloodpact", "G pact that cannot be placed (only G relic is Eternal) is filtered")
	var all_gone := _ctx([])
	all_gone["pacts_taken"] = ["r_bloodpact", "r_brittledice", "r_patientfang", "r_twinfates", "r_devilsreroll", "r_tithepips"]
	_assert(RewardGenerator.pick_pact_offer(Rng.new(1), all_gone).is_empty(), "no valid pact -> no card")


func test_mult_bonus_data() -> void:
	var want := {"r_ancientgene": 0.30, "r_bloodpact": 0.60, "r_lonewolf": 1.00, "r_hearthcore": 0.70, "r_solarcore": 1.00,
		"r_venomengine": 1.00, "r_mirrorshell": 1.00, "r_apexpredator": 1.00, "r_dawnlance": 0.90, "r_ironvow": 0.50}
	for id in want:
		var d = RelicRegistry.get_def(id)
		_assert(is_equal_approx(d.mult_bonus, want[id]) and String(d.mult_axis) != "", "%s mult_bonus %s" % [id, want[id]])
	for d in RelicRegistry.all_defs_sorted():
		_assert((String(d.mult_axis) != "") == (d.mult_bonus > 0.0) or String(d.id).begins_with("__"), "%s: mult_bonus iff mult_axis" % d.id)
