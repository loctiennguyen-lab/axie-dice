extends Node
## M6 Missions R3: board renders from data (MissionBoard/missions.json), locked tiers cannot start,
## states (newcomer, not enough Shard, open run, offline/guest only block with the remote flag),
## starting passes the mission header to the run start, stake goes through MetaState escrow.

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
	s.test_mode = true
	s.day_override = "2026-10-12"
	add_child(s)
	await get_tree().process_frame
	return s


func _ready() -> void:
	print("=== t_missions_r3: start ===")
	_guard.capture()
	MetaState.saved_run_probe = func() -> bool: return false   # never depend on the real user dir
	MetaState.runs = 8
	MetaState.runs_with_battle = 8
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
	# real escrow path: stake is taken from MetaState, id goes into the mission header
	MetaState.mission_escrow = {}
	MetaState.starter_shard_locked = 0
	_ok(s.block_reason("N1") == "", "N1 startable with enough usable Shard")
	_ok(not (s.find_child("Stake_N1", true, false) as Button).disabled, "Stake button enabled")
	var got: Array = []
	s.start_hook = func(p: Dictionary) -> Dictionary:
		got.append(p)
		return {"ok": true, "code": ""}
	var lk: Dictionary = await s.start("N3")
	_ok(not lk.ok and got.is_empty() and MetaState.mission_escrow.is_empty(), "locked tier cannot start, no stake taken")
	var before := MetaState.shard_pool
	var r: Dictionary = await s.start("N2")
	_ok(r.ok and got.size() == 1, "N2 starts")
	_ok(MetaState.shard_pool == before - int(cfg.tiers.N2.stake), "stake taken once from the pool")
	var p: Dictionary = got[0]
	var m: Dictionary = p.mission
	_ok(String(m.mission_id) != "" and String(m.mission_id) == String(MetaState.mission_escrow.get("mission_id", "x")), "header mission_id = escrow id")
	_ok(p.kind == "mission" and p.mode == "short" and p.ascension == int(cfg.tiers.N2.ascension), "mission params")
	_ok(m.tier == 2 and int(m.stake) == int(cfg.tiers.N2.stake) and is_equal_approx(float(m.m_eff), float(cfg.tiers.N2.m_base) * float(cfg.tiers.N2.m_scale)), "mission header numbers from data")
	_ok((m.rules as Array) == (s.offer("N2").rules as Array), "mission rules = today's rule set")
	MetaState.refund_mission_stake()
	_ok(MetaState.shard_pool == before, "refund restores the pool")
	# re-entrancy: a second start() while the first awaits begin_run takes no second stake
	var slow_n := [0]
	s.start_hook = func(_p: Dictionary) -> Dictionary:
		slow_n[0] += 1
		await s.get_tree().create_timer(0.1).timeout
		return {"ok": true, "code": ""}
	var pool0 := MetaState.shard_pool
	var fres: Array = [{}]
	var runner := func() -> void:
		fres[0] = await s.start("N1")
	runner.call()
	var second: Dictionary = await s.start("N1")
	await get_tree().create_timer(0.3).timeout
	var fr: Dictionary = fres[0]
	_ok(String(second.get("code", "")) == "busy" and fr.ok and slow_n[0] == 1, "second start while busy is refused")
	_ok(MetaState.shard_pool == pool0 - int(cfg.tiers.N1.stake), "exactly one stake taken")
	MetaState.refund_mission_stake()
	_ok(MetaState.shard_pool == pool0, "pool restored after double-start test")
	# run start fails -> stake refunded
	s.start_hook = func(_p: Dictionary) -> Dictionary: return {"ok": false, "code": "busy"}
	var bf: Dictionary = await s.start("N1")
	_ok(not bf.ok and MetaState.shard_pool == before and MetaState.mission_escrow.is_empty(), "failed start refunds")
	# take refused (not enough usable Shard because starter grant is locked): no run
	MetaState.starter_shard_locked = MetaState.shard_pool - 10
	s._refresh()
	_ok(s.usable_shards() == 10 and s.block_reason("N1") != "", "locked starter Shard is not usable")
	got.clear()
	s.start_hook = func(p: Dictionary) -> Dictionary:
		got.append(p)
		return {"ok": true, "code": ""}
	var sf: Dictionary = await s.start("N1")
	_ok(not sf.ok and got.is_empty() and MetaState.shard_pool == before, "insufficient usable Shard: nothing taken, no run")
	MetaState.starter_shard_locked = 0
	s._refresh()
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
	MetaState.shard_pool = 5000
	# newcomer: every card locked
	MetaState.runs = 2
	MetaState.runs_with_battle = 2
	s._refresh()
	var all_locked := true
	for o in s.offers():
		all_locked = all_locked and not bool((o as Dictionary).unlocked) and s.block_reason(String((o as Dictionary).tier)) != ""
	_ok(all_locked, "newcomer: every tier locked")
	MetaState.runs = 8
	MetaState.runs_with_battle = 8
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
	await _l1_n1_to_n3_only(s, cfg)
	MetaState.mission_escrow = {}
	s.queue_free()
	MetaState.saved_run_probe = Callable()
	_guard.restore()
	if _fail.is_empty():
		print("t_missions_r3: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_missions_r3: FAIL")
		get_tree().quit(1)


