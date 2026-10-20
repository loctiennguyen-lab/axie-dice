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
	_start(31)
	RunState.apply_chosen_reward(RunState.pending_rewards[0]); RunState.after_node()
	RunState._grant_relic("c_test_quest_amber", "test")
	_assert(RunState.core_quest_progress.has("c_test_quest_amber"), "quest tracked from the grant")
	# 2 wins -> step 1 pays an amber offer; 4 wins -> step 2 pays a crystal offer and the quest Core is gone
	RunState.note_quest_event("elite")
	_assert(RunState.core_bonus_queue.is_empty(), "other kind does not count")
	RunState.note_quest_event("wins")
	_assert(RunState.core_bonus_queue.is_empty() and int(RunState.core_quest_progress["c_test_quest_amber"]["progress"]) == 1, "1/2")
	RunState.note_quest_event("wins")
	_assert(RunState.core_bonus_queue == [1], "step 1 done: amber reward queued at once")
	_assert(RunState.owned_relic_ids.has("c_test_quest_amber"), "quest stays after step 1")
	RunState.note_quest_event("wins", 2)
	_assert(RunState.core_bonus_queue == [1, 2], "step 2 done: crystal reward queued")
	_assert(not RunState.owned_relic_ids.has("c_test_quest_amber") and RunState.core_quest_progress.is_empty(), "finished quest disappears")
	# the queue opens at the next after_node, one offer at a time, not counted as a milestone pick
	var picks := RunState.core_pick_index
	var g := RunMapGraph.from_data(RunState.map_graph)
	RunState.current_node_id = g.get_row(2)[0].id
	RunState.after_node()
	_assert(RunState.phase == RunState.RunPhase.REWARD and RunState._core_offer_active, "bonus offer opens")
	_assert(int(RunState.pending_rewards[0]["tier"]) == 1 or String(RunState.pending_rewards[0]["axis"]) == "stat", "amber offer")
	RunState.apply_chosen_reward(RunState.pending_rewards[0]); RunState.after_node()
	_assert(RunState.phase == RunState.RunPhase.REWARD and RunState.core_bonus_queue.is_empty(), "second bonus follows")
	_assert(int(RunState.pending_rewards[0]["tier"]) == 2 or String(RunState.pending_rewards[0]["axis"]) == "stat", "crystal offer")
	RunState.apply_chosen_reward(RunState.pending_rewards[0]); RunState.after_node()
	_assert(RunState.phase == RunState.RunPhase.MAP and RunState.core_pick_index == picks, "back on the map, milestone count untouched")
	# a combat win feeds the tracker
	RunState.reset()
	_start(32)
	RunState.apply_chosen_reward(RunState.pending_rewards[0]); RunState.after_node()
	RunState._grant_relic("c_test_quest_amber", "test")
	RunState.current_node_id = RunMapGraph.from_data(RunState.map_graph).get_row(1)[0].id
	RunState.apply_combat_result({"won": true, "kind": "battle", "pw": 0, "shards_earned": 0}, 5)
	_assert(int(RunState.core_quest_progress["c_test_quest_amber"]["progress"]) == 1, "won battle counts")
	_done("t_core_quest")
