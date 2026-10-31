extends Node
## UI-05 b23 lane S3b: Run setup modals (picker, picker-empty, presets-load, presets-save, lb-rows / loading / error /
## empty) against ui05-land-screens.html, 1920 and 1280 (scale 0.667).
## Run: AXIE_TEST_NO_NET=1 godot --headless --path godot res://tests/t_ui5_run_picker.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const ILLUSTRATION := ["Thorn Wall", "Sky Rush", "Old NFT team", "Kestrel", "moonwalker", "Tansy", "Okra", "BeetleBun", "Fennec"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_ui5_run_picker: start ===")
	_guard.capture()
	for sc: float in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc, "1920" if sc == 1.0 else "1280")
	UI3Theme.set_scale_override(1.0)
	_guard.restore()
	if _fails.is_empty():
		print("t_ui5_run_picker: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui5_run_picker: FAIL - ", f)
		get_tree().quit(1)


func _settle() -> void:
	for i in 8:
		await get_tree().process_frame


func _make(sc: float) -> RunSetup:
	var host := Control.new()
	host.name = "Frame"
	host.size = Vector2(1920, 1080) * sc
	add_child(host)
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	host.add_child(s)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _settle()
	return s


func _free(s: Node) -> void:
	s.get_parent().queue_free()
	await get_tree().process_frame


func _modal(s: Node) -> Node:
	return s._modal_layer.get_child(0) if s._modal_layer.get_child_count() > 0 else null


func _has(m: Node, names: Array, tag: String) -> void:
	for n in names:
		_check(m != null and m.find_child(n, true, false) != null, "%s: node %s" % [tag, n])


func _btn(m: Node, n: String) -> Button:
	return m.find_child(n, true, false) as Button


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


func _audit(m: Node, sc: float, tag: String, pairs := false) -> void:
	var frame := Rect2(Vector2.ZERO, Vector2(1920, 1080) * sc)
	for n in m.find_children("*", "", true, false):
		if (n is Label or n is Button) and (n as Control).is_visible_in_tree() and String(n.text).strip_edges() != "":
			_check(float(n.get_theme_font_size("font_size")) * sc >= 13.99, "%s: '%s' is %.1f real px (< 14)" % [tag, String(n.text).left(20), n.get_theme_font_size("font_size") * sc])
	var bad: Array[String] = []
	for n in m.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or c.size.x <= 0.0 or c.size.y <= 0.0:
			continue
		var r := c.get_global_rect()
		if r.position.x < -1.0 or r.end.x > frame.end.x + 1.0:
			bad.append("%s x[%.0f..%.0f]" % [c.name, r.position.x, r.end.x])
		elif not _in_scroll(c) and (r.position.y < -1.0 or r.end.y > frame.end.y + 1.0):
			bad.append("%s y[%.0f..%.0f]" % [c.name, r.position.y, r.end.y])
	_check(bad.is_empty(), "%s: all inside the frame (%s)" % [tag, str(bad.slice(0, 4))])
	for pr in Align.check(m, 1.5, tag + ": "):
		_check(false, pr)
	if pairs:
		_check(Align.pairs(m) > 0, "%s: centring check measured no icon / label pair" % tag)
	var txt := _texts(m)
	for b in ILLUSTRATION:
		_check(not txt.contains(b), "%s: no illustration string '%s'" % [tag, b])


func _focus(m: Node, n: String, tag: String) -> void:
	_check(get_viewport().gui_get_focus_owner() == m.find_child(n, true, false), "%s: initial focus on %s (got %s)" % [tag, n, str(get_viewport().gui_get_focus_owner())])


func _caps(b: Button) -> int:
	var n := 0
	for c in b.get_children():
		if c.has_meta("ui5_keycap"):
			n += 1
	return n


