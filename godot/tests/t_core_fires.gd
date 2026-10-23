extends Node
## Depth v3 lane FX: every ENABLED Core / Run Rule must report EventBus.core_fired when it really changes an outcome
## (Liam: "89/101 relics fire silently, I never saw a new relic"). The id list comes from the registry; an enabled id
## with no scenario here FAILS by name. NO_BEHAVIOUR ids are Cores whose effect is not implemented anywhere yet
## (knobs only): they are reported loudly (WARN), and the test fails if one of them starts firing so the entry gets removed.
const ROSTER := ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
## Enabled but nothing in the engine reads them yet (run-flow knobs: fossil/dim stone/crow tier shifts, rule_none is the empty rule).
const NO_BEHAVIOUR := ["rule_none"]
var _fails: Array[String] = []
var _checks := 0
var _log: Array = []   # [id, uid, amount, kind]
var _scen: Dictionary = {}


func _ready() -> void:
	EventBus.core_fired.connect(func(id: String, uid: int, amt: int, kind: String): _log.append([id, uid, amt, kind]))
	_build_table()
	var ids: Array = []
	for def in RelicRegistry.all_defs_sorted():
		var id := String(def.id)
		if (id.begins_with("c_") or id.begins_with("rule_")) and not def.disabled and not id.begins_with("c_test_") and not id.begins_with("rule_test_"):
			ids.append(id)
	var fired := 0
	var warn: Array[String] = []
	for id in ids:
		_log.clear()
		if NO_BEHAVIOUR.has(id):
			_ok(not _any(id), "%s is listed NO_BEHAVIOUR but fires: remove it from the list" % id)
			warn.append(id)
			continue
		if not _scen.has(id):
			_ok(false, "no scenario for enabled Core/rule %s (add one to t_core_fires)" % id)
			continue
		(_scen[id] as Callable).call(id)
		var ok := _any(id)
		_ok(ok, "%s never fired core_fired in its scenario" % id)
		if ok:
			fired += 1
		for e in _log:
			_ok(int(e[2]) > 0, "%s fired with amount <= 0" % id)
	t_preview_silent()
	t_undo_tally()
	print("t_core_fires: %d / %d enabled ids fire (NO_BEHAVIOUR, not implemented: %s)" % [fired, ids.size(), ", ".join(warn)])
	if _fails.is_empty():
		print("t_core_fires: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_core_fires: FAIL - %s" % f)
	get_tree().quit(1)


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _any(id: String) -> bool:
	for e in _log:
		if e[0] == id:
			return true
	return false


