class_name ProfileView
extends Control
## Profile + cosmetics + titles, UI-05 (frames 24-profile*, round 3). One header plate (Back, Title, SubLine, Overview /
## Cosmetics / Titles tabs). Overview + Titles: left column and a ProfileCard (profile_detail_w). Cosmetics: CategoryTabs,
## Grid of CosmeticTile (5 cols) and a PreviewPlate (preview_w) with the 3D die. Names and rarity come from
## cosmetics_manifest.json, numbers from MetaState. Nothing is picked on open except the item really equipped.
## Cosmetic only; state lives in MetaState (equip API checks ownership, saves via SaveStore). `no_scene_change` lets tests build it.

const Parts := preload("res://scenes/profile/ui5/ProfileParts.gd")
const TABS: Array[String] = ["Overview", "Cosmetics", "Titles"]
const TAB_NODES: Array[String] = ["OverviewTab", "CosmeticsTab", "TitlesTab"]
const CATS: Array[String] = [Cosmetics.SLOT_DIE, Cosmetics.SLOT_FRAME]
const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]
const CAT_NAMES := {"die": "Dice skins", "frame": "Avatar frames"}
const GRID_COLS := 5

var no_scene_change := false
## Injectable so tests can stub the account (default: the AccountService autoload).
var service: Node
var tab := 0
var cat := Cosmetics.SLOT_DIE
## Cosmetics pick. Follows the equipped item until the player clicks another tile.
var selected := "":
	get:
		return selected if _sel_set else equipped_for(cat)
	set(v):
		selected = v
		_sel_set = true
var _sel_set := false
var _shell: Dictionary
var _body: HBoxContainer
var _tab_btns: Array[Button] = []
var _preview_gen := 0
var _stage: DiceStage = null
var _equip_busy := false


func _ready() -> void:
	if service == null:
		service = AccountService
	_shell = UI3Meta.build(self, "Profile", "", _on_back)
	(_shell["back"] as Button).name = "BackButton"
	(_shell["sub"] as Control).name = "SubLine"
	(_shell["panel"] as Control).name = "PlateHost"
	var cur := find_child("Currencies", true, false)
	if cur != null:
		cur.visible = false   # frame: the header plate holds Back, Title, SubLine and the tabs only
	_body = HBoxContainer.new()
	_body.name = "Body"
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", UI3Meta.GAP)
	(_shell["col"] as VBoxContainer).add_child(_body)
	var hr: Control = _shell["header_right"]
	var trow := (_shell["sub"] as Control).get_parent()
	hr.get_parent().remove_child(hr)
	hr.name = "Tabs"
	hr.add_theme_constant_override("separation", UI3Theme.space("8"))
	trow.add_child(hr)
	var bar := Ui5TabBar.new()
	bar.setup(TABS, tab, true)
	bar.name = "TabBar"
	hr.add_child(bar)
	for i in TABS.size():
		var b := bar.get_child(i) as Button
		b.name = TAB_NODES[i]
		_tab_btns.append(b)
	bar.tab_selected.connect(set_tab)
	if service.has_signal("changed"):
		service.changed.connect(refresh)
		tree_exiting.connect(func() -> void:
			if is_instance_valid(service) and service.changed.is_connected(refresh):
				service.changed.disconnect(refresh))
	refresh()
	_tab_btns[tab].call_deferred("grab_focus")


func _unhandled_key_input(ev: InputEvent) -> void:
	if UI3Meta.esc_back(ev, _shell, _on_back):
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func set_tab(i: int) -> void:
	tab = clampi(i, 0, TABS.size() - 1)
	_sel_set = false
	refresh()


func _signed_in() -> bool:
	return service.is_signed_in()


func _name() -> String:
	return String(service.display_name()) if _signed_in() else "Guest"


func refresh() -> void:
	if _body == null:
		return
	_preview_gen += 1
	_stage = null
	UI3Meta.clear(_body)
	for i in _tab_btns.size():
		_tab_btns[i].button_pressed = (i == tab)
	var land := "%s Land" % LandUpgradeScreen.TIER_NAMES[clampi(MetaState.land_tier, 1, LandUpgradeScreen.TIER_NAMES.size()) - 1]
	(_shell["sub"] as Label).text = ("Guest · local stats on this computer" if not _signed_in() else "%s · %s" % [_name(), land])
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


