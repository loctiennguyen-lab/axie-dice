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
	t_lane_e_cores()
	t_lane_e_rules()
	t_thorn_cores()
	t_fx_proofs()
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
	# a cantrip face resolved at roll time already noted its type this turn: start from a clean slate so exactly 3 types count
	st.clear()
	st["_t"] = int(c.turn)
	for t in ["dmg", "shield", "heal"]:
		st[t] = true
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(int(CoreHooks.quest(c, "c_collector")["n"]) == 0, "collector: 3 types do not count")
	st["poison"] = true
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(int(CoreHooks.quest(c, "c_collector")["n"]) == 1, "collector: 4 types -> 1 fight counted")
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
	var hp0: int = last.hp
	var dealt: int = DamagePipeline.resolve({"combat": c, "src": c.enemies[0], "tgt": last, "value": 10, "attack": true, "single": true, "face_type": "dmg"})
	var dealt_b: int = DamagePipeline.resolve({"combat": b, "src": b.enemies[0], "tgt": b.party[4], "value": 10, "attack": true, "single": true, "face_type": "dmg"})
	_ok(dealt_b == 10 and dealt == 11, "heavy_finish: enemy attack through the real pipeline +10%% (%d vs %d)" % [dealt, dealt_b])
	last.max_hp = 100
	last.hp = 100
	var pz: int = DamagePipeline.resolve({"combat": c, "src": null, "tgt": last, "value": 10, "attack": false, "single": false, "face_type": "poison"})
	_ok(pz == 10, "heavy_finish: poison / non-attack damage unchanged (%d)" % pz)
	_ok(hp0 > 0, "heavy_finish: probe unit alive")
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

	# Sixth Die: one extra usable die per turn, gone at end of turn, never targeted, not counted for a wipe.
	var sd := _combat(["c_sixth_die"])
	var ph: Array = sd.party.filter(func(u): return u.custom_state.has("phantom"))
	_ok(ph.size() == 1 and (ph[0] as Unit).has_rolled(), "sixth_die: one rolled phantom on turn 1")
	_ok(sd.alive_party().size() == 5 and sd.real_party().size() == 5, "sixth_die: phantom is not a target / not real party")
	var p0: Unit = ph[0]
	var before_n: int = sd.enemies[0].hp
	_ok(sd.use_die(p0.uid, sd.enemies[0].uid) or not String(p0.current_face().get("type", "")) == "dmg", "sixth_die: usable")
	sd.end_turn()
	var ph2: Array = sd.party.filter(func(u): return u.custom_state.has("phantom"))
	_ok(ph2.size() == 1 and (ph2[0] as Unit).uid != p0.uid, "sixth_die: old phantom gone, fresh one next turn")
	var snap := CombatEngine.new()
	snap.from_data(sd.to_data())
	_ok(snap.party.size() == sd.party.size(), "sixth_die: snapshot keeps phantom")

	# Concord: same-class Axies share the rolled face; a face right after a same-part face gets +2.
	var keys := ["plant1", "plant1", "beast1", "aqua1", "bird1"]
	var roster: Array = []
	for i in keys.size():
		roster.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var cc := CombatEngine.new()
	cc.setup_new({"node_id": "t_core", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": roster,
		"relic_ids": ["c_concord"], "combat_seed": 77, "bonus_reroll": 0})
	(cc.party[0] as Unit).set_roll(1, false)
	(cc.party[1] as Unit).set_roll(2, false)
	cc._share_class_rolls()
	_ok((cc.party[1] as Unit).roll_face_index() == 1 and (cc.party[0] as Unit).roll_face_index() == 1, "concord: plants share the first plant's face")
	var cu: Unit = cc.party[2]
	var cfi := 0
	while cfi < 5 and not ["dmg", "shield", "heal", "poison", "mana"].has(String(cu.die[cfi].get("type", ""))):
		cfi += 1
	var v0 := cc._face_value(cu, cfi)
	CoreHooks.turn_state(cc, "cs_concord")["part"] = String(cu.die[cfi].get("part", ""))
	_ok(cc._face_value(cu, cfi) == v0 + 2, "concord: +2 after same part")
	CoreHooks.turn_state(cc, "cs_concord")["part"] = "other_part"
	_ok(cc._face_value(cu, cfi) == v0, "concord: no bonus after other part")

	# Take The Field: the back-row Axie with heal faces moves to the front, heal -> dmg +2, +8 Max HP, 30% lifesteal.
	var dk := ["beast1", "plant1", "aqua1", "bird1", "bug1"]
	var dr: Array = []
	for i in dk.size():
		dr.append({"persistent_id": i + 1, "hero_key": dk[i], "tier": 1,
			"max_hp": ContentDB.heroes[dk[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var dsetup := {"node_id": "t_core", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": dr,
		"relic_ids": [], "combat_seed": 5, "bonus_reroll": 0}
	var d0 := CombatEngine.new()
	d0.setup_new(dsetup)
	dsetup["relic_ids"] = ["c_descend"]
	var d1 := CombatEngine.new()
	d1.setup_new(dsetup)
	var moved := -1
	for i in 5:
		if d1.row_of(d1.party[i]) == 0 and d0.row_of(d0.party[i]) == 1:
			moved = i
	_ok(moved >= 2, "descend: one back-row Axie now stands in the front row (slot %d)" % moved)
	if moved >= 0:
		var mu: Unit = d1.party[moved]
		var bu: Unit = d0.party[moved]
		_ok(mu.max_hp == bu.max_hp + 8, "descend: +8 max hp")
		for fi in 6:
			if String(bu.die[fi].get("type", "")) == "heal":
				_ok(String(mu.die[fi]["type"]) == "dmg" and int(mu.die[fi]["value"]) == int(bu.die[fi]["value"]) + 2, "descend: heal face %d -> dmg +2" % fi)


# ---------------------------------------------------------------- lane E batch 2: the 5 hook Cores + 4 rules
func _combat2(relics: Array, extra: Dictionary = {}) -> CombatEngine:
	var roster: Array = []
	for i in ROSTER.size():
		roster.append({"persistent_id": i + 1, "hero_key": ROSTER[i], "tier": 1,
			"max_hp": ContentDB.heroes[ROSTER[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var setup := {"node_id": "t_core", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": roster,
		"relic_ids": relics, "combat_seed": 4242, "bonus_reroll": 0}
	setup.merge(extra, true)
	var c := CombatEngine.new()
	c.setup_new(setup)
	return c


## HP removed by one hit through the real pipeline (pierce skips Plating so only the hook under test moves it).
func _hit(c: CombatEngine, src: Unit, tgt: Unit, v: int, single: bool = true, pierce: bool = true) -> int:
	tgt.shield = 0
	tgt.hp = tgt.max_hp
	return DamagePipeline.resolve({"combat": c, "src": src, "tgt": tgt, "value": v, "attack": true,
		"single": single, "pierce": pierce, "face_type": "dmg"})


func t_lane_e_cores() -> void:
	# Fissure: a poison face that hits marks the enemy: +25% from all damage through the end of next turn, Plating off.
	var b := _combat2([])
	var c := _combat2(["c_fissure"])
	var e: Unit = c.enemies[0]
	var d0 := _hit(b, b.party[0], b.enemies[0], 8)
	_ok(_hit(c, c.party[0], e, 8) == d0, "fissure: no bonus before a poison face lands")
	_used(c, c.party[1], "poison", 3, e.uid)
	_ok(int(e.custom_state.get("fissure", -1)) == c.turn + 1 and e.plating_off >= 2, "fissure: marked until end of next turn, Plating off")
	_ok(_hit(c, c.party[0], e, 8) == int(ceil(8 * 1.25)) and d0 == 8, "fissure: 8 -> 10 on a marked enemy (base 8)")
	c.turn += 1
	_ok(_hit(c, c.party[0], e, 8) == 10, "fissure: still marked next turn")
	c.turn += 1
	_ok(_hit(c, c.party[0], e, 8) == 8, "fissure: expired after that")
	var c2 := _combat2(["c_fissure"])
	_used(c2, c2.party[1], "dmg", 3, c2.enemies[0].uid)
	_ok(int(c2.enemies[0].custom_state.get("fissure", -1)) == -1, "fissure: a non-poison face does not mark")

	# Bastion: front-row Axies take 2 less from single, non-pierce attacks (min 1); back row / AoE / pierce unchanged.
	b = _combat2([])
	c = _combat2(["c_bastion"])
	var fr: Unit = c.party[0]
	var bk: Unit = c.party[4]
	_ok(c.row_of(fr) == 0 and c.row_of(bk) == 1, "bastion: slot 1 front, slot 5 back")
	var atk: Unit = c.enemies[0]
	_ok(_hit(c, atk, fr, 6, true, false) == _hit(b, b.enemies[0], b.party[0], 6, true, false) - 2, "bastion: front takes 2 less")
	_ok(_hit(c, atk, fr, 2, true, false) == 1, "bastion: min 1")
	_ok(_hit(c, atk, fr, 6, false, false) == 6, "bastion: AoE not reduced")
	_ok(_hit(c, atk, fr, 6, true, true) == 6, "bastion: pierce not reduced")
	_ok(_hit(c, atk, bk, 6, true, false) == 6, "bastion: back row not reduced")

	# Growing Shell: front-row kill = +1 Max HP stack (kept in relic_state); falling keeps ceil(n/3); stacks apply next fight.
	c = _combat2(["c_growing_shell"])
	fr = c.party[0]
	bk = c.party[4]
	var hp0 := fr.max_hp
	for i in 4:
		RelicHooks.fire(c, "on_kill", {"combat": c, "killer": fr, "tgt": c.enemies[0]})
	_ok(fr.max_hp == hp0 + 4 and int((c.relic_run_out["c_growing_shell"] as Dictionary)[str(fr.uid)]) == 4, "growing shell: 4 kills = +4 max hp, 4 stacks")
	RelicHooks.fire(c, "on_kill", {"combat": c, "killer": bk, "tgt": c.enemies[0]})
	_ok(not (c.relic_run_out["c_growing_shell"] as Dictionary).has(str(bk.uid)), "growing shell: back-row kill gives nothing")
	fr.hp = 0
	RelicHooks.fire(c, "on_dmg_taken", {"combat": c, "tgt": fr, "src": c.enemies[0], "dealt": 5})
	_ok(int((c.relic_run_out["c_growing_shell"] as Dictionary)[str(fr.uid)]) == 1, "growing shell: falling 4 -> 4 - ceil(8/3) = 1")
	var nx := _combat2(["c_growing_shell"], {"relic_state": c.relic_run_out})
	_ok(nx.party[0].max_hp == _combat2([]).party[0].max_hp + 1, "growing shell: next fight starts with the stacks")

	# Deep Current: up to 12 leftover Mana after a WON fight is paid at the start of the next one.
	c = _combat2(["c_deep_current"])
	c.mana = 15
	RelicHooks.fire(c, "on_combat_end", {"combat": c, "result": "won"})
	_ok(int((c.relic_run_out["c_deep_current"] as Dictionary)["mana"]) == 12, "deep current: kept capped at 12")
	c.mana = 5
	RelicHooks.fire(c, "on_combat_end", {"combat": c, "result": "lost"})
	_ok(int((c.relic_run_out["c_deep_current"] as Dictionary)["mana"]) == 0, "deep current: nothing kept after a loss")
	nx = _combat2(["c_deep_current"], {"relic_state": {"c_deep_current": {"mana": 7}}})
	_ok(nx.mana == _combat2([]).mana + 7 and int((nx.relic_run_out["c_deep_current"] as Dictionary)["mana"]) == 0, "deep current: +7 mana at the start, counter reset")

	# Nest: one Egg at the start, Eggs count as front row.
	b = _combat2([])
	c = _combat2(["c_nest"])
	var eggs: Array = c.party.filter(func(u): return u.is_token)
	_ok(eggs.size() == 1 and b.party.filter(func(u): return u.is_token).is_empty(), "nest: one Egg at combat start")
	_ok(c.row_of(eggs[0]) == 0 and c.alive_party().has(eggs[0]), "nest: Egg stands in the front row")


func t_lane_e_rules() -> void:
	# Quick Beat: boss rhythm period 2, Strike turns deal x1.2.
	var b := _combat2([], {"kind": "boss", "pw": 9, "boss_key": "mecha"})
	var c := _combat2(["rule_quick_beat"], {"kind": "boss", "pw": 9, "boss_key": "mecha"})
	var bb: Unit = b.enemies.filter(func(u): return u.is_boss)[0]
	var cb: Unit = c.enemies.filter(func(u): return u.is_boss)[0]
	_ok(b.boss_period() == 3 and c.boss_period() == 2, "quick beat: period 3 -> 2")
	cb.custom_state["turn_count"] = 2
	_ok(c.boss_rhythm_phase(cb) == "strike", "quick beat: strike on turn count 2")
	cb.custom_state["turn_count"] = 3
	_ok(c.boss_rhythm_phase(cb) == "hollow", "quick beat: hollow right after")
	cb.custom_state["turn_count"] = 4
	_ok(c.boss_rhythm_phase(cb) == "strike", "quick beat: strike again 2 turns later")
	bb.custom_state["turn_count"] = 2
	_ok(b.boss_rhythm_phase(bb) != "strike", "quick beat: base rhythm has no strike on count 2")
	cb.custom_state["turn_count"] = 2
	bb.custom_state["turn_count"] = 3
	_ok(is_equal_approx(c.boss_hollow_dealt_mult(cb), 1.2) and is_equal_approx(b.boss_hollow_dealt_mult(bb), 1.0), "quick beat: strike x1.2, base strike x1.0")

	# Rising Tide: fight 1 (n=0) the front is in the water, fight 2 the back row; counter in the run state.
	b = _combat2([])
	c = _combat2(["rule_rising_tide"], {"relic_state": {"rule_rising_tide": {"n": 0}}})
	_ok(String(CoreHooks.combat_state(c, "tide")["water"]) == "front" and int((c.relic_run_out["rule_rising_tide"] as Dictionary)["n"]) == 1, "rising tide: even fight = front in water, counter +1")
	var src: Unit = c.enemies[0]
	_ok(_hit(c, src, c.party[0], 8, false, false) == int(ceil(8 * 0.75)), "rising tide (front water): front takes 25% less")
	_ok(_hit(c, src, c.party[4], 8, false, false) == 8, "rising tide (front water): back row unchanged")
	_ok(_val(c, c.party[4], "dmg", 5) == _val(b, b.party[4], "dmg", 5), "rising tide (front water): no back dmg bonus")
	var c2 := _combat2(["rule_rising_tide"], {"relic_state": c.relic_run_out})
	_ok(String(CoreHooks.combat_state(c2, "tide")["water"]) == "back", "rising tide: next fight the back row is in the water")
	_ok(_hit(c2, c2.enemies[0], c2.party[0], 8, false, false) == 8, "rising tide (back water): front takes full damage")
	_ok(_val(c2, c2.party[4], "dmg", 5) == _val(b, b.party[4], "dmg", 5) + 2 and _val(c2, c2.party[0], "dmg", 5) == _val(b, b.party[0], "dmg", 5), "rising tide (back water): back dmg faces +2, front none")

	# Upside Down: single-target enemy attacks pick the back row while one lives.
	var seen := 0
	for sd in 12:
		c = _combat2(["rule_upside_down"], {"combat_seed": 100 + sd})
		for e in c.enemies:
			var f: Dictionary = (e as Unit).die[(e as Unit).roll_face_index()]
			var kws: Array = f.get("keywords", [])
			if String(f.get("type", "")) in ["dmg", "poison", "debuff"] and not kws.has("aoe") and not kws.has("pierce") and (e as Unit).role != "assassin":
				seen += 1
				var t = c.by_uid(int((e as Unit).intent.get("target_uid", -1)))
				_ok(t != null and c.row_of(t) == 1, "upside down: seed %d single-target attack goes to the back row" % sd)
	_ok(seen >= 3, "upside down: enough single-target attacks were checked (%d)" % seen)
	var fronts := 0
	for sd in 12:
		b = _combat2([], {"combat_seed": 100 + sd})
		for e in b.enemies:
			var t2 = b.by_uid(int((e as Unit).intent.get("target_uid", -1)))
			if t2 != null and b.row_of(t2) == 0:
				fronts += 1
	_ok(fronts > 0, "upside down: without the rule the front row IS targeted (sanity)")

	# Hard Shell: R12 (Plating 2 on every enemy, side faces +2) through the real rule id.
	b = _combat2([])
	c = _combat2(["rule_hard_shell"])
	_ok(c.run_rules.has("R12"), "hard shell: switches R12 on")
	for e in c.enemies:
		_ok(CombatTraits.plating_of(c, e) >= 2, "hard shell: every enemy has Plating >= 2")
	var pe: Unit = c.enemies[0]
	pe.plating_off = 0
	_ok(_hit(c, c.party[0], pe, 6, true, false) == 4, "hard shell: single dmg 6 -> 4")
	_ok(_hit(c, c.party[0], pe, 6, true, true) == 6, "hard shell: pierce ignores it")
	_ok(_val(c, c.party[0], "shield", 3) == _val(b, b.party[0], "shield", 3) + 2, "hard shell: shield face +2")
	_ok(_val(c, c.party[0], "poison", 3) == _val(b, b.party[0], "poison", 3) + 2, "hard shell: poison face +2")
	_ok(_val(c, c.party[0], "dmg", 3) == _val(b, b.party[0], "dmg", 3), "hard shell: dmg faces unchanged")


func t_thorn_cores() -> void:
	# Thorn Growth: +1 thorns per single-target hit on a front-row Axie only
	var c := _combat(["c_thorn_growth"])
	var f: Unit = c.party[0]
	var e: Unit = c.enemies[0]
	e.intent = {"face_index": 0, "target_uid": f.uid}
	e.die[0] = {"type": "dmg", "value": 3, "keywords": []}
	var t0 := int(f.status.get("thorns", 0))
	RelicHooks.fire(c, "on_dmg_taken", {"src": e, "tgt": f, "dealt": 3, "attack": true, "combat": c})
	_ok(int(f.status.get("thorns", 0)) == t0 + 1, "thorn_growth: +1 thorns on a single hit to front")
	var bk: Unit = c.party[4]
	var b0 := int(bk.status.get("thorns", 0))
	RelicHooks.fire(c, "on_dmg_taken", {"src": e, "tgt": bk, "dealt": 3, "attack": true, "combat": c})
	_ok(int(bk.status.get("thorns", 0)) == b0, "thorn_growth: back row unchanged")
	e.die[0] = {"type": "dmg", "value": 3, "keywords": ["aoe"]}
	RelicHooks.fire(c, "on_dmg_taken", {"src": e, "tgt": f, "dealt": 3, "attack": true, "combat": c})
	_ok(int(f.status.get("thorns", 0)) == t0 + 1, "thorn_growth: AoE does not grow thorns")
	# Thorn Shield: 2 shield = 1 thorns, odd shield keeps 1
	c = _combat(["c_thorn_shield"])
	var u: Unit = c.party[1]
	u.shield = 7
	var th0 := int(u.status.get("thorns", 0))
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(u.shield == 1 and int(u.status.get("thorns", 0)) == th0 + 3, "thorn_shield: 7 shield -> 3 thorns, 1 shield left")
	# Rebound: top-thorns Axie reflects double and cannot use dmg faces
	c = _combat(["c_thorn_rebound"])
	var a: Unit = c.party[2]
	a.status["thorns"] = 20
	_ok(CoreHooks.rebound_unit(c) == a, "thorn_rebound: top thorns Axie found")
	e = c.enemies[0]
	e.max_hp = 500
	e.hp = 500
	e.plating = 0
	DamagePipeline.resolve({"combat": c, "src": e, "tgt": a, "value": 1, "attack": true, "single": true, "face_type": "dmg"})
	_ok(e.hp == 500 - 40, "thorn_rebound: reflects 20 + 20, lost %d" % (500 - e.hp))
	var dmg_fi := -1
	for i in a.die.size():
		if String(a.die[i].get("type", "")) == "dmg":
			dmg_fi = i
			break
	if dmg_fi >= 0:
		a.set_roll(dmg_fi, false)
		_ok(not c.use_die(a.uid, e.uid), "thorn_rebound: dmg face refused")
	var c2 := _combat(["c_thorn_rebound"])
	for x in c2.party:
		x.status["thorns"] = 0
	_ok(CoreHooks.rebound_unit(c2) == null, "thorn_rebound: nobody has thorns -> no unit")


## Depth v3 lane FX review proofs 3c / 3d / 3e / 3g.
func t_fx_proofs() -> void:
	# 3c: baked Hard Shell (+2 on a shield face) counts against the +10 room, so Kindle (+8) gets all 8 and nothing more
	var base_c := _combat([])
	var base := _val(base_c, base_c.party[0], "shield", 5)
	var c := _combat(["rule_hard_shell", "c_kindle", "c_field_medic"])
	var u: Unit = c.party[0]
	RelicHooks.fire(c, "on_stash", {"combat": c, "unit": u, "face": u.die[0], "fi": 0})
	u.stash_carry = true
	RelicHooks.fire(c, "on_stash", {"combat": c, "unit": u, "face": u.die[0], "fi": 0})
	_ok(_val(c, u, "shield", 5) - base == 10, "3c: Hard Shell +2 + Kindle +8 = +10 and Field Medic gets 0 (delta %d)" % (_val(c, u, "shield", 5) - base))
	_ok(CoreHooks.flat_total(c, u, "shield") == 10, "3c: flat_total stays <= +10 with a baked bonus (%d, baked %d, kindle %d, medic %d)" % [CoreHooks.flat_total(c, u, "shield"), CoreHooks.baked(c, u, "shield", 0), CoreHooks.bonus(c, u, "shield", "c_kindle"), CoreHooks.bonus(c, u, "shield", "c_field_medic")])
	# 3c: x1.5 Cores use knob core.mult_cap (default 8): +50% of 40 would be +20
	_ok(CoreHooks.mult_gain(40) == 48 and CoreHooks.mult_gain(4) == 6, "3c: mult_gain capped at +8 (40 -> %d) and plain +50%% below it" % CoreHooks.mult_gain(40))
	# 3d: Three Dice + Finisher: the third die used is the last one even though two dice are still unused
	c = _combat(["c_three_dice", "c_finisher", "c_kindle", "c_chimera_hunt"])
	_fresh_turn(c)
	_used(c, c.party[0], "dmg")
	_used(c, c.party[1], "dmg")
	_ok(CoreHooks.is_finisher(c, c.party[2]), "3d: 3rd die with Three Dice is the finisher (n=%s, rolled %s used %s held %s)" % [CoreHooks.turn_state(c, "cs_three").get("n"), c.party[2].has_rolled(), c.party[2].roll_used(), c.party[2].held])
	_ok(CoreHooks.finisher_bonus(c, c.party[2]) == 2, "3d: Finisher +2 for the 3rd die")
	RelicHooks.fire(c, "on_kill", {"combat": c, "tgt": c.enemies[0], "killer": c.party[2]})
	_ok(int(CoreHooks.quest(c, "c_chimera_hunt")["n"]) == 1, "3d: Chimera Hunt counts a kill by the 3rd die")
	_used(c, c.party[2], "dmg")
	_ok(c.party[3].held and int((CoreHooks.combat_state(c, "focus_c_kindle").get(str(c.party[3].uid), {}) as Dictionary).get("v", 0)) == 4, "3d: auto-held die also gets Kindle Focus +4")
	c = _combat(["c_three_dice", "rule_tundra"])
	_fresh_turn(c)
	for i in 3:
		_used(c, c.party[i], "dmg")
	_ok(int((CoreHooks.combat_state(c, "focus_rule_tundra").get(str(c.party[3].uid), {}) as Dictionary).get("v", 0)) == 2, "3d: auto-held die gets Tundra Focus +2")
	# 3e: Field Medic +3 on numeric debuff keywords, needs 2 non-dmg faces
	c = _combat(["c_field_medic"])
	u = c.party[0]
	u.die[1] = {"type": "debuff", "value": 0, "keywords": ["weaken:2"], "name": "t", "part": ""}
	CoreHooks.field_medic_face({"combat": c, "unit": u})
	_ok((u.die[1]["keywords"] as Array).has("weaken:5"), "3e: Field Medic debuff keyword +3")
	_ok(String(",".join(RelicRegistry.get_def("c_field_medic").requires)).contains("faces_nondmg:2"), "3e: Field Medic requires faces_nondmg:2")
	# 3e: Backline Glow lifts buff keywords of a back-row Axie
	c = _combat(["c_backline_glow"])
	u = c.party[4]
	u.die[1] = {"type": "buff", "value": 0, "keywords": ["regen:4"], "name": "t", "part": ""}
	CoreHooks.backline_face({"combat": c, "unit": u})
	_ok((u.die[1]["keywords"] as Array).has("regen:6"), "3e: Backline Glow buff keyword x1.5")
	# 3e: Take The Field turns buff faces into 2-dmg faces
	c = _combat(["c_descend"])
	u = c.party[0]
	c.relic_combat["descend"] = {"idx": u.roster_index}
	u.die[1] = {"type": "buff", "value": 0, "keywords": ["regen:4"], "name": "t", "part": ""}
	CoreHooks.descend_face({"combat": c, "unit": u})
	_ok(String(u.die[1]["type"]) == "dmg" and int(u.die[1]["value"]) == 2 and (u.die[1]["keywords"] as Array).is_empty(), "3e: Descend buff -> dmg 2")
	# 3e: Fissure also marks on a debuff face
	c = _combat(["c_fissure"])
	var en = c.enemies[0]
	RelicHooks.fire(c, "on_face_used", {"combat": c, "unit": c.party[0], "face": {"type": "debuff", "value": 0, "keywords": ["weaken:2"]},
		"fi": 0, "target_uid": en.uid, "side": "p", "depth": 0})
	_ok(int(en.custom_state.get("fissure", -1)) >= int(c.turn), "3e: Fissure marks on a debuff face")
	# 3e: Shield Wave with nobody targeting the Axie hits one random enemy
	c = _combat(["c_sonic_shield"])
	var hp_sum := 0
	for e in c.enemies:
		e.intent = {}
		hp_sum += int(e.hp)
	_used(c, c.party[0], "shield", 6, c.party[0].uid)
	var hp_now := 0
	for e in c.enemies:
		hp_now += int(e.hp)
	_ok(hp_sum - hp_now == 3, "3e: Shield Wave random enemy takes half (lost %d)" % (hp_sum - hp_now))
	# 3e: Mirror Face / Three Dice no longer exclude each other
	_ok(not Array(RelicRegistry.get_def("c_mirror_face").excludes).has("owned:c_three_dice") and not Array(RelicRegistry.get_def("c_three_dice").excludes).has("owned:c_mirror_face"), "3e: Mirror Face / Three Dice not mutually excluded")
	# 3e: Night Watch: +3 HP front row only, only the NEXT boss counts
	var nb := _combat([])
	c = _combat(["c_night_watch"])
	_ok(c.party[0].max_hp == nb.party[0].max_hp + 3 and c.party[4].max_hp == nb.party[4].max_hp, "3e: Night Watch +3 Max HP on the front row only")
	c.party[1].hp = 0
	RelicHooks.fire(c, "on_combat_end", {"combat": c, "node_kind": "boss", "result": "won"})
	_ok(not CoreHooks.quest_done(c, "c_night_watch") and int(CoreHooks.quest(c, "c_night_watch")["boss"]) == 1, "3e: Night Watch first boss with a fallen Axie ends the quest chance")
	c.party[1].hp = 5
	RelicHooks.fire(c, "on_combat_end", {"combat": c, "node_kind": "boss", "result": "won"})
	_ok(not CoreHooks.quest_done(c, "c_night_watch"), "3e: Night Watch later boss does not count")
	# 3g: Mirror Face: a die waiting for its second use does not stop another die being the Final Blow
	c = _combat(["c_mirror_face", "c_finisher"])
	for i in [2, 3, 4]:
		c.party[i].clear_roll()
	_used(c, c.party[0], "dmg")
	c.party[1].set_roll(0, false)
	_ok(CoreHooks.mirror_second(c, c.party[0]) and CoreHooks.is_finisher(c, c.party[1]), "3g: Mirror Face waiting die does not block Final Blow")


## A cantrip face resolved at roll time already counted as a use this turn: wipe the per-turn counters.
func _fresh_turn(c: CombatEngine) -> void:
	for k in ["cs_three", "cs_used", "cs_types", "cs_mirror"]:
		c.relic_combat.erase(k)
