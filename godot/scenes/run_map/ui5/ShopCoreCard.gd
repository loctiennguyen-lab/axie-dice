extends PanelContainer
## UI-05 b23 lane R5a: ShopCoreCard (round-2 ui05-run-screens.html, shop--*). shop_card_w x shop_card_h plate, padding 16,
## gap 8, radius xl, tier-coloured border. Tree: ShopCoreCard > Column > [Art, CoreName, ChipRow(TierChip, CategoryChip),
## RuleText, spacer, BuyButton]. Price and rule text come from the offer dict; nothing is hardcoded here.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const Parts := preload("res://scenes/run_map/ui5/RunMenuParts.gd")

var column: VBoxContainer
var buy_button: Button
var index := -1


## `it`: a RunState.shop_items entry (kind relic). `why`: "" when buyable, else the disabled-button text.
func setup(it: Dictionary, shop_index: int, why: String) -> void:
	index = shop_index
	name = "ShopCoreCard"
	theme = UI3Theme.get_theme()
	set_meta("shop_index", shop_index)
	var def = RelicRegistry.get_def(String(it.get("key", "")))
	var tier := clampi(int(def.rarity) if def != null else int(it.get("rar", 0)), 0, 2)
	var tcol := UI3Theme.color(Parts.TIER_TOKEN[tier])
	var pad := UI3Theme.space("16")
	add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("xl"), UI3Theme.stroke("btn"),
		tcol, Vector4(pad, pad, pad, pad)))
	custom_minimum_size = Vector2(UI3Theme.size_of("shop_card_w"), UI3Theme.size_of("shop_card_h"))
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	column = VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", UI3Theme.space("8"))
	add_child(column)
	var axis := String(def.core_axis) if def != null else "stat"
	var art := Panel.new()
	art.name = "Art"
	art.custom_minimum_size = Vector2(0, UI3Theme.size_of("shop_art_h"))
	art.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("l"), UI3Theme.stroke("selected"), tcol))
	var px := 64
	var ic := PanelParts.icon_rect(UI3.icon(String(Parts.AXIS_ICON.get(axis, "face_buff"))), px)
	ic.set_anchors_preset(Control.PRESET_CENTER)
	ic.offset_left = -px / 2.0
	ic.offset_right = px / 2.0
	ic.offset_top = -px / 2.0
	ic.offset_bottom = px / 2.0
	art.add_child(ic)
	column.add_child(art)
	var nm := PanelParts.text(String(it.get("title", "")), "text_title", "text", true)
	nm.name = "CoreName"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER   # text under an icon is centred on it (Liam 29/10)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(nm)
	var chips := HFlowContainer.new()
	chips.name = "ChipRow"
	chips.add_theme_constant_override("h_separation", UI3Theme.space("8"))
	chips.add_theme_constant_override("v_separation", UI3Theme.space("8"))
	column.add_child(chips)
	chips.add_child(Parts.tier_chip(tier))
	chips.add_child(_category_chip(axis))
	var dsc := UI3.describe(String(it.get("desc", "")))
	var rule := PanelParts.text(String(dsc["text"]))
	rule.name = "RuleText"
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rule.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(rule)
	buy_button = shop_buy_button(int(it.get("cost", 0)), why)
	column.add_child(buy_button)


## `.btn-secondary.s.buy`: "Buy · N Shards", or disabled saying why ("Need N Shards", "Bought").
static func shop_buy_button(cost: int, why: String) -> Button:
	var b := UI3.button(TranslationServer.translate("Buy · %d Shards") % cost, &"secondary", &"S")
	b.name = "BuyButton"
	b.size_flags_horizontal = Control.SIZE_FILL
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
	if why != "":
		UI3.set_disabled_reason(b, why)
	return b


## `.tag` with the axis glyph and word (Stat, Dice faces ...).
func _category_chip(axis: String) -> PanelContainer:
	var box := UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(UI3Theme.space("8"), UI3Theme.space("4"), UI3Theme.space("12"), UI3Theme.space("4")))
	var p := PanelParts.panel(box, "CategoryChip")
	p.custom_minimum_size.y = UI3Theme.size_of("tag_h")
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("4"))
	p.add_child(h)
	h.add_child(PanelParts.icon_rect(UI3.icon(String(Parts.AXIS_ICON.get(axis, "face_buff"))), UI3Theme.size_of("icon_s")))
	var w := PanelParts.text(TranslationServer.translate(String(CorePanel.AXIS_NAME.get(axis, "Stat"))), "text_key", "text", true)
	w.name = "Word"
	w.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(w)
	return p
