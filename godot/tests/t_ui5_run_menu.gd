extends Node
## UI-05 b23 lane R6: RunPauseMenu against the menu--* frames (round-2 ui05-run-screens.html).
## Names, side panel states, both confirms, 1920 + 1280, align check (> 0 pairs), real text >= 14 px at 1280,
## and no illustration strings from the HTML.
const Align := preload("res://tests/ui5_align_check.gd")
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _ready() -> void:
	print("=== t_ui5_run_menu: start ===")
	_guard.capture()
	await get_tree().process_frame
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(790, team, "short", 0, false)
	RunState.owned_relic_ids.assign(["c_bastion", "c_backline_glow", "r_ironvow"])
	MetaState.mission_escrow = {"stake": 25}
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc)
	UI3Theme.set_scale_override(1.0)
	MetaState.mission_escrow = {}
	_guard.restore()
	print("=== t_ui5_run_menu: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_run_menu: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)


func _frames(n := 4) -> void:
	for _i in n:
		await get_tree().process_frame


func _small(root: Node, tag: String, sc: float) -> void:
	var bad := []
	for l in root.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.is_visible_in_tree() and lab.text != "" and float(lab.get_theme_font_size("font_size")) * sc < 13.99:
			bad.append(lab.text)
	_ok(bad.is_empty(), "%s: text >= 14 real px (%s)" % [tag, str(bad)])


func _pass(sc: float) -> void:
	var tag := "scale %.2f" % sc
	var pm := RunPauseMenu.new()
	add_child(pm)
	pm.build({"floor": 4, "total": 18, "ascension": 0, "shards": 40})
	await _frames()
	for n in ["MenuColumn", "Title", "SubLine", "ResumeButton", "KeyCap", "CoresownedRow", "RunmapRow", "SettingsRow",
			"SaveandquitRow", "AbandonrunRow", "SidePanel", "OwnedCore", "CoreSlot", "TierChip"]:
		_ok(pm.find_child(n, true, false) != null, "%s: node %s" % [tag, n])
	_ok(Ui5Keycap.all_under(pm).size() == 1, "%s: one keycap (Space on Resume)" % tag)
	_ok(Ui5Keycap.text_of(pm.find_child("KeyCap", true, false) as PanelContainer) == "Space", "%s: Resume key is Space" % tag)
	for k in ["Resume", "Relics", "Map", "Settings", "SaveQuit", "Abandon"]:
		_ok((pm.rows[k] as Button).size.y >= float(UI3Theme.size_of("menu_row_h")) - 0.5, "%s: row %s is 64 high" % [tag, k])
	_ok(pm.find_child("MenuColumn", true, false).size.y == pm.find_child("SidePanel", true, false).size.y, "%s: plates same height" % tag)
	_ok(pm.find_child("OwnedPact", true, false) != null, "%s: pact r_ironvow has a row" % tag)
	_small(pm, tag, sc)
	_ok(Align.pairs(pm) > 0, "%s: align check measured pairs (%d)" % [tag, Align.pairs(pm)])
	_ok(Align.check(pm).is_empty(), "%s: icon/label centred %s" % [tag, str(Align.check(pm))])
	# side panel follows focus
	(pm.rows["Map"] as Button).grab_focus()
	await _frames(2)
	_ok(pm.side_name == "map" and pm.find_children("StatRow*", "", true, false).size() == 5, "%s: focus on Run map shows 5 stat rows" % tag)
	_ok(_text_has(pm, "4 of 18"), "%s: floor from map_info" % tag)
	(pm.rows["Settings"] as Button).grab_focus()
	await _frames(2)
	for n in ["MusicRow", "SfxRow", "MuteRow", "ReduceRow", "OpenSettingsButton"]:
		_ok(pm.find_child(n, true, false) != null, "%s: settings %s" % [tag, n])
	_small(pm, tag + " settings", sc)
	# Save and quit confirm: Cancel first + focus, no keycap on the primary
	(pm.rows["SaveQuit"] as Button).pressed.emit()
	await _frames()
	var sq := pm.find_child("SaveQuitConfirm", true, false)
	_ok(sq != null, "%s: SaveQuitConfirm" % tag)
	if sq != null:
		var foot := sq.find_child("Footer", true, false)
		_ok(foot.get_child(0).name == "CancelButton" and foot.find_child("SaveQuitButton", true, false) != null, "%s: Cancel before Save and quit" % tag)
		_ok(get_viewport().gui_get_focus_owner() == foot.get_child(0), "%s: focus starts on Cancel" % tag)
		_ok(Ui5Keycap.all_under(sq).is_empty(), "%s: no keycap in the Save and quit confirm" % tag)
		_small(sq, tag + " save-quit", sc)
	(pm.find_child("CancelButton", true, false) as Button).pressed.emit()
	await _frames()
	_ok(pm.confirm_dialog() == null, "%s: Cancel closes" % tag)
	# Abandon: Keep playing first with Space, danger button, stake line from MetaState
	(pm.rows["Abandon"] as Button).pressed.emit()
	await _frames()
	var ab := pm.find_child("AbandonConfirm", true, false)
	_ok(ab != null, "%s: AbandonConfirm" % tag)
	if ab != null:
		var foot2 := ab.find_child("Footer", true, false)
		_ok(foot2.get_child(0).name == "KeepPlayingButton" and foot2.find_child("AbandonButton", true, false) != null, "%s: Keep playing first" % tag)
		_ok(get_viewport().gui_get_focus_owner() == foot2.get_child(0), "%s: focus starts on Keep playing" % tag)
		_ok(ab.find_child("KeepPlayingButton", true, false).find_child("KeyCap", true, false) != null, "%s: Keep playing has the Space cap" % tag)
		var keep := ab.find_child("KeepPlayingButton", true, false) as Button
		var kcap := keep.find_child("KeyCap", true, false) as Control
		var nb := keep.get_theme_stylebox("normal") as StyleBoxFlat
		_ok(nb != null and nb.bg_color.a > 0.0, "%s: Keep playing has a fill" % tag)
		var tw := keep.get_theme_font("font").get_string_size(keep.text, HORIZONTAL_ALIGNMENT_LEFT, -1, keep.get_theme_font_size("font_size")).x
		var text_l := (keep.size.x - float(UI3Theme.space("12")) - kcap.size.x) * 0.5 - tw * 0.5
		var group_c := (text_l + kcap.position.x + kcap.size.x) * 0.5
		_ok(absf(group_c - keep.size.x * 0.5) <= 2.0, "%s: Keep playing label + cap centred in the button (c=%.1f w=%.1f)" % [tag, group_c, keep.size.x])
		_ok((ab.find_child("AbandonButton", true, false) as Button).theme_type_variation == &"ButtonDanger", "%s: btn-danger" % tag)
		_ok(ab.find_child("StakeLine", true, false) != null and _text_has(ab, "25 Shard"), "%s: stake line from MetaState" % tag)
		_ok(not _text_has(ab, "60 Shard"), "%s: no illustration stake" % tag)
		_ok(Align.pairs(ab) > 0 and Align.check(ab).is_empty(), "%s: stake icon/label centred" % tag)
		_small(ab, tag + " abandon", sc)
	var abandoned := [0]
	pm.abandon_confirmed.connect(func() -> void: abandoned[0] += 1)
	(pm.find_child("KeepPlayingButton", true, false) as Button).pressed.emit()
	await _frames()
	_ok(abandoned[0] == 0 and pm.confirm_dialog() == null, "%s: Keep playing leaves the run" % tag)
	(pm.rows["Abandon"] as Button).pressed.emit()
	await _frames()
	(pm.find_child("AbandonButton", true, false) as Button).pressed.emit()
	_ok(abandoned[0] == 1, "%s: Abandon run emits" % tag)
	# Esc: no dialog -> resumed; dialog open -> closes only the dialog
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	var resumed := [0]
	pm.resumed.connect(func() -> void: resumed[0] += 1)
	(pm.rows["SaveQuit"] as Button).pressed.emit()
	await _frames()
	pm._unhandled_input(esc)
	_ok(pm.confirm_dialog() == null and resumed[0] == 0, "%s: Esc closes the open dialog only" % tag)
	await _frames()
	pm._unhandled_input(esc)
	_ok(resumed[0] == 1, "%s: Esc with no dialog resumes" % tag)
	pm.queue_free()
	await _frames(2)


func _text_has(root: Node, needle: String) -> bool:
	for l in root.find_children("*", "Label", true, false):
		if (l as Label).text.contains(needle):
			return true
	return false
