extends Node
## P5: a forced pact must always have a way out. Probe: every owned old relic Eternal, slots full.
var _f: Array[String] = []
var _n := 0
var _guard := SaveGuard.new()
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bird1"]

func _ready() -> void:
	_guard.capture()
	for asc in [6, 10]:
		for seed in [1, 2, 3, 777, 4242]:
			_probe(asc, seed, "passive")
			_probe(asc, seed, "all")
	_stuck_state_can_skip()
	_guard.restore()
	print("t_pact_eternal_exit: %d checks, %d failure(s)" % [_n, _f.size()])
	if _f.is_empty():
		print("t_pact_eternal_exit: PASS — %d checks OK" % _n)
		get_tree().quit(0)
		return
	for m in _f:
		print("t_pact_eternal_exit: FAIL — %s" % m)
	get_tree().quit(1)

func _a(c: bool, m: String) -> void:
	_n += 1
	if not c:
		_f.append(m)

func _probe(asc: int, sd: int, mode: String) -> void:
	RunState.start_new_run(sd, TEAM, "full", asc, false)
	RunState.current_node_id = "r3_c0"
	RunState.bosses_started = 1
	var cap := RelicSlots.capacity(asc, [])
	var fill: Array[String] = []
	var want := int(cap["passive"]) if mode == "passive" else 99
	for d in RelicRegistry.all_defs_sorted():
		if fill.size() >= want:
			break
		if String(d.pact_group) == "" and String(d.core_axis) == "" and not d.hidden_from_pool and not String(d.id).begins_with("__") \
				and String(d.requires_class) == "" and d.act_cost == 0:
			fill.append(String(d.id))
	RunState.owned_relic_ids.assign(fill)
	for id in fill:
		RunState.relic_stickers[id] = RelicSlots.STICKER_ETERNAL
	RunState.apply_combat_result({"won": true, "kind": "boss", "pw": 5, "shards_earned": 0})
	var tag := "A%d seed %d %s" % [asc, sd, mode]
	if RunState.phase != RunState.RunPhase.PACT:
		_a(true, tag)
		return
	var any_ok := false
	for c in RunState.pact_cards():
		if bool(c["ok"]):
			any_ok = true
	_a(any_ok, tag + ": PACT phase open but no card can be taken")


## Offers never reach this state, but a stale save could: forced pact, every card needs a sale, every sale is Eternal.
func _stuck_state_can_skip() -> void:
	RunState.start_new_run(777, TEAM, "full", 6, false)
	RunState.current_node_id = "r3_c0"
	RunState.bosses_started = 1
	RunState.apply_combat_result({"won": true, "kind": "boss", "pw": 5, "shards_earned": 0})
	_a(RunState.phase == RunState.RunPhase.PACT and RunState.pending_pact_forced, "A6 boss opens a forced pact")
	_a(not RunState.pact_can_skip() and not RunState.skip_pact(), "normal forced pact: no skip")
	var fill: Array[String] = []
	for d in RelicRegistry.all_defs_sorted():
		if fill.size() >= 40:
			break
		if String(d.pact_group) == "" and String(d.core_axis) == "" and not String(d.id).begins_with("__"):
			fill.append(String(d.id))
	RunState.owned_relic_ids.assign(fill)
	for id in fill:
		RunState.relic_stickers[id] = RelicSlots.STICKER_ETERNAL
	var any_ok := false
	for c in RunState.pact_cards():
		any_ok = any_ok or bool(c["ok"])
	_a(not any_ok, "setup: no pact card is takeable")
	_a(RunState.pact_can_skip(), "stuck forced pact: skip allowed")
	_a(RunState.skip_pact() and RunState.phase == RunState.RunPhase.REWARD, "skip leaves the PACT phase")
