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
