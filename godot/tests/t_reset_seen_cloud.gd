extends Node
## A cloud save older than this device's wipe must not bring history back nor reset econ_reset_seen (second wipe).
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
	var svc: Node = load("res://autoload/AccountService.gd").new()
	svc.transport = func(_m: String, _p: String, _b: String, done: Callable) -> void: done.call(200, "{}")
	add_child(svc)
	svc.account = {"id": "google:rs1"}
	SaveStore.profile = "google:rs1"
	MetaState.reload_from_store()
	MetaState.starter_granted = true
	MetaState.econ_reset_seen = "m2"
	MetaState.runs = 1
	MetaState.save_to_disk()
	svc._apply_server({"rev": 3, "meta": {"save_version": 2, "econ_reset_seen": "m1", "runs": 40}, "run": null})
	_check(MetaState.econ_reset_seen == "m2" and MetaState.runs == 1, "cloud from before the wipe: id and history stay as this device has them")
	svc._apply_server({"rev": 4, "meta": {"save_version": 2, "econ_reset_seen": "m2", "runs": 5}, "run": null})
	_check(MetaState.econ_reset_seen == "m2" and MetaState.runs == 5, "cloud of the same reset: taken as before")
	# device that has never seen a reset takes the cloud's id (no wipe twice)
	MetaState.econ_reset_seen = ""
	MetaState.save_to_disk()
	svc._apply_server({"rev": 5, "meta": {"save_version": 2, "econ_reset_seen": "m2", "runs": 6}, "run": null})
	_check(MetaState.econ_reset_seen == "m2", "fresh device takes the cloud's reset id")
	# wipe still waiting for a run to end: cloud does not overwrite
	MetaState.econ_reset_seen = "m2"
	MetaState.runs = 2
	MetaState.save_to_disk()
	MetaState._pending_reset = {"reset_id": "m3"}
	svc._apply_server({"rev": 6, "meta": {"save_version": 2, "econ_reset_seen": "m2", "runs": 50}, "run": null})
	_check(MetaState.runs != 50, "pending wipe: cloud history (50 runs) does not come back")
	MetaState._pending_reset = {}
	svc.queue_free()
	SaveStore.profile = ""
	_guard.restore()
	print("t_reset_seen_cloud: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