func _left() -> VBoxContainer:
	var left := VBoxContainer.new()
	left.name = "Content"
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", UI3Theme.space("16"))
	_body.add_child(left)
	return left


# ============================================================================ Overview

func _overview_tab() -> void:
	var left := _left()
	if not _signed_in():
		left.add_child(_guest_banner())
	var tiles := HBoxContainer.new()
	tiles.name = "StatTiles"
	tiles.add_theme_constant_override("separation", UI3Theme.space("12"))
	for t in stat_tiles():
		tiles.add_child(Parts.stat_tile(t))
	left.add_child(tiles)
	left.add_child(_land_section())
	var rl := Parts.plate("RunList", UI3Theme.space("16"), UI3Theme.space("16"))
	rl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", UI3Theme.space("8"))
	rl.add_child(rv)
	rv.add_child(Ui5Text.label("Last %d runs" % MetaState.RUN_LOG_MAX, "text_title", "text", true))
	var sc := ScrollContainer.new()
	sc.name = "RunScroll"
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.get_v_scroll_bar().custom_minimum_size.x = UI3Theme.SCROLL_W
	rv.add_child(sc)
	var list := VBoxContainer.new()
	list.name = "Runs"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", UI3Theme.space("4"))
	sc.add_child(list)
	if MetaState.run_log.is_empty():
		# The counter above (MetaState.runs) can be ahead of the list (older saves, or the list was cleared).
		var e := Ui5Text.label(empty_runs_text(MetaState.runs), "text_body", "text_muted")
		e.name = "RunsEmpty"
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(e)
	for i in MetaState.run_log.size():
		list.add_child(_run_row(MetaState.run_log[i] as Dictionary, i))
	left.add_child(rl)
	_body.add_child(_profile_card())


func _guest_banner() -> Control:
	var p := Parts.plate("GuestBanner", UI3Theme.space("12"), UI3Theme.space("16"))
	var sb := p.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	sb.border_color = UI3Theme.color("notice_warn")
	p.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(h)
	h.add_child(Ui5ToneDisc.make(&"info"))
	var t := VBoxContainer.new()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_constant_override("separation", 0)
	t.add_child(Ui5Text.label("Sign in to keep them.", "text_body", "text", true))
	t.add_child(Ui5Text.label("These stats live on this computer only.", "text_body", "text"))
	h.add_child(t)
	var b := UI3.button("Sign in", &"secondary", &"S")
	b.name = "SignInButton"
	b.pressed.connect(_open_account)
	h.add_child(b)
	return p


func _profile_card() -> Control:
	var p := Parts.plate("ProfileCard", UI3Theme.space("20"), UI3Theme.space("20"))
	p.custom_minimum_size.x = UI3Theme.size_of("profile_detail_w")
	p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_BEGIN
	v.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(v)
	var hc := CenterContainer.new()
	hc.add_child(make_avatar(UI3Theme.size_of("avatar_l"), service, not _signed_in()))
	v.add_child(hc)
	var nm := Ui5Text.label(_name(), "text_screen_title", "text", true)
	nm.name = "Name"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	if _signed_in() and bool(service.account.get("sky_mavis", false)):
		var tc := CenterContainer.new()
		tc.add_child(Parts.tag("Sky Mavis", "SkyMavisTag"))
		v.add_child(tc)
	var tl := Ui5Text.label(
		("Title: %s" % TitleNames.display(MetaState.equipped_title)) if MetaState.equipped_title != "" else "No title",
		"text_body", "text")
	tl.name = "TitleLine"
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tl)
	v.add_child(_sync_chip())
	return p


func _sync_chip() -> Control:
	var txt := "Guest · not saved to cloud"
	if _signed_in():
		var line: Array = AccountUI.status_line(service)
		txt = String(line[0])
	var row := CenterContainer.new()
	if txt == "Saved":
		row.add_child(Parts.tag(txt, "SyncChip", UI3Theme.color("success_text"), UI3Theme.color("success_bg"), "ui_check"))
	else:
		row.add_child(Parts.tag(txt, "SyncChip"))
	return row


