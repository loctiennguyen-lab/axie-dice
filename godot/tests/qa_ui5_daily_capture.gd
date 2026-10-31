extends Node
## QA-only, UI-05 b23 lane S11a: shots of 41-daily--* . Scale pinned from the window.
##   ADT_EVIDENCE_DIR=production/qa/ui05-b23/s11a godot/tools/shot.sh res://tests/qa_ui5_daily_capture.tscn 1280x720
var _guard := SaveGuard.new()
var _dir := QaPaths.evidence_dir()


func _shot(frame: String, small: bool) -> void:
	for _i in 10:
		await get_tree().process_frame
	var path := "%s/%s%s.png" % [_dir, frame, "--1280" if small else ""]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui5_daily_capture: saved ", path)


func _make(state: String, remote: bool) -> DailyScreen:
	var d: DailyScreen = load("res://scenes/daily/DailyScreen.tscn").instantiate()
	d.use_account = false
	d.state = state
	d.remote_on = remote
	d.no_scene_change = true
	d.test_mode = true
	d.day_override = MetaState.today_utc()
	add_child(d)
	return d


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_dir)
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	var today := MetaState.today_utc()
	var wk := MetaState.weekly_daily_days()
	MetaState.gem_gift_day = ""
	MetaState.gems_cache = 300
	MetaState.daily_date = ""
	var d := _make("normal", false)
	await _shot("41-daily--unclaimed", small)
	d.claim_daily()
	await get_tree().process_frame
	await _shot("41-daily--gem-gift", small)
	d.claim_gift()
	await _shot("41-daily--claimed", small)
	MetaState.gem_gift_day = ""
	MetaState.gems_cache = 900
	d._refresh()
	await _shot("41-daily--weekly-gem-cap", small)
	MetaState.gems_cache = 300
	d._gift_pending = true
	d._refresh()
	await _shot("41-daily--claiming", small)
	d.queue_free()
	MetaState.daily_date = ""
	MetaState.gem_gift_day = ""
	var o := _make("offline", true)
	await _shot("41-daily--offline", small)
	o.queue_free()
	var g := _make("guest", true)
	await _shot("41-daily--guest", small)
	_guard.restore()
	get_tree().quit(0)
