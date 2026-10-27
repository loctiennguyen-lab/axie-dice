extends Node
## UI-03 defeat panel (screen 30): the continue block states and UI3.cost_chip. Pure view, no engine.
## Run: godot --headless --path godot res://tests/t_defeat_panel.tscn

var _checks := 0
var _fails: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _texts(n: Node, out: Array) -> Array:
	if n is Label:
		out.append((n as Label).text)
	for c in n.get_children():
		_texts(c, out)
	return out


func _ready() -> void:
	print("=== t_defeat_panel: start ===")
	var base := {"title_line": "Boss fight · A6 · turn 3", "recap": [], "aid_used": 0, "aid_cap": 6,
		"heal_pct": 25, "party": [], "price": 180, "variant": "paid", "continue_show": true,
		"continue_enabled": true}
	var dp := DefeatPanel.new()
	add_child(dp)

	# CostChip: gem shows the amount, free shows the word, signature (kind, amount, not_enough).
	var gem := UI3.cost_chip(&"gem", 180)
	add_child(gem)
	_check(_texts(gem, []).has("180"), "gem chip shows 180")
	var dim := UI3.cost_chip(&"gem", 180, true)
	_check(dim.modulate.a < 1.0, "not_enough chip is dimmed")
	var free := UI3.cost_chip(&"free", 0)
	_check(_texts(free, []).has("Free"), "free chip says Free")
	_check(gem.custom_minimum_size.y == 40.0, "chip is 40 high")

	# Paid: enabled, labelled with the data price, focus on Continue.
	dp.show_defeat(base)
	await get_tree().process_frame
	var cont: Button = dp.find_child("Continue", true, false)
	_check(cont != null and not cont.disabled and cont.text == "Continue · 180 Gem", "paid label")
	_check(dp.find_child("CostChip", true, false) != null, "paid shows a cost chip")

	# Short of Gem: grey, says how many.
	var short := base.duplicate()
	short["continue_enabled"] = false
	short["need_more"] = 60
	short["continue_reason"] = "Not enough Gem"
	dp.show_defeat(short)
	await get_tree().process_frame
	cont = dp.find_child("Continue", true, false)
	_check(cont.disabled and cont.text == "Need 60 more Gem", "short: '%s'" % cont.text)
	_check(_texts(dp, []).has("Not enough Gem"), "short: reason line present")
	_check(dp.find_child("EndRun", true, false).has_focus(), "short: End run focused")

	# Free (gift): chip says Free.
	var gift := base.duplicate()
	gift["variant"] = "gift"
	gift["price"] = 0
	dp.show_defeat(gift)
	await get_tree().process_frame
	cont = dp.find_child("Continue", true, false)
	_check(cont.text == "Continue · Free" and _texts(dp.find_child("CostChip", true, false), []).has("Free"), "gift: free")

	# Mission: no Continue at all, End run is the primary button.
	var mis := base.duplicate()
	mis["mission"] = true
	dp.show_defeat(mis)
	await get_tree().process_frame
	_check(dp.find_child("Continue", true, false) == null, "mission: no Continue")
	_check(_texts(dp, []).has("Mission runs have no Continue."), "mission: line shown (no stake known)")
	mis["stake"] = 800
	dp.show_defeat(mis)
	await get_tree().process_frame
	_check(_texts(dp, []).has("Mission lost: your 800 Shard stake is gone. Mission runs have no Continue."), "mission: stake line with the real stake")
	_check(dp.find_child("EndRun", true, false).theme_type_variation == "ButtonPrimaryM", "mission: End run primary")
	var mt := _texts(dp, [])
	_check(not mt.has("Aid used") and not mt.has("Fight") and mt.has("Party") and mt.has("Fell on turn"), "mission: no Aid / Fight tiles")
	dp.show_defeat(base)
	await get_tree().process_frame
	_check(_texts(dp, []).has("Aid used"), "normal run keeps the Aid tile")

	# Busy: Reviving, input locked, restored afterwards.
	dp.show_defeat(base)
	await get_tree().process_frame
	dp.set_busy(true)
	cont = dp.find_child("Continue", true, false)
	_check(cont.text == "Reviving…" and cont.disabled and dp.find_child("EndRun", true, false).disabled, "busy locks")
	dp.set_busy(false)
	_check(cont.text == "Continue · 180 Gem" and not cont.disabled, "busy restores")

	# Boss block carries phase ticks.
	var boss := base.duplicate()
	boss["boss"] = {"name": "Frost Lord", "hp": 50, "max_hp": 100, "phase": 2, "phases": 3, "spike_in": 0,
		"marks": [0.66, 0.33]}
	dp.show_defeat(boss)
	await get_tree().process_frame
	var bb: Node = dp.find_child("BossBlock", true, false)
	_check(bb != null and _texts(bb, []).has("50% left · phase 2 of 3"), "boss block text")
	boss["boss"] = {"name": "Frost Lord", "hp": 50, "max_hp": 100, "phase": 1, "phases": 1, "spike_in": 0,
		"marks": [0.66, 0.33]}
	dp.show_defeat(boss)
	await get_tree().process_frame
	bb = dp.find_child("BossBlock", true, false)
	_check(bb != null and _texts(bb, []).has("50% left"), "one-phase boss: no phase text")

	for f in _fails:
		print("t_defeat_panel: FAIL — %s" % f)
	if _fails.is_empty():
		print("t_defeat_panel: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
