extends Node
## UI-05 b23 lane R5b: Event (event--choices / event--outcome) and Treasure (13-treasure--closed / --opened) against the
## frames: data-names, no preselect, disabled-with-reason buttons, Space keycap only on live buttons, 1920 + 1280 fit,
## text >= 14 real px, align check, initial focus; the RunState event call stays one logged event_choose.
const Align := preload("res://tests/ui5_align_check.gd")
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
var rm: Node


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _has(root: Node, names: Array, tag: String) -> void:
	for n in names:
		_ok(root.find_child(n, true, false) != null, "%s: node %s" % [tag, n])


## Fit, text size, align on the open screen under `root`.
func _fit(root: Node, sc: float, tag: String, align := true) -> int:
	var vp := Vector2(1920, 1080)
	for cn in root.find_children("*", "Control", true, false):
		var ct := cn as Control
		if ct.is_visible_in_tree() and ct.size.x > 0.0 and ct.size.y > 0.0:
			var rr := ct.get_global_rect()
			if rr.end.x > vp.x + 0.5 or rr.position.x < -0.5 or rr.end.y > vp.y + 0.5 or rr.position.y < -0.5:
				_ok(false, "%s: %s outside the frame (%s)" % [tag, ct.name, str(rr)])
	for l in root.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.is_visible_in_tree() and lab.text != "":
			_ok(float(lab.get_theme_font_size("font_size")) * sc >= 13.99, "%s: label '%s' >= 14 real px" % [tag, lab.text.left(20)])
	for b in root.find_children("*", "Button", true, false):
		var bt := b as Button
		if bt.is_visible_in_tree():
			_ok(float(bt.get_theme_font_size("font_size")) * sc >= 13.99, "%s: button '%s' >= 14 real px" % [tag, bt.text.left(20)])
	if align:
		var al: Array[String] = Align.check(root, 1.5, tag)
		_ok(al.is_empty(), "%s: aligned %s" % [tag, str(al.slice(0, 3))])
	return Align.pairs(root)


func _vcentre(a: Control, b: Control, tag: String) -> void:
	_ok(absf(a.get_global_rect().get_center().y - b.get_global_rect().get_center().y) <= 1.5, "%s: %s centred on %s" % [tag, a.name, b.name])


func _event(sc: float) -> void:
	var tag := "event @%.2f" % sc
	UI3Theme.set_scale_override(sc)
	RunState.event_key = ""
	for k in ContentDB.events.keys():
		RunState.event_key = String(k)
		if RunState.event_options().size() >= 3:
			break
	rm.call("_on_event_node", "x")
	await _frames(4)
	var root: Node = rm._overlay_root
	_has(root, ["EventScreen", "EventArt", "EventColumn", "EventTitle", "EventRow", "EventBody", "Choices", "ChoiceRow", "ChoiceRow2", "ChooseButton"], tag)
	_ok(root.find_child("OutcomeText", true, false) == null, "%s: no outcome yet" % tag)
	_ok(root.find_child("EventArt", true, false).size.is_equal_approx(Vector2(UI3Theme.size_of("event_art"), UI3Theme.size_of("event_art"))), "%s: EventArt 720" % tag)
	var go := root.find_child("ChooseButton", true, false) as Button
	_ok(go.disabled and go.text == "Pick a choice" and go.get_node_or_null("KeyCap") == null, "%s: Choose off, says why, no keycap" % tag)
	_ok(int(rm._event_sel) == -1, "%s: nothing preselected" % tag)
	_ok(rm._event_cards[0].has_focus(), "%s: initial focus on the first choice" % tag)
	for c in rm._event_cards:
		_ok(c.theme_type_variation == "PanelCard", "%s: no row shows selected" % tag)
		_ok(c.get_global_rect().size.y >= UI3Theme.size_of("choice_h") * sc - 0.5, "%s: row min height" % tag)
		var ic := (c.get_child(0) as Node).get_child(0) as Control
		_vcentre((c.get_child(0) as Node).get_node("Text") as Control, ic, tag)
	_vcentre(root.find_child("EventHeadText", true, false) as Control, root.find_child("EventHead", true, false).get_child(0) as Control, tag)
	var ll := (RunState.action_log.entries as Array).size()
	rm._select_event(1)
	await _frames(4)
	_ok(not go.disabled and go.text == "Choose" and go.get_node_or_null("KeyCap") != null, "%s: pick turns Choose on with the Space keycap" % tag)
	_ok(Ui5Keycap.text_of(go.get_node("KeyCap")) == "Space", "%s: keycap is Space" % tag)
	_ok(rm._event_cards[1].theme_type_variation == "PanelCardSelected" and rm._event_cards[0].theme_type_variation == "PanelCard", "%s: only the picked row is selected" % tag)
	_ok((RunState.action_log.entries as Array).size() == ll, "%s: picking logs nothing" % tag)
	_fit(root.find_child("EventScreen", true, false), sc, tag)
	# Outcome frame
	rm.call("_build_event_screen", 1, "A made-up outcome line.")
	await _frames(4)
	root = rm._overlay_root
	_has(root, ["EventScreen", "EventArt", "EventColumn", "EventTitle", "EventRow", "OutcomeText", "Choices", "ChoiceRow", "ContinueButton"], tag + " outcome")
	_ok(root.find_child("EventBody", true, false) == null and root.find_child("ChooseButton", true, false) == null, "%s outcome: body and Choose gone" % tag)
	var rows := root.find_children("ChoiceRow*", "PanelContainer", true, false)
	_ok(rows.size() >= 3 and absf((rows[0] as Control).modulate.a - 0.4) < 0.01 and absf((rows[1] as Control).modulate.a - 1.0) < 0.01, "%s outcome: others at 40%%, picked at 100%%" % tag)
	var cb := root.find_child("ContinueButton", true, false) as Button
	_ok(cb.text == "Continue" and cb.get_node_or_null("KeyCap") != null and cb.has_focus(), "%s outcome: Continue has the Space keycap and focus" % tag)
	_fit(root.find_child("EventScreen", true, false), sc, tag + " outcome")


