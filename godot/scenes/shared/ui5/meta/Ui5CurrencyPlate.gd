class_name Ui5CurrencyPlate
extends RefCounted
## UI-05 CurrencyPlate (components-land--sheet): pill plate, three cells CurrencyShard / CurrencyStone / CurrencyGem
## (icon_m icon + Rowdies text_title amount, gap 8; cells gap 24) and an optional trailing control (the settings button).
## `values` = {shard, stone, gem} ints from the game (never literals here); an empty dict = loading, "···" in every cell.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const CELLS := [["CurrencyShard", "cur_shard", "shard"], ["CurrencyStone", "cur_stone", "stone"], ["CurrencyGem", "cur_gem", "gem"]]


static func make(values: Dictionary = {}, trailing: Control = null) -> PanelContainer:
	var pad := UI3Theme.space("12")
	var box := UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("pill"), UI3Theme.stroke("rim"),
		UI3Theme.color("plate_rim"), Vector4(UI3Theme.space("16"), pad, pad, pad), PanelParts.lip(UI3Theme.color("plate_ink")))
	var plate := PanelParts.panel(box, "CurrencyPlate")
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", UI3Theme.space("24"))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	plate.add_child(row)
	for c in CELLS:
		var cell := HBoxContainer.new()
		cell.name = c[0]
		cell.add_theme_constant_override("separation", UI3Theme.space("8"))
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_child(PanelParts.icon_rect(UI3.currency_icon(c[1], UI3Theme.size_of("icon_m")), UI3Theme.size_of("icon_m")))
		var v := PanelParts.text("···" if values.is_empty() else UI3.fmt(int(values.get(c[2], 0))), "text_title", "text", true)
		v.name = "Value"
		v.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cell.add_child(v)
		row.add_child(cell)
	if trailing != null:
		row.add_child(trailing)
	return plate


## Updates the three amounts in place (same keys as make).
static func set_values(plate: PanelContainer, values: Dictionary) -> void:
	for c in CELLS:
		var v := plate.find_child(c[0], true, false)
		if v != null:
			(v.get_node("Value") as Label).text = "···" if values.is_empty() else UI3.fmt(int(values.get(c[2], 0)))
