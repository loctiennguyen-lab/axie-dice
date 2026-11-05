extends Node
## RemoteGemWallet against a fake server (no network): refresh, optimistic spend and its correction,
## the async claim, and that grant() cannot mint Gem.

var _fails := 0


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _ready() -> void:
	var server := {"gem": 100, "spent": [], "claimed": false}
	var net := func(method: String, path: String, body: String, done: Callable) -> void:
		if path == "/api/wallet":
			done.call(200, JSON.stringify({"gem": server["gem"], "ledger_tail": []}))
		elif path == "/api/wallet/spend":
			var b: Dictionary = JSON.parse_string(body)
			(server["spent"] as Array).append(b)
			if int(server["gem"]) >= int(b["amount"]):
				server["gem"] = int(server["gem"]) - int(b["amount"])
				done.call(200, JSON.stringify({"ok": true, "balance": server["gem"]}))
			else:
				done.call(402, JSON.stringify({"ok": false, "balance": server["gem"]}))
		elif path == "/api/gem/claim":
			if server["claimed"]:
				done.call(200, JSON.stringify({"ok": false, "granted": 0, "reason": "already_claimed", "balance": server["gem"], "next_utc": 999}))
			else:
				server["claimed"] = true
				server["gem"] = int(server["gem"]) + 300
				done.call(200, JSON.stringify({"ok": true, "granted": 300, "reason": "", "balance": server["gem"], "next_utc": 999}))
		else:
			done.call(404, "")
	var w := RemoteGemWallet.new(net)
	_check(w.balance() == 0, "starts at 0 until refreshed")
	w.refresh()
	_check(w.balance() == 100, "refresh reads the server balance")
	_check(w.can_afford(100) and not w.can_afford(101), "can_afford uses the cache")

	_check(w.spend(40, "Ticket Bundle!"), "spend within balance")
	_check(w.balance() == 60 and server["gem"] == 60, "cache and server agree after spend")
	var sent: Dictionary = (server["spent"] as Array)[0]
	_check(sent["reason"] == "ticket_bundle_" and String(sent["idem"]).length() >= 8, "reason sanitised, idem key sent")
	_check(not w.spend(61, "too_much"), "spend over the cache refused locally, nothing sent")
	_check((server["spent"] as Array).size() == 1, "no request for a refused spend")

	# the cache is stale-high: server refuses, the wallet corrects itself and says so
	server["gem"] = 10
	var failed := []
	w.spend_failed.connect(func(r: String, b: int) -> void: failed.append([r, b]))
	_check(w.spend(50, "stale"), "optimistic spend allowed from a stale cache")
	_check(w.balance() == 10 and failed == [["stale", 10]], "server refusal corrects the cache and emits spend_failed")

	var pending := w.claim_daily_gift(1000)
	_check(pending["reason"] == "pending" and not pending["ok"], "sync claim returns pending")
	_check(w.balance() == 310, "...but the claim did run and updated the balance")
	var res := []
	w.claim_daily_gift_async(func(r: Dictionary) -> void: res.append(r))
	_check(res[0]["reason"] == "already_claimed" and w.next_claim_utc() == 999, "async claim reports already_claimed")

	w.grant(500, "cheat")
	_check(w.balance() == 310, "grant() cannot mint Gem")
	var off := RemoteGemWallet.new(func(_m: String, _p: String, _b: String, done: Callable) -> void: done.call(0, ""))
	var r2 := []
	off.claim_daily_gift_async(func(r: Dictionary) -> void: r2.append(r))
	_check(r2[0]["reason"] == "offline" and not r2[0]["ok"], "offline claim reports offline")

	# Review 5/11: a GET that left before an optimistic spend answers with the pre-spend balance; it must not
	# flash the old amount back. The spend's own answer sets the server number.
	var held: Array[Array] = []   # [path, done]
	var slow := func(_m: String, path: String, _b: String, done: Callable) -> void: held.append([path, done])
	var ws := RemoteGemWallet.new(slow)
	ws.refresh()
	(held.pop_front()[1] as Callable).call(200, JSON.stringify({"gem": 900}))
	_check(ws.balance() == 900, "slow transport: first refresh lands")
	ws.refresh()                       # GET in flight (server still says 900)
	_check(ws.spend(100, "pull"), "spend while a refresh is in flight")
	_check(ws.balance() == 800, "optimistic drop to 800")
	var get_done: Callable = held[0][1]
	var spend_done: Callable = held[1][1]
	get_done.call(200, JSON.stringify({"gem": 900}))   # stale answer arrives first
	_check(ws.balance() == 800, "stale pre-spend refresh answer does not put 900 back")
	spend_done.call(200, JSON.stringify({"ok": true, "balance": 800}))
	_check(ws.balance() == 800, "spend answer keeps the server number")
	ws.refresh()
	(held[2][1] as Callable).call(200, JSON.stringify({"gem": 750}))
	_check(ws.balance() == 750, "a refresh sent after the spend applies normally")
	# claim that fails while a GET is in flight: the dropped GET must be replaced by a fresh one
	held.clear()
	ws.refresh()                        # GET #1 in flight
	ws.claim_daily_gift_async(Callable())
	(held[1][1] as Callable).call(0, "")   # claim never arrives
	_check(held.size() == 3 and held[2][0] == "/api/wallet", "failed claim re-fetches the wallet")
	(held[0][1] as Callable).call(200, JSON.stringify({"gem": 600}))   # stale GET #1: dropped
	(held[2][1] as Callable).call(200, JSON.stringify({"gem": 640}))   # fresh GET: applies
	_check(ws.balance() == 640, "after a failed claim the cache takes the fresh server balance")
	print("t_remote_gem_wallet: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
