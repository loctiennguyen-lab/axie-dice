extends Node
## M1 Run Setup: scene loads, every state renders, Begin passes the chosen params to the run start,
## locked Ascension / Full cannot be picked, a duplicate Axie cannot take two slots.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()
var _got_params: Dictionary = {}


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _hook(params: Dictionary) -> Dictionary:
	_got_params = params
	return {"ok": true, "code": ""}


func _hook_fail(_p: Dictionary) -> Dictionary:
	return {"ok": false, "code": "net"}


func _make(st := "normal") -> RunSetup:
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.state = st
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	add_child(s)
	await get_tree().process_frame
	return s


func _ready() -> void:
	print("=== t_run_setup: start ===")
	_guard.capture()
	MetaState.asc_max = 3
	MetaState.runs = 9
	MetaState.unlocks.erase("u_full")
	MainMenu.pending_team = []

	var s := await _make()
	_ok(s.filled_count() == 5, "default party has 5")
	_ok(s.get_node_or_null("Panel/Col/Scroll") == null and s.find_child("PartyRow", true, false) != null, "party row exists")
	_ok(s.find_child("KitBoon", true, false) != null, "Kit/Boon shown when not newcomer")
	_ok(s.find_child("Fairness", true, false) != null, "fairness line present")
	# Locked ascension
	_ok(not s.select_ascension(4), "A4 locked refused")
	_ok(s.ascension == 0, "ascension unchanged after refused pick")
	(s.find_child("Asc9", true, false) as Button).pressed.emit()
	_ok(s.ascension == 0, "pressing locked chip does not select")
	_ok(s.select_ascension(3), "A3 unlocked accepted")
	# Full locked
	_ok(not s.select_length("full"), "Full locked refused")
	_ok(s.mode == "short", "mode stays short")
	MetaState.unlocks.append("u_full")
	_ok(s.select_length("full"), "Full accepted once unlocked")
	# Slots
	_ok(not s.set_slot(1, s.party[0]), "same Axie cannot be in two slots")
	s.clear_slot(4)
	_ok(s.filled_count() == 4, "clear removes")
	_ok(s.begin_block_reason().begins_with("Pick 1 more Axie"), "reason for missing Axie")
	_ok((s.find_child("Begin", true, false) as Button).disabled, "Begin disabled with 4")
	s.open_picker(4)
	await get_tree().process_frame
	_ok(s.find_child("Picker", true, false) != null, "picker renders")
	_ok((s.find_child("Tile_%s" % s.party[0], true, false) as Button).disabled, "taken tile disabled in picker")
	(s.find_child("Tile_bird1", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_ok(s.party[4] == "bird1" and s.filled_count() == 5, "picker fills slot")
	_ok(s.find_child("Picker", true, false) == null or s.find_child("Picker", true, false).is_queued_for_deletion(), "picker closed")
	# Begin -> params
	s.start_hook = _hook
	await s.begin()
	_ok(_got_params.get("mode") == "full" and int(_got_params.get("ascension")) == 3, "params mode/asc")
	_ok((_got_params.get("team_keys") as Array).size() == 5 and (_got_params["team_keys"] as Array)[4] == "bird1", "params team")
	s.start_hook = _hook_fail
	var r := await s.begin()
	_ok(not r.ok and s.begin_error != "" and s.find_child("Banner", true, false) != null, "rejected Begin shows banner")
	# Real RunState start
	s.start_hook = Callable()
	s.set_state("normal")
	var rr := await s.begin()
	_ok(rr.ok and RunState.roster.size() == 5 and RunState.mode == "full" and RunState.ascension == 3, "real RunState.begin_run called with params")
	# other states
	for st in ["loading", "offline", "open_run", "normal"]:
		s.set_state(st)
		await get_tree().process_frame
		_ok(s.state == st, "state %s" % st)
	s.set_state("offline")
	_ok(s.begin_block_reason().begins_with("Needs a connection"), "offline reason")
	_ok((s.find_child("Begin", true, false) as Button).disabled, "offline disables Begin")
	s.queue_free()
	await get_tree().process_frame
	# State derived from a stubbed AccountService status
	for pair in [[AccountService.Status.OFFLINE, "offline"], [AccountService.Status.GUEST, "normal"], [AccountService.Status.SAVED, "normal"]]:
		var sa: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
		var cur: Array = [pair[0]]
		sa.account_status_hook = func() -> int: return cur[0]
		sa.remote_on = true
		sa.no_scene_change = true
		add_child(sa)
		await get_tree().process_frame
		_ok(sa.state == pair[1], "account status %d -> %s" % [pair[0], pair[1]])
		if pair[1] == "normal":
			cur[0] = AccountService.Status.OFFLINE
			var rb := await sa.begin()
			_ok(not rb.ok and sa.state == "offline", "begin re-checks account")
		sa.queue_free()
	# Local dice (remote flag off): OFFLINE shows the banner, Begin stays enabled
	var sl := await _make("offline")
	sl.remote_on = false
	sl.set_state("offline")
	_ok(sl.begin_block_reason() == "" or sl.begin_block_reason().begins_with("Pick"), "local mode: offline does not block")
	_ok(sl.find_child("Banner", true, false) != null, "local mode: offline banner shown")
	sl.queue_free()
	# all ascensions render
	MetaState.asc_max = 10
	var s2 := await _make()
	for n in 11:
		_ok(s2.select_ascension(n), "A%d selectable at max 10" % n)
		await get_tree().process_frame
	# newcomer
	s2.queue_free()
	MetaState.runs = 1
	var s3 := await _make("loading")
	_ok(s3.find_child("KitBoon", true, false) == null, "newcomer hides Kit/Boon")
	s3.queue_free()
	_guard.restore()
	if _fail.is_empty():
		print("t_run_setup: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_run_setup: FAIL")
		get_tree().quit(1)
