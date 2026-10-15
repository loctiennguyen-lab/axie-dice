class_name ProfileView
extends Control
## R3 M12 Profile + M14 Cosmetics. Three tabs (Overview / Cosmetics / Titles) in the R3 wide shell.
## Overview: avatar + frame, name, title, sync chip, 6 stat tiles, last 10 runs (MetaState.run_log).
## Guest: banner with a Sign in action (opens the Account screen). Cosmetics: categories with counts,
## owned / missing tiles, preview + Equip / Unequip. Titles: C7 cards. Cosmetic only; state lives in
## MetaState (equip API checks ownership and saves through SaveStore). `no_scene_change` lets tests
## build it without leaving. Visual polish vs the frames is a later pass.

const TABS: Array[String] = ["Overview", "Cosmetics", "Titles"]
const CATS: Array[String] = [Cosmetics.SLOT_DIE, Cosmetics.SLOT_FRAME]
const CAT_NAMES := {"die": "Dice skins", "frame": "Avatar frames"}

var no_scene_change := false
## Injectable so tests can stub the account (default: the AccountService autoload).
var service: Node
var tab := 0
var cat := Cosmetics.SLOT_DIE
var selected := ""
var _shell: Dictionary
var _body: VBoxContainer
var _tab_btns: Array[Button] = []


func _ready() -> void:
	if service == null:
		service = AccountService
	_shell = R3Shell.build(self, "Profile", "", _on_back)
	var panel: Control = _shell["panel"]
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 14)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 24)
	pad.add_child(_body)
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(_shell["col"] as VBoxContainer).add_child(R3Shell.fit_in(pad, panel, R3Shell.BAND_H + 8.0))
	var hr: HBoxContainer = _shell["header_right"]
	for i in TABS.size():
		var b := R3Shell.button(TABS[i], 130, 44)
		b.name = "Tab_" + TABS[i]
		b.toggle_mode = true
		b.pressed.connect(set_tab.bind(i))
		hr.add_child(b)
		_tab_btns.append(b)
	if service.has_signal("changed"):
		service.changed.connect(refresh)
		tree_exiting.connect(func() -> void:
			if is_instance_valid(service) and service.changed.is_connected(refresh):
				service.changed.disconnect(refresh))
	refresh()


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		_on_back()
		get_viewport().set_input_as_handled()


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func set_tab(i: int) -> void:
	tab = clampi(i, 0, TABS.size() - 1)
	refresh()


func _signed_in() -> bool:
	return service.is_signed_in()


func _name() -> String:
	return String(service.display_name()) if _signed_in() else "Guest"


func refresh() -> void:
	if _body == null:
		return
	R3Shell.clear(_body)
	R3Shell.clear(_shell["banner_host"])
	for i in _tab_btns.size():
		_tab_btns[i].button_pressed = (i == tab)
	var land := "%s Land" % LandUpgradeScreen.TIER_NAMES[clampi(MetaState.land_tier, 1, LandUpgradeScreen.TIER_NAMES.size()) - 1]
	(_shell["sub"] as Label).text = ("Guest · local stats on this computer" if not _signed_in() else "%s · %s" % [_name(), land])
	if not _signed_in():
		R3Shell.banner(_shell["banner_host"], "Sign in to keep them.", "These stats live on this computer only.",
			[{"text": "Sign in", "primary": true, "cb": _open_account}])
	match tab:
		1:
			_cosmetics_tab()
		2:
			_titles_tab()
		_:
			_overview_tab()


func _open_account() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.open(&"account")


# ============================================================================ Overview

func _overview_tab() -> void:
	var head := HBoxContainer.new()
	head.name = "HeaderCard"
	head.add_theme_constant_override("separation", 18)
	head.add_child(make_avatar(96.0, service))
	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", 2)
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", 10)
	var nm := DangoTheme.display_label(_name(), 34, DangoTheme.INK)
	nm.name = "PlayerName"
	nrow.add_child(nm)
	if _signed_in() and bool(service.account.get("sky_mavis", false)):
		nrow.add_child(AccountUI.sky_mavis_badge())
	who.add_child(nrow)
	var tl := DangoTheme.display_label(
		("Title: %s" % TitleNames.display(MetaState.equipped_title)) if MetaState.equipped_title != "" else "No title",
		16, DangoTheme.INK_DISABLED)
	tl.name = "EquippedTitle"
	who.add_child(tl)
	head.add_child(who)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	head.add_child(_sync_chip())
	_body.add_child(head)

	var tiles := HBoxContainer.new()
	tiles.name = "Stats"
	tiles.add_theme_constant_override("separation", 12)
	for t in stat_tiles():
		tiles.add_child(_stat_tile(t))
	_body.add_child(tiles)

	_body.add_child(DangoTheme.display_label("Last %d runs" % MetaState.RUN_LOG_MAX, 22, DangoTheme.INK))
	var list := VBoxContainer.new()
	list.name = "RunList"
	list.add_theme_constant_override("separation", 0)
	_body.add_child(list)
	if MetaState.run_log.is_empty():
		var e := Label.new()
		e.name = "RunsEmpty"
		e.text = "No runs yet. Finish a run and it shows up here."
		e.add_theme_font_size_override("font_size", 16)
		e.add_theme_color_override("font_color", DangoTheme.INK_DISABLED)
		list.add_child(e)
	for i in MetaState.run_log.size():
		list.add_child(_run_row(MetaState.run_log[i] as Dictionary, i))


