class_name RunPauseMenu
extends Control
## In-run menu, UI-05 b23 lane R6 (round-2 frames menu--*): MenuColumn (Paused, Resume + 5 rows 64 h) beside a
## SidePanel (Cores owned / Run map / Settings) that follows the focused row. Save and quit asks to confirm (Cancel
## first, focus on Cancel, no keycap on the primary); Abandon run asks with Keep playing first (primary, Space) and, in
## Mission runs, the stake line. Pure view: the host acts on the signals.

signal resumed
signal settings_requested
signal save_quit_confirmed
signal abandon_confirmed

const Parts := preload("res://scenes/run_map/ui5/RunMenuParts.gd")
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const HudStyle := preload("res://scenes/shared/ui5/HudStyle.gd")

## {floor, total, ascension, shards, kind} for the Run map panel (filled by the host from the real run).
var map_info: Dictionary = {}
var side_name := "relics"
var rows: Dictionary = {}
var _side: PanelContainer = null
var _side_body: VBoxContainer = null
var _dlg: Control = null
var _confirm_root: Control = null


func build(p_map_info: Dictionary) -> void:
	map_info = p_map_info
	theme = UI3Theme.get_theme()
	name = "RunPauseMenu"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = UI3Theme.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var pair := HBoxContainer.new()
	pair.name = "Menu"
	pair.add_theme_constant_override("separation", UI3Theme.space("24"))
	center.add_child(pair)

	var menu := PanelParts.panel(PanelParts.plate_box("xl", UI3Theme.space("24")), "MenuColumn")
	menu.custom_minimum_size.x = UI3Theme.size_of("menu_w")
	pair.add_child(menu)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("8"))
	menu.add_child(col)
	var head := VBoxContainer.new()
	head.name = "Head"
	head.add_theme_constant_override("separation", UI3Theme.space("4"))
	col.add_child(head)
	var title := PanelParts.text(tr("Paused"), "text_banner", "text", true)
	title.name = "Title"
	head.add_child(title)
	var sub := PanelParts.text(tr("Your run is safe while you look around."), "text_body", "text_muted")
	sub.name = "SubLine"
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(sub)
	_resume_row(col)
	_row(col, "Relics", "CoresownedRow", tr("Cores owned"), func() -> void: show_side("relics"), "relics")
	_row(col, "Map", "RunmapRow", tr("Run map"), func() -> void: show_side("map"), "map")
	_row(col, "Settings", "SettingsRow", tr("Settings"), func() -> void: show_side("settings"), "settings")
	_row(col, "SaveQuit", "SaveandquitRow", tr("Save and quit"), _ask_save_quit)
	var ab := _row(col, "Abandon", "AbandonrunRow", tr("Abandon run"), _ask_abandon)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		ab.add_theme_color_override(k, UI3Theme.color("danger_text"))

	_side = PanelParts.panel(PanelParts.plate_box("xl", UI3Theme.space("24")), "SidePanel")
	_side.custom_minimum_size.x = UI3Theme.size_of("menu_side_w")
	pair.add_child(_side)
	show_side("relics")
	(rows["Resume"] as Button).grab_focus.call_deferred()


func _resume_row(col: VBoxContainer) -> void:
	var b := PanelParts.button(tr("Resume"), &"primary", &"M")
	b.name = "ResumeButton"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y = UI3Theme.size_of("menu_row_h")
	b.pressed.connect(func() -> void: resumed.emit())
	col.add_child(b)
	rows["Resume"] = b
	# .menu-row.btn-primary: padding 0 20. Theme styles only resolve once the button is in the tree, and the
	# menu may be built before (RunMap, CombatView) or after (tests) it enters the tree.
	var pad := func() -> void:
		for st in ["normal", "hover", "pressed", "disabled", "hover_pressed", "focus"]:
			var sb := b.get_theme_stylebox(st).duplicate() as StyleBox
			sb.content_margin_left = UI3Theme.space("20")
			sb.content_margin_right = UI3Theme.space("20")
			b.add_theme_stylebox_override(st, sb)
	if b.is_node_ready():
		pad.call()
	else:
		b.ready.connect(pad, CONNECT_ONE_SHOT)
	# Space-between: the keycap sits at the right edge (padding 20).
	var cap := Ui5Keycap.make("Space", &"primary")
	b.add_child(cap)
	var place := func() -> void:
		var s := cap.get_combined_minimum_size()
		cap.size = s
		cap.position = Vector2(b.size.x - UI3Theme.space("20") - s.x, (b.size.y - s.y) * 0.5)
	b.resized.connect(place)
	place.call_deferred()


