extends Node
## Rule tables + pressure rules: ascension.json, combat_tune.json, boons.json, boss clock, attrition,
## spike, intent formula, newcomer, boons as plain numbers, A1 price, A3 reroll.

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _roster() -> Array:
	var out: Array = []
	for i in TEAM.size():
		out.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return out


func _engine(kind: String, asc: int, extra: Dictionary = {}) -> CombatEngine:
	var setup := {"node_id": "n", "kind": kind, "pw": 4, "ascension": asc,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 9,
		"boss_key": "agony" if kind == "boss" else ""}
	setup.merge(extra, true)
	var e := CombatEngine.new()
	e.setup_new(setup)
	return e


func _ready() -> void:
	await get_tree().process_frame
	_guard.capture()

	# --- tables ---
	_check(ContentDB.ascension_table.size() == 11, "ascension.json has levels 0..10")
	var a10 := ContentDB.ascension_mods(10)
	_check(absf(float(a10["hp"]) - 1.331) < 0.001 and absf(float(a10["dmg"]) - 1.331) < 0.001, "A10 is x1.331 / x1.331")
	_check(absf(float(ContentDB.ascension_mods(8)["dmg"]) - 1.21) < 0.001, "A8 dmg x1.21 (v2: 1.1 x 1.1)")
	_check(int(ContentDB.ascension_mods(7)["rewards"]) == 2 and int(ContentDB.ascension_mods(6)["rewards"]) == 3, "old `rewards` key")
	_check(int(ContentDB.ascension_mods(5)["continue_heal_pct"]) == 40 and int(ContentDB.ascension_mods(6)["continue_heal_pct"]) == 25, "continue heal 40 / 25 from A6")
	_check(ContentDB.boons.size() == 8, "eight Boons")
	_check(RulesMath.round_half_up(12.5) == 13 and RulesMath.round_half_up(2.49) == 2 and RulesMath.round_half_up(10 * 1.15) == 12, "round half up")

	# --- clock: light (A0) vs full (A4) vs A9 ---
	var b0 := _engine("boss", 0)
	b0.turn = 14
	_check(b0.clock_state()["pct"] == 10 and b0.clock_state()["stacks"] == 1, "A0 light clock: turn 14 = +10%")
	b0.turn = 40
	_check(b0.clock_state()["pct"] == 30, "A0 light clock caps at +30% (3 stacks)")
	var b4 := _engine("boss", 4)
	b4.turn = 9
	_check(b4.clock_state()["turns_left"] == 1 and b4.clock_state()["pct"] == 0, "A4: enrage in 1 turn at turn 9")
	b4.turn = 10
	_check(b4.clock_state()["pct"] == 20, "A4 enrage starts turn 10 at +20%")
	b4.turn = 30
	_check(b4.clock_state()["pct"] == 100, "A4 enrage caps at +100%")
	var b9 := _engine("boss", 9)
	b9.turn = 8
	_check(b9.clock_state()["pct"] == 20, "A9 enrage starts turn 8")
	var nb0 := _engine("boss", 0, {"newcomer": true})
	nb0.turn = 20
	_check(not bool(nb0.clock_state()["active"]), "newcomer: light clock off")
	var nb4 := _engine("boss", 4, {"newcomer": true})
	nb4.turn = 12
	_check(bool(nb4.clock_state()["active"]), "newcomer: the full clock (A4) still runs")
	_check(not bool(_engine("battle", 4).clock_state()["active"]), "no clock outside boss fights")
	# Continue / delay move the base: clock and attrition go back to 0
	b4.clock_turn_base = b4.turn
	_check(b4.clock_state()["pct"] == 0 and b4.attrition_state()["pct"] == 0, "clock_turn_base resets both")

	# --- attrition ---
	var e1 := _engine("battle", 0)
	e1.turn = 5
	_check(e1.attrition_state()["pct"] == 0, "attrition starts turn 6")
	e1.turn = 6
	_check(e1.attrition_state()["pct"] == 5, "turn 6 = +5%")
	e1.turn = 30
	_check(e1.attrition_state()["pct"] == 25, "attrition caps +25%")
	var e1n := _engine("battle", 0, {"newcomer": true})
	e1n.turn = 30
	_check(e1n.attrition_state()["pct"] == 0, "newcomer: attrition off")

	# --- spike + combined intent ---
	var el := _engine("elite", 3)
	var foe: Unit = el.enemies[0]
	el.turn = 4
	_check(el.turns_to_spike(foe) == 0, "elite spikes on turn 4 from A3")
	el.turn = 5
	_check(el.turns_to_spike(foe) == 3, "three turns to the next spike")
	_check(_engine("elite", 2).turns_to_spike(_engine("elite", 2).enemies[0]) == -1, "no spike below A3")
	_check(_engine("battle", 5).turns_to_spike(_engine("battle", 5).enemies[0]) == -1, "no spike in normal battles")
	var plain := _engine("elite", 3)
	var pu: Unit = plain.enemies[0]
	plain.turn = 4
	# turn 4: attrition 0, spike x1.8 => factor 1.8
	_check(absf(plain.enemy_dmg_factor(pu) - 1.8) < 0.001, "factor at a spike turn, no attrition")
	plain.turn = 8
	# turn 8: attrition 3 stacks = 15%, spike => 1.15 x 1.8
	_check(absf(plain.enemy_dmg_factor(pu) - 1.15 * 1.8) < 0.001, "(1 + attrition) x spike, not additive")

	# --- hud_state shape ---
	var h := _engine("boss", 4).hud_state()
	for k in ["turn", "rerolls", "max_rerolls", "mana", "tweak_left", "clock", "attrition", "enemy_next", "boss_phase", "newcomer"]:
		_check(h.has(k), "hud_state has %s" % k)
	_check((h["enemy_next"] as Dictionary).size() >= 1, "enemy_next lists the boss")

	# --- A3 reroll base, bonuses still add ---
	_check(_engine("battle", 2).max_rerolls == 2 and _engine("battle", 3).max_rerolls == 1, "A3 base reroll 2 -> 1")
	_check(_engine("battle", 3, {"bonus_reroll": 2}).max_rerolls == 3, "bonuses stack on the reduced base")

	# --- boons are plain numbers ---
	RunState.start_new_run_seeded(5, {"team_keys": TEAM, "mode": "short", "ascension": 0, "ranked": false,
		"loadout": {"boon_id": "boon_spark"}})
	_check(RunState.boon_id == "boon_spark", "boon accepted")
	_check(int(RunState.boon_numbers_for_fight(1, 0).get("start_mana", 0)) == 2, "Spark: fight 1")
	_check(int(RunState.boon_numbers_for_fight(3, 0).get("start_mana", 0)) == 2, "Spark: fight 3")
	_check(RunState.boon_numbers_for_fight(4, 0).is_empty(), "Spark: gone at fight 4")
	RunState.boon_id = "boon_boss_ward"
	_check(RunState.boon_numbers_for_fight(1, 0).is_empty() and int(RunState.boon_numbers_for_fight(7, 1)["start_shield_all"]) == 5, "Boss Ward only in the first boss")
	RunState.start_new_run_seeded(5, {"team_keys": TEAM, "mode": "short", "ascension": 0, "ranked": false,
		"kind": "mission", "loadout": {"boon_id": "boon_spark"}})
	_check(RunState.boon_id == "", "no Boon in a mission run (MON-12)")
	var bm := _engine("battle", 0, {"start_mana": 2, "start_shield_all": 5, "start_eggs": 1})
	_check(bm.mana >= 2, "start_mana applied")
	var shielded := true
	for u in bm.party:
		if not u.is_token and u.shield < 5:
			shielded = false
	_check(shielded, "start shield on every real Axie")
	_check(bm._count_alive_tokens(bm.party) == 1, "one start egg")

	# --- A1 shop prices, A10 reward reroll ---
	RunState.start_new_run(3, TEAM, "short", 1, false)
	RunState.enter_node("r1_c0", "shop", 1)
	var priced := true
	for it in RunState.shop_items:
		if int(it["cost"]) <= 0:
			priced = false
	_check(priced and RunState.shop_items.size() > 0, "shop built at A1")
	RunState.start_new_run(3, TEAM, "short", 10, false)
	_check(RunState.reward_reroll_max == 0, "A10: no reward reroll")

	if _fails.is_empty():
		print("t_pressure_rules: PASS — %d checks OK" % _checks)
		_guard.restore()
		get_tree().quit(0)
	else:
		for m in _fails:
			print("t_pressure_rules: FAIL — %s" % m)
		_guard.restore()
		get_tree().quit(1)