func _land_section() -> Control:
	var box := Parts.plate("LandSection", UI3Theme.space("16"), UI3Theme.space("16"))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	box.add_child(v)
	v.add_child(Ui5Text.label("Land", "text_title", "text", true))
	var tier := clampi(MetaState.land_tier, 1, LandUpgradeScreen.TIER_NAMES.size())
	var score := LandDecor.aesthetic(MetaState.land_decor_placed)
	var ms := LandDecor.milestones()
	var got := 0
	for m in ms:
		if MetaState.land_milestones_claimed.has(String((m as Dictionary).get("id", ""))):
			got += 1
	v.add_child(Parts.kv("Tier", "%s %d/6" % [LandUpgradeScreen.TIER_NAMES[tier - 1], tier], "LandTier"))
	var sr := Parts.kv("Aesthetic score", str(score), "LandScore")
	UI3Tooltip.bind(sr, "Points from decor placed on your Land. They unlock milestone rewards.")
	v.add_child(sr)
	v.add_child(Parts.kv("Milestones claimed", "%d / %d" % [got, ms.size()], "LandMilestones"))
	var help := Ui5Text.label("Aesthetic score = points from decor you place. Claim each milestone reward in Edit Land, Rewards tab.", "text_body", "text_muted")
	help.name = "LandHelp"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(help)
	return box


## Text under "Last runs" when the list is empty. Never says "No runs yet" while the Runs tile counts some.
static func empty_runs_text(finished: int) -> String:
	if finished > 0:
		return "Your %d finished runs are counted above. The list shows runs from your next one." % finished
	return "No runs yet. Finish a run and it shows up here."


## [{k, v, s}] x 5 from saved data. No finished run yet reads "—" everywhere, never a made-up number.
static func stat_tiles() -> Array[Dictionary]:
	var best := -1
	for k in MetaState.asc_wins:
		if int(MetaState.asc_wins[k]) > 0:
			best = maxi(best, int(k))
	var runs := MetaState.runs
	var ps: Dictionary = MetaState.profile_stats
	var ms_played := int(ps.get("ms_played", 0))
	var none := runs <= 0
	return [
		{"k": "Runs", "v": "—" if none else str(runs), "s": "finished runs"},
		{"k": "Wins", "v": "—" if none else str(MetaState.wins), "s": "" if none else "%d%%" % int(round(100.0 * MetaState.wins / runs))},
		{"k": "Best Ascension", "v": ("A%d" % best) if best >= 0 else "—", "s": "won"},
		{"k": "Pure wins", "v": "—" if none else str(int(ps.get("pure_wins", 0))), "s": "no Aid"},
		{"k": "Missions", "v": ("%d / %d" % [int(ps.get("ms_won", 0)), ms_played]) if ms_played > 0 else "—", "s": "won / played"},
	]


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


## "2026-10-31" -> "31 Oct" (frame format); anything else is shown as saved.
static func _short_date(d: String) -> String:
	var p := d.split("-")
	if p.size() == 3 and p[1].is_valid_int() and int(p[1]) >= 1 and int(p[1]) <= 12:
		return "%d %s" % [int(p[2]), ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][int(p[1]) - 1]]
	return d


func _run_row(e: Dictionary, i: int) -> Control:
	var mission := bool(e.get("mission", false))
	var aid := int(e.get("aid", 0))
	var at := "no Aid (mission)" if mission else ("Aid %d" % aid if aid > 0 else "no Aid")
	var won := bool(e.get("won", false))
	return Parts.run_row(i, _short_date(String(e.get("date", ""))), run_mode_text(e), "A%d" % int(e.get("asc", 0)), won, at, aid == 0 and not mission)


# ============================================================================ Cosmetics

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


func _source_of(id: String) -> String:
	if cat == Cosmetics.SLOT_DIE:
		return String(DiceSkin.info(id).get("source", ""))
	return String(_entry(id).get("source", ""))


