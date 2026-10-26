extends Node
## Depth v3 6.7 M2 Ward, M3 Spite, M4 Mend + trait assignment (6.7b.5-8) + Elite affix A schema.

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
var _ev: Array = []
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	EventBus.ward.connect(func(s, t, a): _ev.append(["ward", s, t, a]))
	EventBus.mend.connect(func(s, t, a): _ev.append(["mend", s, t, a]))
	EventBus.spite.connect(func(s, t, d, n): _ev.append(["spite", s, t, d, n]))
	_ward()
	_mend()
	_spite()
	_assign()
	_affix_schema()
	print("=== t_enemy_traits: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("t_enemy_traits: FAIL - %s" % f)
	if _failures.is_empty():
		print("t_enemy_traits: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


func _roster() -> Array:
	var roster: Array = []
	for i in TEAM.size():
		roster.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return roster


func _engine(kind: String = "battle", pw: int = 6, extra: Dictionary = {}, seed_value: int = 5) -> CombatEngine:
	var c := CombatEngine.new()
	var s := {"node_id": "tr", "kind": kind, "pw": pw, "ascension": 0, "roster_snapshot": _roster(),
		"relic_ids": [], "combat_seed": seed_value}
	s.merge(extra, true)
	c.setup_new(s)
	return c


## Fight with plain enemies we can arrange: drop every trait, then set what the case needs.
func _arena(n: int = 3, pw: int = 8) -> CombatEngine:
	var c := _engine("battle", pw)
	while c.enemies.size() < n:
		c.enemies.append(c._mk_monster("slime", 1.0, {"hp": 1.0, "dmg": 1.0}))
	while c.enemies.size() > n:
		c.enemies.pop_back()
	for e in c.enemies:
		(e as Unit).custom_state.erase("m_trait")
		(e as Unit).plating = 0
		(e as Unit).shield = 0
		(e as Unit).max_hp = 20
		(e as Unit).hp = 20
	return c


func _ward() -> void:
	_check(CombatTraits.ward_amount(5) == 4 and CombatTraits.ward_amount(11) == 5 and CombatTraits.ward_amount(40) == 7, "S = 3 + pw/4, max 7")
	var c := _arena(3, 8)
	c.enemies[0].custom_state["m_trait"] = "ward"
	c.enemies[0].shield = 3
	c.enemies[1].shield = 1
	c.enemies[2].shield = 2
	_ev.clear()
	c.turn = 2
	CombatTraits.enemy_phase_start(c)
	_check(c.enemies[1].shield == 6, "lowest shield (1) gets S=5, got %d" % c.enemies[1].shield)
	_check(_ev.size() == 1 and _ev[0][0] == "ward" and _ev[0][3] == 5, "ward event")
	# stack cap 2 x S
	for e in c.enemies:
		e.shield = 9
	_ev.clear()
	CombatTraits.enemy_phase_start(c)
	_check(c.enemies[0].shield == 10 and _ev.size() == 1 and _ev[0][3] == 1, "cap 2xS: only +1 up to 10")
	for e in c.enemies:
		e.shield = 10
	_ev.clear()
	CombatTraits.enemy_phase_start(c)
	_check(_ev.is_empty(), "at the cap: nothing")
	# anti-stall: no ward from the decay turn
	for e in c.enemies:
		e.shield = 0
	c.turn = 7
	CombatTraits.enemy_phase_start(c)
	_check(c.enemies[0].shield == 0, "ward stops at turn 7")
	# tie -> smallest slot
	c.turn = 2
	CombatTraits.enemy_phase_start(c)
	_check(c.enemies[0].shield == 5, "tie goes to the smallest slot")
	# Elite affix ward: self, S x 1.5
	var g := _engine("elite", 8, {"affix": "ward"}, 9)
	var el: Unit = g.enemies[0]
	el.shield = 0
	g.turn = 2
	CombatTraits.enemy_phase_start(g)
	_check(el.shield == 7, "Elite ward: floor(5 x 1.5)=7, got %d" % el.shield)


func _mend() -> void:
	var c := _arena(3, 8)
	var w: Unit = c.enemies[0]
	w.custom_state["m_trait"] = "mend"
	# fight cap is 25% of the source's max HP since lane E (was 50% of 30): 60 keeps the cap at 15
	w.max_hp = 60
	w.hp = 60
	c.enemies[1].hp = 5
	c.enemies[2].hp = 10
	_ev.clear()
	CombatTraits.enemy_phase_start(c)
	_check(c.enemies[1].hp == 9, "lowest ratio healed 20%% of 20 = 4, got %d" % c.enemies[1].hp)
	c.enemies[1].status["weaken"] = 1
	CombatTraits.enemy_phase_start(c)
	_check(c.enemies[1].hp == 9, "debuffed target is not mended")
	c.enemies[1].status.clear()
	c.enemies[1].status["poison"] = 2
	CombatTraits.enemy_phase_start(c)
	_check(c.enemies[1].hp == 9, "poisoned target is not mended")
	c.enemies[1].status.clear()
	# hp cap 6 and fight cap 50% of the source's max HP (15)
	c.enemies[1].max_hp = 100
	c.enemies[1].hp = 1
	CombatTraits.enemy_phase_start(c)
	_check(c.enemies[1].hp == 7, "single mend capped at 6")
	CombatTraits.enemy_phase_start(c)
	CombatTraits.enemy_phase_start(c)
	var healed_total := int(w.custom_state.get("mend_done", 0))
	_check(healed_total <= 15, "fight cap: %d <= 15" % healed_total)
	c.enemies[1].hp = 1
	var before: int = c.enemies[1].hp
	CombatTraits.enemy_phase_start(c)
	_check(c.enemies[1].hp == before and healed_total == 15, "no mend after the fight cap (done %d)" % healed_total)
	_check(_ev.size() >= 3 and _ev[0][0] == "mend", "mend events")
	var d := Unit.from_data(w.to_data())
	_check(int(d.custom_state.get("mend_done", 0)) == 15, "mend_done survives a snapshot")


func _spite() -> void:
	var c := _arena(2, 8)
	var e: Unit = c.enemies[0]
	e.custom_state["spite"] = true
	e.status["thorns"] = 4
	e.max_hp = 200
	e.hp = 200
	var a: Unit = c.party[1]
	a.shield = 0
	var hp0 := a.hp
	_ev.clear()
	var face := {"type": "dmg", "value": 3, "keywords": [], "name": "x", "part": "horn", "rarity": 0}
	for i in 3:
		a.die = [face.duplicate(true)]
		a.set_roll(0, false)
		c.use_die(a.uid, e.uid) if i == 0 else _fire(c, a, e)
	_check(a.hp == hp0 - 3 * 0 - CombatTraits.spite_damage(8), "3rd hit: Axie takes %d (old thorns ignored), lost %d" % [CombatTraits.spite_damage(8), hp0 - a.hp])
	_check(CombatTraits.spite_damage(8) == 3 and CombatTraits.spite_damage(7) == 2, "pw 8+ = 3")
	_check(_ev.size() == 1 and _ev[0][0] == "spite" and _ev[0][4] == 3, "spite event")
	_check(c.spite_hits.get(e.uid, 0) == 3, "counter per enemy")
	_fire(c, a, e)
	_check(_ev.size() == 2, "4th hit also reflects")
	# other enemy not counted; aoe / pierce not counted
	var o: Unit = c.enemies[1]
	_check(c.spite_hits.get(o.uid, 0) == 0, "other enemy untouched")
	var snap := CombatEngine.new()
	snap.from_data(c.to_data())
	_check(int(snap.spite_hits.get(e.uid, 0)) == 4, "counter in snapshot")
	# end_turn() re-rolls every die: give the 1-face test die six faces so a different RNG stream (pool changes) cannot index past it
	a.die = [face.duplicate(true), face.duplicate(true), face.duplicate(true), face.duplicate(true), face.duplicate(true), face.duplicate(true)]
	c.end_turn()
	_check(c.spite_hits.is_empty(), "reset at the player turn start")


func _fire(c: CombatEngine, a: Unit, e: Unit) -> void:
	var f := {"type": "dmg", "value": 3, "keywords": [], "name": "x", "part": "horn", "rarity": 0}
	a.die = [f]
	a.rolled = [{"face_index": 0, "crit_now": false, "used": false}]
	c._exec_face(a, e.uid)


func _assign() -> void:
	_check(String(ContentDB.enemies["jellyfin"]["trait"]) == "ward" and String(ContentDB.enemies["totem"]["trait"]) == "ward", "ward monsters")
	_check(String(ContentDB.enemies["warden"]["trait"]) == "mend", "warden mends only")
	var most := 0
	var early_most := 0
	var any_trait := false
	for sd in range(1, 80):
		var c := _engine("battle", 11, {}, sd)
		var n := 0
		for e in c.enemies:
			if e.custom_state.has("m_trait"):
				n += 1
		most = maxi(most, n)
		any_trait = any_trait or n > 0
		var c2 := _engine("battle", 11, {"before_first_elite": true}, sd)
		var n2 := 0
		for e in c2.enemies:
			if e.custom_state.has("m_trait"):
				n2 += 1
		early_most = maxi(early_most, n2)
	_check(any_trait and most <= 2, "normal fight: <= 2 trait bearers (max %d)" % most)
	_check(early_most <= 1, "before the first Elite: <= 1 (max %d)" % early_most)
	# Elite: companions carry none; Bulwark keeps plating without an A affix
	for sd in range(1, 60):
		var c3 := _engine("elite", 8, {}, sd)
		for i in range(1, c3.enemies.size()):
			_check(not c3.enemies[i].custom_state.has("m_trait") and c3.enemies[i].plating == 0, "elite companion has no trait")
		if c3.enemies[0].key == "e_bulwark":
			_check(c3.enemies[0].plating >= 2, "bulwark keeps role plating with no affix")
			var c4 := _engine("elite", 8, {"affix": "ward"}, sd)
			_check(c4.enemies[0].plating == 0 and not c4.enemies[0].custom_state.has("m_trait"), "group A affix replaces the role trait")
			var c5 := _engine("elite", 8, {"affix": "iron"}, sd)
			_check(c5.enemies[0].plating == CombatTraits.plating_for_pw(8) + 1, "Giap Sat = P+1 (not stacked on role P)")
			break


func _affix_schema() -> void:
	var t := ContentDB.elite_affixes
	for id in ["iron", "ward", "spite", "mend", "charge"]:
		_check(t.has(id) and String(t[id]["group"]) == "A", "affix %s in group A" % id)
	for id in ["frenzy", "swarm", "rush"]:
		_check(String(t[id]["group"]) == "B", "%s is group B" % id)
	_check(bool(t["thorns"].get("retired", false)), "old thorns retired")
	var c := _engine("elite", 8, {"affix": "spite"})
	_check(bool(c.enemies[0].custom_state.get("spite", false)), "spite flag on the elite")
	var f := _engine("elite", 8, {"first_run_elite": true, "affix": "swarm", "affix2": "rush"})
	_check(f.affix == "iron" and f.affix2 == "" and f.enemies[0].plating >= 3, "first run: Giap Sat only")
	var g := _engine("elite", 8, {"first_run_elite": true, "team_can_break": false})
	_check(g.affix == "ward", "first run, team cannot break: Khien Hoi")
	var two := _engine("elite", 8, {"affix": "iron", "affix2": "frenzy"})
	_check(two.to_data()["affix2"] == "frenzy" and float(two.affix_dealt_mult(two.enemies[0])) >= 1.0, "two affixes merge")


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)
