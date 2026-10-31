class_name Ui5StatusChip
extends RefCounted
## UI-05 b1 lane A: StatusChip above an Axie / enemy head (CSS .status-chip). status_chip_h high, pill, plate fill,
## 0 12 0 8 padding, a 3 px plate_ink lip, icon_m glyph + Rowdies body count in cream (the icon carries the meaning,
## never colour alone). Built by StatusHeads for every status that has an icon.


static func make(tex: Texture2D, count: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "StatusChip"
	p.theme = UI3Theme.get_theme()
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("pill"), 0,
		Color.TRANSPARENT, Vector4(UI3Theme.space("8"), 0, UI3Theme.space("12"), 0),
		Ui5HudStyle.shadow_of("a_chip_lip")))
	p.custom_minimum_size = Vector2(0, UI3Theme.size_of("status_chip_h"))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI3Theme.space("4"))
	p.add_child(row)
	row.add_child(Ui5HudStyle.icon_rect(tex, UI3Theme.size_of("icon_m")))
	var n := UI3.label(str(count), "LabelDisplay")
	n.name = "Count"
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(n)
	return p
