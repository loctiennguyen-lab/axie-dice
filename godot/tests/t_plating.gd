extends Node
## Depth v3 6.7 M1 / M6: Plating (single-target dmg cut by P, min 1), switched off by debuff/poison, wears down from turn 7.

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
var _events: Array = []
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	EventBus.plating.connect(func(uid, b, a, p): _events.append(["plating", uid, b, a, p]))
	EventBus.plating_off.connect(func(uid, t): _events.append(["off", uid, t]))
	EventBus.plating_decay.connect(func(uid, p): _events.append(["decay", uid, p]))
	_reduce()
	_off()
	_decay()
	_boss()
	_data()
	print("=== t_plating: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("t_plating: FAIL - %s" % f)
	if _failures.is_empty():
		print("t_plating: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


func _engine(kind: String = "battle", pw: int = 5, boss_key: String = "") -> CombatEngine:
	var roster: Array = []
	for i in TEAM.size():
		roster.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var c := CombatEngine.new()
	c.setup_new({"node_id": "pl", "kind": kind, "pw": pw, "ascension": 0, "roster_snapshot": roster,
		"relic_ids": [], "combat_seed": 31, "boss_key": boss_key})
	return c


func _hit(c: CombatEngine, e: Unit, v: int, extra: Dictionary = {}) -> int:
	e.hp = e.max_hp
	e.shield = 0
	var ctx := {"combat": c, "src": c.party[0], "tgt": e, "value": v, "attack": true, "single": true, "face_type": "dmg"}
	ctx.merge(extra, true)
	DamagePipeline.resolve(ctx)
	return e.max_hp - e.hp


func _reduce() -> void:
	var c := _engine()
	var e: Unit = c.enemies[0]
	e.max_hp = 200
	e.plating = 3
	_check(_hit(c, e, 4) == 1, "4 vs P3 must be 1")
	_check(_events.size() > 0 and _events[-1][0] == "plating" and _events[-1][2] == 4 and _events[-1][3] == 1, "plating event 4 -> 1")
	_check(_hit(c, e, 10) == 7, "10 vs P3 = 7")
	_check(_hit(c, e, 1) == 1, "1 stays 1 (never raised)")
	_check(_hit(c, e, 2) == 1, "2 vs P3 = 1 (min 1)")
	_check(_hit(c, e, 4, {"pierce": true}) == 4, "pierce ignores Plating")
	_check(_hit(c, e, 4, {"single": false}) == 4, "AoE / secondary ignores Plating")
	_check(_hit(c, e, 4, {"attack": false}) == 4, "non-attack (Core, thorns) ignores Plating")
	var n := _events.size()
	_hit(c, e, 4, {"src": null, "attack": false})
	_check(_events.size() == n, "no event when not plated")
	e.status["vulnerable"] = 2
	_check(_hit(c, e, 4) == 3, "vulnerable first: ceil(4*1.5)=6, then -3 = 3")
	e.status.clear()
	e.hp = e.max_hp
	e.shield = 5
	DamagePipeline.resolve({"combat": c, "src": c.party[0], "tgt": e, "value": 4, "attack": true, "single": true, "face_type": "dmg"})
	_check(e.shield == 4 and e.hp == e.max_hp, "Plating first (4->1), then shield")
	# through the engine: a real single-target face carries `single`, an aoe face does not
	c = _engine()
	e = c.enemies[0]
	e.max_hp = 200
	e.hp = 200
	e.plating = 2
	var u: Unit = c.party[1]
	u.die = [{"type": "dmg", "value": 5, "keywords": [], "name": "x", "part": "horn", "rarity": 0}]
	u.set_roll(0, false)
	_check(c.use_die(u.uid, e.uid) and e.hp == 197, "engine face: 5 - 2 = 3 dealt, got %d" % (200 - e.hp))
	u = c.party[2]
	u.die = [{"type": "dmg", "value": 5, "keywords": ["aoe"], "name": "x", "part": "horn", "rarity": 0}]
	u.set_roll(0, false)
	_check(c.use_die(u.uid, e.uid) and e.hp <= 192, "engine aoe face ignores Plating, hp %d" % e.hp)


func _off() -> void:
	var c := _engine()
	var e: Unit = c.enemies[0]
	e.max_hp = 200
	e.plating = 3
	_check(CombatTraits.plating_of(c, e) == 3, "active")
	_events.clear()
	StatusEngine.add_status(c, e, ["vulnerable:1"], c.party[0])
	_check(CombatTraits.plating_of(c, e) == 0 and e.plating_off == 1, "vulnerable switches it off for 1 (plating.off_turns 1, TD tuning 21/10)")
	_check(_events.size() > 0 and _events[0][0] == "off" and _events[0][2] == 1, "plating_off event")
	CombatTraits.turn_start(c)
	_check(e.plating_off == 0 and CombatTraits.plating_of(c, e) == 3, "back on at T+1 (off_turns 1)")
	StatusEngine.add_status(c, e, ["poison:2"], c.party[0])
	StatusEngine.add_status(c, e, ["vulnerable:1"], c.party[0])
	_check(e.plating_off == 1, "reset, not added")
	CombatTraits.turn_start(c)
	_check(CombatTraits.plating_of(c, e) == 3, "back on after the next turn start")
	StatusEngine.add_status(c, e, ["thorns:2", "regen:1"], null)
	_check(e.plating_off == 0, "buffs do not switch it off")
	var snap := Unit.from_data(e.to_data())
	_check(snap.plating == 3 and snap.plating_off == 0, "round trip")


func _decay() -> void:
	var c := _engine()
	var e: Unit = c.enemies[0]
	e.plating = 3
	# decay_turn is a knob (3 since lane E); the turns below are relative to it
	var dt := int(CombatTraits.knob("plating", "decay_turn", 7.0))
	c.turn = dt - 1
	_check(CombatTraits.plating_of(c, e) == 3, "turn before decay: full")
	c.turn = dt
	_check(CombatTraits.plating_of(c, e) == 2, "decay turn: -1")
	c.turn = dt + 2
	_check(CombatTraits.plating_of(c, e) == 0, "decay turn + 2: gone")
	_events.clear()
	c.turn = dt + 1
	CombatTraits.turn_start(c)
	_check(_events.any(func(x): return x[0] == "decay" and x[2] == 1), "plating_decay event")


func _boss() -> void:
	var c := _engine("boss", 5, "gooey_king")
	var b: Unit = c.enemies[0]
	_check(b.plating >= 2 and b.plating <= 4, "boss P clamp 2..4, got %d" % b.plating)
	b.custom_state["turn_count"] = 0
	_check(CombatTraits.plating_of(c, b) == b.plating, "prep: plated")
	b.custom_state["turn_count"] = 1
	_check(c.boss_rhythm_phase(b) == "hollow" and CombatTraits.plating_of(c, b) == 0, "hollow: Plating drops")
	b.custom_state["turn_count"] = 3
	_check(CombatTraits.plating_of(c, b) == b.plating, "strike: plated")
	c.turn = 20
	_check(CombatTraits.plating_of(c, b) == b.plating, "boss exempt from decay")
	StatusEngine.add_status(c, b, ["weaken:1"], c.party[0])
	_check(CombatTraits.plating_of(c, b) == 0, "debuff opens the boss too")


func _data() -> void:
	_check(CombatTraits.plating_for_pw(5) == 2, "pw5 P=2, got %d" % CombatTraits.plating_for_pw(5))
	_check(CombatTraits.plating_for_pw(20) == 4, "high pw clamps to 4")
	_check(CombatTraits.plating_for_pw(0) == 2, "low pw clamps to 2")
	for k in ["spikelet", "thornback", "e_bulwark"]:
		_check(String(ContentDB.enemies[k].get("trait", "")) == "plating", "%s plating" % k)
	var found := false
	for seed_i in range(1, 40):
		var d := _engine("battle", 6)
		d.combat_seed = seed_i
		d.setup_new({"node_id": "x", "kind": "battle", "pw": 6, "ascension": 0, "roster_snapshot": d_roster(), "relic_ids": [], "combat_seed": seed_i})
		for e in d.enemies:
			if String(e.custom_state.get("m_trait", "")) == "plating":
				found = true
				_check(e.plating >= 2, "trait bearer has P")
	_check(found, "some seed has a plating monster")


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)


func d_roster() -> Array:
	var roster: Array = []
	for i in TEAM.size():
		roster.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return roster
