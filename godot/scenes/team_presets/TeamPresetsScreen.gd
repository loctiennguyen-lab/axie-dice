class_name TeamPresetsScreen
extends Control
## M2 Team presets (House, key 2). Spec: design/handoffs/ui-02-round3 README section 2 M2, frames M2a-M2f.
## Grid of saved teams (MetaState.team_presets via TeamPresets, persisted by SaveStore): Use for next
## run (hands the party to Run Setup through MainMenu.pending_team), Edit / Copy / Delete, a 600
## delete confirm with focus on "Keep it", an editor (name 16 chars + 5 seats, Save disabled with the
## reason), and a read-only "Sample teams" tab fed by ContentDB.GUIDES.
## Not built: mouse drag of the handle (Alt + Left/Right on a focused card reorders), the
## "Best Ascension won with it" line (no per-team result history exists), house thumbnail.

const _Shell := preload("res://scenes/shared/R3Shell.gd")

## "mine" | "samples"
var tab := "mine"
## "grid" | "editor"
var view := "grid"
var no_scene_change := false
var use_account := true
var account_status_hook: Callable
var guest := false

var edit_index := -1            ## -1 = new team
var edit_name := ""
var edit_party: Array = ["", "", "", "", ""]
var last_error := ""

var _shell: Dictionary
var _body: Control
var _tabs_box: HBoxContainer
var _focus_idx := 0
var _delete_idx := -1
var _name_edit: LineEdit
var _save_btn: Button
var _count_lbl: Label


func _ready() -> void:
	_build()
	if use_account:
		guest = _derive_guest()
	refresh()


func _derive_guest() -> bool:
	var st: int = account_status_hook.call() if account_status_hook.is_valid() else AccountService.status
	return st == AccountService.Status.GUEST or st == AccountService.Status.EXPIRED


func _build() -> void:
	_shell = _Shell.build(self, "Team presets", "", _on_back)
	_tabs_box = HBoxContainer.new()
	_tabs_box.name = "Tabs"
	_tabs_box.add_theme_constant_override("separation", 4)
	(_shell["header_right"] as Control).add_child(_tabs_box)
	var col: VBoxContainer = _shell["col"]
	_body = MarginContainer.new()
	_body.name = "Body"
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for s in ["left", "right", "top", "bottom"]:
		_body.add_theme_constant_override("margin_" + s, 20 if s in ["top"] else 24)
	col.add_child(_body)


func _unhandled_key_input(ev: InputEvent) -> void:
	var k := ev as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_ESCAPE:
		if (_shell["modal_layer"] as Control).get_child_count() > 0:
			close_modal()
		elif view == "editor":
			cancel_editor()
		else:
			_on_back()
		get_viewport().set_input_as_handled()
	elif k.alt_pressed and (k.keycode == KEY_LEFT or k.keycode == KEY_RIGHT) and view == "grid" and tab == "mine":
		reorder(_focus_idx, -1 if k.keycode == KEY_LEFT else 1)
		get_viewport().set_input_as_handled()


func _on_back() -> void:
	if view == "editor":
		cancel_editor()
	elif is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


# ------------------------------------------------------------ public API (tests use these)

func switch_tab(t: String) -> void:
	tab = t
	view = "grid"
	refresh()


func use_preset(i: int) -> bool:
	if i < 0 or i >= TeamPresets.count():
		return false
	var e: Dictionary = MetaState.team_presets[i]
	if TeamPresets.missing_count(e) > 0:
		return false
	_hand_party(TeamPresets.usable_party(e))
	return true


func _hand_party(party: Array[String]) -> void:
	var team: Array[String] = []
	for k in party:
		if k != "":
			team.append(k)
	MainMenu.pending_team = team
	if is_inside_tree() and not no_scene_change:
		LandNav.open(&"run_setup")


func use_sample(i: int) -> void:
	if i < 0 or i >= ContentDB.GUIDES.size():
		return
	var t: Array[String] = []
	for k in ContentDB.GUIDES[i].get("team", []):
		t.append(str(k))
	_hand_party(t)


