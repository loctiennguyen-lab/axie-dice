extends Node
## Cores v5 (design/proposals/cores-rules-v5.md section 10): each Core fires when its condition holds and stays silent when it does not.
const ROSTER := ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
var _fails: Array[String] = []
var _checks := 0
var _log: Array = []


func _ready() -> void:
	EventBus.core_fired.connect(func(id: String, uid: int, amt: int, kind: String): _log.append([id, uid, amt, kind]))
	t_tokens()
	t_k1()
	t_e1()
	t_e2()
	t_b2()
	t_k2()
	t_k3()
	t_b1()
	t_b3()
	t_g1()
	t_g2()
	t_e3()
	if _fails.is_empty():
		print("t_cores_v5: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_cores_v5: FAIL - %s" % f)
	get_tree().quit(1)


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _fired(id: String) -> int:
	var n := 0
	for e in _log:
		if e[0] == id:
			n += int(e[2])
	return n


func _combat(relics: Array, stage: int = 3, anchor: String = "") -> CombatEngine:
	var roster: Array = []
	for i in ROSTER.size():
		roster.append({"persistent_id": i + 1, "hero_key": ROSTER[i], "tier": 1,
			"max_hp": ContentDB.heroes[ROSTER[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var c := CombatEngine.new()
	c.setup_new({"node_id": "t_v5", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": roster,
		"relic_ids": relics, "combat_seed": 4242, "bonus_reroll": 0})
	c.depth_stage = stage
	c.anchor_id = anchor
	for e in c.enemies:
		e.max_hp = 900
		e.hp = 900
		e.plating = 0
	_log.clear()
	return c


func _face(ft: String, v: int, kws: Array = [], part: String = "") -> Dictionary:
	return {"type": ft, "value": v, "keywords": kws, "name": "t", "part": part}


## Put `f` on face 0 of `u`, roll it and really use it.
func _play(c: CombatEngine, u: Unit, f: Dictionary, tgt: int = -1) -> void:
	u.die[0] = f
	u.set_roll(0, false)
	if tgt < 0:
		tgt = c.enemies[0].uid if String(f["type"]) in ["dmg", "poison", "debuff"] else u.uid
	c.use_die(u.uid, tgt)


func t_tokens() -> void:
	var ctx := {"roster": CoreTestUtil.roster(["plant1", "beast1", "aqua1"]), "owned_ids": [], "depth_stage": 1, "anchor_id": "a_kin"}
	_ok(CoreOffer.token_ok("classes_distinct:3", ctx), "classes_distinct:3 true with 3 classes")
	_ok(not CoreOffer.token_ok("classes_distinct:4", ctx), "classes_distinct:4 false with 3 classes")
	_ok(not CoreOffer.token_ok("stage_min:2", ctx), "stage_min:2 false at stage 1")
	ctx["depth_stage"] = 2
	_ok(CoreOffer.token_ok("stage_min:2", ctx), "stage_min:2 true at stage 2")
	_ok(CoreOffer.token_ok("anchor:a_kin", ctx) and not CoreOffer.token_ok("anchor:a_gambler", ctx), "anchor token matches the run anchor")


func t_k1() -> void:
	var c := _combat(["c_bloodline_ward"])
	for k in 5:
		c.party[k].cls = "plant" if k < 3 else "beast"
		c.party[k].shield = 0
	_play(c, c.party[1], _face("shield", 5))
	_ok(c.party[1].shield >= 5, "K1: target got the Shield")
	_ok(c.party[0].shield > 0 and c.party[2].shield > 0, "K1: both same-class neighbours got Shield")
	_ok(c.party[3].shield == 0, "K1: other class gets none")
	_ok(_fired("c_bloodline_ward") > 0, "K1: fired")
	var c2 := _combat(["c_bloodline_ward"])
	for k in 5:
		c2.party[k].cls = "plant" if k % 2 == 0 else "beast"
		c2.party[k].shield = 0
	_play(c2, c2.party[1], _face("shield", 5))
	_ok(c2.party[0].shield == 0 and c2.party[2].shield == 0, "K1: different-class neighbours get none")
	_ok(_fired("c_bloodline_ward") == 0, "K1: silent without same-class neighbours")
	# Shield that is not from a face does not spread
	var c3 := _combat(["c_bloodline_ward"])
	for k in 5:
		c3.party[k].cls = "plant"
		c3.party[k].shield = 0
	DamagePipeline.apply_shield(c3, c3.party[2], 6)
	_ok(c3.party[1].shield == 0 and c3.party[3].shield == 0, "K1: non-face Shield does not spread")


func t_e1() -> void:
	var c := _combat(["c_smoldering"])
	c.party[0].held = true
	c.party[1].held = true
	c.party[2].held = true
	var m0 := c.mana
	RelicHooks.fire(c, "on_turn_end", {"combat": c})
	_ok(c.mana == m0 + 2, "E1: 3 Held dice give +2 (cap), got %d" % (c.mana - m0))
	var c2 := _combat(["c_smoldering"])
	c2.party[0].held = true
	var m2 := c2.mana
	RelicHooks.fire(c2, "on_turn_end", {"combat": c2})
	_ok(c2.mana == m2 + 1, "E1: 1 Held die gives +1")
	var c3 := _combat(["c_smoldering"])
	var m3 := c3.mana
	_log.clear()
	RelicHooks.fire(c3, "on_turn_end", {"combat": c3})
	_ok(c3.mana == m3 and _fired("c_smoldering") == 0, "E1: no Held die, nothing")


func t_e2() -> void:
	var c := _combat(["c_cache_plate"])
	var u: Unit = c.party[1]
	u.shield = 0
	u.die[0] = _face("shield", 7)
	u.set_roll(0, false)
	_ok(c.stash(u.uid), "E2: stash works")
	_ok(u.shield == 4, "E2: Hold a shield 7 gives 4 (half, rounded up), got %d" % u.shield)
	# once per die per turn: undo then re-stash does not stack (state is in the undo snapshot), second stash of the same uid is refused by the state key
	CoreHooks.cache_plate_stash({"combat": c, "unit": u, "face": _face("shield", 7)})
	_ok(u.shield == 4, "E2: at most once per die per turn")
	var c2 := _combat(["c_cache_plate"])
	var u2: Unit = c2.party[0]
	u2.shield = 0
	u2.die[0] = _face("dmg", 7)
	u2.set_roll(0, false)
	c2.stash(u2.uid)
	_ok(u2.shield == 0, "E2: a damage face gets no Shield")
	var c3 := _combat(["c_cache_plate"])
	var u3: Unit = c3.party[1]
	u3.shield = 0
	u3.die[0] = _face("shield", 1)
	u3.set_roll(0, false)
	c3.stash(u3.uid)
	_ok(u3.shield == 2, "E2: minimum 2")


func t_b2() -> void:
	var c := _combat(["c_golden_thread"])
	var base := _combat([])
	_ok(c.wild_cost() == base.wild_cost() - 1, "B2: Wild Face costs 1 less")
	_ok(c.wild_per_battle() == base.wild_per_battle() + 1, "B2: 2 uses per fight")
	var mine := _combat(["c_golden_thread"], 3, "a_mana_mine")
	_ok(mine.wild_cost() == int(CombatEngine.tune_knob("anchor", "mine_wild_cost", 3.0)) - 1, "B2: Mana Mine price 3 -> 2")
	var g := {"part": 0, "size": 4, "uids": [c.party[0].uid, c.party[1].uid, c.party[2].uid, c.party[3].uid], "hi": false, "m100": 220}
	_ok(c.bo_group_m100(g) == 220, "B2: no Wild member, no add")
	c.party[1].wild_slot = 0
	_ok(c.bo_group_m100(g) == 240, "B2: Set of four with a Wild member +0.20")
	var g3 := g.duplicate(true)
	g3["size"] = 3
	_ok(c.bo_group_m100(g3) == 220, "B2: a Set of three gets nothing")
	var def = RelicRegistry.get_def("c_golden_thread")
	_ok(not CoreOffer.is_valid(def, {"owned_ids": [], "roster": CoreTestUtil.roster(), "seen": [], "depth_stage": 1}), "B2: not offered at stage 1")
	_ok(CoreOffer.is_valid(def, {"owned_ids": [], "roster": CoreTestUtil.roster(), "seen": [], "depth_stage": 2}), "B2: offered at stage 2")


func _fell(c: CombatEngine, u: Unit) -> void:
	u.hp = 0
	RelicHooks.fire(c, "on_dmg_taken", {"combat": c, "tgt": u, "src": c.enemies[0], "dealt": 3})


func t_k2() -> void:
	var c := _combat(["c_last_testament"])
	for k in 5:
		c.party[k].cls = "plant" if k < 3 else "beast"
	_fell(c, c.party[0])
	_ok(CoreHooks.flat_total(c, c.party[1], "dmg") == 2, "K2: same-class Axie +2 after a fall")
	_ok(CoreHooks.flat_total(c, c.party[3], "dmg") == 0, "K2: other class gets nothing")
	_fell(c, c.party[0])   # same Axie again: fell_now blocks it
	_ok(CoreHooks.flat_total(c, c.party[1], "dmg") == 2, "K2: the same fall counts once")
	var c2 := _combat(["c_last_testament"])
	for k in 5:
		c2.party[k].cls = "plant"
	for k in 4:
		_fell(c2, c2.party[k])
	_ok(CoreHooks.flat_total(c2, c2.party[4], "dmg") == 6, "K2: capped at +6")
	_ok(_fired("c_last_testament") > 0, "K2: fired")


func t_k3() -> void:
	var c := _combat(["c_melting_pot"])
	var cl := ["plant", "beast", "aqua", "reptile", "bird"]
	for k in 5:
		c.party[k].cls = cl[k]
	var g := {"part": 0, "size": 3, "uids": [c.party[0].uid, c.party[1].uid, c.party[2].uid], "hi": false, "m100": 130}
	_ok(c.bo_group_m100(g) == 155, "K3: all-different classes +0.25")
	c.party[4].cls = "plant"
	_ok(c.bo_group_m100(g) == 130, "K3: two Axies of one class: no bonus")
	var c2 := _combat(["c_melting_pot"])
	for k in 5:
		c2.party[k].cls = cl[k]
	c2.party[3].is_token = true
	c2.party[4].is_token = true
	_ok(c2.bo_group_m100(g) == 155, "K3: Eggs are ignored (3 real classes)")
	var c3 := _combat(["c_melting_pot"])
	for k in 5:
		c3.party[k].is_token = k >= 2
	_ok(c3.bo_group_m100(g) == 130, "K3: under 3 Axies: no bonus")
	var def = RelicRegistry.get_def("c_melting_pot")
	_ok(not CoreOffer.is_valid(def, {"owned_ids": [], "roster": CoreTestUtil.roster(["plant1", "plant1", "aqua1"]), "seen": []}), "K3: not offered with 2 classes")


func t_b1() -> void:
	var c := _combat(["c_hunters_reward"])
	for u in c.party:
		u.shield = 0
		u.cls = "x"
	for k in 5:
		c.party[k].held = false
		c.party[k].set_roll(0 if k < 2 else k, false)
	c._snap_bo()
	c.mana = 5
	RelicHooks.fire(c, "on_reroll_paid", {"combat": c, "cost": 2, "k": 1, "rmode": 1})
	c.party[2].set_roll(0, false)   # the reroll made a Set of three
	RelicHooks.fire(c, "on_roll_settled", {"combat": c, "rerolled_uids": [c.party[2].uid]})
	_ok(c.mana == 7, "B1: fee refunded, got %d" % c.mana)
	_ok(c.party[0].shield == 3 and c.party[2].shield == 3 and c.party[4].shield == 0, "B1: 3 Shield to the Set only")
	c._snap_bo()
	RelicHooks.fire(c, "on_reroll_paid", {"combat": c, "cost": 2, "k": 2, "rmode": 1})
	c.party[3].set_roll(0, false)   # Set of four, but second time this turn
	RelicHooks.fire(c, "on_roll_settled", {"combat": c, "rerolled_uids": [c.party[3].uid]})
	_ok(c.mana == 7, "B1: once per turn")
	var c2 := _combat(["c_hunters_reward"])
	for k in 5:
		c2.party[k].set_roll(k, false)
	c2._snap_bo()
	c2.mana = 5
	RelicHooks.fire(c2, "on_reroll_paid", {"combat": c2, "cost": 2, "k": 1, "rmode": 1})
	RelicHooks.fire(c2, "on_roll_settled", {"combat": c2, "rerolled_uids": [c2.party[1].uid]})
	_ok(c2.mana == 5, "B1: no Set made, no refund")
	var c3 := _combat(["c_hunters_reward"])
	for k in 5:
		c3.party[k].set_roll(0 if k < 2 else k, false)
	c3._snap_bo()
	c3.mana = 5
	c3.party[2].set_roll(0, false)
	RelicHooks.fire(c3, "on_roll_settled", {"combat": c3, "rerolled_uids": []})
	_ok(c3.mana == 5, "B1: a free reroll (no fee) refunds nothing")


func t_b3() -> void:
	var c := _combat(["c_support_hand"])
	for k in 5:
		c.party[k].set_roll(0 if k < 3 else k, false)
	c._snap_bo()
	_ok(CoreHooks.flat_total(c, c.party[0], "shield") == 2, "B3: shield face in a Set of 3 +2")
	_ok(CoreHooks.flat_total(c, c.party[0], "heal") == 2 and CoreHooks.flat_total(c, c.party[0], "mana") == 2, "B3: heal and mana too")
	_ok(CoreHooks.flat_total(c, c.party[0], "dmg") == 0, "B3: damage face gets nothing")
	_ok(CoreHooks.flat_total(c, c.party[4], "shield") == 0, "B3: a die outside the Set gets nothing")


func t_g1() -> void:
	var c := _combat(["c_cracked_glass"])
	var last: Unit = c.enemies[c.enemies.size() - 1]
	var h0: int = last.hp
	c.party[0].cracked = true
	_play(c, c.party[0], _face("dmg", 8))
	_ok(last.hp == h0 - 4 or c.enemies.size() == 1, "G1: shards hit every enemy for 50%% of the face (4), hp %d -> %d" % [h0, last.hp])
	_ok(_fired("c_cracked_glass") > 0, "G1: fired")
	var c2 := _combat(["c_cracked_glass"])
	var l2: Unit = c2.enemies[c2.enemies.size() - 1]
	var h2: int = l2.hp
	_play(c2, c2.party[0], _face("dmg", 8))
	_ok(l2.hp == h2 or c2.enemies.size() == 1, "G1: an intact die sprays nothing")
	_ok(_fired("c_cracked_glass") == 0, "G1: silent without a Crack")
	var c3 := _combat(["c_cracked_glass"])
	for k in 5:
		c3.party[k].cracked = true
		_play(c3, c3.party[k], _face("shield", 8))
	_ok(_fired("c_cracked_glass") > 0, "G1: shield face also sprays")
	var n := 0
	for e in _log:
		if e[0] == "c_cracked_glass" and e[1] == c3.enemies[0].uid:
			n += 1
	_ok(n == 3, "G1: at most 3 sprays a turn, got %d" % n)


func t_g2() -> void:
	var c := _combat(["c_high_roller"], 3, "a_gambler")
	var ids: Array = [c.party[0].uid, c.party[1].uid, c.party[2].uid]
	var out: Array = RelicHooks.run_value_hook(c, "gamble_crack", {"combat": c, "settled": ids, "n": 3}, [c.party[1].uid])
	_ok(out.size() == 3, "G2: one Crack in a Gamble of 3 cracks all")
	out = RelicHooks.run_value_hook(c, "gamble_crack", {"combat": c, "settled": ids.slice(0, 2), "n": 2}, [c.party[1].uid])
	_ok(out.size() == 1, "G2: a Gamble of 2 is unchanged")
	out = RelicHooks.run_value_hook(c, "gamble_crack", {"combat": c, "settled": ids, "n": 3}, [])
	_ok(out.is_empty(), "G2: no Crack stays clean")
	RelicHooks.fire(c, "on_gamble", {"combat": c, "n": 3, "cracked": [], "uids": ids})
	_ok(CoreHooks.flat_total(c, c.party[0], "dmg") == 2 and CoreHooks.flat_total(c, c.party[3], "dmg") == 0, "G2: clean Gamble of 3: +2 to the dice in it only")
	RelicHooks.fire(c, "on_roll_settled", {"combat": c, "rerolled_uids": [c.party[0].uid]})
	_ok(CoreHooks.flat_total(c, c.party[0], "dmg") == 0, "G2: a rerolled die loses the +2")
	var c2 := _combat(["c_high_roller"], 3, "a_gambler")
	RelicHooks.fire(c2, "on_gamble", {"combat": c2, "n": 3, "cracked": [c2.party[0].uid], "uids": ids})
	_ok(CoreHooks.flat_total(c2, c2.party[1], "dmg") == 0, "G2: no +2 when a die Cracked")
	# end to end through reroll_dice with the Crack chance forced
	var tune: Dictionary = ContentDB.combat_tune
	var old = (tune.get("crack", {}) as Dictionary).duplicate()
	(tune["crack"] as Dictionary)["pct"] = 0
	var c3 := _combat(["c_high_roller"], 3, "a_gambler")
	c3.rerolls = 0
	c3.mana = 9
	var u3: Array = [c3.party[0].uid, c3.party[1].uid, c3.party[2].uid]
	var anchor_crack := int(CombatEngine.tune_knob("anchor", "gambler_crack_pct", 40.0))
	(tune["anchor"] as Dictionary)["gambler_crack_pct"] = 0
	var ok3 := c3.reroll_dice(u3, 7, false, 0)
	_ok(ok3 and not c3.party[0].cracked and CoreHooks.flat_total(c3, c3.party[0], "dmg") == 2, "G2: real clean Gamble of 3 gives +2")
	(tune["anchor"] as Dictionary)["gambler_crack_pct"] = 100
	var c4 := _combat(["c_high_roller"], 3, "a_gambler")
	c4.rerolls = 0
	c4.mana = 9
	var ok4 := c4.reroll_dice([c4.party[0].uid, c4.party[1].uid, c4.party[2].uid], 7, false, 0)
	_ok(ok4 and c4.party[0].cracked and c4.party[1].cracked and c4.party[2].cracked, "G2: real Gamble cracks all")
	(tune["anchor"] as Dictionary)["gambler_crack_pct"] = anchor_crack
	tune["crack"] = old
	var def = RelicRegistry.get_def("c_high_roller")
	var rc := {"owned_ids": [], "roster": CoreTestUtil.roster(), "seen": [], "depth_stage": 3}
	_ok(not CoreOffer.is_valid(def, rc), "G2: not offered without the Gambler Anchor")
	rc["anchor_id"] = "a_gambler"
	_ok(CoreOffer.is_valid(def, rc), "G2: offered with the Gambler Anchor")


func t_e3() -> void:
	var def = RelicRegistry.get_def("c_magma_seed")
	_ok(def != null and def.disabled, "E3: shipped disabled until the sim")
	var c := _combat(["c_magma_seed"])
	var u: Unit = c.party[0]
	u.die[0] = _face("dmg", 8)
	u.set_roll(0, false)
	_ok(c.stash(u.uid), "E3: first Hold")
	_ok(int(u.custom_state.get("magma_n", 0)) == 1, "E3: counter 1")
	u.held = false
	u.stash_carry = true   # next turn: the die came back
	_ok(c.stash(u.uid), "E3: held again (the Core allows it)")
	_ok(int(u.custom_state.get("magma_n", 0)) == 2, "E3: counter 2 after two turns in a row")
	u.held = false
	u.stash_carry = true
	var hp0: Array = []
	for e in c.enemies:
		hp0.append(e.hp)
	c.use_die(u.uid, c.enemies[0].uid)
	_ok(c.enemies[0].hp == hp0[0] - 10, "E3: x1.25 of 8 = 10 on the target, got %d" % (hp0[0] - c.enemies[0].hp))
	var all_hit := true
	for k in c.enemies.size():
		if c.enemies[k].hp != hp0[k] - 10:
			all_hit = false
	_ok(all_hit, "E3: every enemy takes the hit")
	_ok(not u.custom_state.has("magma_n"), "E3: counter cleared after use")
	var c2 := _combat(["c_magma_seed"])
	var u2: Unit = c2.party[0]
	u2.die[0] = _face("dmg", 8)
	u2.set_roll(0, false)
	c2.stash(u2.uid)
	u2.held = false
	u2.stash_carry = true
	var h2: Array = []
	for e in c2.enemies:
		h2.append(e.hp)
	c2.use_die(u2.uid, c2.enemies[0].uid)
	_ok(c2.enemies[0].hp == h2[0] - 8, "E3: only one Hold turn: plain 8")
	_ok(c2.enemies.size() < 2 or c2.enemies[1].hp == h2[1], "E3: only one Hold turn: no sweep")
