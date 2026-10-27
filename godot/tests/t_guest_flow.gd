extends Node
## SR1: a guest (no account) on a server-economy build can still start the tutorial run and a normal run,
## and neither run pays the wallet. Calls RunState / AccountService directly, no scenes, no network.
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
	RunState.allow_local_epoch = true   # local source: this test never reaches the server
	var old_src: Variant = ProjectSettings.get_setting("axie/epoch_source", "local")
	ProjectSettings.set_setting("axie/epoch_source", "local")   # project default is remote: that would need a RunSession
	MetaState.shard_pool = 100
	MetaState.stone = 50
	var svc: Node = load("res://autoload/AccountService.gd").new()
	svc.remote_econ_enabled = true
	svc.account = {}
	svc.sync_guest_wallet_flag()
	_check(MetaState.guest_no_wallet, "guest on a server-economy build has no wallet")
	var base := {"team_keys": ["bird1", "bird1", "bird1", "bird1", "bird1"], "mode": "short", "ascension": 0}
	var p_tut := base.duplicate(true)
	p_tut["newcomer"] = true
	var r_tut: Dictionary = await RunState.begin_run(p_tut)
	_check(bool(r_tut.get("ok", false)) and RunState.newcomer, "guest starts the tutorial run")
	RunState.end_run(true)
	_check(MetaState.shard_pool == 100 and MetaState.stone == 50, "tutorial run paid no wallet")
	var r_norm: Dictionary = await RunState.begin_run(base.duplicate(true))
	_check(bool(r_norm.get("ok", false)) and not RunState.newcomer and RunState.roster.size() == 5, "guest starts a normal run")
	RunState.end_run(false)
	_check(MetaState.shard_pool == 100 and MetaState.stone == 50, "normal run paid no wallet")
	svc.free()
	MetaState.guest_no_wallet = false
	ProjectSettings.set_setting("axie/epoch_source", old_src)
	RunState.allow_local_epoch = false
	RunState.reset()
	_guard.restore()
	print("t_guest_flow: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
