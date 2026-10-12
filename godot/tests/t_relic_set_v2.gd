extends Node
## Lane B: relic set v2 (design/proposals/relic-set-v2.md). One test group per relic family that
## runs on hooks that exist today; the relics that wait for the new hooks are only checked for
## "data present, hidden from the pool" (pool shape test at the bottom).

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_relic_set_v2: start ===")
	test_pool_shape()
	test_bookend()
	test_brittledice_pact()
	test_towershield_and_soulforge()
	test_patientfang_pact()
	test_festermark_merge()
	test_is_wounded_and_carrioncall()
	test_coupmark()
	test_spikedbulwark()
	test_thornling()
	test_heart_rework()
	test_ancientgene_rework()
	test_bloodpact_rework()
	test_broodpouch_turn3_egg()
	test_active_buffs()
	test_state_survives_roundtrip()
	print("=== t_relic_set_v2: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_relic_set_v2: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_relic_set_v2: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _combat(relic_ids: Array, seed_v: int = 777) -> CombatEngine:
	var roster: Array = []
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
	for i in keys.size():
		roster.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var c := CombatEngine.new()
	c.setup_new({"node_id": "t_relic_set_v2", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": roster, "relic_ids": relic_ids, "combat_seed": seed_v})
	return c


func _dmg_through(c: CombatEngine, src: Unit, tgt: Unit, v: float) -> float:
	return float(RelicHooks.run_value_hook(c, "mod_dmg", {"src": src, "tgt": tgt, "combat": c}, v))


func test_pool_shape() -> void:
	var passive := 0
	var active := 0
	var visible := 0
	for d in RelicRegistry.all_defs_sorted():
		if String(d.id).begins_with("__"):
			continue
		if d.act_cost > 0:
			active += 1
		else:
			passive += 1
		if not d.hidden_from_pool:
			visible += 1
		_assert(String(d.layer) != "" and d.tags.size() >= 1 and d.tags.size() <= 2,
			"%s: needs layer and 1-2 tags" % d.id)
		_assert(not d.hidden_from_pool or String(d.needs_hook) != "", "%s hidden without needs_hook" % d.id)
	_assert(passive == 117 and active == 16, "133 relics = 117 passive + 16 active, got %d + %d" % [passive, active])
	var offerable: Array = RelicRegistry.offerable_defs_sorted()
	_assert(offerable.size() == visible, "offerable pool == non-hidden defs")
	for id in ["r_bookend", "r_festermark", "r_thornling", "r_twinfates", "r_fumeblossom"]:
		_assert(RelicRegistry.get_def(id) != null, "%s has a def" % id)
	_assert(RelicRegistry.get_def("r_twinfates").hidden_from_pool, "twinfates waits for H7")
	_assert(not RelicRegistry.get_def("r_bookend").hidden_from_pool, "bookend is live")
	for id in ["r_rotbite", "r_tinderbox", "r_openwound", "r_voidgene", "r_spines", "r_swarmnest"]:
		_assert(RelicRegistry.get_def(id) == null, "%s merged away" % id)
	var mults := 0
	for d in RelicRegistry.all_defs_sorted():
		if String(d.mult_axis) != "":
			mults += 1
	_assert(mults == 10, "10 relics hold a multiplier slot (3 G + 7 A), got %d" % mults)


func test_bookend() -> void:
	var plain := _combat([])
	var c := _combat(["r_bookend"])
	for i in plain.party.size():
		for j in plain.party[i].die.size():
			var b: Dictionary = plain.party[i].die[j]
			var a: Dictionary = c.party[i].die[j]
			var want: int = int(b["value"]) + (3 if (String(b["type"]) == "dmg" and (i == 0 or i == 4)) else 0)
			_assert(int(a["value"]) == want, "bookend party %d face %d: want %d got %d" % [i, j, want, int(a["value"])])


func test_brittledice_pact() -> void:
	var plain := _combat([])
	var c := _combat(["r_brittledice"])
	for i in plain.party.size():
		for j in plain.party[i].die.size():
			var b: Dictionary = plain.party[i].die[j]
			var a: Dictionary = c.party[i].die[j]
			var t := String(b["type"])
			var want := int(b["value"])
			if t == "dmg":
				want += 4
			elif t == "shield" or t == "heal":
				want = want / 2
			_assert(int(a["value"]) == want, "brittledice party %d face %d (%s): want %d got %d" % [i, j, t, want, int(a["value"])])
	_assert(RelicSlots.is_pact("r_brittledice") and RelicRegistry.get_def("r_brittledice").pact_group == "dice", "brittledice is a dice pact")


func test_towershield_and_soulforge() -> void:
	var c := _combat(["r_towershield"])
	var src: Unit = c.party[0]
	var tgt: Unit = c.alive_enemies()[0]
	src.shield = 0
	_assert(_dmg_through(c, src, tgt, 10.0) == 10.0, "towershield: no shield, no bonus")
	src.shield = 9
	_assert(_dmg_through(c, src, tgt, 10.0) == 12.0, "towershield: 9 shield -> +2")
	src.shield = 500
	_assert(_dmg_through(c, src, tgt, 10.0) == 16.0, "towershield: capped at +6")
	var f := _combat(["r_soulforge"])
	var fs: Unit = f.party[0]
	fs.shield = 25
	_assert(_dmg_through(f, fs, f.alive_enemies()[0], 10.0) == 12.0, "soulforge: 25 shield -> +2")
	fs.shield = 999
	_assert(_dmg_through(f, fs, f.alive_enemies()[0], 10.0) == 16.0, "soulforge: capped at +6")
	_assert(RelicHooks.sum(f, "dr") == 0.0, "soulforge no longer reduces damage taken")
	# shield faces no longer get +2
	var plain := _combat([])
	var j := 0
	for face in plain.party[0].die:
		if String(face["type"]) == "shield":
			_assert(int(f.party[0].die[j]["value"]) == int(face["value"]), "soulforge: shield face unchanged")
		j += 1


func test_patientfang_pact() -> void:
	var c := _combat(["r_patientfang"])
	var src: Unit = c.party[0]
	var tgt: Unit = c.alive_enemies()[0]
	c.turn = 1
	_assert(_dmg_through(c, src, tgt, 10.0) == 0.0, "patientfang: turn 1 deals 0")
	c.turn = 2
	_assert(_dmg_through(c, src, tgt, 10.0) == 12.0, "patientfang: turn 2 +2")
	c.turn = 4
	_assert(_dmg_through(c, src, tgt, 10.0) == 16.0, "patientfang: turn 4 +6")
	c.turn = 30
	_assert(_dmg_through(c, src, tgt, 10.0) == 24.0, "patientfang: capped at +14")


func test_festermark_merge() -> void:
	var c := _combat(["r_festermark"])
	var src: Unit = c.party[0]
	var tgt: Unit = c.alive_enemies()[0]
	tgt.status.erase("poison")
	tgt.status.erase("burn")
	_assert(_dmg_through(c, src, tgt, 10.0) == 10.0, "festermark: clean target, no bonus")
	tgt.status["poison"] = 1
	_assert(_dmg_through(c, src, tgt, 10.0) == 12.0, "festermark: poisoned +2")
	tgt.status.erase("poison")
	tgt.status["burn"] = 3
	_assert(_dmg_through(c, src, tgt, 10.0) == 12.0, "festermark: burning +2")
	tgt.status["poison"] = 1
	_assert(_dmg_through(c, src, tgt, 10.0) == 14.0, "festermark: both +4, flat (no multiplier)")


func test_is_wounded_and_carrioncall() -> void:
	var plain := _combat([])
	var e: Unit = plain.alive_enemies()[0]
	e.hp = e.max_hp
	e.status["poison"] = 9
	_assert(not DamagePipeline.is_wounded(plain, e), "no carrioncall: full HP + poison is not wounded")
	e.hp = int(e.max_hp * 0.4)
	e.status.erase("poison")
	_assert(DamagePipeline.is_wounded(plain, e), "below 50% HP is wounded")
	e.hp = int(e.max_hp * 0.6)
	_assert(DamagePipeline.is_wounded(plain, e, 0.65), "alphafang threshold 65% (parameter)")
	var c := _combat(["r_carrioncall", "r_scentofblood", "r_dawnlance"])
	var t: Unit = c.alive_enemies()[0]
	var src: Unit = c.party[0]
	t.hp = t.max_hp
	t.status["poison"] = 4
	_assert(not DamagePipeline.is_wounded(c, t), "carrioncall: 4 poison is not enough")
	_assert(_dmg_through(c, src, t, 10.0) == ceil(10.0 * 1.9), "dawnlance applies to a not-wounded target")
	t.status["poison"] = 5
	_assert(DamagePipeline.is_wounded(c, t), "carrioncall: 5 poison counts as wounded")
	_assert(_dmg_through(c, src, t, 10.0) == 14.0, "scentofblood +4 and dawnlance off, same wounded test")


func test_coupmark() -> void:
	var c := _combat(["r_coupmark"])
	var src: Unit = c.party[0]
	var t: Unit = c.alive_enemies()[0]
	t.max_hp = 100
	# wounded before (30 -> 20 after a hit of 10), crit, ends <= 25%: dies
	t.hp = 20
	RelicHooks.fire(c, "on_hit", {"type": "dmg", "dealt": 10, "tgt": t, "crit": true, "src": src, "combat": c})
	_assert(t.hp <= 0, "coupmark: crit leaving a wounded target at <=25% kills it")
	var t2: Unit = c.alive_enemies()[0] if not c.alive_enemies().is_empty() else null
	if t2 != null:
		t2.max_hp = 100
		t2.hp = 20
		RelicHooks.fire(c, "on_hit", {"type": "dmg", "dealt": 10, "tgt": t2, "crit": false, "src": src, "combat": c})
		_assert(t2.hp == 20, "coupmark: no crit, no execute")
		t2.hp = 20
		RelicHooks.fire(c, "on_hit", {"type": "dmg", "dealt": 70, "tgt": t2, "crit": true, "src": src, "combat": c})
		_assert(t2.hp == 20, "coupmark: target was NOT wounded before the hit (90 -> 20), no execute")
		t2.hp = 30
		RelicHooks.fire(c, "on_hit", {"type": "dmg", "dealt": 5, "tgt": t2, "crit": true, "src": src, "combat": c})
		_assert(t2.hp == 30, "coupmark: left above 25%, survives")


func test_spikedbulwark() -> void:
	var c := _combat(["r_spikedbulwark"])
	var u: Unit = c.party[1]
	u.status["thorns"] = 1
	u.shield = 12
	RelicHooks.fire(c, "on_shield", {"v": 12, "tgt": u, "combat": c})
	_assert(int(u.status["thorns"]) == 3, "spikedbulwark: 12 shield -> +2 thorns, got %d" % int(u.status["thorns"]))
	u.shield = 200
	RelicHooks.fire(c, "on_shield", {"v": 5, "tgt": u, "combat": c})
	_assert(int(u.status["thorns"]) == 5, "spikedbulwark: capped at +4 total (1 base + 4)")
	RelicHooks.fire(c, "on_shield", {"v": 5, "tgt": u, "combat": c})
	_assert(int(u.status["thorns"]) == 5, "spikedbulwark: re-firing does not stack")
	RelicHooks.fire(c, "on_turn_start", {"combat": c})
	_assert(int(u.status["thorns"]) == 1, "spikedbulwark: bonus removed at the next turn start, base kept")


func test_thornling() -> void:
	var c := _combat(["r_thornling"])
	var egg: Unit = c._mk_ally()
	c.party.append(egg)
	RelicHooks.fire(c, "on_turn_start", {"combat": c})
	_assert(int(egg.status.get("thorns", 0)) == 3, "thornling: egg has thorns 3")
	var left: Unit = c.party[c.party.size() - 2]
	var before: int = left.shield
	RelicHooks.fire(c, "on_thorns", {"src": c.alive_enemies()[0], "tgt": egg, "th": 3, "combat": c})
	_assert(left.shield == before + 2, "thornling: neighbour gains 2 shield (plant gets +2 BULWARK on top, so >=)" if left.cls != "plant" else "thornling: shield gained")
	# a non-egg thorns reflect does nothing extra
	var other: Unit = c.party[2]
	var s2: int = c.party[1].shield
	RelicHooks.fire(c, "on_thorns", {"src": c.alive_enemies()[0], "tgt": other, "th": 3, "combat": c})
	_assert(c.party[1].shield == s2, "thornling: only Eggs trigger it")


func test_heart_rework() -> void:
	var c := _combat(["r_heart"])
	var u: Unit = c.party[0]
	u.hp = int(u.max_hp * 0.2)
	u.shield = 0
	var other: Unit = c.party[1]
	other.shield = 0
	RelicHooks.fire(c, "on_turn_start", {"combat": c})
	_assert(u.shield >= 6, "heart: Axie under 30% gains 6 shield")
	_assert(other.shield == 0, "heart: healthy Axie gains nothing")
	_assert(RelicRegistry.get_def("r_heart").rarity == 0, "heart is Common now")


func test_ancientgene_rework() -> void:
	var c := _combat(["r_ancientgene"])
	var plain := _combat([])
	var grew := 0
	for i in plain.party.size():
		for j in plain.party[i].die.size():
			if (plain.party[i].die[j]["keywords"] as Array).has("growth"):
				grew += 1
				_assert(c.party[i].get_growth(j) == 1, "ancientgene: growth face gets +1 growth")
	_assert(grew > 0, "sanity: the roster has at least one growth face")
	_assert(RelicRegistry.get_def("r_ancientgene").mult_axis == "G", "ancientgene holds the G slot")


func test_bloodpact_rework() -> void:
	var plain := _combat([])
	var c := _combat(["r_bloodpact"])
	_assert(c.max_rerolls == plain.max_rerolls - 2, "bloodpact: max rerolls -2")
	_assert(RelicHooks.mul(c, "dmgMult", 1.0) == 1.6, "bloodpact: still x1.6 damage")


func test_broodpouch_turn3_egg() -> void:
	var c := _combat(["r_broodpouch"])
	var eggs_at_start := _eggs(c)
	_assert(eggs_at_start == 1, "broodpouch: 1 egg at the start, got %d" % eggs_at_start)
	c.turn = 2
	RelicHooks.fire(c, "on_turn_start", {"combat": c})
	_assert(_eggs(c) == 1, "broodpouch: nothing on turn 2")
	c.turn = 3
	RelicHooks.fire(c, "on_turn_start", {"combat": c})
	_assert(_eggs(c) == 2, "broodpouch: turn 3 with <3 eggs adds one")
	c.party.append(c._mk_ally())
	RelicHooks.fire(c, "on_turn_start", {"combat": c})
	_assert(_eggs(c) == 3, "broodpouch: 3 eggs, no more")


func _eggs(c: CombatEngine) -> int:
	var n := 0
	for u in c.party:
		if u.is_token and u.hp > 0:
			n += 1
	return n


func test_active_buffs() -> void:
	var ps = RelicRegistry.get_def("a_perfectstrike")
	var cd = RelicRegistry.get_def("a_coupdegrace")
	var nova = RelicRegistry.get_def("a_nova")
	_assert(ps.act_cost == 4 and int(ps.act["v"]) == 8, "perfect strike 4 MP, 8 dmg")
	_assert(cd.act_cost == 4 and int(cd.act["v"]) == 15, "coup de grace 4 MP, 15 dmg")
	_assert(nova.act_cost == 7 and int(nova.act["v"]) == 12, "gene nova 7 MP, 12 dmg")


func test_state_survives_roundtrip() -> void:
	var c := _combat(["r_spikedbulwark"])
	var u: Unit = c.party[0]
	u.shield = 20
	RelicHooks.fire(c, "on_shield", {"v": 20, "tgt": u, "combat": c})
	var u2 := Unit.from_data(u.to_data())
	_assert(int(u2.custom_state.get("spiked_bonus", 0)) == 4, "spiked_bonus survives to_data/from_data (undo, save/resume)")
	var c2 := CombatEngine.new()
	c2.from_data(c.to_data())
	_assert(int(c2.party[0].custom_state.get("spiked_bonus", 0)) == 4, "spiked_bonus survives CombatEngine to_data/from_data")
