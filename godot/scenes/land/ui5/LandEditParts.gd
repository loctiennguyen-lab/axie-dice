extends RefCounted
## UI-05 b23 lane S2: Edit Land panel pieces (round-3 ui05-land-screens.html .edit-panel / .row / .tabs). Static builders only:
## LandEdit owns the state. Every size is a token (UI3Theme). Use through
## `const Parts := preload("res://scenes/land/ui5/LandEditParts.gd")`.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const TAB_NAMES := ["PlaceTab", "CraftTab", "RewardsTab"]


## `.row`: plate_raised, radius m, padding 12 12 12 16, min-h edit_row_h. `node_name` = DecorRow / CraftRow / RewardRow.
## `sub_rarity` = rarity word coloured by its token ("" = none), `sub` = the muted rest of the line.
static func row(node_name: String, title: String, sub_rarity: String, rarity_token: String, sub: String, btn: Button, selected := false) -> PanelContainer:
	var s12 := UI3Theme.space("12")
	var box := UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("m"), 3 if selected else 0,
		UI3Theme.color("selected"), Vector4(UI3Theme.space("16"), s12, s12, s12))
	var p := PanelParts.panel(box, node_name)
	p.custom_minimum_size.y = UI3Theme.size_of("edit_row_h")
	var h := HBoxContainer.new()
	h.name = "Row"
	h.add_theme_constant_override("separation", s12)
	p.add_child(h)
	var txt := VBoxContainer.new()
	txt.name = "Txt"
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	txt.add_theme_constant_override("separation", UI3Theme.space("4"))
	h.add_child(txt)
	var t := Ui5Text.label(title, "text_body", "text", true)
	t.name = "Name"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt.add_child(t)
	var line := HBoxContainer.new()
	line.name = "Sub"
	line.add_theme_constant_override("separation", 0)
	txt.add_child(line)
	if sub_rarity != "":
		var r := Ui5Text.label(sub_rarity, "text_body", rarity_token)
		r.name = "Rarity"
		line.add_child(r)
	var d := Ui5Text.label(sub, "text_body", "text_muted")
	d.name = "Detail"
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(d)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(btn)
	return p


## Tab bar named Tabs with PlaceTab / CraftTab / RewardsTab (Ui5TabBar's Tab0.. renamed to the frame's data-names).
static func tabs(selected: int, on_pick: Callable) -> Ui5TabBar:
	var tb := Ui5TabBar.new()
	tb.setup(["Place", "Craft", "Rewards"], selected)
	tb.name = "Tabs"
	for i in TAB_NAMES.size():
		tb.get_node("Tab%d" % i).name = TAB_NAMES[i]
	tb.tab_selected.connect(on_pick)
	return tb


## EmptyState (center-block): padding 32, centred body text.
static func empty_state(text: String) -> Control:
	var c := CenterContainer.new()
	c.name = "EmptyState"
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m := MarginContainer.new()
	for k in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + k, UI3Theme.space("32"))
	c.add_child(m)
	var l := Ui5Text.label(text, "text_body", "text")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = 320
	m.add_child(l)
	return c
