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


## UI-05 S3b (06-run-setup--lb-*): popup 640, Title + SubLine, Rows (skeleton / rows / error / empty), Close (focus + Space)
## and Full Leaderboard, both secondary. States: loading, error, normal.
func _show_leaderboard_popup() -> void:
	var m := Ui5RunPickerParts.modal(_s, &"leaderboard", "LeaderboardPopup", "modal_s_w")
	var v: VBoxContainer = m["v"]
	var head := VBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", UI3Theme.space("4"))
	v.add_child(head)
	head.add_child(Ui5RunPickerParts.title(_s.tr("Leaderboard")))
	var sub := Ui5Text.label(_s.tr("Ascension %d · this season") % _s.ascension, "text_body", "text_muted")
	sub.name = "SubLine"
	head.add_child(sub)
	var rows_box := VBoxContainer.new()
	rows_box.name = "Rows"
	rows_box.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(rows_box)
	var close := UI3.button(_s.tr("Close"), &"secondary", &"M")
	close.name = "CloseButton"
	close.pressed.connect(_s.close_modal)
	var full := UI3.button(_s.tr("Full Leaderboard"), &"secondary", &"M")
	full.name = "FullLeaderboardButton"
	full.pressed.connect(_s.open_full_leaderboard)
	var foot := Ui5ModalFooter.make(full, close) as HBoxContainer
	v.add_child(foot)
	Ui5RunPickerParts.cap(close)
	_s._focus_later(close)
	_lb_load(rows_box, foot, full, null)


func _lb_loading(rows_box: VBoxContainer) -> void:
	for c in rows_box.get_children():
		rows_box.remove_child(c)
		c.queue_free()
	var l := Ui5Text.label(_s.tr("Loading…"), "text_body", "text_muted")
	l.name = "LoadingLine"
	rows_box.add_child(l)
	for i in 4:
		rows_box.add_child(Ui5RunPickerParts.skeleton(), true)


## Fetches the board into rows_box. On error a Try again button (focus + Space) sits in the rows; Close loses its keycap.
func _lb_load(rows_box: VBoxContainer, acts: HBoxContainer, full: Button, _loading: Control) -> void:
	_lb_loading(rows_box)
	var close: Button = null
	if acts != null:
		close = acts.get_node_or_null("CloseButton") as Button
	var src: LeaderboardSource = _s.lb_source if _s.lb_source != null else LeaderboardSource.make_default()
	src.fetch({"asc": _s.ascension, "period": "season", "mode": _s.mode}, func(res: Dictionary) -> void:
		if not is_instance_valid(rows_box):
			return
		for c in rows_box.get_children():
			rows_box.remove_child(c)
			c.queue_free()
		if not bool(res.get("ok", false)):
			var blk := Ui5RunPickerParts.center_block(_s.tr("Can't load the board right now. Try again later."), "ErrorState")
			blk.get_node("Msg").name = "ErrorLine"
			blk.add_child(Ui5ToneDisc.make(&"error"))
			blk.move_child(blk.get_child(blk.get_child_count() - 1), 0)
			(blk.get_child(0) as Control).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var retry := UI3.button(_s.tr("Try again"), &"secondary", &"M")
			retry.name = "TryAgainButton"
			retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			retry.pressed.connect(func() -> void:
				if is_instance_valid(close):
					Ui5RunPickerParts.cap(close)
					_s._focus_later(close)
				_lb_load(rows_box, acts, full, null))
			blk.add_child(retry)
			rows_box.add_child(blk)
			if is_instance_valid(close):
				Ui5RunPickerParts.uncap(close)
			Ui5RunPickerParts.cap(retry)
			_s._focus_later(retry)
			return
		var rows: Array = res.get("rows", [])
		var me: Dictionary = res.get("me", {})
		if rows.is_empty() and me.is_empty():
			rows_box.add_child(Ui5RunPickerParts.center_block(_s.tr("No scores yet this season.")))
		for i in mini(5, rows.size()):
			rows_box.add_child(_lb_row(rows[i], false), true)
		if not me.is_empty():
			rows_box.add_child(_lb_row(me, true), true)
		if String(res.get("updated", "")) != "":
			var up := Ui5Text.label(_s.tr("Last updated %s") % String(res["updated"]), "text_body", "text_muted")
			up.name = "UpdatedLine"
			rows_box.add_child(up))


func _lb_row(r: Dictionary, own: bool) -> PanelContainer:
	return Ui5RunPickerParts.lb_row(int(r.get("rank", 0)), String(r.get("name", _s.tr("You"))), UI3.fmt(int(r.get("score", 0))), own, _s.tr("You"))


# ---------------------------------------------------------------- team presets (R3 M2)


