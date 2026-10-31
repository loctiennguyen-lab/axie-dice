extends Node
## QA (not headless): Core offer frames 47-core-offer--* (face-down, moss, amber, crystal, selected, reroll-used, rerolls-none)
## at the window size, scale pinned like qa_ui5_pin. Offers are stand-ins; names / numbers are never from the HTML.
##   UI5_SHOT_DIR=.../production/qa/ui05-b23/r2 godot/tools/shot.sh res://tests/qa_ui5_core_offer_capture.tscn 1280x720
const Util := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()
var rm: Node


func _cards(tier: int, n: int) -> Array:
	var out: Array = []
	var axes := ["pos", "stat", "mana", "dice"]
	for i in n:
		out.append({"t": "relic", "key": "x%d" % i, "rar": 0, "title": "CORE", "desc": "Core %d" % (i + 1),
			"sub": "A sample rule for Core %d that is long enough to wrap onto a second and a third line." % (i + 1),
			"core": true, "axis": axes[i % 4], "tier": tier, "slot": i})
	return out


func _frame(id: String, cards: Array, instant: bool, pick := -1, left := 2, rerolled: Array[int] = []) -> void:
	UI3Gacha.instant_override = 1 if instant else 0
	RunState._core_offer_active = true
	RunState.core_reroll_left = left
	RunState.core_rerolled_slots.assign(rerolled)
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
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	await get_tree().process_frame
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	for i in 8:
		await get_tree().process_frame
	RunState.shards_this_run = 40
	await _frame("47-core-offer--facedown", _cards(0, 3), false)
	await _frame("47-core-offer--moss", _cards(0, 3), true)
	await _frame("47-core-offer--pick1-4cards", _cards(0, 4), true)
	await _frame("47-core-offer--amber", _cards(1, 3), true)
	await _frame("47-core-offer--crystal", _cards(2, 3), true)
	await _frame("47-core-offer--selected", _cards(1, 3), true, 0)
	await _frame("47-core-offer--reroll-used", _cards(1, 3), true, 0, 1, [1] as Array[int])
	await _frame("47-core-offer--rerolls-none", _cards(1, 3), true, -1, 0)
	UI3Gacha.instant_override = -1
	_guard.restore()
	get_tree().quit(0)
