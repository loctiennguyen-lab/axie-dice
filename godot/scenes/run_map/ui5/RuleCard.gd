extends "res://scenes/shared/ui5/RewardCard.gd"
## UI-05 RuleCard (05-run-rule-offer, round-2/ui05-run-screens.html `.rule-card`): rule_card_w x rule_card_h plate, padding 20, gap 12,
## radius xl, 3 px plate_rim border (a rule has no tier). Tree (data-names): RuleCard > Column > [Kind, ArtBox(icon tinted by the house
## colour), RuleName, Cap "Rule", RuleText, PriceBox(Cap "Price", PriceLine)]. "No Rule" has no PriceBox.
## Extends RewardCard so selection (cream ring + 12 lift) and the focus ring keep working.
## Strings come from the offer (RelicRegistry / run rule price table), never from the mockup samples.

var house := Color.WHITE
var rule_text: Label
var price_box: PanelContainer = null
var price_line: Label = null


## house = tint of the ArtBox border and glyph; kind_word = translated "Run rule"; price = "" for no price (No Rule).
func setup_rule(house_col: Color, kind_word: String, icon: Texture2D, title: String, body: String, price: String) -> void:
	house = house_col
	accent = house_col
	theme = UI3Theme.get_theme()
	var pad := UI3Theme.space("20")
	var box := PanelParts.plate_box("xl", pad)
	box.set_border_width_all(UI3Theme.stroke("btn"))
	box.border_color = UI3Theme.color("plate_rim")
	add_theme_stylebox_override("panel", box)
	var inner := UI3Theme.size_of("rule_card_w") - 2 * pad
	custom_minimum_size = Vector2(UI3Theme.size_of("rule_card_w"), UI3Theme.size_of("rule_card_h"))
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	column = VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", UI3Theme.space("12"))
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	var kind := PanelParts.text(kind_word, "text_body", "text_muted")
	kind.name = "Kind"
	# Own row: the muted word is card text, not a label under the ArtBox icon (align check).
	var kind_row := HBoxContainer.new()
	kind_row.name = "KindRow"
	kind_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kind_row.add_child(kind)
	column.add_child(kind_row)

	art = Panel.new()
	art.name = "ArtBox"
	art.custom_minimum_size = Vector2(0, UI3Theme.size_of("core_art_h"))
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("l"),
		UI3Theme.stroke("selected"), house))
	column.add_child(art)
	var px := UI3Theme.size_of("core_glyph")
	art_icon = PanelParts.icon_rect(icon, px)
	art_icon.modulate = house
	art_icon.set_anchors_preset(Control.PRESET_CENTER)
	art_icon.offset_left = -px / 2.0
	art_icon.offset_right = px / 2.0
	art_icon.offset_top = -px / 2.0
	art_icon.offset_bottom = px / 2.0
	art.add_child(art_icon)

	var body_box := VBoxContainer.new()
	body_box.name = "Body"
	body_box.add_theme_constant_override("separation", UI3Theme.space("12"))
	body_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body_box)

	name_label = PanelParts.text(title, "text_screen_title", "text", true)
	name_label.name = "RuleName"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.custom_minimum_size.x = inner
	body_box.add_child(name_label)

	var cap := PanelParts.text(TranslationServer.translate("Rule"), "text_key", "text_muted", true)
	cap.name = "RuleCap"
	body_box.add_child(cap)

	rule_text = PanelParts.text(body)
	rule_text.name = "RuleText"
	rule_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule_text.custom_minimum_size.x = inner
	rule_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_box.add_child(rule_text)

	if price != "":
		price_box = PanelParts.panel(PanelParts.cell_box(UI3Theme.space("12"), UI3Theme.space("16")), "PriceBox")
		price_box.custom_minimum_size.x = inner
		price_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", UI3Theme.space("4"))
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		price_box.add_child(v)
		var pc := PanelParts.text(TranslationServer.translate("Price"), "text_key", "text_muted", true)
		pc.name = "PriceCap"
		v.add_child(pc)
		price_line = PanelParts.text("− " + price, "text_body", "anchor_price", true)
		price_line.name = "PriceLine"
		price_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		price_line.custom_minimum_size.x = inner - 2 * UI3Theme.space("16")
		v.add_child(price_line)
		body_box.add_child(price_box)

	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


## Index into the tint list for a rule key; steps past tints already used by the other card(s) so two cards never match.
static func tint_index(key: String, count: int, used: Array) -> int:
	var i := absi(key.hash()) % count
	for _n in count:
		if not used.has(i):
			return i
		i = (i + 1) % count
	return i
