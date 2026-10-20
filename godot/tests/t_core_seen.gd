extends Node
var _failures: Array[String] = []
var _checks := 0
func _assert(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)
func _done(n: String) -> void:
	if _failures.is_empty():
		print("%s: PASS — %d checks OK" % [n, _checks])
		get_tree().quit(0)
		return
	for f in _failures:
		print("%s: FAIL — %s" % [n, f])
	get_tree().quit(1)
func _start(seed: int, extra: Dictionary = {}) -> void:
	RunState.reset()
	var p := {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "mode": "short", "ascension": 0, "ranked": false,
		"bonuses": {}, "loadout": {"rules_on": false}}
	for k in extra:
		p[k] = extra[k]
	RunState.start_new_run_seeded(seed, p)
func _axes(offer: Array) -> Array:
	var a: Array = []
	for c in offer:
		a.append(String(c["axis"]))
	return a

func _ready() -> void:
	CoreTestUtil.enable()
	_start(21)
	var shown: Array = []
	for c in RunState.pending_rewards:
		shown.append(String(c["key"]))
	_assert(RunState.core_seen == shown or RunState.core_seen.size() == shown.size(), "offer cards are in core_seen at once")
	for k in shown:
		_assert(RunState.core_seen.has(k), "%s seen" % k)
	RunState.apply_chosen_reward(RunState.pending_rewards[0]); RunState.after_node()
	# later offers never contain a seen id (also the two the player passed on)
	var g := RunMapGraph.from_data(RunState.map_graph)
	RunState.current_node_id = g.get_row(5)[0].id
	var seen_before: Array = RunState.core_seen.duplicate()
	RunState.after_node()
	for c in RunState.pending_rewards:
		_assert(not seen_before.has(String(c["key"])), "pick 2 card %s was not shown before" % c["key"])
	_assert(RunState.core_seen.size() == seen_before.size() + RunState.pending_rewards.size(), "seen grows by the offer")
	# save/load round trip keeps core_seen and the open offer
	var snapshot := RunState.core_seen.duplicate()
	var d := RunState.to_data()
	RunState.reset()
	RunState.from_data(JSON.parse_string(JSON.stringify(d)))
	_assert(RunState.core_seen == snapshot, "core_seen survives save/load")
	_assert(RunState._core_offer_active and RunState.pending_rewards.size() == 3, "open Core offer survives save/load")
	# the pool runs dry: later offers just get smaller, never repeat
	var ctx := CoreTestUtil.ctx([], RunState.core_seen.duplicate())
	var cnt := 0
	for sd in 20:
		for c in CoreOffer.build_offer(Rng.new(sd), 0, ctx, 3):
			_assert(not ctx["seen"].has(String(c["key"])), "no repeat")
			cnt += 1
	_done("t_core_seen")
