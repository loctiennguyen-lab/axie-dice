extends Node
## Depth v3 6.7 M5 Charged Strike: elite affix "charge" + boss tell (design/proposals/depth-v3-design.md 6.7 M5).

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
var _ev: Array = []
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	EventBus.charge_start.connect(func(u, t): _ev.append(["start", u, t]))
	EventBus.charge_hit.connect(func(u, t, v): _ev.append(["hit", u, t, v]))
	EventBus.charge_break.connect(func(u): _ev.append(["break", u]))
	_cycle()
	_interrupt()
	_damage_does_not_break()
	_retarget()
	_boss()
	print("=== t_charge: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("t_charge: FAIL - %s" % f)
	if _failures.is_empty():
		print("t_charge: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


func _roster() -> Array:
	var roster: Array = []
	for i in TEAM.size():
		roster.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return roster


func _engine(kind: String, extra: Dictionary = {}) -> CombatEngine:
	var c := CombatEngine.new()
	var s := {"node_id": "ch", "kind": kind, "pw": 8, "ascension": 0, "roster_snapshot": _roster(),
		"relic_ids": [], "combat_seed": 21}
	s.merge(extra, true)
	c.setup_new(s)
	return c


## Party full HP, a fat elite that deals measurable damage, and no side effects from other mechanics.
func _prep(c: CombatEngine) -> Unit:
	for p in c.party:
		(p as Unit).hp = 99
		(p as Unit).max_hp = 99
	while c.enemies.size() > 1:
		c.enemies.pop_back()                     # companions would hurt the party on the charge turn
	var e: Unit = c.enemies[0]
	e.hp = 500
	e.max_hp = 500
	return e


func _step(c: CombatEngine, seed_value: int) -> void:
	for p in c.party:
		(p as Unit).hp = 99
		(p as Unit).shield = 0
	_ev.clear()
	c.end_turn(seed_value)


func _cycle() -> void:
	var c := _engine("elite", {"affix": "charge"})
	var e := _prep(c)
	_check(CombatTraits.charge_period() == 4 and CombatTraits.is_charge_turn(3) and CombatTraits.is_strike_turn(4) and CombatTraits.is_strike_turn(8), "cycle 4: charge n%4==3, strike n%4==0")
	var charged_seen := false
	for sd in [11, 12]:
		_check(String(e.intent.get("charge", "")) == "", "turn %d: ordinary intent" % c.turn)
		_step(c, sd)
	_check(c.turn == 3, "now turn 3, is %d" % c.turn)
	_check(String(e.intent.get("charge", "")) == "start", "turn 3 intent is the charge")
	var tgt_uid := int(e.intent.get("target_uid", -1))
	var lowest: Unit = null
	for u in c.front_row_targets(c.alive_party()):
		if lowest == null or (u as Unit).hp + (u as Unit).shield < lowest.hp + lowest.shield:
			lowest = u
	_check(tgt_uid == lowest.uid and c.affix_state().get("charge_now", false), "target locked, lowest HP+shield of the allowed")
	# Make the shield decide nothing; run the charge turn: nobody gets hurt.
	var hp_before: Array = []
	for p in c.party:
		hp_before.append((p as Unit).hp)
	for p in c.party:
		(p as Unit).hp = 99
	_ev.clear()
	c.end_turn(13)
	var hurt := 0
	for p in c.party:
		hurt += 99 - (p as Unit).hp
	_check(hurt == 0, "charge turn: the elite does not attack (hurt %d)" % hurt)
	_check(c.turn == 4 and String(e.intent.get("charge", "")) == "hit", "turn 4: strike intent")
	var f: Dictionary = e.die[int(e.intent["face_index"])]
	var base := c._face_value(e, int(e.intent["face_index"]))
	var best := 0
	for ff in e.die:
		if String(ff.get("type", "")) == "dmg":
			best = maxi(best, int(ff.get("value", 0)))
	_check(String(f.get("type", "")) == "dmg" and int(f.get("value", 0)) == best, "strike uses the strongest dmg face")
	var plain := float(best) * c.enemy_dmg_factor(e) * c.affix_dealt_mult(e)
	_check(base == RulesMath.round_half_up(plain * 2.5), "x2.5: %d vs %d" % [base, RulesMath.round_half_up(plain * 2.5)])
	for p in c.party:
		(p as Unit).shield = 0
	var t: Unit = c.by_uid(int(e.intent["target_uid"]))
	var hp0 := t.hp
	_ev.clear()
	c.end_turn(14)
	var hit_ev: Array = []
	for x in _ev:
		if x[0] == "hit":
			hit_ev = x
	_check(not hit_ev.is_empty() and hit_ev[3] == base, "charge_hit event with the value")
	_check(hp0 - t.hp >= 1 or t.hp <= 0, "target took the hit")
	_check(String(e.intent.get("charge", "")) == "", "turn 5 ordinary again")
	# Shield >= strike absorbs it.
	var c2 := _engine("elite", {"affix": "charge"})
	var e2 := _prep(c2)
	for sd in [11, 12, 13]:
		_step(c2, sd)
	var t2: Unit = c2.by_uid(int(e2.intent["target_uid"]))
	t2.shield = 200
	var h := t2.hp
	c2.end_turn(14)
	_check(t2.hp == h, "shield >= strike: no HP lost")


func _interrupt() -> void:
	var c := _engine("elite", {"affix": "charge"})
	var e := _prep(c)
	for sd in [11, 12]:
		_step(c, sd)
	_check(String(e.intent.get("charge", "")) == "start", "charge up (interrupt case)")
	e.status["stun"] = 1
	_ev.clear()
	c.end_turn(13)
	var brk := false
	for x in _ev:
		brk = brk or x[0] == "break"
	_check(brk, "stun on the charge turn: charge_break")
	_check(String(e.intent.get("charge", "")) != "hit", "no strike after a break")
	# freeze on an enemy is the same as stun
	var d := _engine("elite", {"affix": "charge"})
	var f := _prep(d)
	for sd in [11, 12]:
		_step(d, sd)
	StatusEngine.add_status(d, f, ["freeze"], d.party[0])
	_ev.clear()
	d.end_turn(13)
	var brk2 := false
	for x in _ev:
		brk2 = brk2 or x[0] == "break"
	_check(brk2 and String(f.intent.get("charge", "")) != "hit", "freeze breaks it as well")


func _damage_does_not_break() -> void:
	var c := _engine("elite", {"affix": "charge"})
	var e := _prep(c)
	for sd in [11, 12]:
		_step(c, sd)
	DamagePipeline.resolve({"combat": c, "src": c.party[0], "tgt": e, "value": 50, "attack": true})
	_ev.clear()
	c.end_turn(13)
	_check(String(e.intent.get("charge", "")) == "hit", "damage never interrupts")


func _retarget() -> void:
	var c := _engine("elite", {"affix": "charge"})
	var e := _prep(c)
	for sd in [11, 12]:
		_step(c, sd)
	var first := int(e.intent["target_uid"])
	for p in c.party:
		(p as Unit).hp = 99
	c.by_uid(first).hp = 0   # dies during the charge turn
	c.end_turn(13)
	if c.won or c.lost:
		return
	var now: Unit = c.by_uid(int(e.intent.get("target_uid", -1)))
	_check(now != null and now.hp > 0 and now.uid != first, "dead target: re-picked by the same rule")


func _boss() -> void:
	var c := _engine("boss", {"boss_key": "mecha", "combat_seed": 4242})
	var b: Unit = null
	for e in c.enemies:
		if (e as Unit).is_boss:
			b = e
	b.hp = 900
	b.max_hp = 900
	# prep turn right before a strike: tell, no x2.5
	b.custom_state["turn_count"] = 2
	for p in c.party:
		(p as Unit).hp = 99
	_ev.clear()
	c.roll_all()
	_check(String(b.intent.get("charge", "")) == "tell" and _ev.size() == 1 and _ev[0][0] == "start", "boss prep: charge_start tell")
	var locked := int(b.custom_state.get("charge_target", -1))
	_check(locked > 0, "boss target locked on prep")
	b.custom_state["turn_count"] = 3
	c.roll_all()
	var fi := int(b.intent["face_index"])
	_check(CombatTraits.charge_mult(b) == 1.0, "boss never x2.5")
	_check(String(b.die[fi].get("type", "")) != "dmg" or CombatEngine._has_kw(b.die[fi], "aoe") or int(b.intent["target_uid"]) == locked, "strike hits the locked Axie")
	# stun on prep: break, strike falls back to the plain roll
	var d := _engine("boss", {"boss_key": "mecha", "combat_seed": 4242})
	var b2: Unit = null
	for e in d.enemies:
		if (e as Unit).is_boss:
			b2 = e
	b2.custom_state["turn_count"] = 2
	d.roll_all()
	b2.status["stun"] = 1
	_ev.clear()
	d.begin_end_turn(5)
	d.step_end_turn_action(d.enemies.find(b2))
	_check(_ev.size() == 1 and _ev[0][0] == "break" and bool(b2.custom_state.get("charge_broken", false)), "stun on the boss prep: charge_break")
	b2.custom_state["turn_count"] = 3
	d._apply_strike_face(b2)


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)
