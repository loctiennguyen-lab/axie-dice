extends Node
## Low-fire Cores fix 23/10 (design/proposals/core-visibility-fix.md "Sua 23/10"): R2 Fissure gate, R4 Open Ranks gate,
## R5 Golden Egg second source, R8 Steady Hold ramp, Rising Wave threshold 2.
const ROSTER := ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	t_fissure_gate()
	t_open_ranks_gate()
	t_tidecaller()
	t_steady_hold()
	t_golden_egg()
	t_tide_accumulator()
	t_rising_tide_exclude()
	t_steady_hold_real()
	t_fissure_fires()
	print("=== t_core_lf2: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_core_lf2: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_core_lf2: FAIL — %s" % f)
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


func _ctx(keys: Array, owned: Array) -> Dictionary:
	var roster: Array = []
	for k in keys:
		roster.append({"hero_key": k})
	return {"owned_ids": owned, "roster": roster, "seen": [], "mode": "short", "first_run": false, "pick_index": 1, "front_size": 2, "ascension": 0}


func t_fissure_gate() -> void:
	var d = RelicRegistry.get_def("c_fissure")
	_ok((d.requires as PackedStringArray).has("face:poison|weaken|vulnerable|blind|freeze|stun"), "fissure: requires lists every real debuff")
	# a party whose only debuff is a real keyword (no poison, no "debuff" label) must now see Fissure
	ContentDB.heroes["t_dbf"] = {"die": [{"type": "dmg", "value": 3, "keywords": ["weaken:2"]}]}
	_ok(CoreOffer.is_valid(d, _ctx(["t_dbf"], [])), "fissure: weaken-only party -> valid")
	ContentDB.heroes["t_dbf"] = {"die": [{"type": "dmg", "value": 3, "keywords": ["stun"]}]}
	_ok(CoreOffer.is_valid(d, _ctx(["t_dbf"], [])), "fissure: stun-only party -> valid")
	ContentDB.heroes["t_dbf"] = {"die": [{"type": "dmg", "value": 3}, {"type": "shield", "value": 2}]}
	_ok(not CoreOffer.is_valid(d, _ctx(["t_dbf"], [])), "fissure: no debuff -> hidden")
	ContentDB.heroes.erase("t_dbf")


func t_open_ranks_gate() -> void:
	var d = RelicRegistry.get_def("c_open_ranks")
	_ok((d.requires as PackedStringArray).is_empty(), "open_ranks: no requires")
	_ok(CoreOffer.is_valid(d, _ctx(ROSTER, [])), "open_ranks: valid with no front Core owned")
	_ok(not CoreOffer.is_valid(d, _ctx(ROSTER, ["c_living_wall"])), "open_ranks: living_wall excludes it")
	for id in ["c_backline_glow", "c_descend"]:
		var o = RelicRegistry.get_def(id)
		_ok((o.excludes as PackedStringArray).has("owned:c_open_ranks"), "%s excludes open_ranks" % id)
		_ok(not CoreOffer.is_valid(o, _ctx(ROSTER, ["c_open_ranks"])), "%s hidden when open_ranks owned" % id)


func t_tidecaller() -> void:
	_ok(String(RelicRegistry.get_def("c_tidecaller").description).begins_with("Every 2 Mana"), "tidecaller: rule text says 2 Mana")
	var t := _combat(["c_tidecaller"])
	var hp0: int = t.enemies[0].hp
	RelicHooks.fire(t, "on_active_played", {"combat": t, "cost": 2})
	_ok(t.enemies[0].hp < hp0, "tidecaller: one active costing 2 deals damage")
	var t2 := _combat(["c_tidecaller"])
	RelicHooks.fire(t2, "on_reroll_paid", {"combat": t2, "cost": 1, "k": 1})
	_ok(t2.enemies[0].hp == hp0, "tidecaller: 1 mana alone does nothing")
	RelicHooks.fire(t2, "on_reroll_paid", {"combat": t2, "cost": 1, "k": 2})
	_ok(t2.enemies[0].hp < hp0, "tidecaller: 1+1 mana triggers")