## B5: L1 = only N1-N3. N4-N6 refused on every path; house stays lv1; N1 flow end to end (local run start).
func _l1_n1_to_n3_only(s: MissionsScreen, cfg: Dictionary) -> void:
	MetaState.runs = 8
	MetaState.runs_with_battle = 8
	MetaState.asc_wins = {"3": 1, "4": 1, "6": 1, "7": 1, "9": 1}
	MetaState.full_a9_won = true
	MetaState.shard_pool = 9000
	MetaState.starter_shard_locked = 0
	MetaState.mission_escrow = {}
	MetaState.mission_house_level = 4   # even a tampered save cannot lift the house
	s.set_state("normal")
	s.remote_on = false
	var big := ["N4", "N5", "N6"]
	for id in ["N1", "N2", "N3"]:
		_ok(bool(cfg.tiers[id].enabled) and MissionBoard.tier_enabled(id), "%s enabled in data" % id)
		var rs: Dictionary = cfg.rule_sets[id]
		for k in ["A", "B"]:
			# approved doc 13/10: rule count per tier matches doc (N1-N2 = 2, N3 = 3), not "<=1"
			_ok((rs[k] as Array).size() == {"N1": 2, "N2": 2, "N3": 3}[id],
				"%s set %s rule count matches missions.json/doc" % [id, k])
	_ok(MissionBoard.house_level(MetaState) == 1, "house stays lv1 even with level 4 in the save")
	_ok(MissionBoard.upgrade_house(MetaState) == "disabled", "house upgrade refused")
	for id in big:
		_ok(not bool(cfg.tiers[id].enabled) and not MissionBoard.tier_enabled(id), "%s disabled in data" % id)
		var o := s.offer(id)
		_ok(not bool(o.enabled) and not bool(o.unlocked) and o.lock_reason == "disabled" and s.lock_text(o) == "Not in this build", "%s offer locked, Not in this build" % id)
		_ok(s.block_reason(id) == "Not in this build", "%s block_reason" % id)
		_ok(MetaState.take_mission_stake(id, int(cfg.tiers[id].stake)) == "" and MetaState.mission_escrow.is_empty() and MetaState.shard_pool == 9000, "%s: stake refused, nothing spent" % id)
		var hit := [0]
		s.start_hook = func(_p: Dictionary) -> Dictionary:
			hit[0] += 1
			return {"ok": true, "code": ""}
		var r: Dictionary = await s.start(id)
		_ok(not r.ok and hit[0] == 0 and MetaState.shard_pool == 9000, "%s: screen start refused" % id)
		# direct API: forged header, no stake needed
		var forged := {"team_keys": ["axie_aquatic"], "mode": "short", "ascension": 9, "ranked": false, "kind": "mission",
			"mission": {"mission_id": "forged", "tier": int(id.substr(1)), "rules": [], "stake": 0, "m_base": 1.0, "m_scale": 1.0, "m_eff": 1.0}}
		var fr: Dictionary = await RunState.begin_run(forged)
		_ok(not fr.ok and String(fr.code) == "tier_disabled", "%s: RunState.begin_run refuses" % id)
	# N1 end to end: stake -> begin_run (real, local) with the header -> win -> payout + Stone
	var stake := int(cfg.tiers.N1.stake)
	var pay := MissionBoard.payout("N1")
	MetaState.shard_pool = 5000
	MetaState.stone = 0
	MetaState.mission_stone_day = {"day": "", "n": 0}
	s.start_hook = Callable()
	s.test_mode = false
	var st: Dictionary = await s.start("N1")
	s.test_mode = true
	_ok(st.ok, "N1 starts through the real begin_run")
	_ok(MetaState.shard_pool == 5000 - stake and not MetaState.mission_escrow.is_empty(), "stake in escrow")
	var mid := MetaState.current_mission_id()
	_ok(String(RunState.mission.get("mission_id", "")) == mid and int(RunState.mission.get("tier", 0)) == 1 and int(RunState.mission.get("stake", 0)) == stake, "run carries the mission header")
	var run_shards := int(RunState.shards_this_run)   # normal run reward, paid on top by end_run
	var stone0 := MetaState.stone
	RunState.end_run(true)
	_ok(MetaState.mission_escrow.is_empty() and int(MetaState.mission_stone_day["n"]) == int(cfg.tiers.N1.stone) and MetaState.stone >= stone0 + int(cfg.tiers.N1.stone), "win: escrow closed, mission Stone paid")
	_ok(MetaState.shard_pool >= 5000 - stake + pay + run_shards, "win: payout %d paid (pool %d, run %d)" % [pay, MetaState.shard_pool, run_shards])
	# lose: stake gone, no Stone
	MetaState.shard_pool = 5000
	s.test_mode = false
	st = await s.start("N1")
	s.test_mode = true
	_ok(st.ok, "N1 starts again")
	var loss_shards := int(RunState.shards_this_run)
	var day_n := int(MetaState.mission_stone_day["n"])
	RunState.end_run(false)
	_ok(MetaState.mission_escrow.is_empty() and int(MetaState.mission_stone_day["n"]) == day_n and MetaState.shard_pool >= 5000 - stake + loss_shards and MetaState.shard_pool < 5000 - stake + pay,
		"loss: stake lost, no payout, no mission Stone")
	# abandon (Settings "Abandon run" path): stake lost, no Stone
	MetaState.shard_pool = 5000
	s.test_mode = false
	st = await s.start("N1")
	s.test_mode = true
	var stone_ab := MetaState.stone
	_ok(st.ok and MetaState.settle_mission_stake(false) and MetaState.shard_pool == 5000 - stake and MetaState.stone == stone_ab and MetaState.mission_escrow.is_empty(),
		"abandon: stake lost, no Stone, no payout")
	RunState.reset()
	MetaState.mission_house_level = 0
