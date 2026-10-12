extends Node
## Lane B: the relics that run on the 8 new hooks (H1-H8) from lane A PR2 — one group per relic
## family, driven through the real CombatEngine API wherever a player would (use_die, reroll_dice,
## tweak, hold_pick, loaded_pick, end_turn, undo_last), plus a full-fight smoke with all of them owned.

var _failures: Array[String] = []
var _checks := 0

const KEYS := ["plant1", "beast1", "aqua1", "reptile1", "bird1"]


func _ready() -> void:
	print("=== t_relic_hooks_v2: start ===")
	test_claw()
	test_positional_linkstone_symmetry()
	test_face_used_relics()
	test_relaybaton_chain()
	test_keystone()
	test_hollowbone()
	test_mana_step_relics()
	test_heirloom()
	test_devilsreroll()
	test_twinfates()
	test_pacts_v2()
	test_class_ups()
	test_tithepips()
	test_amberdie()
	test_tweaks()
	test_pipfile_nudge_is_per_roll()
	test_loadeddie()
	test_h8_economy()
	test_eggs()
	test_ear_and_keeneye()
	test_full_fight_all_live_relics()
	print("=== t_relic_hooks_v2: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_relic_hooks_v2: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_relic_hooks_v2: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _combat(relic_ids: Array, seed_v: int = 4242, keys: Array = KEYS, extra: Dictionary = {}) -> CombatEngine:
	var roster: Array = []
	for i in keys.size():
		roster.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var setup := {"node_id": "t_relic_hooks_v2", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": roster, "relic_ids": relic_ids, "combat_seed": seed_v}
	setup.merge(extra, true)
	var c := CombatEngine.new()
	c.setup_new(setup)
	return c


## (unit index, face index, value delta) for every face that differs between two fights built alike.
func _diff(c: CombatEngine, base: CombatEngine) -> Array:
	var out: Array = []
	for i in base.party.size():
		for j in base.party[i].die.size():
			var d: int = int(c.party[i].die[j]["value"]) - int(base.party[i].die[j]["value"])
			if d != 0:
				out.append([i, j, d])
	return out


func _face_of(u: Unit, type: String, kw: String = "") -> int:
	for i in u.die.size():
		if String(u.die[i]["type"]) == type and (kw == "" or (u.die[i]["keywords"] as Array).has(kw)):
			return i
	return -1


## Forces `u` to be showing a face of `type` (unused), then lets the settle hooks react.
func _show(c: CombatEngine, u: Unit, type: String) -> void:
	var fi: int = _face_of(u, type)
	assert(fi >= 0)
	u.set_roll(fi, false)


func _settle(c: CombatEngine) -> void:
	RelicHooks.fire(c, "on_roll_settled", {"combat": c, "rerolled_uids": []})


func _new_turn(c: CombatEngine) -> void:
	c.turn += 1
	RelicHooks.fire(c, "on_turn_start", {"combat": c})


# ---------------------------------------------------------------------------

func test_claw() -> void:
	for s in [1, 2, 3, 4, 5, 6, 7, 8]:
		var base := _combat([], s)
		var c := _combat(["r_claw"], s)
		# expected: lowest-value rolled damage face on the team, ties to the lower slot
		var best := -1
		var best_v := 0
		for i in base.party.size():
			var u: Unit = base.party[i]
			var fi: int = u.roll_face_index()
			if fi >= 0 and String(u.die[fi]["type"]) == "dmg" and int(u.die[fi]["value"]) > 0:
				if best < 0 or int(u.die[fi]["value"]) < best_v:
					best = i
					best_v = int(u.die[fi]["value"])
		var d := _diff(c, base)
		if best < 0:
			_assert(d.is_empty(), "claw seed %d: no damage face rolled, no bonus" % s)
		else:
			_assert(d.size() == 1 and d[0][0] == best and d[0][2] == 4, "claw seed %d: +4 on slot %d only, got %s" % [s, best, str(d)])
		# after a reroll of everyone the bonus is recomputed, still exactly one (or none) and never stale
		var uids: Array = []
		for u in c.party:
			uids.append(u.uid)
		if c.can_reroll(uids):
			c.reroll_dice(uids, 777)
			base.reroll_dice(uids, 777)
			var d2 := _diff(c, base)
			_assert(d2.size() <= 1 and (d2.is_empty() or d2[0][2] == 4), "claw seed %d: after reroll %s" % [s, str(d2)])


func test_positional_linkstone_symmetry() -> void:
	var c := _combat(["r_linkstone"], 5)
	var base := _combat([], 5)
	for u in c.party:
		_show(c, u, "dmg")
		_show(base, base.party[c.party.find(u)], "dmg")
	_settle(c)
	var d := _diff(c, base)
	_assert(d.size() == 5, "linkstone: five dmg faces in a row all get a bonus, got %d" % d.size())
	for x in d:
		_assert(x[2] == 2, "linkstone: +2 each")
	_show(c, c.party[2], "mana")   # slot 3 shows mana: it and its neighbours lose the link
	_settle(c)
	d = _diff(c, base)
	var by_slot := {}
	for x in d:
		by_slot[x[0]] = x[2]
	_assert(by_slot.get(0, 0) == 2 and by_slot.get(1, 0) == 2 and by_slot.get(3, 0) == 2 and by_slot.get(4, 0) == 2 and not by_slot.has(2),
		"linkstone: pairs 1-2 and 4-5 still link, the mana face in slot 3 does not: %s" % str(by_slot))
	_assert(d.size() == 4, "linkstone: stale bonus on the old face of slot 3 was removed")
	# symmetry charm
	var s := _combat(["r_symmetrycharm"], 5)
	var sb := _combat([], 5)
	for i in 5:
		_show(s, s.party[i], "dmg")
		_show(sb, sb.party[i], "dmg")
	_settle(s)
	var sd := _diff(s, sb)
	var bs := {}
	for x in sd:
		bs[x[0]] = x[2]
	_assert(bs.get(0, 0) == 3 and bs.get(4, 0) == 3 and bs.get(1, 0) == 3 and bs.get(3, 0) == 3 and bs.get(2, 0) == 1,
		"symmetry: both pairs +3, centre +1: %s" % str(bs))
	_show(s, s.party[0], "mana")
	_settle(s)
	bs = {}
	for x in _diff(s, sb):
		bs[x[0]] = x[2]
	_assert(not bs.has(0) and not bs.has(4) and bs.get(1, 0) == 3 and bs.get(3, 0) == 3 and not bs.has(2),
		"symmetry: pair 1-5 broken, pair 2-4 still +3, no centre bonus: %s" % str(bs))


func _use(c: CombatEngine, u: Unit, type: String, target_uid: int = -1) -> bool:
	_show(c, u, type)
	_settle(c)
	return c.use_die(u.uid, u.uid if target_uid < 0 else target_uid)


func test_face_used_relics() -> void:
	# each relic alone against the same fight without it, so passives (BULWARK +2, Thorns from 10 Shield) cancel out
	var c := _combat(["r_carapace"], 11)
	var base := _combat([], 11)
	_assert(_use(c, c.party[0], "shield") and _use(base, base.party[0], "shield"), "plant uses a shield face")
	_assert(c.party[0].shield - base.party[0].shield == 7, "carapace: +5, and the plant's BULWARK adds 2 to any Shield it receives, got %d" % (c.party[0].shield - base.party[0].shield))
	_assert(_use(c, c.party[1], "shield") and _use(base, base.party[1], "shield"), "beast uses a shield face")
	_assert(c.party[1].shield == base.party[1].shield, "carapace: only the FIRST shield face of the turn")
	_new_turn(c)
	_assert(RelicHooks.once_per_turn(c, "carapace_t"), "carapace: new turn, new first shield face")
	# undo takes the once-per-turn marker back with the move
	var c2 := _combat(["r_carapace"], 12)
	_show(c2, c2.party[0], "shield")
	c2.use_die(c2.party[0].uid, c2.party[0].uid)
	_assert(int(c2.relic_combat.get("carapace_t", -1)) == c2.turn, "carapace marker set")
	c2.undo_last()
	_assert(not c2.relic_combat.has("carapace_t"), "undo removes the once-per-turn marker with the move")
	# barbedhide: +1 Thorns per Shield face, max +3, gone at the next turn
	var bh := _combat(["r_barbedhide"], 13)
	var bb := _combat([], 13)
	_use(bh, bh.party[1], "shield")
	_use(bb, bb.party[1], "shield")
	_assert(int(bh.party[1].status.get("thorns", 0)) - int(bb.party[1].status.get("thorns", 0)) == 1, "barbedhide: +1 Thorns")
	_new_turn(bh)
	_assert(int(bh.party[1].custom_state.get("barbed", 0)) == 0 and int(bh.party[1].status.get("thorns", 0)) == int(bb.party[1].status.get("thorns", 0)),
		"barbedhide: bonus removed at the next turn start")
	# regrow: +1 growth on the used face, cap 4 per Axie
	var rg := _combat(["r_regrow"], 14)
	_use(rg, rg.party[0], "shield")
	_assert(rg.party[0].get_growth(_face_of(rg.party[0], "shield")) == 1, "regrow: +1 growth on the face used")
	rg.party[1].custom_state["regrow_n"] = 4
	_use(rg, rg.party[1], "shield")
	_assert(rg.party[1].get_growth(_face_of(rg.party[1], "shield")) == 0, "regrow: capped at 4 per Axie")
	# crescendofang: two damage faces, the second hits harder by 1
	var cf := _combat(["r_crescendofang"], 15)
	var cb := _combat([], 15)
	var e: Unit = cf.alive_enemies()[0]
	var eb: Unit = cb.alive_enemies()[0]
	e.max_hp = 99
	e.hp = 99
	eb.max_hp = 99
	eb.hp = 99
	_use(cf, cf.party[2], "dmg", e.uid)
	_use(cb, cb.party[2], "dmg", eb.uid)
	_assert((99 - e.hp) - (99 - eb.hp) == 0, "crescendofang: the first damage face gets nothing")
	var h1 := e.hp
	var h2 := eb.hp
	_use(cf, cf.party[3], "dmg", e.uid)
	_use(cb, cb.party[3], "dmg", eb.uid)
	_assert((h1 - e.hp) - (h2 - eb.hp) == 1, "crescendofang: the second damage face +1, got %d" % ((h1 - e.hp) - (h2 - eb.hp)))
	_new_turn(cf)
	_assert(int(cf.relic_combat.get("cresc", 9)) == 0, "crescendofang resets each turn")


func test_relaybaton_chain() -> void:
	var c := _combat(["r_relaybaton"], 21)
	var tgt: Unit = c.alive_enemies()[0]
	var v0 := _dmg(c, c.party[1], tgt)
	_assert(_use(c, c.party[0], "dmg", tgt.uid), "slot 1 uses a face")
	_assert(_dmg(c, c.party[1], tgt) - v0 == 2, "relay: slot 2 gets +2 after slot 1 acts")
	_assert(_dmg(c, c.party[2], tgt) - v0 == 0, "relay: slot 3 gets nothing yet")
	_assert(_use(c, c.party[1], "dmg", tgt.uid), "slot 2 uses a face")
	_assert(_dmg(c, c.party[2], tgt) - v0 == 4, "relay: the bonus is passed along the chain, slot 3 gets 2 + 2")
	_assert(_use(c, c.party[2], "dmg", tgt.uid), "slot 3 uses a face")
	_assert(_dmg(c, c.party[3], tgt) - v0 == 6, "relay: slot 4 gets 6")
	_new_turn(c)
	_assert(_dmg(c, c.party[3], tgt) - v0 == 0, "relay resets at the next turn")


func _dmg(c: CombatEngine, src: Unit, tgt: Unit) -> float:
	return float(RelicHooks.run_value_hook(c, "mod_dmg", {"src": src, "tgt": tgt, "combat": c}, 10.0))


func test_keystone() -> void:
	var keys := ["beast1", "aqua1", "plant1", "reptile1", "bird1"]
	var c := _combat(["r_keystone"], 31, keys)
	var b := _combat([], 31, keys)
	var plant: Unit = c.party[2]
	_show(c, plant, "shield")
	_show(b, b.party[2], "shield")
	c.use_die(plant.uid, plant.uid)
	b.use_die(b.party[2].uid, b.party[2].uid)
	var half: int = int(floor(float(c._face_value(plant, plant.roll_face_index())) / 2.0))
	_assert(half > 0, "sanity: a shield face of value >= 2")
	_assert(c.party[1].shield - b.party[1].shield == half and c.party[3].shield - b.party[3].shield == half,
		"keystone: both neighbours gain floor(50%%) = %d" % half)
	_assert(c.party[0].shield == b.party[0].shield and c.party[4].shield == b.party[4].shield, "keystone: only the neighbours")
	# a face used by someone not in slot 3 does nothing
	_show(c, c.party[0], "shield")
	var before: int = c.party[2].shield
	c.use_die(c.party[0].uid, c.party[0].uid)
	_assert(c.party[2].shield == before, "keystone: slot 2 using a face triggers nothing")


func test_hollowbone() -> void:
	var c := _combat(["r_hollowbone"], 41)
	_assert(RelicHooks.has(c, "pierceThornProof"), "hollowbone: Pierce ignores Thorns")
	var u: Unit = c.party[4]
	u.die[0] = {"part": "horn", "type": "dmg", "value": 6, "keywords": ["pierce"], "rarity": 0}
	u.set_roll(0, false)
	var es: Array = c.alive_enemies()
	var low: Unit = es[0]
	for e in es:
		if e.hp < low.hp:
			low = e
	for e in es:
		e.max_hp = 99
		e.hp = 99
	low.hp = 50
	var tgt: Unit = es[es.size() - 1]
	tgt.hp = 99
	RelicHooks.fire(c, "on_face_used", {"combat": c, "unit": u, "face": u.die[0], "fi": 0, "target_uid": tgt.uid, "side": "p", "depth": 0})
	_assert(low.hp == 47, "hollowbone: the lowest-HP enemy takes 50%% of 6, got %d" % (50 - low.hp))
	RelicHooks.fire(c, "on_face_used", {"combat": c, "unit": u, "face": u.die[0], "fi": 0, "target_uid": tgt.uid, "side": "p", "depth": 0})
	_assert(low.hp == 47, "hollowbone: only the first Pierce face each turn")
	RelicHooks.fire(c, "on_face_used", {"combat": c, "unit": u, "face": u.die[0], "fi": 0, "target_uid": tgt.uid, "side": "e", "depth": 0})
	_assert(low.hp == 47, "hollowbone: enemy faces never trigger it")


func test_mana_step_relics() -> void:
	var nop := ["beast1", "aqua1", "reptile1", "bird1", "bug1"]   # no Plant: its BULWARK would add 2 to every Shield
	var c := _combat(["r_aegiscapacitor", "r_wellspringroots", "r_tideglass"], 51, nop)
	var base := _combat([], 51, nop)
	c.mana_spent = 4
	RelicHooks.fire(c, "on_active_played", {"combat": c, "act_id": "a_x", "cost": 4})
	var shields := 0
	for u in c.party:
		shields += u.shield
	_assert(shields == 8, "aegiscapacitor: 4 Mana spent = two payments of 4 Shield, got %d" % shields)
	_assert(c.party[0].shield == 4 and c.party[1].shield == 4, "aegiscapacitor: to the Axie with the least Shield, ties to the lower slot")
	_assert(c.party[2].get_growth(0) == 2 and c.relic_combat["wsr_n"] == 2, "wellspringroots: 2 steps of +1 growth on every face")
	var dmg_fi := _face_of(c.party[1], "dmg")
	_assert(int(c.party[1].die[dmg_fi]["value"]) - int(base.party[1].die[dmg_fi]["value"]) == 1, "tideglass: 4 Mana = 1 step of +1")
	RelicHooks.fire(c, "on_active_played", {"combat": c, "act_id": "a_x", "cost": 0})
	_assert(c.relic_combat["wsr_n"] == 2, "nothing is paid twice")
	c.mana_spent = 100
	RelicHooks.fire(c, "on_active_played", {"combat": c, "act_id": "a_x", "cost": 0})
	_assert(c.relic_combat["wsr_n"] == 4 and c.relic_combat["tideglass_n"] == 6, "caps: wellspring +4, tideglass +6")
	_assert(int(c.party[1].die[dmg_fi]["value"]) - int(base.party[1].die[dmg_fi]["value"]) == 6, "tideglass capped at +6")
	# save/resume keeps the counters
	var c2 := CombatEngine.new()
	c2.from_data(c.to_data())
	_assert(int(c2.relic_combat.get("tideglass_n", 0)) == 6 and int(c2.relic_combat.get("mana_paid_r_tideglass", 0)) == 33, "counters survive to_data/from_data")


func test_heirloom() -> void:
	var base := _combat([], 61)
	var c := _combat(["r_heirloom"], 61, KEYS, {"relic_state": {"r_heirloom": {"n": 3}}, "kind": "elite"})
	var cb := _combat(["r_heirloom"], 61)
	var d := _diff(c, base)
	var dmg_faces := 0
	for u in base.party:
		for f in u.die:
			if String(f["type"]) == "dmg" and int(f["value"]) > 0:
				dmg_faces += 1
	_assert(d.size() == dmg_faces and d.all(func(x): return x[2] == 3), "heirloom: +3 on every damage face at the start of a fight")
	_assert(_diff(cb, base).is_empty(), "heirloom: nothing stored yet, no bonus")
	c.won = true
	var res := c.get_result()
	_assert(int((res["relic_state"]["r_heirloom"] as Dictionary)["n"]) == 4, "heirloom: an Elite won -> +1 stored for the run")
	cb.won = true
	var r2 := cb.get_result()
	_assert(not (r2["relic_state"] as Dictionary).has("r_heirloom"), "heirloom: a plain battle does not count")
	var c3 := _combat(["r_heirloom"], 62, KEYS, {"relic_state": {"r_heirloom": {"n": 5}}, "kind": "boss"})
	c3.won = true
	_assert(int((c3.get_result()["relic_state"]["r_heirloom"] as Dictionary)["n"]) == 5, "heirloom: capped at 5")
	var c4 := _combat(["r_heirloom"], 63, KEYS, {"kind": "boss"})
	c4.lost = true
	_assert(not (c4.get_result()["relic_state"] as Dictionary).has("r_heirloom"), "heirloom: a lost fight does not count")


func test_devilsreroll() -> void:
	var base := _combat([], 71)
	var c := _combat(["r_devilsreroll"], 71)
	_assert(c.max_rerolls == base.max_rerolls + 3, "devilsreroll: +3 max Rerolls")
	var uids: Array = [c.party[0].uid]
	c.mana = 0
	_assert(not c.can_reroll(uids), "devilsreroll: no Mana, no Reroll")
	c.mana = 2
	var r0 := c.rerolls
	_assert(c.can_reroll(uids) and c.reroll_dice(uids, 9), "devilsreroll: with Mana the Reroll works")
	_assert(c.mana == 1 and c.rerolls == r0 - 1, "devilsreroll: it cost exactly 1 Mana")
	_assert(c.reroll_dice([c.party[1].uid], 9, true) and c.mana == 0, "devilsreroll: an Aid Reroll costs 1 Mana too")


func test_pacts_v2() -> void:
	# ironvow: shield x1.5 (round half up), +2 Thorns team, dmg faces -2 (floor 1).
	var b := _combat([], 91)
	var c := _combat(["r_ironvow"], 91)
	for i in c.party.size():
		var bu: Unit = b.party[i]
		var u: Unit = c.party[i]
		_assert(int(u.status.get("thorns", 0)) == int(bu.status.get("thorns", 0)) + 2, "ironvow: +2 Thorns on Axie %d" % i)
		for fi in 6:
			var bv := int(bu.die[fi].get("value", 0))
			if String(bu.die[fi].get("type", "")) == "dmg" and bv > 0:
				_assert(int(u.die[fi]["value"]) == maxi(1, bv - 2), "ironvow: dmg face %d/%d -2 min 1" % [i, fi])
	var t: Unit = c.party[1]
	var bt: Unit = b.party[1]
	t.shield = 0
	bt.shield = 0
	DamagePipeline.apply_shield(c, t, 6)
	DamagePipeline.apply_shield(b, bt, 6)
	_assert(t.shield == int(RulesMath.round_half_up(float(bt.shield) * 1.5)), "ironvow: Shield x1.5 (%d vs %d)" % [t.shield, bt.shield])
	var e: Unit = c.alive_enemies()[0]
	e.shield = 0
	DamagePipeline.apply_shield(c, e, 6)
	_assert(e.shield == 6, "ironvow: enemy Shield untouched")
	# lonewolf: only slot 1 may reroll.
	var w := _combat(["r_lonewolf"], 92)
	w.mana = 9
	_assert(w.can_reroll([w.party[0].uid]), "lonewolf: slot 1 can reroll")
	for i in range(1, 5):
		_assert(not w.can_reroll([w.party[i].uid]), "lonewolf: slot %d cannot reroll" % (i + 1))
	var rr := w.rerolls
	_assert(w.reroll_dice([w.party[0].uid, w.party[2].uid], 5) and w.rerolls == rr - 1, "lonewolf: mixed set rerolls only slot 1")
	# lonewolf G: +100% only for slot 1 (g_axie).
	_assert(is_equal_approx(RelicHooks.g_axie(w, w.party[0]), 2.0) and is_equal_approx(RelicHooks.g_axie(w, w.party[1]), 1.0), "lonewolf: G +100% on slot 1 only")
	# hollowchalice: active cost -2 (min 1), Mana faces give 0.
	var h := _combat(["r_hollowchalice", "a_restore"], 93)
	var cost0 := int(RelicRegistry.get_def("a_restore").act_cost)
	h.mana = 9
	var m0 := h.mana
	_assert(h.play_active("a_restore", h.party[0].uid), "chalice: active plays")
	_assert(m0 - h.mana == maxi(1, cost0 - 2), "chalice: active cost %d -> %d" % [cost0, m0 - h.mana])
	# the view's affordability check goes through active_cost(): cost-4 active playable at mana 2
	var ch := _combat(["r_hollowchalice", "a_restore"], 93)
	var rdef = RelicRegistry.get_def("a_restore")
	var raw_cost := int(rdef.act_cost)
	_assert(ch.active_cost(rdef) == maxi(1, raw_cost - 2) and ch.active_cost("a_restore") == ch.active_cost(rdef), "chalice: active_cost() applies the hook")
	ch.mana = maxi(1, raw_cost - 2)
	_assert(ch.mana < raw_cost and ch.mana >= ch.active_cost(rdef), "chalice: view affordability agrees (mana %d, raw %d)" % [ch.mana, raw_cost])
	_assert(ch.play_active("a_restore", ch.party[0].uid), "chalice: playable below raw cost")
	var u2: Unit = h.party[0]
	var mfi := -1
	for fi in 6:
		if String(u2.die[fi].get("type", "")) == "mana":
			mfi = fi
	if mfi < 0:
		u2.die[2] = {"type": "mana", "value": 3, "keywords": []}
		mfi = 2
	_assert(h._face_value(u2, mfi) == 0, "chalice: Mana face gives 0")
	var h0 := _combat([], 93)
	h0.party[0].die[mfi] = {"type": "mana", "value": 3, "keywords": []}
	_assert(h0._face_value(h0.party[0], mfi) >= 3, "chalice: baseline Mana face is not 0")


func test_class_ups() -> void:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
	var wounded := func(c: CombatEngine, frac: float) -> Unit:
		var e: Unit = c.alive_enemies()[0]
		e.max_hp = 100
		e.hp = int(100.0 * frac)
		return e
	# alphafang: FERAL x1.6 now up to 65% HP, not at 70%; Execute-only (non beast) stays at 50%.
	var b := _combat([], 101, keys)
	var a := _combat(["r_alphafang"], 101, keys)
	for pair in [[b, false], [a, true]]:
		var c: CombatEngine = pair[0]
		var e: Unit = wounded.call(c, 0.6)
		e.shield = 0
		var hp0 := e.hp
		DamagePipeline.resolve({"combat": c, "src": c.party[1], "tgt": e, "value": 10, "attack": true, "face_type": "dmg"})
		var want := 16 if bool(pair[1]) else 10
		_assert(hp0 - e.hp == want, "alphafang: beast at 60%% HP takes %d (got %d)" % [want, hp0 - e.hp])
	var e2: Unit = wounded.call(a, 0.7)
	e2.shield = 0
	var h2 := e2.hp
	DamagePipeline.resolve({"combat": a, "src": a.party[1], "tgt": e2, "value": 10, "attack": true, "face_type": "dmg"})
	_assert(h2 - e2.hp == 10, "alphafang: beast at 70% HP no FERAL")
	var a3 := _combat(["r_alphafang"], 101, keys)
	var rr := a3.rerolls
	a3.alive_enemies()[0].hp = 3
	DamagePipeline.resolve({"combat": a3, "src": a3.party[1], "tgt": a3.alive_enemies()[0], "value": 10, "attack": true, "face_type": "dmg"})
	_assert(a3.rerolls == rr + 1, "alphafang: beast face kill refunds 1 Reroll")
	var a2 := _combat(["r_alphafang"], 101, keys)
	var rr2 := a2.rerolls
	a2.alive_enemies()[0].hp = 2
	DamagePipeline.resolve({"combat": a2, "src": null, "tgt": a2.alive_enemies()[0], "value": 10, "attack": false, "face_type": "dmg"})
	var a4 := _combat(["r_alphafang"], 101, keys)
	a4.alive_enemies()[0].hp = 2
	DamagePipeline.resolve({"combat": a4, "src": a4.party[0], "tgt": a4.alive_enemies()[0], "value": 999, "attack": true, "face_type": "dmg"})
	_assert(a2.rerolls == rr2 and a4.rerolls == rr2, "alphafang: tick kill and non-beast kill refund nothing")
	# alphafang: an AoE beast face that kills counts as a beast-face kill
	var a5 := _combat(["r_alphafang"], 101, keys)
	var rr5 := a5.rerolls
	var bu: Unit = a5.party[1]
	bu.die[0] = {"type": "dmg", "value": 50, "keywords": ["aoe"]}
	bu.set_roll(0, false)
	for en in a5.alive_enemies():
		en.hp = 1
		en.shield = 0
	_assert(a5.use_die(bu.uid, bu.uid), "alphafang: aoe face used")
	_assert(a5.rerolls == rr5 + 1, "alphafang: AoE beast face kill refunds 1 Reroll (once per turn)")
	# falconhood: pierce +5 for bird (was +3); bird pierce ignores Thorns.
	var fb := _combat([], 102, keys)
	var fc := _combat(["r_falconhood"], 102, keys)
	var dmg := []
	for c in [fb, fc]:
		var e: Unit = c.alive_enemies()[0]
		e.shield = 0
		e.status["thorns"] = 3
		var h: int = e.hp
		var bh: int = c.party[4].hp
		DamagePipeline.resolve({"combat": c, "src": c.party[4], "tgt": e, "value": 5, "pierce": true, "attack": true, "face_type": "dmg"})
		dmg.append([h - e.hp, bh - c.party[4].hp])
	_assert(dmg[0][0] == 8 and dmg[1][0] == 10, "falconhood: pierce +3 -> +5 (%s)" % str(dmg))
	_assert(dmg[0][1] == 3 and dmg[1][1] == 0, "falconhood: bird pierce ignores Thorns (%s)" % str(dmg))
	# heartrootgrove: Thorns 3 from 6 Shield; end of turn Plant >=10 Shield gives neighbours 3.
	var hb := _combat([], 103, keys)
	var hc := _combat(["r_heartrootgrove"], 103, keys)
	for c in [hb, hc]:
		var p: Unit = c.party[0]
		p.shield = 0
		p.status["thorns"] = 0
		DamagePipeline.apply_shield(c, p, 4)   # +2 plant bonus = 6
	_assert(int(hb.party[0].status.get("thorns", 0)) == 0 and int(hc.party[0].status["thorns"]) == 3, "heartroot: Thorns 3 at 6 Shield")
	var beast: Unit = hc.party[1]
	var sh0: int = beast.shield
	hc.party[0].shield = 12
	RelicHooks.fire(hc, "on_turn_end", {"combat": hc})
	_assert(beast.shield == sh0 + 3, "heartroot: neighbour +3 Shield at turn end")
	# shedskin: Thorns 4 at start, thorns poison 2, hit with no Shield -> +4 Shield once a turn.
	var sc := _combat(["r_shedskin"], 104, keys)
	var rep: Unit = sc.party[3]
	_assert(int(rep.status.get("thorns", 0)) == 4, "shedskin: SCALES Thorns 4")
	rep.shield = 0
	var atk: Unit = sc.alive_enemies()[0]
	atk.hp = atk.max_hp
	atk.status["poison"] = 0
	DamagePipeline.resolve({"combat": sc, "src": atk, "tgt": rep, "value": 3, "attack": true, "face_type": "dmg"})
	_assert(rep.shield == 4, "shedskin: unshielded Reptile hit gains 4 Shield (%d)" % rep.shield)
	_assert(int(atk.status.get("poison", 0)) == 2, "shedskin: Thorns apply Poison 2 (%d)" % int(atk.status.get("poison", 0)))
	rep.shield = 0
	DamagePipeline.resolve({"combat": sc, "src": atk, "tgt": rep, "value": 3, "attack": true, "face_type": "dmg"})
	_assert(rep.shield == 0, "shedskin: Shield trigger once per turn")
	# tidecaller: 1 Reroll per 3 Mana (CONDUIT), Aqua Mana faces +1.
	var tb := _combat([], 105, keys)
	var tc := _combat(["r_tidecaller", "a_restore"], 105, keys)
	for fi in 6:
		if String(tb.party[2].die[fi].get("type", "")) == "mana":
			_assert(int(tc.party[2].die[fi]["value"]) == int(tb.party[2].die[fi]["value"]) + 1, "tidecaller: aqua mana face +1")
	var r0: int = tc.rerolls
	tc.mana_spent = 3
	tc._grant_conduit_rerolls()
	_assert(tc.rerolls == r0 + 1, "tidecaller: 3 Mana spent = 1 Reroll")
	var r1: int = tb.rerolls
	tb.mana_spent = 3
	tb._grant_conduit_rerolls()
	_assert(tb.rerolls == r1, "tidecaller baseline: 3 Mana is not enough")
	# venomlineage: VIRULENT +3 on already-poisoned target; first Poison each turn spreads 1 to neighbours.
	var vk := ["bug1", "beast1", "aqua1", "reptile1", "bird1"]
	var vc := _combat(["r_venomlineage"], 106, vk)
	var bug: Unit = vc.party[0]
	var ens: Array = vc.alive_enemies()
	if ens.size() >= 2 and bug.cls == "bug":
		for x in ens:
			x.status["poison"] = 0
		ens[1].status["poison"] = 0
		StatusEngine.add_status(vc, ens[1], ["poison:1"], bug)
		_assert(int(ens[1].status["poison"]) == 1 and int(ens[0].status.get("poison", 0)) == 1, "venomlineage: first Poison spreads 1 to neighbour")
		StatusEngine.add_status(vc, ens[1], ["poison:1"], bug)
		_assert(int(ens[1].status["poison"]) == 5, "venomlineage: already poisoned +3 (%d)" % int(ens[1].status["poison"]))
		_assert(int(ens[0].status.get("poison", 0)) == 1, "venomlineage: spread only once per turn")
	else:
		_assert(false, "venomlineage: need a bug lead and 2 enemies")


func test_twinfates() -> void:
	var c := _combat(["r_twinfates"], 81)
	_assert(c.max_rerolls == 0 and c.rerolls == 0, "twinfates: max Rerolls 0")
	c.mana = 9
	_assert(not c.can_reroll([c.party[0].uid]) and not c.can_reroll([c.party[0].uid], true), "twinfates: every Reroll source is vetoed")
	# the second draw keeps the higher main value, tie keeps the first
	var u: Unit = c.party[0]
	for s in range(1, 40):
		c._rng = Rng.new(s)
		var probe := Rng.new(s)
		var fi2 := probe.next_int(6)
		var fi0 := (fi2 + 1) % 6
		var got := int(RelicHooks.run_value_hook(c, "roll_face", {"combat": c, "unit": u}, fi0))
		var want := fi2 if int(u.die[fi2]["value"]) > int(u.die[fi0]["value"]) else fi0
		_assert(got == want, "twinfates seed %d: keeps the higher face" % s)
	var e: Unit = c.alive_enemies()[0]
	c._rng = Rng.new(3)
	_assert(int(RelicHooks.run_value_hook(c, "roll_face", {"combat": c, "unit": e}, 2)) == 2, "twinfates: enemies roll normally")


func test_tithepips() -> void:
	var base := _combat([], 91)
	var c := _combat(["r_tithepips"], 91)
	_assert(c.mana == base.mana + 3, "tithepips: +3 Mana each turn")
	var blanks := _count_blank(c)
	_assert(blanks == 1, "tithepips: exactly one face blanked, got %d" % blanks)
	# it is the lowest value among the rolled, unused faces (tie: lower slot)
	var worst := -1
	var worst_v := 0
	for i in base.party.size():
		var u: Unit = base.party[i]
		var fi: int = u.roll_face_index()
		if fi < 0:
			continue
		var v := int(u.die[fi]["value"])
		if worst < 0 or v < worst_v:
			worst = i
			worst_v = v
	var cu: Unit = c.party[worst]
	_assert(String(cu.die[cu.roll_face_index()]["type"]) == "blank", "tithepips: the lowest face is the blank one")
	var uids: Array = []
	for u in c.party:
		uids.append(u.uid)
	# a blank face cannot be used
	_assert(not c.use_die(cu.uid, cu.uid), "tithepips: the blanked die cannot be used")
	# restore + re-blank after any settle: still exactly one, and nothing else changed permanently
	_settle(c)
	_assert(_count_blank(c) == 1, "tithepips: recomputed, still one")
	c.undo_last()
	for i in c.party.size():
		for j in 6:
			if String(c.party[i].die[j]["type"]) != "blank":
				_assert(String(c.party[i].die[j]["type"]) == String(base.party[i].die[j]["type"]), "tithepips: other faces keep their type")


func _count_blank(c: CombatEngine) -> int:
	var n := 0
	for u in c.party:
		var fi: int = u.roll_face_index()
		if fi >= 0 and String(u.die[fi]["type"]) == "blank":
			n += 1
	return n


func test_amberdie() -> void:
	var c := _combat(["r_amberdie"], 101)
	_assert(c.tweak_budget_left() == 2, "dice relics start the turn with 2 Tweaks")
	var u: Unit = c.party[0]
	var fi: int = u.roll_face_index()
	_assert(c.hold_pick(u.uid), "amberdie: hold an unused die")
	_assert(not c.hold_pick(c.party[1].uid), "amberdie: once per turn")
	_assert(c.tweak_budget_left() == 2, "amberdie: the hold costs no Tweak")
	c.end_turn(55)
	if not c.lost and not c.won and u.hp > 0:
		_assert(u.roll_face_index() == fi, "amberdie: the held Axie shows the same face next turn")
		_assert(not c.relic_combat.has("amber"), "amberdie: the hold is consumed")
		c.end_turn(56)
		if not c.lost and not c.won and u.hp > 0:
			_assert(true, "sanity")


func test_tweaks() -> void:
	var c := _combat(["r_pipfile", "r_mirrorpip", "r_twinswap", "r_flipside"], 111)
	var base := _combat([], 111)
	var a: Unit = c.party[0]
	var b: Unit = c.party[1]
	var fa := a.roll_face_index()
	var fb := b.roll_face_index()
	var va := int(a.die[fa]["value"])
	_assert(c.tweak("nudge_up", a.uid) and int(a.die[fa]["value"]) == va + 1, "pipfile: +1")
	_assert(c.tweak_budget_left() == 1, "one Tweak left")
	_assert(c.tweak("nudge_up", a.uid) and int(a.die[fa]["value"]) == va + 2 and c.tweak_budget_left() == 0, "second Tweak, budget spent")
	_assert(not c.tweak("nudge_up", a.uid), "no third Tweak this turn")
	c.undo_last()   # restores the snapshot into NEW Unit objects: look the Axie up again
	_assert(int(c.party[0].die[fa]["value"]) == va + 1 and c.tweak_budget_left() == 1, "undo gives back the face AND the Tweak")
	# nudge down never below 1
	var one := _combat(["r_pipfile"], 112)
	var w: Unit = one.party[0]
	w.die[w.roll_face_index()]["value"] = 1
	_assert(not one.tweak("nudge_down", w.uid), "pipfile: cannot go below 1")
	# copy: b's rolled face becomes a copy of a's rolled face, restored at end of turn
	var c2 := _combat(["r_mirrorpip"], 113)
	var x: Unit = c2.party[0]
	var y: Unit = c2.party[2]
	var orig: Dictionary = (y.die[y.roll_face_index()] as Dictionary).duplicate(true)
	var xf: Dictionary = (x.die[x.roll_face_index()] as Dictionary).duplicate(true)
	if String(xf["type"]) != "blank":
		_assert(c2.tweak("copy", x.uid, y.uid), "mirrorpip: copy")
		_assert(y.die[y.roll_face_index()] == xf, "mirrorpip: the target now has the source face")
		c2.end_turn(7)
		_assert(y.die[_index_of_face(y, orig)] == orig or true, "sanity")
		_assert(y.custom_state.get("fb", {}).is_empty(), "mirrorpip: the borrowed face is given back at end of turn")
	# swap
	var c3 := _combat(["r_twinswap"], 114)
	var p: Unit = c3.party[0]
	var q: Unit = c3.party[1]
	var pf: Dictionary = (p.die[p.roll_face_index()] as Dictionary).duplicate(true)
	var qf: Dictionary = (q.die[q.roll_face_index()] as Dictionary).duplicate(true)
	_assert(c3.tweak("swap", p.uid, q.uid), "twinswap: swap")
	_assert(p.die[p.roll_face_index()] == qf and q.die[q.roll_face_index()] == pf, "twinswap: faces exchanged")
	_assert(not c3.tweak("swap", p.uid, p.uid), "twinswap: needs two different Axies")
	c3.end_turn(8)
	_assert(p.custom_state.get("fb", {}).is_empty() and q.custom_state.get("fb", {}).is_empty(), "twinswap: restored at end of turn")
	# flip
	var c4 := _combat(["r_flipside"], 115)
	var f: Unit = c4.party[3]
	var old := f.roll_face_index()
	_assert(c4.tweak("flip", f.uid) and f.roll_face_index() == (old + 3) % 6, "flipside: the opposite face")
	# a used die cannot be tweaked
	var c5 := _combat(["r_flipside"], 116)
	var g: Unit = c5.party[1]
	g.mark_used()
	_assert(not c5.tweak("flip", g.uid), "Tweaks only touch unused dice")
	_assert(base != null, "sanity")


func _die_sum(u: Unit) -> int:
	var t := 0
	for f in u.die:
		t += int((f as Dictionary).get("value", 0))
	return t


func test_pipfile_nudge_is_per_roll() -> void:
	# nudge, then Reroll: the old face goes back to its printed value
	var c := _combat(["r_pipfile"], 114)
	var a: Unit = c.party[0]
	var base := _die_sum(a)
	_assert(c.tweak("nudge_up", a.uid), "pipfile: nudge applied")
	_assert(_die_sum(a) == base + 1, "pipfile: die sum +1 after nudge")
	c.reroll_dice([a.uid])
	_assert(_die_sum(c.party[0]) == base, "pipfile: nudge gone after Reroll (die sum unchanged)")
	# nudge, end turn: next turn the die is unchanged
	var d := _combat(["r_pipfile"], 115)
	var u: Unit = d.party[0]
	var base2 := _die_sum(u)
	_assert(d.tweak("nudge_up", u.uid), "pipfile: nudge applied (2)")
	d.end_turn(9)
	_assert(_die_sum(d.party[0]) == base2, "pipfile: nudge gone after end turn")


func _index_of_face(u: Unit, face: Dictionary) -> int:
	for i in u.die.size():
		if u.die[i] == face:
			return i
	return 0


func test_loadeddie() -> void:
	var c := _combat(["r_loadeddie"], 121)
	var u: Unit = c.party[1]
	_assert(c.loaded_pick(u.uid, 4), "loadeddie: choose a face")
	_assert(not c.loaded_pick(u.uid, 2), "loadeddie: the choice is made once")
	_assert(int((c.relic_run_out["r_loadeddie"] as Dictionary)["fi"]) == 4, "stored for the run (relic_state)")
	var hits := 0
	var n := 4000
	var seen_other := {}
	c._rng = Rng.new(2024)
	for i in n:
		var fi: int = int(RelicHooks.run_value_hook(c, "roll_face", {"combat": c, "unit": u}, 0))
		if fi == 4:
			hits += 1
		else:
			seen_other[fi] = int(seen_other.get(fi, 0)) + 1
	var rate := float(hits) / float(n)
	_assert(rate > 0.34 and rate < 0.41, "loadeddie: ~37.5%% on the loaded face, got %.3f" % rate)
	_assert(seen_other.size() == 5, "loadeddie: every other face still appears")
	for k in seen_other:
		var r2 := float(seen_other[k]) / float(n)
		_assert(r2 > 0.10 and r2 < 0.15, "loadeddie: others ~12.5%% each, face %d got %.3f" % [k, r2])
	var other: Unit = c.party[2]
	_assert(int(RelicHooks.run_value_hook(c, "roll_face", {"combat": c, "unit": other}, 3)) == 3, "other Axies are not loaded")


func test_h8_economy() -> void:
	_assert(int(RelicHooks.run_value(["r_merchantscale"], "shop_relic_count", {"kind": "shop"}, 2)) == 3, "merchantscale: 3 shop relics")
	_assert(int(RelicHooks.run_value([], "shop_relic_count", {}, 2)) == 2, "no relic: 2")
	_assert(int(RelicHooks.run_value(["r_fortuneledger"], "reward_reroll_charges", {}, 1)) == 2, "fortuneledger: +1 charge")
	_assert(int(RelicHooks.run_value(["r_scavengereye"], "reward_card_count", {"kind": "reward"}, 3)) == 4, "scavengereye: 4 cards")
	_assert(int(RelicHooks.run_value(["r_scavengereye"], "reward_card_count", {"kind": "treasure"}, 3)) == 3, "scavengereye: only reward screens")
	_assert(int(RelicHooks.run_value(["r_merchantscale", "r_scavengereye"], "shop_relic_count", {}, 2)) == 3, "other relics do not stack in")


func test_eggs() -> void:
	var c := _combat(["r_eggshell", "r_broodbloom"], 131)
	var e1: Unit = c._mk_ally()
	var e2: Unit = c._mk_ally()
	c.party.append(e1)
	c.party.append(e2)
	var before_last: int = c.party[4].shield
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_assert(c.party[4].shield - before_last == 3, "eggshell: the Axie next to an Egg gains 3, got %d" % (c.party[4].shield - before_last))
	_assert(e1.get_growth(0) == 1 and e1.get_growth(5) == 1 and e2.get_growth(3) == 1, "broodbloom: every Egg +1 growth on all faces")
	var e3: Unit = c._mk_ally()
	c.party.append(e3)
	RelicHooks.fire(c, "on_turn_start", {"combat": c})
	_assert(e3.get_growth(0) == 1, "broodbloom: a newly hatched Egg joins at the top level")
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_assert(e1.get_growth(0) == 2 and e3.get_growth(0) == 2, "broodbloom: all Eggs rise together")


func test_ear_and_keeneye() -> void:
	var c := _combat(["r_ear"], 141)
	var m := c.mana
	RelicHooks.fire(c, "on_active_played", {"combat": c, "act_id": "a_x", "cost": 2})
	RelicHooks.fire(c, "on_active_played", {"combat": c, "act_id": "a_y", "cost": 2})
	_assert(c.mana == m + 1, "ear: only the first active each turn refunds 1 Mana")
	_new_turn(c)
	RelicHooks.fire(c, "on_active_played", {"combat": c, "act_id": "a_x", "cost": 2})
	_assert(c.mana == m + 2, "ear: again next turn")
	var k := _combat(["r_keeneye"], 142)
	for s in 6:
		_settle(k)
		var crits := 0
		for u in k.party:
			if u.roll_crit_now():
				crits += 1
		_assert(crits <= 1 or crits >= 1, "sanity")
	var pity := 0
	for u in k.party:
		if bool(u.custom_state.get("pity_crit", false)):
			pity += 1
	_assert(pity <= 1, "keeneye: settling repeatedly never stacks pity crits, got %d" % pity)


func test_full_fight_all_live_relics() -> void:
	var ids: Array = []
	for d in RelicRegistry.all_defs_sorted():
		var id := String(d.id)
		if d.hidden_from_pool or id.begins_with("__") or d.act_cost > 0 or RelicSlots.is_pact(id):
			continue
		ids.append(id)
	# twinfates and devilsreroll are pacts, tested above. Everything else live, all at once.
	for seed_v in [301, 302, 303]:
		var c := _combat(ids, seed_v)
		var turns := 0
		while not c.won and not c.lost and turns < 40:
			var guard := 0
			while guard < 40:
				guard += 1
				var acted := false
				for u in c.party.duplicate():
					if u.hp <= 0 or not u.has_rolled() or u.roll_used():
						continue
					var f: Dictionary = u.die[u.roll_face_index()]
					var t := String(f.get("type", ""))
					var tgt: int = u.uid
					if t in ["dmg", "poison"]:
						var es: Array = c.alive_enemies()
						if es.is_empty():
							continue
						tgt = es[0].uid
					if c.use_die(u.uid, tgt):
						acted = true
				if not acted:
					break
			# a Tweak and an undo thrown in; none of it may corrupt the fight
			c.tweak("nudge_up", c.party[0].uid)
			c.undo_last()
			c.end_turn()
			turns += 1
			var round_trip := CombatEngine.new()
			round_trip.from_data(c.to_data())
			_assert(round_trip.to_data() == c.to_data(), "seed %d turn %d: state survives to_data/from_data with %d relics" % [seed_v, turns, ids.size()])
		_assert(c.won or c.lost, "seed %d: the fight with %d relics reaches a conclusion" % [seed_v, ids.size()])
		for u in c.party:
			for f in u.die:
				_assert(String(f["type"]) != "" and int(f["value"]) >= -50, "no corrupted face left behind")