func _row(col: VBoxContainer, key: String, node_name: String, text: String, on: Callable, side_key := "") -> Button:
	var b := Parts.row_button(text, node_name, side_key != "" and side_key == side_name)
	b.set_meta("side_key", side_key)
	b.pressed.connect(on)
	if side_key != "":
		b.focus_entered.connect(on)   # the side panel follows the focused row
	col.add_child(b)
	rows[key] = b
	return b


func _sync_active() -> void:
	for k in ["Relics", "Map", "Settings"]:
		if rows.has(k):
			var b := rows[k] as Button
			Parts.style_row(b, String(b.get_meta("side_key", "")) == side_name)


## Fills the side panel: "relics" (owned list), "map" (progress summary) or "settings" (button to the screen).
func show_side(which: String) -> void:
	side_name = which
	_sync_active()
	for c in _side.get_children():
		_side.remove_child(c)
		c.queue_free()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI3Theme.space("12"))
	_side.add_child(v)
	_side_body = v
	match which:
		"relics":
			var cores: Array = RelicSlots.owned_cores(RunState.owned_relic_ids)
			var t := PanelParts.text(tr("Cores owned") + " · %d" % cores.size(), "text_title", "text", true)
			t.name = "PanelTitle"
			v.add_child(t)
			var sc := ScrollContainer.new()
			sc.name = "RelicScroll"
			sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
			sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			v.add_child(sc)
			var list := VBoxContainer.new()
			list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			list.add_theme_constant_override("separation", UI3Theme.space("12"))
			sc.add_child(list)
			if cores.is_empty() and RunState.run_rule == "" and _other_ids(cores).is_empty() and not AnchorAdapter.has_anchor():
				list.add_child(PanelParts.text(tr("No Cores yet."), "text_body", "text_muted"))
			var ar := _anchor_row()
			if ar != null:
				list.add_child(ar, true)
			for id in cores:
				list.add_child(_core_row(String(id)), true)
			for id in _other_ids(cores):
				list.add_child(_other_row(String(id)), true)
			if RunState.run_rule != "":
				list.add_child(_rule_row(RunState.run_rule), true)
		"map":
			var t2 := PanelParts.text(tr("Run map"), "text_title", "text", true)
			t2.name = "PanelTitle"
			v.add_child(t2)
			var n_cores: int = RelicSlots.owned_cores(RunState.owned_relic_ids).size()
			v.add_child(Parts.stat_row(tr("Floor"), tr("%d of %d") % [int(map_info.get("floor", 0)), int(map_info.get("total", 0))]), true)
			v.add_child(Parts.stat_row(tr("Ascension"), str(int(map_info.get("ascension", 0)))), true)
			v.add_child(Parts.stat_row(tr("Shards this run"), UI3.fmt(int(map_info.get("shards", 0)))), true)
			v.add_child(Parts.stat_row(tr("Axies in the party"), str(RunState.roster.size())), true)
			v.add_child(Parts.stat_row(tr("Cores owned"), str(n_cores)), true)
		_:
			var t3 := PanelParts.text(tr("Settings"), "text_title", "text", true)
			t3.name = "PanelTitle"
			v.add_child(t3)
			v.add_child(Parts.stat_row(tr("Music"), "%d%%" % roundi(MetaState.audio_music_volume * 100.0), "MusicRow"))
			v.add_child(Parts.stat_row(tr("Sound effects"), "%d%%" % roundi(MetaState.audio_sfx_volume * 100.0), "SfxRow"))
			v.add_child(Parts.stat_row(tr("Mute everything"), tr("On") if MetaState.audio_muted else tr("Off"), "MuteRow"))
			v.add_child(Parts.stat_row(tr("Reduce flashing and screen shake"), tr("On") if MetaState.reduce_flash else tr("Off"), "ReduceRow"))
			var n := PanelParts.text(tr("Change these in Settings. The run stays paused and you come back here."), "text_body", "text_muted")
			n.name = "Note"
			n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(n)
			# Clearly secondary: small, not stretched, so Resume stays the only primary.
			var go := UI3.button(tr("Open Settings"), &"secondary", &"S")
			go.name = "OpenSettingsButton"
			go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			go.pressed.connect(func() -> void: settings_requested.emit())
			v.add_child(go)