func _treasure(sc: float) -> void:
	var tag := "treasure @%.2f" % sc
	UI3Theme.set_scale_override(sc)
	RunState.pending_rewards.assign([
		{"t": "relic", "key": "x0", "rar": 0, "title": "RELIC", "desc": "Name 0", "sub": "Does thing 0."},
		{"t": "relic", "key": "x1", "rar": 0, "title": "RELIC", "desc": "Name 1", "sub": "Does thing 1."},
		{"t": "relic", "key": "x2", "rar": 0, "title": "RELIC", "desc": "Name 2", "sub": "Does thing 2."}])
	rm.call("_build_treasure", false)
	await _frames(4)
	var root: Node = rm._overlay_root
	_has(root, ["Treasure", "Chest", "Title", "ShardPill", "OpenButton"], tag + " closed")
	var ob := root.find_child("OpenButton", true, false) as Button
	_ok(ob.get_node_or_null("KeyCap") != null and ob.has_focus(), "%s closed: Open has the Space keycap and focus" % tag)
	_ok(root.find_child("Chest", true, false).size.is_equal_approx(Vector2(UI3Theme.size_of("chest"), UI3Theme.size_of("chest"))), "%s closed: Chest 384" % tag)
	_ok(String((root.find_child("Title", true, false) as Label).text) == "A sealed Gene vault", "%s closed: title" % tag)
	var pairs := _fit(root.find_child("Treasure", true, false), sc, tag + " closed")
	_ok(pairs > 0, "%s closed: align check measured pairs" % tag)
	ob.pressed.emit()
	await _frames(5)
	root = rm._overlay_root
	_has(root, ["TreasureReward", "Title", "ShardPill", "CardRow", "Footer", "TakeButton"], tag + " opened")
	_ok(root.find_child("Chest", true, false) == null, "%s opened: no chest" % tag)
	var tb := root.find_child("TakeButton", true, false) as Button
	_ok(tb.disabled and tb.text == "Pick a reward" and tb.get_node_or_null("KeyCap") == null, "%s opened: Take off, says why, no keycap" % tag)
	_ok(int(rm._reward_sel) == -1 and rm._reward_cards.size() == 3, "%s opened: nothing preselected, 3 cards" % tag)
	_ok(rm._reward_cards[0].has_focus(), "%s opened: initial focus card 0" % tag)
	_fit(root.find_child("TreasureReward", true, false), sc, tag + " opened", false)
	var hd := root.find_child("Header", true, false)   # the RewardCards are R2's component; align here = Header (ShardPill)
	_ok(Align.pairs(hd) > 0 and Align.check(hd, 1.5, tag).is_empty(), "%s opened: Header aligned (%d pairs)" % [tag, Align.pairs(hd)])
	rm._select_reward(0)
	await _frames(4)
	_ok(not tb.disabled and tb.text == "Take and continue" and tb.get_node_or_null("KeyCap") != null, "%s opened: pick turns Take on" % tag)


func _ready() -> void:
	print("=== t_ui5_event_treasure: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	await _frames(2)
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)
	for sc in [1.0, 2.0 / 3.0]:
		get_window().size = Vector2i(1920, 1080) if sc > 0.9 else Vector2i(1280, 720)   # headless default is 64x64 = a square 1920 viewport
		await _frames(3)
		await _event(sc)
		await _treasure(sc)
	# Empty vault: Continue (TakeButton) with the Space keycap and focus, pressing it finishes the node.
	RunState.pending_rewards.assign([])
	rm.call("_build_treasure", true)
	await _frames(4)
	var ct := rm._overlay_root.find_child("TakeButton", true, false) as Button
	_ok(ct != null and ct.text == "Continue" and not ct.disabled and ct.has_focus() and ct.get_node_or_null("KeyCap") != null, "empty vault: Continue with keycap and focus")
	_ok(rm._overlay_root.find_child("CardRow", true, false) == null, "empty vault: no card row")
	ct.pressed.emit()
	await _frames(6)
	var ov: Node = rm._overlay_root
	_ok(not is_instance_valid(ov) or ov.find_child("TakeButton", true, false) == null or not (ov as CanvasItem).visible, "empty vault: Continue finished the node (screen closed)")
	# One real choose: exactly one event_choose in the log, ChooseButton drives it.
	UI3Theme.set_scale_override(1.0)
	rm.call("_on_event_node", "x")
	await _frames(3)
	rm._select_event(0)
	var n0 := 0
	for e in RunState.action_log.entries:
		n0 += 1 if String((e as Dictionary).get("fn", "")).begins_with("event") else 0
	(rm._overlay_root.find_child("ChooseButton", true, false) as Button).pressed.emit()
	await _frames(12)
	var n1 := 0
	for e in RunState.action_log.entries:
		n1 += 1 if String((e as Dictionary).get("fn", "")).begins_with("event") else 0
	_ok(n1 == n0 + 1, "real choose logs exactly one event entry (%d -> %d)" % [n0, n1])
	_ok(rm._overlay_root.find_child("OutcomeText", true, false) != null, "real choose shows OutcomeText")
	UI3Theme.set_scale_override(-1.0)
	RunState.pending_rewards.assign([])
	rm.queue_free()
	_guard.restore()
	print("=== t_ui5_event_treasure: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_event_treasure: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)
