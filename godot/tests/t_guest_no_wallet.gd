extends Node
## Guest on a server-economy build: no wallet. Signed-in flag lifts it.
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
	MetaState.shard_pool = 100
	MetaState.stone = 50
	var svc: Node = load("res://autoload/AccountService.gd").new()
	svc.remote_econ_enabled = true
	svc.sync_guest_wallet_flag()
	_check(MetaState.guest_no_wallet, "guest + server economy -> no wallet")
	MetaState.add_shards(10, "earn", false)
	MetaState.add_stone(10, "x", false)
	_check(MetaState.shard_pool == 100 and MetaState.stone == 50, "nothing earned")
	_check(not MetaState.spend("shard", 1, "t", false) and MetaState.buy_unlock("u_hp") != "", "nothing spent or bought")
	svc.account = {"id": "google:1"}
	svc.sync_guest_wallet_flag()
	_check(not MetaState.guest_no_wallet, "signed in -> wallet allowed")
	# The release project sets [axie] econ="remote" (R3); a local-economy dev build needs both switches off.
	var econ_before: Variant = ProjectSettings.get_setting("axie/econ", "local")
	ProjectSettings.set_setting("axie/econ", "local")
	svc.remote_econ_enabled = false
	svc.account = {}
	svc.sync_guest_wallet_flag()
	_check(not MetaState.guest_no_wallet, "local economy (tests/dev) -> unchanged")
	ProjectSettings.set_setting("axie/econ", econ_before)
	svc.free()
	MetaState.guest_no_wallet = false
	_guard.restore()
	print("t_guest_no_wallet: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