func t_steady_hold() -> void:
	_ok("max +3" in String(RelicRegistry.get_def("c_steady_hold").description), "steady_hold: rule text mentions the ramp")
	var b := _combat([])
	var c := _combat(["c_steady_hold"])
	var u: Unit = c.party[0]
	var fi := u.roll_face_index()
	var st := CoreHooks.combat_state(c, "focus_c_steady_hold")
	RelicHooks.fire(c, "on_stash", {"combat": c, "unit": u, "face": u.current_face(), "fi": fi})
	_ok(int(st[str(u.uid)]["v"]) == 1, "steady_hold: first held turn -> +1")
	u.stash_carry = true
	for want in [2, 3, 3]:
		RelicHooks.fire(c, "on_stash", {"combat": c, "unit": u, "face": u.current_face(), "fi": fi})
		_ok(int(st[str(u.uid)]["v"]) == want, "steady_hold: held again -> +%d (max 3)" % want)
	_ok(CoreHooks.focus_value(c, "focus_c_steady_hold", u, "dmg") == 3, "steady_hold: focus value 3 on a value face")
	CoreHooks.focus_spent(c, "focus_c_steady_hold", u)
	_ok(CoreHooks.focus_value(c, "focus_c_steady_hold", u, "dmg") == 0, "steady_hold: reset after use")
	u.stash_carry = false
	RelicHooks.fire(c, "on_stash", {"combat": c, "unit": u, "face": u.current_face(), "fi": fi})
	_ok(int(st[str(u.uid)]["v"]) == 1, "steady_hold: a fresh hold restarts at +1")
	_ok(b.stash_cap() == 1 and c.stash_cap() == 2, "steady_hold: cap still 2")


func t_golden_egg() -> void:
	_ok("hatches (once per turn)" in String(RelicRegistry.get_def("c_golden_egg").description), "golden_egg: rule text mentions hatching")
	var c := _combat(["c_golden_egg"])
	var m0: int = c.mana
	RelicHooks.fire(c, "on_egg_hatched", {"combat": c, "egg": c._mk_ally()})
	_ok(c.mana == m0 + 3 and bool(CoreHooks.combat_state(c, "ge")["on"]), "golden_egg: an Egg hatching pays +3 mana and arms the +3 dmg")
	var n := _combat([])
	n.mana = 0
	RelicHooks.fire(n, "on_egg_hatched", {"combat": n, "egg": n._mk_ally()})
	_ok(n.mana == 0, "golden_egg: hatching pays nothing without the Core")

	# second hatch in the same turn pays nothing
	var m2: int = c.mana
	RelicHooks.fire(c, "on_egg_hatched", {"combat": c, "egg": c._mk_ally()})
	_ok(c.mana == m2, "golden_egg: second hatch the same turn pays nothing")
	c.turn += 1
	RelicHooks.fire(c, "on_egg_hatched", {"combat": c, "egg": c._mk_ally()})
	_ok(c.mana == m2 + 3, "golden_egg: next turn pays again")
	# real summon path through use_die
	var s := _combat(["c_golden_egg"])
	var u: Unit = s.party[0]
	var fi := u.roll_face_index()
	u.die[fi] = {"type": "summon", "value": 1, "keywords": []}
	var m1: int = s.mana
	var tok0 := s._count_alive_tokens(s.party)
	var used: bool = s.use_die(u.uid, -1)
	_ok(used and s._count_alive_tokens(s.party) == tok0 + 1, "golden_egg: summon face hatches an Egg (fixture)")
	_ok(s.mana == m1 + 3 and bool(CoreHooks.combat_state(s, "ge")["on"]), "golden_egg: real summon face pays through use_die")


func _tide_drop(costs: Array) -> int:
	var t := _combat(["c_tidecaller"])
	var hp0: int = t.enemies[0].hp
	for cst in costs:
		RelicHooks.fire(t, "on_active_played", {"combat": t, "cost": cst})
	return hp0 - int(t.enemies[0].hp)


func t_tide_accumulator() -> void:
	var one := _tide_drop([2])
	_ok(one > 0, "tide: 2 Mana -> one pulse")
	_ok(_tide_drop([2, 2]) == 2 * one, "tide: two actives of 2 -> two pulses (leftover not eaten)")
	_ok(_tide_drop([1, 1, 1, 1]) == 2 * one, "tide: 1+1+1+1 -> two pulses")
	_ok(_tide_drop([3, 1]) == 2 * one, "tide: 3 then 1 -> two pulses (carry 1)")
	_ok(_tide_drop([3]) == one, "tide: 3 Mana -> one pulse, 1 carried")


func t_rising_tide_exclude() -> void:
	var rt = RelicRegistry.get_def("rule_rising_tide")
	_ok((rt.excludes as PackedStringArray).has("owned:c_open_ranks"), "rising_tide: excludes owned open_ranks")
	_ok(CoreOffer.is_valid(rt, _ctx(ROSTER, [])), "rising_tide: valid on its own")
	_ok(not CoreOffer.is_valid(rt, _ctx(ROSTER, ["c_open_ranks"])), "rising_tide: hidden when open_ranks owned")
	_ok(not CoreOffer.is_valid(RelicRegistry.get_def("c_open_ranks"), _ctx(ROSTER, ["rule_rising_tide"])), "open_ranks: hidden under rising_tide")


