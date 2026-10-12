extends Node
## Lane B: multiplier axes (relic-set-v2 §3.3), reroll caps, eternal, forced pact. Behaviour tests.

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_relic_axes: start ===")
	test_g_axis()
	test_a_axes()
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
