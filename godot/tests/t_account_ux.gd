extends Node
## BUG-0006: (a) remote economy hides server-owned numbers in the save dialogs; (b) a same-device reload after an
## interrupted push is not a conflict; real conflicts still ask. Reset notice: once per reset id, before the gift toast.
var _fails := 0
var _guard := SaveGuard.new()
var _asked: Array = []


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _svc() -> Node:
	var svc: Node = load("res://autoload/AccountService.gd").new()
	svc.transport = func(_m: String, _p: String, _b: String, done: Callable) -> void: done.call(200, "{\"rev\": 9}")
	svc.ask = func(kind: String, _i: Dictionary, done: Callable) -> void:
		_asked.append(kind)
		done.call("cloud")
	add_child(svc)
	svc.account = {"id": "google:ux1"}
	SaveStore.profile = "google:ux1"
	return svc


func _labels(n: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for c in n.find_children("*", "Label", true, false):
		out.append((c as Label).text)
	return out


func _ready() -> void:
	_guard.capture()
	var svc := _svc()
	var local := {"save_version": 2, "starter_granted": true, "runs": 4, "xp": 30, "shard_pool": 500, "vault": [], "unlocks": []}
	SaveStore.write_text_as("google:ux1", "user://meta_save.json", JSON.stringify(local))
	# (b) push interrupted: server holds rev 4 with the same content (no shard_pool), device still says rev 3 dirty
	svc._set_sync(3, true)
	var same := {"save_version": 2, "starter_granted": true, "runs": 4, "xp": 30, "vault": [], "unlocks": []}
	svc._reconcile(JSON.parse_string(JSON.stringify({"rev": 4, "meta": same, "run": null})))
	_check(_asked.is_empty(), "same content after interrupted push: no dialog")
	_check(svc._rev == 4, "rev adopted from server")
	# real conflict: the server copy has different progress
	svc._set_sync(3, true)
	var other := same.duplicate()
	other["xp"] = 99
	svc._reconcile(JSON.parse_string(JSON.stringify({"rev": 5, "meta": other, "run": null})))
	_check(_asked == ["conflict"], "different content still asks")

	# (a) dialog rows
	var info := {"local": AccountService.summarize({"meta": local})}
	var local_dlg := AccountUI._save_card("x", "", info["local"])
	_check("Gene Shards" in _labels(local_dlg), "local econ: Shards row kept")
	local_dlg.free()
	MetaState.use_remote_econ(RemoteEcon.new())
	var remote_dlg := AccountUI._save_card("x", "", info["local"])
	_check(not ("Gene Shards" in _labels(remote_dlg)) and "XP" in _labels(remote_dlg), "remote econ: no Shards row, XP kept")
	remote_dlg.free()
	MetaState.use_remote_econ(null)
	svc.queue_free()
	SaveStore.profile = ""

	# reset notice
	MetaState.reload_from_store()
	_check(MetaState.reset_notice_id == "", "no notice by default")
	MetaState.wipe_for_server_reset("m9")
	_check(MetaState.reset_notice_id == "m9", "wipe queues the notice")
	MetaState.reload_from_store()
	_check(MetaState.reset_notice_id == "m9", "notice survives save/load")
	MetaState.tutorial_seen = true
	LandNav.dry_run = true
	LandHub.qa = {"guest": false}
	var h := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	add_child(h)
	for i in 4:
		await get_tree().process_frame
	_check(h.find_child("ResetNotice", true, false) != null, "Land shows the reset notice")
	_check(h.find_child("TierBanner", true, false) == null, "tier banner waits")
	var ok := h.find_child("ResetNoticeOk", true, false) as Button
	if ok != null:
		ok.pressed.emit()
	_check(MetaState.reset_notice_id == "", "OK clears it")
	h.queue_free()
	await get_tree().process_frame
	var h2 := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	add_child(h2)
	for i in 4:
		await get_tree().process_frame
	_check(h2.find_child("ResetNotice", true, false) == null, "not shown twice for the same reset id")
	h2.queue_free()
	LandHub.qa = {}
	LandNav.dry_run = false
	_guard.restore()
	print("t_account_ux: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
