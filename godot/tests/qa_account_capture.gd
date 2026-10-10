extends Node
## One-off capture of the account UI (claude/ACCOUNT_SYSTEM_v1.md §7): menu chip signed in,
## welcome panel, save-choice dialog, an error toast, and Settings → Account.
## Desktop builds keep AccountService off, so this switches it on by hand with a fake account and
## never makes a network call. Run: godot/tools/shot.sh res://tests/qa_account_capture.tscn

var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	MetaState.tutorial_seen = true
	var svc := AccountService
	svc.enabled = true
	svc.account = {"id": "google:qa", "name": "Lộc Tiến Nguyễn", "email": "loc.tien.nguyen@skymavis.com",
		"hd": "skymavis.com", "sky_mavis": true}
	svc.status = AccountServiceScript.Status.SAVED
	svc.last_synced = int(Time.get_unix_time_from_system()) - 120

	var menu := await _open("res://scenes/main_menu/MainMenu.tscn")
	await _shot("account_1_menu_signed_in")

	svc.account = {}
	svc.status = AccountServiceScript.Status.GUEST
	svc.changed.emit()
	await _frames(5)
	await _shot("account_2_menu_guest")
	var welcome := AccountUI.show_welcome(svc._ui_layer())
	await _frames(10)
	await _shot("account_3_welcome")
	welcome.queue_free()

	var info := {"local": {"shards": 60, "xp": 340, "vault": 3, "runs": 12, "wins": 4,
			"run": "Short · Ascension 0"},
		"cloud": {"shards": 25, "xp": 820, "vault": 6, "runs": 20, "wins": 7, "run": "",
			"updated_at": int(Time.get_unix_time_from_system()) - 3 * 86400}}
	var dlg := AccountUI.show_choice(svc._ui_layer(), "choose", info, func(_c: String) -> void: pass)
	await _frames(10)
	await _shot("account_4_choose")
	dlg.queue_free()
	var mv := AccountUI.show_choice(svc._ui_layer(), "move", info, func(_c: String) -> void: pass)
	await _frames(10)
	await _shot("account_5_move")
	mv.queue_free()

	AccountUI.show_toast(svc._ui_layer(), "admin_policy_enforced")
	await _frames(10)
	await _shot("account_6_toast")
	for c in svc._ui_layer().get_children():
		c.queue_free()

	menu.queue_free()
	svc.account = {"id": "google:qa", "name": "Lộc Tiến Nguyễn", "email": "loc.tien.nguyen@skymavis.com",
		"hd": "skymavis.com", "sky_mavis": true}
	svc.status = AccountServiceScript.Status.SAVED
	await _open("res://scenes/settings/Settings.tscn")
	await _shot("account_7_settings")

	svc.enabled = false
	svc.account = {}
	_guard.restore()
	get_tree().quit(0)


func _open(path: String) -> Node:
	var n: Node = (load(path) as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(n)
	await _frames(30)
	return n


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	var path := QaPaths.evidence_dir() + "/%s.png" % name
	get_tree().root.get_texture().get_image().save_png(path)
	print("QA: saved ", path)
