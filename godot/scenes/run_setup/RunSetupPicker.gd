class_name RunSetupPicker
extends RefCounted
## Run Setup popups moved out of RunSetup.gd (UI-05 b23 lane 0c): Leaderboard popup, Axie picker, Team presets
## (Load / Save). Code only moved: all state (`_picker_*`, `_presets_tab`, `lb_source`, `party`, ...) stays on the
## RunSetup screen (`_s`), which keeps same-name forwarders for every symbol tests and tools call.

var _s: RunSetup   # the RunSetup screen


func _init(screen: RunSetup) -> void:
	_s = screen


func open_picker(slot: int) -> void:
	_s._picker_slot = slot
	_s._picker_tab = "all"
	_s._picker_cls = "all"
	_s._picker_sel = ""
	_show_picker()


## UI-03 35: top 5 for the picked Ascension, own row pinned under them. States: loading, error, normal.
func _show_leaderboard_popup() -> void:
	var v := _s._modal_box(640, "LeaderboardPopup")
	var asc_n := _s.ascension
	v.add_child(_s._lbl(_s.tr("Leaderboard"), "LabelScreenTitle"))
	var sub := _s._lbl(_s.tr("Ascension %d · this season") % asc_n, "LabelMuted")
	sub.name = "LbSub"
	v.add_child(sub)
	var rows_box := VBoxContainer.new()
	rows_box.name = "LbRows"
	rows_box.add_theme_constant_override("separation", 8)
	v.add_child(rows_box)
	var loading := _s._lbl(_s.tr("Loading..."), "LabelMuted")
	rows_box.add_child(loading)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 16)
	acts.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(acts)
	var close := UI3.button(_s.tr("Close"), &"secondary", &"M")
	close.name = "CloseLeaderboard"
	close.pressed.connect(_s.close_modal)
	acts.add_child(close)
	var full := UI3.button(_s.tr("Full Leaderboard"), &"primary", &"M")
	full.name = "FullLeaderboard"
	full.pressed.connect(_s.open_full_leaderboard)
	acts.add_child(full)
	_s._focus_later(close)
	_lb_load(rows_box, acts, full, loading)


## Fetches the board into rows_box. On error "Try again" becomes the primary and "Full Leaderboard" drops to secondary.
func _lb_load(rows_box: VBoxContainer, acts: HBoxContainer, full: Button, loading: Control) -> void:
	var src: LeaderboardSource = _s.lb_source if _s.lb_source != null else LeaderboardSource.make_default()
	var asc_n := _s.ascension
	src.fetch({"asc": asc_n, "period": "season", "mode": _s.mode}, func(res: Dictionary) -> void:
		if not is_instance_valid(rows_box):
			return
		for c in rows_box.get_children():
			c.queue_free()
		if not bool(res.get("ok", false)):
			var e := _s._lbl(_s.tr("Can't load the board right now. Try again later."), "LabelMuted")
			e.name = "LbError"
			e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			rows_box.add_child(e)
			if is_instance_valid(full):
				acts.remove_child(full)
				full.queue_free()
			var full2 := UI3.button(_s.tr("Full Leaderboard"), &"secondary", &"M")
			full2.name = "FullLeaderboard"
			full2.pressed.connect(_s.open_full_leaderboard)
			acts.add_child(full2)
			var retry := UI3.button(_s.tr("Try again"), &"primary", &"M")
			retry.name = "LbRetry"
			retry.pressed.connect(func() -> void:
				for c in rows_box.get_children():
					c.queue_free()
				rows_box.add_child(_s._lbl(_s.tr("Loading..."), "LabelMuted"))
				acts.remove_child(retry)
				retry.queue_free()
				_lb_load(rows_box, acts, full2, null))
			acts.add_child(retry)
			_s._focus_later(retry)
			return
		var rows: Array = res.get("rows", [])
		if rows.is_empty():
			rows_box.add_child(_s._lbl(_s.tr("No scores yet this season."), "LabelMuted"))
		for i in mini(5, rows.size()):
			rows_box.add_child(_lb_row(rows[i], false))
		var me: Dictionary = res.get("me", {})
		if not me.is_empty():
			var mr := _lb_row(me, true)
			mr.name = "LbMe"
			rows_box.add_child(mr)
		if String(res.get("updated", "")) != "":
			rows_box.add_child(_s._lbl(_s.tr("Last updated %s") % String(res["updated"]), "LabelMuted")))


func _lb_row(r: Dictionary, own: bool) -> PanelContainer:
	var p := UI3.plate(&"plate")
	p.custom_minimum_size.y = 56
	if own:
		p.theme_type_variation = "PanelCardSelected"
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	p.add_child(h)
	var rk := _s._lbl("#%d" % int(r.get("rank", 0)), "LabelTitle")
	rk.custom_minimum_size.x = 64
	h.add_child(rk)
	var nm := _s._lbl(String(r.get("name", _s.tr("You"))).substr(0, 20), "LabelTitle")
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nm)
	h.add_child(_s._lbl(UI3.fmt(int(r.get("score", 0))), "LabelTitle"))
	return p


