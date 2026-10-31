extends RefCounted
## UI-05 S4b: builders for the tutorial (37-tutorial, round-3/ui05-land-screens.html). Every number is a token.
## Node names = the frame's data-names (StepCard, StepLabel, Title, Body, SkipButton, GotItButton, Curtain, CtaButton,
## SkipTutorialButton, StarterPackCard, ShardCell, TutorialRewardPick, CardRow, Footer, TakeButton, SkipConfirm).

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


## Space keycap on a button that Space presses (primary variant), centred after the label. Needs the button in the tree.
static func add_space_cap(b: Button) -> void:
	if b.get_node_or_null("KeyCap") != null:
		return
	var cap := Ui5Keycap.make(KeyBindings.text(KeyBindings.COMBAT_END_TURN), b.get_meta("cap_variant", &"primary"))
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_child(cap)
	var pad := int(b.get_theme_stylebox("normal").content_margin_left)
	if not b.has_meta("cap_wired"):
		b.set_meta("cap_wired", true)
		b.resized.connect(func() -> void:
			var c := b.get_node_or_null("KeyCap") as Control
			if c != null:
				Ui5HudStyle.place_trailing(b, c, pad))
	Ui5HudStyle.place_trailing.call_deferred(b, cap, pad)


static func remove_space_cap(b: Button) -> void:
	var cap := b.get_node_or_null("KeyCap")
	if cap != null:
		b.remove_child(cap)
		cap.queue_free()
		Ui5HudStyle.reserve_trailing(b, null, int(b.get_theme_stylebox("normal").content_margin_left))


## `.step-card`: 640 plate, pad 24, gap 12. Column > StepLabel, Title, Body, StepFoot(SkipButton, GotItButton).
static func step_card() -> PanelContainer:
	var card := PanelParts.panel(Ui5HudStyle.plate_box(UI3Theme.radius("l"), Vector4(24, 24, 24, 24)), "StepCard")
	card.custom_minimum_size = Vector2(UI3Theme.size_of("step_card_w"), 0)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var col := VBoxContainer.new()
	col.name = "Column"
	col.add_theme_constant_override("separation", UI3Theme.space("12"))
	card.add_child(col)
	var w := UI3Theme.size_of("step_card_w") - 48.0
	var step := PanelParts.text("", "text_key", "text_muted", true)
	step.name = "StepLabel"
	col.add_child(step)
	var title := PanelParts.text("", "text_title", "text", true)
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = w
	col.add_child(title)
	var body := PanelParts.text("")
	body.name = "Body"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = w
	col.add_child(body)
	var foot := HBoxContainer.new()
	foot.name = "StepFoot"
	foot.add_theme_constant_override("separation", UI3Theme.space("16"))
	col.add_child(foot)
	var skip := UI3.button(TranslationServer.translate("Skip tutorial"), &"secondary", &"S")
	skip.name = "SkipButton"
	skip.focus_mode = Control.FOCUS_NONE
	foot.add_child(skip)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_child(sp)
	var got := UI3.button("", &"primary", &"M")
	got.name = "GotItButton"
	got.focus_mode = Control.FOCUS_NONE
	foot.add_child(got)
	return card


## One starter cell: icon, hero number (text_hero), label, muted sub. Named `<Kind>Cell`.
static func starter_cell(kind: String, icon: Texture2D, value: String, label: String, sub: String) -> PanelContainer:
	var cell := PanelParts.panel(PanelParts.cell_box(UI3Theme.space("16"), UI3Theme.space("16")), kind + "Cell")
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.add_theme_constant_override("separation", UI3Theme.space("4"))
	cell.add_child(v)
	var ic := PanelParts.icon_rect(icon, UI3Theme.size_of("icon_l"))
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	for spec in [[value, "text_hero", "text", true], [label, "text_body", "text", true]]:
		var l := PanelParts.text(spec[0], spec[1], spec[2], spec[3])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	if sub != "":
		var s := PanelParts.text(sub, "text_body", "text_muted")
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s.custom_minimum_size.x = 200
		v.add_child(s)
	return cell
