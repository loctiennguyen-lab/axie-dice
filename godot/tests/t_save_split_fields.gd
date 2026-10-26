extends Node
## Server-owned money fields never travel in the cloud save: the PUT body lacks them, and a downloaded save cannot
## overwrite what the device shows (nor mint it).
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
	var sent: Array = []
	var svc: Node = load("res://autoload/AccountService.gd").new()
	svc.transport = func(m: String, path: String, body: String, done: Callable) -> void:
		sent.append({"m": m, "path": path, "body": body})
		done.call(200, JSON.stringify({"rev": 2}))
	add_child(svc)
	svc.enabled = true
	svc.account = {"id": "google:split1"}
	SaveStore.profile = "google:split1"
	MetaState.reload_from_store()
	MetaState.shard_pool = 500
	MetaState.stone = 40
	MetaState.unlocks.append("u_hp")
	MetaState.runs = 4
	MetaState.save_to_disk()
	svc._dirty = true
	svc._push()
	var put: Dictionary = {}
	for s in sent:
		if s["m"] == "PUT":
			put = JSON.parse_string(s["body"])
	var meta: Dictionary = put.get("meta", {})
	_check(not put.is_empty() and meta.get("runs", -1) == 4, "PUT carries the non-money fields")
	for k in MetaState.SERVER_FIELDS:
		_check(not meta.has(k), "PUT body has no " + k)
	# a cloud save with inflated money must not land
	svc._apply_server({"rev": 5, "meta": {"shard_pool": 99999, "stone": 99999, "unlocks": ["u_all"], "runs": 7}, "run": null})
	_check(MetaState.runs == 7, "non-money fields come from the cloud save")
	_check(MetaState.shard_pool == 500 and MetaState.stone == 40 and MetaState.has_unlock("u_hp") and not MetaState.has_unlock("u_all"),
		"money fields kept from the device cache, cloud values ignored")
	svc.queue_free()
	SaveStore.profile = ""
	_guard.restore()
	print("t_save_split_fields: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
