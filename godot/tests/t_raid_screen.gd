extends Node
## Raid R1 screen (lane RV): guest/offline say why (online-only), the list renders from a stub transport,
## defence save sends the snapshot, a fight opens the real combat embedded and leaves the run/save alone,
## the result (points / cap / badge) is shown, and the Land entry exists. No network.

var _fails: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()
var _sent: Array = []
var _answers: Dictionary = {}


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fails.append(msg)


func _client() -> RaidClient:
	var c := RaidClient.new()
	c.http = func(method: String, path: String, body: String, cb: Callable) -> void:
		_sent.append({"m": method, "p": path, "b": body})
		var a: Array = _answers.get(path.split("?")[0], [200, "{}"])
		cb.call(a[0], a[1])
	return c


func _screen(setup := {}) -> RaidScreen:
	var s: RaidScreen = load("res://scenes/raid/Raid.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	s.client = _client()
	for k in setup:
		s.set(k, setup[k])
	add_child(s)
	await get_tree().process_frame
	return s


func _ready() -> void:
	print("=== t_raid_screen: start ===")
	_guard.capture()
	MetaState.team_presets = []
	var team := RaidGhost.snapshot_team(["beast1", "bug1", "plant1"])
	var opp := {"ghost_id": "0123456789abcdef", "name": "Mira", "team": team, "skin": {}, "power_hint": 99}
	_answers["/api/raid/opponents"] = [200, JSON.stringify({"opponents": [opp, {"ghost_id": "ffffffffffffffff", "name": "Bad", "team": [], "skin": {}, "power_hint": 1}], "points": 8})]
	_answers["/api/raid/defense"] = [200, '{"ok":true,"ghost_id":"aaaaaaaaaaaaaaaa"}']
	_answers["/api/raid/start"] = [200, JSON.stringify({"challenge_id": "c".repeat(32), "seed": 77, "team": team, "skin": {}, "name": "Mira"})]
	_answers["/api/raid/finish"] = [200, '{"ok":true,"points":3,"counted":true,"total":11,"badge":1}']

	# guest / offline: no request, reason shown, buttons say why
	var g := await _screen({"guest": true})
	_ok(_sent.is_empty() and g.status == "failed", "guest: no request")
	_ok(g._def_btn.disabled and g._def_btn.text.contains("Sign in"), "guest: defence button says why")
	g.queue_free()
	var o := await _screen({"offline": true})
	_ok(_sent.is_empty() and o._def_btn.disabled and o._def_btn.text.contains("connection"), "offline: says why, no request")
	o.queue_free()

	# list
	_sent.clear()
	var s := await _screen()
	_ok(s.status == "ok" and s.opponents.size() == 1, "bad ghost row filtered, got %d" % s.opponents.size())
	_ok(s.points == 8 and s._points_lbl.text.contains("Next badge at 10"), "points + next badge text")
	_ok(s.get_node_or_null("%Ghosts") != null or s._list.get_child_count() == 1, "one row drawn")
	_ok(s.current_party() == ["plant1", "beast1", "aqua1"], "no preset -> starter trio")

	# defence
	_sent.clear()
	s.save_defense()
	var body: Dictionary = JSON.parse_string(_sent[0]["b"])
	_ok(_sent[0]["p"] == "/api/raid/defense" and body["team"].size() == 3 and int(body["power_hint"]) > 0, "defence snapshot sent")
	_ok(s._info.text.begins_with("Defence team set"), "defence confirmation")

	# fight: opens the embedded combat, run/save untouched
	_sent.clear()
	var run_phase = RunState.phase
	s.challenge(0)
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(_sent[0]["p"] == "/api/raid/start", "start sent")
	_ok(s._view != null, "combat embedded")
	if s._view != null:
		var eng: CombatEngine = s._view.get("_combat")
		_ok(eng != null and eng.enemies.size() == 3 and String(eng.enemies[0].custom_state.get("ghost_key", "")) != "", "enemies are the ghost")
		_ok(eng.party.size() == 3, "attacker party")
		_ok(RunState.phase == run_phase, "RunState untouched")
		_sent.clear()
		s._view.call("_finish", true)
		for i in 240:
			if s._view == null:
				break
			await get_tree().process_frame
		_ok(s._view == null, "combat closed after the fight")
		_ok(not _sent.is_empty() and _sent[0]["p"] == "/api/raid/finish", "finish sent")
		if not _sent.is_empty():
			var fb: Dictionary = JSON.parse_string(_sent[0]["b"])
			_ok(fb["won"] == true and fb["challenge_id"] == "c".repeat(32) and String(fb["h"]).length() == 64, "finish body")
		await get_tree().process_frame
		_ok(s.points == 11 and s.result_text().contains("+3 Raid points") and s.result_text().contains("badge 1"), "result text: " + s.result_text())
		_ok(s._info.text == s.result_text(), "result shown")

	# result texts for cap / error
	s.last_result = {"ok": true, "won": false, "ghost": "Mira", "counted": false, "reason": "ghost_cap"}
	_ok(s.result_text().contains("No points") and s.result_text().contains("3 times"), "ghost cap text")
	s.last_result = {"ok": true, "won": true, "ghost": "Mira", "counted": false, "reason": "daily_cap"}
	_ok(s.result_text().contains("Daily raid limit"), "daily cap text")
	s.last_result = {"ok": false, "won": true, "ghost": "Mira", "code": "offline"}
	_ok(s.result_text().contains("could not be saved"), "finish error text")
	s.queue_free()

	# failed list shows retry
	_answers["/api/raid/opponents"] = [500, '{"error":"server"}']
	var f := await _screen()
	_ok(f.status == "failed" and f._list.get_child_count() == 2, "failed list: message + retry")
	f.queue_free()

	# Land entry
	_ok(LandNav.is_available(&"raid"), "LandNav knows raid")
	var land_src := FileAccess.get_file_as_string("res://scenes/land/Land.gd")
	_ok(land_src.contains('&"raid"'), "Land has the Raid button")

	_guard.restore()
	if _fails.is_empty():
		print("t_raid_screen: PASS (%d checks)" % _checks)
	else:
		print("t_raid_screen: FAIL")
		for x in _fails:
			print("  FAIL: ", x)
	get_tree().quit(0 if _fails.is_empty() else 1)