## OwnedCore: stat-row with a CoreSlot + the Core's name on the left and its TierChip on the right.
func _core_row(id: String) -> Control:
	var def = RelicRegistry.get_def(id)
	var row := PanelParts.panel(PanelParts.cell_box(UI3Theme.space("8"), UI3Theme.space("16"), "s"), "OwnedCore")
	row.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	row.add_child(h)
	var left := HBoxContainer.new()
	left.name = "Left"
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", UI3Theme.space("12"))
	h.add_child(left)
	left.add_child(_socket(def, false))
	var tv := VBoxContainer.new()
	tv.name = "Texts"
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 0)
	left.add_child(tv)
	var nm := PanelParts.text("", "text_body", "text", true)
	nm.name = "CoreName"
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(nm)
	Ui5Ellipsis.set_text(nm, UI3.title_case(UI3.player_text(String(def.name) if def != null else id)))
	var hl := PanelParts.text("", "text_body", "core_headline")
	hl.name = "Headline"
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(hl)
	CoreHeadline.apply(hl, id)
	h.add_child(TierShards.new().setup(int(def.rarity) if def != null else 0, 28))
	return row


## Socket picture + family emblem (or the Run Rule stamp) for a menu row. Name "CoreSlot" / "RunRuleSlot".
func _socket(def, is_rule: bool) -> Control:
	var px := float(UI3Theme.size_of("core_slot"))
	var tier := clampi(int(def.rarity), 0, 2) if def != null else -1
	var s := TextureRect.new()
	s.name = "RunRuleSlot" if is_rule else "CoreSlot"
	s.texture = UI6Assets.slot(tier, px)
	s.custom_minimum_size = Vector2.ONE * px
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER   # round socket art: never stretch it to the row height
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var e := TextureRect.new()
	e.name = "RunRuleEmblem" if is_rule else "FamilyEmblem"
	var ax := "run_rule" if is_rule else (String(def.core_axis) if def != null else "stat")
	e.texture = CoreVisuals.family_texture(ax, px * UI6Assets.SLOT_EMBLEM)
	UI6Assets.place_in_slot(e, px)
	e.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(e)
	return s


## AnchorRow: house emblem, Anchor name + house, awaken chip (1/2). Null without an Anchor.
func _anchor_row() -> Control:
	var id := AnchorAdapter.current_id()
	if id == "":
		return null
	var house := AnchorAdapter.house_id(id)
	var row := PanelParts.panel(PanelParts.cell_box(UI3Theme.space("8"), UI3Theme.space("16"), "s"), "AnchorRow")
	row.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	row.add_child(h)
	var ic := TextureRect.new()
	ic.name = "HouseEmblem"
	var px := float(UI3Theme.size_of("core_slot"))
	ic.texture = UI6Assets.house(house, px)
	ic.custom_minimum_size = Vector2.ONE * px
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	UI6Assets.light_disc(ic, px)
	h.add_child(ic)
	var nm := PanelParts.text("", "text_body", "text", true)
	nm.name = "AnchorName"
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nm)
	Ui5Ellipsis.set_text(nm, "%s · %s" % [AnchorAdapter.name_of(id), AnchorAdapter.house_name(house)])
	var chip := AwakenProgress.chip()
	if chip != null:
		h.add_child(chip)
	return row


