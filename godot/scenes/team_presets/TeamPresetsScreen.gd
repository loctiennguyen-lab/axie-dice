class_name TeamPresetsScreen
extends Control
## M2 Team presets (House, key 2). UI-05 b23 lane S4a: frames t01-t09 of design/handoffs/ui-05-figma/round-3/ui05-land-screens.html,
## parts in ui5/Ui5PresetParts.gd; node names = the frames' data-names.
## Grid of saved teams (MetaState.team_presets via TeamPresets, persisted by SaveStore): Use for next
## run (hands the party to Run Setup through MainMenu.pending_team), Edit / Copy / Delete, a 600
## delete confirm with focus on "Keep it", an editor (name 16 chars + 5 seats, Save disabled with the
## reason), and a read-only "Sample teams" tab fed by ContentDB.GUIDES.
## Not built: mouse drag of the handle (Alt + Left/Right on a focused card reorders), the
## "Best Ascension won with it" line (no per-team result history exists), house thumbnail.

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
var _orig_name := ""
var _orig_party: Array = []
var _pick_slot := -1
var _pick_sel := ""
var _pick_class := ""
## What to focus after the picker body is rebuilt: a hero key (its tile) or "" (the active class tab).
var _pick_focus := ""
var _focus_name := false
var _put_btn: Button
var _pick_grid_host: VBoxContainer


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
	var cur := (_shell["col"] as Control).find_child("Currencies", true, false)
	if cur != null:   # the frames draw no wallet in this header
		cur.get_parent().remove_child(cur)
		cur.free()
	(_shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	(_shell["back"] as Control).name = "BackButton"
	(_shell["sub"] as Control).name = "SubLine"
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
	if k.is_action_pressed(&"menu_back"):
		var ml := _shell["modal_layer"] as Control
		if ml.get_child_count() > 0 and not (view == "editor" and ml.get_child_count() == 1):
			if Ui5PresetParts.kind_of(ml.get_child(ml.get_child_count() - 1)) == &"picker":
				_close_picker()
			else:
				close_modal()   # a confirm (on top of the editor or alone)
		elif view == "editor":
			request_cancel()
		else:
			_on_back()
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()
	elif not k.alt_pressed and not k.ctrl_pressed and not k.meta_pressed and view == "grid" \
			and (_shell["modal_layer"] as Control).get_child_count() == 0 and k.keycode in [KEY_E, KEY_S, KEY_M]:
		if k.keycode == KEY_S:
			switch_tab("samples")
		elif k.keycode == KEY_M:
			switch_tab("mine")
		elif tab == "mine" and _focus_idx >= 0 and _focus_idx < TeamPresets.count():
			open_editor(_focus_idx)
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()
	elif k.alt_pressed and (k.keycode == KEY_LEFT or k.keycode == KEY_RIGHT) and view == "grid" and tab == "mine":
		reorder(_focus_idx, -1 if k.keycode == KEY_LEFT else 1)
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


func _on_back() -> void:
	if view == "editor":
		request_cancel()
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
	tab = "mine"
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
	_orig_name = edit_name
	_orig_party = edit_party.duplicate()
	view = "editor"
	_focus_name = true
	last_error = ""
	refresh()


func cancel_editor() -> void:
	view = "grid"
	_pick_slot = -1
	UI3Meta.clear(_shell["modal_layer"])
	refresh()


## True when the editor differs from what it opened with.
func is_dirty() -> bool:
	return edit_name != _orig_name or edit_party != _orig_party


## Cancel / Esc / Back in the editor: closes at once, or asks first when there are unsaved changes.
func request_cancel() -> void:
	if not is_dirty():
		cancel_editor()
		return
	var keep := UI3.button("Keep editing", &"secondary", &"M")
	keep.name = "KeepEditingButton"
	keep.pressed.connect(close_modal)
	var dis := UI3.button("Discard", &"danger", &"M")
	dis.name = "DiscardButton"
	dis.pressed.connect(cancel_editor)
	Ui5PresetParts.confirm(_shell["modal_layer"], "DiscardConfirm", "Discard changes?", "This team has changes you have not saved.", keep, dis)
	_focus_later(keep)   # the safe button


## Picker rule (spec 33): a Vault Axie that sits in another slot swaps places with whatever is in `slot`; a starter is copied.
func swap_edit_seat(slot: int, key: String) -> bool:
	if slot < 0 or slot >= TeamPresets.PARTY_SIZE or not TeamPresets.seat_ok(key):
		return false
	var other := edit_party.find(key)
	if other >= 0 and other != slot and not TeamPresets.may_repeat(key):
		edit_party[other] = edit_party[slot]
	edit_party[slot] = key
	if view == "editor":
		refresh()
	return true


func set_edit_name(n: String) -> void:
	edit_name = n.substr(0, TeamPresets.NAME_MAX)
	_refresh_editor_state()


func set_edit_seat(slot: int, key: String) -> bool:
	if slot < 0 or slot >= TeamPresets.PARTY_SIZE:
		return false
	if key != "":
		if not TeamPresets.seat_ok(key):
			return false
		if TeamPresets.seat_taken(edit_party, slot, key):
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
	var keep := UI3.button("Keep it", &"secondary", &"M")
	keep.name = "KeepItButton"
	keep.pressed.connect(close_modal)
	var del := UI3.button("Delete preset", &"danger", &"M")
	del.name = "DeletePresetButton"
	del.pressed.connect(confirm_delete)
	Ui5PresetParts.confirm(_shell["modal_layer"], "DeleteConfirm", "Delete \"%s\"?" % nm,
		"The preset is removed. Your Axies stay in the Vault and the starter roster. This cannot be undone.", keep, del)
	_focus_later(keep)   # the safe button: nothing is deleted without the second, danger button


func confirm_delete() -> void:
	TeamPresets.remove(_delete_idx)
	_delete_idx = -1
	UI3Meta.clear(_shell["modal_layer"])
	view = "grid"
	refresh()


## Closes the topmost modal only (a confirm or the picker can sit on top of the editor).
func close_modal() -> void:
	var ml := _shell["modal_layer"] as Control
	if ml.get_child_count() > 0:
		var top := ml.get_child(ml.get_child_count() - 1)
		ml.remove_child(top)
		top.queue_free()


func reorder(i: int, dir: int) -> void:
	var j := TeamPresets.move(i, dir)
	_focus_idx = j
	refresh()


# ------------------------------------------------------------ drawing (UI-05 b23 lane S4a, frames t01-t09)

func refresh() -> void:
	if _body == null:
		return
	UI3Meta.clear(_body)
	UI3Meta.clear(_shell["banner_host"])
	UI3Meta.clear(_tabs_box)
	var sub: Label = _shell["sub"]
	if guest:
		(_shell["banner_host"] as Control).add_child(Ui5PresetParts.guest_banner("Presets are saved on this computer only.",
			"Sign in to keep them across devices.", func() -> void:
				if is_inside_tree() and not no_scene_change:
					LandNav.open(&"account")))
	_remove_editor_modal()
	var bar := Ui5TabBar.new()
	bar.setup(["My teams", "Sample teams"], 0 if tab == "mine" else 1, true)
	bar.get_node("Tab0").name = "MyTeamsTab"
	bar.get_node("Tab1").name = "SampleTeamsTab"
	(bar.get_node("MyTeamsTab") as Button).tooltip_text = "My teams · M"
	(bar.get_node("SampleTeamsTab") as Button).tooltip_text = "Sample teams · S"
	bar.tab_selected.connect(func(i: int) -> void: switch_tab("mine" if i == 0 else "samples"))
	_tabs_box.add_child(bar)
	if tab == "samples":
		sub.text = "From Guides"
		_body.add_child(UI3Meta.scroll(_build_samples()))
	else:
		sub.text = "%d of %d slots used%s" % [TeamPresets.count(), TeamPresets.slot_count(),
			" · more at higher Land tiers" if TeamPresets.slot_count() < TeamPresets.MAX_SLOTS else ""]
		_body.add_child(_build_empty() if TeamPresets.count() == 0 else UI3Meta.scroll(_build_grid()))
	if view == "editor":
		_add_editor_modal()


func _build_empty() -> Control:
	var c := CenterContainer.new()
	c.name = "EmptyHost"
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.name = "EmptyState"
	v.add_theme_constant_override("separation", UI3Theme.space("24"))
	v.custom_minimum_size.x = UI3Theme.size_of("defeat_panel_w")
	c.add_child(v)
	var t := Ui5Text.label("No saved teams yet", "text_banner", "text", true)
	t.name = "EmptyTitle"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var d := Ui5Text.label("Save a party of 5 here and load it in Run Setup with one press. You have %d preset slots at %s Land." % [TeamPresets.slot_count(), TeamPresets.tier_name()], "text_body", "text_muted")
	d.name = "EmptyBody"
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(d)
	var b := UI3.button("Build your first team", &"primary", &"L")
	b.name = "BuildButton"
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(open_editor.bind(-1))
	v.add_child(b)
	if view != "editor":
		_focus_later(b)
	return c


func _build_grid() -> Control:
	var g := GridContainer.new()
	g.name = "Grid"
	g.columns = 3   # 3 / 6 / 9 slots by Land tier = 3 x 3 at most
	g.add_theme_constant_override("h_separation", UI3Theme.space("16"))
	g.add_theme_constant_override("v_separation", UI3Theme.space("16"))
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var open_n := TeamPresets.slot_count()
	for n in TeamPresets.MAX_SLOTS:
		if n < TeamPresets.count():
			g.add_child(_preset_card(n), true)
		elif n < open_n:
			g.add_child(_open_card(n), true)
		else:
			g.add_child(_locked_card(n + 1), true)
	return g


func _focus_later(c: Control) -> void:
	(func() -> void:
		if is_instance_valid(c) and c.is_inside_tree():
			c.grab_focus()).call_deferred()


## A grid cell: equal share of the width, one height for every cell.
func _cell(kind := &"card", node_name := "TeamCard") -> PanelContainer:
	var p := UI3.plate(kind)
	p.name = node_name
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size = Vector2(0, int(round(UI3Theme.size_of("seat") * 2.4)))
	return p


func _locked_card(n: int) -> Control:
	var p := _cell(&"row", "LockedSlot")
	p.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("chip"), UI3Theme.radius("l"), 2, UI3Theme.color("plate_rim"),
		Vector4(UI3Theme.space("20"), UI3Theme.space("16"), UI3Theme.space("20"), UI3Theme.space("16"))))
	p.set_meta("slot", n)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	p.add_child(v)
	var lock := TextureRect.new()
	lock.name = "LockIcon"
	lock.texture = UI3.icon("ui_lock")
	lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock.custom_minimum_size = Vector2.ONE * UI3Theme.size_of("icon_m")
	lock.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	lock.modulate.a = 0.7
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(lock)
	var a := Ui5Text.label("Preset slot %d" % n, "text_title", "text_muted", true)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(a)
	var b := Ui5Text.label("Opens at %s Land" % String(TeamPresets.TIER_NAME.get(TeamPresets.tier_for_slot(n), "")), "text_body", "text_muted")
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(b)
	return p


