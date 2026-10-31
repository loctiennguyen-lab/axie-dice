extends Node
## QA (not headless): 05-run-rule-offer--offer / --picked and a plain reward offer, window size, scale pinned.
##   UI5_SHOT_DIR=.../production/qa/ui05-b23/r2b godot/tools/shot.sh res://tests/qa_ui5_rule_offer_capture.tscn 1280x720
const Util := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()
var rm: Node


func _shot(id: String, pick := -1) -> void:
	rm._show_reward_overlay("x")
	for i in 8:
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
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": true})
	await get_tree().process_frame
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	for i in 8:
		await get_tree().process_frame
	await _shot("05-run-rule-offer--offer")
	var real: Dictionary = RunState.pending_rewards[0]
	var nd = RelicRegistry.get_def(CoreOffer.NO_RULE_ID)
	if nd != null:
		RunState.pending_rewards.assign([real, CoreOffer.rule_card_of(nd, 1)])
	await _shot("05-run-rule-offer--picked", 0)
	RunState._rule_offer_active = false
	RunState._core_offer_active = false
	RunState.reward_reroll_charges = 1
	var fake: Array = []
	for i in 3:
		fake.append({"t": "relic", "key": "x%d" % i, "rar": i, "title": "RELIC", "desc": "Sample %d" % (i + 1), "sub": "A sample effect that is long enough to wrap onto a second line."})
	RunState.pending_rewards.assign(fake)
	await _shot("31-reward-card", 1)
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)
