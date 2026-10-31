extends Node
## UI-05 b23 lane S4a: Team presets against t01-t09 (ui05-land-screens.html), 1920 and 1280 (scale 0.667).
## Data-names, nine states, real names from data, text >= 14 real px (Label + Button), inside the frame, icon / label
## centring on > 0 pairs, initial focus, delete only after the confirm.
## Run: AXIE_TEST_NO_NET=1 godot --headless --path godot res://tests/t_ui5_presets.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const SHELL := ["Header", "BackButton", "Title", "SubLine", "MyTeamsTab", "SampleTeamsTab"]
const ILLUSTRATION := ["Thorn Wall", "Sky Rush", "Old NFT team"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_ui5_presets: start ===")
	_guard.capture()
	for sc: float in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc, "1920" if sc == 1.0 else "1280")
	UI3Theme.set_scale_override(1.0)
	_guard.restore()
	if _fails.is_empty():
		print("t_ui5_presets: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui5_presets: FAIL - ", f)
		get_tree().quit(1)


func _settle() -> void:
	for i in 6:
		await get_tree().process_frame


func _make(sc: float, setup := {}) -> TeamPresetsScreen:
	var host := Control.new()
	host.name = "Frame"
	host.size = Vector2(1920, 1080) * sc
	add_child(host)
	var s: TeamPresetsScreen = load("res://scenes/team_presets/TeamPresets.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	for k in setup:
		s.set(k, setup[k])
	host.add_child(s)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _settle()
	return s


func _free(s: Node) -> void:
	s.get_parent().queue_free()
	await get_tree().process_frame


func _has(s: Node, names: Array, tag: String) -> void:
	for n in names:
		_check(s.find_child(n, true, false) != null, "%s: node %s" % [tag, n])


func _btn(s: Node, n: String) -> Button:
	return s.find_child(n, true, false) as Button


func _texts(root: Node) -> String:
	var out := ""
	for n in root.find_children("*", "", true, false):
		if n is Label:
			out += (n as Label).text + "\n"
		elif n is Button:
			out += (n as Button).text + "\n"
	return out


func _in_scroll(c: Node) -> bool:
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


func _audit(s: Node, sc: float, tag: String, pairs := false) -> void:
	var frame := Rect2(Vector2.ZERO, Vector2(1920, 1080) * sc)
	for n in s.find_children("*", "", true, false):
		if (n is Label or n is Button) and (n as Control).is_visible_in_tree() and String(n.text).strip_edges() != "":
			_check(float(n.get_theme_font_size("font_size")) * sc >= 13.99, "%s: '%s' is %.1f real px (< 14)" % [tag, String(n.text).left(20), n.get_theme_font_size("font_size") * sc])
	var bad: Array[String] = []
	for n in s.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or c.size.x <= 0.0 or c.size.y <= 0.0:
			continue
		var r := c.get_global_rect()
		if r.position.x < -1.0 or r.end.x > frame.end.x + 1.0:
			bad.append("%s x[%.0f..%.0f]" % [c.name, r.position.x, r.end.x])
		elif not _in_scroll(c) and (r.position.y < -1.0 or r.end.y > frame.end.y + 1.0):
			bad.append("%s y[%.0f..%.0f]" % [c.name, r.position.y, r.end.y])
	_check(bad.is_empty(), "%s: all inside the frame (%s)" % [tag, str(bad.slice(0, 4))])
	for pr in Align.check(s, 1.5, tag + ": "):
		_check(false, pr)
	if pairs:
		_check(Align.pairs(s) > 0, "%s: centring check measured no icon / label pair" % tag)
	var txt := _texts(s)
	for b in ILLUSTRATION:
		_check(not txt.contains(b), "%s: no illustration string '%s'" % [tag, b])


func _focus(s: Node, n: String, tag: String) -> void:
	_check(get_viewport().gui_get_focus_owner() == s.find_child(n, true, false), "%s: initial focus on %s (got %s)" % [tag, n, str(get_viewport().gui_get_focus_owner())])


func _pass(sc: float, tag: String) -> void:
	var party := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	MetaState.team_presets = []
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	# t01 empty
	var s := await _make(sc)
	_has(s, SHELL + ["EmptyState", "BuildButton"], tag + " t01")
	_check(s.find_child("TeamCard", true, false) == null, "%s t01: no card" % tag)
	_check(_btn(s, "BuildButton").theme_type_variation == "ButtonPrimaryL", "%s t01: BuildButton primary L" % tag)
	_check((s.find_child("SubLine", true, false) as Label).text.begins_with("0 of "), "%s t01: SubLine from data" % tag)
	_focus(s, "BuildButton", tag + " t01")
	_audit(s, sc, tag + " t01")
	await _free(s)

	# t02 grid (3 cards, 6 locked)
	TeamPresets.add("Alpha", party)
	TeamPresets.add("Beta", party)
	MetaState.team_presets[1]["party"] = ["plant1", "beast1", "aqua1", "reptile1", "vault_missing"]
	TeamPresets.add("Gamma", party)
	s = await _make(sc)
	var cards := s.find_children("TeamCard*", "PanelContainer", true, false)
	_has(s, SHELL + ["Grid", "Seat", "SeatMissing", "Name", "NamesLine", "UseButton", "EditButton", "CopyButton", "DeleteButton", "NftTag", "LockedSlot"], tag + " t02")
	_check(cards.size() == 3 and s.find_children("LockedSlot*", "PanelContainer", true, false).size() == 6, "%s t02: 3 cards + 6 locked" % tag)
	_check((cards[0].find_child("Name", true, false) as Label).text == "Alpha", "%s t02: name from data" % tag)
	_check((cards[0].find_child("NamesLine", true, false) as Label).text.contains(" · "), "%s t02: NamesLine from hero names" % tag)
	_check((cards[1].find_child("UseButton", true, false) as Button).text == "Pick a replacement" and cards[1].find_child("SeatMissing", true, false) != null, "%s t02: missing seat -> Pick a replacement" % tag)
	_check((cards[0].find_child("DeleteButton", true, false) as Button).theme_type_variation != "ButtonDanger", "%s t02: card Delete is quiet" % tag)
	_focus(s, "UseButton", tag + " t02")
	_check(s.find_child("PickGrid", true, false) == null and not (s.find_child("Grid", true, false) as Control).get_children().is_empty(), "%s t02: nothing preselected" % tag)
	_audit(s, sc, tag + " t02", true)
	# t07 delete: only after the confirm, safe button first and focused, danger without keycap
	var n0 := TeamPresets.count()
	_btn(cards[2], "DeleteButton").pressed.emit()
	await _settle()
	_has(s, ["DeleteConfirm", "Title", "Body", "Footer", "KeepItButton", "DeletePresetButton", "Scrim"], tag + " t07")
	_check(TeamPresets.count() == n0, "%s t07: nothing deleted before the confirm" % tag)
	var foot := s.find_child("DeleteConfirm", true, false).find_child("Footer", true, false) as Control
	_check(foot.get_child(0) == _btn(s, "KeepItButton"), "%s t07: safe button first" % tag)
	_focus(s, "KeepItButton", tag + " t07")
	_check(_btn(s, "KeepItButton").find_child("KeyCap", true, false) != null and Ui5Keycap.text_of(_btn(s, "KeepItButton").find_child("KeyCap", true, false)) == "Space", "%s t07: Space keycap on Keep it" % tag)
	_check(_btn(s, "DeletePresetButton").find_child("KeyCap", true, false) == null and _btn(s, "DeletePresetButton").theme_type_variation == "ButtonDanger", "%s t07: danger button, no keycap" % tag)
	_audit(s, sc, tag + " t07")
	_btn(s, "DeletePresetButton").pressed.emit()
	await _settle()
	_check(TeamPresets.count() == n0 - 1 and s.find_child("DeleteConfirm", true, false) == null, "%s t07: Delete preset removes" % tag)
	TeamPresets.add("Gamma", party)
	s.refresh()
	await _settle()
	# t04 editor (edit): name field focus, Delete present
	s.open_editor(0)
	await _settle()
	_has(s, ["EditorModal", "NameField", "Seats", "SeatRow", "Portrait", "SwapButton", "ClearButton", "DeleteButton", "CancelButton", "SaveButton", "Scrim"], tag + " t04")
	_check(s.find_children("SeatRow*", "PanelContainer", true, false).size() == 5, "%s t04: 5 SeatRows" % tag)
	_check((s.find_child("NameField", true, false) as LineEdit).text == "Alpha", "%s t04: name from data" % tag)
	_focus(s, "NameField", tag + " t04")
	_check(_btn(s, "SaveButton").find_child("KeyCap", true, false) == null, "%s t04: no keycap" % tag)
	_audit(s, sc, tag + " t04", true)
	# t05 picker: nothing picked, Cancel focused, Put disabled with reason
	_btn(s, "SwapButton").pressed.emit()
	await _settle()
	_has(s, ["PresetPicker", "AllTab", "AxieTile", "CancelButton", "PutButton"], tag + " t05")
	var put := s.find_child("PutButton", true, false) as Button
	_check(put.disabled and put.text == "Pick an Axie first" and put.find_child("KeyCap", true, false) == null, "%s t05: Put disabled, says why, no keycap" % tag)
	var pk := s.find_child("PresetPicker", true, false)
	_check(pk.find_child("CancelButton", true, false).has_focus(), "%s t05: Cancel has focus" % tag)
	_check(pk.find_child("CancelButton", true, false).find_child("KeyCap", true, false) != null, "%s t05: Space keycap on Cancel" % tag)
	for t in pk.find_children("AxieTile*", "Button", true, false):
		_check(not (t as Button).button_pressed, "%s t05: no tile preselected" % tag)
	_check(pk.find_child("PlantTab", true, false) != null, "%s t05: class tab from data" % tag)
	_audit(s, sc, tag + " t05", true)
	# t06 discard
	s._close_picker()
	s.set_edit_name("Changed")
	s.request_cancel()
	await _settle()
	_has(s, ["DiscardConfirm", "KeepEditingButton", "DiscardButton"], tag + " t06")
	_focus(s, "KeepEditingButton", tag + " t06")
	_check(_btn(s, "DiscardButton").find_child("KeyCap", true, false) == null and s.view == "editor", "%s t06: Discard no keycap, editor still open" % tag)
	_audit(s, sc, tag + " t06")
	s.close_modal()
	s.cancel_editor()
	# t08 editor (new, full list -> remove one so there is room)
	TeamPresets.remove(2)
	s.open_editor(-1)
	await _settle()
	_check(_btn(s, "SaveButton").disabled and _btn(s, "SaveButton").text.contains("Give the team a name") and s.find_child("EditorModal", true, false).find_child("DeleteButton", true, false) == null, "%s t08: Save disabled with reason, no Delete" % tag)
	_audit(s, sc, tag + " t08", true)
	s.cancel_editor()
	# t03 samples
	s.switch_tab("samples")
	await _settle()
	_has(s, SHELL + ["Samples", "SampleCard", "UseButton"], tag + " t03")
	_check(s.find_children("SampleCard*", "PanelContainer", true, false).size() == ContentDB.GUIDES.size(), "%s t03: one card per guide" % tag)
	_check((s.find_child("SubLine", true, false) as Label).text == "From Guides", "%s t03: SubLine" % tag)
	_audit(s, sc, tag + " t03", true)
	await _free(s)

	# t09 guest
	s = await _make(sc, {"guest": true})
	_has(s, ["GuestBanner", "ToneDisc", "SignInButton", "Grid"], tag + " t09")
	_check((s.find_child("ToneDisc", true, false) as Control).get_meta("tone") == &"info", "%s t09: info disc" % tag)
	_audit(s, sc, tag + " t09", true)
	await _free(s)
