class_name RunPauseMenu
extends Control
## In-run menu, UI-03 14: menu plate 480 (Paused, Resume + 5 rows 64 h) beside a 560x576 side panel (Relics owned /
## Run map / Settings). Save and quit asks to confirm; Abandon run is a destructive dialog with focus on Keep
## playing and, in Mission runs, the stake line. Pure view: the host acts on the signals.

signal resumed
signal settings_requested
signal save_quit_confirmed
signal abandon_confirmed

const MENU_W := 480.0
const SIDE_W := 560.0
const SIDE_H := 576.0   # relics list height; Map/Settings hug their content
const ROW_H := 64.0

## {floor, total, ascension, shards, kind} for the Run map panel (filled by the host from the real run).
var map_info: Dictionary = {}
var side_name := "relics"
var rows: Dictionary = {}
var _side: PanelContainer = null
var _side_body: VBoxContainer = null


func build(p_map_info: Dictionary) -> void:
	map_info = p_map_info
	theme = UI3Theme.get_theme()
	name = "RunPauseMenu"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var scrim := ColorRect.new()
	scrim.color = UI3Theme.color("scrim")
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", 24)
	center.add_child(pair)

	var menu := UI3.plate(&"dialog")
	menu.name = "MenuPlate"
	menu.custom_minimum_size = Vector2(MENU_W, 0)
	pair.add_child(menu)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	menu.add_child(col)
	col.add_child(UI3.label(tr("Paused"), "LabelScreenTitle"))
	var sub := UI3.label(tr("Your run is safe while you look around."), "LabelMuted")
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(sub)
	_row(col, "Resume", tr("Resume"), &"primary", func() -> void: resumed.emit())
	_row(col, "Relics", tr("Relics owned"), &"secondary", func() -> void: show_side("relics"))
	_row(col, "Map", tr("Run map"), &"secondary", func() -> void: show_side("map"))
	_row(col, "Settings", tr("Settings"), &"secondary", func() -> void: show_side("settings"))
	_row(col, "SaveQuit", tr("Save and quit"), &"secondary", _ask_save_quit)
	# Same 64 px row as the others; destructive = red-8 text on the secondary plate, no underline.
	var ab := _row(col, "Abandon", tr("Abandon run"), &"secondary", _ask_abandon)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		ab.add_theme_color_override(k, UI3Theme.color("danger_text"))

	_side = UI3.plate(&"dialog")
	_side.name = "SidePanel"
	_side.custom_minimum_size = Vector2(SIDE_W, 0)
	_side.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pair.add_child(_side)
	show_side("relics")
	(rows["Resume"] as Button).grab_focus.call_deferred()


func _row(col: VBoxContainer, key: String, text: String, variant: StringName, on: Callable) -> Button:
	var b := UI3.button(text, variant, &"M")
	b.name = "Row" + key
	b.custom_minimum_size.y = ROW_H
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(on)
	col.add_child(b)
	rows[key] = b
	return b


