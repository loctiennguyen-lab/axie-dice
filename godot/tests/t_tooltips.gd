extends Node
## UI-03 43: tooltip plate on focus and hover, <= 360 wide, hides on focus-out and Esc, no native tooltip left
## on bound controls; the combat relic / active / die-face owners are bound.
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	_guard.capture()
	var long_text := "A long tooltip body that must wrap inside the plate and never grow wider than the spec: three hundred and sixty pixels including its padding, however long the sentence is."
	var b := Button.new()
	b.text = "Owner"
	b.custom_minimum_size = Vector2(120, 48)
	b.position = Vector2(400, 300)
	b.focus_mode = Control.FOCUS_ALL
	add_child(b)
	UI3Tooltip.bind(b, long_text)
	await get_tree().process_frame
	_t(b.tooltip_text == "" and UI3Tooltip.text_of(b) == long_text, "bind moves the text off the native tooltip")
	b.grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	var p := UI3Tooltip.shown_plate(get_tree())
	_t(p != null, "focus shows the tooltip at once")
	if p != null:
		_t(p.size.x <= UI3Tooltip.MAX_W + 0.5, "plate width %s <= 360" % p.size.x)
		_t(p.get_global_rect().position.y >= b.get_global_rect().end.y or p.get_global_rect().end.y <= b.get_global_rect().position.y,
			"plate does not cover its owner: plate %s owner %s" % [p.get_global_rect(), b.get_global_rect()])
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	Input.parse_input_event(esc)
	await get_tree().process_frame
	await get_tree().process_frame
	_t(UI3Tooltip.shown_plate(get_tree()) == null, "Esc hides it")
	b.release_focus()
	b.grab_focus()
	await get_tree().process_frame
	_t(UI3Tooltip.shown_plate(get_tree()) != null, "focus again shows it")
	b.release_focus()
	await get_tree().process_frame
	_t(UI3Tooltip.shown_plate(get_tree()) == null, "focus out hides it")
	_t(UI3Theme.motion_sec("tooltip_delay_ms") > 0.0, "delay comes from the motion token")
	b.queue_free()

	# Combat owners: relic slot, active, die card are bound.
	CombatView.disable_juice_for_tests = true
	RunState.start_new_run(4242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 0, false)
	RunState._grant_relic("r_amberdie", "t")
	RunState._grant_relic("a_bloom", "t")
	RunState.enter_node("r1_c0", "battle")
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(scene)
	for i in 5:
		await get_tree().process_frame
	var bound := 0
	for n in scene.find_children("*", "Control", true, false):
		if n.has_meta("ui3_tip"):
			bound += 1
			_t((n as Control).tooltip_text == "", "no native tooltip on a bound control (%s)" % n.name)
	for n in scene.find_children("*", "Control", true, false):
		if n.has_meta("ui3_tip"):
			var tt := UI3Tooltip.text_of(n)
			_t(not tt.contains("[") and not tt.contains("RULE:") and not tt.contains("PACT."), "tooltip has no raw tags: %s" % tt.replace("\n", " / "))
	# Esc over a mouse-hover tooltip must reach the pause menu: only focus-origin tooltips eat it.
	var hb := Button.new()
	hb.custom_minimum_size = Vector2(120, 48)
	hb.position = Vector2(200, 200)
	add_child(hb)
	UI3Tooltip.bind(hb, "Title\nBody")
	UI3Tooltip._show(hb)
	await get_tree().process_frame
	await get_tree().process_frame
	var l := get_tree().root.get_node(UI3Tooltip.LAYER_NAME)
	_t(not l.from_focus, "hover tooltip is not focus-origin (Esc passes through)")
	_t(l.title_label.visible and l.title_label.text == "Title" and l.label.text == "Body", "first line is the title")
	UI3Tooltip.hide_for(hb)
	hb.queue_free()
	_t(bound >= 5, "combat binds the die cards (and relics/actives): %d" % bound)
	scene.queue_free()
	print("t_tooltips: %d checks, %d fail" % [_checks, _fails.size()])
	_guard.restore()
	if _fails.is_empty():
		print("t_tooltips: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_tooltips: FAIL — %s" % f)
		get_tree().quit(1)


func _t(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)
