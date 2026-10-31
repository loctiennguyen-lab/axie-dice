extends RefCounted
## UI-05 b23 lane S1b: Land overlays (round-3 ui05-land-screens.html, 01-land--first-visit / offline / reconnecting /
## new-run-confirm / abandon-mission-confirm / beta-reset). Static builders only; LandHud owns the state and wiring.
## Every size is a token; every string comes from the caller.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const Plates := preload("res://scenes/land/ui5/LandPlates.gd")


## StartHint: 640 coach plate (Title + Body) and a 32x20 arrow whose tip is `tip_x` px from the card's left edge.
static func coach(title: String, body: String, tip_x: Callable) -> VBoxContainer:
	var hint := VBoxContainer.new()
	hint.name = "StartHint"
	hint.theme = UI3Theme.get_theme()
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.add_theme_constant_override("separation", 0)
	var w := UI3Theme.size_of("coach_w")
	var card := PanelParts.panel(PanelParts.plate_box("l", 0), "Card")
	card.custom_minimum_size.x = w
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := MarginContainer.new()
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_theme_constant_override("margin_left", UI3Theme.space("24"))
	m.add_theme_constant_override("margin_right", UI3Theme.space("24"))
	m.add_theme_constant_override("margin_top", UI3Theme.space("20"))
	m.add_theme_constant_override("margin_bottom", UI3Theme.space("20"))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("4"))
	var t := PanelParts.text(title, "text_title", "text", true)
	t.name = "Title"
	v.add_child(t)
	var b := PanelParts.text(body, "text_body", "text_muted")
	b.name = "Body"
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.x = w - 2 * UI3Theme.space("24")
	v.add_child(b)
	m.add_child(v)
	card.add_child(m)
	hint.add_child(card)
	var aw := float(UI3Theme.size_of("coach_arrow_w"))
	var ah := float(UI3Theme.size_of("coach_arrow_h"))
	var arrow := Control.new()
	arrow.name = "Arrow"
	arrow.custom_minimum_size = Vector2(w, ah)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.draw.connect(func() -> void:
		var cx: float = tip_x.call()
		arrow.draw_colored_polygon(PackedVector2Array([Vector2(cx - aw * 0.5, 0), Vector2(cx + aw * 0.5, 0), Vector2(cx, ah)]),
			UI3Theme.color("plate_rim")))
	hint.add_child(arrow)
	return hint


## Spotlight ring (coach_ring, stroke selected) around the coached control. Child of the control, ignores the mouse.
static func spotlight(target: Control, radius_px: int) -> Panel:
	var p := Panel.new()
	p.name = "Spotlight"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_theme_stylebox_override("panel", PanelParts.ring_style(UI3Theme.color("coach_ring"), UI3Theme.stroke("selected"), 0, radius_px))
	target.add_child(p)
	return p


## OfflineBanner: 600 wide plate with a warn rim, ToneDisc, Message and RetryButton (or a Spinner while reconnecting).
static func banner(text: String, retry_text: String, on_retry: Callable, reconnecting := false) -> PanelContainer:
	var s8 := UI3Theme.space("8")
	var box := UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("m"), UI3Theme.stroke("rim"), UI3Theme.color("notice_warn"),
		Vector4(UI3Theme.space("16"), s8, s8, s8), PanelParts.lip(UI3Theme.color("plate_ink")))
	var p := PanelParts.panel(box, "OfflineBanner")
	var w := UI3Theme.size_of("offline_banner_w")
	p.custom_minimum_size.x = w
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(row)
	row.add_child(Ui5ToneDisc.make(&"warn"))
	var l := Ui5Text.label(text, "text_body", "text")
	l.name = "Message"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = 100
	row.add_child(l)
	if reconnecting:
		row.add_child(Ui5Spinner.new())
	else:
		var b := UI3.button(retry_text, &"secondary", &"S")
		b.name = "RetryButton"
		b.pressed.connect(on_retry)
		row.add_child(b)
	return p


## Modal shell: scrim + centred dialog (defeat_panel_w). Returns the ModalRoot; `col` of the dialog is meta "col".
static func dialog(root_name: String, dlg_name: String, title: String, body: String, danger_title := false) -> UI3.ModalRoot:
	var root := UI3.ModalRoot.new()
	root.theme = UI3Theme.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.name = root_name
	root.add_to_group("ui3_modal")
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		UI3Tooltip.hide_all(tree)
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = UI3Theme.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var dlg := PanelParts.panel(PanelParts.plate_box("xl", UI3Theme.space("32")), dlg_name)
	dlg.custom_minimum_size.x = UI3Theme.size_of("defeat_panel_w")
	center.add_child(dlg)
	var col := VBoxContainer.new()
	col.name = "Col"
	col.add_theme_constant_override("separation", UI3Theme.space("20"))
	dlg.add_child(col)
	var head := VBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", UI3Theme.space("4"))
	var t := Ui5Text.label(title, "text_banner", "danger_text" if danger_title else "text", true)
	t.name = "Title"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(t)
	var b := Ui5Text.label(body, "text_body", "text")
	b.name = "Body"
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(b)
	col.add_child(head)
	root.set_meta("col", col)
	return root


## LossRows: danger_bg box, label line in danger_text over a body line; optional shard icon.
static func loss_rows(label: String, line: String, with_shard := false) -> PanelContainer:
	var box := UI3Theme.flat(UI3Theme.color("danger_bg"), UI3Theme.radius("l"), 0, Color.TRANSPARENT,
		Vector4(UI3Theme.space("20"), UI3Theme.space("16"), UI3Theme.space("20"), UI3Theme.space("16")))
	var p := PanelParts.panel(box, "LossRows")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(row)
	if with_shard:
		row.add_child(PanelParts.icon_rect(UI3.currency_icon("shard", UI3Theme.size_of("icon_l")), UI3Theme.size_of("icon_l")))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("4"))
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var a := Ui5Text.label(label, "text_body", "danger_text", true)
	a.name = "Label"
	v.add_child(a)
	var b := Ui5Text.label(line, "text_body", "text")
	b.name = "Line"
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(b)
	row.add_child(v)
	return p


## Footer for a destructive confirm: [safe] ... [danger] (space-between), the safe button carries the Space cap.
static func confirm_footer(safe: Button, danger: Button) -> Control:
	var f := Ui5ModalFooter.make(danger, safe)
	var sp := Control.new()
	sp.name = "Spacer"
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.add_child(sp)
	f.move_child(sp, 1)
	return f


## Space keycap on a secondary (safe) button.
static func safe_cap(b: Button) -> void:
	var cap := Plates.attach_space_cap(b, UI3Theme.space("32"))
	Ui5Keycap.set_variant(cap, &"plain")
