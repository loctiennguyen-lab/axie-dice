extends "res://scenes/shared/ui5/RewardCard.gd"
## UI-06 CoreCard (47-core-offer, ui06-run-cards.html). The face is a CoreCardShell (tier frame + crest + art window)
## held as child 0 ("Face": GachaReveal fades / flips child 0, covers are added after it). Inside Face > Content > Body:
## ArtWindow(FamilyEmblem, HouseTag) · (ComboTag) · CoreName (Rowdies 32) · Headline · Detail (RichTextLabel + Chipify)
## · BadgeRow (TagBadges) · (CapStrip) · RerollButton. No tier chip: the frame and crest carry the tier.
## Extends RewardCard for selection (cream ring + 12 lift), the focus ring and the GachaReveal contract.
## Strings and numbers come from the offer (CoreOffer / relic data), never from the mockup samples.

var tier := 0
var core_id := ""
var face: CoreCardShell
var body_box: VBoxContainer
var headline_label: Label
var detail: RichTextLabel
var badge_row: HFlowContainer
var combo_tag: Control = null
var house_tag: Control = null
var reroll_button: Button = null
var cap_strip: PanelContainer = null
var compact := false   ## art window at 60% (combo / cap card)


## tier 0..2; axis = core_axis (family emblem); title = Core name; id = relic key (headline lookup, house tag);
## tags = the Core's tags (TagBadges picks); is_compact = combo / cap card (art 60%, emblem 0.7).
func setup_core(core_tier: int, axis: String, title: String, id: String, body: String, tags: Variant = [], is_compact := false) -> void:
	tier = clampi(core_tier, 0, 2)
	core_id = id
	compact = is_compact
	theme = UI3Theme.get_theme()
	accent = CoreVisuals.tier_color(tier)
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	face = CoreCardShell.new().setup(tier, axis, false, 0.6 if compact else 1.0, 0.7 if compact else 1.0)
	face.name = "Face"
	add_child(face)
	custom_minimum_size = face.custom_minimum_size
	body_box = face.body
	column = face.body
	var inner := UI3Theme.size_of("core_card_w") - 2 * UI3Theme.size_of("core_pad")

	name_label = PanelParts.text(title, "text_screen_title", "text", true)
	name_label.name = "CoreName"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.custom_minimum_size.x = inner
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_box.add_child(name_label)

	headline_label = PanelParts.text("", "text_body", "text_muted", true)
	headline_label.name = "Headline"
	headline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headline_label.custom_minimum_size.x = inner
	headline_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	CoreHeadline.apply(headline_label, id)
	body_box.add_child(headline_label)

	detail = RichTextLabel.new()
	detail.name = "Detail"
	detail.bbcode_enabled = true
	detail.fit_content = true
	detail.scroll_active = false
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_override("normal_font", UI3Theme.font_body())
	detail.add_theme_font_size_override("normal_font_size", UI3Theme.size_of("text_body"))
	detail.add_theme_color_override("default_color", UI3Theme.color("text"))
	detail.custom_minimum_size.x = inner
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.text = Chipify.bbcode(body)
	detail.set_meta("plain", body)
	body_box.add_child(detail)

	badge_row = TagBadges.row(tags, axis)
	body_box.add_child(badge_row)

	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


## "+1 to awaken" / "Awakens" tag over the art window (a House Core of the current Anchor). No-op otherwise.
func add_house_tag() -> void:
	if house_tag != null or face == null:
		return
	var t := AwakenProgress.house_tag(core_id)
	if t == null:
		return
	house_tag = t
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	t.grow_horizontal = Control.GROW_DIRECTION_BOTH
	t.grow_vertical = Control.GROW_DIRECTION_BEGIN
	t.offset_bottom = -8
	face.art_window.add_child(t)


## PAIR / FULL tag + combo name (+ "With: ..." partners) above the Core name.
func add_combo_tag(full: bool, combo_name: String, with: String) -> void:
	if combo_tag != null:
		return
	var row := VBoxContainer.new()
	row.name = "ComboTag"
	row.add_theme_constant_override("separation", 2)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(UI3.combo_tier_tag(full, false))
	var nm := PanelParts.text(combo_name, "text_body", "text", true)
	nm.name = "ComboName"
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(nm)
	row.add_child(top)
	if with != "":
		var w := PanelParts.text(with, "text_body", "text_muted")
		w.name = "ComboWith"
		w.clip_text = true
		w.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		w.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(w)
	combo_tag = row
	body_box.add_child(row)
	body_box.move_child(row, name_label.get_index())


## `.cap-strip`: the Crystal cap notice, crystal bg + 2 px crystal border. Sits above the Reroll button.
func add_cap_strip(text: String) -> void:
	if cap_strip != null:
		return
	cap_strip = PanelParts.panel(UI3Theme.flat(UI3Theme.color("tier_crystal_bg"), UI3Theme.radius("s"), UI3Theme.stroke("hairline"),
		UI3Theme.color("tier_crystal"), Vector4(UI3Theme.space("12"), UI3Theme.space("8"), UI3Theme.space("12"), UI3Theme.space("8"))), "CapStrip")
	cap_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := PanelParts.text(text)
	l.name = "Text"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = UI3Theme.size_of("core_card_w") - 2 * UI3Theme.size_of("core_pad") - 2 * UI3Theme.space("12")
	cap_strip.add_child(l)
	body_box.add_child(cap_strip)
	if reroll_button != null:
		body_box.move_child(cap_strip, reroll_button.get_index())


func add_reroll(btn: Button) -> void:
	reroll_button = btn
	body_box.add_child(btn)
