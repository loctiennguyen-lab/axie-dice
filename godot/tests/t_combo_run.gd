extends Node
## Gacha lane GD: RunState combo bookkeeping (combo_done, +1 reroll cap, skipped T, combo_formed / combo_fired, save round trip).
var _failures: Array[String] = []
var _checks := 0
var _formed: Array = []
var _fired: Array = []


func _assert(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)


func _start(seed: int) -> void:
	RunState.reset()
	RunState.start_new_run_seeded(seed, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "mode": "short",
		"ascension": 0, "ranked": false, "bonuses": {}, "loadout": {"rules_on": false}})
	RunState.owned_relic_ids = []
	_formed = []
	_fired = []


func _ready() -> void:
	CoreTestUtil.enable()
	EventBus.combo_formed.connect(func(id: String, t: String) -> void: _formed.append([id, t]))
	EventBus.combo_fired.connect(func(id: String) -> void: _fired.append(id))
	_start(5)
	var r0 := RunState.core_reroll_left
	RunState._grant_relic("c_living_wall", "core")
	_assert(RunState.combo_done.is_empty() and _formed.is_empty(), "one member: nothing formed")
	RunState._grant_relic("c_gatekeeper", "core")
	_assert(RunState.combo_done.get("combo_turtle_fort", "") == "pair", "pair recorded")
	_assert(_formed == [["combo_turtle_fort", "pair"]], "combo_formed pair emitted: %s" % str(_formed))
	_assert(RunState.core_reroll_left == r0 + 1 and RunState.combo_rerolls_gained == 1, "first Pair gives +1 Core reroll")
	RunState._grant_relic("c_backline_glow", "core")
	_assert(RunState.combo_done.get("combo_turtle_fort", "") == "full" and _formed.back() == ["combo_turtle_fort", "full"], "Full upgrade emitted")
	_assert(RunState.core_reroll_left == r0 + 1, "Full of an already-formed combo gives no 2nd reroll")
	# cap: 2 per run
	RunState._grant_relic("c_nest", "core")
	RunState._grant_relic("c_golden_egg", "core")
	_assert(RunState.combo_rerolls_gained == 2 and RunState.core_reroll_left == r0 + 2, "second combo gives the 2nd reroll")
	RunState._grant_relic("c_overflow", "core")
	RunState._grant_relic("c_dewdrop", "core")
	_assert(RunState.combo_done.has("combo_rising_tide"), "third combo still recorded")
	_assert(RunState.combo_rerolls_gained == 2 and RunState.core_reroll_left == r0 + 2, "cap 2 per run: third combo gives no reroll")
	# save round trip
	var d := RunState.to_data()
	var keep := RunState.combo_done.duplicate()
	RunState.reset()
	RunState.from_data(d)
	_assert(RunState.combo_done == keep and RunState.combo_rerolls_gained == 2, "combo_done + counter survive save/load")
	# combo_fired: both Pair Cores in one turn, once per fight
	_fired = []
	EventBus.turn_phase_changed.emit(3, CombatEngine.CombatPhase.ROLL)
	EventBus.core_fired.emit("c_living_wall", -1, 3, "x")
	_assert(_fired.is_empty(), "one Core of the Pair is not enough")
	EventBus.core_fired.emit("c_gatekeeper", -1, 3, "x")
	_assert(_fired == ["combo_turtle_fort"], "both fired in a turn: combo_fired once: %s" % str(_fired))
	EventBus.turn_phase_changed.emit(3, CombatEngine.CombatPhase.ROLL)
	EventBus.core_fired.emit("c_living_wall", -1, 3, "x")
	EventBus.core_fired.emit("c_gatekeeper", -1, 3, "x")
	_assert(_fired.size() == 1, "second time in the same fight stays silent")
	EventBus.combat_finished.emit(true)
	EventBus.turn_phase_changed.emit(3, CombatEngine.CombatPhase.ROLL)
	EventBus.core_fired.emit("c_living_wall", -1, 3, "x")
	EventBus.turn_phase_changed.emit(3, CombatEngine.CombatPhase.ROLL)
	EventBus.core_fired.emit("c_gatekeeper", -1, 3, "x")
	_assert(_fired.size() == 1, "fires split over two turns do not count")
	EventBus.core_fired.emit("c_living_wall", -1, 3, "x")
	_assert(_fired.size() == 2, "new fight announces again")
	# quest Core completion keeps counting
	_start(6)
	RunState._grant_relic("c_kindle", "core")
	RunState.core_quest_done = ["c_key_strike"]
	RunState._note_combo_grant()
	_assert(RunState.combo_done.get("combo_kindling_brew", "") == "pair", "finished quest Core still forms the Pair")
	# skipped T: a real offer
	_start(7)
	var cards: Array = [{"core": true, "key": "c_bastion", "tier": 0}, {"core": true, "key": "c_cascade", "tier": 2},
		{"core": true, "key": "c_sixth_die", "tier": 2}]
	RunState.pending_rewards.assign(cards)
	RunState.apply_chosen_reward(RunState.pending_rewards[0])
	_assert(RunState.core_skipped_t == ["c_cascade", "c_sixth_die"], "unpicked Crystal cards are remembered: %s" % str(RunState.core_skipped_t))
	var d2 := RunState.to_data()
	RunState.reset()
	RunState.from_data(d2)
	_assert(RunState.core_skipped_t.size() == 2, "skipped_t survives save/load")
	RunState.reset()
	_done()


func _done() -> void:
	if _failures.is_empty():
		print("t_combo_run: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_combo_run: FAIL — %s" % f)
	get_tree().quit(1)