## Letter-disc avatar `px` wide wearing frame `frame_id` (node = px x 1.5); the frame is not the equipped one.
func _frame_preview(frame_id: String, avatar_px: float) -> Control:
	var av := PanelContainer.new()
	av.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("accent"), int(avatar_px * 0.5)))
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ini := UI3.label(_name().left(1).to_upper(), "LabelDisplay")
	ini.add_theme_color_override("font_color", UI3Theme.color("accent_text"))
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(ini)
	return AvatarFrame.wrap(av, AvatarFrame.frame_size(avatar_px), frame_id, avatar_px, avatar_px)



func _cosmetics_tab() -> void:
	var owned := Cosmetics.owned_art(MetaState.cosmetics_owned, cat)
	var all := catalog(cat)
	var left := _left()
	var cat_labels: Array[String] = []
	for c in CATS:
		cat_labels.append("%s · %d of %d" % [CAT_NAMES[c], Cosmetics.owned_art(MetaState.cosmetics_owned, c).size() + 1, catalog(c).size() + 1])
	var bar := Ui5TabBar.new()
	bar.setup(cat_labels, CATS.find(cat), true)
	bar.name = "CategoryTabs"
	(bar.get_child(0) as Button).name = "DiceTab"
	(bar.get_child(1) as Button).name = "FramesTab"
	bar.tab_selected.connect(func(i: int) -> void:
		cat = CATS[i]
		_sel_set = false
		refresh())
	left.add_child(bar)
	var scroll := ScrollContainer.new()
	scroll.name = "GridScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.get_v_scroll_bar().custom_minimum_size.x = UI3Theme.SCROLL_W
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = GRID_COLS
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", UI3Theme.space("12"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("12"))
	scroll.add_child(grid)
	var eq_now := equipped_for(cat)
	var sel := selected
	grid.add_child(_cos_tile("", owned, eq_now, sel))
	for id in all:
		grid.add_child(_cos_tile(id, owned, eq_now, sel))
	_body.add_child(_preview_plate(owned, sel))


func _cos_tile(id: String, owned: Array[String], eq_now: String, sel: String) -> Button:
	var is_default := id == ""
	var have := is_default or owned.has(id)
	var e := _entry(id)
	var tier := int(e.get("tier", 0))
	var b := Parts.tile_button("CosmeticTile_default_" + cat if is_default else "CosmeticTile_" + id, id == sel, "cos_tile_h")
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, UI3Theme.space("12"))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", UI3Theme.space("4"))
	b.add_child(v)
	var strip := ColorRect.new()
	strip.name = "TierStrip"
	strip.custom_minimum_size.y = 4
	strip.color = UI3Theme.color("plate_rim") if is_default else DiceSkin.tier_color(tier)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(strip)
	var box := PanelContainer.new()
	box.name = "Art"
	box.theme = UI3Theme.get_theme()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cs := float(UI3Theme.size_of("cos_art"))
	box.custom_minimum_size = Vector2(cs, cs)
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("m")))
	var art: Control
	if cat == Cosmetics.SLOT_DIE:
		var tr := TextureRect.new()
		tr.name = "Thumb"
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_fill_thumb(tr, id)
		art = tr
	else:
		art = _frame_preview(id, cs * 0.5)
		art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not have:
		art.modulate = Color(1, 1, 1, 0.45)
	box.add_child(art)
	v.add_child(box)
	var nm := Ui5Text.label(("Default" if cat == Cosmetics.SLOT_DIE else "No frame") if is_default else CosmeticTile.any_name(id), "text_body", "text", true)
	nm.name = "Name"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(nm)
	var line := HBoxContainer.new()
	line.name = "Line"
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not is_default:
		var tw := Ui5Text.label(RARITY_NAMES[clampi(tier, 0, 5)] + " · ", "text_body", "text")
		tw.name = "TierWord"
		tw.add_theme_color_override("font_color", DiceSkin.tier_text_color(tier))
		line.add_child(tw)
	var st := Ui5Text.label("Equipped" if eq_now == id else ("Owned" if have else "Locked"), "text_body", "text_muted")
	st.name = "Badge"
	line.add_child(st)
	v.add_child(line)
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, cs + float(UI3Theme.size_of("text_body")) * 3.4 + 48.0)   # strip + art + name + line + padding
	var disc := Parts.equipped_disc()
	disc.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	disc.position = Vector2(-disc.size.x - UI3Theme.space("8"), UI3Theme.space("12"))
	disc.visible = eq_now == id
	b.add_child(disc)
	b.pressed.connect(func() -> void:
		selected = id
		refresh())
	return b


