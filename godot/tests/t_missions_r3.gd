extends Node
## M6 Missions R3: board renders from data (MissionBoard/missions.json), locked tiers cannot start,
## states (newcomer, not enough Shard, open run, offline/guest only block with the remote flag),
## starting passes the mission header to the run start, stake goes through stake_hook only.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _make(st := "normal") -> MissionsScreen:
	var s: MissionsScreen = load("res://scenes/missions/MissionsScreen.tscn").instantiate()
	s.state = st
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.day_override = "2026-10-12"
	add_child(s)
	await get_tree().process_frame
	return s


func _ready() -> void:
	print("=== t_missions_r3: start ===")
	_guard.capture()
	MetaState.runs = 8
	MetaState.asc_wins = {"3": 1, "4": 1}
	MetaState.full_a9_won = false
	MetaState.starter_granted = false
	MetaState.shard_pool = 5000
	var cfg: Dictionary = (load("res://scripts/meta/economy_db.gd") as Script).get_table("missions")
	var s := await _make()
	_ok(s.offers().size() == (cfg.tiers as Dictionary).size(), "one offer per tier in data")
	for id in (cfg.tiers as Dictionary):
		_ok(s.find_child("Card_" + id, true, false) != null, "card " + id)
		var o := s.offer(id)
		_ok(int(o.stake) == int(cfg.tiers[id].stake), "%s stake from data" % id)
		_ok(int(o.payout) == MissionBoard.payout(id), "%s payout from MissionBoard" % id)
	# unlock gates from MetaState
	_ok(bool(s.offer("N1").unlocked) and bool(s.offer("N2").unlocked), "N1/N2 unlocked by asc wins")
	_ok(not bool(s.offer("N3").unlocked) and s.offer("N3").lock_reason == "asc_win", "N3 locked: no A6 win")
	_ok(s.offer("N4").lock_reason == "disabled" and s.offer("N6").lock_reason == "disabled", "N4/N6 not in this build")
	_ok(s.find_child("LockNote", true, false) != null, "lock note shown")
	_ok((s.find_child("UpgradeHouse", true, false) as Button).disabled, "house upgrade disabled in L1")
	# no stake API -> cannot start even when unlocked and rich
	_ok(s.block_reason("N1") == "Staking is not available in this build", "no stake_hook: blocked")
	_ok((s.find_child("Stake_N1", true, false) as Button).disabled, "Stake button disabled without stake API")
	var no: Dictionary = await s.start("N1")
	_ok(not no.ok and RunState.mission.is_empty(), "start without stake API does nothing")
	# stake_hook + start_hook
	var paid: Array = []
	s.stake_hook = func(t: String, n: int) -> bool:
		paid.append([t, n])
		return true
	var got: Array = []
	s.start_hook = func(p: Dictionary) -> Dictionary:
		got.append(p)
		return {"ok": true, "code": ""}
	s._refresh()
	_ok(s.block_reason("N1") == "", "N1 startable with stake API")
	var lk: Dictionary = await s.start("N3")
	_ok(not lk.ok and paid.is_empty() and got.is_empty(), "locked tier cannot start, no stake taken")
	var r: Dictionary = await s.start("N2")
	_ok(r.ok and paid.size() == 1 and paid[0] == ["N2", int(cfg.tiers.N2.stake)], "stake taken once for N2")
	var p: Dictionary = got[0]
	var m: Dictionary = p.mission
	_ok(p.kind == "mission" and p.mode == "short" and p.ascension == int(cfg.tiers.N2.ascension), "mission params")
	_ok(m.tier == 2 and int(m.stake) == int(cfg.tiers.N2.stake) and is_equal_approx(float(m.m_eff), float(cfg.tiers.N2.m_base) * float(cfg.tiers.N2.m_scale)), "mission header numbers from data")
	_ok((m.rules as Array) == (s.offer("N2").rules as Array), "mission rules = today's rule set")
	# stake failure: no run
	s.stake_hook = func(_t: String, _n: int) -> bool: return false
	got.clear()
	var sf: Dictionary = await s.start("N1")
	_ok(not sf.ok and got.is_empty(), "stake refused: no run started")
	s.stake_hook = func(_t: String, _n: int) -> bool: return true
	# run start fails -> refund hook
	var refunded: Array = []
	s.refund_hook = func(t: String, n: int) -> void: refunded.append([t, n])
	s.start_hook = func(_p: Dictionary) -> Dictionary: return {"ok": false, "code": "busy"}
	var bf: Dictionary = await s.start("N1")
	_ok(not bf.ok and refunded.size() == 1, "failed start refunds")
	# confirm modal, focus on Not now, rules text from data
	s.open_confirm("N2")
	await get_tree().process_frame
	_ok(s.find_child("NotNow", true, false) != null and s.find_child("ConfirmStake", true, false) != null, "confirm modal")
	_ok((s.find_child("NotNow", true, false) as Button).has_focus(), "focus starts on Not now")
	_ok(s.rule_lines(s.offer("N2")).size() == 1 + (s.offer("N2").rules as Array).size(), "rule lines: standard + extras")
	s.close_modal()
	# insufficient Shard
	MetaState.shard_pool = int(cfg.tiers.N1.stake) - 50
	s._refresh()
	_ok(s.block_reason("N1") == "Need 50 more Shard", "missing amount shown")
	_ok((s.find_child("Stake_N1", true, false) as Button).text == "Need 50 more Shard", "button shows missing amount")
	# starter shards are not usable
	MetaState.starter_granted = true
	MetaState.shard_pool = 5000
	var st_sh := int(((load("res://scripts/meta/economy_db.gd") as Script).get_table("daily").starter as Dictionary).get("shards", 0))
	_ok(s.usable_shards() == 5000 - st_sh, "starter allowance excluded")
	MetaState.starter_granted = false
	# newcomer: every card locked
	MetaState.runs = 2
	s._refresh()
	var all_locked := true
	for o in s.offers():
		all_locked = all_locked and not bool((o as Dictionary).unlocked) and s.block_reason(String((o as Dictionary).tier)) != ""
	_ok(all_locked, "newcomer: every tier locked")
	MetaState.runs = 8
	# open run blocks
	s.set_state("open_run")
	_ok(s.block_reason("N1") != "" and (s.find_child("Stake_N1", true, false) as Button).disabled, "open run disables cards")
	_ok(s.find_child("Banner", true, false) != null, "open run banner")
	# offline / guest block only with remote flag
	for st in ["offline", "guest"]:
		s.remote_on = true
		s.set_state(st)
		_ok(s.block_reason("N1") != "" and s.find_child("Banner", true, false) != null, "remote: %s blocks staking" % st)
		s.remote_on = false
		s.set_state(st)
		_ok(s.block_reason("N1") == "" and s.find_child("Banner", true, false) != null, "local: %s info banner only" % st)
	s.set_state("loading")
	_ok(s.find_child("Grid", true, false) == null, "loading renders no cards")
	s.queue_free()
	_guard.restore()
	if _fail.is_empty():
		print("t_missions_r3: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_missions_r3: FAIL")
		get_tree().quit(1)
