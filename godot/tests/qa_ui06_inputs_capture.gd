extends Node
## QA (not headless): Core offer with REAL Cores for the UI-06 Claude Design inputs (the 47-* QA captures use stand-ins).
##   UI5_SHOT_DIR=<dir> godot/tools/shot.sh res://tests/qa_ui06_inputs_capture.tscn 1920x1080
const Util := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()
var rm: Node


func _cards(ids: Array) -> Array:
	var out: Array = []
	for i in ids.size():
		out.append(CoreOffer.card_of(RelicRegistry.get_def(String(ids[i])), i))
	return out


func _frame(id: String, cards: Array, instant: bool, pick := -1) -> void:
	UI3Gacha.instant_override = 1 if instant else 0
	RunState._core_offer_active = true
	RunState.core_reroll_left = 2
	RunState.core_rerolled_slots.assign([] as Array[int])
	RunState.pending_rewards.assign(cards)
	rm._show_reward_overlay("x")
	for i in 6:
		await get_tree().process_frame
	if pick >= 0:
		rm._select_reward(pick)
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	Util.save(get_viewport(), id)


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Theme.set_scale_override(2.0 / 3.0 if get_window().size.x < 1600 else 1.0)
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	await get_tree().process_frame
	# a new run opens Core pick 1 face-down at once: shoot it with real owned Cores, an Anchor and a Run Rule set
	RunState.anchor_id = "a_volley"
	RunState.run_rule = "rule_crow"
	RunState.owned_relic_ids.assign(["c_thorn_shield", "c_dewdrop", "c_concord", "c_deep_current"])
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	for i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	Util.save(get_viewport(), "real-47-core-offer--facedown")
	RunState.shards_this_run = 40
	await _frame("real-47-core-offer--moss", _cards(["c_finisher", "c_mana_pool", "c_tidecaller"]), true)
	await _frame("real-47-core-offer--amber", _cards(["c_thorn_shield", "c_backline_glow", "c_golden_thread"]), true)
	await _frame("real-47-core-offer--crystal", _cards(["c_concord", "c_deep_current", "c_blood_sign"]), true)
	await _frame("real-47-core-offer--pick1-4cards", _cards(["c_cache_plate", "c_descend", "c_chimera_hunt", "c_dewdrop"]), true, 1)
	UI3Gacha.instant_override = -1
	_guard.restore()
	get_tree().quit(0)
