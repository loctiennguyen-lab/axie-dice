extends Node
## M1 reset, client side: a server snapshot with a new reset_id wipes this device through SaveStore (so the cloud
## copy is overwritten by the next upload) and everything reads 0. Not in the middle of a run: it waits.
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
	SaveStore.profile = "google:m1other"
	var uploads := [0]
	SaveStore.on_changed = func() -> void: uploads[0] += 1
	# "another machine": an old local save with money and run history
	MetaState.reload_from_store()
	MetaState.shard_pool = 777
	MetaState.stone = 55
	MetaState.runs = 9
	MetaState.run_log = [{"date": "x", "won": true}]
	MetaState.save_to_disk()
	var snap := {"shard": 0, "stone": 0, "ticket": 0, "unlocks": [], "owned": [], "pity": {}, "opens": 0, "buy_day": "", "buy_count": 0, "reset_id": "m1"}
	var e := RemoteEcon.new(func(_m: String, _p: String, _b: String, done: Callable) -> void: done.call(200, JSON.stringify(snap)))
	MetaState.use_remote_econ(e)
	# 1) a run is open: nothing is wiped yet
	RunState.phase = RunState.RunPhase.COMBAT
	e.refresh()
	_check(MetaState.runs == 9 and MetaState.econ_reset_seen == "", "run open: wipe postponed")
	# 2) back at the menu: RunState.reset() lands it
	RunState.phase = RunState.RunPhase.MENU
	RunState.reset()
	_check(MetaState.runs == 0 and MetaState.shard_pool == 0 and MetaState.stone == 0 and MetaState.run_log.is_empty(), "after the run: everything reads 0")
	_check(MetaState.econ_reset_seen == "m1", "reset id remembered")
	var disk: Variant = JSON.parse_string(SaveStore.read_text_as("google:m1other", MetaState.SAVE_PATH))
	_check(typeof(disk) == TYPE_DICTIONARY and int(disk["runs"]) == 0 and int(disk["shard_pool"]) == 0 and disk["econ_reset_seen"] == "m1", "the profile's save on disk was overwritten")
	_check(MetaState.starter_granted and MetaState.starter_shard_locked == 0 and MetaState.shard_pool == 0 and int(MetaState.tickets["normal"]) == 0,
		"wipe leaves no local starter behind (locked Shard, tickets, flag)")
	_check(uploads[0] > 0, "SaveStore notified, so the cloud upload is scheduled")
	# 3) same id again: no second wipe
	MetaState.runs = 2
	e.refresh()
	_check(MetaState.runs == 2, "same reset id does not wipe again")
	MetaState.use_remote_econ(null)
	SaveStore.on_changed = Callable()
	SaveStore.profile = ""
	_guard.restore()
	print("t_reset_m1_cloud: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
