class_name Ui5WaitingPill
extends RefCounted
## UI-05 b1 lane A: WaitingPill "… Waiting for the server" (CSS .waiting-pill, 02-combat--waiting). dice_header_h
## high, pill, plate fill with a 3 px plate_ink lip, 0 12 padding, gap space_8: a Rowdies "…" then Work Sans body.
## Where it sits (centred in the DiceDock header row) is the dice dock's job (lane B); this is only the look.

const TEXT := "Waiting for the server"


static func make(text := TEXT) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "WaitingPill"
	p.theme = UI3Theme.get_theme()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("pill"), 0,
		Color.TRANSPARENT, Vector4(UI3Theme.space("12"), 0, UI3Theme.space("12"), 0),
		Ui5HudStyle.shadow_of("a_chip_lip")))
	p.custom_minimum_size = Vector2(0, UI3Theme.size_of("dice_header_h"))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	p.add_child(row)
	var dots := UI3.label("…", "LabelDisplay")
	dots.name = "Dots"
	var l := UI3.label(TranslationServer.translate(text), "")
	l.name = "Text"
	for x in [dots, l]:
		x.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		x.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(x)
	return p