func _open_card(n: int) -> Control:
	var p := _cell(&"row", "OpenSlot")
	p.set_meta("slot", n + 1)
	var b := UI3.button("+  New team", &"secondary", &"M")
	b.name = "NewButton"
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(open_editor.bind(-1))
	p.add_child(b)
	return p


func _preset_card(i: int) -> Control:
	var e: Dictionary = MetaState.team_presets[i]
	var miss := TeamPresets.missing_count(e)
	var p := _cell(&"card", "TeamCard")
	p.set_meta("index", i)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("8"))
	p.add_child(v)
	v.add_child(Ui5PresetParts.seats(e["party"], func(k: String) -> bool: return not TeamPresets.seat_ok(k)))
	var names: Array[String] = []
	for k in (e["party"] as Array):
		if TeamPresets.seat_ok(String(k)):
			names.append(Ui5PresetParts.hero_name(String(k)))
	var head := HBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", UI3Theme.space("12"))
	v.add_child(head)
	var nm := Ui5Text.label("", "text_title", "text", true)
	nm.name = "Name"
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # takes the free width: "…" only when truly too long
	nm.clip_text = true
	nm.custom_minimum_size.x = 0
	head.add_child(nm)
	Ui5Ellipsis.set_text(nm, String(e["name"]))
	var cnt := Ui5Text.label("%d / 5" % (5 - miss), "text_body", "text_muted")
	cnt.name = "Count"
	head.add_child(cnt)
	if TeamPresets.has_nft(e):
		head.add_child(Ui5PresetParts.nft_tag())
	var line := Ui5Text.label("", "text_body", "danger_text" if miss > 0 else "text_muted")
	line.name = "NamesLine"
	line.clip_text = true
	line.custom_minimum_size.x = 0
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(line)
	Ui5Ellipsis.set_text(line, " · ".join(names) if miss == 0 else "%d of 5 seats empty: the Axie left your Vault" % miss)
	var row := HFlowContainer.new()
	row.name = "Actions"
	row.add_theme_constant_override("h_separation", UI3Theme.space("12"))
	row.add_theme_constant_override("v_separation", UI3Theme.space("8"))
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = FlowContainer.ALIGNMENT_BEGIN
	v.add_child(row)
	var use := UI3.button("Pick a replacement" if miss > 0 else "Use for next run", &"secondary", &"S")
	use.name = "UseButton"
	if miss > 0:
		use.pressed.connect(open_editor.bind(i))
	else:
		use.pressed.connect(use_preset.bind(i))
	use.focus_entered.connect(func() -> void: _focus_idx = i)
	row.add_child(use)
	for a in [["EditButton", "Edit", open_editor.bind(i), &"secondary", "Edit · E"], ["CopyButton", "Copy", copy_preset.bind(i), &"quiet", ""],
			["DeleteButton", "Delete", request_delete.bind(i), &"quiet", ""]]:
		var b := UI3.button(a[1], a[3], &"S")
		b.name = a[0]
		b.tooltip_text = a[4]
		b.pressed.connect(a[2])
		b.focus_entered.connect(func() -> void: _focus_idx = i)
		row.add_child(b)
	if i == 0 and view != "editor":
		_focus_later(use)
	return p


