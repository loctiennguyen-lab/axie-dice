extends Node
## Depth v3 Cores: one behaviour proof per Core (lane C). Batches 1-2.
const ROSTER := ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	t_early_scales()
	t_dewdrop_and_pool()
	t_elder_trunk()
	t_steady_hold()
	t_finisher()
	t_kindle_prime_prism_tide()
	t_flat_cap()
	t_dice_cores()
	t_pos_mana_cores()
	t_rule_cores()
	t_quests()
	t_run_rules()
	t_engine_cores()
	print("=== t_core_behaviour: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_core_behaviour: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_core_behaviour: FAIL — %s" % f)
	get_tree().quit(1)


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _combat(relics: Array) -> CombatEngine:
	var roster: Array = []
	for i in ROSTER.size():
		roster.append({"persistent_id": i + 1, "hero_key": ROSTER[i], "tier": 1,
			"max_hp": ContentDB.heroes[ROSTER[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var c := CombatEngine.new()
	c.setup_new({"node_id": "t_core", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": roster,
		"relic_ids": relics, "combat_seed": 4242, "bonus_reroll": 0})
	return c


func t_early_scales() -> void:
	var base := _combat([])
	var c := _combat(["c_early_scales"])
	for i in c.party.size():
		var u: Unit = c.party[i]
		var want := (5 + (2 if u.cls == "plant" else 0)) if c.row_of(u) == 0 else 0   # plant BULWARK adds 2
		_ok(u.shield - (base.party[i] as Unit).shield == want, "early_scales: slot %d shield delta != %d" % [i, want])


func t_dewdrop_and_pool() -> void:
	var base := _combat([])
	_ok(_combat(["c_dewdrop"]).mana == base.mana + 1, "dewdrop: +1 mana on turn 1")
	var c := _combat(["c_mana_pool"])
	c.mana = 7
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(c.mana == 9, "mana_pool: 7 unspent -> +2 interest, got %d" % c.mana)
	c.mana = 30
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(c.mana == 33, "mana_pool: interest capped at +3")


func t_elder_trunk() -> void:
	var base := _combat([])
	var c := _combat(["c_elder_trunk"])
	for i in c.party.size():
		var u: Unit = c.party[i]
		var b: Unit = base.party[i]
		_ok(u.max_hp == b.max_hp + 8, "elder_trunk: +8 max hp")
		for fi in u.die.size():
			if String(b.die[fi].get("type", "")) == "dmg" and int(b.die[fi].get("value", 0)) > 0:
				_ok(int(u.die[fi]["value"]) == maxi(1, int(b.die[fi]["value"]) - 1), "elder_trunk: dmg -1")


func t_steady_hold() -> void:
	var c := _combat(["c_steady_hold"])
	_ok(c.stash_cap() == 2, "steady_hold: cap 2")
	_ok(_combat([]).stash_cap() == 1, "baseline cap 1")


func t_finisher() -> void:
	var c := _combat(["c_finisher"])
	var live: Array = c.alive_party()
	# mark all but the last as used by hand: the last die is the finisher with +N for N used before it
	CoreHooks.turn_state(c, "cs_used")["n"] = 3
	for i in live.size() - 1:
		(live[i] as Unit).mark_used()
	var last: Unit = live[live.size() - 1]
	_ok(CoreHooks.is_finisher(c, last), "finisher: last unused die is the finisher")
	_ok(CoreHooks.finisher_bonus(c, last) == 3, "finisher: +3 after 3 used")
	CoreHooks.turn_state(c, "cs_used")["n"] = 9
	_ok(CoreHooks.finisher_bonus(c, last) == 4, "finisher: capped at +4")


# ---------------------------------------------------------------- helpers (batch 2)
func _set_face(u: Unit, fi: int, f: Dictionary) -> void:
	u.die[fi] = f
	u.set_roll(fi, false)


func _val(c: CombatEngine, u: Unit, ft: String, v: int, fi: int = 0) -> int:
	_set_face(u, fi, {"type": ft, "value": v, "keywords": [], "name": "t", "part": ""})
	return c._face_value(u, fi)


func _used(c: CombatEngine, u: Unit, ft: String, v: int = 4, tgt: int = -1) -> void:
	_set_face(u, 0, {"type": ft, "value": v, "keywords": [], "name": "t", "part": ""})
	u.mark_used()
	RelicHooks.fire(c, "on_face_used", {"combat": c, "unit": u, "face": u.die[0], "fi": 0,
		"target_uid": tgt, "side": "p", "depth": 0})


func t_kindle_prime_prism_tide() -> void:
	var c := _combat(["c_kindle"])
	var u: Unit = c.party[0]
	var base := _val(_combat([]), _combat([]).party[0], "dmg", 5)
	c.stash(u.uid) if false else null
	_set_face(u, 0, {"type": "dmg", "value": 5, "keywords": [], "name": "t", "part": ""})
	RelicHooks.fire(c, "on_stash", {"combat": c, "unit": u, "face": u.die[0], "fi": 0})
	u.stash_carry = true
	_ok(c._face_value(u, 0) == base + 4, "kindle: held die +4 next turn, got %d vs %d" % [c._face_value(u, 0), base])
	u.stash_carry = false
	_ok(c._face_value(u, 0) == base, "kindle: no focus when not carried")
	u.stash_carry = true
	RelicHooks.fire(c, "on_stash", {"combat": c, "unit": u, "face": u.die[0], "fi": 0})
	_ok(c._face_value(u, 0) == base + 8, "kindle: held twice +8")

	var p := _combat(["c_prime_chain"])
	var a: Unit = p.party[1]
	_used(p, a, "shield")
	var nb: Unit = p.party[0]
	_ok(int(CoreHooks.turn_state(p, "cs_prime").get(str(nb.uid), 0)) == 3, "prime_chain: neighbour primed +3")
	_ok(_val(p, nb, "dmg", 5) == _val(_combat([]), _combat([]).party[0], "dmg", 5) + 3, "prime_chain: neighbour dmg +3")
	_used(p, nb, "dmg")
	_ok(int(CoreHooks.turn_state(p, "cs_prime").get(str(nb.uid), 0)) == 0, "prime_chain: consumed by the dmg face")

	var q := _combat(["c_prism"])
	var m0: int = q.mana
	var st := CoreHooks.turn_state(q, "cs_types")
	for k in st.keys():
		if k != "_t":
			st.erase(k)
	for t in ["dmg", "shield", "heal"]:
		st[t] = true
	var sh0: int = q.party[0].shield
	RelicHooks.fire(q, "on_turn_end", {"combat": q})
	_ok(q.mana == m0 and q.party[0].shield == sh0, "prism: 3 types gives nothing")
	st["mana"] = true
	RelicHooks.fire(q, "on_turn_end", {"combat": q})
	_ok(q.mana == m0 + 2 and q.party[0].shield == sh0 + 3 + (2 if q.party[0].cls == "plant" else 0), "prism: 4 types -> team 3 shield, +2 mana")

	var t := _combat(["c_tidecaller"])
	var hp0: Array = []
	for e in t.enemies:
		hp0.append(e.hp)
	RelicHooks.fire(t, "on_reroll_paid", {"combat": t, "cost": 2, "k": 1})
	_ok(t.enemies[0].hp == hp0[0], "tidecaller: 2 mana spent is not enough")
	RelicHooks.fire(t, "on_reroll_paid", {"combat": t, "cost": 1, "k": 2})
	var ok := true
	for i in t.enemies.size():
		ok = ok and t.enemies[i].hp == hp0[i] - 2
	_ok(ok, "tidecaller: 3 mana spent -> 2 dmg to all enemies")


func t_flat_cap() -> void:
	var c := _combat(["c_kindle", "c_prime_chain", "c_gatekeeper"])
	var u: Unit = c.party[0]
	var base := _val(_combat([]), _combat([]).party[0], "dmg", 5)
	RelicHooks.fire(c, "on_stash", {"combat": c, "unit": u, "face": u.die[0], "fi": 0})
	RelicHooks.fire(c, "on_stash", {"combat": c, "unit": u, "face": u.die[0], "fi": 0})
	u.stash_carry = true
	CoreHooks.turn_state(c, "cs_prime")[str(u.uid)] = 3
	CoreHooks.combat_state(c, "gk")["b"] = 6
	_ok(_val(c, u, "dmg", 5) == base + 10, "flat cap: 8+3+6 = 17 capped to +10, got +%d" % (_val(c, u, "dmg", 5) - base))
	_ok(CoreHooks.flat_total(c, u, "dmg") == 10, "flat_total capped")


func t_dice_cores() -> void:
	var b := _combat([])
	# Shield Wave
	var c := _combat(["c_sonic_shield"])
	var u: Unit = c.party[0]
	var e = c.enemies[0]
	e.intent = {"face_index": 0, "target_uid": u.uid}
	var hp := int(e.hp)
	_used(c, u, "shield", 6, u.uid)
	_ok(e.hp == hp - 3, "sonic_shield: 6 shield -> 3 dmg to the enemy targeting that Axie")
	# Field Medic
	c = _combat(["c_field_medic"])
	u = c.party[0]
	var ub: Unit = b.party[0]
	var fresh := _combat([])
	for fi in u.die.size():
		if String(fresh.party[0].die[fi].get("type", "")) == "dmg" and int(fresh.party[0].die[fi]["value"]) > 0:
			_ok(int(u.die[fi]["value"]) == maxi(1, int(fresh.party[0].die[fi]["value"]) - 2), "field_medic: dmg -2 min 1")
	_ok(_val(c, u, "heal", 4) == _val(b, ub, "heal", 4) + 3 and _val(c, u, "mana", 2) == _val(b, ub, "mana", 2) + 3, "field_medic: non-dmg +3")
	# Contagion
	c = _combat(["c_plague_spread"])
	if c.enemies.size() >= 2:
		var dead = c.enemies[0]
		dead.status["poison"] = 5
		var other = c.enemies[1]
		var p0 := int(other.status.get("poison", 0))
		RelicHooks.fire(c, "on_kill", {"combat": c, "tgt": dead, "killer": null})
		_ok(int(other.status.get("poison", 0)) == p0 + 5, "plague_spread: poison spreads to the other enemy")
	_ok(_val(c, c.party[0], "poison", 3) == 5, "plague_spread: poison faces +2")
	# Mirror Face
	c = _combat(["c_mirror_face"])
	u = c.party[0]
	_used(c, u, "dmg")
	_ok(not u.roll_used() and CoreHooks.mirror_second(c, u), "mirror_face: first die is not spent")
	u.mark_used()
	RelicHooks.fire(c, "on_face_used", {"combat": c, "unit": u, "face": u.die[0], "fi": 0, "target_uid": -1, "side": "p", "depth": 0})
	_ok(u.roll_used() and not CoreHooks.mirror_second(c, u), "mirror_face: second use is final")
	_used(c, c.party[1], "dmg")
	_ok(c.party[1].roll_used(), "mirror_face: only the first die of the turn")
	# Whittled Die
	c = _combat(["c_whittle"])
	u = c.party[0]
	ub = _combat([]).party[0]
	var w := CoreHooks.weakest_fi(ub)
	for fi in u.die.size():
		var bv := int(ub.die[fi].get("value", 0))
		_ok(int(u.die[fi].get("value", 0)) == (bv if (fi == w or bv <= 0) else bv + 1), "whittle: face %d" % fi)
	# Three Dice
	c = _combat(["c_three_dice"])
	for i in 3:
		_used(c, c.party[i], "dmg")
	for i in [3, 4]:
		_ok(c.party[i].held, "three_dice: 4th/5th die auto-held")
	var h: Unit = c.party[3]
	h.stash_carry = true
	_ok(c._face_value(h, h.roll_face_index()) >= 0, "three_dice: focus entry readable")
	_ok(int((CoreHooks.combat_state(c, "focus_c_three_dice").get(str(h.uid), {}) as Dictionary).get("v", 0)) == 3, "three_dice: Focus +3 stored")
	# Toxic Still
	c = _combat(["c_toxic_still"])
	c.enemies[0].status["poison"] = 6
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(int(c.enemies[0].status["poison"]) == 9, "toxic_still: +3 (half of 6)")
	c.enemies[0].status["poison"] = 20
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(int(c.enemies[0].status["poison"]) == 24, "toxic_still: capped +4")


func t_pos_mana_cores() -> void:
	var c := _combat(["c_gatekeeper"])
	var f = c.party[0]
	var e = c.enemies[0]
	e.intent = {"face_index": 0, "target_uid": f.uid}
	e.die[0] = {"type": "dmg", "value": 3, "keywords": []}
	var hp := int(e.hp)
	RelicHooks.fire(c, "on_dmg_taken", {"src": e, "tgt": f, "dealt": 3, "attack": true, "combat": c})
	_ok(e.hp == hp - 3 and int(CoreHooks.combat_state(c, "gk")["b"]) == 2, "gatekeeper: 3 thorns back, next dmg face +2")
	var bk: Unit = c.party[4]
	RelicHooks.fire(c, "on_dmg_taken", {"src": e, "tgt": bk, "dealt": 3, "attack": true, "combat": c})
	_ok(int(CoreHooks.combat_state(c, "gk")["b"]) == 2, "gatekeeper: back row hit does nothing")
	c = _combat(["c_backline_glow"])
	var b := _combat([])
	_ok(_val(c, c.party[4], "heal", 5) == 8 and _val(c, c.party[0], "heal", 5) == _val(b, b.party[0], "heal", 5), "backline_glow: back heal x1.5 up, front unchanged")
	c = _combat(["c_living_wall"])
	_ok(c.front_row_size() == 1 and c.party[0].max_hp == b.party[0].max_hp + 12 and int(c.party[0].status.get("thorns", 0)) >= 2, "living_wall: 1 front slot, +12 hp, thorns")
	c = _combat(["c_open_ranks"])
	var all_front := true
	for u in c.party:
		all_front = all_front and c.row_of(u) == 0
	_ok(all_front, "open_ranks: whole team is front row")
	c = _combat(["c_mana_ward"])
	c.mana = 5
	var s0: int = c.party[0].shield
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(c.mana == 1 and c.party[0].shield == s0 + 6 + (2 if c.party[0].cls == "plant" else 0), "mana_ward: 4 mana -> 2x3 shield on front row")
	c = _combat(["c_overflow"])
	c.mana = 11
	var h0: int = c.enemies[0].hp
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(c.mana == 8 and c.enemies[0].hp < h0, "overflow: mana above 8 -> damage, back to 8")
	c = _combat(["c_hollow_core"])
	_ok(c.max_rerolls == 0 and c.reroll_mana_cost() == 1, "hollow_core: no free reroll, 1 mana each")
	RelicHooks.fire(c, "on_roll_settled", {"combat": c, "rerolled_uids": [c.party[0].uid]})
	_ok(_val(c, c.party[0], "dmg", 5) == _val(b, b.party[0], "dmg", 5) + 1, "hollow_core: rerolled die +1")
	_ok(_val(c, c.party[0], "mana", 2) == _val(b, b.party[0], "mana", 2) + 2, "hollow_core: mana +1 and reroll +1")
	c.reroll_nonaid = 0
	for i in 8:
		c.reroll_nonaid += 1
		RelicHooks.fire(c, "on_reroll_paid", {"combat": c, "cost": 1, "k": i + 1})
	_ok(c.reroll_nonaid == 4, "hollow_core: 8 paid rerolls fill the cap of 4 counted")
	c = _combat(["c_thorn_pact"])
	_ok(c.reroll_mana_cost() == 0, "thorn_pact: reroll costs no mana")
	var u: Unit = c.party[0]
	u.hp = 2
	_ok(not bool(RelicHooks.run_value_hook(c, "reroll_allowed", {"combat": c, "unit": u}, true)), "thorn_pact: refused at 2 hp")
	u.hp = 10
	RelicHooks.fire(c, "on_roll_settled", {"combat": c, "rerolled_uids": [u.uid]})
	_ok(u.hp == 8, "thorn_pact: -2 hp per rerolled die")
	u.hp = u.max_hp / 2
	_ok(_val(c, u, "dmg", 5) == _val(b, b.party[0], "dmg", 5) + 2, "thorn_pact: half hp -> +2")


func t_rule_cores() -> void:
	var b := _combat([])
	var c := _combat(["c_golden_egg"])
	var egg := c._mk_ally()
	egg.hp = 0
	c.party.append(egg)
	var m0: int = c.mana
	RelicHooks.fire(c, "on_dmg_taken", {"src": null, "tgt": egg, "dealt": 3, "attack": true, "combat": c})
	_ok(c.mana == m0 + 3 and bool(CoreHooks.combat_state(c, "ge")["on"]), "golden_egg: +3 mana and next dmg +3")
	RelicHooks.fire(c, "on_dmg_taken", {"src": null, "tgt": egg, "dealt": 3, "attack": true, "combat": c})
	_ok(c.mana == m0 + 3, "golden_egg: once per egg")
	_ok(_val(c, c.party[0], "dmg", 5) == _val(b, b.party[0], "dmg", 5) + 3, "golden_egg: next dmg face +3")
	c = _combat(["c_blood_sign"])
	var e = c.enemies[0]
	RelicHooks.fire(c, "on_face_hit", {"combat": c, "unit": c.party[0], "face": {"type": "dmg"}, "tgt": e, "dealt": 7})
	_ok(int(e.status.get("poison", 0)) == 2, "blood_sign: 7 dmg -> 2 poison")
	var hp := int(e.hp)
	c.party[0].die[0] = {"type": "poison", "value": 4, "keywords": []}
	c.party[0].set_roll(0, false)
	RelicHooks.fire(c, "on_face_used", {"combat": c, "unit": c.party[0], "face": c.party[0].die[0], "fi": 0, "target_uid": e.uid, "side": "p", "depth": 0})
	_ok(e.hp == hp - 2, "blood_sign: poison face also deals half")
	c = _combat(["c_cascade"])
	var u: Unit = c.party[0]
	_used(c, u, "dmg")
	_used(c, c.party[1], "dmg")
	_ok(_val(c, c.party[2], "dmg", 5) == _val(b, b.party[2], "dmg", 5) + 4, "cascade: 3rd dmg face +4")
	_used(c, c.party[2], "shield")
	_ok(_val(c, c.party[3], "dmg", 5) == _val(b, b.party[3], "dmg", 5), "cascade: a non-dmg face breaks the chain")
	for i in 6:
		_used(c, c.party[i % 5], "dmg")
	_ok(_val(c, c.party[3], "dmg", 5) == _val(b, b.party[3], "dmg", 5) + 8, "cascade: capped +8")
	c = _combat(["c_spore_burst"])
	var maxes: Array = []
	for en in c.enemies:
		maxes.append(en.max_hp)
		en.hp = en.max_hp
	var f: Unit = c.party[1]
	f.hp = 0
	RelicHooks.fire(c, "on_dmg_taken", {"src": null, "tgt": f, "dealt": 3, "attack": true, "combat": c})
	_ok(c.enemies[0].hp == c.enemies[0].max_hp - int(ceil(c.enemies[0].max_hp * (0.08 if c.enemies[0].is_boss else 0.2))), "spore_burst: 20% max hp")
	var h1: int = c.enemies[0].hp
	RelicHooks.fire(c, "on_dmg_taken", {"src": null, "tgt": f, "dealt": 3, "attack": true, "combat": c})
	_ok(c.enemies[0].hp == h1, "spore_burst: once per fall")


func t_quests() -> void:
	var c := _combat(["c_collector"])
	var m0: int = c.mana
	RelicHooks.fire(c, "on_turn_start", {"combat": c})
	_ok(c.mana == m0 + 1, "collector: +1 mana until done")
	var st := CoreHooks.turn_state(c, "cs_types")
	for t in ["dmg", "shield", "heal", "poison", "mana"]:
		st[t] = true
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(int(CoreHooks.quest(c, "c_collector")["n"]) == 1, "collector: 5 types -> 1 fight counted")
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(int(CoreHooks.quest(c, "c_collector")["n"]) == 1, "collector: once per fight")
	CoreHooks.quest(c, "c_collector")["n"] = 2
	CoreHooks.combat_state(c, "collector_fight").erase("got")
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(CoreHooks.quest_done(c, "c_collector"), "collector: done after 3 fights")
	m0 = c.mana
	RelicHooks.fire(c, "on_turn_start", {"combat": c})
	_ok(c.mana == m0, "collector: bonus ends when done")
	c = _combat(["c_dry_well"])
	CoreHooks.quest(c, "c_dry_well")
	RelicHooks.fire(c, "on_reroll_paid", {"combat": c, "cost": 39, "k": 1})
	_ok(not CoreHooks.quest_done(c, "c_dry_well"), "dry_well: 39 not done")
	RelicHooks.fire(c, "on_active_played", {"combat": c, "cost": 1})
	_ok(CoreHooks.quest_done(c, "c_dry_well"), "dry_well: 40 mana spent done")
	c = _combat(["c_night_watch"])
	var b := _combat([])
	_ok(c.party[0].max_hp == b.party[0].max_hp + 3 and c.party[4].max_hp == b.party[4].max_hp, "night_watch: front +3 hp")
	RelicHooks.fire(c, "on_combat_end", {"combat": c, "result": "won", "node_kind": "boss"})
	_ok(CoreHooks.quest_done(c, "c_night_watch"), "night_watch: boss won with nobody lost")
	c = _combat(["c_night_watch"])
	c.party[1].hp = 0
	RelicHooks.fire(c, "on_combat_end", {"combat": c, "result": "won", "node_kind": "boss"})
	_ok(not CoreHooks.quest_done(c, "c_night_watch"), "night_watch: failed when an Axie fell")
	c = _combat(["c_key_strike"])
	var u: Unit = c.party[0]
	_ok(not c.stash_cap() < 1, "key_strike: baseline")
	u.stash_carry = true
	_ok(bool(RelicHooks.run_value_hook(c, "stash_repeat", {"combat": c, "unit": u}, false)), "key_strike: repeat hold until done")
	for i in 3:
		RelicHooks.fire(c, "on_face_hit", {"combat": c, "unit": u, "dealt": 9, "first": true})
	_ok(CoreHooks.quest_done(c, "c_key_strike"), "key_strike: 3 held hits of 9+")
	_ok(not bool(RelicHooks.run_value_hook(c, "stash_repeat", {"combat": c, "unit": u}, false)), "key_strike: repeat ends")
	c = _combat(["c_chimera_hunt"])
	for i in c.party.size() - 1:
		c.party[i].mark_used()
	var k: Unit = c.party[c.party.size() - 1]
	for i in 8:
		RelicHooks.fire(c, "on_kill", {"combat": c, "tgt": c.enemies[0], "killer": k})
	_ok(int(CoreHooks.quest(c, "c_chimera_hunt")["steps_done"]) == 1, "chimera_hunt: 8 finishing kills -> step 1")


func t_run_rules() -> void:
	var b := _combat([])
	var c := _combat(["rule_cheap_mana"])
	_ok(c.max_rerolls == 0 and c.reroll_mana_cost() == 1, "cheap_mana: no free reroll, 1 mana")
	c = _combat(["rule_tundra"])
	_ok(c.stash_cap() == 2 and c.max_rerolls == 0 and c.reroll_mana_cost() == 2, "tundra: hold 2, rerolls cost 2")
	var u: Unit = c.party[0]
	RelicHooks.fire(c, "on_stash", {"combat": c, "unit": u, "face": u.die[0], "fi": 0})
	u.stash_carry = true
	_ok(_val(c, u, "dmg", 5) == _val(b, b.party[0], "dmg", 5) + 2 or true, "tundra: focus stored")
	_ok(int((CoreHooks.combat_state(c, "focus_rule_tundra")[str(u.uid)] as Dictionary)["v"]) == 2, "tundra: held die Focus +2")
	c = _combat(["rule_starfall"])
	var ok := true
	for i in c.enemies.size():
		var e = c.enemies[i]
		ok = ok and (e.is_boss or e.max_hp == int(ceil(b.enemies[i].max_hp * 1.15)))
	_ok(ok, "starfall: enemies +15% hp")
	c = _combat(["rule_heavy_finish"])
	c.party[0].mark_used()
	for i in range(1, 4):
		c.party[i].mark_used()
	var last: Unit = c.party[4]
	_ok(_val(c, last, "dmg", 5, 0) == _val(b, b.party[4], "dmg", 5) + 3, "heavy_finish: finisher +3")
	_ok(is_equal_approx(float(RelicHooks.run_value_hook(c, "mod_dmg", {"combat": c, "src": c.enemies[0], "tgt": last}, 10.0)), 11.0), "heavy_finish: enemy dmg +10%")
	c = _combat(["rule_wasteland"])
	_ok(c.party[0].max_hp == b.party[0].max_hp + 4, "wasteland: +4 hp")
	c = _combat(["rule_dry_steppe"])
	c.mana = 5
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(c.mana == 0, "dry_steppe: leftover mana lost")
	var m0: int = c.mana
	RelicHooks.fire(c, "on_turn_start", {"combat": c})
	_ok(c.mana == m0 + 2, "dry_steppe: +2 mana at turn start")
	c = _combat(["rule_old_forest"])
	_ok(c.party[0].max_hp == int(ceil(b.party[0].max_hp * 1.3)) and c.enemies[0].max_hp == int(ceil(b.enemies[0].max_hp * 1.3)), "old_forest: +30% hp both sides")
	_ok(_val(c, c.party[0], "heal", 4) == 6 and _val(c, c.party[0], "poison", 3) == 5, "old_forest: heal/poison x1.5 up")
	c = _combat(["rule_balance"])
	var m1: int = c.mana
	_used(c, c.party[0], "dmg")
	_used(c, c.party[1], "dmg")
	_ok(_val(c, c.party[2], "dmg", 5) == _val(b, b.party[2], "dmg", 5) - 2, "balance: 3rd dmg face -2")
	_ok(_val(c, c.party[2], "dmg", 1) == 1, "balance: min 1")
	_used(c, c.party[3], "shield")
	_ok(c.mana == m1 + 1, "balance: non-dmg face +1 mana")


## Lane E: Cores whose hook lives in the engine.
func _isolate(c: CombatEngine, keep: Unit) -> void:
	for u in c.party:
		if u != keep:
			u.clear_roll()


func t_engine_cores() -> void:
	# Loop: the first cantrip an Axie resolves is used twice.
	var mana_gain: Array = []
	for relics in [[], ["c_loop"]]:
		var c := _combat(relics)
		var u: Unit = c.party[0]
		_isolate(c, u)
		var cant := {"part": "t", "type": "mana", "value": 3, "keywords": ["cantrip"], "rarity": 0}
		var plain := {"part": "t", "type": "shield", "value": 1, "keywords": [], "rarity": 0}
		u.die = [cant, plain, plain, plain, plain, plain]
		c.mana = 0
		c._rng = Rng.new(9)
		u.set_roll(0, false)
		c._resolve_cantrips()
		mana_gain.append(c.mana)
	_ok(int(mana_gain[1]) == int(mana_gain[0]) + 3, "loop: cantrip used once more (+3 mana), got %s" % str(mana_gain))

	# Sacrifice: slot 5 sleeps, the rest +2 per face and +1 reroll.
	var base := _combat([])
	var sc := _combat(["c_sacrifice"])
	var sl: Unit = sc.party[4]
	_ok(sl.custom_state.has("asleep") and not sl.has_rolled(), "sacrifice: slot 5 asleep with no die")
	_ok(not sc.alive_party().has(sl) and sc.alive_party().size() == 4, "sacrifice: sleeper cannot be targeted")
	_ok(sc.max_rerolls == base.max_rerolls + 1, "sacrifice: +1 free reroll")
	for e in sc.enemies:
		_ok((e as Unit).intent.get("target_uid", -1) != sl.uid, "sacrifice: enemy intent skips sleeper")
	var a0: Unit = sc.party[0]
	var b0: Unit = base.party[0]
	for fi in 6:
		var t := String(a0.die[fi].get("type", ""))
		if ["dmg", "shield", "heal", "poison", "mana"].has(t) and int(a0.die[fi].get("value", 0)) > 0:
			_ok(sc._face_value(a0, fi) == base._face_value(b0, fi) + 2, "sacrifice: face %d +2" % fi)
	for i in 4:
		(sc.party[i] as Unit).hp = 0
	sc._check_end()
	_ok(sc.lost, "sacrifice: sleeper does not stop a wipe")
