extends Node
## UI-05 b1 defeat panel (frames 30-defeat--paid / free / normal / mission): states, the price once inside
## Continue, Gem violet only on paid surfaces, End run as primary when Continue is not usable, the 1000 ms primary
## delay, focus, the ui3_modal group. Pure view, no engine.
## Run: godot --headless --path godot res://tests/t_defeat_panel.tscn

var _checks := 0
var _fails: Array[String] = []
var _got := {"continue": 0, "end": 0, "gem": 0}


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _texts(n: Node, out: Array) -> Array:
	if n is Label and (n as Label).is_visible_in_tree():
		out.append((n as Label).text)
	for c in n.get_children():
		_texts(c, out)
	return out


func _bg(p: Control) -> Color:
	return (p.get_theme_stylebox("panel") as StyleBoxFlat).bg_color


func _border(p: Control) -> Color:
	return (p.get_theme_stylebox("panel") as StyleBoxFlat).border_color


func _f(dp: Node, n: String) -> Node:
	return dp.find_child(n, true, false)


func _ready() -> void:
	print("=== t_defeat_panel: start ===")
	var base := {"title_line": "Fight 4 of 18 · A6 · 5 Axies", "turn": 1, "enemies_left": 2, "aid_used": 0, "aid_cap": 6,
		"heal_pct": 25, "keep_line": "Enemies keep their HP.", "attrition_reset_line": "Attrition resets to 0%.",
		"price": 180, "variant": "paid", "continue_show": true, "continue_enabled": true}
	var dp := DefeatPanel.new()
	add_child(dp)
	dp.continue_pressed.connect(func() -> void: _got["continue"] += 1)
	dp.end_run_pressed.connect(func() -> void: _got["end"] += 1)
	dp.get_gem_pressed.connect(func() -> void: _got["gem"] += 1)

	# Paid: violet revive card, Continue + one Gem chip inside it, Continue focused, End run secondary.
	dp.show_defeat(base)
	await get_tree().process_frame
	var panel: Control = _f(dp, "DefeatPanel")
	_check(panel != null and panel.custom_minimum_size.x == UI3Theme.size_of("defeat_panel_w"), "panel is defeat_panel_w wide")
	for n in ["Scrim", "Title", "SubLine", "Recap", "ReviveCard", "ContinueButton", "Footer", "EndRunButton"]:
		_check(_f(dp, n) != null, "paid: node %s" % n)
	_check((_f(dp, "Title") as Label).text == "Party down", "title")
	var cont: Button = _f(dp, "ContinueButton")
	_check(not cont.disabled and cont.get("caption") == "Continue", "paid: Continue caption")
	_check(cont.find_child("CostChip", true, false) != null and _texts(cont, []).has("180"), "paid: price inside Continue")
	_check(dp.find_children("CostChip", "", true, false).size() == 1, "paid: exactly one price chip")
	var rc: Control = _f(dp, "ReviveCard")
	_check(_bg(rc).is_equal_approx(UI3Theme.color("gem_bg")) and _border(rc).is_equal_approx(UI3Theme.color("gem_border")),
		"paid: revive card is the violet surface")
	_check(cont.has_focus() and dp.primary_button() == cont, "paid: Continue is primary and focused")
	_check((_f(dp, "EndRunButton") as Button).theme_type_variation == "ButtonSecondary", "paid: End run secondary")
	_check(_f(dp, "GetGemButton") == null, "paid: no Get Gem")
	_check(dp.get_child_count() > 0 and dp.is_in_group("ui3_modal") and UI3Tooltip.modal_open(get_tree()), "panel counts as a modal")
	_check(_f(dp, "RecapCell2") != null and (_f(_f(dp, "RecapCell2"), "Value") as Label).text == "0 of 6", "recap: Aid used 0 of 6")
	var val_lbl := _f(_f(dp, "RecapCell0"), "Value") as Label
	_check(val_lbl.get_theme_font_size("font_size") == UI3Theme.size_of("text_title"), "recap value is text_title")

	# 1000 ms primary delay: a press right away is ignored, after the delay it goes through.
	cont.pressed.emit()
	_check(_got["continue"] == 0 and not dp.primary_armed(), "primary ignores presses before 1000 ms")
	dp.primary_delay_ms = 0
	dp.show_defeat(base)
	await get_tree().process_frame
	(_f(dp, "ContinueButton") as Button).pressed.emit()
	_check(_got["continue"] == 1, "primary works once armed")
	(_f(dp, "EndRunButton") as Button).pressed.emit()
	_check(_got["end"] == 1, "secondary End run is never delayed")

	# Not enough Gem: Continue disabled "Need 180 Gem" (no chip), Get Gem under it, End run is the primary (M).
	var short := base.duplicate()
	short["continue_enabled"] = false
	short["need_more"] = 60
	short["continue_reason"] = "Not enough Gem"
	dp.primary_delay_ms = DefeatPanel.PRIMARY_DELAY_MS
	dp.show_defeat(short)
	await get_tree().process_frame
	cont = _f(dp, "ContinueButton")
	_check(cont.disabled and cont.text == "Need 180 Gem", "short: '%s'" % cont.text)
	_check(not (cont.find_child("CostChip", true, false) as Control).is_visible_in_tree(), "short: no chip on the disabled Continue")
	var gg: Button = _f(dp, "GetGemButton")
	_check(gg != null and not gg.disabled and gg.text == "Get Gem", "short: Get Gem live")
	_check((gg.get_theme_stylebox("normal") as StyleBoxFlat).bg_color.is_equal_approx(UI3Theme.color("gem_bg")), "short: Get Gem is violet")
	gg.pressed.emit()
	_check(_got["gem"] == 1, "Get Gem emits")
	var er: Button = _f(dp, "EndRunButton")
	_check(er.theme_type_variation == "ButtonPrimaryM" and er.has_focus() and dp.primary_button() == er, "short: End run primary M, focused")
	er.pressed.emit()
	_check(_got["end"] == 1, "short: End run (primary) waits 1000 ms too")
	short["get_gem_reason"] = "Buying disabled in the playtest"
	dp.show_defeat(short)
	await get_tree().process_frame
	gg = _f(dp, "GetGemButton")
	_check(gg.disabled and gg.text == "Buying disabled in the playtest", "short: Get Gem says why when off")
	var other := base.duplicate()
	other["continue_enabled"] = false
	other["continue_reason"] = "Aid cap for this run reached"
	dp.show_defeat(other)
	await get_tree().process_frame
	_check((_f(dp, "ContinueButton") as Button).text == "Aid cap for this run reached" and _f(dp, "GetGemButton") == null,
		"other reason: Continue says it, no Get Gem")

	# Free (gift): amber edge, Free chip, nothing violet.
	var gift := base.duplicate()
	gift["variant"] = "gift"
	gift["price"] = 0
	dp.show_defeat(gift)
	await get_tree().process_frame
	cont = _f(dp, "ContinueButton")
	rc = _f(dp, "ReviveCard")
	var chip: Control = cont.find_child("CostChip", true, false)
	_check(cont.get("caption") == "Continue" and _texts(chip, []).has("Free"), "gift: Continue + Free chip")
	_check(_border(rc).is_equal_approx(UI3Theme.color("accent")) and _bg(rc).is_equal_approx(UI3Theme.color("plate_raised")), "gift: amber edge")
	_check(not _bg(chip).is_equal_approx(UI3Theme.color("gem_bg")) and not _border(rc).is_equal_approx(UI3Theme.color("gem_border")),
		"gift: no violet on a free revive")

	# Mission: no Continue at all, stake line, End run primary L and focused, 2 recap cells.
	var mis := base.duplicate()
	mis["mission"] = true
	mis["stake"] = 0
	dp.show_defeat(mis)
	await get_tree().process_frame
	_check(_f(dp, "ContinueButton") == null and _f(dp, "ReviveCard") == null, "mission: no Continue")
	_check(_f(dp, "StakeLost") == null and _texts(dp, []).has("Mission runs have no Continue."), "mission: line only (no stake known)")
	mis["stake"] = 800
	dp.show_defeat(mis)
	await get_tree().process_frame
	_check(_f(dp, "StakeLost") != null and _texts(dp, []).has("Mission lost: your 800 Shard stake is gone"), "mission: stake line with the real stake")
	er = _f(dp, "EndRunButton")
	_check(er.theme_type_variation == "ButtonPrimaryL" and er.has_focus(), "mission: End run primary L, focused")
	var mt := _texts(dp, [])
	_check(not mt.has("Aid used") and mt.has("Fell on turn") and _f(dp, "Recap").get_child_count() == 2, "mission: no Aid cell")
	_check((_f(dp, "NoContinueLine") as Label).text == "Mission runs have no Continue.", "mission: NoContinueLine")

	# Busy: Reviving, input locked, restored afterwards.
	dp.show_defeat(base)
	await get_tree().process_frame
	dp.set_busy(true)
	cont = _f(dp, "ContinueButton")
	_check(cont.get("caption") == "Reviving…" and cont.disabled and (_f(dp, "EndRunButton") as Button).disabled, "busy locks")
	dp.set_busy(false)
	_check(cont.get("caption") == "Continue" and not cont.disabled, "busy restores")
	_check(_f(dp, "Recap").get_child_count() == 3, "recap is 3 cells")

	# Boss bar carries the phase line only for multi-phase bosses.
	var boss := base.duplicate()
	boss["boss"] = {"name": "FROST LORD", "hp": 50, "max_hp": 100, "phase": 2, "phases": 3, "marks": [0.66, 0.33]}
	dp.show_defeat(boss)
	await get_tree().process_frame
	var bb: Node = _f(dp, "BossBar")
	_check(bb != null and _texts(bb, []).has("50% left · phase 2 of 3"), "boss bar text")
	boss["boss"] = {"name": "FROST LORD", "hp": 50, "max_hp": 100, "phase": 1, "phases": 1, "marks": [0.66, 0.33]}
	dp.show_defeat(boss)
	await get_tree().process_frame
	bb = _f(dp, "BossBar")
	_check(bb != null and _texts(bb, []).has("50% left"), "one-phase boss: no phase text")

	# Hidden panel no longer counts as a modal.
	dp.visible = false
	_check(not UI3Tooltip.modal_open(get_tree()), "hidden panel releases the tooltips")

	for f in _fails:
		print("t_defeat_panel: FAIL — %s" % f)
	if _fails.is_empty():
		print("t_defeat_panel: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
