extends Node
## Manual visual QA for gacha moments (non-headless): tools/shot.sh res://tests/qa_gacha_moments_capture.tscn 1280x720
var _guard := SaveGuard.new()
var rm: Node


func _snap(name: String) -> void:
	var tag := "%dx%d" % [int(DisplayServer.window_get_size().x), int(DisplayServer.window_get_size().y)]
	var dir := QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/gacha_pick_%s_%s.png" % [dir, name, tag])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _open(tier: int, seed := 13) -> void:
	if rm != null:
		rm.queue_free()
	UI3Gacha.reset_seen()
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await get_tree().process_frame
	await get_tree().process_frame
	RunState.pending_rewards = CoreOffer.build_offer(Rng.new(seed), tier, RunState._core_ctx(), 3)
	RunState._core_offer_active = true
	RunState.core_rerolled_slots = []
	RunState.core_reroll_left = 2
	RunState.set_phase(RunState.RunPhase.REWARD)
	rm._show_reward_overlay("x")


func _offer_with(keys: Array) -> void:
	if rm != null:
		rm.queue_free()
	UI3Gacha.reset_seen()
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await get_tree().process_frame
	await get_tree().process_frame
	var cards: Array[Dictionary] = []
	for i in keys.size():
		cards.append(CoreOffer.card_of(RelicRegistry.get_def(String(keys[i])), i))
	RunState.pending_rewards = cards
	RunState._core_offer_active = true
	RunState.set_phase(RunState.RunPhase.REWARD)
	rm._show_reward_overlay("x")


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Gacha.instant_override = 0
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	await get_tree().process_frame
	await _open(1)
	await _wait(1.8)
	rm._on_core_card_reroll(0)
	await _wait(0.75)
	_snap("reroll")
	await _wait(1.0)
	await _offer_with(["c_dim_stone", "c_nest", "c_kindle"])
	await _wait(1.8)
	rm._select_reward(0)
	rm._take_selected_reward()
	await _wait(0.9)
	_snap("spin")
	await _wait(2.0)
	RunState.owned_relic_ids.append("c_nest")
	await _offer_with(["c_golden_egg", "c_kindle", "c_dewdrop"])
	await _wait(2.2)
	_snap("pair_label")
	rm._select_reward(0)
	rm._take_selected_reward()
	await _wait(0.4)
	_snap("banner_pair")
	await _wait(1.5)
	RunState.owned_relic_ids.append("c_golden_egg")
	await _offer_with(["c_spore_burst", "c_kindle", "c_dewdrop"])
	await _wait(2.2)
	_snap("full_label")
	rm._select_reward(0)
	rm._take_selected_reward()
	await _wait(0.5)
	_snap("banner_full")
	RunState.owned_relic_ids.assign(["c_cascade", "c_blood_sign", "c_deep_current"])
	RunState.core_tier_chain = [2, 2, 2, 2, 2, 2]
	RunState._core_offer_pick = 1
	RunState.core_pick_index = 2
	await _open(1)
	await _wait(1.2)
	_snap("nearmiss_before")
	await _wait(0.5)
	_snap("nearmiss_crack")
	_guard.restore()
	get_tree().quit(0)
