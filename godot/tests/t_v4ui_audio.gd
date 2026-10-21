extends Node
## v4 UI item 3: dm_* sound routing. Priority window, silent mapping, SFX bus, headless silence.
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _ready() -> void:
	var saved := CombatView.disable_juice_for_tests
	CombatView.disable_juice_for_tests = false
	var a := DiceMomentAudio.new()
	add_child(a)
	await get_tree().process_frame
	_check(a._voices.size() == 2, "two private voices")
	for v in a._voices:
		_check(v.bus == "SFX", "voice on SFX bus (follows audio_sfx_volume / mute)")
	# every mapped file exists or is the empty (silent) slot; the four placeholders exist
	var with_file := 0
	for e in DiceMomentAudio.EVENTS:
		var p := String(DiceMomentAudio.EVENTS[e]["path"])
		if p != "":
			with_file += 1
			_check(ResourceLoader.exists(p), "%s file exists: %s" % [e, p])
	for e in DiceMomentAudio.EVENTS:
		for l in DiceMomentAudio.EVENTS[e].get("layers", []):
			for lp in (l["paths"] if l.has("paths") else [l["path"]]):
				_check(ResourceLoader.exists(String(lp)), "%s layer file exists: %s" % [e, lp])
	_check(with_file >= 2 and with_file <= 5, "placeholder files mapped: %d" % with_file)
	# priority window
	_check(a.play("dm_set4", 10.0), "set4 plays")
	_check(not a.play("dm_roll", 10.2), "roll inside the window after set4 is dropped")
	_check(a.play("dm_set5", 10.3), "set5 cuts set4")
	_check(a.play("dm_roll", 11.0), "roll after the window plays")
	_check(not a.play("dm_nope", 20.0), "unknown event ignored")
	# silent events do not error
	_check(a.play("dm_crack", 30.0), "event without a file is let through silently")
	a.queue_free()
	# headless mode: no players
	CombatView.disable_juice_for_tests = true
	var b := DiceMomentAudio.new()
	add_child(b)
	await get_tree().process_frame
	_check(b._voices.is_empty() and not b.play("dm_set3"), "juice off: no voices, nothing plays")
	b.queue_free()
	CombatView.disable_juice_for_tests = saved
	print("=== t_v4ui_audio: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_v4ui_audio: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_v4ui_audio: FAIL - %s" % f)
	get_tree().quit(1)
