extends Node
## BUG-0004: the cloud save was uploaded AFTER the reset by the broken client: old meta with the old econ_reset_seen.
## First open after the fix: cloud meta comes in, then /api/econ shows a newer reset_id: this device wipes and the
## clean save is marked for upload (overwrites the cloud); the old history does not come back. Same in the other order.
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
	svc.account = {"id": "google:stale"}
	SaveStore.profile = "google:stale"
	var uploads := [0]
	SaveStore.on_changed = func() -> void: uploads[0] += 1
	var stale := {"save_version": 2, "econ_reset_seen": "old", "runs": 40, "land_tier": 3, "cosmetics_owned": ["x"]}
	var snap := {"shard": 500, "stone": 0, "ticket": 3, "reset_id": "m5"}
	get_tree().current_scene = self
	# order A: cloud first, then econ
	MetaState.reload_from_store()
	MetaState.econ_reset_seen = ""
	MetaState.save_to_disk()
	svc._apply_server({"rev": 9, "meta": stale, "run": null})
	_check(MetaState.runs == 40 and MetaState.econ_reset_seen == "old", "A: stale cloud meta adopted")
	uploads[0] = 0
	MetaState.apply_server_econ(snap)
	_check(MetaState.runs == 0 and MetaState.land_tier != 3 and MetaState.econ_reset_seen == "m5", "A: econ wipes the stale meta")
	_check(MetaState.shard_pool == 500 and int(MetaState.tickets["normal"]) == 3, "A: balances are the server's")
	_check(uploads[0] > 0, "A: clean save marked for upload")
	var disk: Variant = JSON.parse_string(SaveStore.read_text_as("google:stale", MetaState.SAVE_PATH))
	_check(typeof(disk) == TYPE_DICTIONARY and int(disk["runs"]) == 0 and disk["econ_reset_seen"] == "m5", "A: local file is clean")
	# order B: econ first, then the stale cloud
	MetaState.runs = 0
	svc._apply_server({"rev": 10, "meta": stale, "run": null})
	_check(MetaState.runs == 0 and MetaState.econ_reset_seen == "m5", "B: stale cloud after the wipe does not bring history back")
	svc.queue_free()
	SaveStore.on_changed = Callable()
	SaveStore.profile = ""
	_guard.restore()
	print("t_reset_cloud_stale: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
