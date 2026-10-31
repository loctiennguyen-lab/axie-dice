extends "res://scenes/shared/ui5/RewardCard.gd"
## UI-05 CoreCard (47-core-offer, round-2/ui05-run-screens.html `.core-card`): core_card_w x core_card_h plate, padding 20, gap 12,
## radius xl, 3 px border in the tier colour. Tree (data-names): CoreCard > Column > [ArtBox, CoreName, (ComboTag), ChipRow(TierChip,
## CategoryChip, ComboChip, HouseTag / AwakenChip), RuleText, (CapStrip), RerollButton].
## Extends RewardCard so selection (cream ring + 12 lift), the Crystal prism and GachaReveal (child 0 = content column) keep working.
## Strings and numbers come from the offer (CoreOffer / relic data), never from the mockup samples.

const _TIER_KEY := ["moss", "amber", "crystal"]

var tier := 0
var chip_row: HFlowContainer
var rule_text: Label
var reroll_button: Button
var cap_strip: PanelContainer = null


## tier 0..2 (Moss / Amber / Crystal); title = Core name; icon = the axis glyph; tier_word = translated tier name.
func setup_core(core_tier: int, tier_word: String, icon: Texture2D, title: String, body: String) -> void:
	tier = clampi(core_tier, 0, 2)
	theme = UI3Theme.get_theme()
	var tier_col := UI3Theme.color("tier_" + _TIER_KEY[tier])
	accent = tier_col
	var pad := UI3Theme.space("20")
	var box := PanelParts.plate_box("xl", pad)
	box.set_border_width_all(UI3Theme.stroke("btn"))
	box.border_color = tier_col
	add_theme_stylebox_override("panel", box)
	custom_minimum_size = Vector2(UI3Theme.size_of("core_card_w"), UI3Theme.size_of("core_card_h"))
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	column = VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", UI3Theme.space("12"))
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	art = Panel.new()
	art.name = "ArtBox"
	art.custom_minimum_size = Vector2(0, UI3Theme.size_of("core_art_h"))
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("l"),
		UI3Theme.stroke("selected"), tier_col))
	column.add_child(art)
	var px := UI3Theme.size_of("core_glyph")
	art_icon = PanelParts.icon_rect(icon, px)
	art_icon.set_anchors_preset(Control.PRESET_CENTER)
	art_icon.offset_left = -px / 2.0
	art_icon.offset_right = px / 2.0
	art_icon.offset_top = -px / 2.0
	art_icon.offset_bottom = px / 2.0
	art.add_child(art_icon)

	name_label = PanelParts.text(title, "text_banner" if tier >= 2 else "text_screen_title", "text", true)
	name_label.name = "CoreName"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.custom_minimum_size.x = UI3Theme.size_of("core_card_w") - 2 * pad
	column.add_child(name_label)

	chip_row = HFlowContainer.new()
	chip_row.name = "ChipRow"
	chip_row.add_theme_constant_override("h_separation", UI3Theme.space("4"))
	chip_row.add_theme_constant_override("v_separation", UI3Theme.space("4"))
	chip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rarity_chip = tier_chip(tier, tier_word, "TierChip")
	chip_row.add_child(rarity_chip)
	column.add_child(chip_row)

	rule_text = PanelParts.text(body)
	rule_text.name = "RuleText"
	rule_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule_text.custom_minimum_size.x = UI3Theme.size_of("core_card_w") - 2 * pad
	rule_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(rule_text)

	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


## `.tier-chip`: tag_h high pill, tier_*_bg fill, 2 px tier border, Rowdies text_key in the tier colour. Child "Text".
static func tier_chip(t: int, word: String, node_name := "TierChip") -> PanelContainer:
	var key: String = _TIER_KEY[clampi(t, 0, 2)]
	var pad := UI3Theme.space("12")
	var col := UI3Theme.color("tier_" + key)
	var chip := PanelParts.panel(UI3Theme.flat(UI3Theme.color("tier_%s_bg" % key), UI3Theme.radius("pill"), UI3Theme.stroke("hairline"),
		col, Vector4(pad, 0, pad, 0)), node_name)
	chip.custom_minimum_size = Vector2(0, UI3Theme.size_of("tag_h"))
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := PanelParts.text(word, "text_key", "tier_" + key, true)
	l.name = "Text"
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(l)
	return chip


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
	l.custom_minimum_size.x = UI3Theme.size_of("core_card_w") - 2 * UI3Theme.space("20") - 2 * UI3Theme.space("12")
	cap_strip.add_child(l)
	column.add_child(cap_strip)
	if reroll_button != null:
		column.move_child(cap_strip, reroll_button.get_index())