# ---------------------------------------------------------------- team presets (R3 M2)


## UI-03 34: one modal, two tabs (Load / Save current). Load rows are 72 high; a row with a missing Axie says so.
func _show_presets(tab: String) -> void:
	_s._presets_tab = tab
	var v := _s._modal_box(640, "LoadPresets" if tab == "load" else "SavePresetModal")
	v.add_child(_s._lbl(_s.tr("Team presets"), "LabelScreenTitle"))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	v.add_child(tabs)
	var tl := UI3.tab(_s.tr("Load"), tab == "load")
	tl.name = "TabLoad"
	tl.pressed.connect(func() -> void: _show_presets("load"))
	tabs.add_child(tl)
	var ts := UI3.tab(_s.tr("Save current"), tab == "save")
	ts.name = "TabSave"
	ts.pressed.connect(func() -> void: _show_presets("save"))
	tabs.add_child(ts)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 16)
	acts.alignment = BoxContainer.ALIGNMENT_END
	var cancel := UI3.button(_s.tr("Cancel"), &"secondary", &"M")
	cancel.name = "ClosePresets"
	cancel.pressed.connect(_s.close_modal)
	if tab == "load":
		_presets_load_body(v, acts)
	else:
		_presets_save_body(v, acts)
	v.add_child(acts)
	acts.add_child(cancel)
	acts.move_child(cancel, 0)
	if tab == "load":
		_s._focus_later(cancel)


func _presets_load_body(v: VBoxContainer, acts: HBoxContainer) -> void:
	if TeamPresets.count() == 0:
		var none := _s._lbl(_s.tr("No saved teams yet. Build one in Team presets (House)."), "LabelMuted")
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(none)
	var go := UI3.button(_s.tr("Load team"), &"primary", &"M")
	go.name = "ConfirmLoadPreset"
	UI3.set_disabled_reason(go, _s.tr("Load team") + " · " + _s.tr("Pick a team"))
	var rows: Array[Button] = []
	for i in TeamPresets.count():
		var e: Dictionary = MetaState.team_presets[i]
		var miss := TeamPresets.missing_count(e)
		var b := UI3.button("%s%s" % [String(e["name"]).substr(0, 20), " · %d seats empty" % miss if miss > 0 else ""], &"secondary", &"M")
		b.name = "Preset%d" % i
		b.custom_minimum_size.y = 72
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.pressed.connect(func() -> void:
			for o in rows:
				_s._outline(o, o == b)
			go.set_meta("preset", i)
			UI3.clear_disabled_reason(go))
		rows.append(b)
		v.add_child(b)
	go.pressed.connect(func() -> void:
		if go.has_meta("preset"):
			_s.load_preset(int(go.get_meta("preset"))))
	acts.add_child(go)


func _presets_save_body(v: VBoxContainer, acts: HBoxContainer) -> void:
	var edit := LineEdit.new()
	edit.name = "PresetName"
	edit.max_length = TeamPresets.NAME_MAX
	edit.text = "Team %d" % (TeamPresets.count() + 1)
	edit.custom_minimum_size = Vector2(0, 48)
	v.add_child(edit)
	var slotline := _s._lbl(_s.tr("Saves to slot %d") % (TeamPresets.count() + 1), "LabelMuted")
	v.add_child(slotline)
	var save := UI3.button(_s.tr("Save team"), &"primary", &"M")
	save.name = "ConfirmSavePreset"
	var refresh_save := func(_t := "") -> void:
		var why := TeamPresets.save_block_reason(_s.party)
		if why == "" and TeamPresets.clean_name(edit.text) == "":
			why = _s.tr("Give the team a name")
		if why == "" and not TeamPresets.has_room():
			why = _s.tr("All preset slots are used")
		if why == "":
			UI3.clear_disabled_reason(save)
		else:
			UI3.set_disabled_reason(save, _s.tr("Save team") + " · " + why)
	edit.text_changed.connect(refresh_save)
	refresh_save.call()
	save.pressed.connect(func() -> void: _s.save_preset(edit.text))
	acts.add_child(save)
	_s._focus_later(edit)