func open_editor(i: int) -> void:
	edit_index = i
	if i >= 0 and i < TeamPresets.count():
		var e: Dictionary = MetaState.team_presets[i]
		edit_name = String(e["name"])
		edit_party = []
		for k in TeamPresets.usable_party(e):
			edit_party.append(k)
	else:
		edit_name = ""
		edit_party = ["", "", "", "", ""]
	view = "editor"
	last_error = ""
	refresh()


func cancel_editor() -> void:
	view = "grid"
	refresh()


func set_edit_name(n: String) -> void:
	edit_name = n.substr(0, TeamPresets.NAME_MAX)
	_refresh_editor_state()


func set_edit_seat(slot: int, key: String) -> bool:
	if slot < 0 or slot >= TeamPresets.PARTY_SIZE:
		return false
	if key != "":
		if not TeamPresets.seat_ok(key):
			return false
		for j in edit_party.size():
			if j != slot and edit_party[j] == key:
				return false
	edit_party[slot] = key
	if view == "editor":
		refresh()
	return true


## Why Save is disabled right now ("" = it can save).
func save_block_reason() -> String:
	if TeamPresets.clean_name(edit_name) == "":
		return "Give the team a name"
	var why := TeamPresets.save_block_reason(edit_party)
	if why != "":
		return why
	if edit_index < 0 and not TeamPresets.has_room():
		return "All preset slots are used"
	return ""


func save_editor() -> bool:
	var why := save_block_reason()
	if why != "":
		last_error = why
		return false
	var r := TeamPresets.update(edit_index, edit_name, edit_party) if edit_index >= 0 \
		else TeamPresets.add(edit_name, edit_party)
	if r != "":
		last_error = r
		return false
	view = "grid"
	refresh()
	return true


func copy_preset(i: int) -> String:
	var r := TeamPresets.copy(i)
	refresh()
	return r


func request_delete(i: int) -> void:
	if i < 0 or i >= TeamPresets.count():
		return
	_delete_idx = i
	var nm := String((MetaState.team_presets[i] as Dictionary)["name"])
	_Shell.confirm(_shell["modal_layer"], "Delete \"%s\"?" % nm,
		"The preset is removed. Your Axies stay in the Vault and the starter roster. This cannot be undone.",
		"Keep it", "Delete preset", confirm_delete, close_modal)


func confirm_delete() -> void:
	TeamPresets.remove(_delete_idx)
	_delete_idx = -1
	close_modal()
	refresh()


func close_modal() -> void:
	_Shell.clear(_shell["modal_layer"])


func reorder(i: int, dir: int) -> void:
	var j := TeamPresets.move(i, dir)
	_focus_idx = j
	refresh()


# ------------------------------------------------------------ drawing

func refresh() -> void:
	if _body == null:
		return
	_Shell.clear(_body)
	_Shell.clear(_shell["banner_host"])
	_Shell.clear(_tabs_box)
	var sub: Label = _shell["sub"]
	if guest:
		_Shell.banner(_shell["banner_host"], "Presets are saved on this computer only.",
			"Sign in to keep them across devices.",
			[{"text": "Sign in", "primary": true, "cb": func() -> void:
				if is_inside_tree() and not no_scene_change:
					LandNav.open(&"account")}])
	if view == "editor":
		sub.text = "Team presets › %s" % (edit_name if edit_name != "" else "New team")
		_body.add_child(_build_editor())
		return
	for t in [["mine", "My teams"], ["samples", "Sample teams"]]:
		var b := _Shell.button(t[1], 0, 40, t[0] == tab)
		b.name = "Tab_" + t[0]
		b.pressed.connect(switch_tab.bind(t[0]))
		_tabs_box.add_child(b)
	if tab == "samples":
		sub.text = "From Guides"
		_body.add_child(_build_samples())
	else:
		sub.text = "%d of %d slots used%s" % [TeamPresets.count(), TeamPresets.slot_count(),
			" · more at higher Land tiers" if TeamPresets.slot_count() < TeamPresets.MAX_SLOTS else ""]
		_body.add_child(_build_empty() if TeamPresets.count() == 0 else _build_grid())


