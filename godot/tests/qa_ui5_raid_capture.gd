extends Node
## QA-only, UI-05 b23 lane S7b: shots of r01-r10. Scale pinned from the window.
##   ADT_EVIDENCE_DIR=production/qa/ui05-b23/s7b godot/tools/shot.sh res://tests/qa_ui5_raid_capture.tscn 1280x720
var _guard := SaveGuard.new()
var _dir := QaPaths.evidence_dir()
var _sent := []
var _answers := {}


func _client() -> RaidClient:
	var c := RaidClient.new()
	c.http = func(method: String, path: String, body: String, cb: Callable) -> void:
		var a: Array = _answers.get(path.split("?")[0], [200, "{}"])
		cb.call(a[0], a[1])
	return c


func _shot(frame: String, small: bool) -> void:
	for _i in 10:
		await get_tree().process_frame
	var path := "%s/%s%s.png" % [_dir, frame, "--1280" if small else ""]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui5_raid_capture: saved ", path)


func _make(setup := {}) -> RaidScreen:
	var s: RaidScreen = load("res://scenes/raid/Raid.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	s.client = _client()
	for k in setup:
		s.set(k, setup[k])
	add_child(s)
	return s


func _opp(i: int, nm: String, keys: Array, power: int) -> Dictionary:
	return {"ghost_id": "%016x" % (i + 1), "name": nm, "team": RaidGhost.snapshot_team(keys), "skin": {}, "power_hint": power}


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_dir)
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	var opps := [
		_opp(0, "Mira", ["beast1", "bug1", "plant1"], 412), _opp(1, "Kito", ["bird1", "bird1", "aqua1", "bug1"], 388),
		_opp(2, "Tuan Anh", ["beast1", "beast1", "bug1", "plant1", "aqua1"], 365), _opp(3, "Linh", ["aqua1", "bug1", "bird1"], 290),
		_opp(4, "Bao", ["bug1", "beast1", "plant1", "aqua1"], 251)]
	_answers["/api/raid/opponents"] = [200, JSON.stringify({"opponents": opps, "points": 8})]
	_answers["/api/raid/defense"] = [200, '{"ok":true,"ghost_id":"aaaaaaaaaaaaaaaa"}']
	MetaState.team_presets = [{"name": "Thorn Wall", "party": ["plant1", "beast1", "aqua1"]}, {"name": "Second", "party": ["bug1", "beast1", "aqua1"]}]
	var s := _make()
	await _shot("r01-raid--list", small)
	s.save_defense()
	await _shot("r02-raid--defence-set", small)
	s.points = 11
	s.last_result = {"ok": true, "won": true, "ghost": "Mira", "counted": true, "points": 3, "total": 11, "badge": 1}
	s._show_result()
	s._redraw()
	await _shot("r03-raid--win", small)
	s.points = 8
	s.last_result = {"ok": true, "won": false, "ghost": "Kito", "counted": false, "reason": "daily_cap"}
	s._show_result()
	s._redraw()
	await _shot("r04-raid--loss-no-points", small)
	s.queue_free()
	s = _make()
	s.status = "loading"
	s._redraw()
	await _shot("r05-raid--loading", small)
	s.queue_free()
	_answers["/api/raid/opponents"] = [200, JSON.stringify({"opponents": [], "points": 8})]
	s = _make()
	await _shot("r06-raid--empty", small)
	s.queue_free()
	_answers["/api/raid/opponents"] = [500, '{"error":"server"}']
	s = _make()
	await _shot("r07-raid--failed", small)
	s.queue_free()
	s = _make({"guest": true})
	await _shot("r08-raid--guest", small)
	s.queue_free()
	s = _make({"offline": true})
	await _shot("r09-raid--offline", small)
	s.queue_free()
	_answers["/api/raid/opponents"] = [200, JSON.stringify({"opponents": opps, "points": 312})]
	MetaState.team_presets = []
	s = _make()
	s.last_result = {"ok": true, "won": true, "ghost": "Mira", "counted": true, "points": 3, "total": 312}
	await get_tree().process_frame
	s._show_result()
	await _shot("r10-raid--starter-all-badges", small)
	s.queue_free()
	_guard.restore()
	get_tree().quit(0)
