extends Node
## M1 Run Setup: scene loads, every state renders, Begin passes the chosen params to the run start,
## locked Ascension / Full cannot be picked, a duplicate Axie cannot take two slots.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()
var _got_params: Dictionary = {}
var _daily_used := 1


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
	s.daily_info_hook = func(cb: Callable) -> void: cb.call(true, {"used": _daily_used, "max": 3})
	add_child(s)
	await get_tree().process_frame
	return s


func _ready() -> void:
	print("=== t_run_setup: start ===")
	_guard.capture()
	# L1: defaults are remote; the real RunState.begin_run below runs the local path.
	ProjectSettings.set_setting("axie/epoch_source", "local")
	ProjectSettings.set_setting("axie/gem_wallet", "local")
	MetaState.asc_max = 3
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
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
	_ok(s.party.size() < 5 or s.party[4] != "bird1", "tile only selects")
	(s.find_child("PutInSlot", true, false) as Button).pressed.emit()
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
	# newcomer param reaches the header and RunState (default false)
	var base := {"team_keys": ["bird1", "bird1", "bird1", "bird1", "bird1"], "mode": "short", "ascension": 0}
	var p_nc := base.duplicate(true)
	p_nc["newcomer"] = true
	var r_nc: Dictionary = await RunState.begin_run(p_nc)
	_ok(r_nc.ok and RunState.newcomer == true, "begin_run newcomer:true -> RunState.newcomer")
	var r_df: Dictionary = await RunState.begin_run(base.duplicate(true))
	_ok(r_df.ok and RunState.newcomer == false, "begin_run default newcomer false")
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
	for pair in [[AccountService.Status.OFFLINE, "offline"], [AccountService.Status.GUEST, "guest"], [AccountService.Status.EXPIRED, "guest"], [AccountService.Status.SAVED, "normal"]]:
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
	# L1: guest / expired session cannot begin any kind, sees "Sign in to play" + a Sign in button
	var sg := await _make("guest")
	sg.set_state("guest")
	var signed := [0]
	sg.sign_in_hook = func() -> void: signed[0] += 1
	_ok(sg.begin_block_reason() == "Sign in to play", "guest: Begin reason")
	_ok((sg.find_child("Begin", true, false) as Button).disabled, "guest: Begin disabled")
	for k in ["daily", "ranked"]:
		_ok(sg.kind_block_reason(k) == "Sign in to play", "guest: %s reason" % k)
	var sib := sg.find_child("SignInButton", true, false) as Button
	_ok(sib != null, "guest: Sign in button")
	if sib != null:
		sib.pressed.emit()
	_ok(signed[0] == 1, "guest: Sign in button calls sign-in")
	_ok((await sg.begin()).get("code", "") == "blocked", "guest: begin refused")
	sg.queue_free()
	# Session revoked after the screen opened: server says unauthenticated -> guest state, no retry banner
	var se := await _make("normal")
	se.start_hook = func(_p: Dictionary) -> Dictionary: return {"ok": false, "code": "unauthenticated"}
	await se.begin()
	_ok(se.state == "guest" and se.begin_error == "", "unauthenticated -> Sign in to play")
	_ok(se.find_child("SignInButton", true, false) != null and se.find_child("Try again", true, false) == null, "no retry banner")
	se.queue_free()
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
	MetaState.runs_with_battle = 1
	var s3 := await _make("loading")
	_ok(s3.find_child("KitBoon", true, false) == null, "newcomer hides Kit/Boon")
	_ok(bool(s3.start_params().get("newcomer", false)), "start_params carries newcomer=true for a fresh save")
	s3.queue_free()
	await _kind_tests()
	await _begin_error_tests()
	_guard.restore()
	if _fail.is_empty():
		print("t_run_setup: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_run_setup: FAIL")
		get_tree().quit(1)


func _banners(s: RunSetup) -> int:
	var n := 0
	for c in s.find_child("Panel", true, false).find_children("Banner", "PanelContainer", true, false):
		if not (c as Node).is_queued_for_deletion():
			n += 1
	return n


## 15/10: every create error has its own message (no generic "rejected"), and a new error replaces the old banner.
func _begin_error_tests() -> void:
	var expect := {
		"run_open": "old run", "daily_tries": "No Daily tries left today", "daily_cap": "No runs left today",
		"not_available": "Not available", "newcomer_locked": "Ranked unlocks", "vault_banned": "Imported Axies",
		"version": "Update the game", "offline": "Can't reach"}
	for code in expect.keys():
		var t := RunSetup.begin_error_text(code)
		_ok(String(t[0]).contains(expect[code]), "error text for %s: %s" % [code, t[0]])
		_ok(not String(t[1]).contains("Code:"), "%s: no raw code in the detail" % code)
	_ok(String(RunSetup.begin_error_text("zzz")[1]).contains("Code: zzz"), "unknown code keeps the raw code")
	var s := await _make("normal")
	var codes := ["daily_tries"]
	s.start_hook = func(_p: Dictionary) -> Dictionary: return {"ok": false, "code": codes[0]}
	await s.begin()
	_ok(s.begin_error == "No Daily tries left today" and _banners(s) == 1, "failure shows its message, one banner")
	await s.begin()
	_ok(_banners(s) == 1, "second identical failure replaces the banner, never stacks")
	codes[0] = "version"
	await s.begin()
	_ok(_banners(s) == 1 and s.begin_error == "Update the game", "a different failure replaces it too")
	# a saved run can resume the server run: route to the Continue card, no error banner
	codes[0] = "run_in_progress"
	await s.begin()
	_ok(s.state == "open_run" and s.begin_error == "" and s.find_child("Continue", true, false) != null, "run_in_progress -> Continue card")
	_ok(_banners(s) == 0, "no error banner on the Continue card")
	s.queue_free()
	await get_tree().process_frame


