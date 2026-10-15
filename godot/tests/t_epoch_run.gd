extends Node
## The epoch seam end to end: RunState + CombatEngine draw only from the epoch source.
## Determinism, from_aid reroll, explicit seeds, resume of the tape, referee with tape.

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _fingerprint() -> String:
	return JSON.stringify([RunState.boss_plan, RunState.map_graph, RunState.owned_relic_ids])


func _roster() -> Array:
	var out: Array = []
	for i in TEAM.size():
		out.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return out


func _engine(seed_value: int) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup_new({"node_id": "n", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": seed_value})
	return e


func _ready() -> void:
	await get_tree().process_frame
	_guard.capture()
	_force_local()

	# --- run start is a function of the epoch secret only ---
	RunState.start_new_run(11, TEAM, "short", 0, true)
	var a := _fingerprint()
	var seed_a := RunState.run_seed
	RunState.start_new_run(11, TEAM, "short", 0, true)
	_check(_fingerprint() == a, "same secret => same boss plan and map")
	_check(seed_a == 11, "run_seed still shows the typed seed")
	RunState.start_new_run(12, TEAM, "short", 0, true)
	_check(_fingerprint() != a, "different secret => different run")
	_check(String(RunState.action_log.header.get("run_id", "")).begins_with("local_"), "run_id in header")
	_check(not RunState.action_log.header.has("seed"), "header no longer carries a seed")

	# --- node epoch gives the combat seed; same decisions => same combat ---
	RunState.start_new_run(11, TEAM, "short", 0, true)
	var graph := RunMapGraph.from_data(RunState.map_graph)
	var n := graph.find_node(graph.start_node_id)
	RunState.enter_node(n.id, "battle")
	var cs1 := int(RunState.pending_combat["combat_seed"])
	_check(RunState.epoch.tape().size() == 2, "run_start + node on the tape")
	RunState.start_new_run(11, TEAM, "short", 0, true)
	RunState.enter_node(n.id, "battle")
	_check(int(RunState.pending_combat["combat_seed"]) == cs1, "node seed reproducible")

	# --- explicit seed overrides the epoch (verifier/bot path) ---
	RunState.start_new_run(11, TEAM, "short", 0, true)
	RunState.enter_node(n.id, "battle", 777)
	_check(int(RunState.pending_combat["combat_seed"]) == 777, "explicit node seed used")
	_check(RunState.epoch.tape().size() == 1, "explicit seed asks nothing from the epoch")

	# --- from_aid reroll: legal with 0 rerolls, costs none, is logged ---
	var e := _engine(5)
	e.action_log = ActionLog.new()
	e.action_log.begin(0, TEAM, "short", 0)
	e.rerolls = 0
	var uids := [e.party[0].uid]
	_check(not e.can_reroll(uids), "no reroll left: refused")
	_check(e.can_reroll(uids, true), "an Aid reroll ignores the counter")
	_check(e.reroll_dice(uids, 4242, true), "aid reroll with explicit seed succeeds")
	_check(e.rerolls == 0, "aid reroll does not spend a reroll")
	_check(e.action_log.entries.size() == 1 and int((e.action_log.entries[0]["args"] as Array)[1]) == 1,
		"from_aid is in the log")
	var e2 := _engine(5)
	e2.rerolls = 0
	_check(e2.reroll_dice(uids, 4242, true), "replay of the aid reroll is accepted")
	_check(JSON.stringify(e.to_data()) == JSON.stringify(e2.to_data()), "aid reroll replays to the same state")
	var e3 := _engine(5)
	e3.rerolls = 0
	_check(not e3.reroll_dice(uids, 4242, false), "same reroll without from_aid is refused at 0")

	# --- same reroll seed, same faces; other seed, (very likely) other state ---
	var f1 := _engine(5)
	var f2 := _engine(5)
	f1.reroll_dice([f1.party[0].uid, f1.party[1].uid], 9)
	f2.reroll_dice([f2.party[0].uid, f2.party[1].uid], 9)
	_check(JSON.stringify(f1.to_data()) == JSON.stringify(f2.to_data()), "reroll deterministic in its seed")
	var g := _engine(5)
	g.end_turn(31)
	var g2 := _engine(5)
	g2.end_turn(31)
	_check(JSON.stringify(g.to_data()) == JSON.stringify(g2.to_data()), "end_turn deterministic in its seed")

	# --- a resumed fight (from_data) reconnects to the epoch with set_epoch() ---
	RunState.start_new_run(31, TEAM, "short", 0, true)
	RunState.enter_node(n.id, "battle")
	var live := CombatEngine.new()
	live.setup_new(RunState.pending_combat)
	var snap := JSON.parse_string(JSON.stringify(live.to_data())) as Dictionary
	var resumed := CombatEngine.new()
	resumed.from_data(snap)
	var before := RunState.epoch.tape().size()
	resumed.end_turn()
	_check(RunState.epoch.tape().size() == before, "without set_epoch the resumed engine is off the tape")
	var resumed2 := CombatEngine.new()
	resumed2.from_data(snap)
	resumed2.set_epoch(RunState.epoch)
	resumed2.end_turn()
	_check(RunState.epoch.tape().size() == before + 1, "after set_epoch the end_turn epoch is on the tape")

	# --- tape survives a save round trip and the run goes on from the same chain position ---
	RunState.start_new_run(21, TEAM, "short", 0, true)
	RunState.enter_node(n.id, "battle")
	var data := JSON.parse_string(JSON.stringify(RunState.to_data())) as Dictionary
	var tape_len := RunState.epoch.tape().size()
	var after_live := _next_seed()   # what the live run's next epoch would be
	RunState.reset()
	RunState.from_data(data)
	_check(RunState.epoch != null and RunState.epoch.tape().size() == tape_len, "tape restored on resume")
	_check(_next_seed() == after_live, "resumed run continues the same epoch chain")

	# B4: the close summary carries what the L1 report reads (production/l1-telemetry.md).
	RunState.fights_started = 4
	RunState.power_level = 5
	RunState.newcomer = true
	RunState.aid_uses = [{"aid": "R1", "node_id": "n1"}]
	RunState.mission = {"tier": "N2", "stake": 7}
	var cs := RunState.close_summary(true, true, {"stake": 7, "payout": 12})
	_check(int(cs["battles_done"]) == 4 and int(cs["nodes_done"]) == 5 and bool(cs["newcomer"]), "close_summary: battles/nodes/newcomer")
	_check((cs["aids"] as Array) == ["R1"] and String(cs["client"]) != "", "close_summary: aids + client version")
	_check(String(cs["mission"]["tier"]) == "N2" and int(cs["mission"]["payout"]) == 12 and int(cs["mission"]["stake"]) == 7, "close_summary: mission tier/stake/payout")
	_check(int(RunState.close_summary(false, true, {"stake": 7, "payout": 12})["mission"]["payout"]) == 0, "close_summary: lost mission pays 0")
	_check(JSON.stringify(cs).length() < 1024, "close_summary fits the server's 2 KB cap")
	RunState.reset()

	if _fails.is_empty():
		print("t_epoch_run: PASS — %d checks OK" % _checks)
		_guard.restore()
		get_tree().quit(0)
	else:
		for m in _fails:
			print("t_epoch_run: FAIL — %s" % m)
		_guard.restore()
		get_tree().quit(1)


## Peeks the seed the next epoch would give, without disturbing the run: a throwaway ask on a
## duplicate is not possible, so the live source is asked and the answer compared across two runs
## that were advanced identically.
func _next_seed() -> int:
	return RunState.epoch.request("end_turn", {"turn": 1}).seed


## L1: project defaults are remote/remote; this test runs the local path and must never touch the network.
func _force_local() -> void:
	ProjectSettings.set_setting("axie/epoch_source", "local")
	ProjectSettings.set_setting("axie/gem_wallet", "local")
