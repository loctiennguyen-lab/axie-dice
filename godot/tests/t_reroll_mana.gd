extends Node
## Depth v3 3.5: 1 free reroll per turn, then mana (combat_tune.json reroll.*), cap reroll.max_total.

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
const SEED := 777


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	_costs()
	_a3()
	_tamper()
	print("=== t_reroll_mana: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("t_reroll_mana: FAIL - %s" % f)
	if _failures.is_empty():
		print("t_reroll_mana: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


func _engine() -> CombatEngine:
	var roster: Array = []
	for i in TEAM.size():
		roster.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var e := CombatEngine.new()
	e.setup_new({"node_id": "rr_node", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": roster, "relic_ids": [], "combat_seed": SEED})
	return e


func _uids(e: CombatEngine) -> Array:
	var out: Array = []
	for u in e.party:
		out.append((u as Unit).uid)
	return out


func _costs() -> void:
	var e := _engine()
	_check(e.rerolls == 1 and e.max_rerolls == 1, "free rerolls should be 1, got %d" % e.rerolls)
	var all := _uids(e)
	e.mana = 0
	_check(e.reroll_mana_cost() == 0, "first reroll should be free")
	var m0 := e.mana
	_check(e.reroll_dice(all), "free reroll refused")
	_check(e.rerolls == 0 and e.mana >= m0, "free reroll spent mana")   # cantrip mana faces may add, never spend
	e.mana = 0
	_check(e.reroll_mana_cost() == 1, "second reroll (first chosen) should cost 1 (A+)")
	_check(not e.can_reroll(all) and not e.reroll_dice(all), "paid reroll allowed with 0 mana")
	e.mana = 5
	_check(e.reroll_dice(all), "paid reroll refused with mana")
	_check(e.mana >= 3 and e.mana <= 3 + 20 and e.rerolls == 0, "paid reroll should spend 1 mana (mana=%d)" % e.mana)
	# v4 3.5: the second chosen reroll costs mana_cost_3 = 3, and max_total 3 stops a third choice.
	_check(e.reroll_mana_cost() == 3, "second chosen reroll should cost 3")
	e.mana = 2
	_check(not e.can_reroll(all), "3 mana reroll allowed with 2 mana")
	e.mana = 50
	_check(e.reroll_dice(all), "second chosen reroll refused with mana")
	e.mana = 50
	_check(not e.can_reroll(all) and e.reroll_paid_k == 2, "3rd chosen reroll allowed past reroll.max_total")
	# An Aid reroll (bought) is outside max_total (still under hard_cap 4): paid_k does not move.
	var k_before: int = e.reroll_paid_k
	_check(e.reroll_dice(all, -1, true), "aid reroll refused")
	_check(e.reroll_paid_k == k_before, "an Aid reroll was counted against reroll.max_total")
	_check(e.reroll_total_turn == 4 and not e.reroll_dice(all, -1, true), "hard_cap 4 not enforced for Aid")
	e.end_turn()
	if e.won or e.lost:
		return
	_check(e.rerolls == 1 and e.reroll_k == 0, "turn change should restore the free reroll")


func _a3() -> void:
	var roster: Array = []
	for i in TEAM.size():
		roster.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var e := CombatEngine.new()
	e.setup_new({"node_id": "rr3", "kind": "battle", "pw": 2, "ascension": 3,
		"roster_snapshot": roster, "relic_ids": [], "combat_seed": SEED})
	var all := _uids(e)
	e.mana = 0
	_check(e.rerolls == 0 and e.reroll_mana_cost() == 1, "A3: no free reroll, first reroll costs mana")
	_check(not e.reroll_dice(all), "A3: reroll without mana allowed")
	e.mana = 2
	_check(e.reroll_dice(all) and e.mana <= 20, "A3: paid reroll refused with mana")


func _tamper() -> void:
	var log := ActionLog.new()
	log.begin(SEED, TEAM, "short", 0, "test")
	var e := _engine()
	e.action_log = log
	var all := _uids(e)
	_check(e.reroll_dice(all), "setup free reroll")
	e.mana = 4
	_check(e.reroll_dice(all), "setup paid reroll")
	# A replay starts with 0 mana: the paid reroll must be refused (a cheater cannot invent mana).
	var r := _engine()
	r.mana = 0
	var ok1 := RunVerifier._apply_combat(r, "reroll_dice", (log.entries[0] as Dictionary)["args"])
	r.mana = 0
	var ok2 := RunVerifier._apply_combat(r, "reroll_dice", (log.entries[1] as Dictionary)["args"])
	_check(ok1, "replay refused the free reroll")
	_check(not ok2, "replay accepted a paid reroll with no mana")


func _check(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)
