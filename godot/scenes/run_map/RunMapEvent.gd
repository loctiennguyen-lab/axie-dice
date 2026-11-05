class_name RunMapEvent
extends RefCounted
## Event screen. Split out of RunMapController (UI-05 b23 lane 0b): code moved as-is, state stays on the controller (`ctrl`).
## The controller keeps a same-name forwarder for every method here.


const _PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")

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


## `picked` < 0: choices. Otherwise the outcome: the picked row keeps its ring, the other choices at 40%, `outcome` in
## the OutcomeText box. UI-05 frames event--choices / event--outcome (design round-2): EventScreen = EventArt (720) +
## EventColumn (720): head, body or outcome, Choices, one button (ChooseButton, then ContinueButton).
func _build_event_screen(picked: int, outcome: String) -> void:
	UI3Theme.sync_scale()   # the 1280 text floor follows the window
	var ev: Dictionary = ContentDB.events.get(RunState.event_key, {})
	var host := ctrl._open_ui3_screen()
	var screen := HBoxContainer.new()
	screen.name = "EventScreen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.alignment = BoxContainer.ALIGNMENT_CENTER
	screen.add_theme_constant_override("separation", UI3Theme.space("40"))
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(screen)

	var art_px := UI3Theme.size_of("event_art")
	var art := UI3.plate(&"plate")
	art.name = "EventArt"
	art.custom_minimum_size = Vector2(art_px, art_px)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	screen.add_child(art)
	var art_c := CenterContainer.new()
	art.add_child(art_c)
	var art_i := TextureRect.new()
	art_i.name = "EventIllustration"
	art_i.texture = UI6Assets.illustration("node_event")   # UI-06 painting (the header keeps the small node icon)
	var glyph := art_px * 0.9   # original square painting fills the plate (Liam 2/11), never cropped or stretched
	art_i.custom_minimum_size = Vector2(glyph, glyph)
	art_i.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_i.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_c.add_child(art_i)

	var col := VBoxContainer.new()
	col.name = "EventColumn"
	col.custom_minimum_size.x = UI3Theme.size_of("event_col_w")
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", UI3Theme.space("16"))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(col)

	var head := HBoxContainer.new()
	head.name = "EventHead"
	head.add_theme_constant_override("separation", UI3Theme.space("16"))
	col.add_child(head)
	var np := UI3Theme.size_of("node_icon")
	var hi := TextureRect.new()
	hi.texture = UI3.icon("node_event")
	hi.custom_minimum_size = Vector2(np, np)
	hi.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hi.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(hi)
	var hc := VBoxContainer.new()
	hc.name = "EventHeadText"
	hc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hc.add_theme_constant_override("separation", UI3Theme.space("4") / 2)
	head.add_child(hc)
	var title := _PanelParts.on_view(UI3.label(_sentence(String(ev.get("n", tr("Event")))), "LabelScreenTitle"))
	title.name = "EventTitle"
	hc.add_child(title)
	var erow := _PanelParts.on_view(UI3.label(event_subtitle(ctrl._current_row())))
	erow.name = "EventRow"
	hc.add_child(erow)

	if picked >= 0:
		var box := UI3Theme.flat(UI3Theme.color("success_bg"), UI3Theme.radius("l"), 2, UI3Theme.color("path_on"),
			Vector4(UI3Theme.space("20"), UI3Theme.space("16"), UI3Theme.space("20"), UI3Theme.space("16")))
		var oc := _PanelParts.panel(box, "OutcomeText")
		oc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(oc)
		var ol := UI3.label(core_words(outcome), "LabelTitle")
		ol.name = "Text"
		ol.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ol.custom_minimum_size.x = _wrap_w(40)
		oc.add_child(ol)
	else:
		var body := _PanelParts.on_view(UI3.label(core_words(String(ev.get("desc", "")))))
		body.name = "EventBody"
		body.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size.x = _wrap_w(0)
		col.add_child(body)

	ctrl._overlay_vbox = VBoxContainer.new()
	ctrl._overlay_vbox.name = "Choices"
	ctrl._overlay_vbox.add_theme_constant_override("separation", UI3Theme.space("12"))
	col.add_child(ctrl._overlay_vbox)
	ctrl._event_cards.clear()
	for i in ctrl._event_opts.size():
		_add_event_option(ctrl._event_opts[i], i, picked)

	var acts := HBoxContainer.new()
	acts.name = "Footer"
	acts.alignment = BoxContainer.ALIGNMENT_CENTER   # polish 3/11 #13: right under the choices, not in the far corner
	col.add_child(acts)
	# No choice is picked for the player: ChooseButton is off and says why (no Space cap) until a row is picked.
	var go := UI3.button(tr("Continue") if picked >= 0 else tr("Pick a choice"), &"primary", &"L")
	go.name = "ContinueButton" if picked >= 0 else "ChooseButton"
	acts.add_child(go)
	if picked >= 0:
		go.pressed.connect(_on_continue)
		Ui5RunScreenParts.set_space_cap(go, true)
		go.grab_focus.call_deferred()
	else:
		UI3.set_disabled_reason(go, tr("Pick a choice"))
		go.pressed.connect(_on_choose)
		if not ctrl._event_cards.is_empty():
			ctrl._event_cards[0].grab_focus.call_deferred()


