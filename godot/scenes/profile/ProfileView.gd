class_name ProfileView
extends Control
## B12 Profile: avatar with the equipped frame, and an "Appearance" section listing the dice skins
## and frames the player owns, with Equip. Cosmetic only; state lives in MetaState (equip API checks
## ownership and saves through SaveStore). `no_scene_change` lets tests build it without leaving.

var no_scene_change := false
var _host: VBoxContainer


func _ready() -> void:
	DangoScreen.build(self, MockupAssets.tex("assets/bg/rocky.jpg"), DangoTheme.Scrim.DEFAULT, false)
	var back := _button("← Back  Esc", 150)
	back.name = "Back"
	back.position = Vector2(40, 40)
	back.pressed.connect(_on_back)
	add_child(back)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.CREAM
	sb.set_corner_radius_all(28)
	sb.set_border_width_all(4)
	sb.border_color = DangoTheme.LINE
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(820, 600)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_host = VBoxContainer.new()
	_host.add_theme_constant_override("separation", 12)
	_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_host)
	refresh()


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		_on_back()
		get_viewport().set_input_as_handled()


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func refresh() -> void:
	for c in _host.get_children():
		_host.remove_child(c)
		c.queue_free()
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	head.add_child(make_avatar(64.0 * 1.5))
	var nm := "Player"
	if AccountService.is_signed_in():
		nm = AccountService.display_name()
	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", -2)
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	who.add_child(DangoTheme.display_label(nm, 30, DangoTheme.INK))
	if MetaState.equipped_title != "":
		var tl := DangoTheme.display_label(TitleNames.display(MetaState.equipped_title), 16, DangoTheme.INK_DISABLED)
		tl.name = "EquippedTitle"
		who.add_child(tl)
	head.add_child(who)
	_host.add_child(head)
	_titles_section()
	_host.add_child(DangoTheme.display_label("Appearance", 24, DangoTheme.INK))
	_section("Dice skins", Cosmetics.SLOT_DIE, MetaState.equipped_die_skin)
	_section("Avatar frames", Cosmetics.SLOT_FRAME, MetaState.equipped_frame)


## C7 (R3 M12d): title cards, 3 per row. Owned titles can be equipped (one at a time); the Ascension
## titles you have not earned yet show as "Not yet". Names and goals come from ascension_titles.json.
func _titles_section() -> void:
	_host.add_child(DangoTheme.display_label("Titles", 18, DangoTheme.INK))
	var grid := GridContainer.new()
	grid.name = "Grid_titles"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_host.add_child(grid)
	var owned := TitleNames.owned(MetaState.cosmetics_owned)
	var goals := {}
	for t in TitleNames.ascension_titles():
		goals[String(t["id"])] = "Win a run at A%d" % int(t["asc"])
	grid.add_child(_title_card("", "No title", "", MetaState.equipped_title == "", true))
	for id in owned:
		grid.add_child(_title_card(id, TitleNames.display(id), String(goals.get(id, "")), MetaState.equipped_title == id, true))
	for t in TitleNames.ascension_titles():
		if not owned.has(String(t["id"])):
			grid.add_child(_title_card(String(t["id"]), String(t["name"]), String(goals[t["id"]]), false, false))


func _title_card(id: String, label: String, goal: String, on: bool, have: bool) -> Control:
	var card := PanelContainer.new()
	card.name = "Title_" + (id.replace(":", "_") if id != "" else "none")
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("FFE3A6") if on else (Color("FFF8EA") if have else Color("F3E9D6"))
	sb.border_color = DangoTheme.OUTLINE if on else (Color("8A3E22") if have else Color("B89A74"))
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	card.add_child(col)
	var nm := DangoTheme.display_label(label, 20, DangoTheme.INK if have else DangoTheme.INK_DISABLED)
	nm.name = "Name"
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(nm)
	if goal != "":
		var g := Label.new()
		g.text = goal
		g.add_theme_font_size_override("font_size", 13)
		g.add_theme_color_override("font_color", DangoTheme.INK_DISABLED)
		col.add_child(g)
	if have:
		var b := _button("Equipped" if on else ("Equip" if id != "" else "Use default"), 0)
		b.name = "Equip"
		b.disabled = on
		b.pressed.connect(func() -> void:
			MetaState.equip_title(id)
			refresh())
		col.add_child(b)
	else:
		var st := DangoTheme.display_label("Not yet", 14, DangoTheme.INK_DISABLED)
		st.name = "Status"
		col.add_child(st)
	return card


## Initial-letter avatar wearing the equipped frame (same look as the Land chip).
static func make_avatar(total_px: float) -> Control:
	var nm := "P"
	if AccountService.is_signed_in():
		nm = AccountService.display_name().left(1).to_upper()
	var av := PanelContainer.new()
	av.name = "Avatar"
	av.add_theme_stylebox_override("panel", DangoTheme.solid_chip_style(Color("FFC445"), 20, 3))
	var ini := DangoTheme.display_label(nm, int(total_px * 0.3), DangoTheme.INK)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(ini)
	return AvatarFrame.wrap(av, total_px, MetaState.equipped_frame, total_px * 0.66)


func _section(title: String, slot: String, equipped: String) -> void:
	_host.add_child(DangoTheme.display_label(title, 18, DangoTheme.INK))
	var grid := HFlowContainer.new()
	grid.name = "Grid_" + slot
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_host.add_child(grid)
	grid.add_child(_tile("", "None", equipped == "", slot))
	var m: Dictionary = CosmeticArt.manifest().get("dice" if slot == Cosmetics.SLOT_DIE else "frames", {})
	var owned := Cosmetics.owned_art(MetaState.cosmetics_owned, slot)
	for id in owned:
		grid.add_child(_tile(id, String((m[id] as Dictionary).get("name", id)), equipped == id, slot))
	if owned.is_empty():
		var l := Label.new()
		l.text = "Nothing owned yet. Echo Box, Store and Pass give these."
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_color_override("font_color", DangoTheme.INK_DISABLED)
		grid.add_child(l)


func _tile(id: String, label: String, on: bool, slot: String) -> Control:
	var box := VBoxContainer.new()
	box.name = "Tile_" + (id if id != "" else "none_" + slot)
	box.custom_minimum_size = Vector2(120, 0)
	box.add_theme_constant_override("separation", 4)
	var art: Control = CosmeticArt.make_node(id, 88.0) if id != "" else null
	if art == null:
		art = Control.new()
		art.custom_minimum_size = Vector2(88, 88)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(art)
	var l := Label.new()
	l.text = label
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", DangoTheme.INK)
	box.add_child(l)
	var b := _button("Equipped" if on else ("Equip" if id != "" else "Use default"), 0)
	b.name = "Equip"
	b.disabled = on
	b.pressed.connect(func() -> void:
		if id == "":
			MetaState.unequip_cosmetic(slot)
		else:
			MetaState.equip_cosmetic(id)
		refresh())
	box.add_child(b)
	return box


func _button(text: String, w: float) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, 44)
	b.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	b.add_theme_font_size_override("font_size", 16)
	DangoTheme.style_button(b, false)
	return b
