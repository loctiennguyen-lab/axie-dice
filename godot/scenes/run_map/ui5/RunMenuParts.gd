extends RefCounted
## UI-05 b23 lane R6: small builders for the in-run menu (round-2 ui05-run-screens.html, frames menu--*).
## Every number is a token (UI3Theme); nothing here is added to UI3.gd. Use via
## const Parts := preload("res://scenes/run_map/ui5/RunMenuParts.gd")

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const HudStyle := preload("res://scenes/shared/ui5/HudStyle.gd")

const TIER_NAME := ["Moss", "Amber", "Crystal"]
const TIER_TOKEN := ["tier_moss", "tier_amber", "tier_crystal"]
const AXIS_ICON := {"stat": "face_buff", "dice": "face_dmg", "pos": "face_summon", "mana": "face_mana",
	"quest": "node_treasure", "rule": "face_debuff", "run_rule": "ui_settings"}


## `.menu-row`: a 64 high raised plate row, label left. `active` = the 3 px selected ring (this row's panel is showing).
static func row_button(text: String, node_name: String, active := false) -> Button:
	var b := UI3.button(text, &"secondary", &"M")
	b.name = node_name
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = UI3Theme.size_of("menu_row_h")
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_title"))
	style_row(b, active)
	return b


static func style_row(b: Button, active: bool) -> void:
	var pad := Vector4(UI3Theme.space("20"), 0, UI3Theme.space("20"), 0)
	var ring := UI3Theme.stroke("focus")   # 3 px
	var raised := UI3Theme.color("plate_raised")
	var normal := UI3Theme.flat(raised, UI3Theme.radius("m"), ring if active else 0,
		UI3Theme.color("selected"), pad)
	var hover := UI3Theme.flat(UI3Theme.color("btn_secondary_hover"), UI3Theme.radius("m"), ring if active else 0,
		UI3Theme.color("selected"), pad)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("hover_pressed", hover)
	b.add_theme_stylebox_override("focus", UI3Theme.focus_style(UI3Theme.radius("m")))


## `.btn-danger`: danger fill, 3 px danger_rim bevel, danger_lip lip, Rowdies 24, text colour.
static func danger_button(text: String, node_name: String) -> Button:
	var b := UI3.button(text, &"danger", &"M")
	b.name = node_name
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_title"))
	var pad := Vector4(UI3Theme.space("24"), 0, UI3Theme.space("24"), 0)
	var lip := {"y": HudStyle.lip(), "color": UI3Theme.color("danger_lip")}
	var normal := UI3Theme.flat(UI3Theme.color("danger"), UI3Theme.radius("m"), UI3Theme.stroke("btn"),
		UI3Theme.color("danger_rim"), pad, lip)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = UI3Theme.color("danger").lightened(0.12)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("hover_pressed", hover)
	b.add_theme_stylebox_override("focus", UI3Theme.focus_style(UI3Theme.radius("m")))
	return b


## `.stat-row`: raised cell, label left (Rowdies body) and value right.
static func stat_row(label: String, value: String, node_name := "StatRow") -> PanelContainer:
	var p := PanelParts.panel(PanelParts.cell_box(UI3Theme.space("8"), UI3Theme.space("16"), "s"), node_name)
	p.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(h)
	var l := PanelParts.text(label, "text_body", "text", true)
	l.name = "Label"
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	var v := PanelParts.text(value, "text_body", "text", true)
	v.name = "Value"
	v.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(v)
	return p


## `.core-slot.l`: square (core_slot), tier border, first letter, axis glyph bottom-right.
static func core_slot(def, is_rule: bool) -> PanelContainer:
	var tier := clampi(int(def.rarity), 0, 2) if def != null else 0
	var border := UI3Theme.color("run_rule_border") if is_rule else UI3Theme.color(TIER_TOKEN[tier])
	var fill := UI3Theme.color("run_rule_bg") if is_rule else UI3Theme.color("chip")
	var px := UI3Theme.size_of("core_slot")
	var p := PanelParts.panel(UI3Theme.flat(fill, UI3Theme.radius("s"), 2, border), "CoreSlot")
	p.custom_minimum_size = Vector2(px, px)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := PanelParts.text(String(def.name).substr(0, 1).to_upper() if def != null else "?", "text_body", "text", true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	var ax := "run_rule" if is_rule else String(def.core_axis) if def != null else "stat"
	var ic := TextureRect.new()
	ic.name = "AxisIcon"
	ic.texture = UI3.icon(String(AXIS_ICON.get(ax, "face_buff")))
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.size = Vector2(14, 14)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ic.offset_left = -16
	ic.offset_top = -16
	ic.offset_right = -2
	ic.offset_bottom = -2
	p.add_child(ic)
	return p


## `.tag.tier-chip`: tier_bg pill, 2 px tier border, 1/2/3 fragment pips, tier word in tier colour.
static func tier_chip(tier: int) -> PanelContainer:
	var t := clampi(tier, 0, 2)
	var col := UI3Theme.color(TIER_TOKEN[t])
	var box := UI3Theme.flat(UI3Theme.color(TIER_TOKEN[t] + "_bg"), UI3Theme.radius("pill"), 2, col,
		Vector4(UI3Theme.space("8"), UI3Theme.space("4"), UI3Theme.space("12"), UI3Theme.space("4")))
	var p := PanelParts.panel(box, "TierChip")
	p.custom_minimum_size.y = UI3Theme.size_of("tag_h")
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("4"))
	p.add_child(h)
	for i in t + 1:
		var pip := TextureRect.new()
		pip.name = "Pip"
		pip.texture = UI3.icon("cur_fragment")
		pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pip.custom_minimum_size = Vector2(14, 14)
		pip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(pip)
	var w := PanelParts.text(TIER_NAME[t], "text_key", TIER_TOKEN[t], true)
	w.name = "Word"
	w.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(w)
	return p
