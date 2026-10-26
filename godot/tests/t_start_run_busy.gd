extends Node
## Start run is slow (server may have to close an old run first): the button goes busy at once, says why,
## ignores a second click, and comes back when the call ends (ok or error). Same for Missions.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()
var _calls := 0
var _gate := false


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _slow(_p: Dictionary) -> Dictionary:
	_calls += 1
	while not _gate:
		await get_tree().process_frame
	_gate = false
	return {"ok": _next_ok, "code": "" if _next_ok else (_code if _code != "" else "net")}

var _next_ok := false
var _code := ""


func _make_setup() -> RunSetup:
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.state = "normal"
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.start_hook = _slow
	s.daily_info_hook = func(cb: Callable) -> void: cb.call(true, {"used": 0, "max": 3})
	add_child(s)
	await get_tree().process_frame
	return s


func _ready() -> void:
	print("=== t_start_run_busy: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	MetaState.asc_max = 3
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	MetaState.runs_completed = 9
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.state = "normal"
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.start_hook = _slow
	s.daily_info_hook = func(cb: Callable) -> void: cb.call(true, {"used": 0, "max": 3})
	add_child(s)
	await get_tree().process_frame
	var b: Button = s.find_child("Begin", true, false)
	_ok(b != null and not b.disabled, "Begin starts enabled")
	var label0 := b.text
	b.pressed.emit()
	await get_tree().process_frame
	_ok(_calls == 1, "first click calls begin once")
	_ok(b.disabled, "busy: disabled")
	_ok(b.text.begins_with("Starting"), "busy: says why (%s)" % b.text)
	var r2: Dictionary = await s.begin()
	b.pressed.emit()
	await get_tree().process_frame
	_ok(_calls == 1 and String(r2.get("code", "")) == "busy", "second click does not call begin again")
	s._on_start_phase("closing_old")
	_ok(b.text.contains("Closing your old run"), "old-run step is named (%s)" % b.text)
	_gate = true
	_next_ok = false
	for i in 4:
		await get_tree().process_frame
	_ok(not b.disabled and b.text == label0, "error: button back to normal (%s)" % b.text)
	b.pressed.emit()
	await get_tree().process_frame
	_ok(_calls == 2 and b.disabled, "can retry after an error")
	_gate = true
	_next_ok = true
	for i in 4:
		await get_tree().process_frame
	_ok(not b.disabled, "ok (no scene change): button back")
	s.queue_free()

	# 409 -> run_in_progress: open_run state, button usable again afterwards.
	var s2 := await _make_setup()
	var b2: Button = s2.find_child("Begin", true, false)
	_code = "run_in_progress"
	_next_ok = false
	b2.pressed.emit()
	await get_tree().process_frame
	_ok(b2.disabled, "409 case: busy while waiting")
	_gate = true
	for i in 4:
		await get_tree().process_frame
	_ok(s2.state == "open_run" and not s2._busy, "run_in_progress: open_run state, busy cleared")
	s2.queue_free()
	# unauthenticated -> guest, busy cleared.
	var s3 := await _make_setup()
	_code = "unauthenticated"
	_next_ok = false
	(s3.find_child("Begin", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_gate = true
	for i in 4:
		await get_tree().process_frame
	_ok(s3.state == "guest" and not s3._busy, "unauthenticated: guest state, busy cleared")
	s3.queue_free()
	# change_scene fails (RUN_MAP missing): busy cleared and a reason shown.
	var s4 := await _make_setup()
	s4.no_scene_change = false
	s4.run_map_override = "res://nope_missing.tscn"
	_code = ""
	_next_ok = true
	(s4.find_child("Begin", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_gate = true
	for i in 4:
		await get_tree().process_frame
	_ok(not s4._busy and s4.begin_error != "", "change_scene error: busy cleared, reason set")
	s4.queue_free()
	# Hung call: the guard timer releases the button and says so.
	var s5 := await _make_setup()
	s5.start_timeout_s = 0.2
	_code = ""
	_next_ok = false
	(s5.find_child("Begin", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_ok(s5._busy, "timeout case: busy at first")
	await get_tree().create_timer(0.5).timeout
	_ok(not s5._busy and not (s5.find_child("Begin", true, false) as Button).disabled, "timeout: button released")
	_ok(s5.find_child("Banner", true, false) != null or s5._banner_host.get_child_count() > 0, "timeout: banner shown")
	_gate = true
	s5.queue_free()

	# Missions: idle stake buttons are not stuck on the busy text.
	var m: MissionsScreen = load("res://scenes/missions/MissionsScreen.tscn").instantiate()
	m.test_mode = true
	m.no_scene_change = true
	m.start_hook = _slow
	m.use_account = false
	add_child(m)
	await get_tree().process_frame
	_ok(m.block_reason("N1", false) != "Starting…", "mission idle is not 'Starting…'")
	m.queue_free()

	_guard.restore()
	if _fail.is_empty():
		print("PASS t_start_run_busy (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		get_tree().quit(1)