func _pass(sc: float, tag: String) -> void:
	MetaState.team_presets = []
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	var s := await _make(sc)
	s.party = ["plant1", "beast1", "aqua1", "reptile1", ""]
	s._refresh_party()
	# picker (all)
	s.open_picker(4)
	await _settle()
	var m := _modal(s)
	_has(m, ["PickerModal", "Title", "AllTab", "StarterTab", "VaultTab", "Grid", "AxieTile", "Portrait", "CancelButton", "PutButton", "InPartyTooltip"], tag + " picker")
	var cls_chips := m.find_children("*Chip", "Button", true, false)
	_check(cls_chips.size() > 0, "%s picker: class chips" % tag)
	_check(m.find_children("AxieTile*", "Button", true, false).size() == MainMenu.T1_HERO_KEYS.size(), "%s picker: one tile per starter" % tag)
	var put := _btn(m, "PutButton")
	_check(put.disabled and put.text.contains("Pick an Axie") and _caps(put) == 0, "%s picker: Put off with the reason, no keycap" % tag)
	_check(s._picker_sel == "" and m.find_children("SelOutline", "Panel", true, false).is_empty(), "%s picker: nothing picked at first" % tag)
	_focus(m, "CancelButton", tag + " picker")
	_check(_caps(_btn(m, "CancelButton")) == 1, "%s picker: Cancel carries the Space keycap" % tag)
	_audit(m, sc, tag + " picker", true)
	# a tile only picks; Put commits
	var tile: Button = null
	for b in m.find_children("AxieTile*", "Button", true, false):
		if not s.party.has(String(b.get_meta("hero_key"))):
			tile = b
			break
	var tkey := String(tile.get_meta("hero_key"))
	tile.pressed.emit()
	_check(s.party[4] == "" and not put.disabled, "%s picker: tile picks, Put enables, nothing seated yet" % tag)
	put.pressed.emit()
	await _settle()
	_check(s.party[4] == tkey and _modal(s) == null, "%s picker: Put seats the Axie and closes" % tag)
	# taken tile shows the tip
	s.open_picker(0)
	await _settle()
	m = _modal(s)
	for b in m.find_children("AxieTile*", "Button", true, false):
		if String(b.get_meta("hero_key")) == s.party[1]:
			b.mouse_entered.emit()
	var tip := m.find_child("InPartyTooltip", true, false) as Control
	_check(tip.visible and (tip.get_child(0) as Label).text.contains("swaps"), "%s picker: in-party tip" % tag)
	# picker-empty (Vault empty)
	MetaState.vault = []
	s._picker_tab = "vault"
	s._show_picker()
	await _settle()
	m = _modal(s)
	_has(m, ["PickerModal", "AllTab", "StarterTab", "VaultTab", "EmptyState", "CancelButton", "PutButton"], tag + " picker-empty")
	_check(m.find_children("AxieTile*", "Button", true, false).is_empty() and _btn(m, "PutButton").disabled, "%s picker-empty: no tiles, Put off" % tag)
	_focus(m, "CancelButton", tag + " picker-empty")
	_audit(m, sc, tag + " picker-empty")
	s.close_modal()
	# presets-load with data
	s.party = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	s._refresh_party()
	var sample := ["bird1", "beast1", "bug1", "bird1", "aqua1"]
	TeamPresets.add("Alpha", sample)
	TeamPresets.add("Beta", sample)
	MetaState.team_presets[1]["party"] = ["plant1", "beast1", "aqua1", "reptile1", "vault_missing"]
	s.open_load_presets()
	await _settle()
	m = _modal(s)
	_has(m, ["PresetsModal", "Title", "LoadTab", "SaveTab", "TeamList", "TeamButton", "CancelButton", "LoadButton"], tag + " presets-load")
	var go := _btn(m, "LoadButton")
	_check(go.disabled and go.text.contains("Pick a team") and _caps(go) == 0, "%s presets-load: nothing picked, Load off with reason" % tag)
	_check(m.find_children("TeamButton*", "Button", true, false).size() == 2, "%s presets-load: one button per saved team" % tag)
	_check((m.find_children("TeamButton*", "Button", true, false)[1] as Button).text.contains("1 seats empty"), "%s presets-load: missing seat said" % tag)
	_focus(m, "CancelButton", tag + " presets-load")
	_check(_caps(_btn(m, "CancelButton")) == 1, "%s presets-load: Cancel keycap" % tag)
	_audit(m, sc, tag + " presets-load")
	var before := s.party.duplicate()
	(m.find_children("TeamButton*", "Button", true, false)[0] as Button).pressed.emit()
	_check(not go.disabled and s.party == before, "%s presets-load: pick enables Load, party untouched" % tag)
	go.pressed.emit()
	await _settle()
	_check(s.party == sample and _modal(s) == null, "%s presets-load: Load applies the team" % tag)
	# presets-save: only after Save
	s.open_save_preset()
	await _settle()
	m = _modal(s)
	_has(m, ["PresetsModal", "LoadTab", "SaveTab", "NameField", "SlotLine", "CancelButton", "SaveButton"], tag + " presets-save")
	_focus(m, "NameField", tag + " presets-save")
	_check(_caps(_btn(m, "CancelButton")) == 0 and _caps(_btn(m, "SaveButton")) == 0, "%s presets-save: no keycaps" % tag)
	_audit(m, sc, tag + " presets-save")
	var n0 := TeamPresets.count()
	(m.find_child("NameField", true, false) as LineEdit).text = "Mine"
	(m.find_child("NameField", true, false) as LineEdit).text_changed.emit("Mine")
	_check(TeamPresets.count() == n0, "%s presets-save: typing saves nothing" % tag)
	_btn(m, "CancelButton").pressed.emit()
	await _settle()
	_check(TeamPresets.count() == n0 and _modal(s) == null, "%s presets-save: Cancel saves nothing" % tag)
	s.open_save_preset()
	await _settle()
	m = _modal(s)
	(m.find_child("NameField", true, false) as LineEdit).text = "Mine"
	_btn(m, "SaveButton").pressed.emit()
	await _settle()
	_check(TeamPresets.count() == n0 + 1 and String(MetaState.team_presets[n0]["name"]) == "Mine", "%s presets-save: Save adds the team" % tag)
	# leaderboard
	var st := LeaderboardSourceStub.new()
	s.lb_source = st
	st.boards[LeaderboardSource.query_key({"asc": s.ascension, "period": "season"})] = {"rows": [
		{"rank": 1, "name": "Zed", "score": 9000}, {"rank": 2, "name": "Yan", "score": 8000}], "me": {"rank": 9, "name": "Me", "score": 100}, "updated": "14:05"}
	st.pending = true
	s.open_leaderboard()
	await _settle()
	m = _modal(s)
	_has(m, ["LeaderboardPopup", "Title", "SubLine", "Rows", "Skeleton", "CloseButton", "FullLeaderboardButton"], tag + " lb-loading")
	_focus(m, "CloseButton", tag + " lb-loading")
	_check(_caps(_btn(m, "CloseButton")) == 1, "%s lb-loading: Close keycap" % tag)
	_audit(m, sc, tag + " lb-loading")
	st.release()
	await _settle()
	_has(m, ["Row", "UpdatedLine", "YouTag"], tag + " lb-rows")
	_check(m.find_children("Row*", "PanelContainer", true, false).size() == 3, "%s lb-rows: 2 rows + own" % tag)
	_audit(m, sc, tag + " lb-rows")
	s.close_modal()
	st.boards.clear()
	st.pending = false
	st.boards[LeaderboardSource.query_key({"asc": s.ascension, "period": "season"})] = {"rows": []}
	s.open_leaderboard()
	await _settle()
	m = _modal(s)
	_has(m, ["EmptyState"], tag + " lb-empty")
	_audit(m, sc, tag + " lb-empty")
	s.close_modal()
	st.fail_reason = "offline"
	s.open_leaderboard()
	await _settle()
	m = _modal(s)
	_has(m, ["ErrorState", "ToneDisc", "ErrorLine", "TryAgainButton", "CloseButton", "FullLeaderboardButton"], tag + " lb-error")
	_focus(m, "TryAgainButton", tag + " lb-error")
	_check(_caps(_btn(m, "TryAgainButton")) == 1 and _caps(_btn(m, "CloseButton")) == 0, "%s lb-error: keycap moves to Try again" % tag)
	_audit(m, sc, tag + " lb-error", true)
	await _free(s)
