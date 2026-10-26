extends Node
## "This version is out of date" modal: shown for 409 `version` and 409 `mission_needs_update` from every place
## that calls a run (NetNotice, RunSetup, MissionsScreen), never a raw code. No network: fake RunSession http.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _texts(n: Node, out: Array) -> void:
	if n is Label:
		out.append((n as Label).text)
	for c in n.get_children():
		_texts(c, out)


func _ready() -> void:
	print("=== t_version_409_screen: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	MetaState.saved_run_probe = func() -> bool: return false
	var opened: Array = []
	UpdateRequired.open_url_hook = func(url: String) -> void: opened.append(url)
	_ok(UpdateRequired.is_update_code("version") and UpdateRequired.is_update_code("mission_needs_update"), "both codes mean update")
	_ok(not UpdateRequired.is_update_code("offline") and not UpdateRequired.is_update_code("tier_locked"), "other codes do not")
	_ok(UpdateRequired.DOWNLOAD_URL.begins_with("https://"), "download link is a constant")
	for code in ["version", "mission_needs_update"]:
		var tx := UpdateRequired.texts_for(code)
		_ok(String(tx[1]).find("Nothing was spent") >= 0 and String(tx[0]).find("_") < 0 and String(tx[1]).find("_") < 0 and String(tx[1]).find("409") < 0, "%s: plain text, no raw code" % code)

	# 1. NetNotice (in-run and Continue) shows the modal, not the toast plate
	for code in ["version", "mission_needs_update"]:
		var host := Control.new()
		add_child(host)
		var layer := NetNotice.show(host, code)
		await get_tree().process_frame
		_ok(layer != null and layer.name == UpdateRequired.NODE_NAME, "%s: NetNotice shows the update modal" % code)
		_ok(host.get_node_or_null(NetNotice.NODE_NAME) == null, "%s: no raw notice under it" % code)
		var dl := host.find_child("DownloadButton", true, false) as Button
		_ok(dl != null and dl.has_focus(), "%s: Download is the focused primary" % code)
		opened.clear()
		dl.pressed.emit()
		_ok(opened == [UpdateRequired.DOWNLOAD_URL], "%s: Download opens the fixed link" % code)
		var txt: Array = []
		_texts(layer, txt)
		_ok("\n".join(txt).find("out of date") >= 0, "%s: says the version is out of date" % code)
		host.queue_free()
	var h2 := Control.new()
	add_child(h2)
	NetNotice.show(h2, "offline")
	_ok(h2.get_node_or_null(NetNotice.NODE_NAME) != null and h2.get_node_or_null(UpdateRequired.NODE_NAME) == null, "other codes keep the old notice")
	h2.queue_free()

	# 2. the 409 bodies travel create_run -> RemoteEpochSource -> the code the screens switch on
	var session := RunSession.new()
	add_child(session)
	var answer := [409, ""]
	var sent: Array = []
	session.http = func(_m: String, path: String, body: String, done: Callable) -> void:
		if path == "/api/run":
			sent.append(JSON.parse_string(body))
		done.call(answer[0], answer[1])
	var params := {"mode": "short", "ascension": 1, "kind": "mission", "team_keys": ["plant1"],
		"mission": {"mission_id": "ms_t", "tier": 2, "stake": 500, "rules": ["M6"]}}
	for code in ["version", "mission_needs_update", "mission_rules_mismatch", "tier_not_unlocked"]:
		answer[1] = JSON.stringify({"error": code})
		var r := RemoteEpochSource.new(session).start_run(params)
		_ok(r.done and not r.ok and r.code == code, "%s passes through (got %s)" % [code, r.code])
	_ok(((sent[0] as Dictionary).get("mission", {}) as Dictionary).get("rules", null) == ["M6"], "create body carries the tier rules")
	session.queue_free()

	# 3. MissionsScreen: an update code from begin_run -> modal + stake returned
	MetaState.runs = 8
	MetaState.runs_with_battle = 8
	MetaState.shard_pool = 5000
	MetaState.starter_shard_locked = 0
	MetaState.mission_escrow = {}
	var s: MissionsScreen = load("res://scenes/missions/MissionsScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = false
	s.no_scene_change = true
	s.test_mode = true
	add_child(s)
	await get_tree().process_frame
	for code in ["version", "mission_needs_update"]:
		s.start_hook = func(_p: Dictionary) -> Dictionary: return {"ok": false, "code": code}
		var res: Dictionary = await s.start("N1")
		await get_tree().process_frame
		_ok(not res.ok and MetaState.shard_pool == 5000 and MetaState.mission_escrow.is_empty(), "%s: stake returned" % code)
		_ok(s.get_node_or_null(UpdateRequired.NODE_NAME) != null, "%s: MissionsScreen shows the update modal" % code)
		(s.get_node(UpdateRequired.NODE_NAME) as Node).queue_free()
		await get_tree().process_frame
	for code in ["tier_not_unlocked", "mission_rules_mismatch", "tier_locked", "zzz"]:
		var et := MissionsScreen.begin_error_text(code)
		_ok(String(et[1]).find("stake was returned") >= 0 or String(et[1]).find("Your stake was returned") >= 0, "%s: error text says the stake came back" % code)
	s.queue_free()
	_ok(RunSetup.begin_error_text("mission_needs_update")[0] == "Update the game", "RunSetup maps mission_needs_update")
	UpdateRequired.open_url_hook = Callable()
	MetaState.saved_run_probe = Callable()
	_guard.restore()
	if _fail.is_empty():
		print("t_version_409_screen: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_version_409_screen: FAIL")
		get_tree().quit(1)
