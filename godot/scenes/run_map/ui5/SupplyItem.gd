extends PanelContainer
## UI-05 b23 lane R5a: SupplyItem (shop--*): shop_card_w plate, padding 16, radius l. Tree: SupplyItem > Column >
## [Row(Icon, Text(ItemName, ItemDesc)), BuyButton]. Name, text and price come from the offer dict.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const CoreCard := preload("res://scenes/run_map/ui5/ShopCoreCard.gd")
const ICONS := {"heal": "face_heal", "reroll": "ui_reroll", "core": "ui_mooncard"}

var buy_button: Button
var index := -1


func setup(it: Dictionary, shop_index: int, why: String) -> void:
	index = shop_index
	name = "SupplyItem"
	theme = UI3Theme.get_theme()
	set_meta("shop_index", shop_index)
	var pad := UI3Theme.space("16")
	add_theme_stylebox_override("panel", PanelParts.plate_box("l", pad))
	custom_minimum_size.x = UI3Theme.size_of("shop_card_w")
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var col := VBoxContainer.new()
	col.name = "Column"
	col.add_theme_constant_override("separation", UI3Theme.space("8"))
	add_child(col)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", UI3Theme.space("12"))
	col.add_child(row)
	row.add_child(PanelParts.icon_rect(UI3.icon(String(ICONS.get(String(it.get("kind", "")), "face_buff"))), UI3Theme.size_of("choice_icon")))
	var tx := VBoxContainer.new()
	tx.name = "Text"
	tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tx.add_theme_constant_override("separation", 2)
	row.add_child(tx)
	var nm := PanelParts.text(String(it.get("title", "")), "text_title", "text", true)
	nm.name = "ItemName"
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tx.add_child(nm)
	var ds := PanelParts.text(String(UI3.describe(String(it.get("desc", "")))["text"]))
	ds.name = "ItemDesc"
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tx.add_child(ds)
	buy_button = CoreCard.shop_buy_button(int(it.get("cost", 0)), why)
	col.add_child(buy_button)