func _build_samples() -> Control:
	var v := VBoxContainer.new()
	v.name = "Samples"
	v.add_theme_constant_override("separation", UI3Theme.space("16"))
	var intro := Ui5Text.label("Read-only. Four compositions from Guides that work for new players. \"Use this team\" loads it into Run Setup with starter Axies.", "text_body", "text_muted")
	intro.name = "Intro"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(intro)
	var g := GridContainer.new()
	g.name = "SampleGrid"
	g.columns = 2
	g.add_theme_constant_override("h_separation", UI3Theme.space("16"))
	g.add_theme_constant_override("v_separation", UI3Theme.space("16"))
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(g)
	for i in ContentDB.GUIDES.size():
		var gd: Dictionary = ContentDB.GUIDES[i]
		var c := _cell(&"card", "SampleCard")
		c.set_meta("index", i)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", UI3Theme.space("8"))
		c.add_child(cv)
		var tl := Ui5Text.label(String(gd.get("n", "")).capitalize(), "text_title", "text", true)
		tl.name = "Name"
		cv.add_child(tl)
		cv.add_child(Ui5PresetParts.seats(gd.get("team", []), func(k: String) -> bool: return not ContentDB.heroes.has(k)))
		var why := Ui5Text.label(String(gd.get("why", "")), "text_body", "text_muted")
		why.name = "Why"
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(why)
		var use := UI3.button("Use this team", &"secondary", &"S")
		use.name = "UseButton"
		use.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		use.pressed.connect(use_sample.bind(i))
		cv.add_child(use)
		g.add_child(c, true)
		if i == 0:
			_focus_later(use)
	return v


