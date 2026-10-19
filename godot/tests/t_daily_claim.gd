extends Node
## Liam b931: "Claim 300 Gem" on the Daily screen did nothing. With the server wallet the claim is
## asynchronous (reason "pending"); the screen showed nothing and never refreshed. Now: it shows
## "Claiming...", refreshes with the real answer, and a failure gives a toast. No network: a fake transport.

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _screen(kind: String) -> DailyScreen:
	var d: DailyScreen = load("res://scenes/daily/DailyScreen.tscn").instantiate()
	d.use_account = false
	d.remote_on = true
	d.no_scene_change = true
	d.day_override = MetaState.today_utc()
	add_child(d)
	return d


func _ready() -> void:
	print("=== t_daily_claim: start ===")
	_guard.capture()
	var old_wallet := MetaState.gem_wallet()
	MetaState.gems_cache = 0
	MetaState.gem_gift_day = ""
	MetaState.daily_date = MetaState.today_utc()   # daily card out of the way

	# 1. server answers ok after a delay: button must react at once, then show the result
	var pending: Array = []
	var net := func(_m: String, _p: String, _b: String, done: Callable) -> void:
		pending.append(done)
	MetaState.set_gem_wallet(RemoteGemWallet.new(net))
	var d := _screen("ok")
	await get_tree().process_frame
	var btn := d.find_child("ClaimGift", true, false) as Button
	_ok(not btn.disabled, "gift button is claimable")
	btn.pressed.emit()
	await get_tree().process_frame
	_ok(pending.size() == 1, "clicking sent exactly one claim request")
	_ok(d.last_result == "Claiming...", "screen says Claiming... while waiting")
	(d.find_child("ClaimGift", true, false) as Button).pressed.emit()
	_ok(pending.size() == 1, "double click while waiting sends nothing more")
	(pending[0] as Callable).call(200, JSON.stringify({"ok": true, "granted": 300, "reason": "", "balance": 300, "next_utc": 999}))
	await get_tree().process_frame
	_ok(d.last_result == "+300 Gem", "result shown after the server answers")
	_ok(MetaState.gem_gift_day == MetaState.today_utc(), "claimed day recorded")
	_ok((d.find_child("ClaimGift", true, false) as Button).disabled, "button disabled after the claim, says why")
	d.queue_free()

	# 2. server unreachable: a clear message and a toast, button stays usable
	MetaState.gem_gift_day = ""
	MetaState.set_gem_wallet(RemoteGemWallet.new(func(_m: String, _p: String, _b: String, done: Callable) -> void: done.call(0, "")))
	var d2 := _screen("offline")
	await get_tree().process_frame
	(d2.find_child("ClaimGift", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_ok(d2.last_result.begins_with("Couldn't reach the server"), "offline: message says so")
	_ok(d2.find_child("GiftToast", true, false) != null, "offline: toast shown")
	_ok(not (d2.find_child("ClaimGift", true, false) as Button).disabled, "offline: can try again")
	d2.queue_free()

	# 3. local wallet still claims at once
	MetaState.set_gem_wallet(old_wallet)
	MetaState.gems_cache = 0
	MetaState.gem_gift_day = ""
	var d3 := _screen("local")
	await get_tree().process_frame
	(d3.find_child("ClaimGift", true, false) as Button).pressed.emit()
	_ok(MetaState.gems_cache == 300 and d3.last_result == "+300 Gem", "local wallet claims 300 on click")
	d3.queue_free()

	MetaState.set_gem_wallet(old_wallet)
	_guard.restore()
	if _fail.is_empty():
		print("t_daily_claim: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fail:
			print("FAIL: ", f)
		print("t_daily_claim: FAIL")
		get_tree().quit(1)
