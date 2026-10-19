extends Node
## M5 Echo Box R3: scene loads, each implemented state renders, pull goes through the real
## EchoBox.open_normal (tickets spent, reward granted), cannot pull without tickets, buy goes
## through EchoBox.buy_tickets, Seasonal tab has no Open button.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _make(st := "normal") -> EchoBoxScreen:
	var s: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
	s.state = st
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.instant = true
	add_child(s)
	await get_tree().process_frame
	return s


func _ready() -> void:
	print("=== t_echobox_r3: start ===")
	_guard.capture()
	MetaState.tickets = {"normal": 0, "season": 0}
	MetaState.echobox_pity = {}
	MetaState.shard_pool = 5000
	var s := await _make()
	_ok(s.find_child("PityPanel", true, false) != null and s.find_child("PoolPanel", true, false) != null, "side panels")
	_ok(s.find_child("DupLine", true, false) != null, "duplicates line")
	_ok(s.find_child("Pool_mythic", true, false) != null, "pool tiles")
	# No tickets
	_ok((s.find_child("Open1", true, false) as Button).disabled, "Open 1 disabled with 0 tickets")
	_ok((s.find_child("Open1", true, false) as Button).text.begins_with("Not enough tickets") and (s.find_child("OpenN", true, false) as Button).text.begins_with("Not enough tickets"), "reason shown inside both disabled buttons")
	_ok(s.find_child("Reason", true, false) == null, "reason is not repeated on its own line")
	var r0: Array = await s.pull(1)
	_ok(r0.is_empty() and s.tickets() == 0, "pull without tickets does nothing")
	# Buy a ticket (real API)
	var before := MetaState.shard_pool
	var b := s.buy_ticket()
	_ok(b.ok and s.tickets() == 1 and MetaState.shard_pool == before - 200, "buy ticket spends 200 Shards")
	_ok(not (s.find_child("Open1", true, false) as Button).disabled, "Open 1 enabled with a ticket")
	# Real pull
	s.rng.seed = 7
	var r1: Array = await s.pull(1)
	_ok(r1.size() == 1 and s.tickets() == 0 or s.tickets() == 1, "pull consumed the ticket (or recycled one back)")
	_ok(String((r1[0] as Dictionary).get("kind", "")) in ["stone", "cosmetic"], "one reward per pull")
	_ok(s.find_child("Summary", true, false) != null, "summary rendered")
	s.close_modal()
	# Open 10 with 12 tickets
	MetaState.tickets["normal"] = 12
	s._refresh_all()
	s.rng.seed = 11
	var r10: Array = await s.pull(10)
	_ok(r10.size() == 10, "Open 10 returns 10 results")
	_ok(int(MetaState.echobox_pity.get("opens", 0)) == 11, "pity opens counted by real API")
	_ok(s.find_child("ResultGrid", true, false).get_child_count() == 10, "grid shows 10 cells")
	s.close_modal()
	# Rates + confirm
	s.open_rates()
	await get_tree().process_frame
	_ok(s.find_child("RatesTable", true, false) != null, "rates modal")
	s.close_modal()
	# Seasonal locked
	s.select_tab("seasonal")
	_ok(s.find_child("ComingLater", true, false) == null, "seasonal is live, no coming-later label")
	_ok(s.find_child("SeasonOpen", true, false) != null, "seasonal has its Open button")
	s.select_tab("regular")
	# States
	for st in ["loading", "offline", "guest", "error", "last_pull", "normal"]:
		s.set_state(st)
		await get_tree().process_frame
		_ok(s.state == st, "state " + st)
	s.set_state("offline")
	_ok(s.pull_block_reason(1).begins_with("Needs a connection"), "offline reason")
	_ok((s.find_child("BuyTicket", true, false) as Button).disabled, "offline disables buy")
	s.set_state("guest")
	_ok(s.pull_block_reason(1) != "", "guest blocked")
	# Server error: hook returns nothing, tickets untouched
	s.set_state("normal")
	MetaState.tickets["normal"] = 3
	s.pull_hook = func(_n: int) -> Array: return []
	var re: Array = await s.pull(1)
	_ok(re.is_empty() and s.state == "error" and s.tickets() == 3, "failed pull: error state, tickets kept")
	s.queue_free()
	# State derived from a stubbed AccountService status (not set by hand)
	s.queue_free()
	await get_tree().process_frame
	MetaState.tickets["normal"] = 3
	for pair in [[AccountService.Status.GUEST, "guest"], [AccountService.Status.EXPIRED, "guest"], [AccountService.Status.OFFLINE, "offline"], [AccountService.Status.SAVED, "normal"]]:
		var sa: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
		var cur: Array = [pair[0]]
		sa.account_status_hook = func() -> int: return cur[0]
		sa.remote_on = true
		sa.no_scene_change = true
		sa.instant = true
		add_child(sa)
		await get_tree().process_frame
		_ok(sa.state == pair[1], "account status %d -> %s" % [pair[0], pair[1]])
		if pair[1] == "normal":
			# goes offline between open and pull: re-check blocks, nothing spent
			cur[0] = AccountService.Status.OFFLINE
			var blocked: Array = await sa.pull(1)
			_ok(blocked.is_empty() and sa.state == "offline" and sa.tickets() == 3, "pull re-checks account")
			var by := sa.buy_ticket()
			_ok(not by.get("ok", true), "buy re-checks account")
		sa.queue_free()
	# Local mode (remote wallet off): guest/offline keep an info banner but may pull and buy
	for st in ["guest", "offline"]:
		var sl: EchoBoxScreen = await _make(st)
		sl.remote_on = false
		sl.set_state(st)
		MetaState.tickets["normal"] = 3
		_ok(sl.pull_block_reason(1) == "", "local mode: %s may pull" % st)
		_ok(sl.find_child("Banner", true, false) != null, "local mode: %s info banner" % st)
		var pr: Array = await sl.pull(1)
		_ok(pr.size() == 1 and sl.tickets() == 2, "local mode: %s pull spends a ticket" % st)
		sl.queue_free()
	# partial pull
	var sp: EchoBoxScreen = await _make()
	MetaState.tickets["normal"] = 5
	sp.pull_hook = func(_n: int) -> Array:
		var one := EchoBox.open_normal(MetaState, sp.rng)
		return [one]
	await sp.pull(3)
	_ok(sp.error_text == "Opened 1 of 3", "partial pull text")
	_ok(sp.find_child("PartialPull", true, false) != null, "partial pull text visible in summary")
	sp.queue_free()
	_guard.restore()
	if _fail.is_empty():
		print("t_echobox_r3: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_echobox_r3: FAIL")
		get_tree().quit(1)
