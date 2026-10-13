extends Node
## B2: buying Aid R1 (Continue) / R2 (extra reroll). Prices come from the catalog, one charge, effect applied,
## caps, newcomer / tutorial hidden, not enough Gem, and remote mode never spends locally.

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


class StubStore extends RefCounted:
	var gems_cache := 0
	var ledger: Array = []
	var saves := 0
	func ledger_add(cur: String, delta: int, reason: String) -> void:
		ledger.append([cur, delta, reason])
	func save_to_disk() -> void:
		saves += 1


class CountingWallet extends LocalGemWallet:
	var spends := 0
	func spend(n: int, reason: String, save: bool = true) -> bool:
		spends += 1
		return super.spend(n, reason, save)


class FakeRemote extends EpochSource:
	var reqs: Array = []
	func is_remote() -> bool:
		return true
	func request(kind: String, args: Dictionary) -> EpochReply:
		reqs.append([kind, args.duplicate(true)])
		return EpochReply.ok_reply(4242 + reqs.size())


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _roster(frail: bool) -> Array:
	var out: Array = []
	for i in TEAM.size():
		var mh := int(ContentDB.heroes[TEAM[i]]["max_hp"])
		out.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1, "max_hp": mh, "muts": [], "growth": {},
			"bonus_hp": (1 - mh) if frail else 0})
	return out


func _engine(kind: String, asc: int, frail: bool) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup_new({"node_id": "n1", "kind": kind, "pw": 8, "ascension": asc,
		"roster_snapshot": _roster(frail), "relic_ids": [], "combat_seed": 5})
	e.action_log = ActionLog.new()
	e.action_log.begin(0, TEAM, "short", asc)
	return e


func _wipe(e: CombatEngine) -> void:
	var i := 0
	while not e.lost and i < 40:
		e.end_turn(100 + i)
		i += 1


func _fresh(gems: int) -> Array:
	RunState.aid_uses = []
	RunState.boon_used = false
	RunState.epoch = null
	MetaState.runs_with_battle = 99   # not a newcomer
	var st := StubStore.new()
	st.gems_cache = gems
	var w := CountingWallet.new(st)
	MetaState.set_gem_wallet(w)
	return [st, w]


