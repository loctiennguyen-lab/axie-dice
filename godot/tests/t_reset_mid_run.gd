extends Node
## BUG-0004: a reset that arrives while the player is inside a run (scene is not Land/menu) still gives the server's
## balances at once; only the local wipe waits, and lands when the run is over.
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
	MetaState.reload_from_store()
	MetaState.shard_pool = 560
	MetaState.stone = 500
	MetaState.runs = 7
	MetaState.econ_reset_seen = "old"
	MetaState.save_to_disk()
	get_tree().current_scene = self   # not a Land/menu scene
	RunState.phase = RunState.RunPhase.COMBAT
	var snap := {"shard": 500, "stone": 0, "ticket": 3, "reset_id": "m5", "unlocks": ["u1"]}
	MetaState.apply_server_econ(snap)
	_check(MetaState.shard_pool == 500 and MetaState.stone == 0 and int(MetaState.tickets["normal"]) == 3, "mid-run: balances already the server's")
	_check(MetaState.runs == 7 and MetaState.econ_reset_seen == "old" and MetaState.has_pending_reset(), "mid-run: wipe postponed")
	# the run pays out: a newer snapshot arrives (same reset id as the pending one)
	MetaState.apply_server_econ({"shard": 530, "stone": 0, "ticket": 3, "reset_id": "m5", "unlocks": ["u1"]})
	_check(MetaState.shard_pool == 530, "mid-run: later snapshot still applied")
	RunState.phase = RunState.RunPhase.LOST
	RunState.reset()
	_check(MetaState.runs == 0 and MetaState.econ_reset_seen == "m5" and not MetaState.has_pending_reset(), "after the run: wiped, id remembered")
	_check(MetaState.shard_pool == 530 and MetaState.unlocks.has("u1"), "after the run: balances kept (not the older pending snapshot)")
	_guard.restore()
	print("t_reset_mid_run: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
