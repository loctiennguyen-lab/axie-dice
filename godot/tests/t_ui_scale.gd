extends Node
## UI-05 b1 lane 0: the 1280 overrides. Canvas is always logical 1920, so the override numbers (real px at 1280)
## are divided by the scale: card 116 -> 174, dock 612 -> 918, Aid 228 -> 342, text floor 14 real px -> 21 logical.
## The scale comes from window / (1920, 1080) divided by the device pixel ratio, so a web build at 1280 CSS px is the
## same on DPR 1 and DPR 2. Resize 1920 -> 1280 -> 1920 rebuilds the SAME Theme object.
var _fail: Array[String] = []
var _checks := 0

func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fail.append(m)

func _ready() -> void:
	UI3Theme.reset_cache()
	_ok(is_equal_approx(UI3Theme.scale_for(Vector2(1920, 1080)), 1.0), "1920x1080 DPR1 = 1")
	_ok(absf(UI3Theme.scale_for(Vector2(1280, 720)) - 2.0 / 3.0) < 0.001, "1280x720 DPR1 = 0.667")
	_ok(absf(UI3Theme.scale_for(Vector2(2560, 1440), 2.0) - 2.0 / 3.0) < 0.001, "web 1280 CSS px at DPR2 (2560 physical) = 0.667, not 1.33")
	_ok(UI3Theme.scale_for(Vector2(2560, 1440), 1.0) > 1.0, "a real 2560 window is not small")
	_ok(absf(UI3Theme.scale_for(Vector2(1280, 1080)) - 2.0 / 3.0) < 0.001, "the smaller axis wins")
	# every override key maps onto a real snake_case size token
	var raw: Dictionary = UI3Theme.tokens()["_size_1280_overrides"]
	for k in raw:
		if k == "note" or k == "min_text":
			continue
		var snake := String(k).replace("-", "_")
		_ok((UI3Theme.tokens()["size"] as Dictionary).has(snake), "override '%s' maps to size token '%s'" % [k, snake])
	UI3Theme.set_scale_override(1.0)
	var th := UI3Theme.get_theme()
	_ok(UI3Theme.size_of("die_card_w") == 152 and UI3Theme.size_of("dice_dock_w") == 808 and UI3Theme.size_of("aid_w") == 320, "1920: token sizes")
	_ok(UI3Theme.size_of("text_body") == 18 and th.default_font_size == 18 and not UI3Theme.is_small(), "1920: text 18, not small")
	UI3Theme.set_scale_override(2.0 / 3.0)
	_ok(UI3Theme.size_of("die_card_w") == 174, "1280: die card 116 real = 174 logical (%d)" % UI3Theme.size_of("die_card_w"))
	_ok(UI3Theme.size_of("dice_dock_w") == 918, "1280: dock 612 real = 918 logical (%d)" % UI3Theme.size_of("dice_dock_w"))
	_ok(UI3Theme.size_of("aid_w") == 342, "1280: aid 228 real = 342 logical (%d)" % UI3Theme.size_of("aid_w"))
	_ok(UI3Theme.size_of("text_body") == 21 and UI3Theme.size_of("text_key_hint") == 21, "1280: 16 / 18 raised to 21 logical = 14 real")
	_ok(UI3Theme.size_of("text_title") == 24 and UI3Theme.size_of("text_banner") == 36, "1280: 24 / 36 already >= 14 real, unchanged")
	_ok(UI3Theme.get_theme() == th and th.default_font_size == 21 and th.get_font_size("body", "Label") == 21, "1280: SAME Theme object rebuilt in place (default 21)")
	_ok(UI3Theme.is_small(), "1280 is small")
	# in between: continuous and monotonic in REAL px (size * scale), exact at both ends
	var last_real := 0.0
	for sc: float in [1.0, 0.977, 0.9, 0.8, 0.7, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		var real := float(UI3Theme.size_of("die_card_w")) * sc
		_ok(real <= 152.0 * sc + 1.0 and (last_real == 0.0 or real <= last_real + 3.0), "die card real px non-increasing at scale %.3f (%.1f)" % [sc, real])
		last_real = real
	UI3Theme.set_scale_override(0.977)
	_ok(UI3Theme.size_of("die_card_w") >= 150 and UI3Theme.size_of("die_card_w") <= 152, "scale 0.977 is nearly the 1920 size, not 116 real px (%d)" % UI3Theme.size_of("die_card_w"))
	UI3Theme.set_scale_override(0.8)
	var mid := float(UI3Theme.size_of("die_card_w")) * 0.8
	_ok(mid > 116.0 and mid < 152.0 * 0.8, "scale 0.8 lies between the two ends (%.1f real)" % mid)
	UI3Theme.set_scale_override(1.0)
	_ok(UI3Theme.get_theme() == th and th.default_font_size == 18 and UI3Theme.size_of("die_card_w") == 152, "back to 1920: theme and sizes restored")
	_ok(not UI3Theme.sync_scale(), "sync_scale reports no change when nothing moved")
	UI3Theme.set_scale_override(-1.0)
	UI3Theme.reset_cache()
	print("=== t_ui_scale: %d checks, %d failure(s) ===" % [_checks, _fail.size()])
	if _fail.is_empty():
		print("t_ui_scale: PASS")
		get_tree().quit(0)
		return
	for f in _fail:
		print("t_ui_scale: FAIL - " + f)
	get_tree().quit(1)