func _seat_cell(key: String, missing: bool) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(0, 58)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := _Shell.box(Color("E8D6B4") if missing else DangoTheme.CREAM, Color("8A3E22") if missing else Color("B89A74"), 12, 2, 4)
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var def: Dictionary = ContentDB.heroes.get(key, {})
	var cls := String(def.get("cls", ""))
	var dot := TextureRect.new()
	dot.custom_minimum_size = Vector2(32, 32)
	dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not missing:
		dot.texture = MockupAssets.tex("assets/portrait/%s.png" % cls)
	v.add_child(dot)
	var nm := _Shell.label("Missing" if missing else String(def.get("n", key)), 12,
		DangoTheme.INK_DISABLED if missing else DangoTheme.INK)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	v.add_child(nm)
	p.name = "Seat_missing" if missing else "Seat_" + key
	return p


func _build_empty() -> Control:
	var c := CenterContainer.new()
	c.name = "Empty"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	var t := _Shell.label("No saved teams yet", 30, DangoTheme.INK, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var d := _Shell.label("Save a party of 5 here and load it in Run Setup with one press. You have %d preset slots at Savannah Land." % TeamPresets.slots_for_tier(1), 16, DangoTheme.INK_ON_CREAM_MUTED)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(520, 0)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(d)
	var b := _Shell.button("Build your first team", 340, 60, true)
	b.name = "BuildFirst"
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(open_editor.bind(-1))
	v.add_child(b)
	b.grab_focus.call_deferred()
	return c


func _build_grid() -> Control:
	var g := GridContainer.new()
	g.name = "Grid"
	g.columns = 3
	g.add_theme_constant_override("h_separation", 16)
	g.add_theme_constant_override("v_separation", 16)
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var open_n := TeamPresets.slot_count()
	for n in TeamPresets.MAX_SLOTS:
		if n < TeamPresets.count():
			g.add_child(_preset_card(n))
		elif n < open_n:
			g.add_child(_open_card(n))
		else:
			g.add_child(_locked_card(n + 1))
	return g


func _cell(fill: Color, border: Color, dashed := false) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(0, 200)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _Shell.box(fill, border, 20, 3, 14))
	return p


func _locked_card(n: int) -> Control:
	var p := _cell(DangoTheme.CREAM_DISABLED, Color("9A7650"))
	p.name = "Locked%d" % n
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	var a := _Shell.label("Preset slot %d" % n, 18, DangoTheme.INK_DISABLED, true)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(a)
	var b := _Shell.label("Opens at %s Land" % String(TeamPresets.TIER_NAME.get(TeamPresets.tier_for_slot(n), "")), 13, DangoTheme.INK_DISABLED)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(b)
	return p


func _open_card(n: int) -> Control:
	var p := _cell(Color(1, 0.97, 0.92, 0.5), DangoTheme.LINE)
	p.name = "Open%d" % (n + 1)
	var b := _Shell.button("+  New team", 0, 60)
	b.name = "New%d" % (n + 1)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(open_editor.bind(-1))
	p.add_child(b)
	return p