func _preview_plate(owned: Array[String], sel: String) -> Control:
	var e := _entry(sel)
	var is_default := sel == ""
	var tier := int(e.get("tier", 0))
	var have := is_default or owned.has(sel)
	var p := Parts.plate("PreviewPlate", UI3Theme.space("16"), UI3Theme.space("16"))
	p.custom_minimum_size.x = UI3Theme.size_of("preview_w")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI3Theme.space("12"))
	v.add_child(head)
	var nm := Ui5Text.label(("Default" if cat == Cosmetics.SLOT_DIE else "No frame") if is_default else CosmeticTile.any_name(sel), "text_screen_title", "text", true)
	nm.name = "PreviewName"
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nm)
	if not is_default:
		head.add_child(Parts.tag(RARITY_NAMES[clampi(tier, 0, 5)], "TierChip", DiceSkin.tier_text_color(tier), Color(0, 0, 0, 0.001), "", DiceSkin.tier_color(tier)))
	var stage := PanelContainer.new()
	stage.name = "Preview3D"
	stage.theme = UI3Theme.get_theme()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.custom_minimum_size.y = 200
	stage.clip_contents = true
	stage.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("m")))
	v.add_child(stage)
	if cat == Cosmetics.SLOT_DIE:
		_build_die_preview(stage, sel)
	else:
		var row := CenterContainer.new()
		row.name = "FramePreview"
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", UI3Theme.space("8"))
		for px in [160.0, 64.0]:
			var fp := _frame_preview(sel, px)
			fp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hb.add_child(fp)
		row.add_child(hb)
		stage.add_child(row)
		if not have:
			row.modulate = Color(1, 1, 1, 0.45)
	var body_text := ""
	if is_default:
		body_text = "Nothing equipped: the standard look is used."
	elif cat == Cosmetics.SLOT_DIE:
		body_text = "Drag to spin · your preset's faces"
	if not is_default and tier >= 3:
		body_text += (" " if body_text != "" else "") + "Moves while equipped; Reduce flashing keeps it still."
	var body := Ui5Text.label(body_text, "text_body", "text_muted")
	body.name = "PreviewBody"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	v.add_child(body)
	if not is_default:
		var src := Parts.kv("Source", _source_of(sel), "SourceRow")
		var sv := src.find_child("Value", true, false) as Label
		sv.name = "SourceValue"
		sv.add_theme_font_size_override("font_size", UI3Theme.size_of("text_body"))
		if not have:
			sv.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
		v.add_child(src)
	var eq := UI3.button("Equip", &"primary", &"L")
	eq.name = "EquipButton"
	eq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eq.custom_minimum_size.y = UI3Theme.size_of("btn_l")
	if equipped_for(cat) == sel:
		Ui5DisabledReason.apply(eq, "Equip · Equipped")
	elif not have:
		Ui5DisabledReason.apply(eq, "Equip · Locked")
	eq.pressed.connect(_on_equip.bind(eq))
	v.add_child(eq)
	return p


## Baked thumbnail into `tr` (async; a rebuilt tab drops late answers). Default tile = the plain die.
func _fill_thumb(tr: TextureRect, id: String) -> void:
	var gen := _preview_gen
	var tex: Texture2D = null
	if id == "":
		tex = await DiceThumb.get_plain(self)
	else:
		tex = DiceThumb.cached_texture(id)
		if tex == null:
			tex = await DiceThumb.get_thumb(self, id)
	if gen == _preview_gen and is_instance_valid(tr) and tex != null:
		tr.texture = tex


