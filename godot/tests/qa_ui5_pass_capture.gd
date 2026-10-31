extends Node
## QA (not headless): the frames 21-pass--* of round-3 at the window size (1920x1080 or 1280x720, scale pinned).
##   UI5_SHOT_DIR=.../production/qa/ui05-b23/s10 godot/tools/shot.sh res://tests/qa_ui5_pass_capture.tscn 1280x720
const Util := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()


func _frame(id: String, day: String, xp: int, claimed: Array, setup: Callable = Callable(), state := "normal") -> void:
	MetaState.pass_season = PassV2.new_state("s1")
	MetaState.pass_season["xp"] = xp
	MetaState.pass_season["claimed_free"] = claimed.duplicate()
	var s: PassView = load("res://scenes/pass/Pass.tscn").instantiate()
	s.use_account = false
	s.state = state
	s.no_scene_change = true
	s.today_override = day
	add_child(s)
	for i in 4:
		await get_tree().process_frame
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
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	var l10 := int(PassV2.level_def(10).get("xp_total", 0)) + 100
	var live := "2026-11-10"
	var w := PassV2.week_key(live)
	var tasks := func() -> void:
		MetaState.pass_season["weekly"] = {w: {"runs": 5, "wins": 2, "boss": 0, "claimed": ["win_runs"]}}
	await _frame("21-pass--before", "2026-10-12", 0, [])
	tasks.call()
	await _frame("21-pass--live", live, l10, [1, 2, 3, 4, 5, 6, 7], func(s: PassView) -> void: tasks.call(); s.refresh())
	await _frame("21-pass--detail", live, l10, [1, 2, 3, 4, 5, 6, 7], func(s: PassView) -> void: tasks.call(); s.refresh(); s.select_level(9))
	await _frame("21-pass--claimed", live, l10, [1, 2, 3, 4, 5, 6, 7], func(s: PassView) -> void: tasks.call(); s.refresh(); s.claim_all())
	await _frame("21-pass--scrolled", live, l10, [1, 2, 3, 4, 5, 6, 7], func(s: PassView) -> void:
		tasks.call(); s.refresh()
		(s.find_child("TrackScroll", true, false) as ScrollContainer).scroll_vertical = 100000
		s.select_level(25))
	await _frame("21-pass--popup", live, l10, [1, 2, 3, 4, 5, 6, 7], func(s: PassView) -> void: tasks.call(); s.refresh(); s.open_reward(9))
	await _frame("21-pass--loop", live, 200000, range(1, 31))
	await _frame("21-pass--over", "2027-01-05", int(PassV2.level_def(12).get("xp_total", 0)) + 10, range(1, 12))
	await _frame("21-pass--offline", live, l10, [1, 2, 3, 4, 5, 6, 7], Callable(), "offline")
	await _frame("21-pass--guest", live, l10, [1, 2, 3, 4, 5, 6, 7], Callable(), "guest")
	_guard.restore()
	get_tree().quit(0)
