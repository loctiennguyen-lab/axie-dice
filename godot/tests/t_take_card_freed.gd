extends Node
## Regression (UI-04 review): the Core take beat awaited `take_tw.finished`. If the picked card / overlay is freed
## mid-tween the tween dies without emitting, `_taking` stayed true and the node never finished (map stuck).
## Free the picked card right after Take and assert the node still finishes and the map comes back.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame

func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": true})
	await _frames(2)
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)
	rm._select_reward(1)
	await _frames(2)
	rm._take_selected_reward()   # Run Rule pick -> Core offer opens
	await _frames(8)
	_check(RunState._core_offer_active and not RunState.pending_rewards.is_empty(), "Core offer is up")
	rm._select_reward(0)
	await _frames(2)
	var card: Node = rm._reward_cards[0]
	rm._take_selected_reward()
	await _frames(1)
	_check(rm._taking, "take is in progress")
	card.queue_free()   # the card dies mid-tween
	await get_tree().create_timer(1.6).timeout   # cap is 1 s
	await _frames(4)
	_check(not rm._taking, "_taking cleared after the card was freed mid-take")
	_check(RunState.pending_rewards.is_empty(), "node finished: no pending offer")
	_check(RelicSlots.owned_cores(RunState.owned_relic_ids).size() == 1, "the Core was taken")
	print("=== t_take_card_freed: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	_guard.restore()
	if _fails.is_empty():
		print("t_take_card_freed: PASS")
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_take_card_freed: FAIL - " + f)
		get_tree().quit(1)