# ------------------------------------------------------------ modals

func _modal_of(kind: StringName) -> Control:
	for c in (_shell["modal_layer"] as Control).get_children():
		if Ui5PresetParts.kind_of(c) == kind:
			return c
	return null


func _remove_editor_modal() -> void:
	var ed := _modal_of(&"editor")
	if ed != null:
		ed.get_parent().remove_child(ed)
		ed.queue_free()


## Editor (t04 / t08): EditorModal = Title, Name row (NameField + count), Seats (five SeatRow), Footer
## [DeleteButton (existing presets only)] ... [CancelButton] [SaveButton]. Esc = Cancel, asks first when dirty.
func _add_editor_modal() -> void:
	var layer := _shell["modal_layer"] as Control
	var c := Ui5PresetParts.modal_root(layer, &"editor")
	layer.move_child(c.get_parent(), 0)   # under any picker / confirm
	var p := UI3.plate(&"dialog")
	p.name = "EditorModal"
	p.custom_minimum_size.x = UI3Theme.size_of("defeat_panel_w")
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("20"))
	p.add_child(v)
	var ttl := Ui5Text.label("Edit team" if edit_index >= 0 else "New team", "text_banner", "text", true)
	ttl.name = "Title"
	v.add_child(ttl)
	var nrow := HBoxContainer.new()
	nrow.add_theme_constant_override("separation", UI3Theme.space("16"))
	v.add_child(nrow)
	nrow.add_child(Ui5Text.label("Name", "text_title", "text", true))
	_name_edit = LineEdit.new()
	_name_edit.name = "NameField"
	_name_edit.max_length = TeamPresets.NAME_MAX
	_name_edit.text = edit_name
	_name_edit.custom_minimum_size = Vector2(0, UI3Theme.size_of("field_h"))
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fpad := UI3Theme.space("16")
	var fbox := UI3Theme.flat(UI3Theme.color("field_bg"), UI3Theme.radius("m"), 3, UI3Theme.color("accent"), Vector4(fpad, 0, fpad, 0))
	_name_edit.add_theme_stylebox_override("normal", fbox)
	_name_edit.add_theme_stylebox_override("focus", fbox)
	_name_edit.text_changed.connect(set_edit_name)
	nrow.add_child(_name_edit)
	_count_lbl = Ui5Text.label("", "text_body", "text_muted")
	_count_lbl.name = "Count"
	nrow.add_child(_count_lbl)
	var rows := VBoxContainer.new()
	rows.name = "Seats"
	rows.add_theme_constant_override("separation", UI3Theme.space("8"))
	for sl in TeamPresets.PARTY_SIZE:
		rows.add_child(_edit_seat(sl), true)
	var sc := UI3Meta.scroll(rows)
	sc.name = "SeatsScroll"
	sc.custom_minimum_size.y = rows.get_combined_minimum_size().y
	v.add_child(sc)
	_fit_editor.call_deferred(p, sc, rows)
	var foot := HBoxContainer.new()
	foot.name = "Footer"
	foot.add_theme_constant_override("separation", UI3Theme.space("16"))
	v.add_child(foot)
	if edit_index >= 0:
		var del := UI3.button("Delete", &"danger", &"M")
		del.name = "DeleteButton"
		del.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		del.pressed.connect(request_delete.bind(edit_index))
		foot.add_child(del)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(sp)
	var cancel := UI3.button("Cancel", &"secondary", &"M")
	cancel.name = "CancelButton"
	cancel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cancel.pressed.connect(request_cancel)
	foot.add_child(cancel)
	_save_btn = UI3.button("Save team", &"primary", &"L")
	_save_btn.name = "SaveButton"
	_save_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_save_btn.pressed.connect(save_editor)
	foot.add_child(_save_btn)
	_refresh_editor_state()
	if _focus_name:
		_focus_name = false
		_focus_later(_name_edit)


