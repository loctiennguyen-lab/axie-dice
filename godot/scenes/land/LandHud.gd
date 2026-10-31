class_name LandHud
extends RefCounted
## Land hub HUD pieces moved out of Land.gd (UI-05 b23 lane 0c): Run plate + "Start here" coach, offline banner,
## toast stack and the confirm dialog. Code only moved: every piece of state still lives on the LandHub (`_l`),
## and LandHub keeps same-name forwarders for everything tests and tools call.

var _l: Node3D   # the LandHub


func _init(land: Node3D) -> void:
	_l = land


## Primary "Start run" (guest on the server build: "Sign in to play"). Name stays RunPlate.
func build_run_button() -> Button:
	var title := "Start run"
	var tip := "Your first run" if _l._first else "Run Setup"
	if _l._has_run:
		if _l._mission_run:
			title = "Continue mission"
			tip = mission_line()
		else:
			title = "Continue run"
			tip = continue_line()
	elif _l._guest_blocked():
		title = "Sign in to play"
		tip = "Dice are rolled on the server, so runs need an account"
	var plate := UI3.button(title, &"primary", &"L")
	plate.name = "RunPlate"
	plate.tooltip_text = tip
	plate.pressed.connect(_l._on_run_pressed)
	if _l._offline and not _l._has_run and not _l._guest_blocked():   # round 2: a new run needs a connection
		UI3.set_disabled_reason(plate, "Start run · needs connection")
	if _l._first and not _l._has_run:
		plate.grab_focus.call_deferred()
	# "Start here" coach card (640 wide, 32x20 arrow toward the Start run spotlight).
	var hint := VBoxContainer.new()
	_l._start_hint = hint
	hint.name = "StartHint"
	hint.theme = UI3Theme.get_theme()
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_constant_override("separation", 0)
	var card := UI3.plate(&"dialog")
	card.custom_minimum_size.x = 640
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hv := VBoxContainer.new()
	hv.add_child(UI3.label("Start here", "LabelTitle"))
	var hb := UI3.label("Pick a mode and play your first run", "LabelMuted")
	hb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hb.custom_minimum_size.x = 592   # card 640 minus 24 padding each side
	hv.add_child(hb)
	card.add_child(hv)
	hint.add_child(card)
	var arrow := Control.new()
	arrow.name = "HintArrow"
	arrow.custom_minimum_size = Vector2(640, 20)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.draw.connect(func() -> void:
		var cx := 640.0 - plate.size.x * 0.5
		arrow.draw_colored_polygon(PackedVector2Array([Vector2(cx - 16, 0), Vector2(cx + 16, 0), Vector2(cx, 20)]),
			UI3Theme.color("panel")))
	hint.add_child(arrow)
	hint.visible = _l._first and not _l._has_run and not _l._guest
	_l._ui.add_child(hint)
	return plate


func continue_line() -> String:
	if not _l._has_run:
		return ""
	return "%s · Ascension %d" % [String(RunState.mode).capitalize(), int(RunState.ascension)]


func mission_line() -> String:
	var e: Dictionary = MetaState.mission_escrow
	return "Mission %s · stake %s" % [String(e.get("mission_id", "N?")).to_upper(), UI3.fmt(int(e.get("stake", 0)))]


func build_banners() -> void:
	var b: Control = UI3.net_notice("Offline · Runs, Store, Pass, Echo Box, Daily and Leaderboard need a connection.",
		"Retry", _l._on_retry)
	_l._offline_banner = b
	b.name = "OfflineBanner"
	b.custom_minimum_size = Vector2(600, 0)
	var msg := b.find_children("*", "Label", true, false)
	if not msg.is_empty():
		(msg[0] as Label).custom_minimum_size.x = 440
	var rb := b.find_child("Retry", true, false)
	if rb != null:
		rb.name = "RetryButton"
	b.visible = _l._offline
	_l._ui.add_child(b)


func on_retry() -> void:
	if _l._detect_offline():
		show_toast("Still offline", 1.6, &"error")
		return
	LandHub.qa.erase("offline")
	_l.get_tree().reload_current_scene()


func build_toast() -> void:
	# UI-03 18-system: the toast is rebuilt per message by show_toast (UI3.toast, top-centre 24 px down).
	_l._toast = null


func show_toast(text: String, hold: float = 1.6, tone: StringName = &"ok") -> void:
	# Stack of at most 3, top-centre, 24 px from the top, 8 px gap (UI-03 18-system).
	_l._toasts = _l._toasts.filter(func(t: Variant) -> bool: return is_instance_valid(t))
	# S4-14: one toast at a time (they stacked over the Upgrade Land chip); the rest wait their turn.
	if not _l._toasts.is_empty() and not _l._draining:
		_l._toast_queue.append([text, hold, tone])
		return
	var tw_node := UI3.toast(text, tone)
	tw_node.name = "Toast"
	tw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_l._ui.add_child(tw_node)
	_l._toasts.append(tw_node)
	_l._toast = tw_node
	layout_toasts()
	var tw := _l.create_tween()
	tw.tween_interval(hold)
	tw.tween_property(tw_node, "modulate:a", 0.0, UI3Motion.REDUCED_MAX_SEC if UI3Motion.reduced() else 0.4)
	tw.tween_callback(func() -> void:
		if is_instance_valid(tw_node):
			tw_node.queue_free()
		_l._toasts.erase(tw_node)
		layout_toasts()
		if not _l._toast_queue.is_empty() and _l._toasts.is_empty() and _l.is_inside_tree():
			var nx: Array = _l._toast_queue.pop_front()
			_l._draining = true
			show_toast(String(nx[0]), float(nx[1]), nx[2])
			_l._draining = false)


func layout_toasts() -> void:
	var y := 24.0
	for t in _l._toasts:
		if not is_instance_valid(t) or t.is_queued_for_deletion():
			continue
		var c := t as Control
		c.reset_size()
		c.position = Vector2((_l._ui.size.x - c.size.x) * 0.5, y)
		y += c.size.y + 8.0


func open_confirm(title: String, body: String, ok_text: String, on_ok: Callable, _warning: bool = false,
		cancel_text: String = "Cancel", loss: Array = [], _head: Color = Color(0, 0, 0, 0)) -> void:
	if _l._modal != null:
		return
	# UI-03 18-system: UI3.modal (560 w dialog). Destructive (`loss` given) = red button + focus on Cancel;
	# otherwise amber primary + focus on the primary action.
	var destructive := loss.size() >= 2
	var cancel := UI3.button(cancel_text, &"secondary")
	cancel.name = "ConfirmCancel"
	cancel.pressed.connect(_l._close_modal)
	var ok := UI3.button(ok_text, &"danger" if destructive else &"primary")
	ok.name = "ConfirmOk"
	ok.pressed.connect(on_ok)
	var m := UI3.modal(title, body, [cancel, ok], 0 if destructive else 1)
	m.name = "Confirm"
	m.cancelled.connect(_l._close_modal)
	if destructive:
		var row := ok.get_parent()
		var lb := UI3.plate(&"row")
		lb.name = "LossRow"
		lb.custom_minimum_size = Vector2(0, 48)
		var lv := VBoxContainer.new()
		lv.add_child(UI3.label(String(loss[0])))
		lv.add_child(UI3.label(String(loss[1]), "LabelMuted"))
		lb.add_child(lv)
		row.get_parent().add_child(lb)
		row.get_parent().move_child(lb, row.get_index())
	_l._modal = m
	_l._ui.add_child(m)


func close_modal() -> void:
	if _l._modal != null:
		_l._modal.queue_free()
		_l._modal = null
