extends Node
## UI-05 b23 lane S7b: Raid against r01-r10 (ui05-meta1-screens.html), 1920 and 1280 (scale 0.667).
## Data-names, the ten states, numbers and names from the (stub) raid data, no illustration string left, text >= 14 real px,
## everything inside the frame, icon / label centring on > 0 pairs, columns that do not depend on text length, initial focus.
## Run: AXIE_TEST_NO_NET=1 godot --headless --path godot res://tests/t_ui5_raid.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const SHELL := ["Header", "BackButton", "Title", "SubLine", "Body", "TopPlate", "PointsLine", "RuleLine", "TeamButton", "DefenceButton", "GhostList"]
## Example values of the HTML frames: they must come from the game, not from this screen.
const ILLUSTRATION := ["Thorn Wall", "Mira", "Kito", "Tuan Anh", "Linh", "Bao"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
var _sent: Array = []
var _answers: Dictionary = {}


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _client() -> RaidClient:
	var c := RaidClient.new()
	c.http = func(method: String, path: String, body: String, cb: Callable) -> void:
		_sent.append({"m": method, "p": path, "b": body})
		var a: Array = _answers.get(path.split("?")[0], [200, "{}"])
		cb.call(a[0], a[1])
	return c


func _opp(i: int, nm: String, keys: Array, power: int) -> Dictionary:
	return {"ghost_id": "%016x" % (i + 1), "name": nm, "team": RaidGhost.snapshot_team(keys), "skin": {}, "power_hint": power}


func _ready() -> void:
	print("=== t_ui5_raid: start ===")
	_guard.capture()
	for sc: float in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc, "1920" if sc == 1.0 else "1280")
	UI3Theme.set_scale_override(1.0)
	_source_check()
	_guard.restore()
	if _fails.is_empty():
		print("t_ui5_raid: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui5_raid: FAIL - ", f)
		get_tree().quit(1)