## The editor never grows past the screen: when the dialog is taller than the room (1280 raises the text to 14 real px),
## the Seats list scrolls inside it.
func _fit_editor(dlg: Control, sc: ScrollContainer, rows: Control) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(dlg) or not is_instance_valid(sc) or not dlg.is_inside_tree():
		return
	var room := size.y - UI3Theme.space("40") * 2.0
	var over := dlg.size.y - room
	if over > 0.5:
		sc.custom_minimum_size.y = maxf(sc.size.y - over, UI3Theme.size_of("seat") * 1.5)


func _refresh_editor_state() -> void:
	if _count_lbl != null:
		_count_lbl.text = "%d / %d" % [edit_name.length(), TeamPresets.NAME_MAX]
	if _save_btn != null:
		var why := save_block_reason()
		if why == "":
			Ui5DisabledReason.clear(_save_btn)
		else:
			Ui5DisabledReason.apply(_save_btn, "Save team · " + why)


## One SeatRow: Portrait (seat x 0.7), Slot n / hero / class, SwapButton (Pick when empty), ClearButton.
func _edit_seat(s: int) -> Control:
	var key := String(edit_party[s])
	var c := PanelContainer.new()
	c.name = "SeatRow"
	c.set_meta("slot", s)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("plate_raised"), UI3Theme.radius("m"), 0, Color.TRANSPARENT,
		Vector4(UI3Theme.space("12"), UI3Theme.space("8"), UI3Theme.space("12"), UI3Theme.space("8"))))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	c.add_child(h)
	h.add_child(Ui5PresetParts.portrait(key, int(round(UI3Theme.size_of("seat") * 0.7))))
	var v := VBoxContainer.new()
	v.name = "Txt"
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(v)
	v.add_child(Ui5Text.label("Slot %d" % (s + 1), "text_body", "text_muted"))
	var nl := Ui5Text.label(Ui5PresetParts.hero_name(key) if key != "" else "Empty slot", "text_body", "text", true)
	nl.name = "SeatName"
	nl.clip_text = true
	nl.custom_minimum_size.x = 0
	v.add_child(nl)
	if key != "":
		v.add_child(Ui5Text.label(Ui5PresetParts.class_name_of(key), "text_body", "text_muted"))
	var swap := UI3.button("Swap" if key != "" else "Pick", &"secondary", &"S")
	swap.name = "SwapButton"
	swap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swap.pressed.connect(_show_picker.bind(s))
	h.add_child(swap)
	var clr := UI3.button("Clear", &"quiet", &"S")
	clr.name = "ClearButton"
	clr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	clr.disabled = key == ""
	clr.pressed.connect(set_edit_seat.bind(s, ""))
	h.add_child(clr)
	return c