func _preset_card(i: int) -> Control:
	var e: Dictionary = MetaState.team_presets[i]
	var miss := TeamPresets.missing_count(e)
	var p := _cell(DangoTheme.CREAM_RAISED, DangoTheme.LINE)
	p.name = "Preset%d" % i
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	v.add_child(head)
	var handle := _Shell.label("⋮⋮", 16, Color("9A7650"))
	handle.tooltip_text = "Alt + Left / Right moves this team"
	head.add_child(handle)
	var nm := _Shell.label(String(e["name"]), 21, DangoTheme.INK, true)
	nm.name = "Name"
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nm)
	if TeamPresets.has_nft(e):
		var tag := PanelContainer.new()
		tag.add_theme_stylebox_override("panel", _Shell.box(DangoTheme.GOLD, DangoTheme.OUTLINE, 12, 2, 4))
		tag.add_child(_Shell.label("NFT", 13, DangoTheme.GOLD_INK, true))
		head.add_child(tag)
	var seats := HBoxContainer.new()
	seats.add_theme_constant_override("separation", 6)
	v.add_child(seats)
	for k in (e["party"] as Array):
		seats.add_child(_seat_cell(String(k), not TeamPresets.seat_ok(String(k))))
	if miss > 0:
		v.add_child(_Shell.label("%d of 5 seats empty: the Axie left your Vault" % miss, 13, Color("8A3E22")))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	var use := _Shell.button("Pick a replacement" if miss > 0 else "Use for next run", 0, 36, miss == 0)
	use.name = "Use"
	use.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	use.size_flags_stretch_ratio = 1.6
	if miss > 0:
		use.pressed.connect(open_editor.bind(i))
	else:
		use.pressed.connect(use_preset.bind(i))
	use.focus_entered.connect(func() -> void: _focus_idx = i)
	row.add_child(use)
	for a in [["Edit", open_editor.bind(i)], ["Copy", copy_preset.bind(i)], ["Delete", request_delete.bind(i)]]:
		var b := _Shell.button(a[0], 0, 36)
		b.name = a[0]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(a[1])
		b.focus_entered.connect(func() -> void: _focus_idx = i)
		row.add_child(b)
	if i == 0:
		use.grab_focus.call_deferred()
	return p


func _build_samples() -> Control:
	var v := VBoxContainer.new()
	v.name = "Samples"
	v.add_theme_constant_override("separation", 14)
	var intro := _Shell.label("Read-only. Four compositions from Guides that work for new players. \"Use this team\" loads it into Run Setup with starter Axies.", 15, DangoTheme.INK_ON_CREAM_MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(intro)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 16)
	g.add_theme_constant_override("v_separation", 16)
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(g)
	for i in ContentDB.GUIDES.size():
		var gd: Dictionary = ContentDB.GUIDES[i]
		var c := PanelContainer.new()
		c.name = "Sample%d" % i
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
		c.add_theme_stylebox_override("panel", _Shell.box(DangoTheme.CREAM_RAISED, DangoTheme.LINE, 20, 3, 16))
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 10)
		c.add_child(cv)
		cv.add_child(_Shell.label(String(gd.get("n", "")).capitalize(), 22, DangoTheme.INK, true))
		var seats := HBoxContainer.new()
		seats.add_theme_constant_override("separation", 6)
		cv.add_child(seats)
		for k in gd.get("team", []):
			seats.add_child(_seat_cell(String(k), not ContentDB.heroes.has(str(k))))
		var why := _Shell.label(String(gd.get("why", "")), 14)
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cv.add_child(why)
		var use := _Shell.button("Use this team", 0, 36, true)
		use.name = "UseSample"
		use.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		use.custom_minimum_size.x = 160
		use.pressed.connect(use_sample.bind(i))
		cv.add_child(use)
		g.add_child(c)
	return v


func _build_editor() -> Control:
	var v := VBoxContainer.new()
	v.name = "Editor"
	v.add_theme_constant_override("separation", 16)
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", 12)
	v.add_child(nrow)
	nrow.add_child(_Shell.label("NAME", 15, DangoTheme.LINE, true))
	_name_edit = LineEdit.new()
	_name_edit.name = "NameEdit"
	_name_edit.max_length = TeamPresets.NAME_MAX
	_name_edit.text = edit_name
	_name_edit.custom_minimum_size = Vector2(360, 48)
	_name_edit.add_theme_font_override("font", DangoTheme.FONT_DISPLAY)
	_name_edit.add_theme_font_size_override("font_size", 20)
	_name_edit.text_changed.connect(set_edit_name)
	nrow.add_child(_name_edit)
	_count_lbl = _Shell.label("", 13, DangoTheme.INK_ON_CREAM_MUTED)
	nrow.add_child(_count_lbl)
	var seats := HBoxContainer.new()
	seats.add_theme_constant_override("separation", 16)
	v.add_child(seats)
	for s in TeamPresets.PARTY_SIZE:
		seats.add_child(_edit_seat(s))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_theme_constant_override("separation", 16)
	v.add_child(foot)
	var cancel := _Shell.button("Cancel", 240, 60)
	cancel.name = "Cancel"
	cancel.pressed.connect(cancel_editor)
	foot.add_child(cancel)
	_save_btn = _Shell.button("Save team", 240, 60, true)
	_save_btn.name = "Save"
	_save_btn.pressed.connect(save_editor)
	foot.add_child(_save_btn)
	_refresh_editor_state()
	return v


