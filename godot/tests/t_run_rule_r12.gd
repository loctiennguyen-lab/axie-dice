extends Node
## Depth v3 2b R12 Vo Cung, engine half: shield / poison / debuff faces of the Axie +side_face_bonus, plating_global.
## R13 is deliberately absent (lane C does it through a Core hook).

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	var r: Array = []
	for i in ["plant1", "reptile1", "bug1"].size():
		var k: String = ["plant1", "reptile1", "bug1"][i]
		r.append({"persistent_id": i + 1, "hero_key": k, "tier": 1, "max_hp": ContentDB.heroes[k]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var off := _fight(r, [])
	var on := _fight(r, ["R12"])
	for ui in off.party.size():
		var u0: Unit = off.party[ui]
		var u1: Unit = on.party[ui]
		for fi in u0.die.size():
			var t := String(u0.die[fi].get("type", ""))
			var a := off._face_value(u0, fi)
			var b := on._face_value(u1, fi)
			var want := a + (2 if ((t == "shield" or t == "poison") and a > 0) else 0)
			_check(b == want, "%s face %d (%s): %d -> %d, want %d" % [u0.key, fi, t, a, b, want])
	# enemy faces never get the bonus
	var e0: Unit = off.enemies[0]
	var e1: Unit = on.enemies[0]
	for fi in e0.die.size():
		var t2 := String(e0.die[fi].get("type", ""))
		if t2 == "shield" or t2 == "poison":
			_check(off._face_value(e0, fi) == on._face_value(e1, fi), "enemy %s face unchanged" % t2)
	# debuff keyword strength
	var bug: Unit = on.party[2]
	var kws := CombatTraits.side_bonus_keywords(on, bug, "debuff", ["weaken:2", "stun"])
	_check(kws == ["weaken:4", "stun"], "weaken:2 -> weaken:4, stun stays: %s" % str(kws))
	_check(CombatTraits.side_bonus_keywords(off, bug, "debuff", ["weaken:2"]) == ["weaken:2"], "no R12, no bonus")
	_check(CombatTraits.side_bonus_keywords(on, on.enemies[0], "debuff", ["weaken:2"]) == ["weaken:2"], "enemy debuff unchanged")
	# plating_global (already there): every enemy has Plating 2
	var tank: Unit = on.enemies[0]
	tank.plating = 0
	_check(CombatTraits.plating_of(on, tank) == 2, "R12: Plating 2 on everything")
	_check(CombatTraits.plating_of(off, tank) == 0, "no R12: none")
	print("=== t_run_rule_r12: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("t_run_rule_r12: FAIL - %s" % f)
	if _failures.is_empty():
		print("t_run_rule_r12: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


func _fight(roster: Array, rules: Array) -> CombatEngine:
	var c := CombatEngine.new()
	c.setup_new({"node_id": "r12", "kind": "battle", "pw": 8, "ascension": 0, "roster_snapshot": roster, "relic_ids": [],
		"combat_seed": 5, "run_rules": rules})
	return c


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)
