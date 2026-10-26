extends Node
## Accounts on the client: SaveStore namespacing and AccountService's reconcile table
## (claude/ACCOUNT_SYSTEM_v1.md §5-§6), against a fake server and auto-answered dialogs.
##
## Nothing here touches the network or the player's real save: the guest meta/run files are
## backed up byte for byte and put back, and every account profile used is a test id whose
## folder is removed at the end.

var _failures: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()
var _run_backup := ""
## The real save may already hold a kept backup profile (user://acct/backup). The test creates and
## deletes its own; snapshot the player's files first and put them back in _cleanup().
var _acct_backup_files: Dictionary = {}
var _had_run := false

const META := "user://meta_save.json"
const RUN := "user://run_save.json"
const ID := "google:test-1"
const SVC_SCRIPT := "res://autoload/AccountService.gd"

# fake server state
var _calls: Array = []
var _routes: Dictionary = {}
var _asked: Array = []
var _answer := ""
var _toasts: Array = []


func _ready() -> void:
	print("=== t_account_sync: start ===")
	_guard.capture()
	_had_run = FileAccess.file_exists(RUN)
	_run_backup = FileAccess.get_file_as_string(RUN) if _had_run else ""
	for fname in DirAccess.get_files_at("user://acct/backup"):
		_acct_backup_files[fname] = FileAccess.get_file_as_bytes("user://acct/backup/" + fname)
	await get_tree().process_frame

	test_savestore_namespacing()
	await test_first_sign_in_empty_cloud_moves_guest_progress()
	await test_first_sign_in_start_fresh_keeps_guest_untouched()
	await test_first_sign_in_pulls_cloud_when_no_guest_progress()
	await test_first_sign_in_both_have_saves_keep_cloud()
	await test_first_sign_in_both_have_saves_keep_device()
	await test_dirty_same_rev_uploads()
	await test_cloud_moved_on_and_device_clean_pulls()
	await test_both_moved_on_asks_and_keep_device_overwrites()
	await test_push_409_turns_into_a_conflict()
	await test_edits_during_upload_stay_dirty()
	await test_offline_and_expired_statuses()
	await test_sign_out_only_drops_to_guest_once_server_agrees()
	await test_welcome_waits_for_the_session_answer()
	test_messages_and_summary()

	_cleanup()
	print("=== t_account_sync: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_account_sync: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_account_sync: FAIL — %s" % f)
	get_tree().quit(1)


# ============================================================================ helpers

