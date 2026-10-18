class_name TeamPresetsScreen
extends Control
## M2 Team presets (House, key 2). Spec: design/handoffs/ui-02-round3 README section 2 M2, frames M2a-M2f.
## Grid of saved teams (MetaState.team_presets via TeamPresets, persisted by SaveStore): Use for next
## run (hands the party to Run Setup through MainMenu.pending_team), Edit / Copy / Delete, a 600
## delete confirm with focus on "Keep it", an editor (name 16 chars + 5 seats, Save disabled with the
## reason), and a read-only "Sample teams" tab fed by ContentDB.GUIDES.
## Not built: mouse drag of the handle (Alt + Left/Right on a focused card reorders), the
## "Best Ascension won with it" line (no per-team result history exists), house thumbnail.

const SEAT := 160   # largest square Axie preview (spec 27)
const TILE_H := 284.0

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
	_shell = UI3Meta.build(self, "Team presets", "", _on_back)
	_tabs_box = _shell["header_right"]
	_tabs_box.name = "Tabs"
	_body = MarginContainer.new()
	_body.name = "Body"
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	(_shell["col"] as Control).add_child(_body)


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
	elif not k.alt_pressed and not k.ctrl_pressed and not k.meta_pressed and view == "grid" \
			and (_shell["modal_layer"] as Control).get_child_count() == 0 and k.keycode in [KEY_E, KEY_S, KEY_M]:
		if k.keycode == KEY_S:
			switch_tab("samples")
		elif k.keycode == KEY_M:
			switch_tab("mine")
		elif tab == "mine" and _focus_idx >= 0 and _focus_idx < TeamPresets.count():
			open_editor(_focus_idx)
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
	UI3Meta.confirm(_shell["modal_layer"], "Delete \"%s\"?" % nm,
		"The preset is removed. Your Axies stay in the Vault and the starter roster. This cannot be undone.",
		"Keep it", "Delete preset", confirm_delete, close_modal)


func confirm_delete() -> void:
	TeamPresets.remove(_delete_idx)
	_delete_idx = -1
	close_modal()
	refresh()


func close_modal() -> void:
	UI3Meta.clear(_shell["modal_layer"])


func reorder(i: int, dir: int) -> void:
	var j := TeamPresets.move(i, dir)
	_focus_idx = j
	refresh()


# ------------------------------------------------------------ drawing (UI-03 screen 27)

func refresh() -> void:
	if _body == null:
		return
	UI3Meta.clear(_body)
	UI3Meta.clear(_shell["banner_host"])
	UI3Meta.clear(_tabs_box)
	var sub: Label = _shell["sub"]
	if guest:
		UI3Meta.banner(_shell["banner_host"], "Presets are saved on this computer only.",
			"Sign in to keep them across devices.",
			[{"name": "SignIn", "text": "Sign in", "primary": true, "cb": func() -> void:
				if is_inside_tree() and not no_scene_change:
					LandNav.open(&"account")}])
	if view == "editor":
		sub.text = "› %s" % (edit_name if edit_name != "" else "New team")
		_body.add_child(UI3Meta.scroll(_build_editor()))
		return
	for t in [["mine", "My teams", "M"], ["samples", "Sample teams", "S"]]:
		var b := UI3Meta.tab(t[1], t[0] == tab, t[2])
		b.name = "Tab_" + String(t[0])
		b.pressed.connect(switch_tab.bind(t[0]))
		_tabs_box.add_child(b)
	if tab == "samples":
		sub.text = "From Guides"
		_body.add_child(UI3Meta.scroll(_build_samples()))
	else:
		sub.text = "%d of %d slots used%s" % [TeamPresets.count(), TeamPresets.slot_count(),
			" · more at higher Land tiers" if TeamPresets.slot_count() < TeamPresets.MAX_SLOTS else ""]
		_body.add_child(_build_empty() if TeamPresets.count() == 0 else UI3Meta.scroll(_build_grid()))


## Square Axie preview 160x160 (portrait + name); a missing Axie gets a red-8 frame and "Missing".
func _seat_cell(key: String, missing: bool) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(0, 0)
	p.theme = UI3Theme.get_theme()
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("danger_bg") if missing else UI3Theme.color("panel_raised"),
		8, 2 if missing else 0, UI3Theme.color("danger_text"), Vector4(8, 8, 8, 8)))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var def: Dictionary = ContentDB.heroes.get(key, {})
	var dot := TextureRect.new()
	dot.custom_minimum_size = Vector2(88, 88)
	dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not missing:
		dot.texture = MockupAssets.tex("assets/portrait/%s.png" % String(def.get("cls", "")))
	v.add_child(dot)
	var nm := UI3.label("Missing" if missing else String(def.get("n", key)))
	if missing:
		nm.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	v.add_child(nm)
	p.name = "Seat_missing" if missing else "Seat_" + key
	return p