## Park die 0 (forced to a plain damage face) and play the next turn: returns the unit.
func _hold_turn(c: CombatEngine, fi: int) -> Unit:
	var u: Unit = c.party[0]
	_ok(c.stash(u.uid), "hold: stash accepted")
	c.end_turn()
	return c.party[0]


func _prep(relics: Array) -> CombatEngine:
	var c := _combat(relics)
	var u: Unit = c.party[0]
	u.die[u.roll_face_index()] = {"type": "dmg", "value": 5, "keywords": []}
	u.max_hp = 9999
	u.hp = 9999   # the fixture die must survive the enemy turns
	return c


func t_steady_hold_real() -> void:
	var c := _prep(["c_steady_hold"])
	var b := _prep([])
	var fi: int = c.party[0].roll_face_index()
	var key := "focus_c_steady_hold"
	var want := [1, 2, 3, 3]
	for turn in 4:
		var u := _hold_turn(c, fi)
		var ub: Unit = b.party[0]
		if turn == 0:
			ub = _hold_turn(b, fi)
		if c.won or c.lost or u.hp <= 0 or u.roll_face_index() != fi:
			_ok(false, "steady_hold real: fixture lost the die on turn %d (won %s lost %s hp %d fi %d want %d)" % [turn, c.won, c.lost, u.hp, u.roll_face_index(), fi])
			return
		var delta: int = c._face_value(u, fi) - b._face_value(ub, fi)
		_ok(delta == want[turn] and u.stash_carry, "steady_hold real: after %d held turn(s) the die deals +%d (got %d)" % [turn + 1, want[turn], delta])
		if turn == 1:
			# undo of the next Hold rewinds the counter, a state round trip keeps it
			var n_before := int((CoreHooks.combat_state(c, key)[str(u.uid)] as Dictionary)["n"])
			_ok(c.stash(u.uid), "steady_hold real: re-hold")
			_ok(int((CoreHooks.combat_state(c, key)[str(u.uid)] as Dictionary)["n"]) == n_before + 1, "steady_hold real: re-hold counts")
			_ok(c.undo_last() and int((CoreHooks.combat_state(c, key)[str(u.uid)] as Dictionary)["n"]) == n_before, "steady_hold real: undo rewinds the counter")
			var c2 := _combat(["c_steady_hold"])
			c2._apply_state_dict(c._state_dict())
			_ok(JSON.stringify(CoreHooks.combat_state(c2, key)) == JSON.stringify(CoreHooks.combat_state(c, key)), "steady_hold real: state round trip keeps the counter")
	# using the die resets the ramp
	var uu: Unit = c.party[0]
	if not uu.held:
		c.use_die(uu.uid, c.enemies[0].uid)
	_ok(CoreHooks.focus_value(c, key, uu, "dmg") == 0, "steady_hold real: using the die resets the bonus")

	# with Kindle the flat bonuses together stay inside the +10 room
	var k := _prep(["c_kindle", "c_steady_hold"])
	var kb := _prep([])
	var kfi: int = k.party[0].roll_face_index()
	var ku: Unit = null
	for turn in 3:
		ku = _hold_turn(k, kfi)
		if turn == 0:
			_hold_turn(kb, kfi)
	if ku != null and ku.roll_face_index() == kfi and not k.lost:
		var extra: int = k._face_value(ku, kfi) - kb._face_value(kb.party[0], kfi)
		_ok(extra <= 10, "steady_hold+kindle: total flat stays <= +10 (got %d)" % extra)
		_ok(CoreHooks.flat_total(k, ku, "dmg", "", kfi) <= 10, "steady_hold+kindle: flat_total <= 10")
		_ok(extra >= 9, "steady_hold+kindle: both Cores really add (got %d)" % extra)
	else:
		_ok(false, "steady_hold+kindle: fixture lost the die")


func t_fissure_fires() -> void:
	for kw in ["weaken:2", "stun", "vulnerable:2", "freeze"]:
		var c := _combat(["c_fissure"])
		var e = c.enemies[0]
		CoreHooks.fissure_used({"combat": c, "side": "p", "face": {"type": "dmg", "value": 3, "keywords": [kw]}, "target_uid": e.uid})
		_ok(int(e.custom_state.get("fissure", -1)) == c.turn + 1, "fissure: a %s face marks the enemy" % kw)