## UI-03 33: modal 1120, class filter chips, 5-column grid of square previews, Cancel / "Put in slot n".
## A tile only selects; the primary button commits through set_slot().
func _show_picker() -> void:
	var v := _s._modal_box(1120, "Picker")
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	v.add_child(head)
	var t := _s._lbl(_s.tr("Pick an Axie · slot %d") % (_s._picker_slot + 1), "LabelScreenTitle")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var chips := HBoxContainer.new()
	chips.name = "PickerFilters"
	chips.add_theme_constant_override("separation", 8)
	v.add_child(chips)
	var opts: Array = [["all", _s.tr("All")], ["starter", _s.tr("Starter")], ["vault", _s.tr("Vault")]]
	for o in opts:
		var tb := UI3.tab(String(o[1]), _s._picker_tab == o[0])
		tb.name = "Tab_" + String(o[0])
		tb.custom_minimum_size.y = 44
		tb.pressed.connect(func() -> void:
			_s._picker_tab = o[0]
			_show_picker())
		chips.add_child(tb)
	for c in _pick_classes():
		var cb := UI3.tab(c.capitalize(), _s._picker_cls == c)
		cb.name = "Class_" + c
		cb.custom_minimum_size.y = 44
		cb.pressed.connect(func() -> void:
			_s._picker_cls = "all" if _s._picker_cls == c else c
			_show_picker())
		chips.add_child(cb)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 570
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_s._picker_grid = GridContainer.new()
	_s._picker_grid.columns = 5
	_s._picker_grid.add_theme_constant_override("h_separation", 12)
	_s._picker_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_s._picker_grid)
	var put := UI3.button(_s.tr("Put in slot %d") % (_s._picker_slot + 1), &"primary", &"M")
	put.name = "PutInSlot"
	var tiles: Array[Button] = []
	var shown := 0
	for k in _pick_keys():
		var def: Dictionary = ContentDB.heroes[k]
		var cls := String(def.get("cls", ""))
		if _s._picker_cls != "all" and cls != _s._picker_cls:
			continue
		shown += 1
		var taken := TeamPresets.seat_taken(_s.party, _s._picker_slot, k)
		var b := _picker_tile(k, def, taken)
		b.pressed.connect(func() -> void:
			_s._picker_sel = k
			for o in tiles:
				_s._outline(o, o == b)
			UI3.clear_disabled_reason(put))
		tiles.append(b)
		_s._picker_grid.add_child(b)
		if k == _s._picker_sel:
			_s._outline.call_deferred(b, true)
	if shown == 0:
		var msg := _s.tr("Your Vault is empty. Import an Axie in the Vault.") if _s._picker_tab == "vault" and _s._picker_cls == "all" else _s.tr("No Axie matches this filter.")
		var em := _s._lbl(msg, "LabelMuted")
		em.name = "PickerEmpty"
		v.add_child(em)
	if _s._picker_sel == "" or not _pick_keys().has(_s._picker_sel):
		UI3.set_disabled_reason(put, _s.tr("Put in slot %d") % (_s._picker_slot + 1) + " · " + _s.tr("Pick an Axie"))
	put.pressed.connect(func() -> void:
		if _s._picker_sel != "" and _s.swap_into_slot(_s._picker_slot, _s._picker_sel):
			_s.close_modal())
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 16)
	acts.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(acts)
	var cancel := UI3.button(_s.tr("Cancel"), &"secondary", &"M")
	cancel.name = "CancelPicker"
	cancel.pressed.connect(_s.close_modal)
	acts.add_child(cancel)
	acts.add_child(put)


## Square preview (portrait >= 160), name (ellipsis), class and Max HP. 50% and disabled when the Axie sits in another slot.
func _picker_tile(k: String, def: Dictionary, taken: bool) -> Button:
	var b := UI3.button("", &"secondary", &"M")
	b.name = "Tile_" + k
	b.custom_minimum_size = Vector2(188, 276)
	b.tooltip_text = _s.tr("In slot %d · picking it swaps") % (_s.party.find(k) + 1) if taken else ""
	b.set_meta("base_normal", b.get_theme_stylebox("normal"))
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 4)
	col.offset_left = 8
	col.offset_top = 8
	col.offset_right = -8
	col.offset_bottom = -8
	b.add_child(col)
	var cls := String(def.get("cls", ""))
	var pv := Panel.new()
	pv.custom_minimum_size = Vector2(168, 168)
	pv.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var psb := StyleBoxFlat.new()
	psb.bg_color = UI3Theme.color("viewport")
	psb.set_corner_radius_all(UI3Theme.radius("m"))
	pv.add_theme_stylebox_override("panel", psb)
	col.add_child(pv)
	var port_path := "res://assets/portraits/%s.png" % cls
	if ResourceLoader.exists(port_path):
		var pic := TextureRect.new()
		pic.texture = load(port_path)
		pic.set_anchors_preset(Control.PRESET_FULL_RECT)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pv.add_child(pic)
	var nm := _s._lbl(String(def.get("n", k)).substr(0, 20), "LabelTitle")
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.clip_text = true
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(nm)
	var sub := _s._lbl("%s · %s %d" % [cls.capitalize(), _s.tr("HP"), int(def.get("max_hp", 0))], "LabelMuted")
	sub.clip_text = true
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(sub)
	if taken:
		b.modulate.a = 0.5
	return b


func _pick_keys() -> Array[String]:
	var keys: Array[String] = []
	if _s._picker_tab != "vault":
		keys.append_array(MainMenu.T1_HERO_KEYS)
	if _s._picker_tab != "starter":
		for entry in MetaState.vault:
			if MetaState.vault_stale(entry):
				continue
			var k := MetaState.vault_key(entry)
			if ContentDB.heroes.has(k) and not keys.has(k):
				keys.append(k)
	return keys


func _pick_classes() -> Array[String]:
	var cl: Array[String] = []
	for k in _pick_keys():
		var c := String(ContentDB.heroes[k].get("cls", ""))
		if c != "" and not cl.has(c):
			cl.append(c)
	return cl