## Owned ids that are neither a Core nor the Run rule (boss pacts, old relics); "__" ids are internal markers.
func _other_ids(cores: Array) -> Array:
	return RunState.owned_relic_ids.filter(func(x) -> bool:
		var id := String(x)
		return not id.begins_with("__") and not cores.has(id) and id != RunState.run_rule \
			and not (RelicRegistry.get_def(id) != null and String(RelicRegistry.get_def(id).core_axis) == "run_rule"))


## OwnedPact / OwnedRelic: name left, "Pact" (or the rarity) muted right, what it does muted below.
func _other_row(id: String) -> Control:
	var def = RelicRegistry.get_def(id)
	var is_pact: bool = def != null and String(def.pact_group) != ""
	var row := PanelParts.panel(PanelParts.cell_box(UI3Theme.space("8"), UI3Theme.space("16"), "s"), "OwnedPact" if is_pact else "OwnedRelic")
	row.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("4"))
	row.add_child(col)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	col.add_child(h)
	var nm := PanelParts.text("", "text_body", "text", true)
	nm.name = "Name"
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(nm)
	Ui5Ellipsis.set_text(nm, UI3.title_case(UI3.player_text(String(def.name) if def != null else id)))
	var names := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]
	var tag := tr("Pact") if is_pact else (tr(names[clampi(int(def.rarity), 0, 5)]) if def != null else "")
	var t := PanelParts.text(tag, "text_body", "text_muted")
	t.name = "Kind"
	h.add_child(t)
	if def != null:
		var d := UI3.describe(String(def.description))
		var txt := ("MP %d · " % int(d["mp"]) if int(d["mp"]) >= 0 else "") + String(d["text"])
		if txt.strip_edges() != "":
			var body := PanelParts.text(txt, "text_body", "text_muted")
			body.name = "Effect"
			body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(body)
	return row


## OwnedRule: the Run rule, name left and "Run rule" muted.
func _rule_row(id: String) -> Control:
	var def = RelicRegistry.get_def(id)
	var row := PanelParts.panel(PanelParts.cell_box(UI3Theme.space("8"), UI3Theme.space("16"), "s"), "OwnedRule")
	row.custom_minimum_size.y = UI3Theme.size_of("btn_s")
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("12"))
	row.add_child(h)
	var nm := PanelParts.text("", "text_body", "text", true)
	nm.name = "RuleName"
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_socket(def, true))
	h.add_child(nm)
	Ui5Ellipsis.set_text(nm, UI3.title_case(UI3.player_text(String(def.name) if def != null else id)))
	h.add_child(PanelParts.text(tr("Run rule"), "text_body", "text_muted"))
	return row


## The open confirm dialog (SaveQuitConfirm / AbandonConfirm), or null.
func confirm_dialog() -> Control:
	return _dlg


func _close_confirm() -> void:
	if _confirm_root != null and is_instance_valid(_confirm_root):
		remove_child(_confirm_root)
		_confirm_root.queue_free()
	_confirm_root = null
	_dlg = null
	if rows.has("Resume"):
		(rows["Resume"] as Button).grab_focus.call_deferred()