## UI-05 S3b (06-run-setup--presets-load / -save): PresetsModal 640, LoadTab / SaveTab. Load: nothing picked, Cancel has
## focus + Space, LoadButton off with "Pick a team". Save: the name field has focus, no keycap.
func _show_presets(tab: String) -> void:
	_s._presets_tab = tab
	var m := Ui5RunPickerParts.modal(_s, &"presets", "PresetsModal", "modal_s_w")
	var v: VBoxContainer = m["v"]
	v.add_child(Ui5RunPickerParts.title(_s.tr("Team presets")))
	var tabs := HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.add_theme_constant_override("separation", UI3Theme.space("8"))
	v.add_child(tabs)
	var tl := Ui5RunPickerParts.tab(_s.tr("Load"), tab == "load", "btn_m", "LoadTab", true)
	tl.pressed.connect(func() -> void: _show_presets("load"))
	tabs.add_child(tl)
	var ts := Ui5RunPickerParts.tab(_s.tr("Save current"), tab == "save", "btn_m", "SaveTab", true)
	ts.pressed.connect(func() -> void: _show_presets("save"))
	tabs.add_child(ts)
	var cancel := UI3.button(_s.tr("Cancel"), &"secondary", &"M")
	cancel.name = "CancelButton"
	cancel.pressed.connect(_s.close_modal)
	var primary: Button
	if tab == "load":
		primary = _load_list(v)
	else:
		primary = _save_form(v)
	v.add_child(Ui5ModalFooter.make(primary, cancel))
	if tab == "load":
		Ui5RunPickerParts.cap(cancel)
		_s._focus_later(cancel)


func _presets_load_body(v: VBoxContainer, acts: HBoxContainer) -> void:
	acts.add_child(_load_list(v))


func _presets_save_body(v: VBoxContainer, acts: HBoxContainer) -> void:
	acts.add_child(_save_form(v))


## TeamList + LoadButton (returned). A row with a missing Axie says so; the pick only enables the button.
func _load_list(v: VBoxContainer) -> Button:
	var go := UI3.button(_s.tr("Load team"), &"primary", &"M")
	go.name = "LoadButton"
	Ui5DisabledReason.apply(go, _s.tr("Load team") + " · " + _s.tr("Pick a team"))
	if TeamPresets.count() == 0:
		var none := Ui5RunPickerParts.center_block(_s.tr("No saved teams yet. Build one in Team presets (House)."))
		v.add_child(none)
	else:
		var list := VBoxContainer.new()
		list.name = "TeamList"
		list.add_theme_constant_override("separation", UI3Theme.space("12"))
		v.add_child(list)
		var rows: Array[Button] = []
		for i in TeamPresets.count():
			var e: Dictionary = MetaState.team_presets[i]
			var miss := TeamPresets.missing_count(e)
			var b := Ui5RunPickerParts.team_button("%s%s" % [String(e["name"]).substr(0, 20), (" · %d seats empty" % miss) if miss > 0 else ""])
			b.set_meta("preset", i)
			b.pressed.connect(func() -> void:
				for o in rows:
					Ui5RunPickerParts.set_team_on(o, o == b)
				go.set_meta("preset", i)
				Ui5DisabledReason.clear(go))
			rows.append(b)
			list.add_child(b, true)
	go.pressed.connect(func() -> void:
		if go.has_meta("preset"):
			_s.load_preset(int(go.get_meta("preset"))))
	return go


## NameField + SlotLine + SaveButton (returned). Nothing is saved until SaveButton is pressed.
func _save_form(v: VBoxContainer) -> Button:
	var col := VBoxContainer.new()
	col.name = "Form"
	col.add_theme_constant_override("separation", UI3Theme.space("12"))
	v.add_child(col)
	col.add_child(Ui5Text.label(_s.tr("Name"), "text_body", "text_muted"))
	var edit := Ui5RunPickerParts.name_field("Team %d" % (TeamPresets.count() + 1), TeamPresets.NAME_MAX)
	col.add_child(edit)
	var slotline := Ui5Text.label(_s.tr("Saves to slot %d") % (TeamPresets.count() + 1), "text_body", "text_muted")
	slotline.name = "SlotLine"
	col.add_child(slotline)
	var save := UI3.button(_s.tr("Save team"), &"primary", &"M")
	save.name = "SaveButton"
	var refresh_save := func(_t := "") -> void:
		var why := TeamPresets.save_block_reason(_s.party)
		if why == "" and TeamPresets.clean_name(edit.text) == "":
			why = _s.tr("Give the team a name")
		if why == "" and not TeamPresets.has_room():
			why = _s.tr("All preset slots are used")
		if why == "":
			Ui5DisabledReason.clear(save)
		else:
			Ui5DisabledReason.apply(save, _s.tr("Save team") + " · " + why)
	edit.text_changed.connect(refresh_save)
	refresh_save.call()
	save.pressed.connect(func() -> void: _s.save_preset(edit.text))
	_s._focus_later(edit)
	return save


