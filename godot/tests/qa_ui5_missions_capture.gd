extends Node
## QA (not headless): the 16 frames 40-missions--* of round-3 at the window size (1920x1080 or 1280x720, scale pinned
## like qa_ui5_pin). State comes from MetaState / screen flags only. Files: <UI5_SHOT_DIR>/<frame id>-WxH.png
##   UI5_SHOT_DIR=.../production/qa/ui05-b23/s5 godot/tools/shot.sh res://tests/qa_ui5_missions_capture.tscn 1280x720
const Util := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()


func _frame(id: String, unlocked: Array, shards: int, pick: String, setup: Callable = Callable(), remote := false, runs := 9) -> void:
	MetaState.runs = runs
	MetaState.runs_with_battle = runs
	MetaState.shard_pool = shards
	MetaState.starter_shard_locked = 0
	MetaState.mission_escrow = {}
	MetaState.set_mission_unlocks(unlocked, false)
	var s: MissionsScreen = load("res://scenes/missions/MissionsScreen.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	s.test_mode = true
	s.remote_on = remote
	s.day_override = "2026-10-12"
	add_child(s)
	for i in 4:
		await get_tree().process_frame
	if pick != "":
		s.select_tier(pick)
	if setup.is_valid():
		setup.call(s)
	for i in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	Util.save(get_viewport(), id)
	s.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	ProjectSettings.set_setting("axie/gem_wallet", "local")
	MetaState.saved_run_probe = func() -> bool: return false
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	var n3 := ["N1", "N2", "N3"]
	await _frame("40-missions--open", n3, 4200, "")
	await _frame("40-missions--picked", n3, 4200, "N3")
	await _frame("40-missions--challenge", ["N1", "N2", "N3", "N4", "N5"], 4200, "N5")
	await _frame("40-missions--title-tier", ["N1", "N2", "N3", "N4", "N5", "N6"], 5000, "N6")
	await _frame("40-missions--locked", n3, 4200, "N4")
	await _frame("40-missions--need-shards", ["N1", "N2", "N3", "N4"], 1000, "N4")
	await _frame("40-missions--guest", n3, 4200, "", func(s: MissionsScreen) -> void: s.set_state("guest"), true)
	await _frame("40-missions--offline", n3, 4200, "", func(s: MissionsScreen) -> void: s.set_state("offline"), true)
	await _frame("40-missions--newcomer", [], 4200, "N1", Callable(), false, 2)
	var cfg := MissionBoard.config()
	var t2: Dictionary = (cfg.tiers as Dictionary)["N2"]
	t2["enabled"] = false
	await _frame("40-missions--closed", ["N1", "N2"], 4200, "N2")
	t2["enabled"] = true
	await _frame("40-missions--loading", n3, 4200, "", func(s: MissionsScreen) -> void: s.set_state("loading"))
	await _frame("40-missions--checking", n3, 4200, "", func(s: MissionsScreen) -> void:
		s._syncing = true
		s._refresh())
	await _frame("40-missions--confirm", n3, 4200, "N3", func(s: MissionsScreen) -> void: s.open_confirm("N3"))
	await _frame("40-missions--open-run", n3, 4200, "", func(s: MissionsScreen) -> void: s.set_state("open_run"))
	await _frame("40-missions--refund", n3, 4200, "", func(s: MissionsScreen) -> void:
		s._banner("Old run, stake refunded", "That mission started before an update, so your 800 Shards stake was returned.", &"ok"))
	await _frame("40-missions--error", n3, 4200, "", func(s: MissionsScreen) -> void:
		s._banner("Could not take the stake", "Nothing was spent.", &"error"))
	MetaState.saved_run_probe = Callable()
	_guard.restore()
	get_tree().quit(0)
