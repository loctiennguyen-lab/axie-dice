extends Node
## Anchor data + API gate (design/proposals/mutation-and-keystones-v1.md, Liam 23/10).

var _checks := 0
var _failures: Array[String] = []


func _assert(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_failures.append(msg)


func _ready() -> void:
	var all := Anchors.all()
	_assert(all.size() == 6, "6 anchors")
	var en := Anchors.enabled()
	var en_ids: Array = []
	for a in en:
		en_ids.append(a["id"])
	en_ids.sort()
	_assert(en_ids == ["a_gambler", "a_mana_mine", "a_volley"], "enabled = Volley, Gambler, Mana Mine: %s" % str(en_ids))
	var seen_houses := {}
	for a in all:
		var id := String(a["id"])
		_assert(id.begins_with("a_"), "id prefix " + id)
		for k in ["name_en", "name_vi", "rule_en", "cost_en", "house_id"]:
			_assert(String(a.get(k, "")) != "", "%s has %s" % [id, k])
		_assert(String(a["awaken"].get("name_en", "")) != "" and String(a["awaken"].get("rule_en", "")) != "", id + " awaken")
		var cores: Array = a["house_cores"]
		_assert(cores.size() == 5, id + " has 5 house cores")
		for c in cores:
			_assert(RelicRegistry.get_def(String(c)) != null, "%s core exists: %s" % [id, c])
		_assert(Anchors.get_house(String(a["house_id"])).size() > 0, id + " house exists")
		seen_houses[a["house_id"]] = true
	_assert(seen_houses.size() == 6, "6 distinct houses")
	_assert(Anchors.get_def("nope").is_empty(), "unknown anchor -> {}")

	# houses: 14 combos, each once, all real; both mutation tiers present
	var combo_seen := {}
	for h in Anchors.houses():
		_assert(h["mutation"].has("tier1") and h["mutation"].has("tier2"), String(h["id"]) + " tiers")
		_assert(String(h["mutation"]["tier1"].get("rule_en", "")) != "" and String(h["mutation"]["tier2"].get("rule_en", "")) != "", String(h["id"]) + " tier rules")
		for cid in h["combo_ids"]:
			_assert(not CoreCombos.get_combo(String(cid)).is_empty(), "combo exists " + String(cid))
			_assert(not combo_seen.has(cid), "combo in one house " + String(cid))
			combo_seen[cid] = true
			_assert(Anchors.house_of_combo(String(cid)) == String(h["id"]), "house_of_combo " + String(cid))
	_assert(combo_seen.size() == 14, "all 14 combos assigned")
	_assert(Anchors.house_of_combo("combo_x") == "", "house_of_combo unknown")

	# offer_three: deterministic, distinct, input-order independent
	var ids: Array = ["a_volley", "a_gambler", "a_mana_mine", "a_kin", "a_embers"]
	var o1 := Anchors.offer_three(Rng.new(42), ids)
	var o2 := Anchors.offer_three(Rng.new(42), ids)
	var o3 := Anchors.offer_three(Rng.new(42), ["a_embers", "a_kin", "a_mana_mine", "a_gambler", "a_volley"])
	_assert(o1 == o2 and o1 == o3, "offer_three deterministic")
	_assert(o1.size() == 3, "offer_three size")
	var u := {}
	for x in o1:
		u[x] = true
		_assert(ids.has(x), "offer in pool")
	_assert(u.size() == 3, "offer_three distinct")
	var varied := false
	for s in range(1, 30):
		if Anchors.offer_three(Rng.new(s), ids) != o1:
			varied = true
	_assert(varied, "offer_three varies with seed")
	_assert(Anchors.offer_three(Rng.new(1), ["a_volley", "a_gambler", "a_mana_mine"]).size() == 3, "exactly 3 candidates")
	_assert(Anchors.offer_three(Rng.new(1), ["a_volley", "a_volley"]) == ["a_volley"], "dedupe, fewer than 3")

	# house_count / is_awakened
	_assert(Anchors.house_count([], "a_volley") == 0, "count 0")
	_assert(not Anchors.is_awakened([], "a_volley"), "not awakened at 0")
	_assert(not Anchors.is_awakened(["c_sonic_shield", "c_nest"], "a_volley"), "1 house core + foreign: no")
	_assert(Anchors.is_awakened(["c_sonic_shield", "c_descend"], "a_volley"), "exactly 2 awakens")
	_assert(Anchors.house_count(["c_sonic_shield", "c_descend", "c_living_wall", "c_x"], "a_volley") == 3, "count 3")
	_assert(Anchors.house_count(["c_thorn_shield"], "a_gambler") == 1 and Anchors.house_count(["c_thorn_shield"], "a_volley") == 1, "shared core counts in both houses")
	_assert(Anchors.house_count(["c_sonic_shield"], "a_nope") == 0, "unknown anchor 0")
	RunState.reset()
	RunState.owned_relic_ids = ["c_mana_pool"]
	RunState.core_quest_done = ["c_dewdrop"]
	_assert(Anchors.is_awakened(RunState.combo_owned_ids(), "a_mana_mine"), "finished quest Core counts (combo_owned_ids)")
	_assert(not Anchors.is_awakened(RunState.owned_relic_ids, "a_mana_mine"), "...but not in owned_relic_ids alone")

	# mutation_tier
	var h := "h_volley"
	var none := Anchors.mutation_tier([], h, CoreCombos.state([]))
	_assert(none == 0, "no combo -> 0")
	var pair1: Array = ["c_living_wall", "c_thorn_shield"]
	_assert(Anchors.mutation_tier(pair1, h, CoreCombos.state(pair1)) == 1, "one Pair -> 1")
	var full1: Array = ["c_living_wall", "c_thorn_shield", "c_gatekeeper"]
	_assert(Anchors.mutation_tier(full1, h, CoreCombos.state(full1)) == 2, "Full -> 2")
	var two: Array = ["c_living_wall", "c_thorn_shield", "c_sonic_shield", "c_backline_glow"]
	_assert(Anchors.mutation_tier(two, h, CoreCombos.state(two)) == 2, "2 Pairs same house -> 2")
	# two Pairs that share a Core (turtle_fort + shield_engine share c_thorn_shield) stay tier 1
	var shared3: Array = ["c_living_wall", "c_thorn_shield", "c_sonic_shield"]
	_assert(Anchors.mutation_tier(shared3, h, CoreCombos.state(shared3)) == 1, "2 Pairs sharing a Core -> 1")
	# Pair in another house does not count; two houses can both be on
	var cross: Array = ["c_living_wall", "c_thorn_shield", "c_mana_pool", "c_deep_current"]
	var st := CoreCombos.state(cross)
	_assert(Anchors.mutation_tier(cross, "h_volley", st) == 1 and Anchors.mutation_tier(cross, "h_mana_mine", st) == 1, "other-house pair stays tier 1")
	_assert(Anchors.mutation_tier(cross, "h_kin", st) == 0, "house w/o combo 0")
	# combo hidden by a Run Rule is absent from state -> no mutation
	_assert(Anchors.mutation_tier([], h, {"combo_turtle_fort": "pair"}) == 1, "state dict is authoritative")
	_assert(Anchors.mutation_tier([], "h_none", {"combo_turtle_fort": "full"}) == 0, "unknown house 0")
	# jackpot: Full only, jumps to tier 2
	var jp: Array = ["c_cascade", "c_sixth_die", "c_thorn_shield"]
	_assert(Anchors.mutation_tier(jp, "h_big_hand", CoreCombos.state(jp)) == 2, "jackpot -> tier 2")
	# quest Core done counts via combo_owned_ids
	RunState.reset()
	RunState.owned_relic_ids = ["c_sixth_die"]
	RunState.core_quest_done = ["c_collector"]
	var qo := RunState.combo_owned_ids()
	_assert(Anchors.mutation_tier(qo, "h_big_hand", CoreCombos.state(qo)) == 1, "quest-done Core makes the Pair")
	RunState.reset()

	if _failures.is_empty():
		print("t_anchors: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_anchors: FAIL — %s" % f)
	get_tree().quit(1)
