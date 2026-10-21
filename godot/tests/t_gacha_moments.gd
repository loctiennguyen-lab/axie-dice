extends Node
## Gacha pack UI moments: A7 reroll beat, A5 spin, A8 near-miss, B2/B3 labels, banners. Animation never changes a result.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []
var rm: Node


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _fresh_map(tier: int, seed := 13) -> void:
	if rm != null:
		rm.queue_free()
	UI3Gacha.reset_seen()
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(4)
	RunState.pending_rewards = CoreOffer.build_offer(Rng.new(seed), tier, RunState._core_ctx(), 3)
	RunState._core_offer_active = true
	RunState.core_rerolled_slots = []
	RunState.core_reroll_left = 2
	RunState.set_phase(RunState.RunPhase.REWARD)
	rm._show_reward_overlay("x")
	await _frames(3)


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Gacha.instant_override = 0
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	await _frames(2)
	await _a7_reroll()
	UI3Gacha.instant_override = -1
	print("=== t_gacha_moments: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	for f in _fails:
		print("FAIL: ", f)
	_guard.restore()
	if _fails.is_empty():
		print("t_gacha_moments: PASS")
	get_tree().quit(0 if _fails.is_empty() else 1)


func _a7_reroll() -> void:
	await _fresh_map(1)
	await _wait(1.6)   # first reveal done
	var old_keys: Array = RunState.pending_rewards.map(func(r): return String(r["key"]))
	var other1: Control = rm._reward_cards[1]
	var btn := rm._overlay_root.find_child("CardReroll0", true, false) as Button
	_check(btn != null and not btn.disabled, "reroll button on card 0 is live")
	rm.gacha_log.clear()
	rm._on_core_card_reroll(0)
	await _wait(0.15)
	_check(rm.gacha_log.has("reroll_out"), "old card flies out first")
	await _wait(0.5)
	_check(rm.gacha_log.has("reroll_in:0"), "new card arrives after the fly-out")
	var new_keys: Array = RunState.pending_rewards.map(func(r): return String(r["key"]))
	_check(new_keys[0] != old_keys[0] and new_keys[1] == old_keys[1] and new_keys[2] == old_keys[2], "only slot 0 changed")
	var c0: Control = rm._reward_cards[0]
	_check(c0.find_child("CardBack", true, false) != null, "new card is face-down")
	var c1: Control = rm._reward_cards[1]
	_check(c1.find_child("CardBack", true, false) == null, "other cards stay face-up")
	_check(rm._overlay_root.find_child("RerollNote", true, false) != null, "note 'Won't come back this run' shown")
	var shot := OS.get_environment("AXIE_SHOT_REROLL")
	if shot != "" and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(shot)
	await _wait(1.2)
	_check(c0.find_child("CardBack", true, false) == null and rm._reveal != null and not rm._reveal.running, "new card flipped up")
	_check(RunState.pending_rewards.map(func(r): return String(r["key"])) == new_keys, "animation did not change the offer")
