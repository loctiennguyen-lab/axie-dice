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
	await _a5_spin()
	await _banner()
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


func _offer_with(keys: Array) -> void:
	if rm != null:
		rm.queue_free()
	UI3Gacha.reset_seen()
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(4)
	var cards: Array[Dictionary] = []
	for i in keys.size():
		cards.append(CoreOffer.card_of(RelicRegistry.get_def(String(keys[i])), i))
	RunState.pending_rewards = cards
	RunState._core_offer_active = true
	RunState.set_phase(RunState.RunPhase.REWARD)
	rm._show_reward_overlay("x")
	await _frames(3)


func _a5_spin() -> void:
	# pure schedule: sums to 2.0 s, slows down, ends on the result
	var sch := GachaFx.spin_schedule(2.0, 16)
	var sum := 0.0
	for v in sch:
		sum += v
	_check(absf(sum - 2.0) < 0.001 and sch[15] > sch[0] * 3.0, "spin schedule: 2.0 s total, slows down")
	var faces := GachaFx.spin_faces(["A", "B", "C"], "B", 16)
	_check(faces[15] == "B" and faces.size() == 16 and faces.has("A"), "spin faces cycle the pool and end on the result")
	await _offer_with(["c_dim_stone", "c_nest", "c_kindle"])
	await _wait(1.0)
	var before: Array = RunState.owned_relic_ids.duplicate()
	rm.gacha_log.clear()
	rm._select_reward(0)
	rm._take_selected_reward()
	await _frames(2)
	var fx := rm._overlay_root.find_child("GachaSpin", true, false) as GachaFx
	_check(fx != null and fx.running, "spin plate is running after taking Dim Stone")
	var granted := ""
	for id in RunState.owned_relic_ids:
		if not before.has(id):
			granted = String(RelicRegistry.get_def(String(id)).name)
	_check(granted != "" and int(RelicRegistry.get_def(RunState.owned_relic_ids[-1]).rarity) == 2, "the Core granted is already Crystal before the spin ends")
	var shot := OS.get_environment("AXIE_SHOT_SPIN")
	await _wait(0.8)
	var mid := (fx.find_child("SpinName", true, false) as Label).text
	_check(mid != "" and fx.running, "mid-spin shows a pool name")
	await _wait(1.4)   # 2.2 s since start: stop reached, still holding
	_check(fx.events.has("stop") and (fx.find_child("SpinName", true, false) as Label).text == UI3.title_case(UI3.player_text(granted)), "spin stops on the granted Core")
	await _wait(0.7)
	_check(not rm._overlay_root.visible, "overlay closes after the hold")
	# click skips
	await _offer_with(["c_dim_stone", "c_nest", "c_kindle"])
	await _wait(1.0)
	rm._select_reward(0)
	rm._take_selected_reward()
	await _frames(2)
	fx = rm._overlay_root.find_child("GachaSpin", true, false) as GachaFx
	var after_take: Array = RunState.owned_relic_ids.duplicate()
	var evs: Array[String] = fx.events
	fx.skip()
	await _frames(3)
	_check(evs.has("skip") and RunState.owned_relic_ids == after_take, "skipping the spin does not change the result")


func _banner() -> void:
	RunState.owned_relic_ids.append("c_nest")
	await _offer_with(["c_golden_egg", "c_kindle", "c_dewdrop"])
	await _wait(1.0)
	# B2/B3 labels on the cards
	var c0: Control = rm._reward_cards[0]
	var tag := c0.find_child("ComboTag", true, false) as Label
	_check(tag != null and tag.text.begins_with("PAIR!"), "card that completes a Pair says PAIR!")
	_check(c0.find_child("WorksWith", true, false) != null and String((c0.find_child("WorksWith", true, false) as Label).text).contains("Nest"), "Works with lists the owned partner")
	_check((rm._reward_cards[1] as Control).find_child("ComboTag", true, false) == null, "other cards have no combo label")
	_check(not tag.text.contains("1/2") and rm._overlay_root.find_child("ComboProgress", true, false) == null, "no 1/2 label, no progress bar")
	rm.gacha_log.clear()
	rm._select_reward(0)
	rm._take_selected_reward()
	await _frames(3)
	_check(rm.gacha_log.has("banner:pair"), "taking the Pair card raises the PAIR banner")
	var ban: Node = rm._overlay_layer.find_child("ComboBanner", true, false)
	_check(ban != null and ban.mouse_filter == Control.MOUSE_FILTER_IGNORE, "banner is click-through")
	var shot := OS.get_environment("AXIE_SHOT_PAIR")
	if shot != "" and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(shot)
	await _wait(1.4)
	_check(rm._overlay_layer.find_child("ComboBanner", true, false) == null, "pair banner gone after 1.2 s")
	RunState.owned_relic_ids.append("c_golden_egg")
	await _offer_with(["c_spore_burst", "c_kindle", "c_dewdrop"])
	await _wait(1.0)
	rm.gacha_log.clear()
	rm._select_reward(0)
	rm._take_selected_reward()
	await _frames(3)
	_check(rm.gacha_log.has("banner:full"), "taking the third Core raises the FULL banner")
	ban = rm._overlay_layer.find_child("ComboBanner", true, false)
	_check(ban != null, "full banner is up")
	await _wait(1.4)
	_check(rm._overlay_layer.find_child("ComboBanner", true, false) != null, "full banner outlasts the pair length (1.8 s)")
	await _wait(0.7)
	_check(rm._overlay_layer.find_child("ComboBanner", true, false) == null, "full banner gone after 1.8 s")
