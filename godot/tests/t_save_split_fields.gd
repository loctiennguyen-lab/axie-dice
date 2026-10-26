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
	MetaState.starter_granted = true
	MetaState.shard_pool = 500
	MetaState.stone = 40
	MetaState.unlocks.append("u_full")
	MetaState.runs = 4
	MetaState.pass_season = {"id": "s1", "xp": 300, "level": 3, "claimed_free": [1]}
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
	svc._apply_server({"rev": 5, "meta": {"save_version": 2, "shard_pool": 99999, "stone": 99999, "unlocks": ["u_all"], "runs": 7, "pass_season": {"id": "s1", "xp": 99999, "level": 99, "claimed_free": []}}, "run": null})
	_check(MetaState.runs == 7, "non-money fields come from the cloud save")
	_check(MetaState.shard_pool == 500 and MetaState.stone == 40 and MetaState.has_unlock("u_full") and not MetaState.has_unlock("u_all"),
		"money fields kept from the device cache, cloud values ignored")
	_check(int(MetaState.pass_season.get("level", 0)) == 3, "pass_season kept from the device cache, cloud value ignored")
	# remote wallet on: local add_shards for server-paid reasons is refused, others still land
	var e := RemoteEcon.new(func(_m: String, _p: String, _b: String, done: Callable) -> void: done.call(200, "{}"))
	MetaState.use_remote_econ(e)
	for r in MetaState.SERVER_PAID_REASONS:
		MetaState.add_shards(10, r, false)
	_check(MetaState.shard_pool == 500, "add_shards refuses every server-paid reason while the wallet is remote")
	MetaState.add_shards(10, "refund", false)
	_check(MetaState.shard_pool == 510, "other reasons still add")
	MetaState.use_remote_econ(null)
	svc.queue_free()
	SaveStore.profile = ""
	_guard.restore()
	print("t_save_split_fields: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