## Screen titles elsewhere are sentence case ("Choose a run rule"); the event name arrives in Title Case.
## Second head line: "Event", plus the map row once the run is past the start (a row 0 / -1 reads as a bug).
static func event_subtitle(row: int) -> String:
	return String(TranslationServer.translate("Event · Row %d")) % row if row >= 1 else String(TranslationServer.translate("Event"))


## The player calls a relic a Core (Liam 29/10). Event data and outcomes still say "relic": swap the word, keep case.
static func core_words(s: String) -> String:
	var res := RegEx.create_from_string("\\bRELIC(S?)\\b").sub(s, "CORE$1", true)
	res = RegEx.create_from_string("\\b[Rr]elic(s?)\\b").sub(res, "Core$1", true)
	return res


static func _sentence(t: String) -> String:
	return t if t.length() < 2 else t.substr(0, 1).to_upper() + t.substr(1).to_lower()


## Wrap width for text in the event column: event_col_w less `pad` (side padding / icon) and the card padding.
func _wrap_w(pad: float) -> float:
	return UI3Theme.size_of("event_col_w") - pad - 2.0 * UI3Theme.space("20")


func _action_button() -> Button:
	if ctrl._overlay_root == null or not is_instance_valid(ctrl._overlay_root):
		return null
	return ctrl._overlay_root.find_child("ChooseButton", true, false) as Button


func _select_event(index: int) -> void:
	ctrl._event_sel = index
	for c in ctrl._event_cards:
		UI3.set_card_selected(c, int(c.get_meta("opt")) == index, false)
	var go := _action_button()
	if go != null and index >= 0 and index < ctrl._event_opts.size():
		if go.disabled:
			UI3.clear_disabled_reason(go)
		go.text = tr("Choose")
		Ui5RunScreenParts.set_space_cap(go, true)


func _add_event_option(raw: Dictionary, index: int, picked: int) -> Control:
	var card := UI3.plate(&"card")
	card.name = "ChoiceRow"
	card.custom_minimum_size.y = UI3Theme.size_of("choice_h")
	ctrl._overlay_vbox.add_child(card, true)   # ChoiceRow, ChoiceRow2, ...
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UI3Theme.space("16"))
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(line)
	var ic := TextureRect.new()
	ic.texture = UI3.icon(String(ctrl._EVENT_FX_UI3.get(String(raw.get("fx", "")), "face_blank")))
	var ipx := UI3Theme.size_of("choice_icon")
	ic.custom_minimum_size = Vector2(ipx, ipx)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(ic)
	var tc := VBoxContainer.new()
	tc.name = "Text"
	tc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tc.add_theme_constant_override("separation", UI3Theme.space("4"))
	tc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(tc)
	var tl := UI3.label(String(raw.get("text", "")), "LabelTitle")
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tc.add_child(tl)
	var d := UI3.label(core_words(String(raw.get("desc", ""))))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = _wrap_w(40 + 2 * 16 + UI3Theme.size_of("choice_icon"))   # a wrap width from the first layout pass (else the min height spikes)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tc.add_child(d)
	card.set_meta("opt", index)
	if picked >= 0:
		card.modulate.a = 1.0 if index == picked else 0.4
		UI3.set_card_selected(card, index == picked, false)
		return card
	ctrl._event_cards.append(card)
	card.focus_mode = Control.FOCUS_ALL
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.draw.connect(_draw_focus.bind(card))
	card.focus_entered.connect(card.queue_redraw)
	card.focus_exited.connect(card.queue_redraw)
	card.gui_input.connect(_card_input.bind(card, index))
	return card


func _on_continue() -> void:
	ctrl._finish_node()


func _on_choose() -> void:
	_on_event_choice(ctrl._event_sel)


func _draw_focus(card: Control) -> void:
	if card.has_focus():
		card.draw_style_box(UI3Theme.focus_style(UI3Theme.radius("l")), Rect2(Vector2.ZERO, card.size))


## Click or Space on a row picks it; focus then moves to Choose so Space really presses it (the keycap says so).
func _card_input(ev: InputEvent, card: Control, index: int) -> void:
	var by_mouse: bool = ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT
	if by_mouse or (ev.is_action_pressed("ui_accept") and not ev.is_echo()):
		_select_event(index)
		var go := _action_button()
		if go != null:
			go.grab_focus.call_deferred()
		card.accept_event()


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