## Fills the side panel: "relics" (owned list), "map" (progress summary) or "settings" (button to the screen).
func show_side(which: String) -> void:
	side_name = which
	_side.custom_minimum_size.y = SIDE_H if which == "relics" else 0.0
	for c in _side.get_children():
		_side.remove_child(c)
		c.queue_free()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	_side.add_child(v)
	_side_body = v
	match which:
		"relics":
			var ids: Array = RunState.owned_relic_ids.filter(func(x) -> bool: return not String(x).begins_with("__"))
			v.add_child(UI3.label(tr("Relics owned") + " · %d" % ids.size(), "LabelTitle"))
			var sc := ScrollContainer.new()
			sc.name = "RelicScroll"
			sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
			sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			v.add_child(sc)
			var list := VBoxContainer.new()
			list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			list.add_theme_constant_override("separation", 8)
			sc.add_child(list)
			if ids.is_empty():
				list.add_child(UI3.label(tr("No relics yet."), "LabelMuted"))
			for id in ids:
				list.add_child(_relic_row(String(id)))
		"map":
			v.add_child(UI3.label(tr("Run map"), "LabelTitle"))
			var ids2: Array = RunState.owned_relic_ids.filter(func(x) -> bool: return not String(x).begins_with("__"))
			v.add_child(_info_row("Floor", tr("Floor"), tr("%d of %d") % [int(map_info.get("floor", 0)), int(map_info.get("total", 0))]))
			v.add_child(_info_row("Ascension", tr("Ascension"), str(int(map_info.get("ascension", 0)))))
			v.add_child(_info_row("Shards", tr("Shards this run"), UI3.fmt(int(map_info.get("shards", 0)))))
			v.add_child(_info_row("Party", tr("Axies in the party"), str(RunState.roster.size())))
			v.add_child(_info_row("Relics", tr("Relics owned"), str(ids2.size())))
		_:
			v.add_child(UI3.label(tr("Settings"), "LabelTitle"))
			v.add_child(_info_row("Music", tr("Music"), "%d%%" % roundi(MetaState.audio_music_volume * 100.0)))
			v.add_child(_info_row("Sfx", tr("Sound effects"), "%d%%" % roundi(MetaState.audio_sfx_volume * 100.0)))
			v.add_child(_info_row("Mute", tr("Mute everything"), tr("On") if MetaState.audio_muted else tr("Off")))
			v.add_child(_info_row("Flash", tr("Reduce flashing and screen shake"), tr("On") if MetaState.reduce_flash else tr("Off")))
			var t := UI3.label(tr("Change these in Settings. The run stays paused and you come back here."), "LabelMuted")
			t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(t)
			# Clearly secondary: small, not stretched, so Resume stays the only primary.
			var go := UI3.button(tr("Open Settings"), &"secondary", &"S")
			go.name = "OpenSettings"
			go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			go.pressed.connect(func() -> void: settings_requested.emit())
			v.add_child(go)


## One label-left, value-right row for the Run map and Settings panels (18 px, real data).
func _info_row(key: String, label: String, value: String) -> Control:
	var row := UI3.plate(&"row")
	row.name = "Info" + key
	var h := HBoxContainer.new()
	row.add_child(h)
	var l := UI3.label(label)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(l)
	h.add_child(UI3.label(value, "LabelDisplay"))
	return row


func _relic_row(id: String) -> Control:
	var def = RelicRegistry.get_def(id)
	var row := UI3.plate(&"row")
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var nm := UI3.label(UI3.title_case(UI3.player_text(String(def.name) if def != null else id)), "LabelDisplay")
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(nm)
	if def != null:
		var names := ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic"]
		var rl := UI3.label(tr(names[clampi(int(def.rarity), 0, 5)]), "LabelMuted")
		head.add_child(rl)
		var d := UI3.describe(String(def.description))
		var body := UI3.label(("MP %d · " % int(d["mp"]) if int(d["mp"]) >= 0 else "") + String(d["text"]), "LabelMuted")
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", maxi(UI3Theme.size_of("text_body"), 18))   # >= 18 px
		col.add_child(body)
	return row


func _confirm(title: String, body: String, ok_text: String, ok_variant: StringName, keep_text: String, on_ok: Callable) -> void:
	var keep := UI3.button(keep_text, &"secondary", &"M")
	keep.name = "ConfirmKeep"
	var ok := UI3.button(ok_text, ok_variant, &"M")
	ok.name = "ConfirmOk"
	var dlg := UI3.modal(title, body, [keep, ok], 0)
	dlg.name = "ConfirmDialog"
	add_child(dlg)
	var close := func() -> void:
		remove_child(dlg)
		dlg.queue_free()
	keep.pressed.connect(close)
	dlg.cancelled.connect(close)
	ok.pressed.connect(func() -> void:
		close.call()
		on_ok.call())


func _ask_save_quit() -> void:
	_confirm(tr("Save and quit?"), tr("Your run is saved. You can continue it from the main menu."),
		tr("Save and quit"), &"primary", tr("Cancel"), func() -> void: save_quit_confirmed.emit())


## Destructive dialog: focus on Keep playing. Mission runs add the stake line.
func _ask_abandon() -> void:
	var body := tr("The run is deleted: its Axies, relics and Shards are gone. Shards banked from finished runs are safe.")
	var stake := int(MetaState.mission_escrow.get("stake", 0))
	if stake > 0:
		body += "\n" + tr("You lose your %d Shard mission stake.") % stake
	_confirm(tr("Abandon this run?"), body, tr("Abandon run"), &"danger", tr("Keep playing"),
		func() -> void: abandon_confirmed.emit())


## Esc = Resume (a confirm dialog's own Esc closes only the dialog).
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and find_child("ConfirmDialog", true, false) == null:
		resumed.emit()
		get_viewport().set_input_as_handled()
