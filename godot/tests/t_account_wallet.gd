extends Node
## AccountService <-> wallet wiring: remote wallet only when the flag is on, and sign-out goes back to local.
var _fails := 0
var _guard := SaveGuard.new()


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	var net := func(_m: String, path: String, _b: String, done: Callable) -> void:
		if path == "/api/wallet":
			done.call(200, JSON.stringify({"gem": 250, "ledger_tail": []}))
		else:
			done.call(404, "")
	var svc: Node = load("res://autoload/AccountService.gd").new()
	svc.transport = net
	var local_before := MetaState.gem_wallet()
	svc._attach_remote_wallet()
	_check(MetaState.gem_wallet() == local_before, "flag off: wallet stays local")
	svc.remote_wallet_enabled = true
	svc._attach_remote_wallet()
	_check(MetaState.gem_wallet() is RemoteGemWallet, "flag on + signed in: remote wallet")
	_check(MetaState.gems_cache == 250, "balance refreshed from server")
	svc._detach_remote_wallet()
	_check(MetaState.gem_wallet() is LocalGemWallet, "sign-out: local wallet again")
	svc.free()
	_guard.restore()
	print("t_account_wallet: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