func _check(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(what)


func _reset_storage() -> void:
	SaveStore.profile = ""
	SaveStore.on_changed = Callable()
	for who in ["", ID, "google:test-2", AccountServiceScript.BACKUP_PROFILE]:
		for p in [META, RUN, AccountServiceScript.ACCOUNT_PATH, AccountServiceScript.PREFS_PATH,
				AccountServiceScript.SYNC_PATH]:
			SaveStore.erase_as(who, p)
	_calls.clear()
	_routes.clear()
	_asked.clear()
	_toasts.clear()
	_answer = ""


func _meta(shards: int, runs: int = 0) -> Dictionary:
	# xp mirrors shards: shard_pool is a server-owned field (SR1) and never travels in the cloud save, so xp is the marker the
	# tests follow through upload/download. save_version 2 + starter_granted: a v1 save is (by decision) reset on load, not what this test is about
	return {"shard_pool": shards, "runs": runs, "xp": shards, "vault": [], "unlocks": [], "save_version": 2, "starter_granted": true}


func _put_meta(who: String, m: Dictionary) -> void:
	SaveStore.write_text_as(who, META, JSON.stringify(m))


func _read_meta(who: String) -> Variant:
	var t := SaveStore.read_text_as(who, META)
	return JSON.parse_string(t) if not t.is_empty() else null


func _sign_in_cache(id: String = ID) -> void:
	SaveStore.write_text_as("", AccountServiceScript.ACCOUNT_PATH,
		JSON.stringify({"id": id, "email": "liam@skymavis.com", "name": "Liam", "hd": "skymavis.com",
			"sky_mavis": true}))


func _set_sync(rev: int, dirty: bool) -> void:
	SaveStore.write_text_as(ID, AccountServiceScript.SYNC_PATH, JSON.stringify({"rev": rev, "dirty": dirty}))


func _me(id: String = ID) -> String:
	return JSON.stringify({"id": id, "email": "liam@skymavis.com", "name": "Liam", "hd": "skymavis.com",
		"sky_mavis": true})


func _server(rev: int, meta: Variant, run: Variant = null) -> String:
	return JSON.stringify({"rev": rev, "meta": meta, "run": run, "updated_at": 1790000000})


func _transport(method: String, path: String, body: String, done: Callable) -> void:
	_calls.append([method, path, body])
	var key := "%s %s" % [method, path]
	var r: Variant = _routes.get(key, [0, ""])
	if r is Callable:
		r = (r as Callable).call(body)
	done.call(int(r[0]), String(r[1]))


func _ask(kind: String, info: Dictionary, done: Callable) -> void:
	_asked.append([kind, info])
	done.call(_answer)


func _boot() -> Node:
	var svc: Node = load(SVC_SCRIPT).new()
	add_child(svc)
	svc.ask = _ask
	svc.toast = func(code: String) -> void: _toasts.append(code)
	svc.start(_transport)
	await get_tree().process_frame
	await get_tree().process_frame
	# The test scene is not a menu, so a fetched cloud save waits for the menu — exercise that.
	svc.menu_entered()
	return svc


func _puts() -> Array:
	return _calls.filter(func(c: Array) -> bool: return c[0] == "PUT")


func _done(svc: Node) -> void:
	svc.queue_free()
	SaveStore.profile = ""
	SaveStore.on_changed = Callable()


# ============================================================================ tests

func test_savestore_namespacing() -> void:
	_reset_storage()
	_check(SaveStore.path_for("", META) == META, "guest path unchanged from pre-accounts builds")
	_check(SaveStore.path_for(ID, META) == "user://acct/google_test-1/meta_save.json",
		"account path is per-player")
	var fired := [0]
	SaveStore.on_changed = func() -> void: fired[0] += 1
	SaveStore.profile = ID
	SaveStore.write_text(META, "{\"shard_pool\":5}")
	_check(SaveStore.read_text_as(ID, META) == "{\"shard_pool\":5}", "write goes to the account's save")
	_check(SaveStore.read_text_as("", META).is_empty(), "guest save untouched by an account write")
	_check(fired[0] == 1, "a write for the signed-in profile notifies")
	SaveStore.write_text_as(ID, META, "{}")
	_check(fired[0] == 1, "silent _as writes do not notify")
	SaveStore.erase(META)
	_check(fired[0] == 2 and not SaveStore.exists(META), "erase notifies and removes")
	SaveStore.profile = ""
	SaveStore.write_text(META, "{}")
	_check(fired[0] == 2, "guest writes never notify")
	SaveStore.on_changed = Callable()


func test_first_sign_in_empty_cloud_moves_guest_progress() -> void:
	_reset_storage()
	_put_meta("", _meta(60, 12))
	_routes["GET /api/me"] = [200, _me()]
	_routes["GET /api/save"] = [200, _server(0, null)]
	_routes["PUT /api/save"] = [200, "{\"rev\":1,\"updated_at\":1}"]
	_answer = "move"
	var svc := await _boot()
	_check(_asked.size() == 1 and _asked[0][0] == "move", "asked to move guest progress")
	_check(int(_asked[0][1]["local"]["shards"]) == 60, "move dialog shows the guest's shards")
	var puts := _puts()
	_check(puts.size() == 1, "uploaded once")
	if puts.size() == 1:
		var body: Dictionary = JSON.parse_string(puts[0][2])
		_check(int(body["rev"]) == 0 and int(body["meta"]["xp"]) == 60,
			"upload is the guest save on top of rev 0")
		_check(not (body["meta"] as Dictionary).has("shard_pool") and not (body["meta"] as Dictionary).has("stone"),
			"SR1: server-owned money fields are not in the PUT")
	_check(int((_read_meta(ID) as Dictionary)["xp"]) == 60, "account save is the guest save")
	_check(_read_meta("") == null, "guest save cleared after moving, so it cannot be moved twice")
	_check(svc.status == AccountServiceScript.Status.SAVED, "status Saved")
	_check(MetaState.shard_pool == 60, "MetaState reloaded from the account")
	_done(svc)


func test_first_sign_in_start_fresh_keeps_guest_untouched() -> void:
	_reset_storage()
	_put_meta("", _meta(60, 12))
	_routes["GET /api/me"] = [200, _me()]
	_routes["GET /api/save"] = [200, _server(0, null)]
	_answer = "fresh"
	var svc := await _boot()
	_check(_puts().is_empty(), "start fresh uploads nothing")
	_check(int((_read_meta("") as Dictionary)["shard_pool"]) == 60, "guest save left as it was")
	_check(_read_meta(ID) == null, "account save starts empty")
	_check(SaveStore.exists_as(ID, AccountServiceScript.SYNC_PATH), "sync record written so it is not asked again")
	_done(svc)


func test_first_sign_in_pulls_cloud_when_no_guest_progress() -> void:
	_reset_storage()
	_routes["GET /api/me"] = [200, _me()]
	_routes["GET /api/save"] = [200, _server(4, _meta(25, 20), {"version": 1, "run": {"mode": "short"}})]
	var svc := await _boot()
	_check(_asked.is_empty(), "nothing to ask")
	_check(_puts().is_empty(), "nothing uploaded")
	_check(int((_read_meta(ID) as Dictionary)["xp"]) == 25, "cloud meta downloaded")
	_check(SaveStore.exists_as(ID, RUN), "cloud run downloaded, so CONTINUE works on a new device")
	_check(svc._rev == 4 and not svc._dirty, "in step with rev 4")
	_done(svc)


func test_first_sign_in_both_have_saves_keep_cloud() -> void:
	_reset_storage()
	_put_meta("", _meta(60, 12))
	_routes["GET /api/me"] = [200, _me()]
	_routes["GET /api/save"] = [200, _server(3, _meta(25, 20))]
	_answer = "cloud"
	var svc := await _boot()
	_check(_asked.size() == 1 and _asked[0][0] == "choose", "asked to choose")
	_check(int(_asked[0][1]["cloud"]["runs"]) == 20 and int(_asked[0][1]["local"]["runs"]) == 12,
		"both sides summarised")
	_check(int((_read_meta(ID) as Dictionary)["xp"]) == 25, "cloud kept")
	_check(int((_read_meta(AccountServiceScript.BACKUP_PROFILE) as Dictionary)["xp"]) == 60,
		"guest save kept as the backup")
	_check(_read_meta("") == null, "guest cleared")
	_check(_puts().is_empty(), "keeping cloud uploads nothing")
	_done(svc)


func test_first_sign_in_both_have_saves_keep_device() -> void:
	_reset_storage()
	_put_meta("", _meta(60, 12))
	_routes["GET /api/me"] = [200, _me()]
	_routes["GET /api/save"] = [200, _server(3, _meta(25, 20))]
	_routes["PUT /api/save"] = [200, "{\"rev\":4,\"updated_at\":1}"]
	_answer = "local"
	var svc := await _boot()
	var puts := _puts()
	_check(puts.size() == 1 and int(JSON.parse_string(puts[0][2])["rev"]) == 3,
		"device save uploaded on top of the cloud's rev 3")
	_check(int((_read_meta(AccountServiceScript.BACKUP_PROFILE) as Dictionary)["xp"]) == 25,
		"cloud save kept as the backup")
	_check(svc._rev == 4, "now at rev 4")
	_done(svc)


func test_dirty_same_rev_uploads() -> void:
	_reset_storage()
	_sign_in_cache()
	_put_meta(ID, _meta(30))
	_set_sync(2, true)
	_routes["GET /api/me"] = [200, _me()]
	_routes["GET /api/save"] = [200, _server(2, _meta(20))]
	_routes["PUT /api/save"] = [200, "{\"rev\":3,\"updated_at\":1}"]
	var svc := await _boot()
	_check(SaveStore.profile == ID, "cached account selects its save before MetaState loads")
	_check(_puts().size() == 1 and int(JSON.parse_string(_puts()[0][2])["meta"]["xp"]) == 30,
		"unsynced local change uploaded")
	_check(svc._rev == 3 and not svc._dirty, "clean at rev 3")
	_done(svc)


func test_cloud_moved_on_and_device_clean_pulls() -> void:
	_reset_storage()
	_sign_in_cache()
	_put_meta(ID, _meta(30))
	_set_sync(2, false)
	_routes["GET /api/me"] = [200, _me()]
	_routes["GET /api/save"] = [200, _server(5, _meta(90))]
	var svc := await _boot()
	_check(_asked.is_empty() and _puts().is_empty(), "no question, no upload")
	_check(int((_read_meta(ID) as Dictionary)["xp"]) == 90, "newer cloud save downloaded")
	_check(svc._rev == 5, "rev 5")
	_done(svc)


func test_both_moved_on_asks_and_keep_device_overwrites() -> void:
	_reset_storage()
	_sign_in_cache()
	_put_meta(ID, _meta(30))
	_set_sync(2, true)
	_routes["GET /api/me"] = [200, _me()]
	_routes["GET /api/save"] = [200, _server(5, _meta(90))]
	_routes["PUT /api/save"] = [200, "{\"rev\":6,\"updated_at\":1}"]
	_answer = "local"
	var svc := await _boot()
	_check(_asked.size() == 1 and _asked[0][0] == "conflict", "conflict dialog")
	_check(_puts().size() == 1 and int(JSON.parse_string(_puts()[0][2])["rev"]) == 5,
		"device save sent on top of rev 5")
	_check(int((_read_meta(AccountServiceScript.BACKUP_PROFILE) as Dictionary)["xp"]) == 90,
		"the cloud copy is kept as backup")
	_done(svc)


func test_push_409_turns_into_a_conflict() -> void:
	_reset_storage()
	_sign_in_cache()
	_put_meta(ID, _meta(30))
	_set_sync(2, true)
	_routes["GET /api/me"] = [200, _me()]
	_routes["GET /api/save"] = [200, _server(2, _meta(20))]
	_routes["PUT /api/save"] = [409, JSON.stringify({"error": "conflict",
		"server": {"rev": 3, "meta": _meta(77), "run": null, "updated_at": 1}})]
	_answer = "cloud"
	var svc := await _boot()
	_check(_asked.size() == 1 and _asked[0][0] == "conflict", "409 shows the conflict dialog")
	_check(int((_read_meta(ID) as Dictionary)["xp"]) == 77, "keep cloud applied the server copy")
	_check(svc._rev == 3 and not svc._dirty, "clean at the server's rev")
	_done(svc)


func test_edits_during_upload_stay_dirty() -> void:
	_reset_storage()
	_sign_in_cache()
	_put_meta(ID, _meta(30))
	_set_sync(2, true)
	_routes["GET /api/me"] = [200, _me()]
	_routes["GET /api/save"] = [200, _server(2, _meta(20))]
	var svc_ref: Array = []
	_routes["PUT /api/save"] = func(_body: String) -> Array:
		# The player saves again while the upload is in flight.
		if not svc_ref.is_empty() and _puts().size() == 1:
			SaveStore.write_text(META, JSON.stringify(_meta(31)))
		return [200, "{\"rev\":%d,\"updated_at\":1}" % (2 + _puts().size())]
	var svc: Node = load(SVC_SCRIPT).new()
	svc_ref.append(svc)
	add_child(svc)
	svc.ask = _ask
	svc.toast = func(_c: String) -> void: pass
	svc.start(_transport)
	await get_tree().process_frame
	await get_tree().process_frame
	svc.menu_entered()
	_check(svc._dirty, "a save made during the upload is still pending afterwards")
	_check(svc.status == AccountServiceScript.Status.SAVING, "and the chip still says Saving…")
	svc.sync_now()
	_check(not svc._dirty and _puts().size() == 2, "the follow-up upload sends it")
	_done(svc)


func test_offline_and_expired_statuses() -> void:
	_reset_storage()
	_sign_in_cache()
	_set_sync(1, false)
	_routes["GET /api/me"] = [0, "TypeError: Failed to fetch"]
	var svc := await _boot()
	_check(svc.status == AccountServiceScript.Status.OFFLINE, "unreachable server -> Offline, still signed in")
	_check(svc.is_signed_in(), "offline keeps the account")
	_done(svc)

	_reset_storage()
	_sign_in_cache()
	_routes["GET /api/me"] = [401, "{\"error\":\"signed_out\"}"]
	svc = await _boot()
	_check(svc.status == AccountServiceScript.Status.EXPIRED, "401 with a known account -> Expired")
	_check(SaveStore.profile == ID, "expired keeps playing on the account's local save")
	svc.show_pending_error()
	_check(_toasts == ["session_expired"], "expired explains itself once")
	SaveStore.write_text(META, JSON.stringify(_meta(5)))
	_check(_puts().is_empty() and svc._dirty, "no upload while expired, change kept as pending")
	_done(svc)

	_reset_storage()
	_routes["GET /api/me"] = [401, "{\"error\":\"signed_out\"}"]
	svc = await _boot()
	_check(svc.status == AccountServiceScript.Status.GUEST and svc.should_offer_welcome(),
		"a new visitor is a guest and is offered the account panel")
	svc.play_as_guest()
	_check(not svc.should_offer_welcome(), "Play as guest is remembered")
	_done(svc)


func test_sign_out_only_drops_to_guest_once_server_agrees() -> void:
	_reset_storage()
	_sign_in_cache()
	_put_meta(ID, _meta(10))
	_set_sync(1, false)
	_routes["GET /api/me"] = [200, _me()]
	_routes["GET /api/save"] = [200, _server(1, _meta(10))]
	_routes["POST /auth/logout"] = [0, ""]
	var svc := await _boot()
	svc.sign_out()
	_check(svc.is_signed_in() and _toasts == ["sign_out_failed"],
		"offline sign-out does not pretend: still signed in, and says so")
	_routes["POST /auth/logout"] = [204, ""]
	svc.sign_out()
	_check(not svc.is_signed_in() and SaveStore.profile == "", "sign-out returns this browser to guest")
	_check(not SaveStore.exists_as("", AccountServiceScript.ACCOUNT_PATH), "cached account forgotten")
	_check(SaveStore.exists_as(ID, META), "the account's local copy stays on the device")
	_done(svc)


## Regression, live 10 Oct 2026: back from Google with nothing cached yet, the menu offered the
## welcome panel before /api/me answered, and the panel stayed up over a signed-in menu.
func test_welcome_waits_for_the_session_answer() -> void:
	_reset_storage()
	var pending: Array = []
	var svc: Node = load(SVC_SCRIPT).new()
	add_child(svc)
	svc.ask = _ask
	svc.toast = func(_c: String) -> void: pass
	svc.start(func(m: String, p: String, b: String, done: Callable) -> void:
		pending.append([m, p, done]))
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not svc.should_offer_welcome(), "no welcome while /api/me has not answered")
	var stray := Control.new()
	stray.name = "AccountWelcome"
	svc._ui_layer().add_child(stray)
	(pending[0][2] as Callable).call(200, _me())
	_check(stray.is_queued_for_deletion(), "a signed-in answer closes any welcome panel already up")
	_check(not svc.should_offer_welcome(), "signed in: never offered")
	_done(svc)

	_reset_storage()
	pending.clear()
	svc = load(SVC_SCRIPT).new()
	add_child(svc)
	svc.toast = func(_c: String) -> void: pass
	svc.start(func(m: String, p: String, b: String, done: Callable) -> void:
		pending.append([m, p, done]))
	await get_tree().process_frame
	await get_tree().process_frame
	(pending[0][2] as Callable).call(401, "{}")
	_check(svc.should_offer_welcome(), "a confirmed guest is offered the panel")
	_done(svc)