## Baked thumbnail at once, the live spinning die when its faces are drawn (one SubViewport on screen).
func _build_die_preview(art: Control, id: String) -> void:
	var gen := _preview_gen
	var tr := TextureRect.new()
	tr.name = "PreviewThumb"
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.add_child(tr)
	_fill_thumb(tr, id)
	if DisplayServer.get_name() == "headless":
		return
	var faces := DiceStage.preview_faces()
	var roller := DiceRoller3D.new()
	add_child(roller)
	await roller.prepare(faces, id)
	roller.queue_free()
	if gen != _preview_gen or not is_instance_valid(art):
		return
	var st := DiceStage.new()
	st.name = "DiceStage"
	var side := int(UI3Theme.size_of("preview_w")) - 2 * int(UI3Theme.space("16"))
	st.setup(Vector2i(side, side), id, faces, true)
	st.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	art.add_child(st)
	st.start_spin()
	_stage = st
	tr.visible = false


## 49-equip-moment. Equip on the Default tile = back to the plain die / no frame.
func _on_equip(btn: Button) -> void:
	if _equip_busy:
		return
	var prev := equipped_for(cat)
	var why := ""
	if selected == "":
		MetaState.unequip_cosmetic(cat)
	else:
		why = MetaState.equip_cosmetic(selected)
	if why != "":
		_toast("Couldn't equip. Try again.")
		refresh()
		return
	if MetaState.reduce_flash or DisplayServer.get_name() == "headless":
		refresh()   # check appears at once, no motion
		return
	_equip_busy = true
	_equip_moment(prev)
	await get_tree().create_timer(0.4).timeout
	_equip_busy = false
	if is_inside_tree():
		refresh()


func _equip_moment(prev: String) -> void:
	var newest := find_child("CosmeticTile_default_" + cat if selected == "" else "CosmeticTile_" + selected, true, false)
	var old := find_child("CosmeticTile_default_" + cat if prev == "" else "CosmeticTile_" + prev, true, false)
	if old != null:
		var od := old.find_child("EquippedDisc", true, false) as Control
		if od != null:
			create_tween().tween_property(od, "modulate:a", 0.0, 0.12)
	if newest != null:
		var nd := newest.find_child("EquippedDisc", true, false) as Control
		if nd != null:
			nd.visible = true
			nd.scale = Vector2.ONE * 0.6
			var tw := create_tween()
			tw.tween_property(nd, "scale", Vector2.ONE * 1.35, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(nd, "scale", Vector2.ONE, 0.1)
	if _stage != null and is_instance_valid(_stage):
		_stage.play_equip()
	elif cat == Cosmetics.SLOT_FRAME:
		var fp := find_child("FramePreview", true, false) as Control
		if fp != null:
			fp.pivot_offset = fp.size / 2.0
			fp.scale = Vector2.ONE * 1.15
			fp.modulate.a = 0.4
			var ft := create_tween().set_parallel(true)
			ft.tween_property(fp, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			ft.tween_property(fp, "modulate:a", 1.0, 0.24)


func _toast(text: String) -> void:
	var t := UI3.toast(text, &"error")
	t.name = "Toast"
	t.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	t.position = Vector2(size.x * 0.5 - 160.0, size.y - 96.0)
	add_child(t)
	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		if is_instance_valid(t):
			t.queue_free())


# ============================================================================ Titles

## Goal line of a title: Ascension goal, Land milestone points, else "" (no line, no guess).
static func title_goal(id: String) -> String:
	for t in TitleNames.ascension_titles():
		if String(t["id"]) == id:
			return "Win a run at A%d" % int(t["asc"])
	for m in LandDecor.milestones():
		if String((m as Dictionary).get("item", "")) == id:
			return "Land: %d aesthetic points" % int((m as Dictionary).get("points", 0))
	return ""


## [{id, name, goal, have}]: No title, owned titles, then Ascension and Land titles not earned yet.
static func title_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = [{"id": "", "name": "No title", "goal": "Show no title under your name.", "have": true}]
	var owned := TitleNames.owned(MetaState.cosmetics_owned)
	for id in owned:
		out.append({"id": id, "name": TitleNames.display(id), "goal": title_goal(id), "have": true})
	for t in TitleNames.ascension_titles():
		if not owned.has(String(t["id"])):
			out.append({"id": String(t["id"]), "name": String(t["name"]), "goal": title_goal(String(t["id"])), "have": false})
	for m in LandDecor.milestones():
		var it := String((m as Dictionary).get("item", ""))
		if String((m as Dictionary).get("kind", "")) == "title" and not owned.has(it):
			out.append({"id": it, "name": TitleNames.display(it), "goal": title_goal(it), "have": false})
	return out


func _titles_tab() -> void:
	var left := _left()
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 0)
	head.add_child(Ui5Text.label("Titles", "text_title", "text", true))
	head.add_child(Ui5Text.label("Titles from Ascension goals. One title at a time.", "text_body", "text_muted"))
	left.add_child(head)
	var grid := GridContainer.new()
	grid.name = "TitleGrid"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", UI3Theme.space("12"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("12"))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.get_v_scroll_bar().custom_minimum_size.x = UI3Theme.SCROLL_W
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(grid)
	left.add_child(sc)
	for e in title_entries():
		grid.add_child(_title_tile(e))
	_body.add_child(_profile_card())


