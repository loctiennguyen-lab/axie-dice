extends Node
## UI-04 prep gate: motion_ui3.json loads, every moment validates, the seeded moments keep the timings
## that used to be hardcoded in CombatView, and play() really runs (skip path + one short real tween).
## Timing only, no pixels, no network, no save access.

var _fails: Array[String] = []
var _checks := 0
var _done_calls := 0


func _ready() -> void:
	print("=== t_ui3_motion: start ===")
	UI3Motion.reload()
	_test_loader()
	_test_validation()
	await _test_play()
	if _fails.is_empty():
		print("t_ui3_motion: PASS — %d checks OK" % _checks)
	else:
		for f in _fails:
			print("t_ui3_motion: FAIL — %s" % f)
	get_tree().quit(0 if _fails.is_empty() else 1)


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)


func _test_loader() -> void:
	var ids := UI3Motion.moment_ids()
	_ok(ids.has("turn_banner") and ids.has("combo_banner"), "seed moments missing: %s" % [ids])
	for id in ids:
		var errs := UI3Motion.validate_moment(id, UI3Motion.table()[id])
		_ok(errs.is_empty(), "moment %s invalid: %s" % [id, errs])
	# Timings hardcoded in CombatView before: banner 390 + 750 + 360 = 1.5 s; combo chip 180 in + 1550 hold
	# (caller passes COMBO_FLOAT_SEC - 0.25 s) + 250 out = 1.98 s.
	_ok(is_equal_approx(UI3Motion.duration_sec("turn_banner"), 1.5), "turn_banner total != 1.5 s")
	_ok(is_equal_approx(UI3Motion.duration_sec("combo_banner", {"hold_ms": 1550.0}), 1.98), "combo_banner total != 1.98 s")
	_ok(is_equal_approx(UI3Motion.duration_sec("turn_banner", {"scale_ms": 0.5}), 0.75), "scale_ms not applied")
	_ok(UI3Motion.duration_sec("nope") == 0.0, "unknown moment has a duration")


func _test_validation() -> void:
	_ok(not UI3Motion.validate_moment("x", {}).is_empty(), "empty moment accepted")
	_ok(not UI3Motion.validate_moment("x", {"in": {"ms": 10, "trans": "WOBBLE"}}).is_empty(), "bad trans accepted")
	_ok(not UI3Motion.validate_moment("x", {"in": {"ms": 10, "props": {"glow": {"to": 1}}}}).is_empty(), "bad prop accepted")
	_ok(not UI3Motion.validate_moment("x", {"in": {"ms": 10}, "particles": {"texture": "res://nope.png"}}).is_empty(), "missing particle texture accepted")
	_ok(UI3Motion.validate_moment("x", {"in": {"ms": 10, "trans": "BACK", "ease": "OUT", "props": {"alpha": {"to": 1}}}}).is_empty(), "valid moment rejected")
	_ok(not UI3Motion.has_moment("does_not_exist") and not UI3Motion.has_moment("_note"), "unknown / note key counted as a moment")


func _test_play() -> void:
	# Skip path: lands in the last phase's end state at once, calls on_done, hides.
	var c := Control.new()
	add_child(c)
	var r := UI3Motion.play("turn_banner", c, {"skip": true, "on_done": func(): _done_calls += 1})
	_ok(r == null, "skip returned a tween")
	_ok(is_equal_approx(c.modulate.a, 0.0) and not c.visible and _done_calls == 1, "skip end state wrong")
	# Real tween at 1% speed (~15 ms): starts from `from`, ends at final state, on_done after.
	var d := Control.new()
	add_child(d)
	d.visible = true
	var tw := UI3Motion.play("turn_banner", d, {"scale_ms": 0.01, "on_done": func(): _done_calls += 1})
	_ok(tw != null, "no tween for a normal play")
	_ok(is_equal_approx(d.scale.x, 0.9) and is_equal_approx(d.modulate.a, 0.0), "from-state not applied")
	await tw.finished
	_ok(_done_calls == 2 and not d.visible, "real play did not finish (done=%d)" % _done_calls)
	_ok(UI3Motion.played.size() == 2, "played log wrong: %s" % [UI3Motion.played])
	# free_on_done
	var e := Control.new()
	add_child(e)
	var tw2 := UI3Motion.play("combo_banner", e, {"scale_ms": 0.01})
	await tw2.finished
	await get_tree().process_frame
	_ok(not is_instance_valid(e), "free_on_done did not free")
	c.queue_free()
	d.queue_free()
