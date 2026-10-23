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
	_ok("dies or hatches" in String(RelicRegistry.get_def("c_golden_egg").description), "golden_egg: rule text mentions hatching")
	var c := _combat(["c_golden_egg"])
	var m0: int = c.mana
	RelicHooks.fire(c, "on_egg_hatched", {"combat": c, "egg": c._mk_ally()})
	_ok(c.mana == m0 + 3 and bool(CoreHooks.combat_state(c, "ge")["on"]), "golden_egg: an Egg hatching pays +3 mana and arms the +3 dmg")
	var n := _combat([])
	n.mana = 0
	RelicHooks.fire(n, "on_egg_hatched", {"combat": n, "egg": n._mk_ally()})
	_ok(n.mana == 0, "golden_egg: hatching pays nothing without the Core")
