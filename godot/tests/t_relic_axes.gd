extends Node
## Lane B: multiplier axes (relic-set-v2 §3.3), reroll caps, eternal, forced pact. Behaviour tests.

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	RelicRegistry.legacy_unhide_for_tests()
	print("=== t_relic_axes: start ===")
	test_g_axis()
	test_a_axes()
	test_reroll_caps()
	test_eternal()
	test_eternal_skips_starter()
	test_forced_pact()
	print("=== t_relic_axes: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_relic_axes: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_relic_axes: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _combat(relic_ids: Array, muts: Array = []) -> CombatEngine:
	var roster: Array = []
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
	for i in keys.size():
		roster.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": muts.duplicate(true), "growth": {}, "bonus_hp": 0})
	var c := CombatEngine.new()
	c.setup_new({"node_id": "t_relic_axes", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": roster, "relic_ids": relic_ids, "combat_seed": 99})
	return c


func _hit(c: CombatEngine, src: Unit, v: int) -> int:
	var t: Unit = c.alive_enemies()[0]
	t.max_hp = 1000
	t.hp = 1000
	t.shield = 0
	t.status = {}
	DamagePipeline.resolve({"combat": c, "src": src, "tgt": t, "value": v, "attack": true, "face_type": "dmg"})
	return 1000 - t.hp


func test_g_axis() -> void:
	var plain := _combat([])
	_assert(_hit(plain, plain.party[0], 10) == 10, "no relic: 10 dmg stays 10")
	var c := _combat(["r_ancientgene"])
	_assert(_hit(c, c.party[0], 10) == 13, "ancientgene +30%: 10 -> 13")
	# ascend x3 (+0.75) + bloodpact (+0.6) = 2.35 ; + forge (+0.3) = 2.65 -> capped 2.5
	var oc3: Array = [{"type": "oc", "mult": 1.25}, {"type": "oc", "mult": 1.25}, {"type": "oc", "mult": 1.25}]
	var c2 := _combat(["r_bloodpact"], oc3)
	_assert(is_equal_approx(RelicHooks.g_axie(c2, c2.party[0]), 2.35), "G adds: 1+0.6+0.75")
	_assert(_hit(c2, c2.party[0], 10) == 24, "10 x2.35 = 23.5 -> ceil 24")
	var c3 := _combat(["r_bloodpact"], oc3 + [{"type": "oc", "mult": 1.3}])
	_assert(is_equal_approx(RelicHooks.g_axie(c3, c3.party[0]), 2.5), "G_axie capped at 2.5")
	_assert(_hit(c3, c3.party[0], 10) == 25, "capped: 10 -> 25")
	# lonewolf: slot 1 only
	var c4 := _combat(["r_lonewolf"])
	_assert(_hit(c4, c4.party[0], 10) == 20, "lonewolf: slot 1 x2")
	_assert(_hit(c4, c4.party[1], 10) == 10, "lonewolf: other Axies unaffected")
	# non-damage faces: ascend multiplier capped x2.0 and damage faces are not baked
	var c5 := _combat([], [{"type": "oc", "mult": 1.25}, {"type": "oc", "mult": 1.25}, {"type": "oc", "mult": 1.25}, {"type": "oc", "mult": 1.25}])
	var base := _combat([])
	for i in c5.party.size():
		for j in c5.party[i].die.size():
			var f: Dictionary = c5.party[i].die[j]
			var b: Dictionary = base.party[i].die[j]
			var bv := int(b.get("value", 0))
			if bv <= 0:
				continue
			if String(f.get("type", "")) == "dmg":
				_assert(int(f["value"]) == bv, "dmg face not baked by oc")
			else:
				_assert(int(f["value"]) == int(ceil(bv * 2.0)), "non-dmg face capped x2.0")


func test_a_axes() -> void:
	var c := _combat(["r_venomengine", "r_hearthcore"])
	var e: Unit = c.alive_enemies()[0]
	e.max_hp = 1000
	e.hp = 1000
	e.status = {"poison": 5}
	StatusEngine.tick_status(c)
	_assert(1000 - e.hp == 10, "venomengine: poison tick 5 -> 10 (+100%)")
	e.hp = 1000
	e.status = {"burn": 10}
	StatusEngine.tick_status(c)
	_assert(1000 - e.hp == 17, "hearthcore: burn tick 10 -> 17 (+70%)")
	var c2 := _combat(["r_hearthcore", "r_solarcore"])
	_assert(is_equal_approx(RelicHooks.axis_sum(c2, "A:burn"), 1.7), "two burn relics add: x2.7")
	var c3 := _combat(["r_apexpredator"])
	var src: Unit = c3.party[0]
	var t: Unit = c3.alive_enemies()[0]
	t.max_hp = 1000
	t.hp = 1000
	DamagePipeline.resolve({"combat": c3, "src": src, "tgt": t, "value": 10, "attack": true, "crit": true, "face_type": "dmg"})
	_assert(1000 - t.hp == 30, "apexpredator: crit x3")
	_assert(RelicHooks.sum(c3, "critBonus") == 0.0, "apexpredator: adds no crit chance")
	var c4 := _combat([])
	t = c4.alive_enemies()[0]
	t.hp = 1000
	t.max_hp = 1000
	DamagePipeline.resolve({"combat": c4, "src": c4.party[0], "tgt": t, "value": 10, "attack": true, "crit": true, "face_type": "dmg"})
	_assert(1000 - t.hp == 20, "base crit x2")
	var c5 := _combat(["r_dawnlance"])
	t = c5.alive_enemies()[0]
	t.hp = 1000
	t.max_hp = 1000
	DamagePipeline.resolve({"combat": c5, "src": c5.party[0], "tgt": t, "value": 10, "attack": true, "face_type": "dmg"})
	_assert(1000 - t.hp == 19, "dawnlance opener +90%")


func test_reroll_caps() -> void:
	var c := _combat(["a_chaos"])
	c.mana = 10
	c.rerolls = 0
	var def: RelicDef = RelicRegistry.get_def("a_chaos")
	_assert(def.act.get("v", 0) == 4, "a_chaos gives +4")
	c.play_active("a_chaos")
	_assert(c.rerolls == 4, "first a_chaos: +4 (rerolls=%d)" % c.rerolls)
	c.chaos_reroll_given = 4
	c.rerolls = 0
	c.mana = 10
	c.used_actives = []
	c.play_active("a_chaos")
	_assert(c.rerolls == 2, "second a_chaos capped at 6 per turn total: +2 (got %d)" % c.rerolls)
	var d := _combat([])
	d.rerolls = 0
	_assert(d.grant_relic_reroll(3) == 3 and d.grant_relic_reroll(3) == 1 and d.rerolls == 4, "relic reroll cap 4/turn")
	_assert(d.grant_relic_reroll(1) == 0, "cap holds")
	_assert(int(d._state_dict()["relic_reroll_given"]) == 4, "cap counter is in the undo state")


## H8 (Liam 13/10): the starting relic (u_start) never takes an Eternal sticker; only relics granted after run start count.
func test_eternal_skips_starter() -> void:
	RunState.start_new_run_seeded(11, {"team_keys": ["plant1", "beast1", "aqua1"], "mode": "short", "ascension": 5,
		"ranked": false, "bonuses": {"start_relic_max_rarity": 0}})
	# Depth v3: the start-relic perk no longer grants a relic; it adds a 4th card to Core pick 1.
	_assert(RunState.owned_relic_ids.is_empty() and RunState.core_first_extra, "perk = 4th card on Core pick 1, no starter relic")
	var starter := "__none"
	_assert(RunState.relic_stickers.is_empty(), "starter relic carries no Eternal sticker")
	var added: Array = []
	for id in ["r_claw", "r_seedling", "r_heart", "r_fang"]:
		if id != starter and added.size() < 3:
			RunState._grant_relic(id, "reward")
			added.append(id)
	_assert(RunState.relic_stickers.size() == 2 and not RunState.relic_stickers.has(starter)
		and RunState.relic_stickers.has(added[0]) and RunState.relic_stickers.has(added[1]),
		"first two relics GRANTED after start are Eternal, starter is not")


func test_eternal() -> void:
	var saved_asc: int = RunState.ascension
	var saved_owned: Array = RunState.owned_relic_ids.duplicate()
	var saved_st: Dictionary = RunState.relic_stickers.duplicate()
	RunState.owned_relic_ids = []
	RunState.relic_stickers = {}
	RunState.ascension = 4
	RunState._grant_relic("r_claw", "reward")
	_assert(RunState.relic_stickers.is_empty(), "A4: no Eternal sticker")
	RunState.owned_relic_ids = []
	RunState.ascension = 5
	for id in ["r_claw", "r_seedling", "r_heart"]:
		RunState._grant_relic(id, "reward")
	_assert(RunState.relic_stickers.size() == 2, "A5: eternal_max 2 stickers (got %d)" % RunState.relic_stickers.size())
	_assert(RunState.relic_stickers.has("r_claw") and RunState.relic_stickers.has("r_seedling") and not RunState.relic_stickers.has("r_heart"), "first two relics are Eternal")
	_assert(not RunState.sell_relic("r_claw"), "Eternal relic cannot be sold")
	_assert(RunState.owned_relic_ids.has("r_claw"), "still owned")
	var d: Dictionary = RunState.to_data()
	_assert((d["relic_stickers"] as Dictionary).size() == 2, "stickers saved in to_data")
	RunState.owned_relic_ids = saved_owned
	RunState.relic_stickers = saved_st
	RunState.ascension = saved_asc


func test_forced_pact() -> void:
	for a in range(0, 6):
		_assert(not RelicSlots.pact_forced(a, 0) and not RelicSlots.pact_forced(a, 1), "A%d: pact skippable" % a)
	for a in range(6, 10):
		_assert(RelicSlots.pact_forced(a, 0), "A%d: first boss pact forced" % a)
		_assert(not RelicSlots.pact_forced(a, 1), "A%d: later boss pact skippable" % a)
	_assert(RelicSlots.pact_forced(10, 0) and RelicSlots.pact_forced(10, 2), "A10: every boss pact forced")
	var full: Array = ["r_claw", "r_seedling", "r_heart", "r_fang", "r_ear", "r_bloomscale", "r_rotmouth", "r_squallmark"]
	var r := RelicSlots.check_add(full, {}, "r_brittledice", 10, RelicSlots.pact_forced(10, 0))
	_assert(bool(r["needs_sell"]) and not bool(r["can_cancel"]), "forced pact on full slots: sale, no cancel")
	var r2 := RelicSlots.check_add(full, {}, "r_brittledice", 0, RelicSlots.pact_forced(0, 0))
	_assert(bool(r2["can_cancel"]), "unforced pact: can cancel")