func _make(sc: float, setup := {}) -> RaidScreen:
	var host := Control.new()
	host.name = "Frame"
	host.size = Vector2(1920, 1080) * sc
	add_child(host)
	var s: RaidScreen = load("res://scenes/raid/Raid.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	s.client = _client()
	for k in setup:
		s.set(k, setup[k])
	host.add_child(s)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await _settle()
	return s


func _settle() -> void:
	for i in 5:
		await get_tree().process_frame


func _free(s: Node) -> void:
	s.get_parent().queue_free()
	await get_tree().process_frame


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


func _small(root: Node, sc: float, tag: String) -> void:
	for n in root.find_children("*", "", true, false):
		if (n is Label or n is Button) and (n as Control).is_visible_in_tree() and String(n.text).strip_edges() != "":
			_check(float(n.get_theme_font_size("font_size")) * sc >= 13.99, "%s: '%s' is %.1f real px (< 14)" % [tag, String(n.text).left(20), n.get_theme_font_size("font_size") * sc])


func _inside(s: Node, frame: Rect2, tag: String) -> void:
	var bad: Array[String] = []
	for n in s.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or c.size.x <= 0.0 or c.size.y <= 0.0:
			continue
		# Anything inside the scroll list may be clipped by it; the list itself and every other control must sit in the frame.
		var r := c.get_global_rect()
		if r.position.x < frame.position.x - 1.0 or r.end.x > frame.end.x + 1.0:
			bad.append("%s x[%.0f..%.0f]" % [c.name, r.position.x, r.end.x])
		elif not _in_scroll(c) and (r.position.y < frame.position.y - 1.0 or r.end.y > frame.end.y + 1.0):
			bad.append("%s y[%.0f..%.0f]" % [c.name, r.position.y, r.end.y])
	_check(bad.is_empty(), "%s: all inside the %.0fx%.0f frame (%s)" % [tag, frame.size.x, frame.size.y, str(bad.slice(0, 4))])


func _in_scroll(c: Node) -> bool:
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


func _audit(s: RaidScreen, sc: float, tag: String, with_pairs := false) -> void:
	_small(s, sc, tag)
	_inside(s, Rect2(Vector2.ZERO, Vector2(1920, 1080) * sc), tag)
	for pr in Align.check(s, 1.5, tag + ": "):
		_check(false, pr)
	if with_pairs:
		_check(Align.pairs(s) > 0, "%s: the centring check measured no icon / label pair" % tag)
	_check(Ui5Keycap.all_under(s).is_empty(), "%s: no keycap (frames draw none)" % tag)
	var txt := _texts(s)
	for bad in ILLUSTRATION:
		_check(not txt.contains(bad), "%s: no illustration string '%s'" % [tag, bad])


func _names(s: Node, extra: Array, tag: String) -> void:
	for n in SHELL + extra:
		_check(s.find_child(n, true, false) != null, "%s: node %s" % [tag, n])


func _pass(sc: float, tag: String) -> void:
	var team_a := RaidGhost.snapshot_team(["beast1", "bug1", "plant1"])
	var opps: Array = []
	for i in 5:
		opps.append(_opp(i, "Zed%d" % i, ["beast1", "bug1", "plant1", "aqua1", "bird1"].slice(0, 3 + (i % 3)), 100 + i * 17))
	_answers["/api/raid/opponents"] = [200, JSON.stringify({"opponents": opps, "points": 8})]
	_answers["/api/raid/defense"] = [200, '{"ok":true,"ghost_id":"aaaaaaaaaaaaaaaa"}']
	MetaState.team_presets = [{"name": "Preset A", "party": ["plant1", "beast1", "aqua1"]}, {"name": "Preset B", "party": ["bug1", "beast1", "aqua1"]}]

	# r01 list: 5 rows, nothing preselected, no InfoLine, buttons by role
	var s := await _make(sc)
	_names(s, ["GhostRow", "FightButton"], tag + " r01")
	_check(s.find_children("GhostRow*", "PanelContainer", true, false).size() == 5, "%s r01: 5 GhostRows (got %d)" % [tag, s.find_children("GhostRow*", "PanelContainer", true, false).size()])
	_check(s.find_children("FightButton", "Button", true, false).size() == 5, "%s r01: 5 FightButtons" % tag)
	_check(s.find_child("InfoLine", true, false) != null and not (s.find_child("InfoLine", true, false) as Control).visible, "%s r01: InfoLine hidden without a message" % tag)
	_check(_btn(s, "DefenceButton").theme_type_variation == "ButtonPrimaryL" and _btn(s, "TeamButton").theme_type_variation == "ButtonSecondary", "%s r01: Defence primary L, Team secondary" % tag)
	_check(_btn(s, "BackButton").text == "←", "%s r01: back arrow" % tag)
	_check(s._points_lbl.text == "Raid points 8 · Next badge at 10 points", "%s r01: PointsLine from data '%s'" % [tag, s._points_lbl.text])
	_check(_btn(s, "TeamButton").text == "Team: Preset A" and not _btn(s, "TeamButton").disabled, "%s r01: TeamButton from presets" % tag)
	var g0 := s.find_child("GhostName", true, false) as Label
	_check(Ui5Ellipsis.full_text(g0).begins_with("Zed0 · power 100"), "%s r01: ghost name + power from data" % tag)
	_check(get_viewport().gui_get_focus_owner() == _btn(s, "DefenceButton"), "%s r01: initial focus on DefenceButton" % tag)
	_audit(s, sc, tag + " r01")
	# columns: same width in every row whatever the text length
	var w0 := (s.find_children("GhostName", "Label", true, false)[0] as Label).size.x
	var all_same := true
	for l in s.find_children("GhostName", "Label", true, false):
		all_same = all_same and absf((l as Label).size.x - w0) < 1.0
	_check(all_same, "%s r01: name column the same width in every row" % tag)
	var tw0 := (s.find_children("GhostTeam", "Label", true, false)[0] as Label).size.x
	var team_same := true
	for l in s.find_children("GhostTeam", "Label", true, false):
		team_same = team_same and absf((l as Label).size.x - tw0) < 1.0
	_check(team_same and tw0 > w0, "%s r01: team column the same width, wider than the name column" % tag)
	var row0 := s.find_children("GhostRow*", "PanelContainer", true, false)[0] as Control
	_check(row0.size.y >= UI3Theme.size_of("raid_row_h") - 1.0, "%s r01: row height >= raid_row_h" % tag)
	# a very long ghost name is cut with an ellipsis, columns unchanged
	s.opponents[0]["name"] = "N".repeat(120)
	s._redraw()
	await _settle()
	var gl := s.find_children("GhostName", "Label", true, false)[0] as Label
	_check(gl.text.ends_with("…") and absf(gl.size.x - w0) < 1.0, "%s r01: long name ends in an ellipsis, column %.0f -> %.0f" % [tag, w0, gl.size.x])
	s.opponents[0]["name"] = "Zed0"
	# r02 defence set
	s.save_defense()
	await _settle()
	_names(s, ["InfoLine", "ToneDisc"], tag + " r02")
	_check(s._info.text == "Defence team set: Preset A." and (s.find_child("ToneDisc", true, false) as Control).get_meta("tone") == &"ok", "%s r02: ok disc + text" % tag)
	_audit(s, sc, tag + " r02", true)
	# r03 win
	s.points = 11
	s.last_result = {"ok": true, "won": true, "ghost": "Zed1", "counted": true, "points": 3, "total": 11, "badge": 1}
	s._show_result()
	s._redraw()
	await _settle()
	_check(s._points_lbl.text == "Raid points 11 · Next badge at 30 points" and (s.find_child("ToneDisc", true, false) as Control).get_meta("tone") == &"ok", "%s r03: win: points + ok disc" % tag)
	_check(s._info.text.contains("+3 Raid points (total 11)") and s._info.text.contains("badge 1"), "%s r03: win text from result" % tag)
	_audit(s, sc, tag + " r03", true)
	# r04 loss, no points
	s.points = 8
	s.last_result = {"ok": true, "won": false, "ghost": "Zed2", "counted": false, "reason": "daily_cap"}
	s._show_result()
	s._redraw()
	await _settle()
	var td := s.find_child("ToneDisc", true, false) as Control
	_check(td.get_meta("tone") == &"info" and td.find_child("Glyph", true, false) is Label and (td.find_child("Glyph", true, false) as Label).text == "i", "%s r04: info disc with 'i'" % tag)
	_check(s._info.text.contains("No points: Daily raid limit reached."), "%s r04: loss text" % tag)
	_audit(s, sc, tag + " r04", true)
	await _free(s)

	# r05 loading: skeleton rows, no ghost rows
	s = await _make(sc)
	s.status = "loading"
	s._redraw()
	await _settle()
	_check(s.find_children("Skeleton*", "Panel", true, false).size() == 2 and s.find_child("GhostRow", true, false) == null, "%s r05: 2 skeleton rows" % tag)
	_check((s.find_children("Skeleton*", "Panel", true, false)[0] as Control).size.y >= UI3Theme.size_of("raid_row_h") - 1.0, "%s r05: skeleton height raid_row_h" % tag)
	_audit(s, sc, tag + " r05")
	await _free(s)

	# r06 empty
	_answers["/api/raid/opponents"] = [200, JSON.stringify({"opponents": [], "points": 8})]
	s = await _make(sc)
	_names(s, ["EmptyState"], tag + " r06")
	_check(s.find_child("GhostRow", true, false) == null and s.find_child("FailedState", true, false) == null, "%s r06: only the EmptyState" % tag)
	_check(_texts(s.find_child("EmptyState", true, false)).strip_edges() == "No ghosts yet. Set your own defence team, others will find it.", "%s r06: empty text" % tag)
	_audit(s, sc, tag + " r06")
	await _free(s)

	# r07 failed: err disc, Retry; Retry reloads
	_answers["/api/raid/opponents"] = [500, '{"error":"server"}']
	s = await _make(sc)
	_names(s, ["FailedState", "ToneDisc", "RetryButton"], tag + " r07")
	_check((s.find_child("ToneDisc", true, false) as Control).get_meta("tone") == &"error" and (s.find_child("FailedState", true, false).find_child("Text", true, false) as Label).text == "Server error. Try again.", "%s r07: error disc + text" % tag)
	_check(get_viewport().gui_get_focus_owner() == _btn(s, "DefenceButton"), "%s r07: focus stays on DefenceButton" % tag)
	_audit(s, sc, tag + " r07", true)
	_sent.clear()
	_answers["/api/raid/opponents"] = [200, JSON.stringify({"opponents": opps, "points": 8})]
	_btn(s, "RetryButton").pressed.emit()
	await _settle()
	_check(_sent.size() == 1 and s.status == "ok" and s.find_child("GhostRow", true, false) != null and s.find_child("FailedState", true, false) == null, "%s r07: Retry reloads the list" % tag)
	await _free(s)

	# r08 guest, r09 offline: DefenceButton disabled with the reason, no Retry, info disc
	_sent.clear()
	for case in [["guest", "Sign in to raid", "Sign in to raid."], ["offline", "Raids need a connection", "Can't reach the server."]]:
		s = await _make(sc, {case[0]: true})
		_names(s, ["FailedState", "ToneDisc"], "%s %s" % [tag, case[0]])
		var db := _btn(s, "DefenceButton")
		_check(db.disabled and db.text == case[1] and Ui5Keycap.all_under(db).is_empty(), "%s %s: DefenceButton disabled, says '%s'" % [tag, case[0], case[1]])
		_check(s.find_child("RetryButton", true, false) == null and _sent.is_empty(), "%s %s: no Retry, no request" % [tag, case[0]])
		var fd := s.find_child("FailedState", true, false)
		_check((fd.find_child("ToneDisc", true, false) as Control).get_meta("tone") == &"info" and (fd.find_child("Text", true, false) as Label).text == case[2], "%s %s: info disc + text" % [tag, case[0]])
		_check(get_viewport().gui_get_focus_owner() == _btn(s, "BackButton"), "%s %s: focus falls to Back" % [tag, case[0]])
		var w := db.size.x
		_check(w >= 1.0, "%s %s: button has width" % [tag, case[0]])
		_audit(s, sc, "%s %s" % [tag, case[0]], true)
		await _free(s)

	# r10 starter team, all badges: no presets, Team disabled, points from data
	_answers["/api/raid/opponents"] = [200, JSON.stringify({"opponents": opps, "points": 312})]
	MetaState.team_presets = []
	s = await _make(sc)
	_check(s._points_lbl.text == "Raid points 312 · All Raid badges earned", "%s r10: points + all badges '%s'" % [tag, s._points_lbl.text])
	_check(_btn(s, "TeamButton").text == "Team: Starter team" and _btn(s, "TeamButton").disabled, "%s r10: Starter team, disabled" % tag)
	s.last_result = {"ok": true, "won": false, "ghost": "Zed3", "counted": true, "points": 1, "total": 313}
	s._show_result()
	await _settle()
	_audit(s, sc, tag + " r10", true)
	# Fight still goes through the same call path
	_sent.clear()
	_answers["/api/raid/start"] = [500, '{"error":"server"}']
	s.challenge(0)
	await _settle()
	_check(not _sent.is_empty() and _sent[0]["p"] == "/api/raid/start" and s._info.text == "Server error. Try again.", "%s r10: Fight calls /api/raid/start, error shown" % tag)
	await _free(s)
	MetaState.team_presets = []
	_answers.erase("/api/raid/start")
	_check(team_a.size() > 0, "%s: fixture team" % tag)


func _source_check() -> void:
	for p in ["res://scenes/raid/RaidScreen.gd", "res://scenes/raid/ui5/RaidParts.gd"]:
		var src := FileAccess.get_file_as_string(p)
		for bad in ["Thorn Wall", "Mira", "Kito", "Tuan Anh", "Pomodoro", "Machito", "312"]:
			_check(not src.contains(bad), "%s: no illustration string '%s' in source" % [p, bad])