## Five square previews in a row: each takes an equal share of the width (up to SEAT px) and stays square.
func _seat_row(keys: Array, missing_of: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for k in keys:
		var a := AspectRatioContainer.new()
		a.ratio = 1.0
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		a.custom_minimum_size = Vector2(64, 0)
		a.add_child(_seat_cell(String(k), missing_of.call(String(k))))
		row.add_child(a)
	return row


func _build_empty() -> Control:
	var c := CenterContainer.new()
	c.name = "Empty"
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("32"))   # body-to-button gap
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	var t := UI3.label("No saved teams yet", "LabelScreenTitle")
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var d := UI3.label("Save a party of 5 here and load it in Run Setup with one press. You have %d preset slots at %s Land." % [TeamPresets.slot_count(), TeamPresets.tier_name()], "LabelMuted")
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(560, 0)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(d)
	var b := UI3.button("Build your first team", &"primary", &"L")
	b.name = "BuildFirst"
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(open_editor.bind(-1))
	v.add_child(b)
	_focus_later(b)
	return c


func _build_grid() -> Control:
	var g := GridContainer.new()
	g.name = "Grid"
	g.columns = 3   # 3 / 6 / 9 slots by Land tier = 3 x 3 at most
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


func _focus_later(c: Control) -> void:
	(func() -> void:
		if is_instance_valid(c) and c.is_inside_tree():
			c.grab_focus()).call_deferred()


func _tile(kind := &"card") -> PanelContainer:
	var p := UI3.plate(kind)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.size_flags_stretch_ratio = 1.0
	p.custom_minimum_size = Vector2(0, TILE_H)   # all tiles the same height
	return p


func _locked_card(n: int) -> Control:
	var p := _tile(&"row")
	p.modulate.a = 0.6   # locked = 0.6 (components.md ListRow)
	p.name = "Locked%d" % n
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	var a := UI3.label("Preset slot %d" % n, "LabelTitle")
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(a)
	var b := UI3.label("Opens at %s Land" % String(TeamPresets.TIER_NAME.get(TeamPresets.tier_for_slot(n), "")), "LabelMuted")
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(b)
	return p


func _open_card(n: int) -> Control:
	var p := _tile(&"row")
	p.name = "Open%d" % (n + 1)
	var b := UI3.button("+  New team", &"secondary", &"M")
	b.name = "New%d" % (n + 1)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(open_editor.bind(-1))
	p.add_child(b)
	return p


func _preset_card(i: int) -> Control:
	var e: Dictionary = MetaState.team_presets[i]
	var miss := TeamPresets.missing_count(e)
	var p := _tile(&"card")
	p.name = "Preset%d" % i
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("4"))
	p.add_child(v)
	v.add_child(_seat_row(e["party"], func(k: String) -> bool: return not TeamPresets.seat_ok(k)))
	var names: Array[String] = []
	for k in (e["party"] as Array):
		if TeamPresets.seat_ok(String(k)):
			names.append(String((ContentDB.heroes.get(String(k), {}) as Dictionary).get("n", k)))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(head)
	var nm := UI3.label(String(e["name"]), "LabelTitle")
	nm.name = "Name"
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # takes the free width: ellipsis only when truly too long
	head.add_child(nm)
	head.add_child(UI3.label("%d / 5" % (5 - miss), "LabelMuted"))
	if TeamPresets.has_nft(e):
		head.add_child(UI3Meta.tag("NFT"))
	var line := UI3.label(" · ".join(names) if miss == 0 else "%d of 5 seats empty: the Axie left your Vault" % miss, "LabelMuted")
	line.name = "PartyLine"
	line.clip_text = true
	line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	line.custom_minimum_size.x = 0
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if miss > 0:
		line.add_theme_color_override("font_color", UI3Theme.color("danger_text"))
	v.add_child(line)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(row)
	var use := UI3.button("Pick a replacement" if miss > 0 else "Use for next run", &"secondary", &"S")
	use.name = "Use"
	if miss > 0:
		use.pressed.connect(open_editor.bind(i))
	else:
		use.pressed.connect(use_preset.bind(i))
	use.focus_entered.connect(func() -> void: _focus_idx = i)
	row.add_child(use)
	for a in [["Edit  E", open_editor.bind(i), &"secondary"], ["Copy", copy_preset.bind(i), &"quiet"], ["Delete", request_delete.bind(i), &"quiet"]]:
		var b := UI3.button(a[0], a[2], &"S")
		b.name = String(a[0]).split(" ")[0]
		b.pressed.connect(a[1])
		b.focus_entered.connect(func() -> void: _focus_idx = i)
		row.add_child(b)
	if i == 0:
		_focus_later(use)
	return p


