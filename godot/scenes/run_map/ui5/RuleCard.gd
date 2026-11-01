extends "res://scenes/shared/ui5/RewardCard.gd"
## UI-05 RuleCard (05-run-rule-offer, round-2/ui05-run-screens.html `.rule-card`): rule_card_w x rule_card_h plate, padding 20, gap 12,
## radius xl, 3 px plate_rim border (a rule has no tier). Tree (data-names): RuleCard > Column > [Kind, ArtBox(icon tinted by the house
## colour), RuleName, Cap "Rule", RuleText, PriceBox(Cap "Price", PriceLine)]. "No Rule" has no PriceBox.
## Extends RewardCard so selection (cream ring + 12 lift) and the focus ring keep working.
## Strings come from the offer (RelicRegistry / run rule price table), never from the mockup samples.

var house := Color.WHITE
var face: CoreCardShell
var rule_text: RichTextLabel
var headline_label: Label
var price_box: PanelContainer = null
var price_line: Label = null


## UI-06: the card is a CoreCardShell in Run Rule mode (walnut plaque, never a tier frame; no crest, no art window).
## Body: RuleName (Rowdies 32) · Headline · RuleText (chip detail) · PriceBox. `house_col` only tints the price caption;
## `icon` / `kind_word` are kept for callers, the plaque carries its own seal. price = "" for no price (No Rule).
func setup_rule(house_col: Color, _kind_word: String, _icon: Texture2D, title: String, body: String, price: String, rule_key := "") -> void:
	house = house_col
	accent = UI3Theme.color("plate_rim")
	theme = UI3Theme.get_theme()
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	face = CoreCardShell.new().setup(0, "run_rule", true)
	face.name = "Face"
	add_child(face)
	custom_minimum_size = face.custom_minimum_size
	text_box = face.body
	column = face.body
	var inner := UI3Theme.size_of("rule_card_w") - 2 * UI3Theme.size_of("core_pad")

	name_label = PanelParts.text(title, "text_screen_title", "text", true)
	name_label.name = "RuleName"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.custom_minimum_size.x = inner
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(name_label)

	headline_label = PanelParts.text("", "text_body", "text_muted", true)
	headline_label.name = "Headline"
	headline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headline_label.custom_minimum_size.x = inner
	headline_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	CoreHeadline.apply(headline_label, rule_key)
	text_box.add_child(headline_label)

	rule_text = RichTextLabel.new()
	rule_text.name = "RuleText"
	rule_text.bbcode_enabled = true
	rule_text.fit_content = true
	rule_text.scroll_active = false
	rule_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule_text.add_theme_font_override("normal_font", UI3Theme.font_body())
	rule_text.add_theme_font_size_override("normal_font_size", UI3Theme.size_of("text_body"))
	rule_text.add_theme_color_override("default_color", UI3Theme.color("text"))
	rule_text.custom_minimum_size.x = inner
	rule_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rule_text.text = Chipify.bbcode(body)
	rule_text.set_meta("plain", body)
	text_box.add_child(rule_text)

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
		price_line = PanelParts.text("\u2212 " + price, "text_body", "anchor_price", true)
		price_line.name = "PriceLine"
		price_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		price_line.custom_minimum_size.x = inner - 2 * UI3Theme.space("16")
		v.add_child(price_line)
		text_box.add_child(price_box)

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
