class_name ProfileView
extends Control
## Profile + cosmetics + titles on the UI-03 meta shell (screen 24, round 2). Tabs in the header
## (Overview / Cosmetics / Titles), content column + 440 detail plate. Overview: identity in the detail
## plate, 5 stat tiles, last 10 runs (MetaState.run_log). Guest: banner with Sign in. Cosmetics: categories
## with counts, tiles (Equipped / Owned / Locked), preview 392 + Equip / Unequip. Titles: A5 / A10 tiles,
## detail Equip. Cosmetic only; state lives in MetaState (equip API checks ownership, saves via SaveStore).
## `no_scene_change` lets tests build it without leaving.

const TABS: Array[String] = ["Overview", "Cosmetics", "Titles"]
const CATS: Array[String] = [Cosmetics.SLOT_DIE, Cosmetics.SLOT_FRAME]
const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]
const CAT_NAMES := {"die": "Dice skins", "frame": "Avatar frames"}

var no_scene_change := false
## Injectable so tests can stub the account (default: the AccountService autoload).
var service: Node
var tab := 0
var cat := Cosmetics.SLOT_DIE
var selected := ""
## Titles tab selection ("" = No title). `_title_sel_set` false = follow the equipped title.
var title_sel := ""
var _title_sel_set := false
var _shell: Dictionary
var _body: HBoxContainer
var _tab_btns: Array[Button] = []


func _ready() -> void:
	if service == null:
		service = AccountService
	_shell = UI3Meta.build(self, "Profile", "", _on_back)
	_body = HBoxContainer.new()
	_body.name = "Body"
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", UI3Meta.GAP)
	(_shell["col"] as VBoxContainer).add_child(_body)
	var hr: HBoxContainer = _shell["header_right"]
	for i in TABS.size():
		var b := UI3Meta.tab(TABS[i], i == tab)
		b.name = "Tab_" + TABS[i]
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
	if UI3Meta.esc_back(ev, _shell, _on_back):
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
	UI3Meta.clear(_body)
	UI3Meta.clear(_shell["banner_host"])
	for i in _tab_btns.size():
		_tab_btns[i].button_pressed = (i == tab)
	var land := "%s Land" % LandUpgradeScreen.TIER_NAMES[clampi(MetaState.land_tier, 1, LandUpgradeScreen.TIER_NAMES.size()) - 1]
	(_shell["sub"] as Label).text = ("Guest · local stats on this computer" if not _signed_in() else "%s · %s" % [_name(), land])
	if not _signed_in():
		UI3Meta.banner(_shell["banner_host"], "Sign in to keep them.", "These stats live on this computer only.",
			[{"name": "SignIn", "text": "Sign in", "primary": true, "cb": _open_account}])
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


## Content column (expands) + detail plate (440) added to the body; returns [left VBox, detail plate].
func _frame() -> Array:
	var left := VBoxContainer.new()
	left.name = "Content"
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", UI3Meta.GAP)
	_body.add_child(left)
	var d := UI3.plate(&"plate")
	d.name = "DetailPlate"
	d.custom_minimum_size = Vector2(440, 0)
	_body.add_child(d)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	d.add_child(v)
	return [left, v]


func _info_row(k: String, val: String, nm: String) -> Control:
	var r := UI3.plate(&"row")
	r.custom_minimum_size = Vector2(0, 48)
	var h := HBoxContainer.new()
	r.add_child(h)
	var a := UI3.label(k, "LabelMuted")
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a)
	var b := UI3.label(val, "LabelTitle")
	b.name = nm
	h.add_child(b)
	return r


## Selectable tile (a toggle Button so Enter / click / focus all work): content stacked inside.
func _tile(nm: String, on: bool, art: Control, label: String, badge: String, dim: bool) -> Button:
	var b := UI3.button("", &"secondary", &"M")
	b.name = nm
	b.toggle_mode = true
	b.button_pressed = on
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 120)
	b.clip_contents = true
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	if art != null:
		art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if dim:
			art.modulate = Color(1, 1, 1, 0.4)   # locked art at 40%
		v.add_child(art)
	var l := UI3.label(label, "LabelTitle")
	l.name = "Name"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	var bl := UI3.label(badge)
	bl.name = "Badge"
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(bl)
	b.add_child(v)
	return b