func _pick_keys() -> Array[String]:
	var keys: Array[String] = []
	keys.append_array(MainMenu.T1_HERO_KEYS)
	for entry in MetaState.vault:
		var k := MetaState.vault_key(entry)
		if ContentDB.heroes.has(k) and not MetaState.vault_stale(entry) and not keys.has(k):
			keys.append(k)
	return keys


## Picker (t05): PresetPicker = Title, class tabs (AllTab, PlantTab ...), 6-column AxieTile grid, [CancelButton + Space]
## [PutButton]. Nothing is picked when it opens (PutButton disabled and says why), Cancel has the focus.
## A Vault Axie already in another slot is drawn at 60% and swaps places when chosen; starters can repeat.
func _show_picker(slot: int) -> void:
	_close_picker()
	_pick_slot = slot
	_pick_sel = ""
	_pick_class = ""
	_pick_focus = "-"
	var c := Ui5PresetParts.modal_root(_shell["modal_layer"], &"picker")
	var p := UI3.plate(&"dialog")
	p.name = "PresetPicker"
	p.custom_minimum_size.x = UI3Theme.size_of("picker_w")
	c.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("20"))
	p.add_child(v)
	var ttl := Ui5Text.label("Choose an Axie for slot %d" % (slot + 1), "text_banner", "text", true)
	ttl.name = "Title"
	v.add_child(ttl)
	_pick_grid_host = VBoxContainer.new()
	_pick_grid_host.name = "PickBody"
	_pick_grid_host.add_theme_constant_override("separation", UI3Theme.space("20"))
	v.add_child(_pick_grid_host)
	var foot := HBoxContainer.new()
	foot.name = "Footer"
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_theme_constant_override("separation", UI3Theme.space("16"))
	v.add_child(foot)
	var cancel := UI3.button("Cancel", &"secondary", &"M")
	cancel.name = "CancelButton"
	cancel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cancel.pressed.connect(_close_picker)
	foot.add_child(cancel)
	_put_btn = UI3.button("Put in slot %d" % (slot + 1), &"primary", &"L")
	_put_btn.name = "PutButton"
	_put_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_put_btn.pressed.connect(_put_in_slot)
	foot.add_child(_put_btn)
	_draw_picker_body()
	Ui5PresetParts.attach_space_cap(cancel)
	_focus_later(cancel)


