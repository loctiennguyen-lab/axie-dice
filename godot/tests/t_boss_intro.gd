extends Node
## Boss intro (52): data covers every boss, shows for the boss node only, skip by click / Fight / the
## boss_intro_skip key / Esc only after the 300 ms guard, purely presentational (RunState unchanged),
## never reachable from resume paths, Reduce flashing cuts instead of fading.
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
var _finished := 0


func _t(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _make(key: String) -> BossIntro:
	var i := BossIntro.new()
	_t(i.setup(key), "setup(%s)" % key)
	add_child(i)
	return i


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	return e


func _click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e


func _warm(i: BossIntro) -> void:
	# warm-up frames, then the 300 ms guard
	while i._t0 < 0:
		await get_tree().process_frame
	await get_tree().create_timer(0.36).timeout


func _src(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	MetaState.reduce_flash = false
	KeyBindings.reset_registration()

	# Data: every boss in ContentDB has an intro with a painting; unknown keys have none.
	for k in ContentDB.bosses.keys():
		var d := BossIntroData.info(String(k))
		_t(not d.is_empty() and ResourceLoader.exists(String(d.get("bg_path", ""))), "intro data for boss %s" % k)
		_t(String(d.get("threat", "")).length() <= 70, "threat line <= 70 chars (%s)" % k)
	_t(BossIntroData.info("nope").is_empty(), "unknown boss has no intro")
	_t(BossIntroData.info("agony")["bg_path"].ends_with("Chimera_BG_Venom.jpg"), "agony uses the Venom painting")

	# Key binding.
	_t(KeyBindings.keys_of(KeyBindings.BOSS_INTRO_SKIP).has(KEY_SPACE) and KeyBindings.keys_of(KeyBindings.BOSS_INTRO_SKIP).has(KEY_ENTER),
		"boss_intro_skip defaults to Space + Enter")
	_t(String(KeyBindings.def_of(KeyBindings.BOSS_INTRO_SKIP).get("group", "")) == "General", "boss_intro_skip is in General")

	var before := JSON.stringify(RunState.to_data())

	# Guard: nothing skips in the first 300 ms.
	var a := _make("agony")
	a.finished.connect(func() -> void: _finished += 1)
	await get_tree().process_frame
	a.skip()
	a._on_gui_input(_click())
	a._input(_key(KEY_ESCAPE))
	_t(not a.is_skipped, "inside the 300 ms guard nothing skips")
	await _warm(a)
	_t(a.plate != null and a.fight_button != null and a.find_child("Painting", true, false) != null, "plate, Fight and painting exist")
	_t(a.find_child("BossPivot", true, false).get_child_count() > 0, "a model stands in front of the painting")
	a._on_gui_input(_click())
	_t(a.is_skipped, "click skips after the guard")
	await get_tree().create_timer(0.5).timeout
	_t(_finished == 1, "finished fires once after the out-fade")
	a.queue_free()

	# Each other way of skipping.
	var b := _make("gooey_king")   # sprite-only boss still works
	await _warm(b)
	b.fight_button.pressed.emit()
	_t(b.is_skipped, "Fight skips")
	b.queue_free()
	var c := _make("mecha")
	await _warm(c)
	c._input(_key(KEY_SPACE))
	_t(c.is_skipped, "the boss_intro_skip key (Space) skips")
	c.queue_free()
	var d := _make("frost_lord")
	await _warm(d)
	d._input(_key(KEY_ESCAPE))
	_t(d.is_skipped, "Esc skips")
	d.queue_free()

	# Reduce flashing: cut, no fade.
	MetaState.reduce_flash = true
	var e := _make("agony")
	var got := [0]
	e.finished.connect(func() -> void: got[0] += 1)
	await _warm(e)
	e.skip()
	_t(got[0] == 1, "Reduce flashing: skip cuts at once")
	e.queue_free()
	MetaState.reduce_flash = false

	# Purely presentational: no change to the run state (no rule call, no seed drawn).
	_t(JSON.stringify(RunState.to_data()) == before, "RunState unchanged by the intro")

	# Hook: only the boss node goes through the intro; resume paths never reference it.
	var rm := _src("res://scenes/run_map/RunMapController.gd")
	_t(rm.contains("\"boss\":\n\t\t\t_enter_boss_fight()"), "run map boss node enters via _enter_boss_fight")
	_t(rm.contains("\"battle\", \"elite\":\n\t\t\tget_tree().change_scene_to_file"), "battle / elite go straight to combat")
	for f in ["res://scenes/shared/run_continue.gd", "res://scenes/combat/CombatView.gd", "res://scenes/land/Land.gd",
			"res://scenes/main_menu/MainMenu.gd", "res://scenes/tutorial/TutorialCoach.gd"]:
		if FileAccess.file_exists(f):
			_t(not _src(f).contains("BossIntro"), "%s does not use BossIntro (resume / tutorial unaffected)" % f)

	_guard.restore()
	if _fails.is_empty():
		print("t_boss_intro: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_boss_intro: FAIL - " + f)
		get_tree().quit(1)