func _combat(relics: Array, kind: String = "battle") -> CombatEngine:
	var roster: Array = []
	for i in ROSTER.size():
		roster.append({"persistent_id": i + 1, "hero_key": ROSTER[i], "tier": 1,
			"max_hp": ContentDB.heroes[ROSTER[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var c := CombatEngine.new()
	c.setup_new({"node_id": "t_fire", "kind": kind, "pw": 2, "ascension": 0, "roster_snapshot": roster,
		"relic_ids": relics, "combat_seed": 4242, "bonus_reroll": 0})
	for e in c.enemies:
		e.max_hp = 900
		e.hp = 900
		e.plating = 0
	return c


func _face(ft: String, v: int, kws: Array = [], part: String = "") -> Dictionary:
	return {"type": ft, "value": v, "keywords": kws, "name": "t", "part": part}


## Put `f` on face 0 of `u`, roll it, and really use it (value computed by _do_face, so flat Cores fire).
func _play(c: CombatEngine, u: Unit, f: Dictionary, tgt: int = -1) -> void:
	u.die[0] = f
	u.set_roll(0, false)
	if tgt < 0:
		tgt = c.enemies[0].uid if String(f["type"]) in ["dmg", "poison", "debuff"] else u.uid
	c.use_die(u.uid, tgt)


func _roll_faces(c: CombatEngine, faces: Array) -> void:
	for k in faces.size():
		c.party[k].held = false
		c.party[k].set_roll(int(faces[k]), false)


func _only(c: CombatEngine, u: Unit) -> void:
	for o in c.party:
		if o != u:
			o.clear_roll()


func _hit_front(c: CombatEngine, v: int = 6) -> void:
	DamagePipeline.resolve({"combat": c, "src": c.enemies[0], "tgt": c.party[0], "value": v, "attack": true, "single": true, "face_type": "dmg"})


func _build_table() -> void:
	# build / start-of-combat effects: constructing the fight is the scenario
	for id in ["c_early_scales", "c_dewdrop", "c_elder_trunk", "c_dry_well", "c_field_medic", "c_living_wall", "c_nest",
			"c_night_watch", "c_open_ranks", "c_sacrifice", "c_sixth_die", "c_toxic_still", "c_whittle", "rule_dry_steppe",
			"rule_old_forest", "rule_starfall", "rule_wasteland"]:
		_scen[id] = func(i: String): _combat([i])
	_scen["c_collector"] = func(i): _collector(i)
	_scen["c_meme_nametag"] = func(i): _combat([i])
	_scen["c_meme_copycat"] = func(i): var c := _combat([i]); _roll_faces(c, [0, 0, 0, 1, 2]); RelicHooks.fire(c, "on_roll_settled", {"combat": c, "rerolled_uids": []})
	_scen["c_meme_jumpy"] = func(i): var c := _combat([i]); _roll_faces(c, [0, 1, 2, 3, 4]); RelicHooks.fire(c, "on_roll_settled", {"combat": c, "rerolled_uids": []})
	_scen["c_backline_glow"] = func(i): var c := _combat([i]); _play(c, c.party[4], _face("heal", 4))
	_scen["c_bastion"] = func(i): _hit_front(_combat([i]))
	_scen["rule_rising_tide"] = func(i): var c := _combat([i]); CoreHooks.combat_state(c, "tide")["water"] = "front"; _hit_front(c)
	_scen["c_blood_sign"] = func(i): var c := _combat([i]); _play(c, c.party[0], _face("dmg", 9))
	_scen["c_cascade"] = func(i): var c := _combat([i]); _play(c, c.party[0], _face("dmg", 3)); _play(c, c.party[1], _face("dmg", 3))
	_scen["c_chimera_hunt"] = func(i): var c := _combat([i]); _only(c, c.party[0]); c.party[0].set_roll(0, false); RelicHooks.fire(c, "on_kill", {"combat": c, "killer": c.party[0], "tgt": c.enemies[0]})
	_scen["c_concord"] = func(i): var c := _combat([i]); CoreHooks.turn_state(c, "cs_concord")["part"] = "p1"; _play(c, c.party[0], _face("dmg", 3, [], "p1"))
	_scen["c_deep_current"] = func(i): var c := _combat([i]); c.relic_run_in["c_deep_current"] = {"mana": 5}; RelicHooks.fire(c, "on_combat_start", {"combat": c})
	_scen["c_descend"] = func(i): _descend(i)
	_scen["c_finisher"] = func(i): var c := _combat([i]); _only(c, c.party[0]); CoreHooks.turn_state(c, "cs_used")["n"] = 2; _play(c, c.party[0], _face("dmg", 3))
	_scen["c_fissure"] = func(i): var c := _combat([i]); _play(c, c.party[0], _face("poison", 3))
	_scen["c_gatekeeper"] = func(i): _gatekeeper(i)
	_scen["c_golden_egg"] = func(i): var c := _combat([i]); var egg = c._mk_ally(); c.party.append(egg); egg.hp = 0; RelicHooks.fire(c, "on_dmg_taken", {"combat": c, "tgt": egg, "src": c.enemies[0], "dealt": 3, "attack": true})
	_scen["c_growing_shell"] = func(i): var c := _combat([i]); RelicHooks.fire(c, "on_kill", {"combat": c, "killer": c.party[0], "tgt": c.enemies[0]})
	_scen["c_hollow_core"] = func(i): var c := _combat([i]); RelicHooks.fire(c, "on_reroll_paid", {"combat": c, "cost": 1, "k": 1})
	_scen["c_key_strike"] = func(i): var c := _combat([i]); c.party[0].stash_carry = true; RelicHooks.fire(c, "on_face_hit", {"combat": c, "unit": c.party[0], "first": true, "dealt": 9})
	_scen["c_kindle"] = func(i): _focus(i)
	_scen["rule_tundra"] = func(i): _focus(i)
	_scen["c_loop"] = func(i): var c := _combat([i]); c.party[0].die[0] = _face("shield", 2, ["cantrip"]); c.party[0].set_roll(0, false); c._resolve_cantrips()
	_scen["c_mana_pool"] = func(i): var c := _combat([i]); _play(c, c.party[0], _face("mana", 2))
	_scen["c_mana_ward"] = func(i): var c := _combat([i]); c.mana = 6; RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_scen["c_mirror_face"] = func(i): var c := _combat([i]); _play(c, c.party[0], _face("dmg", 3))
	_scen["c_overflow"] = func(i): var c := _combat([i]); c.mana = 12; RelicHooks.fire(c, "on_turn_start", {"combat": c})
	_scen["c_plague_spread"] = func(i): var c := _combat([i]); c.enemies[0].status["poison"] = 3; RelicHooks.fire(c, "on_kill", {"combat": c, "killer": c.party[0], "tgt": c.enemies[0]})
	_scen["c_prime_chain"] = func(i): var c := _combat([i]); _play(c, c.party[1], _face("shield", 3)); _play(c, c.party[0], _face("dmg", 3))
	_scen["c_prism"] = func(i): var c := _combat([i]); var st := CoreHooks.turn_state(c, "cs_types"); for k in ["dmg", "shield", "heal", "mana"]: st[k] = true; RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_scen["c_sonic_shield"] = func(i): var c := _combat([i]); _play(c, c.party[0], _face("shield", 4))
	_scen["c_spore_burst"] = func(i): var c := _combat([i]); c.party[0].hp = 0; RelicHooks.fire(c, "on_dmg_taken", {"combat": c, "tgt": c.party[0], "src": c.enemies[0], "dealt": 3})
	_scen["c_steady_hold"] = func(i): var c := _combat([i]); c.stash(c.party[0].uid); c.stash(c.party[1].uid)
	_scen["c_thorn_growth"] = func(i): _thorn_growth(i)
	_scen["c_thorn_pact"] = func(i): var c := _combat([i]); RelicHooks.fire(c, "on_roll_settled", {"combat": c, "rerolled_uids": [c.party[0].uid]})
	_scen["c_thorn_rebound"] = func(i): var c := _combat([i]); c.party[2].status["thorns"] = 5; _hit_on(c, c.party[2])
	_scen["c_bloodline_ward"] = func(i): var c := _combat([i]); for k in 5: c.party[k].cls = "plant"; _play(c, c.party[2], _face("shield", 5))
	_scen["c_smoldering"] = func(i): var c := _combat([i]); c.party[0].held = true; RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_scen["c_cache_plate"] = func(i): var c := _combat([i]); c.party[0].die[0] = _face("shield", 6); c.party[0].set_roll(0, false); c.stash(c.party[0].uid)
	_scen["c_golden_thread"] = func(i): var c := _combat([i]); _roll_faces(c, [0, 0, 0, 1, 2]); c._snap_bo(); c.mana = 5; c.wild_face(c.party[3].uid, 0)
	_scen["c_thorn_shield"] = func(i): var c := _combat([i]); c.party[1].shield = 7; RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_scen["c_three_dice"] = func(i): var c := _combat([i]); RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_scen["c_tidecaller"] = func(i): var c := _combat([i]); RelicHooks.fire(c, "on_reroll_paid", {"combat": c, "cost": 3, "k": 1})
	_scen["rule_balance"] = func(i): var c := _combat([i]); CoreHooks.turn_state(c, "cs_dmgn")["n"] = 2; _play(c, c.party[0], _face("dmg", 5))
	_scen["rule_cheap_mana"] = func(i): var c := _combat([i]); RelicHooks.fire(c, "on_reroll_paid", {"combat": c, "cost": 1, "k": 1})
	_scen["rule_hard_shell"] = func(i): var c := _combat([i]); _play(c, c.party[0], _face("shield", 3))
	_scen["rule_heavy_finish"] = func(i): var c := _combat([i]); _only(c, c.party[0]); _play(c, c.party[0], _face("dmg", 3))
	_scen["rule_quick_beat"] = func(i): var c := _combat([i]); c.enemies[0].is_boss = true; RelicHooks.fire(c, "on_turn_start", {"combat": c})
	_scen["rule_upside_down"] = func(i): _upside(i)
	_scen["rule_crow"] = func(_i): _crow()
	_scen["c_fossil"] = func(i): _bet_run(i)
	_scen["c_dim_stone"] = func(i): _bet_run(i)


func _crow() -> void:
	CoreTestUtil.crow_setup(ROSTER)
	RunState._crow_judge({"stat": {"turns": 2}, "downed": 0}, "battle")


## Run-flow bets (Fossil / Dim Stone): fire from RunState, outside combat.
func _bet_run(i: String) -> void:
	RunState.reset()
	RunState.start_new_run_seeded(5, {"team_keys": ROSTER, "mode": "short", "ascension": 0, "ranked": false, "bonuses": {},
		"loadout": {"rules_on": true}})
	RunState.pending_rewards = []
	RunState._core_offer_active = false
	RunState._rule_offer_active = false
	if i == "c_fossil":
		RunState.core_pick_index = 1
		RunState.owned_relic_ids.append("c_fossil")
		RunState._open_core_offer()
	else:
		var other := CoreOffer.card_of(RelicRegistry.get_def("c_dim_stone"), 0)
		RunState.core_seen.clear()
		RunState.pending_rewards = [other]
		RunState._core_offer_active = true
		RunState._core_offer_pick = 0
		RunState.apply_chosen_reward(other, "")


func _collector(i: String) -> void:
	var c := _combat([i])
	RelicHooks.fire(c, "on_turn_start", {"combat": c})


func _hit_on(c: CombatEngine, t: Unit) -> void:
	DamagePipeline.resolve({"combat": c, "src": c.enemies[0], "tgt": t, "value": 1, "attack": true, "single": true, "face_type": "dmg"})


func _descend(i: String) -> void:
	var c := _combat([i])
	var u: Unit = c.party[0]
	c.relic_combat["descend"] = {"idx": u.roster_index}
	u.hp = maxi(1, u.hp - 5)
	RelicHooks.fire(c, "on_face_hit", {"combat": c, "unit": u, "dealt": 10})


func _gatekeeper(i: String) -> void:
	var c := _combat([i])
	var e: Unit = c.enemies[0]
	e.intent = {"face_index": 0, "target_uid": c.party[0].uid}
	e.die[0] = {"type": "dmg", "value": 3, "keywords": []}
	RelicHooks.fire(c, "on_dmg_taken", {"src": e, "tgt": c.party[0], "dealt": 3, "attack": true, "combat": c})


func _thorn_growth(i: String) -> void:
	_gatekeeper(i)


func _focus(i: String) -> void:
	var c := _combat([i])
	var u: Unit = c.party[0]
	u.die[0] = _face("dmg", 3)
	u.set_roll(0, false)
	RelicHooks.fire(c, "on_stash", {"combat": c, "unit": u, "face": u.die[0], "fi": 0})
	u.stash_carry = true
	c.use_die(u.uid, c.enemies[0].uid)


func _upside(i: String) -> void:
	var c := _combat([i])
	for n in 8:
		if _any(i):
			return
		c.end_turn()


## An undone move gives its Core activation back (RunState.core_impact), so redoing it is not counted twice.
func t_undo_tally() -> void:
	RunState.core_impact = {}
	var c := _combat(["c_finisher"])
	var u: Unit = c.party[4]
	_only(c, u)
	for o in c.party:
		if o != u:
			o.mark_used()
	var before := JSON.stringify(RunState.core_impact)
	_play(c, u, _face("dmg", 3))
	var after := JSON.stringify(RunState.core_impact)
	_ok(after != before, "undo proof: the play counted a Core activation (%s)" % after)
	_ok(c.undo_last(), "undo proof: undo works")
	_ok(JSON.stringify(RunState.core_impact) == before, "undo proof: undo takes the activation back (%s)" % JSON.stringify(RunState.core_impact))
	_play(c, u, _face("dmg", 3))
	_ok(JSON.stringify(RunState.core_impact) == after, "undo proof: redo counts once (%s)" % JSON.stringify(RunState.core_impact))


## A UI preview / forecast must never count as a Core firing.
func t_preview_silent() -> void:
	var c := _combat(["c_kindle", "c_finisher", "c_mana_pool", "c_backline_glow"])
	var u: Unit = c.party[4]
	u.die[0] = _face("heal", 4)
	u.set_roll(0, false)
	CoreHooks.combat_state(c, "focus_c_kindle")[str(u.uid)] = {"v": 4, "fi": 0}
	u.stash_carry = true
	_log.clear()
	c._face_value(u, 0)
	c.preview_damage(c.party[0], c.enemies[0], 0)
	_ok(_log.is_empty(), "preview / _face_value outside _do_face fired core_fired: %s" % [_log])