## UI-05 S3b (06-run-setup--picker): PickerModal 1120, class tabs, 6-column grid of AxieTile, nothing picked at first,
## Cancel has focus + Space, PutButton off with "Put in slot n · Pick an Axie". A tile only picks; PutButton commits.
func _show_picker() -> void:
	var m := Ui5RunPickerParts.modal(_s, &"picker", "PickerModal", "picker_w")
	var v: VBoxContainer = m["v"]
	var root: Control = m["root"]
	v.add_child(Ui5RunPickerParts.title(_s.tr("Pick an Axie · slot %d") % (_s._picker_slot + 1)))
	var chips := HFlowContainer.new()
	chips.name = "Tabs"
	chips.add_theme_constant_override("h_separation", UI3Theme.space("8"))
	chips.add_theme_constant_override("v_separation", UI3Theme.space("8"))
	v.add_child(chips)
	var opts: Array = [["all", _s.tr("All"), "AllTab"], ["starter", _s.tr("Starter"), "StarterTab"], ["vault", _s.tr("Vault"), "VaultTab"]]
	for o in opts:
		var tb := Ui5RunPickerParts.tab(String(o[1]), _s._picker_tab == o[0], "btn_m", String(o[2]))
		tb.pressed.connect(func() -> void:
			_s._picker_tab = o[0]
			_show_picker())
		chips.add_child(tb)
	for c in _pick_classes():
		var cb := Ui5RunPickerParts.tab(c.capitalize(), _s._picker_cls == c, "btn_s", "%sChip" % c.capitalize())
		cb.pressed.connect(func() -> void:
			_s._picker_cls = "all" if _s._picker_cls == c else c
			_show_picker())
		chips.add_child(cb)
	var scroll := ScrollContainer.new()
	scroll.name = "GridScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = 6
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", UI3Theme.space("12"))
	grid.add_theme_constant_override("v_separation", UI3Theme.space("12"))
	scroll.add_child(grid)
	_s._picker_grid = grid
	var tip := Ui5RunPickerParts.tip("")
	root.add_child(tip)
	var put := UI3.button(_s.tr("Put in slot %d") % (_s._picker_slot + 1), &"primary", &"M")
	put.name = "PutButton"
	var tiles: Array[Button] = []
	var shown := 0
	for k in _pick_keys():
		var def: Dictionary = ContentDB.heroes[k]
		if _s._picker_cls != "all" and String(def.get("cls", "")) != _s._picker_cls:
			continue
		shown += 1
		var taken := TeamPresets.seat_taken(_s.party, _s._picker_slot, k)
		var b := _picker_tile(k, def, taken)
		b.pressed.connect(func() -> void:
			_s._picker_sel = k
			for o in tiles:
				_s._outline(o, o == b)
			Ui5DisabledReason.clear(put))
		if _s.party.has(k):
			b.mouse_entered.connect(func() -> void: _show_tip(tip, b, k))
			b.focus_entered.connect(func() -> void: _show_tip(tip, b, k))
			b.mouse_exited.connect(func() -> void: tip.visible = false)
			b.focus_exited.connect(func() -> void: tip.visible = false)
		tiles.append(b)
		grid.add_child(b, true)
		if k == _s._picker_sel:
			_s._outline.call_deferred(b, true)
	if shown == 0:
		grid.columns = 1
		var msg := _s.tr("Your Vault is empty. Import an Axie in the Vault.") if _s._picker_tab == "vault" and _s._picker_cls == "all" else _s.tr("No Axie matches this filter.")
		grid.add_child(Ui5RunPickerParts.center_block(msg))
	var rows_n := clampi(int(ceil(shown / 6.0)), 1, 2)
	var th := int(Ui5RunPickerParts.tile_portrait_px() + 2 * UI3Theme.space("8") + 2 * UI3Theme.space("4") + 2 * ceil(UI3Theme.size_of("text_body") * 1.35))
	scroll.custom_minimum_size.y = rows_n * th + (rows_n - 1) * UI3Theme.space("12") + 4
	if _s._picker_sel == "" or not _pick_keys().has(_s._picker_sel):
		Ui5DisabledReason.apply(put, _s.tr("Put in slot %d") % (_s._picker_slot + 1) + " · " + _s.tr("Pick an Axie"))
	put.pressed.connect(func() -> void:
		if _s._picker_sel != "" and _s.swap_into_slot(_s._picker_slot, _s._picker_sel):
			_s.close_modal())
	var cancel := UI3.button(_s.tr("Cancel"), &"secondary", &"M")
	cancel.name = "CancelButton"
	cancel.pressed.connect(_s.close_modal)
	v.add_child(Ui5ModalFooter.make(put, cancel))
	Ui5RunPickerParts.cap(cancel)
	_s._focus_later(cancel)


## "In slot n · picking it swaps" over a tile whose Axie already sits in the party.
func _show_tip(tip: PanelContainer, tile: Button, key: String) -> void:
	(tip.get_child(0) as Label).text = _s.tr("In slot %d · picking it swaps") % (_s.party.find(key) + 1)
	tip.reset_size()
	var root := tip.get_parent() as Control
	tip.position = tile.global_position - root.global_position + Vector2(UI3Theme.space("16"), tile.size.y * 0.3)
	tip.visible = true


func _picker_tile(k: String, def: Dictionary, taken: bool) -> Button:
	return Ui5RunPickerParts.axie_tile(k, def, taken, _s.party.find(k))


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
