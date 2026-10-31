class_name Ui5EchoParts
extends RefCounted
## UI-05 Echo Box pieces (ui05-meta2-screens.html, frames 20-echo*): Banner (ToneDisc + optional button), the dialog used by
## Open10Confirm / BuyTicketConfirm / SeasonConfirm / RatesModal (safe button first, focus + Space), Shard cluster for Buy ticket.
## Numbers and words come from the screen; nothing here knows a price or a rate.
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


## Banner plate: ToneDisc, Title + Detail, optional right button (name e.g. "TryAgainButton", "SignInButton").
static func banner(tone: StringName, msg: String, detail: String, btn_text := "", cb := Callable()) -> PanelContainer:
	var pad := Vector4(UI3Theme.space("16"), UI3Theme.space("12"), UI3Theme.space("16"), UI3Theme.space("12"))
	var p := PanelParts.panel(UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("l"), UI3Theme.stroke("rim"),
		UI3Theme.color("notice_warn"), pad, PanelParts.lip(UI3Theme.color("plate_ink"))), "Banner")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(h)
	h.add_child(Ui5ToneDisc.make(tone))
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var t := Ui5Text.label(msg, "text_body", "text", true)
	t.name = "Title"
	v.add_child(t)
	var d := Ui5Text.label(detail, "text_body", "text")
	d.name = "Detail"
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	if btn_text != "":
		var b := UI3.button(btn_text, &"secondary", &"S")
		b.name = "TryAgainButton" if btn_text == "Try again" else "SignInButton"
		if cb.is_valid():
			b.pressed.connect(cb)
		h.add_child(b)
	return p


## Dialog on a scrim in `layer`. `safe` (Cancel / Close) stands first, takes focus and carries the Space keycap; `act` (may be
## null) spends and has no keycap. `body` may be a Control (rates table) or "". Returns the ModalRoot.
static func dialog(layer: Control, node_name: String, title: String, body: String, extra: Control, safe: Button, act: Button,
		width_token := "defeat_panel_w") -> Control:
	var root := UI3.ModalRoot.new()
	root.theme = UI3Theme.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.name = "Modal"
	root.add_to_group("ui3_modal")
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
	var dlg := PanelParts.panel(PanelParts.plate_box("xl", UI3Theme.space("32")), node_name)
	dlg.custom_minimum_size.x = UI3Theme.size_of(width_token)
	center.add_child(dlg)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("20"))
	dlg.add_child(col)
	var ttl := Ui5Text.label(title, "text_banner", "text", true)
	ttl.name = "Title"
	ttl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(ttl)
	if body != "":
		var bl := Ui5Text.label(body, "text_body", "text")
		bl.name = "Body"
		bl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(bl)
	if extra != null:
		col.add_child(extra)
	col.add_child(Ui5ModalFooter.make(act if act != null else safe, safe if act != null else null))
	root.actions = [safe, act] if act != null else [safe]
	root.focus_index = 0
	layer.add_child(root)
	var cap := Ui5Keycap.make("Space")
	safe.add_child(cap)
	Ui5HudStyle.place_trailing(safe, cap, UI3Theme.space("24"))
	safe.resized.connect(func() -> void:
		if is_instance_valid(cap):
			Ui5HudStyle.place_trailing(safe, cap, UI3Theme.space("24")))
	return root


## [Shard icon][text] centred as one HBox over a secondary button (Button.icon would overlap the text).
static func shard_cluster(b: Button, text: String, after := "") -> void:
	b.text = ""
	var h := HBoxContainer.new()
	h.name = "ShardCluster"
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", UI3Theme.space("8"))
	var l := Ui5Text.label(text, "text_body", "text", true)
	l.name = "BuyText"
	h.add_child(l)
	var ic := PanelParts.icon_rect(UI3.currency_icon("cur_shard", UI3Theme.size_of("icon_s")), UI3Theme.size_of("icon_s"))
	ic.name = "ShardIcon"
	h.add_child(ic)
	if after != "":
		var a := Ui5Text.label(after, "text_body", "text", true)
		a.name = "BuyAmount"
		h.add_child(a)
	b.add_child(h)
	b.custom_minimum_size.x = maxf(b.custom_minimum_size.x, h.get_combined_minimum_size().x + 2.0 * UI3Theme.space("16"))