func test_messages_and_summary() -> void:
	for code in ["access_denied", "expired", "state", "network", "admin_policy_enforced",
			"session_expired", "save_failed", "sign_out_failed", "token", "anything"]:
		var m := AccountServiceScript.error_message(code)
		_check(not m.is_empty() and not m.contains("_"), "message for %s is plain English" % code)
	# The Worker's rate limit (worker/src/accounts.js) sends ?auth_error=rate_limited; it must get
	# its own line, not the generic fallback.
	_check(AccountServiceScript.error_message("rate_limited")
		!= AccountServiceScript.error_message("anything"), "rate_limited has its own message")
	var s := AccountServiceScript.summarize({"meta": _meta(7, 3),
		"run": {"run": {"mode": "full", "ascension": 2}}})
	_check(s["shards"] == 7 and s["runs"] == 3 and s["run"] == "Full · Ascension 2", "summary fields")


func _cleanup() -> void:
	_reset_storage()
	for d in ["user://acct/google_test-1", "user://acct/google_test-2", "user://acct/backup"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(d))
	if not _acct_backup_files.is_empty():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://acct/backup"))
		for fname in _acct_backup_files:
			var bf := FileAccess.open("user://acct/backup/" + String(fname), FileAccess.WRITE)
			bf.store_buffer(_acct_backup_files[fname])
			bf.close()
	_guard.restore()
	if _had_run:
		var f := FileAccess.open(RUN, FileAccess.WRITE)
		f.store_string(_run_backup)
		f.close()
	elif FileAccess.file_exists(RUN):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUN))
	MetaState.reload_from_store()