func _build_samples() -> Control:
	var v := VBoxContainer.new()
	v.name = "Samples"
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	var intro := UI3.label("Read-only. Four compositions from Guides that work for new players. \"Use this team\" loads it into Run Setup with starter Axies.", "LabelMuted")
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
		var c := _tile(&"card")
		c.name = "Sample%d" % i
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", UI3Theme.space("8"))
		c.add_child(cv)
		cv.add_child(UI3.label(String(gd.get("n", "")).capitalize(), "LabelTitle"))
		cv.add_child(_seat_row(gd.get("team", []), func(k: String) -> bool: return not ContentDB.heroes.has(k)))
		var why := UI3.label(String(gd.get("why", "")))
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		why.custom_minimum_size.x = 400
		cv.add_child(why)
		var use := UI3.button("Use this team", &"secondary", &"S")
		use.name = "UseSample"
		use.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		use.pressed.connect(use_sample.bind(i))
		cv.add_child(use)
		g.add_child(c)
	return v


func _build_editor() -> Control:
	var v := VBoxContainer.new()
	v.name = "Editor"
	v.add_theme_constant_override("separation", UI3Theme.space("24"))
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", UI3Theme.space("16"))
	v.add_child(nrow)
	nrow.add_child(UI3.label("Name", "LabelTitle"))
	_name_edit = LineEdit.new()
	_name_edit.name = "NameEdit"
	_name_edit.max_length = TeamPresets.NAME_MAX
	_name_edit.text = edit_name
	_name_edit.custom_minimum_size = Vector2(400, 56)
	_name_edit.text_changed.connect(set_edit_name)
	nrow.add_child(_name_edit)
	_count_lbl = UI3.label("", "LabelMuted")
	nrow.add_child(_count_lbl)
	var seats := HBoxContainer.new()
	seats.add_theme_constant_override("separation", 16)
	v.add_child(seats)
	for s in TeamPresets.PARTY_SIZE:
		seats.add_child(_edit_seat(s))
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_theme_constant_override("separation", UI3Theme.space("16"))
	v.add_child(foot)
	var cancel := UI3.button("Cancel", &"secondary", &"M")
	cancel.name = "Cancel"
	cancel.custom_minimum_size.y = 56
	cancel.pressed.connect(cancel_editor)
	foot.add_child(cancel)
	_save_btn = UI3.button("Save team", &"primary", &"L")
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
		if why == "":
			UI3.clear_disabled_reason(_save_btn)
		else:
			UI3.set_disabled_reason(_save_btn, why)


func _edit_seat(s: int) -> Control:
	var key := String(edit_party[s])
	var c := UI3.plate(&"card" if key != "" else &"row")
	c.name = "EditSeat%d" % s
	c.custom_minimum_size = Vector2(272, 208)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	c.add_child(v)
	if key == "":
		var t := UI3.label("Pick an Axie", "LabelTitle")
		t.size_flags_vertical = Control.SIZE_EXPAND_FILL
		t.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(t)
	else:
		var def: Dictionary = ContentDB.heroes.get(key, {})
		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", UI3Theme.space("16"))
		v.add_child(top)
		var pic := TextureRect.new()
		pic.custom_minimum_size = Vector2(64, 64)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.texture = MockupAssets.tex("assets/portrait/%s.png" % String(def.get("cls", "")))
		top.add_child(pic)
		var names := VBoxContainer.new()
		names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nl := UI3.label(String(def.get("n", key)), "LabelTitle")
		nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		names.add_child(nl)
		names.add_child(UI3.label(String(def.get("cls", "")).capitalize(), "LabelMuted"))
		top.add_child(names)
		var sp := Control.new()
		sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(sp)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(row)
	var swap := UI3.button("Swap" if key != "" else "Pick", &"secondary", &"S")
	swap.name = "Swap"
	swap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	swap.pressed.connect(_show_picker.bind(s))
	row.add_child(swap)
	var clr := UI3.button("Clear", &"quiet", &"S")
	clr.name = "Clear"
	clr.disabled = key == ""
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
	var c := UI3Meta.scrim(_shell["modal_layer"], "Picker")
	var p := UI3.plate(&"dialog")
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	p.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI3Theme.space("16"))
	v.add_child(head)
	var back := UI3.button("← Back", &"secondary", &"S")
	back.pressed.connect(close_modal)
	head.add_child(back)
	head.add_child(UI3.label("Slot %d" % (slot + 1), "LabelTitle"))
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	v.add_child(g)
	for k in _pick_keys():
		var def: Dictionary = ContentDB.heroes[k]
		var taken: bool = edit_party.has(k) and edit_party.find(k) != slot
		var b := UI3.button("%s\n%s" % [String(def.get("n", k)), String(def.get("cls", "")).capitalize()], &"secondary", &"M")
		b.custom_minimum_size = Vector2(160, 80)
		b.name = "Tile_" + k
		b.disabled = taken
		b.tooltip_text = "Already in another slot" if taken else ""
		b.pressed.connect(func() -> void:
			if set_edit_seat(slot, k):
				close_modal())
		g.add_child(b)
	_focus_later(g.get_child(0) as Control)
