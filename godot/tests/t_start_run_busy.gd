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
	return {"ok": _next_ok, "code": "" if _next_ok else "net"}

var _next_ok := false


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

	# Missions: already busy-locks every stake button while starting (own_start excepted).
	var m: MissionsScreen = load("res://scenes/missions/MissionsScreen.tscn").instantiate()
	m.test_mode = true
	m.no_scene_change = true
	m.start_hook = _slow
	m.use_account = false
	add_child(m)
	await get_tree().process_frame
	_ok(m.block_reason("N1", false) == "" or m.block_reason("N1", false) != "Starting...", "mission idle is not 'Starting...'")
	m.queue_free()

	_guard.restore()
	if _fail.is_empty():
		print("PASS t_start_run_busy (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		get_tree().quit(1)
