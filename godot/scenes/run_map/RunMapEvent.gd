class_name RunMapEvent
extends RefCounted
## Event screen. Split out of RunMapController (UI-05 b23 lane 0b): code moved as-is, state stays on the controller (`ctrl`).
## The controller keeps a same-name forwarder for every method here.


var ctrl: RunMapController


func _init(owner_ctrl: RunMapController) -> void:
	ctrl = owner_ctrl

func _on_event_node(_node_id: String) -> void:
	if RunState.event_key.is_empty():
		push_error("RunMapController: no playable events in ContentDB - cannot resolve event node")
		ctrl._finish_node()
		return
	ctrl._event_opts = RunState.event_options()
	ctrl._event_sel = -1
	_build_event_screen(-1, "")


## `picked` < 0: choices. Otherwise the outcome: the other choices at 40%, `outcome` as the body.
func _build_event_screen(picked: int, outcome: String) -> void:
	var ev: Dictionary = ContentDB.events.get(RunState.event_key, {})
	var host := ctrl._open_ui3_screen()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 48)
	center.add_child(row)

	var art := UI3.plate(&"plate")
	art.name = "EventArt"
	art.custom_minimum_size = Vector2(720, 720)
	row.add_child(art)
	var art_c := CenterContainer.new()
	art.add_child(art_c)
	var art_i := TextureRect.new()
	art_i.texture = UI3.icon("node_event")
	art_i.custom_minimum_size = Vector2(320, 320)
	art_i.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_i.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_c.add_child(art_i)

	var col := VBoxContainer.new()
	col.custom_minimum_size.x = 720
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 24)
	row.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	col.add_child(head)
	var hi := TextureRect.new()
	hi.texture = UI3.icon("node_event")
	hi.custom_minimum_size = Vector2(64, 64)
	hi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(hi)
	var hc := VBoxContainer.new()
	head.add_child(hc)
	var title := UI3.label(String(ev.get("n", tr("Event"))), "LabelScreenTitle")
	title.name = "EventTitle"
	hc.add_child(title)
	hc.add_child(UI3.label(tr("Event · Row %d") % maxi(ctrl._current_row(), 0), "LabelMuted"))

	var body := UI3.label(outcome if picked >= 0 else String(ev.get("desc", "")))
	body.name = "EventBody"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(body)

	ctrl._overlay_vbox = VBoxContainer.new()
	ctrl._overlay_vbox.name = "EventOptions"
	ctrl._overlay_vbox.add_theme_constant_override("separation", 12)
	col.add_child(ctrl._overlay_vbox)
	ctrl._event_cards.clear()
	for i in ctrl._event_opts.size():
		_add_event_option(ctrl._event_opts[i], i, picked)

	var acts := HBoxContainer.new()
	acts.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(acts)
	var go := UI3.button(tr("Continue") if picked >= 0 else tr("Pick a choice"), &"primary", &"L")
	go.name = "EventAction"
	if picked >= 0:
		go.pressed.connect(func() -> void: ctrl._finish_node())
		go.grab_focus.call_deferred()
	else:
		UI3.set_disabled_reason(go, tr("Pick a choice"))
		go.pressed.connect(func() -> void: _on_event_choice(ctrl._event_sel))
		if not ctrl._event_cards.is_empty():
			ctrl._event_cards[0].grab_focus.call_deferred()
	acts.add_child(go)


func _select_event(index: int) -> void:
	ctrl._event_sel = index
	for c in ctrl._event_cards:
		c.theme_type_variation = "PanelCardSelected" if int(c.get_meta("opt")) == index else "PanelCard"
	var go := ctrl._overlay_root.find_child("EventAction", true, false) as Button
	if go != null and index >= 0 and index < ctrl._event_opts.size():
		UI3.clear_disabled_reason(go)
		go.text = tr("Choose")


func _add_event_option(raw: Dictionary, index: int, picked: int) -> Control:
	var card := UI3.plate(&"card")
	card.name = "EventOption%d" % index
	card.custom_minimum_size.y = 88
	ctrl._overlay_vbox.add_child(card)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	card.add_child(line)
	var ic := TextureRect.new()
	ic.texture = UI3.icon(String(ctrl._EVENT_FX_UI3.get(String(raw.get("fx", "")), "face_blank")))
	ic.custom_minimum_size = Vector2(56, 56)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	line.add_child(ic)
	var tc := VBoxContainer.new()
	tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(tc)
	tc.add_child(UI3.label(String(raw.get("text", "")), "LabelTitle"))
	var d := UI3.label(String(raw.get("desc", "")))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tc.add_child(d)
	card.set_meta("opt", index)
	if picked >= 0:
		card.modulate.a = 1.0 if index == picked else 0.4
		return card
	ctrl._event_cards.append(card)
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.draw.connect(func() -> void:
		if card.has_focus():
			card.draw_style_box(UI3Theme.focus_style(UI3Theme.radius("l")), Rect2(Vector2.ZERO, card.size)))
	card.focus_entered.connect(card.queue_redraw)
	card.focus_exited.connect(card.queue_redraw)
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			card.grab_focus()
			_select_event(index)
		elif ev.is_action_pressed("ui_accept") and not ev.is_echo():
			_select_event(index)
			var go := ctrl._overlay_root.find_child("EventAction", true, false) as Control
			if go != null:
				go.grab_focus())
	return card


func _on_event_choice(index: int) -> void:
	if index < 0:
		return
	var res: Dictionary = await RunState.request_choose_event_option(index)
	if not is_instance_valid(ctrl):
		return   # the run map was freed while waiting (scene change); the old Node coroutine stopped here
	if not bool(res["ok"]):
		if String(res["code"]) not in ["illegal", "busy"]:
			NetNotice.show(ctrl, String(res["code"]), _on_event_choice.bind(index))
		return
	ctrl._save_map_progress()   # the effect is already applied; quitting on the outcome must not hand it back
	_build_event_screen(index, String(res["msg"]))