# ============================================================================ Overview

func _overview_tab() -> void:
	var fr := _frame()
	var left: VBoxContainer = fr[0]
	var d: VBoxContainer = fr[1]
	(d.get_parent() as Control).size_flags_vertical = Control.SIZE_SHRINK_BEGIN   # identity card hugs its content
	# identity in the detail plate
	var hc := CenterContainer.new()
	hc.name = "HeaderCard"
	hc.add_child(make_avatar(128.0, service))
	d.add_child(hc)
	var nrow := HBoxContainer.new()
	nrow.alignment = BoxContainer.ALIGNMENT_CENTER
	nrow.add_theme_constant_override("separation", UI3Theme.space("8"))
	var nm := UI3.label(_name(), "LabelScreenTitle")
	nm.name = "PlayerName"
	nrow.add_child(nm)
	if _signed_in() and bool(service.account.get("sky_mavis", false)):
		nrow.add_child(UI3Meta.tag("Sky Mavis"))
	d.add_child(nrow)
	var tl := UI3.label(
		("Title: %s" % TitleNames.display(MetaState.equipped_title)) if MetaState.equipped_title != "" else "No title",
		"LabelMuted")
	tl.name = "EquippedTitle"
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.add_child(tl)
	d.add_child(_sync_chip())

	var tiles := HBoxContainer.new()
	tiles.name = "Stats"
	tiles.add_theme_constant_override("separation", UI3Theme.space("16"))
	for t in stat_tiles():
		tiles.add_child(_stat_tile(t))
	left.add_child(tiles)
	left.add_child(UI3.label("Last %d runs" % MetaState.RUN_LOG_MAX, "LabelTitle"))
	var list := VBoxContainer.new()
	list.name = "RunList"
	list.add_theme_constant_override("separation", UI3Theme.space("8"))
	left.add_child(UI3Meta.scroll(list))
	if MetaState.run_log.is_empty():
		var e := UI3.label("No runs yet. Finish a run and it shows up here.", "LabelMuted")
		e.name = "RunsEmpty"
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
		{"k": "Missions", "v": ("%d / %d" % [int(ps.get("ms_won", 0)), ms_played]) if ms_played > 0 else "—", "s": "won / played"},
	]


func _stat_tile(t: Dictionary) -> Control:
	var p := UI3.plate(&"card")
	p.name = "Stat_" + String(t["k"]).replace(" ", "")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var k := UI3.label(String(t["k"]), "LabelMuted")
	k.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(k)
	var val := UI3.label(String(t["v"]), "LabelScreenTitle")
	val.name = "Value"
	v.add_child(val)
	v.add_child(UI3.label(String(t["s"]), "LabelMuted"))
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
	var p := UI3.plate(&"row")
	p.name = "Run_%d" % i
	p.custom_minimum_size = Vector2(0, 56)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(h)
	var cells: Array = [[String(e.get("date", "")), 130], [run_mode_text(e), 200], ["A%d" % int(e.get("asc", 0)), 60]]
	for c in cells:
		var l := UI3.label(String(c[0]))
		l.custom_minimum_size = Vector2(float(c[1]), 0)
		h.add_child(l)
	var won := bool(e.get("won", false))
	var res := UI3.label("Won" if won else "Lost", "LabelTitle")
	res.name = "Result"
	res.custom_minimum_size = Vector2(100, 0)
	h.add_child(res)
	var aid := int(e.get("aid", 0))
	var at := "no Aid (mission)" if bool(e.get("mission", false)) else ("Aid %d" % aid if aid > 0 else "no Aid")
	var al := UI3.label(at, "LabelMuted")
	al.name = "AidMark"
	al.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(al)
	if aid == 0 and not bool(e.get("mission", false)):
		var pill := UI3Meta.tag("Pure")
		pill.name = "PurePill"
		h.add_child(pill)
	return p