## Scrim2 + a centred dialog plate: Title (banner), Body, optional StakeLine, Footer (space-between).
func _confirm(dlg_name: String, title: String, title_color: String, body: String, stake: int,
		first: Button, second: Button) -> void:
	var root := Control.new()
	root.name = "ConfirmModal"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.name = "Scrim2"
	scrim.color = UI3Theme.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var dlg := PanelParts.panel(PanelParts.plate_box("xl", UI3Theme.space("32")), dlg_name)
	dlg.custom_minimum_size.x = UI3Theme.size_of("defeat_panel_w")
	center.add_child(dlg)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI3Theme.space("20"))
	dlg.add_child(col)
	var head := VBoxContainer.new()
	head.name = "DialogHead"
	head.add_theme_constant_override("separation", UI3Theme.space("4"))
	col.add_child(head)
	var t := PanelParts.text(title, "text_banner", title_color, true)
	t.name = "Title"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(t)
	var b := PanelParts.text(body, "text_body")
	b.name = "Body"
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(b)
	if stake > 0:
		var sp := PanelParts.panel(UI3Theme.flat(UI3Theme.color("danger_bg"), UI3Theme.radius("l"), 0,
			Color.TRANSPARENT, Vector4(UI3Theme.space("20"), UI3Theme.space("16"), UI3Theme.space("20"), UI3Theme.space("16"))), "StakeLine")
		var sh := HBoxContainer.new()
		sh.add_theme_constant_override("separation", UI3Theme.space("12"))
		sp.add_child(sh)
		var ic := TextureRect.new()
		ic.name = "StakeIcon"
		ic.texture = UI3.icon("cur_shard")
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(UI3Theme.size_of("icon_l"), UI3Theme.size_of("icon_l"))
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sh.add_child(ic)
		var sl := PanelParts.text(tr("You lose your %d Shard mission stake.") % stake, "text_title", "text", true)
		sl.name = "StakeText"
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		sh.add_child(sl)
		col.add_child(sp)
	var foot := HBoxContainer.new()
	foot.name = "Footer"
	foot.add_theme_constant_override("separation", UI3Theme.space("16"))
	col.add_child(foot)
	foot.add_child(first)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # space-between
	foot.add_child(spacer)
	foot.add_child(second)
	add_child(root)
	_confirm_root = root
	_dlg = dlg
	first.grab_focus.call_deferred()


func _ask_save_quit() -> void:
	var cancel := PanelParts.button(tr("Cancel"), &"secondary", &"M")
	cancel.name = "CancelButton"
	var ok := PanelParts.button(tr("Save and quit"), &"primary", &"L")
	ok.name = "SaveQuitButton"
	cancel.pressed.connect(_close_confirm)
	ok.pressed.connect(func() -> void:
		_close_confirm()
		save_quit_confirmed.emit())
	_confirm("SaveQuitConfirm", tr("Save and quit?"), "text",
		tr("Your run is saved. You can continue it from the main menu."), 0, cancel, ok)


## Keep playing first (primary, Space, focus); Abandon run is the danger button. Mission runs add the stake line.
func _ask_abandon() -> void:
	var body := tr("The run is deleted: its Axies, Cores and Shards are gone. Shards banked from finished runs are safe.")
	var stake := int(MetaState.mission_escrow.get("stake", 0))
	var keep := PanelParts.button(tr("Keep playing"), &"primary", &"L")
	keep.name = "KeepPlayingButton"
	var cap := Ui5Keycap.make("Space", &"primary")
	keep.add_child(cap)
	var ab := Parts.danger_button(tr("Abandon run"), "AbandonButton")
	keep.pressed.connect(_close_confirm)
	ab.pressed.connect(func() -> void:
		_close_confirm()
		abandon_confirmed.emit())
	_confirm("AbandonConfirm", tr("Abandon this run?"), "danger_text", body, stake, keep, ab)
	# place_trailing needs the button in the tree: _confirm has just added the dialog.
	var pad := UI3Theme.space("32")
	var place := func() -> void:
		if is_instance_valid(keep) and keep.is_inside_tree():
			HudStyle.place_trailing(keep, cap, pad)
	keep.resized.connect(place)
	place.call_deferred()


## Esc = Resume (a confirm dialog's own Esc closes only the dialog: Cancel / Keep playing).
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _dlg != null:
			_close_confirm()
			get_viewport().set_input_as_handled()
			return
		resumed.emit()
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()
