extends PanelContainer
## UI-05 BossIntroBand (boss-intro--default): full-width walnut band pinned 24 px from the top, rims top and bottom,
## the large lip. Centred column, gap 12, padding 24: BOSS tag, BossName (text_hero 56, hard 4 px ink drop),
## Facts (chips), Rhythm (Prep / Strike / Hollow, the current step filled cream).
## d = {name, tag_word, facts: [{text, color, icon(Texture2D|null), sub(muted, optional)}], rhythm: ["Prep", ...],
##      rhythm_now: int (-1 = none)}. Every string comes from the caller (game data), none from the mockup.

const PanelParts := preload("res://scenes/combat/ui5/PanelParts.gd")

var name_label: Label
var facts_row: HBoxContainer
var rhythm_row: HBoxContainer


func setup(d: Dictionary) -> void:
	theme = UI3Theme.get_theme()
	name = "BossIntroBand"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rim := UI3Theme.stroke("rim")
	var pad := UI3Theme.space("24")
	var box := UI3Theme.flat(UI3Theme.color("plate"), 0, 0, Color.TRANSPARENT, Vector4(0, pad, 0, pad),
		PanelParts.lip(UI3Theme.color("plate_ink"), true))
	box.border_width_top = rim
	box.border_width_bottom = rim
	box.border_color = UI3Theme.color("plate_rim")
	add_theme_stylebox_override("panel", box)
	var col := VBoxContainer.new()
	col.name = "Column"
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", UI3Theme.space("12"))
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)

	col.add_child(_center(_boss_tag(String(d.get("tag_word", "BOSS")))))
	name_label = PanelParts.text(String(d.get("name", "")), "text_hero", "text", true)
	name_label.name = "BossName"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_shadow_color", UI3Theme.color("plate_ink"))
	name_label.add_theme_constant_override("shadow_offset_x", 0)
	name_label.add_theme_constant_override("shadow_offset_y", UI3Theme.space("4"))
	name_label.add_theme_constant_override("shadow_outline_size", 0)
	col.add_child(name_label)

	facts_row = HBoxContainer.new()
	facts_row.name = "Facts"
	facts_row.alignment = BoxContainer.ALIGNMENT_CENTER
	facts_row.add_theme_constant_override("separation", UI3Theme.space("12"))
	facts_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(facts_row)
	var facts: Array = d.get("facts", [])
	for i in facts.size():
		var f: Dictionary = facts[i]
		var chip := PanelParts.fact_chip(String(f.get("text", "")), String(f.get("color", "text")), f.get("icon", null),
			String(f.get("node", "Fact%d" % i)))
		if String(f.get("sub", "")) != "":
			var sub := PanelParts.text(String(f["sub"]), "text_body", "text_muted")
			sub.name = "Sub"
			sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			chip.get_node("Row").add_child(sub)
		facts_row.add_child(chip)
	facts_row.visible = not facts.is_empty()

	rhythm_row = HBoxContainer.new()
	rhythm_row.name = "Rhythm"
	rhythm_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rhythm_row.add_theme_constant_override("separation", UI3Theme.space("8"))
	rhythm_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(rhythm_row)
	var steps: Array = d.get("rhythm", [])
	var now := int(d.get("rhythm_now", -1))
	for i in steps.size():
		rhythm_row.add_child(_rhythm_step(String(steps[i]), i == now, i))
	rhythm_row.visible = not steps.is_empty()


## `.enemy-tag.tag-boss` at chip size: solid tag_boss_bg pill, boss glyph + the word in cream, Rowdies 18.
func _boss_tag(word: String) -> PanelContainer:
	var pad := UI3Theme.space("16")
	var tag := PanelParts.panel(UI3Theme.flat(UI3Theme.color("tag_boss_bg"), UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(pad, 0, pad, 0)), "BossTag")
	tag.custom_minimum_size = Vector2(0, UI3Theme.size_of("chip_h"))
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("4"))
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_child(row)
	row.add_child(PanelParts.icon_rect(UI3.icon("node_boss"), UI3Theme.size_of("icon_m")))
	var l := PanelParts.text(word, "text_body", "text", true)
	l.name = "Word"
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	return tag


## `.rhythm-step`: btn_s high, radius m, plate_raised; the current step is filled cream with ink text.
func _rhythm_step(word: String, now: bool, i: int) -> PanelContainer:
	var pad := UI3Theme.space("16")
	var step := PanelParts.panel(UI3Theme.flat(UI3Theme.color("text") if now else UI3Theme.color("plate_raised"),
		UI3Theme.radius("m"), 0, Color.TRANSPARENT, Vector4(pad, 0, pad, 0)), "Step%d" % i)
	step.custom_minimum_size = Vector2(0, UI3Theme.size_of("btn_s"))
	step.mouse_filter = Control.MOUSE_FILTER_IGNORE
	step.set_meta("now", now)
	var l := PanelParts.text(word, "text_body", "text_ink" if now else "text", true)
	l.name = "Text"
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	step.add_child(l)
	return step


func _center(c: Control) -> Control:
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return c