func _sync_chip() -> Control:
	var txt := "Guest · not saved to cloud"
	if _signed_in():
		var line: Array = AccountUI.status_line(service)
		txt = String(line[0])
	var row := CenterContainer.new()
	var chip := UI3.chip(("✓ " + txt) if txt == "Saved" else txt)
	chip.name = "SyncChip"
	row.add_child(chip)
	var l := chip.get_child(0) as Label
	l.name = "SyncText"
	return row


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
	var fr := _frame()
	var left: VBoxContainer = fr[0]
	# category row with counts
	var cats := HBoxContainer.new()
	cats.name = "Categories"
	cats.add_theme_constant_override("separation", UI3Theme.space("8"))
	for c in CATS:
		var n := Cosmetics.owned_art(MetaState.cosmetics_owned, c).size()
		var b := UI3Meta.tab("%s   %d / %d" % [CAT_NAMES[c], n, catalog(c).size()], c == cat)
		b.name = "Cat_" + c
		b.pressed.connect(func() -> void:
			cat = c
			selected = ""
			refresh())
		cats.add_child(b)
	left.add_child(cats)
	var head := UI3.plate(&"plate")
	var hv := VBoxContainer.new()
	head.add_child(hv)
	hv.add_child(UI3.label(CAT_NAMES[cat], "LabelTitle"))
	hv.add_child(UI3.label("%d owned" % owned.size() if cat != Cosmetics.SLOT_DIE else "%d / %d owned · one dice skin at a time" % [owned.size(), all.size()], "LabelMuted"))
	left.add_child(head)
	var grid := GridContainer.new()
	grid.name = "Grid_" + cat
	grid.columns = 5
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", UI3Theme.space("16"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("16"))
	left.add_child(grid)
	for id in all:
		var have := owned.has(id)
		var badge := "Locked"
		if have:
			badge = "Equipped" if equipped_for(cat) == id else "Owned"
		var t := _tile("Tile_" + id, id == selected, CosmeticArt.make_node(id, 80.0),
			String(_entry(id).get("name", id)), badge, not have)
		t.pressed.connect(func() -> void:
			selected = id
			refresh())
		grid.add_child(t)
	_cos_detail(fr[1], owned)


func _cos_detail(v: VBoxContainer, owned: Array[String]) -> void:
	var e := _entry(selected)
	var tier := int(e.get("tier", 0))
	var have := owned.has(selected)
	var art := Panel.new()
	art.name = "PreviewArt"
	art.custom_minimum_size = Vector2(0, 200)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("bg"), UI3Theme.radius("s")))
	v.add_child(art)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(head)
	var nm := UI3.label(String(e.get("name", "Default")) if selected != "" else "Default", "LabelScreenTitle")
	nm.name = "PreviewName"
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nm)
	if selected != "":
		head.add_child(UI3Meta.tag(RARITY_NAMES[clampi(tier, 0, 5)]))
		var sizes: Array = [104.0, 64.0, 36.0] if cat == Cosmetics.SLOT_DIE else [96.0, 40.0]
		var art_row := HBoxContainer.new()
		art_row.alignment = BoxContainer.ALIGNMENT_CENTER
		art_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art_row.add_theme_constant_override("separation", UI3Theme.space("16"))
		for px in sizes:
			var a := CosmeticArt.make_node(selected, px)
			if a != null:
				a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				if not have:
					a.modulate = Color(1, 1, 1, 0.4)
				art_row.add_child(a)
		art.add_child(art_row)
		var body := UI3.label("Source: Echo Box, Store or Pass" if have else "Not owned yet", "LabelMuted")
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size.x = 392
		v.add_child(body)
	else:
		var body := UI3.label("Nothing equipped: the default plate is used.", "LabelMuted")
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size.x = 392
		v.add_child(body)
	var on := selected != "" and equipped_for(cat) == selected
	var eq := UI3.button("Unequip" if on else "Equip", &"primary", &"L")
	eq.name = "Equip"
	if not have:
		UI3.set_disabled_reason(eq, "Nothing to equip" if owned.is_empty() else "Not owned yet")
	eq.pressed.connect(func() -> void:
		if on:
			MetaState.unequip_cosmetic(cat)
		else:
			MetaState.equip_cosmetic(selected)
		refresh())
	v.add_child(eq)
	if equipped_for(cat) != "" and not on:
		var d := UI3.button("Use default", &"secondary", &"S")
		d.name = "UseDefault"
		d.pressed.connect(func() -> void:
			MetaState.unequip_cosmetic(cat)
			refresh())
		v.add_child(d)


