extends Node
## L1 PR2 seams: relic_combat/relic_state plumbing, unit.slot, acquire/sell/reorder, hook points
## that must be inert when no relic declares them.

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _engine(extra: Dictionary = {}) -> CombatEngine:
	var roster: Array = []
	for i in TEAM.size():
		roster.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var setup := {"node_id": "n", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": roster, "relic_ids": [], "combat_seed": 5}
	setup.merge(extra, true)
	var e := CombatEngine.new()
	e.setup_new(setup)
	return e


func _ready() -> void:
	RelicRegistry.legacy_unhide_for_tests()
	await get_tree().process_frame
	_guard.capture()

	var e := _engine({"relic_state": {"r_x": {"n": 2}}})
	for i in e.party.size():
		_check(e.party[i].slot == i, "unit.slot = roster index")
	_check(e.relic_run_in == {"r_x": {"n": 2}}, "relic_state enters the fight")

	# relic_combat survives snapshot round trip and undo
	e.relic_combat = {"tweak_left": 2}
	var e2 := CombatEngine.new()
	e2.from_data(JSON.parse_string(JSON.stringify(e.to_data())) as Dictionary)
	_check(e2.tweak_budget_left() == 2, "relic_combat round-trips through to_data/from_data")
	e._push_undo()
	e.relic_combat["tweak_left"] = 0
	_check(e.undo_last() and e.tweak_budget_left() == 2, "undo restores relic_combat")

	# no relic handles roll_edit: all three edits refuse and leave no trace
	var n_log := 0
	var uid: int = e.party[0].uid
	_check(not e.tweak("nudge_up", uid) and not e.hold_pick(uid) and not e.loaded_pick(uid, 0),
		"dice edits are refused when no relic allows them")
	_check(e.undo_stack.size() == 0, "a refused edit leaves no undo snapshot")

	# on_combat_end bookkeeping: result carries relic_state and fires once
	e.won = true
	var r1 := e.get_result()
	_check(r1.has("relic_state"), "result carries relic_state")
	_check(bool(e.to_data()["end_fired"]), "on_combat_end flag set after the first get_result")

	# RunState: reorder / sell / swap, and the verifier replays them
	# Depth v3: a new run opens on the Core offers; this test is about the map-phase seams, so skip them (test switch).
	RunState.start_run_with_epoch(LocalEpochSource.new(PackedByteArray(), 41), {
		"team_keys": TEAM.duplicate(), "mode": "short", "ascension": 0, "ranked": true,
		"loadout": {"core_off": true}}, 41)
	var order: Array = []
	for i in range(TEAM.size() - 1, -1, -1):
		order.append(i + 1)
	_check(RunState.reorder_party(order), "reorder_party on the map")
	_check(int(RunState.roster[0]["persistent_id"]) == 5, "roster follows the new order")
	_check(not RunState.reorder_party([1, 2]), "reorder needs a full permutation")
	_check(RunState.action_log.entries.back()["fn"] == "reorder_party", "reorder is logged")

	var passive: Array[String] = []
	for def in RelicRegistry.offerable_defs_sorted():
		if int(def.act_cost) == 0 and String(def.pact_group) == "" and String(def.mult_axis) == "":
			passive.append(String(def.id))
	var cap: int = int(RelicSlots.capacity(0, [])["passive"])
	for i in cap:
		_check(RunState.acquire_relic(passive[i], "test"), "fills passive slot %d" % i)
	var extra_id := passive[cap]
	_check(not RunState.acquire_relic(extra_id, "test"), "full slots refuse without a sale")
	var shards_before := RunState.shards_this_run
	_check(RunState.acquire_relic(extra_id, "test", passive[0]), "swap_on_full with a sale")
	_check(not RunState.owned_relic_ids.has(passive[0]) and RunState.owned_relic_ids.has(extra_id), "swap result")
	_check(RunState.shards_this_run >= shards_before, "sale pays shards")
	_check(RunState.sell_relic(passive[1]) and not RunState.owned_relic_ids.has(passive[1]), "sell_relic")
	_check(not RunState.sell_relic("r_not_owned"), "cannot sell what is not owned")
	var fns: Array = []
	for en in RunState.action_log.entries:
		fns.append(en["fn"])
	_check(fns.has("swap_on_full") and fns.has("sell_relic"), "swap and sale are logged")

	# relic_state survives the run save
	RunState.relic_state = {"r_y": {"k": 3}}
	var data := JSON.parse_string(JSON.stringify(RunState.to_data())) as Dictionary
	RunState.reset()
	RunState.from_data(data)
	_check(int((RunState.relic_state["r_y"] as Dictionary)["k"]) == 3, "relic_state saved and restored")
	_check(RunState.owned_relic_ids.size() == cap - 1, "owned relics restored")

	if _fails.is_empty():
		print("t_combat_seams: PASS — %d checks OK" % _checks)
		_guard.restore()
		get_tree().quit(0)
	else:
		for m in _fails:
			print("t_combat_seams: FAIL — %s" % m)
		_guard.restore()
		get_tree().quit(1)