func _ready() -> void:
	await get_tree().process_frame
	_guard.capture()

	# --- Continue, local: charged once at the catalog price, effect applied, ledgered
	var sw := _fresh(200)
	var st: StubStore = sw[0]
	var w: CountingWallet = sw[1]
	var e := _engine("battle", 0, true)
	_wipe(e)
	_check(e.can_continue(), "wiped")
	var r := AidPurchase.buy("continue", e)
	_check(bool(r["ok"]) and int(r["charged"]) == 90, "local Continue ok, charged 90")
	_check(st.gems_cache == 110 and w.spends == 1, "deducted exactly once (200 -> 110, 1 spend call)")
	_check(not e.lost and e.attempt == 1, "party revived through continue_after_wipe")
	_check(RunState.aid_uses_view().size() == 1 and RunState.aid_uses_view()[0]["aid"] == "R1", "ledger R1")
	_check(String(st.ledger[0][2]) == "aid:R1", "wallet reason aid:R1")
	# second Continue refused by cap_run 1 (party is alive again anyway)
	_wipe(e)
	var r2 := AidPurchase.buy("continue", e)
	_check(not bool(r2["ok"]) and String(r2["code"]) == "cap_type" and st.gems_cache == 110, "Continue cap 1/run, nothing charged")

	# --- Continue on a boss = 180
	sw = _fresh(500)
	st = sw[0]
	var eb := _engine("boss", 0, true)
	_wipe(eb)
	_check(AidPurchase.offer("continue", eb)["price"] == 180, "boss Continue price 180 from the catalog")
	_check(bool(AidPurchase.buy("continue", eb)["ok"]) and st.gems_cache == 320, "boss Continue charged 180")

	# --- Insufficient Gem: disabled with reason, nothing spent, no effect
	sw = _fresh(89)
	st = sw[0]
	var ei := _engine("battle", 0, true)
	_wipe(ei)
	var oi := AidPurchase.offer("continue", ei)
	_check(not bool(oi["enabled"]) and String(oi["reason"]) == "no_gems", "89 Gem: disabled, reason no_gems")
	var ri := AidPurchase.buy("continue", ei)
	_check(not bool(ri["ok"]) and st.gems_cache == 89 and ei.lost, "no charge, no revive")

	# --- Gift Gem pays like any Gem: the wallet balance is the only thing read
	sw = _fresh(90)
	_check(bool(AidPurchase.offer("continue", ei)["enabled"]), "exactly 90 is enough")

	# --- Newcomer and tutorial: hidden
	MetaState.runs_with_battle = 0
	_check(not bool(AidPurchase.offer("continue", ei)["show"]), "newcomer: Continue hidden")
	_check(not bool(AidPurchase.buy("continue", ei)["ok"]) and ei.lost, "newcomer: buy refused")
	MetaState.runs_with_battle = 99
	_check(not bool(AidPurchase.offer("continue", ei, true)["show"]), "tutorial: Continue hidden")

	# --- Extra reroll: charged 15 once, works with 0 rerolls, cap R2 = 4, total cap 6
	sw = _fresh(1000)
	st = sw[0]
	var er := _engine("battle", 0, false)
	er.rerolls = 0
	var uids: Array = []
	for u in er.party:
		if u.hp > 0 and u.has_rolled() and not u.roll_used():
			uids.append(u.uid)
	_check(not uids.is_empty(), "has dice to reroll")
	_check(bool(AidPurchase.offer("extra_reroll", er)["enabled"]), "R2 offered with 0 rerolls")
	var rr := AidPurchase.buy("extra_reroll", er, uids)
	_check(bool(rr["ok"]) and st.gems_cache == 985 and er.rerolls == 0, "R2 charged 15, base rerolls untouched")
	for i in 3:
		er.rerolls = 0
		AidPurchase.buy("extra_reroll", er, uids)
	_check(st.gems_cache == 940, "4 R2 bought = 60 Gem")
	er.rerolls = 0
	var r5 := AidPurchase.buy("extra_reroll", er, uids)
	_check(not bool(r5["ok"]) and String(r5["code"]) == "cap_type" and st.gems_cache == 940, "5th R2 refused (cap 4)")
	# total cap 6 (A0) / 4 (A9)
	_check(AidPurchase.total_cap(0) == 6 and AidPurchase.total_cap(8) == 6 and AidPurchase.total_cap(9) == 4, "total cap 6 / 4 from A9")
	RunState.aid_uses = [{"aid": "R2", "node_id": "a"}, {"aid": "R5", "node_id": "b"}, {"aid": "R6", "node_id": "c"},
		{"aid": "R7", "node_id": "d"}, {"aid": "R7", "node_id": "e"}, {"aid": "R7", "node_id": "f"}]
	_check(String(AidPurchase.offer("extra_reroll", er)["reason"]) == "cap_total", "6 uses: cap_total")

	# --- Remote: the server charges inside the epoch request; local spend is never called
	sw = _fresh(1000)
	st = sw[0]
	w = sw[1]
	var fake := FakeRemote.new()
	RunState.epoch = fake
	var erm := _engine("battle", 0, true)
	erm.set_epoch(fake)
	_wipe(erm)
	fake.reqs.clear()
	var rm := AidPurchase.buy("continue", erm)
	_check(bool(rm["ok"]) and int(rm["charged"]) == 0, "remote Continue ok, client charged 0")
	_check(w.spends == 0 and st.gems_cache == 1000, "remote: wallet.spend never called")
	_check(fake.reqs.size() == 1 and String(fake.reqs[0][0]) == "continue", "exactly one epoch 'continue' request")
	var erm2 := _engine("battle", 0, false)
	erm2.set_epoch(fake)
	erm2.rerolls = 0
	var u2: Array = []
	for u in erm2.party:
		if u.hp > 0 and u.has_rolled() and not u.roll_used():
			u2.append(u.uid)
	fake.reqs.clear()
	RunState.aid_uses = []
	var rm2 := AidPurchase.buy("extra_reroll", erm2, u2)
	_check(bool(rm2["ok"]) and w.spends == 0, "remote R2 ok, no local spend")
	_check(fake.reqs.size() == 1 and fake.reqs[0][1]["source"] == "aid", "one epoch 'reroll' with source=aid")

	RunState.epoch = null
	_guard.restore()
	for f in _fails:
		print("FAIL ", f)
	print("t_aid_purchase: %d checks, %d failed" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("PASS")
	get_tree().quit(1 if not _fails.is_empty() else 0)