# ============================================================================ Titles

## Title tiles, 3 per row: No title, owned titles, then the Ascension titles not earned yet (Locked,
## with the goal). Select a tile; the detail plate has Equip (one title at a time). Names and goals come
## from ascension_titles.json.
func _titles_tab() -> void:
	var fr := _frame()
	var left: VBoxContainer = fr[0]
	var head := UI3.plate(&"plate")
	var hv := VBoxContainer.new()
	head.add_child(hv)
	hv.add_child(UI3.label("Titles", "LabelTitle"))
	hv.add_child(UI3.label("Titles from Ascension goals. One title at a time.", "LabelMuted"))
	left.add_child(head)
	var grid := GridContainer.new()
	grid.name = "Grid_titles"
	grid.columns = 3   # few tiles: keep them tile-sized instead of stretching to the full height
	grid.add_theme_constant_override("h_separation", UI3Theme.space("16"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("16"))
	left.add_child(grid)
	var owned := TitleNames.owned(MetaState.cosmetics_owned)
	var goals := {}
	for t in TitleNames.ascension_titles():
		goals[String(t["id"])] = "Win a run at A%d" % int(t["asc"])
	var cur := title_sel if _title_sel_set else MetaState.equipped_title
	var entries: Array = [["", "No title", "", true]]
	for id in owned:
		entries.append([id, TitleNames.display(id), String(goals.get(id, "")), true])
	for t in TitleNames.ascension_titles():
		if not owned.has(String(t["id"])):
			entries.append([String(t["id"]), String(t["name"]), String(goals[t["id"]]), false])
	var found := false
	for e in entries:
		found = found or String(e[0]) == cur
	if not found:
		cur = ""
	for e in entries:
		var id := String(e[0])
		var have := bool(e[3])
		var badge := "Locked"
		if have:
			badge = "Equipped" if MetaState.equipped_title == id else "Owned"
		var tile := _tile("Title_" + (id.replace(":", "_") if id != "" else "none"), id == cur, null,
			String(e[1]), badge, not have)
		tile.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		tile.custom_minimum_size.y = 160
		tile.pressed.connect(func() -> void:
			title_sel = id
			_title_sel_set = true
			refresh())
		grid.add_child(tile)
	# detail
	var v: VBoxContainer = fr[1]
	var sel_label := "No title"
	var sel_goal := "Show no title under your name."
	var sel_have := true
	for e in entries:
		if String(e[0]) == cur:
			sel_label = String(e[1])
			sel_have = bool(e[3])
			if String(e[2]) != "":
				sel_goal = String(e[2])
	var art := Panel.new()
	art.custom_minimum_size = Vector2(0, 200)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("bg"), UI3Theme.radius("s")))
	var av := CenterContainer.new()
	av.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	av.add_child(make_avatar(128.0, service))
	art.add_child(av)
	v.add_child(art)
	var hd := HBoxContainer.new()
	hd.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(hd)
	var tn := UI3.label(sel_label, "LabelScreenTitle")
	tn.name = "DetailTitle"
	tn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	tn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(tn)
	var bt := "Locked"
	if sel_have:
		bt = "Equipped" if MetaState.equipped_title == cur else "Owned"
	hd.add_child(UI3Meta.tag(bt))
	var gl := UI3.label(sel_goal, "LabelMuted")
	gl.name = "Goal"
	gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gl.custom_minimum_size.x = 392
	v.add_child(gl)
	var eq := UI3.button("Equip" if cur != "" else "Use default", &"primary", &"L")
	eq.name = "Equip"
	if not sel_have:
		UI3.set_disabled_reason(eq, "Not yet earned")
	elif MetaState.equipped_title == cur:
		UI3.set_disabled_reason(eq, "Equipped")
	eq.pressed.connect(func() -> void:
		MetaState.equip_title(cur)
		refresh())
	v.add_child(eq)


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
	av.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("accent"), UI3Theme.radius("m")))
	var ini := UI3.label(nm, "LabelScreenTitle")
	ini.add_theme_color_override("font_color", UI3Theme.color("accent_text"))
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(ini)
	return AvatarFrame.wrap(av, total_px, MetaState.equipped_frame, total_px * 0.66)