func _close_picker() -> void:
	var pk := _modal_of(&"picker")
	if pk != null:
		pk.get_parent().remove_child(pk)
		pk.queue_free()
	_pick_slot = -1
	_put_btn = null
	_pick_grid_host = null


func _put_in_slot() -> void:
	if _pick_slot < 0 or _pick_sel == "":
		return
	var slot := _pick_slot
	var key := _pick_sel
	_close_picker()
	swap_edit_seat(slot, key)


func set_pick_class(cls: String) -> void:
	_pick_class = cls
	_pick_focus = ""
	_draw_picker_body()


func _draw_picker_body() -> void:
	if _pick_grid_host == null:
		return
	UI3Meta.clear(_pick_grid_host)
	var keys := _pick_keys()
	var classes: Array[String] = []
	for k in keys:
		var cl := String((ContentDB.heroes[k] as Dictionary).get("cls", ""))
		if not classes.has(cl):
			classes.append(cl)
	var labels: Array = ["All"]
	for cl in classes:
		labels.append(cl.capitalize())
	var bar := Ui5TabBar.new()
	bar.setup(labels, 0 if _pick_class == "" else 1 + classes.find(_pick_class), true)
	for i in labels.size():
		bar.get_node("Tab%d" % i).name = "%sTab" % String(labels[i])
	bar.tab_selected.connect(func(i: int) -> void: set_pick_class("" if i == 0 else classes[i - 1]))
	_pick_grid_host.add_child(bar)
	var g := GridContainer.new()
	g.name = "PickGrid"
	g.columns = 6
	g.add_theme_constant_override("h_separation", UI3Theme.space("12"))
	g.add_theme_constant_override("v_separation", UI3Theme.space("12"))
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var shown := 0
	for k in keys:
		var def: Dictionary = ContentDB.heroes[k]
		if _pick_class != "" and String(def.get("cls", "")) != _pick_class:
			continue
		g.add_child(_pick_tile(k, def), true)
		shown += 1
	# Inner padding so the selected tile's ring is not clipped by the scroll area.
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, UI3Theme.space("4"))
	pad.add_child(g)
	var sc := UI3Meta.scroll(pad)
	sc.custom_minimum_size = Vector2(0, int(round(UI3Theme.size_of("picker_tile") * 1.5)))
	_pick_grid_host.add_child(sc)
	if shown == 0:
		_pick_grid_host.add_child(Ui5Text.label("No Axies of this class yet", "text_body", "text_muted"))
	_refresh_put()
	_focus_picker_after_rebuild.call_deferred(bar, g)