func _title_tile(e: Dictionary) -> Control:
	var id := String(e["id"])
	var have := bool(e["have"])
	var on := MetaState.equipped_title == id
	var t := Parts.plate("TitleTile_" + (id.replace(":", "_") if id != "" else "none"), UI3Theme.space("16"), UI3Theme.space("16"))
	t.custom_minimum_size.y = UI3Theme.size_of("title_tile_h")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if on:
		var sb := t.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		sb.set_border_width_all(UI3Theme.stroke("selected"))
		sb.border_color = UI3Theme.color("selected")
		t.add_theme_stylebox_override("panel", sb)
	if not have:
		t.modulate = Color(1, 1, 1, 0.6)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	t.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(h)
	var nm := Ui5Text.label(String(e["name"]), "text_title", "text", true)
	nm.name = "Name"
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(nm)
	if on:
		h.add_child(Parts.equipped_disc())
	elif not have:
		var ic := TextureRect.new()
		ic.name = "LockIcon"
		ic.texture = UI3.icon("ui_lock")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_m")
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ic)
	var g := Ui5Text.label(String(e["goal"]), "text_body", "text_muted")
	g.name = "Goal"
	g.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	g.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	g.visible = g.text != ""
	v.add_child(g)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var b := UI3.button("Use default" if id == "" else "Equip", &"secondary", &"S")
	b.name = "UseDefaultButton" if id == "" else "EquipButton"
	if on:
		Ui5DisabledReason.apply(b, "Use default · In use" if id == "" else "Equip · Equipped")
	elif not have:
		Ui5DisabledReason.apply(b, "Equip · Not yet earned")
	b.pressed.connect(func() -> void:
		MetaState.equip_title(id)
		refresh())
	v.add_child(b)
	return t


## Initial-letter avatar wearing the equipped frame (same look as the Land chip).
## `svc` = the account service (is_signed_in / display_name); null falls back to the AccountService autoload.
## `guest_mark` = "?" on the guest colour (ProfileCard).
static func make_avatar(total_px: float, svc: Node = null, guest_mark := false) -> Control:
	if svc == null:
		svc = AccountService
	var nm := "P"
	if guest_mark:
		nm = "?"
	elif svc.is_signed_in():
		nm = svc.display_name().left(1).to_upper()
	var av := PanelContainer.new()
	av.name = "Avatar"
	av.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("avatar_guest" if guest_mark else "accent"), UI3Theme.radius("m")))
	var ini := UI3.label(nm, "LabelScreenTitle")
	ini.add_theme_color_override("font_color", UI3Theme.color("text" if guest_mark else "accent_text"))
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(ini)
	return AvatarFrame.wrap(av, total_px, MetaState.equipped_frame, total_px / AvatarFrame.SCALE, total_px / AvatarFrame.SCALE)