## [{k, v, s}] x 5 from saved data. Missing data reads "—", never a made-up number.
static func stat_tiles() -> Array[Dictionary]:
	var best := -1
	for k in MetaState.asc_wins:
		if int(MetaState.asc_wins[k]) > 0:
			best = maxi(best, int(k))
	var runs := MetaState.runs
	var ps: Dictionary = MetaState.profile_stats
	var ms_played := int(ps.get("ms_played", 0))
	return [
		{"k": "Runs", "v": str(runs), "s": "finished runs"},
		{"k": "Wins", "v": str(MetaState.wins), "s": "%d%%" % int(round(100.0 * MetaState.wins / runs)) if runs > 0 else "—"},
		{"k": "Best Ascension", "v": ("A%d" % best) if best >= 0 else "—", "s": "won"},
		{"k": "Pure wins", "v": str(int(ps.get("pure_wins", 0))), "s": "no Aid"},
		{"k": "Nhiệm vụ", "v": ("%d / %d" % [int(ps.get("ms_won", 0)), ms_played]) if ms_played > 0 else "—", "s": "won / played"},
	]


func _stat_tile(t: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.name = "Stat_" + String(t["k"]).replace(" ", "")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(0, 84)
	p.add_theme_stylebox_override("panel", R3Shell.surface(DangoTheme.Surface.CREAM_RAISED, 16, 3, Vector2(12, 8)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.add_child(R3Shell.label(String(t["k"]), 14, DangoTheme.INK_ON_CREAM_MUTED))
	var val := R3Shell.label(String(t["v"]), 28, DangoTheme.INK, true)
	val.name = "Value"
	v.add_child(val)
	v.add_child(R3Shell.label(String(t["s"]), 12, DangoTheme.INK_ON_CREAM_MUTED))
	p.add_child(v)
	return p


static func run_mode_text(e: Dictionary) -> String:
	if bool(e.get("mission", false)):
		return "Mission"
	var kind := String(e.get("kind", "normal"))
	var mode := "Full" if String(e.get("mode", "short")) == "full" else "Short"
	match kind:
		"ranked":
			return "Ranked · " + mode
		"daily":
			return "Daily"
	return "Normal · " + mode


func _run_row(e: Dictionary, i: int) -> Control:
	var p := PanelContainer.new()
	p.name = "Run_%d" % i
	p.custom_minimum_size = Vector2(0, 42)
	var sb := StyleBoxFlat.new()
	sb.bg_color = DangoTheme.CREAM_100 if i % 2 == 0 else DangoTheme.CREAM_200
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	p.add_child(h)
	var cells: Array = [[String(e.get("date", "")), 130], [run_mode_text(e), 180], ["A%d" % int(e.get("asc", 0)), 60]]
	for c in cells:
		var l := R3Shell.label(String(c[0]), 16)
		l.custom_minimum_size = Vector2(float(c[1]), 0)
		h.add_child(l)
	var won := bool(e.get("won", false))
	var res := R3Shell.label("Won" if won else "Lost", 16, DangoTheme.SUCCESS_ON_CREAM if won else DangoTheme.INK, true)
	res.name = "Result"
	res.custom_minimum_size = Vector2(120, 0)
	h.add_child(res)
	var aid := int(e.get("aid", 0))
	var at := "no Aid (mission)" if bool(e.get("mission", false)) else ("Aid %d" % aid if aid > 0 else "no Aid")
	var al := R3Shell.label(at, 14, DangoTheme.INK_ON_CREAM_MUTED)
	al.name = "AidMark"
	al.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(al)
	if aid == 0 and not bool(e.get("mission", false)):
		var pill := PanelContainer.new()
		pill.name = "PurePill"
		pill.add_theme_stylebox_override("panel", DangoTheme.solid_chip_style(DangoTheme.SUCCESS, 8, 2))
		pill.add_child(R3Shell.label("PURE", 12, DangoTheme.ink_on(DangoTheme.SUCCESS), true))
		h.add_child(pill)
	return p


func _sync_chip() -> Control:
	var p := PanelContainer.new()
	p.name = "SyncChip"
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var txt := "Guest · not saved to cloud"
	var fill := DangoTheme.CREAM_300
	if _signed_in():
		var line: Array = AccountUI.status_line(service)
		txt = String(line[0])
		fill = DangoTheme.SUCCESS if txt == "Saved" else DangoTheme.CREAM_200
	p.add_theme_stylebox_override("panel", DangoTheme.solid_chip_style(fill, 12, 2, Vector2(12, 4)))
	var l := R3Shell.label(("✓ " + txt) if txt == "Saved" else txt, 14, DangoTheme.ink_on(fill), true)
	l.name = "SyncText"
	p.add_child(l)
	return p


# ============================================================================ Cosmetics (M14)

## Every manifest id of a slot, in manifest order.
static func catalog(slot: String) -> Array[String]:
	var out: Array[String] = []
	var m: Dictionary = CosmeticArt.manifest().get("dice" if slot == Cosmetics.SLOT_DIE else "frames", {})
	for k in m:
		out.append(String(k))
	return out


static func equipped_for(slot: String) -> String:
	return MetaState.equipped_die_skin if slot == Cosmetics.SLOT_DIE else MetaState.equipped_frame


func _entry(id: String) -> Dictionary:
	var m: Dictionary = CosmeticArt.manifest().get("dice" if cat == Cosmetics.SLOT_DIE else "frames", {})
	return m.get(id, {})


func _cosmetics_tab() -> void:
	var owned := Cosmetics.owned_art(MetaState.cosmetics_owned, cat)
	var all := catalog(cat)
	if selected == "" or not all.has(selected):
		selected = equipped_for(cat) if equipped_for(cat) != "" else (owned[0] if not owned.is_empty() else (all[0] if not all.is_empty() else ""))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	_body.add_child(row)
	# categories with counts
	var cats := VBoxContainer.new()
	cats.name = "Categories"
	cats.custom_minimum_size = Vector2(230, 0)
	cats.add_theme_constant_override("separation", 8)
	for c in CATS:
		var n := Cosmetics.owned_art(MetaState.cosmetics_owned, c).size()
		var b := R3Shell.button("%s   %d / %d" % [CAT_NAMES[c], n, catalog(c).size()], 230, 52)
		b.name = "Cat_" + c
		b.toggle_mode = true
		b.button_pressed = (c == cat)
		b.pressed.connect(func() -> void:
			cat = c
			selected = ""
			refresh())
		cats.add_child(b)
	row.add_child(cats)
	# grid
	var gv := VBoxContainer.new()
	gv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gv.add_theme_constant_override("separation", 8)
	gv.add_child(DangoTheme.display_label(CAT_NAMES[cat], 24, DangoTheme.INK))
	gv.add_child(R3Shell.label("%d owned" % owned.size() if cat != Cosmetics.SLOT_DIE else "%d / %d owned · one dice skin at a time" % [owned.size(), all.size()], 14, DangoTheme.INK_ON_CREAM_MUTED))
	var grid := GridContainer.new()
	grid.name = "Grid_" + cat
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	gv.add_child(grid)
	for id in all:
		grid.add_child(_cos_tile(id, owned.has(id)))
	row.add_child(gv)
	row.add_child(_preview(owned))


func _cos_tile(id: String, have: bool) -> Control:
	var b := Button.new()
	b.name = "Tile_" + id
	b.toggle_mode = true
	b.button_pressed = (id == selected)
	b.custom_minimum_size = Vector2(138, 138)
	b.text = ""
	b.tooltip_text = String(_entry(id).get("name", id))
	DangoTheme.style_button(b, false, false, null, have)
	b.pressed.connect(func() -> void:
		selected = id
		refresh())
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var art := CosmeticArt.make_node(id, 80.0)
	if art != null:
		art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not have:
			art.modulate = Color(0, 0, 0, 0.45)   # named silhouette
		v.add_child(art)
	var l := R3Shell.label(String(_entry(id).get("name", id)), 12, DangoTheme.INK if have else DangoTheme.INK_DISABLED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	b.add_child(v)
	return b


func _preview(owned: Array[String]) -> Control:
	var p := PanelContainer.new()
	p.name = "Preview"
	p.custom_minimum_size = Vector2(380, 0)
	var e := _entry(selected)
	var tier := int(e.get("tier", 0))
	var mythic := tier == DangoTheme.RARITY_MYTHIC
	var fill: Color = DangoTheme.MYTHIC_NIGHT if mythic else DangoTheme.CREAM_100
	var ink: Color = DangoTheme.MYTHIC_INK if mythic else DangoTheme.INK
	var ink2: Color = DangoTheme.MYTHIC_INK_2 if mythic else DangoTheme.INK_ON_CREAM_MUTED
	p.add_theme_stylebox_override("panel", R3Shell.surface(DangoTheme.Surface.CREAM_RAISED, 20, 3, Vector2(16, 16), fill,
		DangoTheme.MYTHIC_EDGE if mythic else null))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var have := owned.has(selected)
	var nm := DangoTheme.display_label(String(e.get("name", "Default")) if selected != "" else "Default", 24, ink)
	nm.name = "PreviewName"
	v.add_child(nm)
	if selected != "":
		var chip := PanelContainer.new()
		chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var rc := DangoTheme.rarity_color(tier)
		chip.add_theme_stylebox_override("panel", DangoTheme.solid_chip_style(rc, 8, 2))
		chip.add_child(R3Shell.label(DangoTheme.RARITY_NAMES[clampi(tier, 0, 5)].to_upper(), 12, DangoTheme.ink_on(rc), true))
		v.add_child(chip)
		var sizes: Array = [104.0, 64.0, 36.0] if cat == Cosmetics.SLOT_DIE else [96.0, 40.0]
		var art_row := HBoxContainer.new()
		art_row.add_theme_constant_override("separation", 14)
		for px in sizes:
			var a := CosmeticArt.make_node(selected, px)
			if a != null:
				a.size_flags_vertical = Control.SIZE_SHRINK_END
				if not have:
					a.modulate = Color(0, 0, 0, 0.45)
				art_row.add_child(a)
		v.add_child(art_row)
		var src := R3Shell.label("Source: Echo Box, Store or Pass" if have else "Not owned yet", 14, ink2)
		v.add_child(src)
	else:
		v.add_child(R3Shell.label("Nothing equipped: the default plate is used.", 14, ink2))
	var on := selected != "" and equipped_for(cat) == selected
	var eq := R3Shell.button("Unequip" if on else "Equip", 0, 56, not on)
	eq.name = "Equip"
	eq.disabled = not have
	if not have:
		eq.text = "Nothing to equip" if owned.is_empty() else "Not owned yet"
	eq.pressed.connect(func() -> void:
		if on:
			MetaState.unequip_cosmetic(cat)
		else:
			MetaState.equip_cosmetic(selected)
		refresh())
	v.add_child(eq)
	if equipped_for(cat) != "" and not on:
		var d := R3Shell.button("Use default", 0, 44)
		d.name = "UseDefault"
		d.pressed.connect(func() -> void:
			MetaState.unequip_cosmetic(cat)
			refresh())
		v.add_child(d)
	return p


# ============================================================================ Titles

## C7 (R3 M12d): title cards, 3 per row. Owned titles can be equipped (one at a time); the Ascension
## titles you have not earned yet show as "Not yet". Names and goals come from ascension_titles.json.
func _titles_tab() -> void:
	_body.add_child(DangoTheme.display_label("Titles", 24, DangoTheme.INK))
	_body.add_child(R3Shell.label("Titles from Ascension goals. One title at a time.", 14, DangoTheme.INK_ON_CREAM_MUTED))
	var grid := GridContainer.new()
	grid.name = "Grid_titles"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(grid)
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
	sb.bg_color = DangoTheme.GOLD_SOFT if on else (DangoTheme.CREAM_RAISED if have else DangoTheme.CREAM_LOCKED)
	sb.border_color = DangoTheme.OUTLINE if on else (DangoTheme.LINE if have else DangoTheme.FUTURE)
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
## `svc` = the account service (is_signed_in / display_name); null falls back to the AccountService autoload.
static func make_avatar(total_px: float, svc: Node = null) -> Control:
	if svc == null:
		svc = AccountService
	var nm := "P"
	if svc.is_signed_in():
		nm = svc.display_name().left(1).to_upper()
	var av := PanelContainer.new()
	av.name = "Avatar"
	av.add_theme_stylebox_override("panel", DangoTheme.solid_chip_style(DangoTheme.GOLD, 20, 3))
	var ini := DangoTheme.display_label(nm, int(total_px * 0.3), DangoTheme.INK)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(ini)
	return AvatarFrame.wrap(av, total_px, MetaState.equipped_frame, total_px * 0.66)


func _button(text: String, w: float) -> Button:
	return R3Shell.button(text, w, 44)