## The rebuild drops the focused control: put the focus back on the tile just chosen, or on the active class tab.
func _focus_picker_after_rebuild(bar: Control, g: Control) -> void:
	if _pick_grid_host == null or not is_instance_valid(bar) or not bar.is_inside_tree() or _pick_focus == "-":
		return
	if _pick_focus != "":
		for t in g.get_children():
			if String(t.get_meta("hero", "")) == _pick_focus:
				(t as Control).grab_focus()
				return
	var i := 0 if _pick_class == "" else 1 + _pick_classes().find(_pick_class)
	(bar.get_child(i) as Control).grab_focus()


func _pick_classes() -> Array[String]:
	var out: Array[String] = []
	for k in _pick_keys():
		var cl := String((ContentDB.heroes[k] as Dictionary).get("cls", ""))
		if not out.has(cl):
			out.append(cl)
	return out


func _refresh_put() -> void:
	if _put_btn == null:
		return
	if _pick_sel == "":
		Ui5DisabledReason.apply(_put_btn, "Pick an Axie first")
	else:
		Ui5DisabledReason.clear(_put_btn)


func _pick_tile(k: String, def: Dictionary) -> Control:
	var other := edit_party.find(k)
	var in_other: bool = other >= 0 and other != _pick_slot and not TeamPresets.may_repeat(k)
	var b := UI3.button("", &"secondary", &"M")
	b.name = "AxieTile"
	b.set_meta("hero", k)
	b.toggle_mode = true
	b.button_pressed = k == _pick_sel
	b.custom_minimum_size = Vector2(0, int(round(UI3Theme.size_of("picker_tile") * 1.4)))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.tooltip_text = "In slot %d: choosing it swaps" % (other + 1) if in_other else ""
	var r := UI3Theme.radius("m")
	var off := UI3Theme.flat(UI3Theme.color("plate_raised"), r)
	var on := UI3Theme.flat(UI3Theme.color("btn_secondary"), r, 3, UI3Theme.color("selected"))
	for st in ["normal", "hover", "disabled"]:
		b.add_theme_stylebox_override(st, off)
	for st in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, on)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := UI3Theme.space("8")
	v.offset_left = m
	v.offset_right = -m
	v.offset_top = m
	v.offset_bottom = -m
	v.add_theme_constant_override("separation", UI3Theme.space("4"))
	if in_other:
		v.modulate.a = 0.6
	b.add_child(v)
	var pic := Ui5PresetParts.portrait(k, 0)
	pic.custom_minimum_size = Vector2.ZERO
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(pic)
	var nm := Ui5Text.label(Ui5PresetParts.hero_name(k), "text_body", "text", true)
	nm.name = "HeroName"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	nm.custom_minimum_size.x = 0
	v.add_child(nm)
	Ui5Ellipsis.set_text(nm, nm.text)
	var sub := Ui5Text.label("Tier %d · HP %d%s" % [int(def.get("tier", 1)), int(def.get("max_hp", 0)), " · swaps" if in_other else ""], "text_body", "text_muted")
	sub.name = "HeroInfo"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.clip_text = true
	sub.custom_minimum_size.x = 0
	v.add_child(sub)
	Ui5Ellipsis.set_text(sub, sub.text)
	b.pressed.connect(func() -> void:
		_pick_sel = k
		_pick_focus = k
		_draw_picker_body())
	return b
