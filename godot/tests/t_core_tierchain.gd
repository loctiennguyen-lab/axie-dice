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
	var counts: Dictionary = {}
	for sd in 3000:
		var ch := CoreOffer.draw_tier_chain(sd * 7919 + 13, "short")
		_assert(ch.size() == 4, "short chain has 4 picks")
		_assert(ch[0] == 0 and ch[1] <= 1, "pick 1 moss, no crystal before pick 3 (%s)" % str(ch))
		_assert(ch == CoreOffer.draw_tier_chain(sd * 7919 + 13, "short"), "deterministic")
		var k := str(ch)
		counts[k] = int(counts.get(k, 0)) + 1
	_assert(counts.size() == 7, "7 distinct chains (%d)" % counts.size())
	var main := float(counts.get("[0, 1, 2, 1]", 0)) / 3000.0
	_assert(main > 0.26 and main < 0.34, "R H T H ~30%% (%.3f)" % main)
	var rare := float(counts.get("[0, 1, 1, 1]", 0)) / 3000.0
	_assert(rare > 0.02 and rare < 0.08, "R H H H ~5%% (%.3f)" % rare)
	for sd in 200:
		var f := CoreOffer.draw_tier_chain(sd, "full")
		_assert(f.size() == 6 and f.slice(0, 4) == CoreOffer.draw_tier_chain(sd, "short"), "full = short chain + 2")
	# crystal cap: 3 owned crystal Cores (short) drops a crystal pick to amber
	CoreTestUtil.enable()
	var owned := ["c_test_dice_crystal_a", "c_test_pos_crystal_a"]
	_assert(CoreOffer.effective_tier([0, 1, 2, 1], 2, 0, owned, "short") == 2, "under the cap: crystal")
	owned.append("c_test_mana_crystal_a")
	_assert(CoreOffer.effective_tier([0, 1, 2, 1], 2, 0, owned, "short") == 1, "at the cap (3): amber")
	_assert(CoreOffer.effective_tier([0, 1, 2, 1], 2, 0, owned, "full") == 2, "full cap is 4")
	_assert(CoreOffer.effective_tier([0, 1, 2, 1], 0, 1, [], "short") == 1, "bump +1")
	_assert(CoreOffer.effective_tier([0, 1, 2, 1], 2, 1, [], "short") == 2, "bump clamps at crystal")
	_assert(CoreOffer.effective_tier([0, 1, 2, 1], 1, -1, [], "short") == 0, "bump -1 floors at moss")
	_assert(CoreOffer.effective_tier([0, 1, 2, 1], 0, 0, [], "short", 2) == 2, "rule: first pick crystal")
	# the chain lives in the run save and does not touch the shared rng
	RunState.start_new_run_seeded(5, {"team_keys": ["plant1", "beast1", "aqua1"], "mode": "short", "ascension": 0,
		"ranked": false, "bonuses": {}, "loadout": {"rules_on": false, "core_off": true}})
	var chain := RunState.core_tier_chain.duplicate()
	var map_a := RunState.map_graph.duplicate(true)
	var d := RunState.to_data()
	RunState.reset()
	RunState.from_data(JSON.parse_string(JSON.stringify(d)))
	_assert(RunState.core_tier_chain == chain and chain.size() == 4, "chain survives save/load")
	_assert(RunState.core_off, "a core_off run stays core_off after save/load (explicit flag)")
	RunState.reset()
	RunState.start_new_run_seeded(5, {"team_keys": ["plant1", "beast1", "aqua1"], "mode": "short", "ascension": 0,
		"ranked": false, "bonuses": {}, "loadout": {"rules_on": false, "core_off": false}})
	_assert(RunState.map_graph == map_a, "Core offers do not change the map (shared rng untouched)")
	var d2 := RunState.to_data()
	RunState.reset()
	RunState.from_data(JSON.parse_string(JSON.stringify(d2)))
	_assert(not RunState.core_off, "a Core run stays Core after save/load")
	_done("t_core_tierchain")
