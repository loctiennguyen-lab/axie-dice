extends Control
## SAMPLE TEAMS (UI-03 round-2 screen 29, Guides tab, on UI3Meta): the four starter compositions from
## ContentDB.GUIDES. Content = a list of guide rows (name, archetype, difficulty); right 440 plate = the
## article for the selected guide: team strip, why, how, and the one primary USE THIS TEAM. The text is the
## game's own copy, unchanged. USE THIS TEAM hands the team over through MainMenu.pending_team (what Run Setup
## and the legacy menu both read) and opens Run Setup.
## Node names kept: Guide_<id> (the article), TeamStrip, UseButton, ArchLabel; rows are GuideRow_<id>.

const DETAIL_W := 440

var _shell: Dictionary
var _list: VBoxContainer
var _detail: PanelContainer
var _rows: Dictionary = {}   # id -> PanelContainer
var selected_id := ""
var no_scene_change := false


func _ready() -> void:
	_shell = UI3Meta.build(self, "Guides", "Four teams that work", _on_back)
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	UI3Meta.doc_tabs(_shell, "guides")
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", UI3Meta.GAP)
	(_shell["col"] as VBoxContainer).add_child(body)
	_list = VBoxContainer.new()
	_list.name = "GuideList"
	_list.add_theme_constant_override("separation", UI3Theme.space("16"))
	var sc := UI3Meta.scroll(_list)
	sc.name = "ListScroll"
	body.add_child(sc)
	_detail = UI3.plate(&"plate")
	_detail.name = "DetailPlate"
	_detail.custom_minimum_size = Vector2(DETAIL_W, 0)
	body.add_child(_detail)
	for g in ContentDB.GUIDES:
		_list.add_child(_build_row(g))
	if not ContentDB.GUIDES.is_empty():
		select_guide(str((ContentDB.GUIDES[0] as Dictionary).get("id", "")))


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func _unhandled_key_input(ev: InputEvent) -> void:
	if UI3Meta.esc_back(ev, _shell, _on_back):
		get_viewport().set_input_as_handled()


func _arch(guide: Dictionary) -> Dictionary:
	return ContentDB.ARCH.get(str(guide.get("arch", "")), {})


func _build_row(guide: Dictionary) -> PanelContainer:
	var id := str(guide.get("id", ""))
	var card := UI3.plate(&"card")
	card.name = "GuideRow_" + id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 96)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("16"))
	card.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", UI3Theme.space("8"))
	row.add_child(info)
	var nm := UI3.label(str(guide.get("n", "")), "LabelTitle")
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(nm)
	info.add_child(UI3.label("%s · %s" % [str(_arch(guide).get("n", str(guide.get("arch", "")).to_upper())),
		str(guide.get("diff", ""))], "LabelMuted"))
	row.add_child(_build_team_strip(guide.get("team", []), 40))
	var open := UI3.button("Read", &"secondary", &"S")
	open.name = "ReadButton"
	open.pressed.connect(select_guide.bind(id))
	row.add_child(open)
	_rows[id] = card
	return card


## Shows the article for `id` in the detail plate and marks its row.
func select_guide(id: String) -> void:
	var guide: Dictionary = {}
	for g in ContentDB.GUIDES:
		if str((g as Dictionary).get("id", "")) == id:
			guide = g
	if guide.is_empty():
		return
	selected_id = id
	for k in _rows.keys():
		UI3.set_card_selected(_rows[k], k == id, false)
	UI3Meta.clear(_detail)
	var v := VBoxContainer.new()
	v.name = "Guide_" + id
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	_detail.add_child(v)
	var arch := _arch(guide)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI3Theme.space("16"))
	var t := UI3.label(str(guide.get("n", "")), "LabelScreenTitle")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var tag := UI3Meta.tag(str(arch.get("n", str(guide.get("arch", "")).to_upper())))
	tag.name = "ArchLabel"
	head.add_child(tag)
	v.add_child(head)
	v.add_child(UI3.label(str(guide.get("diff", "")), "LabelMuted"))
	v.add_child(_build_team_strip(guide.get("team", []), 64))
	var why := UI3.label(str(guide.get("why", "")))
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(why)
	for line in guide.get("how", []):
		var l := UI3.label("· " + str(line), "LabelMuted")
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var use := UI3.button("Use this team", &"primary", &"L")
	use.name = "UseButton"
	use.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	use.pressed.connect(_on_use_pressed.bind(guide))
	v.add_child(use)


## Portraits of the five heroes. `size` is the square side.
func _build_team_strip(team: Array, size: int) -> HBoxContainer:
	var strip := HBoxContainer.new()
	strip.name = "TeamStrip"
	strip.add_theme_constant_override("separation", UI3Theme.space("8"))
	for key in team:
		var hero: Dictionary = ContentDB.heroes.get(str(key), {})
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(size, size)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture = MockupAssets.tex("assets/portrait/%s.png" % str(hero.get("cls", "")))
		portrait.tooltip_text = str(hero.get("n", ""))
		strip.add_child(portrait)
	return strip


## Sets MainMenu.pending_team (what Run Setup seeds its party from). Split from the scene change so a
## test can call it without leaving the scene.
static func hand_team_to_menu(guide: Dictionary) -> Array[String]:
	var team: Array[String] = []
	for k in guide.get("team", []):
		team.append(str(k))
	MainMenu.pending_team = team
	return team


func _on_use_pressed(guide: Dictionary) -> void:
	hand_team_to_menu(guide)
	if not no_scene_change:
		LandNav.open(&"run_setup")
