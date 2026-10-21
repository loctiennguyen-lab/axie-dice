extends Node
## Gacha A1: timing plan from gacha_timing.json, face-down -> halo -> staggered flip, skip, no next-tier leak.
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
	# Pure plan against the contract table.
	var p0 := UI3Gacha.plan(3, 0, true, false, false)
	var p1 := UI3Gacha.plan(3, 1, true, false, false)
	var p2 := UI3Gacha.plan(3, 2, true, false, false)
	var pr := UI3Gacha.plan(3, 2, false, false, false)
	_check(is_equal_approx(p0["aura"], 0.6) and is_equal_approx(p1["aura"], 0.9) and is_equal_approx(p2["aura"], 1.5), "aura 0.6 / 0.9 / 1.5 first time")
	_check(is_equal_approx(pr["aura"], 0.4), "repeat tier aura 0.4")
	_check(is_equal_approx(p2["flips"][1] - p2["flips"][0], 0.18) and is_equal_approx(p2["flip"], 0.35), "stagger 180 ms, flip 0.35")
	var pj := UI3Gacha.plan(3, 2, true, true, false)
	_check(is_equal_approx(pj["total"] - p2["total"], 0.6), "jackpot adds 0.6 s")
	_check(is_equal_approx(UI3Gacha.plan(3, 2, true, true, true)["total"], p2["total"]), "reduce flashing drops jackpot extra")
	_check(UI3Gacha.first_seen("a", 2) and not UI3Gacha.first_seen("a", 2) and UI3Gacha.first_seen("b", 2), "first-seen is per run")
	# Overlay: bonus Crystal offer.
	UI3Gacha.instant_override = 0
	UI3Gacha.reset_seen()
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	await _frames(2)
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(4)
	RunState.pending_rewards = CoreOffer.build_offer(Rng.new(13), 2, RunState._core_ctx(), 3)
	RunState._core_offer_active = true
	RunState.set_phase(RunState.RunPhase.REWARD)
	rm._show_reward_overlay("x")
	await _frames(3)
	var rev: GachaReveal = rm._reveal
	_check(rev != null and rev.running, "reveal running on a Core offer")
	var card: Control = rm._reward_cards[0]
	_check(card.find_child("CardBack", true, false) != null, "cards start face-down")
	_check(rm._overlay_root.find_child("NextTierChip", true, false) == null, "no next-tier chip")
	var shot := OS.get_environment("AXIE_SHOT")
	if shot != "" and DisplayServer.get_name() != "headless":
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png(shot)
	await get_tree().create_timer(2.2).timeout
	_check(rev.events.has("flip:2") and not rev.running, "flips left to right then finishes")
	_check(card.find_child("CardBack", true, false) == null, "cover gone after flip")
	var c2: Control = rm._reward_cards[0]
	_check(c2.has_meta("prism_accent") and c2.find_child("PrismFrame", true, false) != null, "Crystal card has the prism frame")
	_check((c2.find_child("RewardName", true, false) as Label).theme_type_variation == "LabelTitle", "Crystal name is size 24")
	# Skip: new offer, then a click.
	RunState.pending_rewards = []
	rm._close_overlay()
	RunState.pending_rewards = CoreOffer.build_offer(Rng.new(14), 1, RunState._core_ctx(), 3)
	RunState._core_offer_active = true
	rm._show_reward_overlay("x")
	await _frames(3)
	rev = rm._reveal
	_check(rev != null and rev.running, "second reveal running")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await _frames(3)
	_check(not rev.running and rev.events.has("skip"), "click skips the rest")
	_check((rm._reward_cards[0] as Control).scale == Vector2.ONE, "card restored after skip")
	UI3Gacha.instant_override = -1
	print("=== t_gacha_reveal: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	_guard.restore()
	if _fails.is_empty():
		print("t_gacha_reveal: PASS")
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_gacha_reveal: FAIL - " + f)
		get_tree().quit(1)