## L1 C2: Daily / Ranked in Run Setup, the Daily-run reward, kind carried by the run.
func _kind_tests() -> void:
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	_daily_used = 1
	var s := await _make()
	_ok(s.kind == "normal" and not bool(s.start_params()["ranked"]) and s.start_params()["kind"] == "normal", "kind starts normal")
	_ok(s.select_kind("daily") and s.kind == "daily", "Daily pickable with tries left")
	_ok(s.start_params()["kind"] == "daily" and not bool(s.start_params()["ranked"]), "Daily params: kind daily, not ranked")
	_ok((s.find_child("ModeDaily", true, false) as Button).text.contains("2 of 3 left"), "Daily shows tries left")
	_ok(s.select_kind("ranked") and bool(s.start_params()["ranked"]) and s.start_params()["kind"] == "ranked", "Ranked pickable for a non-newcomer")
	# a vault Axie in the party blocks Ranked and drops it back to Normal
	var keep := s.party[0]
	s.party[0] = "vault_x1"
	s._refresh_kind()
	_ok(s.kind == "normal" and s.kind_block_reason("ranked").contains("Imported"), "vault Axie blocks Ranked")
	_ok(not s.select_kind("ranked"), "Ranked refused with a vault Axie")
	s.party[0] = keep
	s._refresh_kind()
	# offline blocks both
	s.set_state("offline")
	_ok(not s.select_kind("daily") and not s.select_kind("ranked"), "offline blocks Daily and Ranked")
	s.queue_free()
	# no tries left
	_daily_used = 3
	var s2 := await _make()
	_ok(not s2.select_kind("daily") and s2.kind_block_reason("daily") == "No tries left today", "Daily disabled at 0 tries")
	_ok((s2.find_child("ModeDaily", true, false) as Button).disabled, "Daily button disabled at 0 tries")
	s2.queue_free()
	# newcomer: Ranked locked with the count
	MetaState.runs_with_battle = 2
	var s3 := await _make()
	_ok(s3.kind_block_reason("ranked") == "Opens after 5 runs · 2 of 5" and not s3.select_kind("ranked"), "newcomer: Ranked locked")
	s3.queue_free()
	# local (non-remote) build: both locked, begin untouched
	var s4: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s4.use_account = false
	s4.remote_on = false
	add_child(s4)
	await get_tree().process_frame
	_ok(s4.kind_block_reason("daily") == "Needs the online build" and s4.begin_block_reason() == "", "local build: Daily/Ranked locked, Normal fine")
	s4.queue_free()
	# Daily-run reward: once per UTC day, ledgered, survives reload
	var sh0 := MetaState.shard_pool
	var st0 := MetaState.stone
	MetaState.last_daily_reward_utc = ""
	_ok(MetaState.claim_daily_run_reward(), "daily run reward claimed")
	_ok(MetaState.shard_pool == sh0 + 60 and MetaState.stone == st0 + 500, "reward = 60 Shard + 500 Stone")
	_ok(not MetaState.claim_daily_run_reward() and MetaState.shard_pool == sh0 + 60, "reward is once per UTC day")
	MetaState.save_to_disk()
	MetaState.last_daily_reward_utc = ""
	MetaState.reload_from_store()
	_ok(MetaState.last_daily_reward_utc == MetaState.today_utc() and not MetaState.claim_daily_run_reward(), "claim survives reload")
	# the run carries its kind (and saves it)
	var team: Array[String] = []
	for k in ["bird1", "beast1", "plant1", "aquatic1", "reptile1"]:
		if ContentDB.heroes.has(k):
			team.append(k)
	RunState.start_new_run_seeded(7, {"team_keys": team, "mode": "short", "ascension": 0, "kind": "daily"})
	_ok(RunState.run_kind == "daily" and not RunState.ranked, "RunState keeps kind daily")
	_ok(String(RunState.to_data().get("kind", "")) == "daily", "kind saved with the run")
	RunState.start_new_run_seeded(8, {"team_keys": team, "mode": "short", "ascension": 0, "kind": "ranked"})
	_ok(RunState.run_kind == "ranked" and RunState.ranked, "kind ranked sets ranked")
	_ok(int(RunState.close_summary(true, true).get("score", -1)) >= 150, "close_summary carries the leaderboard score")
	RunState.reset()
