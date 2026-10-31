extends Node
## QA (not headless): frames event--choices / event--outcome / 13-treasure--closed / 13-treasure--opened at the window size,
## scale pinned. Stand-in outcome and rewards; names come from ContentDB.
##   UI5_SHOT_DIR=.../production/qa/ui05-b23/r5b godot/tools/shot.sh res://tests/qa_ui5_event_treasure_capture.tscn 1280x720
const Util := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()
var rm: Node


func _snap(id: String) -> void:
	for i in 12:
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
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	for i in 8:
		await get_tree().process_frame
	RunState.shards_this_run = 40
	for k in ContentDB.events.keys():
		RunState.event_key = String(k)
		if RunState.event_options().size() >= 3:
			break
	rm.call("_on_event_node", "x")
	await _snap("event--choices")
	rm.call("_build_event_screen", 2, "The party feels stronger.")
	await _snap("event--outcome")
	RunState.pending_rewards.assign([
		{"t": "relic", "key": "x0", "rar": 0, "title": "MAX HP", "desc": "Reward one", "sub": "A stand-in reward."},
		{"t": "relic", "key": "x1", "rar": 1, "title": "REROLL", "desc": "Reward two", "sub": "A stand-in reward."},
		{"t": "relic", "key": "x2", "rar": 2, "title": "TIER UP", "desc": "Reward three", "sub": "A stand-in reward."}])
	rm.call("_build_treasure", false)
	await _snap("13-treasure--closed")
	rm.call("_build_treasure", true)
	await _snap("13-treasure--opened")
	UI3Theme.set_scale_override(-1.0)
	RunState.pending_rewards.assign([])
	_guard.restore()
	get_tree().quit(0)
