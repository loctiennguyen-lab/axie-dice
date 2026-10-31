extends RefCounted
## UI-05 b23 lane R4: the combo band (round-2 ui05-run-screens.html, 47-core-offer--combo-banner). Build with
## ComboBand.build(parent, tier, name, mutation). Root is a GachaFx named "ComboBanner" (so a click / Space dismisses it
## and `finished` fires) holding Scrim, Band(ComboTag, ComboName, MutationBox) and ContinueHint. No timer: click to continue.

const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")


static func build(parent: Node, tier: String, combo_name: String, house: String, with_mutation: bool) -> GachaFx:
	var full := tier == "full"
	var root := GachaFx.new()
	root.name = "ComboBanner"
	root.z_index = 50
	root.theme = UI3Theme.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = Color(UI3Theme.color("bg"), 0.55)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)
	var py := UI3Theme.space("24")
	var bs := UI3Theme.flat(UI3Theme.color("plate"), 0, 0, Color.TRANSPARENT, Vector4(0, py, 0, py))
	bs.border_width_top = UI3Theme.stroke("rim")
	bs.border_width_bottom = UI3Theme.stroke("rim")
	bs.border_color = UI3Theme.color("plate_rim")
	var band := PanelParts.panel(bs, "Band")
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.anchor_left = 0.0
	band.anchor_right = 1.0
	band.anchor_top = 0.5
	band.anchor_bottom = 0.5
	band.offset_left = 0
	band.offset_right = 0
	band.grow_vertical = Control.GROW_DIRECTION_BOTH
	band.custom_minimum_size.y = UI3Theme.size_of("combo_band_h")
	root.add_child(band)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", UI3Theme.space("12"))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(v)
	v.add_child(_tag(full))
	var nm := PanelParts.text(combo_name, "text_hero", "text", true)
	nm.name = "ComboName"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_color_override("font_shadow_color", UI3Theme.color("plate_ink"))
	nm.add_theme_constant_override("shadow_offset_y", UI3Theme.space("4"))
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nm)
	if with_mutation:
		var mb := _mutation(house, full)
		mb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(mb)
	var hint := PanelParts.text(TranslationServer.translate("Click to continue"), "text_body", "text_muted")
	hint.name = "ContinueHint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(hint)   # inside the band: the run map's own key hint sits at the screen bottom-right
	parent.add_child(root)
	root.set_meta("tier", tier)
	UI3Gacha.play_sfx(root, "full" if full else "pair")
	if UI3Gacha.is_instant():
		return root
	root.running = true
	if not UI3Motion.reduced():
		band.pivot_offset = Vector2(band.size.x / 2.0, 0)
		band.modulate.a = 0.0
		root.create_tween().tween_property(band, "modulate:a", 1.0, 0.18)
	return root


static func _tag(full: bool) -> PanelContainer:
	var ink := UI3Theme.color("text_ink")
	var box := UI3Theme.flat(UI3Theme.color("combo_full" if full else "combo_pair"), UI3Theme.radius("m"),
		UI3Theme.stroke("btn") if full else 0, ink, Vector4(UI3Theme.space("8"), UI3Theme.space("8"), UI3Theme.space("12"), UI3Theme.space("8")))
	var p := PanelParts.panel(box, "ComboTag")
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("8"))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(h)
	var moons := HBoxContainer.new()
	moons.name = "Moons"
	moons.add_theme_constant_override("separation", UI3Theme.stroke("hairline"))
	moons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in (3 if full else 2):
		moons.add_child(PanelParts.icon_rect(UI3.icon("ui_mooncard"), UI3Theme.space("24"), "Moon"), true)
	h.add_child(moons)
	var kb := PanelParts.panel(UI3Theme.flat(ink, UI3Theme.radius("pill"), 0, Color.TRANSPARENT,
		Vector4(UI3Theme.space("8"), 0, UI3Theme.space("8"), 0)), "Kind")
	kb.custom_minimum_size.y = UI3Theme.size_of("keycap_h")
	kb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var kl := PanelParts.text(TranslationServer.translate("FULL") if full else TranslationServer.translate("PAIR"), "text_key", "text", true)
	kl.name = "ComboWord"
	kl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kb.add_child(kl)
	h.add_child(kb)
	return p


static func _mutation(house: String, full: bool) -> PanelContainer:
	var m := AnchorAdapter.mutation_of(house)
	var col := AnchorAdapter.house_color(house)
	var box := UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("l"), 2, col,
		Vector4(UI3Theme.space("24"), UI3Theme.space("12"), UI3Theme.space("24"), UI3Theme.space("12")))
	var p := PanelParts.panel(box, "MutationBox")
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := VBoxContainer.new()
	s.name = "MutationStrip"
	s.alignment = BoxContainer.ALIGNMENT_CENTER
	s.add_theme_constant_override("separation", UI3Theme.space("4"))
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(s)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic := PanelParts.icon_rect(UI3.icon(AnchorAdapter.house_icon(house)), UI3Theme.size_of("icon_m"), "HouseGlyph")
	row.add_child(ic)
	var tag := PanelParts.text(TranslationServer.translate("MUTATION · LEVEL 2") if full else TranslationServer.translate("MUTATION"), "text_body", "text", true)
	tag.name = "MutationTag"
	tag.add_theme_color_override("font_color", col)
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(tag)
	s.add_child(row)
	var mn := PanelParts.text(String(m["name"]), "text_title", "text", true)
	mn.name = "MutationName"
	mn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_child(mn)
	var rule_txt := String(m["rule2"]) if full and String(m["rule2"]) != "" else String(m["rule"])
	var rl := PanelParts.text(rule_txt, "text_body", "text_muted")
	rl.name = "MutationRule"
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font: Font = UI3Theme.get_theme().get_font("font", "Label")
	var tw := font.get_string_size(rule_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, UI3Theme.size_of("text_body")).x
	rl.custom_minimum_size.x = minf(ceilf(tw) + UI3Theme.space("8"), parent_width() * 900.0 / 1920.0)
	s.add_child(rl)
	return p


static func parent_width() -> float:
	var ml := Engine.get_main_loop() as SceneTree
	return ml.root.get_visible_rect().size.x if ml != null else 1920.0
