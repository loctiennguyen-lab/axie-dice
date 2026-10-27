extends Node
## BUG-0004: after a server reset the player at Land (stale run save on disk, RunState.phase left non-MENU) gets the
## server's balances, the old run save is erased, econ_reset_seen is the new id. A failed Continue erases the save and
## puts the plate back to "Start run".
var _fails := 0
var _guard := SaveGuard.new()


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _snap(rid: String) -> Dictionary:
	return {"shard": 500, "stone": 0, "ticket": 3, "unlocks": [], "owned": [], "pity": {}, "opens": 0, "buy_day": "", "buy_count": 0, "reset_id": rid}


func _enter_land() -> LandHub:
	var hub: LandHub = (load("res://scenes/land/Land.tscn") as PackedScene).instantiate()
	hub.set("qa", {"offline": false})
	get_tree().root.add_child(hub)
	get_tree().current_scene = hub
	await get_tree().process_frame
	return hub


func _ready() -> void:
	_guard.capture()
	MetaState.reload_from_store()
	MetaState.tutorial_seen = true
	MetaState.shard_pool = 560
	MetaState.stone = 500
	MetaState.runs = 7
	MetaState.econ_reset_seen = "old"
	MetaState.save_to_disk()
	# a run saved before the reset, loaded in memory (phase MAP) while the player stands on Land
	RunState.phase = RunState.RunPhase.MAP
	RunState.save_run()
	_check(RunState.saved_run_file_exists(), "setup: old run save on disk")
	var hub := await _enter_land()
	_check(RunState.phase != RunState.RunPhase.MENU or RunState.saved_run_file_exists(), "setup: stale run state at Land")
	RunState.phase = RunState.RunPhase.MAP
	MetaState.apply_server_econ(_snap("m5"))
	_check(MetaState.shard_pool == 500 and MetaState.stone == 0 and int(MetaState.tickets["normal"]) == 3, "balances are the server's (500/0/3)")
	_check(not RunState.saved_run_file_exists(), "old run save erased")
	_check(MetaState.econ_reset_seen == "m5" and not MetaState.has_pending_reset(), "reset id remembered, nothing pending")
	_check(MetaState.runs == 0, "local history wiped")
	_check(RunState.phase == RunState.RunPhase.MENU, "run state cleared")
	_check(RunState.discard_notice.find("beta reset") >= 0, "notice names the reset")
	RunState.take_discard_notice()
	# Continue that cannot load: save erased, plate back to Start run
	var f := FileAccess.open("user://run_save.json", FileAccess.WRITE)
	if f != null:
		f.store_string("{}")
		f.close()
	SaveStore.write_text(RunState.SAVE_PATH, "{ not a run")
	hub.set("_has_run", true)
	hub._on_continue_pressed()
	_check(not RunState.saved_run_file_exists(), "failed Continue erased the run save")
	_check(not bool(hub.get("_has_run")), "Land no longer has an open run")
	_check((hub.get("_run_plate") as Button).text == "Start run", "plate says Start run")
	hub.queue_free()
	_guard.restore()
	print("t_reset_on_land: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