func _refresh_editor_state() -> void:
	if _count_lbl != null:
		_count_lbl.text = "%d / %d characters" % [edit_name.length(), TeamPresets.NAME_MAX]
	if _save_btn != null:
		var why := save_block_reason()
		_save_btn.disabled = why != ""
		_save_btn.text = "Save team" if why == "" else "Save team\n" + why


func _edit_seat(s: int) -> Control:
	var key := String(edit_party[s])
	var c := PanelContainer.new()
	c.name = "EditSeat%d" % s
	c.custom_minimum_size = Vector2(272, 176)
	c.add_theme_stylebox_override("panel", _Shell.box(DangoTheme.CREAM_RAISED if key != "" else Color("E8D6B4"), DangoTheme.LINE, 20, 3, 12))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	c.add_child(v)
	if key == "":
		var t := _Shell.label("Pick an Axie", 18, DangoTheme.INK_ON_CREAM_MUTED, true)
		t.size_flags_vertical = Control.SIZE_EXPAND_FILL
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(t)
	else:
		var def: Dictionary = ContentDB.heroes.get(key, {})
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 10)
		v.add_child(top)
		var pic := TextureRect.new()
		pic.custom_minimum_size = Vector2(52, 52)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.texture = MockupAssets.tex("assets/portrait/%s.png" % String(def.get("cls", "")))
		top.add_child(pic)
		var names := VBoxContainer.new()
		names.add_child(_Shell.label(String(def.get("n", key)), 19, DangoTheme.INK, true))
		names.add_child(_Shell.label(String(def.get("cls", "")).capitalize(), 12, DangoTheme.INK_ON_CREAM_MUTED))
		top.add_child(names)
		var sp := Control.new()
		sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(sp)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	var swap := _Shell.button("Swap" if key != "" else "Pick", 0, 36)
	swap.name = "Swap"
	swap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	swap.pressed.connect(_show_picker.bind(s))
	row.add_child(swap)
	var clr := _Shell.button("Clear", 0, 36)
	clr.name = "Clear"
	clr.disabled = key == ""
	clr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clr.pressed.connect(set_edit_seat.bind(s, ""))
	row.add_child(clr)
	return c


func _pick_keys() -> Array[String]:
	var keys: Array[String] = []
	keys.append_array(MainMenu.T1_HERO_KEYS)
	for entry in MetaState.vault:
		var k := MetaState.vault_key(entry)
		if ContentDB.heroes.has(k) and not MetaState.vault_stale(entry) and not keys.has(k):
			keys.append(k)
	return keys


func _show_picker(slot: int) -> void:
	close_modal()
	var dim := ColorRect.new()
	dim.name = "Picker"
	dim.color = DangoTheme.SCRIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.offset_left = 200
	dim.offset_right = -200
	dim.offset_top = 116 + 68
	dim.offset_bottom = -84
	_shell["modal_layer"].add_child(dim)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(c)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _Shell.box(DangoTheme.CREAM, DangoTheme.LINE, 20, 4, 16))
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var back := _Shell.button("← Back", 120, 44)
	back.pressed.connect(close_modal)
	head.add_child(back)
	head.add_child(_Shell.label("  Team presets › Slot %d" % (slot + 1), 24, DangoTheme.INK, true))
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	v.add_child(g)
	for k in _pick_keys():
		var def: Dictionary = ContentDB.heroes[k]
		var taken: bool = edit_party.has(k) and edit_party.find(k) != slot
		var b := _Shell.button("%s\n%s" % [String(def.get("n", k)), String(def.get("cls", "")).capitalize()], 124, 80)
		b.name = "Tile_" + k
		b.disabled = taken
		b.tooltip_text = "Already in another slot" if taken else ""
		b.pressed.connect(func() -> void:
			if set_edit_seat(slot, k):
				close_modal())
		g.add_child(b)
