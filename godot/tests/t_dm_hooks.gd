extends Node
## dm_core_open / dm_core_hover / dm_core_pick are asked for at the right moments on the Core offer; hover is throttled.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Gacha.instant_override = 1
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	await get_tree().process_frame
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	for _i in 4:
		await get_tree().process_frame
	RunState.pending_rewards = CoreOffer.build_offer(Rng.new(13), 1, RunState._core_ctx(), 3)
	RunState._core_offer_active = true
	RunState.core_rerolled_slots = []
	RunState.core_reroll_left = 2
	RunState.set_phase(RunState.RunPhase.REWARD)
	rm.dm_log.clear()
	rm._show_reward_overlay("x")
	for _i in 3:
		await get_tree().process_frame
	_check(rm.dm_log.count("dm_core_open") == 1, "opening the Core offer asks for dm_core_open once")
	await get_tree().create_timer(0.15).timeout   # the auto focus on card 0 may have just ticked
	rm.dm_log.clear()
	rm._dm_core_hover()
	rm._dm_core_hover()
	_check(rm.dm_log.count("dm_core_hover") == 1, "two hovers inside 120 ms make one tick")
	await get_tree().create_timer(0.15).timeout
	rm._dm_core_hover()
	_check(rm.dm_log.count("dm_core_hover") == 2, "a hover after 120 ms ticks again")
	rm.dm_log.clear()
	rm._take_selected_reward()
	_check(rm.dm_log.has("dm_core_pick"), "Take on a Core asks for dm_core_pick")
	for k in ["dm_set4", "dm_land", "dm_pair", "dm_core_open", "dm_core_hover", "dm_core_pick"]:
		_check(DiceMomentAudio.EVENTS.has(k) and DiceMomentAudio.EVENTS[k].has("layers"), "%s has a layered sound" % k)
	UI3Gacha.instant_override = -1
	print("=== t_dm_hooks: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	for f in _fails:
		print("FAIL: ", f)
	_guard.restore()
	if _fails.is_empty():
		print("t_dm_hooks: PASS")
	get_tree().quit(0 if _fails.is_empty() else 1)
