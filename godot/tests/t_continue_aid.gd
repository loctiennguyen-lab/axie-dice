extends Node
## Continue (form B), Aid R4/R6 effects, the Aid ledger, and replay of a fight that was continued.

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _roster(hp_override: int = 0) -> Array:
	var out: Array = []
	for i in TEAM.size():
		out.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {},
			"bonus_hp": (hp_override - int(ContentDB.heroes[TEAM[i]]["max_hp"])) if hp_override > 0 else 0})
	return out


func _engine(asc: int, frail: bool) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup_new({"node_id": "n", "kind": "battle", "pw": 8, "ascension": asc,
		"roster_snapshot": _roster(1 if frail else 0), "relic_ids": [], "combat_seed": 5})
	e.action_log = ActionLog.new()
	e.action_log.begin(0, TEAM, "short", asc)
	return e


## Ends turns with fixed seeds until the party is wiped. Returns the seeds used, in order.
func _wipe(e: CombatEngine, base: int) -> Array:
	var seeds: Array = []
	var i := 0
	while not e.lost and i < 40:
		var sd := base + i
		seeds.append(sd)
		e.end_turn(sd)
		i += 1
	return seeds


func _replay(log: ActionLog, seeds: Array, asc: int) -> CombatEngine:
	var e := _engine(asc, true)
	var si := 0
	for en in log.entries:
		match String(en["fn"]):
			"end_turn":
				e.end_turn(int(seeds[si]))
				si += 1
			"continue":
				e.continue_after_wipe(int(seeds[si]), -1)
				si += 1
	return e


func _ready() -> void:
	await get_tree().process_frame
	_guard.capture()

	var e := _engine(0, true)
	_check(not e.can_continue(), "no continue while alive")
	var seeds := _wipe(e, 100)
	_check(e.lost and e.can_continue(), "frail party wiped")
	var turn_at_wipe := e.turn
	var foe_hp: Array = []
	for en in e.enemies:
		foe_hp.append(en.hp)
	_check(e.continue_after_wipe(777, -1), "continue accepted")
	seeds.append(777)
	_check(not e.lost and e.attempt == 1, "fight goes on, attempt 1")
	_check(e.turn == turn_at_wipe, "same turn: the spike schedule does not move")
	var same_foes := true
	for i in e.enemies.size():
		if e.enemies[i].hp != foe_hp[i]:
			same_foes = false
	_check(same_foes, "enemies keep their HP")
	_check(e.clock_turn_base == e.turn, "clock and attrition are back to 0")
	var alive := 0
	for u in e.party:
		if not u.is_token and u.hp > 0:
			alive += 1
	_check(alive == e.real_party().size() and alive > 0, "whole real party is back")
	_check(e.action_log.entries.back()["fn"] == "continue", "continue is logged")
	_check(not e.continue_after_wipe(1, 40), "cannot continue a living party")

	# the continued fight replays to the very same state
	seeds.append_array(_wipe(e, 900))
	var twin := _replay(e.action_log, seeds, 0)
	_check(JSON.stringify(twin.to_data()) == JSON.stringify(e.to_data()), "continued fight replays identically")

	# heal 40% at A0..A5, 25% from A6 (real HP so the percentage shows)
	for asc in [0, 5, 6, 10]:
		var h := CombatEngine.new()
		h.setup_new({"node_id": "n", "kind": "battle", "pw": 8, "ascension": asc,
			"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 5})
		for u in h.party:
			u.hp = 0
		h._check_end()
		_check(h.lost, "wiped at A%d" % asc)
		h.continue_after_wipe(5, -1)
		var pct := 40 if asc <= 5 else 25
		var u0: Unit = h.party[0]
		_check(u0.hp == int(ceil(float(u0.max_hp) * pct / 100.0)), "A%d revives at %d%%" % [asc, pct])

	# R4 delay clock
	var b := CombatEngine.new()
	b.setup_new({"node_id": "n", "kind": "boss", "pw": 4, "ascension": 4, "roster_snapshot": _roster(),
		"relic_ids": [], "combat_seed": 3, "boss_key": "agony"})
	b.turn = 12
	_check(b.clock_state()["pct"] == 60, "A4 turn 12 = +60%")
	b.delay_clock(2)
	_check(b.clock_state()["pct"] == 20, "delay_clock(2): turn 12 reads as turn 10, +20%")

	# ledger + R6
	RunState.start_new_run(61, TEAM, "short", 0, false)
	RunState.record_aid_use("boon")
	_check(RunState.boon_used and RunState.aid_uses.is_empty(), "Boon is counted by boon_used, not in uses")
	RunState.apply_aid_use("delay_clock", [2])
	_check(RunState.aid_uses.size() == 1 and RunState.action_log.entries.back()["fn"] == "aid_use", "aid_use logged + counted")
	_check(not RunState.refresh_shop(5), "no refresh outside a shop")
	RunState.enter_node("r1_c0", "shop", 11)
	var before := JSON.stringify(RunState.shop_items)
	_check(RunState.refresh_shop(99), "refresh in a shop")
	_check(JSON.stringify(RunState.shop_items) != before, "the row changed")
	_check(RunState.action_log.entries.back()["fn"] == "shop_refresh", "refresh logged")
	var ctx := RunState.aid_context()
	_check(bool(ctx["in_shop"]) and bool(ctx["boon_used"]), "aid_context reads the ledger")
	var data := JSON.parse_string(JSON.stringify(RunState.to_data())) as Dictionary
	RunState.reset()
	RunState.from_data(data)
	_check(RunState.aid_uses.size() == 1 and RunState.boon_used, "ledger survives save")

	if _fails.is_empty():
		print("t_continue_aid: PASS — %d checks OK" % _checks)
		_guard.restore()
		get_tree().quit(0)
	else:
		for m in _fails:
			print("t_continue_aid: FAIL — %s" % m)
		_guard.restore()
		get_tree().quit(1)
