extends Node
## Beta Missions: six tiers from missions.json, one fixed rule set per tier, tier unlock by the server win chain
## (GET /api/missions/unlocks -> MetaState.mission_unlock_cache). No network: a fake transport answers.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _ready() -> void:
	print("=== t_mission_unlock_chain: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	MetaState.saved_run_probe = func() -> bool: return false
	MetaState.runs = 8
	MetaState.runs_with_battle = 8
	var cfg: Dictionary = MissionBoard.config()
	var want := {"N1": [0, "short", []], "N2": [1, "short", ["M6"]], "N3": [3, "short", ["M5", "M6"]],
		"N4": [4, "short", ["M1", "M7"]], "N5": [6, "short", ["M2", "M4", "M5"]], "N6": [6, "full", ["M1", "M5", "M6", "M7"]]}
	for id in want:
		var t: Dictionary = cfg.tiers[id]
		_ok(bool(t.enabled), "%s enabled" % id)
		_ok(int(t.ascension) == int(want[id][0]) and String(t.mode) == String(want[id][1]), "%s ascension and mode" % id)
		_ok((t.rules as Array) == (want[id][2] as Array), "%s fixed rules (the field the Worker checks)" % id)
		_ok(not t.has("unlock_win_asc") and not t.has("unlock_full_a9") and not t.has("house_level"), "%s: old unlock fields gone" % id)
		_ok(typeof(t.get("rules", null)) == TYPE_ARRAY and int(t.get("unlock_wins", 1)) >= 1, "%s rules array + unlock_wins" % id)
	_ok(not cfg.has("rule_sets"), "no A/B rotation")
	var tmp := _has_tmp(cfg)
	if tmp and OS.get_environment("AXIE_RELEASE") == "1":
		_ok(false, "RELEASE: missions.json still holds _tmp / _tmp_note (temp numbers). Replace with N-S numbers.")
	elif tmp:
		print("WARN t_mission_unlock_chain: missions.json still holds TEMP numbers (_tmp). Lane I: replace with N-S numbers before R1 (AXIE_RELEASE=1 makes this a FAIL).")

	# the chain from the cache
	MetaState.set_mission_unlocks([], false)
	_ok(MissionBoard.lock_reason("N1", MetaState) == "", "N1 always open")
	for id in ["N2", "N3", "N4", "N5", "N6"]:
		_ok(MissionBoard.lock_reason(id, MetaState) == "chain", "%s locked with an empty cache" % id)
	var calls: Array = []
	var board := {"tiers": {"N1": {"unlocked": true, "wins": 2, "needs": 0}, "N2": {"unlocked": true, "wins": 1, "needs": 1},
		"N3": {"unlocked": false, "wins": 0, "needs": 1}, "N4": {"unlocked": false, "wins": 0, "needs": 1},
		"N5": {"unlocked": false, "wins": 0, "needs": 1}, "N6": {"unlocked": false, "wins": 0, "needs": 1}}}
	var http_code := [200]
	MissionEscrowSync.transport_override = func(method: String, path: String, _b: String, done: Callable) -> void:
		calls.append(method + " " + path)
		done.call(http_code[0], JSON.stringify(board) if http_code[0] == 200 else "")
	var res: Array = [null]
	MissionEscrowSync.fetch_unlocks(func(ok: bool) -> void: res[0] = ok, true)
	_ok(res[0] == true and calls == ["GET /api/missions/unlocks"], "fetch asks GET /api/missions/unlocks")
	_ok(MetaState.mission_unlock_cache == ["N1", "N2"], "cache = unlocked tiers from the server: %s" % str(MetaState.mission_unlock_cache))
	_ok(MissionBoard.lock_reason("N2", MetaState) == "" and MissionBoard.lock_reason("N3", MetaState) == "chain", "N2 open, N3 still locked")
	# offline / error / garbage: cache untouched
	http_code[0] = 0
	MissionEscrowSync.fetch_unlocks(func(ok: bool) -> void: res[0] = ok, true)
	_ok(res[0] == false and MetaState.mission_unlock_cache == ["N1", "N2"], "offline: cache kept")
	http_code[0] = 200
	_ok(not MissionBoard.apply_unlocks(MetaState, "nope") and not MissionBoard.apply_unlocks(MetaState, {"x": 1}), "garbage answer refused")
	_ok(MetaState.mission_unlock_cache == ["N1", "N2"], "garbage answer changes nothing")
	# server kill switch: unlocked=false + locked_reason tier_locked reads "Closed for now", not a win-chain lock
	MissionBoard.apply_unlocks(MetaState, {"tiers": {"N1": {"unlocked": true, "wins": 0, "needs": 0}, "N2": {"unlocked": false, "wins": 3, "needs": 1, "locked_reason": "tier_locked"}}})
	_ok(MissionBoard.lock_reason("N2", MetaState) == "disabled", "tier_locked from the server = disabled, not chain")
	MissionBoard.apply_unlocks(MetaState, board)
	# lock text from the win counts (unlock_wins > 1 case and the plain one)
	var s: MissionsScreen = load("res://scenes/missions/MissionsScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = false
	s.no_scene_change = true
	add_child(s)
	await get_tree().process_frame
	_ok(s.lock_text(s.offer("N3")) == "Win N2 to unlock", "lock text N3: " + s.lock_text(s.offer("N3")))
	_ok(s.lock_text(s.offer("N6")) == "Unlock N5 first", "lock text N6: " + s.lock_text(s.offer("N6")))
	var fake := {"tier": "N3", "lock_reason": "chain", "unlock_prev": "N2", "unlock_need": 2, "unlock_wins": 1}
	_ok(s.lock_text(fake) == "Win N2 2 times to unlock (1/2)", "lock text with 2 wins: " + s.lock_text(fake))
	_ok(s.block_reason("N3") == "Win N2 to unlock", "disabled button reason")
	MissionBoard.apply_unlocks(MetaState, {"tiers": {"N2": {"unlocked": false, "wins": 3, "needs": 1, "locked_reason": "tier_locked"}}})
	_ok(s.lock_text(s.offer("N2")) == "Closed for now", "card says Closed for now: " + s.lock_text(s.offer("N2")))
	MissionBoard.server_tiers = {}
	s.queue_free()
	MissionEscrowSync.transport_override = Callable()
	MetaState.saved_run_probe = Callable()
	_guard.restore()
	_finish()


## True when any dictionary level holds a "_tmp" or "_tmp_note" key.
func _has_tmp(v: Variant) -> bool:
	if typeof(v) == TYPE_DICTIONARY:
		for k in (v as Dictionary):
			if String(k) == "_tmp" or String(k) == "_tmp_note" or _has_tmp((v as Dictionary)[k]):
				return true
	elif typeof(v) == TYPE_ARRAY:
		for x in (v as Array):
			if _has_tmp(x):
				return true
	return false


func _finish() -> void:
	if _fail.is_empty():
		print("t_mission_unlock_chain: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_mission_unlock_chain: FAIL")
		get_tree().quit(1)
