class_name AccountServiceScript
extends Node
## Autoloaded as `AccountService`. The class name only exists so other scripts can read the
## Status enum and the static helpers without a live instance.
##
## Accounts on the client: who is signed in, and keeping their save in step with the server.
## Design: claude/ACCOUNT_SYSTEM_v1.md §4-§7. Server: worker/src/accounts.js.
##
## WHAT IT OWNS
##   * Which save the game reads. Listed BEFORE MetaState in project.godot, so by the time
##     MetaState loads, `SaveStore.profile` already points at the signed-in player's save (from
##     the last known account cached on this browser) — the game starts instantly and offline.
##   * Checking that guess with `/api/me`, then reconciling local and cloud with `/api/save`.
##   * Uploading after every save, debounced, so a burst of writes (end of combat, a volume
##     slider) is one request.
##   * The account panel, the save-choice dialog and the error toasts (AccountUI).
##
## WHAT IT NEVER DOES
##   * Merge two saves. When local and cloud have both moved on, the player picks one; the other
##     is kept on this device for BACKUP_DAYS days.
##   * Block play. Offline, expired or broken sign-in all leave the player in the game with their
##     progress saved locally, and the next successful contact catches up.
##
## Web: the session is an HttpOnly cookie carried by the browser (`__adAcct` bridge).
## Desktop: there is no cookie, so sign-in goes through the Worker (loopback + PKCE, ADR-RNG 4.8):
## DesktopAuth opens the browser, DesktopTransport sends `Authorization: Bearer` and refreshes.
## Tokens live in DeviceTokens (encrypted file; OS keychain is a known debt). A desktop player with
## no tokens stays a guest and this node stays idle until `sign_in()` succeeds.

signal changed

enum Status { GUEST, CHECKING, SAVED, SAVING, OFFLINE, EXPIRED }

const META_PATH := "user://meta_save.json"   # MetaState.SAVE_PATH
const RUN_PATH := "user://run_save.json"     # RunState.SAVE_PATH
## Guest-level: the account last signed in on this browser (id, name, email, hd). Not a secret —
## the session itself is an HttpOnly cookie the game never sees.
const ACCOUNT_PATH := "user://account.json"
## Guest-level: "guest_ok" once the player chose Play as guest; "backup_at" for the kept save.
const PREFS_PATH := "user://account_prefs.json"
## Per-account: {rev, dirty} — the server revision this device last agreed with, and whether
## the local save has changed since.
const SYNC_PATH := "user://account_sync.json"
## The save a player chose NOT to keep in a choice dialog, held for BACKUP_DAYS.
const BACKUP_PROFILE := "backup"
const BACKUP_DAYS := 7
const PUSH_DELAY := 3.0
const RETRY_DELAYS: Array[float] = [5.0, 15.0, 60.0, 120.0]
const MAIN_MENU := "res://scenes/main_menu/MainMenu.tscn"
const TUTORIAL := "res://scenes/tutorial/Tutorial.tscn"

var enabled := false
var status: int = Status.GUEST
## {id, email, name, hd, sky_mavis} — empty for a guest.
var account: Dictionary = {}
## Unix time of the last successful upload or download, 0 if none this session.
var last_synced := 0

## Network seam. transport.call(method, path, body_text, done) where done(code:int, text:String).
## code 0 = never reached the server. Tests inject a fake; the web build uses fetch().
var transport: Callable
## Dialog seam. ask.call(kind, info, done) where done(choice:String). kind is "move", "choose"
## or "conflict". Tests answer instantly; the game shows AccountUI.
var ask: Callable
## Toast seam: toast.call(code_or_text). Tests record; the game shows AccountUI.
var toast: Callable

var _rev := 0
var _dirty := false
var _edits := 0
var _push_in_flight := false
var _after_push: Callable = Callable()
var _retry_index := 0
var _pending_error := ""
var _welcome_shown := false
## True once /api/me has answered this session. Until then a player who just came back from
## Google looks exactly like a guest (nothing is cached yet), so the welcome panel must wait.
var _session_known := false
var _profile_changed := false
## A cloud save that arrived while the player was in a run. Applying it then would reset the run
## under them; it waits for the next visit to the menu instead.
var _deferred_server: Dictionary = {}
var _push_timer: Timer
var _retry_timer: Timer
var _layer: CanvasLayer
var _js_callbacks: Dictionary = {}
var _js_seq := 0
var _js_keep: Array = []


func _ready() -> void:
	_push_timer = Timer.new()
	_push_timer.one_shot = true
	_push_timer.timeout.connect(_push)
	add_child(_push_timer)
	_retry_timer = Timer.new()
	_retry_timer.one_shot = true
	add_child(_retry_timer)
	if SaveStore.is_web():
		_install_js()
		start(_web_transport)
	elif _desktop_enabled():
		_desktop_boot()


## Turns the service on. The web build calls this from _ready(); tests call it with a fake.
func start(net: Callable) -> void:
	transport = net
	enabled = true
	if not ask.is_valid():
		ask = _ask_with_ui
	if not toast.is_valid():
		toast = _toast_with_ui
	_expire_backup()
	var cached := _read_json("", ACCOUNT_PATH)
	if cached.has("id"):
		account = cached
		SaveStore.profile = String(cached["id"])
		_load_sync()
		status = Status.CHECKING
	SaveStore.on_changed = _on_store_changed
	if SaveStore.is_web():
		_read_url_flags()
	check.call_deferred()


# ============================================================================ public API

func is_signed_in() -> bool:
	return not account.is_empty()


func display_name() -> String:
	var n := String(account.get("name", ""))
	return n if not n.is_empty() else String(account.get("email", "Player"))


## Panel A: offered once, to a web player who has neither signed in nor chosen to play as guest,
## and not while a sign-in error toast is already explaining something.
func should_offer_welcome() -> bool:
	return enabled and _session_known and account.is_empty() \
		and not bool(_prefs().get("guest_ok", false)) and _pending_error.is_empty() \
		and not _welcome_shown


func mark_welcome_shown() -> void:
	_welcome_shown = true


func play_as_guest() -> void:
	var p := _prefs()
	p["guest_ok"] = true
	_write_json("", PREFS_PATH, p)
	changed.emit()


## Leaves the page for Google. Everything is already saved locally — every save is written
## synchronously — so nothing is lost by navigating away mid-flow.
func sign_in(switch_account: bool = false) -> void:
	if not SaveStore.is_web():
		begin_desktop_sign_in()
		return
	JavaScriptBridge.get_interface("__adAcct").go(switch_account)


## Uploads anything pending first, then ends the session and returns this browser to guest.
## The signed-in player's local copy stays on the device under their own key.
func sign_out() -> void:
	if _dt != null:
		_flush_then(_desktop_sign_out)
		return
	_flush_then(func() -> void:
		transport.call("POST", "/auth/logout", "", func(code: int, _text: String) -> void:
			# Only drop to guest once the server has ended the session. Offline, the cookie would
			# still be valid and the next boot would quietly sign the player straight back in.
			if code == 204 or code == 200:
				_become_guest()
			else:
				toast.call("sign_out_failed")))


func has_unsynced_changes() -> bool:
	return _dirty


## MainMenu calls this from _ready(): the one place every path back from a run passes through.
func menu_entered() -> void:
	if not _deferred_server.is_empty():
		var server := _deferred_server
		_deferred_server = {}
		_reconcile(server)


## Shows the pending sign-in error, if any. MainMenu calls this once it is on screen.
func show_pending_error() -> void:
	if _pending_error.is_empty():
		return
	var code := _pending_error
	_pending_error = ""
	toast.call(code)


## Re-checks the session and syncs. Called on boot and by the "Retry" / "Sync now" buttons.
func check() -> void:
	if not enabled:
		return
	if not account.is_empty() and status != Status.SAVING:
		status = Status.CHECKING
	changed.emit()
	transport.call("GET", "/api/me", "", _on_me)


func sync_now() -> void:
	if _dirty and status != Status.EXPIRED:
		_push_timer.stop()
		_push()
	else:
		check()


## The player-facing line for a sign-in error code from the Worker (`?auth_error=`).
static func error_message(code: String) -> String:
	match code:
		"access_denied":
			return "Sign-in was cancelled."
		"expired", "state":
			return "Sign-in timed out. Try again."
		"network":
			return "Can't reach Google sign-in right now."
		"admin_policy_enforced", "org_internal":
			return "Your company account blocked this sign-in. Try a personal Google account, or ask IT to allow Axie Dice."
		"session_expired":
			return "Your session expired. Sign in again to keep saving. Your progress is safe on this device."
		"save_failed":
			return "Couldn't save to the cloud. We'll keep trying."
		"sign_out_failed":
			return "Couldn't sign out. Check your connection and try again."
		"rate_limited":
			return "Too many sign-in attempts. Wait a minute and try again."
	return "Sign-in didn't work. Try again."


# ============================================================================ session check

func _on_me(code: int, text: String) -> void:
	_session_known = true
	if code == 200:
		_close_welcome()
		var me: Variant = JSON.parse_string(text)
		if typeof(me) != TYPE_DICTIONARY or not (me as Dictionary).has("id"):
			_go_offline()
			return
		if String(account.get("id", "")) != String(me["id"]):
			_switch_to(me)
		else:
			account = me
			_write_json("", ACCOUNT_PATH, account)
		_attach_remote_wallet()
		transport.call("GET", "/api/save", "", _on_save_fetched)
	elif code == 401:
		if account.is_empty():
			status = Status.GUEST
			_offer_welcome_on_menu()
		else:
			# Signed out on the server (expired, or signed out on another tab). Keep playing on
			# this account's local save; it uploads after the next sign-in.
			status = Status.EXPIRED
			if _pending_error.is_empty():
				_pending_error = "session_expired"
		changed.emit()
	else:
		_go_offline()


func _switch_to(me: Dictionary) -> void:
	account = me
	_write_json("", ACCOUNT_PATH, account)
	SaveStore.profile = String(me["id"])
	_load_sync()
	_reload_game_state()


func _on_save_fetched(code: int, text: String) -> void:
	if code == 200:
		var server: Variant = JSON.parse_string(text)
		if typeof(server) == TYPE_DICTIONARY:
			if _safe_scene():
				_reconcile(server)
			else:
				_deferred_server = server
			return
	if code == 401:
		_on_me(401, "")
		return
	_go_offline()


# ============================================================================ reconcile

## The whole decision table (ACCOUNT_SYSTEM_v1.md §5-§6). `server` is {rev, meta, run, updated_at}.
func _reconcile(server: Dictionary) -> void:
	var id := String(account["id"])
	var srev := int(server.get("rev", 0))

	if not SaveStore.exists_as(id, SYNC_PATH):
		# First time this account is seen on this browser.
		var guest := _snapshot("")
		var guest_has := _has_progress(guest)
		if srev == 0:
			if guest_has:
				ask.call("move", {"local": summarize(guest)}, func(choice: String) -> void:
					if choice == "move":
						_adopt(guest, 0)
					else:
						_set_sync(0, _has_progress(_snapshot(id)))
						_after_reconcile())
				return
			_set_sync(0, _has_progress(_snapshot(id)))
		elif guest_has:
			ask.call("choose", {"local": summarize(guest), "cloud": summarize(server)},
				func(choice: String) -> void:
					if choice == "local":
						_backup(server)
						_adopt(guest, srev)
					else:
						_backup(guest)
						_clear_guest()
						_apply_server(server)
						_after_reconcile())
			return
		else:
			_apply_server(server)
		_after_reconcile()
		return

	if srev == _rev:
		pass
	elif srev > _rev:
		if _dirty:
			_conflict(server)
			return
		_apply_server(server)
	else:
		# The server is behind this device (a restored or reset database). This device holds
		# the newer copy; send it on top of whatever the server has now.
		_rev = srev
		_dirty = true
		_save_sync()
	_after_reconcile()


func _conflict(server: Dictionary) -> void:
	var id := String(account["id"])
	ask.call("conflict", {"local": summarize(_snapshot(id)), "cloud": summarize(server)},
		func(choice: String) -> void:
			if choice == "local":
				_backup(server)
				_rev = int(server.get("rev", 0))
				_dirty = true
				_save_sync()
			else:
				_backup(_snapshot(id))
				_apply_server(server)
			_after_reconcile())


func _after_reconcile() -> void:
	if _dirty:
		_push()
	else:
		status = Status.SAVED
		last_synced = int(Time.get_unix_time_from_system())
		changed.emit()
	if _profile_changed:
		_profile_changed = false
		_refresh_scene()


## Makes `snap` this account's save and marks it for upload on top of `base_rev`.
func _adopt(snap: Dictionary, base_rev: int) -> void:
	var id := String(account["id"])
	_write_snapshot(id, snap)
	_clear_guest()
	_rev = base_rev
	_dirty = true
	_save_sync()
	_reload_game_state()
	_after_reconcile()


func _apply_server(server: Dictionary) -> void:
	var id := String(account["id"])
	_write_snapshot(id, {"meta": server.get("meta"), "run": server.get("run")})
	_rev = int(server.get("rev", 0))
	_dirty = false
	_save_sync()
	last_synced = int(Time.get_unix_time_from_system())
	_reload_game_state()


# ============================================================================ upload

func _on_store_changed() -> void:
	if account.is_empty():
		return
	_edits += 1
	if not _dirty:
		_dirty = true
		_save_sync()
	if status == Status.SAVED or status == Status.OFFLINE:
		status = Status.SAVING
		changed.emit()
	if status == Status.SAVING and not _push_in_flight:
		_push_timer.start(PUSH_DELAY)


func _push() -> void:
	if _push_in_flight or not enabled or account.is_empty() or status == Status.EXPIRED:
		_run_after_push()
		return
	if not _dirty:
		_run_after_push()
		return
	var snap := _snapshot(String(account["id"]))
	var body := {"rev": _rev, "run": snap["run"]}
	if typeof(snap["meta"]) == TYPE_DICTIONARY:
		body["meta"] = snap["meta"]
	_push_in_flight = true
	var edits_at := _edits
	status = Status.SAVING
	changed.emit()
	transport.call("PUT", "/api/save", JSON.stringify(body), func(code: int, text: String) -> void:
		_on_pushed(code, text, edits_at))


func _on_pushed(code: int, text: String, edits_at: int) -> void:
	_push_in_flight = false
	var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if code == 200 and typeof(parsed) == TYPE_DICTIONARY:
		_rev = int(parsed.get("rev", _rev + 1))
		_dirty = _edits != edits_at
		_save_sync()
		_retry_index = 0
		last_synced = int(Time.get_unix_time_from_system())
		status = Status.SAVING if _dirty else Status.SAVED
		changed.emit()
		if _dirty:
			_push_timer.start(PUSH_DELAY)
		_run_after_push()
	elif code == 409 and typeof(parsed) == TYPE_DICTIONARY and parsed.has("server"):
		_run_after_push()
		_conflict(parsed["server"])
	elif code == 401:
		_run_after_push()
		_on_me(401, "")
	else:
		_go_offline()
		_schedule_retry(_push)
		_run_after_push()


func _flush_then(cb: Callable) -> void:
	if not _dirty or status == Status.EXPIRED or status == Status.GUEST:
		cb.call()
		return
	_after_push = cb
	_push_timer.stop()
	_push()


func _run_after_push() -> void:
	if _after_push.is_valid():
		var cb := _after_push
		_after_push = Callable()
		cb.call()


func _go_offline() -> void:
	status = Status.OFFLINE if not account.is_empty() else Status.GUEST
	changed.emit()
	if not account.is_empty() and not _push_in_flight:
		_schedule_retry(check)


func _schedule_retry(what: Callable) -> void:
	var delay: float = RETRY_DELAYS[mini(_retry_index, RETRY_DELAYS.size() - 1)]
	_retry_index += 1
	for c in _retry_timer.timeout.get_connections():
		_retry_timer.timeout.disconnect(c["callable"])
	_retry_timer.timeout.connect(what, CONNECT_ONE_SHOT)
	_retry_timer.start(delay)


# ============================================================================ local state

## Server-side Gem wallet (lane S). OFF unless project setting `axie/gem_wallet` = "remote" (or a test sets
## `remote_wallet_enabled`). Signed in -> RemoteGemWallet; signed out -> MetaState back to the local wallet.
var remote_wallet_enabled := false
var _remote_wallet: RemoteGemWallet = null


func _attach_remote_wallet() -> void:
	if not (remote_wallet_enabled or String(ProjectSettings.get_setting("axie/gem_wallet", "local")) == "remote"):
		return
	if _remote_wallet != null:
		return
	_remote_wallet = RemoteGemWallet.new(transport)
	MetaState.use_remote_gem_wallet(_remote_wallet)
	_remote_wallet.refresh()


func _detach_remote_wallet() -> void:
	if _remote_wallet == null:
		return
	_remote_wallet = null
	MetaState.set_gem_wallet(null)   # gem_wallet() lazily rebuilds the local wallet


func _become_guest() -> void:
	_detach_remote_wallet()
	SaveStore.erase_as("", ACCOUNT_PATH)
	account = {}
	SaveStore.profile = ""
	_rev = 0
	_dirty = false
	status = Status.GUEST
	_reload_game_state()
	changed.emit()
	_refresh_scene()


func _reload_game_state() -> void:
	_profile_changed = true
	var meta := get_node_or_null("/root/MetaState")
	if meta != null:
		meta.reload_from_store()
	var run := get_node_or_null("/root/RunState")
	if run != null:
		run.reset()


## The menu asks for the welcome panel in _ready(), which is usually before /api/me has
## answered; this is the second chance, once the answer says "nobody is signed in".
func _offer_welcome_on_menu() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null or tree.current_scene.scene_file_path != MAIN_MENU:
		return
	if should_offer_welcome():
		mark_welcome_shown()
		AccountUI.show_welcome(_ui_layer())


func _close_welcome() -> void:
	if _layer == null:
		return
	for c in _layer.get_children():
		if c.name == "AccountWelcome":
			c.queue_free()


func _safe_scene() -> bool:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return true
	var path := tree.current_scene.scene_file_path
	return path == MAIN_MENU or path == TUTORIAL or path.get_file().begins_with("Settings")


## Rebuilds the menu so it shows the save that just became active. Never pulls a player out of a
## run: account changes only happen from the menu, Settings or at boot.
func _refresh_scene() -> void:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	if _safe_scene():
		tree.change_scene_to_file.call_deferred(MAIN_MENU)


func _load_sync() -> void:
	var s := _read_json(String(account.get("id", "")), SYNC_PATH)
	_rev = int(s.get("rev", 0))
	_dirty = bool(s.get("dirty", false))


func _set_sync(rev: int, dirty: bool) -> void:
	_rev = rev
	_dirty = dirty
	_save_sync()


func _save_sync() -> void:
	if account.is_empty():
		return
	_write_json(String(account["id"]), SYNC_PATH, {"rev": _rev, "dirty": _dirty})


## {meta: Dictionary|null, run: Dictionary|null} as stored for `who`.
func _snapshot(who: String) -> Dictionary:
	return {"meta": _parse_or_null(SaveStore.read_text_as(who, META_PATH)),
		"run": _parse_or_null(SaveStore.read_text_as(who, RUN_PATH))}


func _write_snapshot(who: String, snap: Dictionary) -> void:
	if typeof(snap.get("meta")) == TYPE_DICTIONARY:
		SaveStore.write_text_as(who, META_PATH, JSON.stringify(snap["meta"], "\t"))
	else:
		SaveStore.erase_as(who, META_PATH)
	if typeof(snap.get("run")) == TYPE_DICTIONARY:
		SaveStore.write_text_as(who, RUN_PATH, JSON.stringify(snap["run"]))
	else:
		SaveStore.erase_as(who, RUN_PATH)


func _clear_guest() -> void:
	SaveStore.erase_as("", META_PATH)
	SaveStore.erase_as("", RUN_PATH)


func _backup(snap: Dictionary) -> void:
	_write_snapshot(BACKUP_PROFILE, snap)
	var p := _prefs()
	p["backup_at"] = int(Time.get_unix_time_from_system())
	_write_json("", PREFS_PATH, p)


func _expire_backup() -> void:
	var p := _prefs()
	if not p.has("backup_at"):
		return
	if Time.get_unix_time_from_system() - float(p["backup_at"]) > BACKUP_DAYS * 86400.0:
		_write_snapshot(BACKUP_PROFILE, {})
		p.erase("backup_at")
		_write_json("", PREFS_PATH, p)


func _prefs() -> Dictionary:
	return _read_json("", PREFS_PATH)


static func _has_progress(snap: Dictionary) -> bool:
	if typeof(snap.get("run")) == TYPE_DICTIONARY:
		return true
	var m: Variant = snap.get("meta")
	if typeof(m) != TYPE_DICTIONARY:
		return false
	return int(m.get("runs", 0)) > 0 or int(m.get("shard_pool", 0)) > 0 \
		or int(m.get("xp", 0)) > 0 or (m.get("vault", []) as Array).size() > 0 \
		or (m.get("unlocks", []) as Array).size() > 0


## What the choice dialog shows for one side. Counts only — enough to tell two saves apart.
static func summarize(snap: Dictionary) -> Dictionary:
	var m: Dictionary = snap["meta"] if typeof(snap.get("meta")) == TYPE_DICTIONARY else {}
	var out := {
		"shards": int(m.get("shard_pool", 0)),
		"xp": int(m.get("xp", 0)),
		"vault": (m.get("vault", []) as Array).size(),
		"runs": int(m.get("runs", 0)),
		"wins": int(m.get("wins", 0)),
		"run": "",
		"updated_at": int(snap.get("updated_at", 0)) if snap.get("updated_at") != null else 0,
	}
	if typeof(snap.get("run")) == TYPE_DICTIONARY:
		var r: Dictionary = (snap["run"] as Dictionary).get("run", {})
		out["run"] = "%s · Ascension %d" % [String(r.get("mode", "short")).capitalize(),
			int(r.get("ascension", 0))]
	return out


static func _parse_or_null(text: String) -> Variant:
	if text.is_empty():
		return null
	var v: Variant = JSON.parse_string(text)
	return v if typeof(v) == TYPE_DICTIONARY else null


func _read_json(who: String, path: String) -> Dictionary:
	var v: Variant = _parse_or_null(SaveStore.read_text_as(who, path))
	return v if v != null else {}


func _write_json(who: String, path: String, data: Dictionary) -> void:
	SaveStore.write_text_as(who, path, JSON.stringify(data))


# ============================================================================ web plumbing

const _JS_HELPER := """
window.__adAcct = window.__adAcct || {
  req: function (method, path, body) {
    var init = { method: method, credentials: 'same-origin', cache: 'no-store' };
    if (method !== 'GET') { init.keepalive = !body || body.length < 60000; }
    if (body) { init.body = body; init.headers = { 'Content-Type': 'application/json' }; }
    return fetch(path, init).then(function (r) {
      return r.text().then(function (t) { return { status: r.status, text: t }; });
    }).catch(function (e) { return { status: 0, text: String(e) }; });
  },
  flags: function () {
    var q = new URLSearchParams(location.search);
    var out = { auth: q.get('auth') || '', error: q.get('auth_error') || '' };
    if (out.auth || out.error) {
      q.delete('auth'); q.delete('auth_error');
      var s = q.toString();
      history.replaceState(null, '', location.pathname + (s ? '?' + s : '') + location.hash);
    }
    return JSON.stringify(out);
  },
  go: function (sw) {
    location.assign('/auth/login?return=' + encodeURIComponent(location.origin + location.pathname)
      + (sw ? '&switch=1' : ''));
  }
};
"""


func _install_js() -> void:
	JavaScriptBridge.eval(_JS_HELPER, true)
	# Upload right away when the tab is hidden or closed, instead of waiting out the debounce.
	var on_hide := JavaScriptBridge.create_callback(func(_args: Array) -> void:
		if _dirty and not _push_in_flight and status != Status.EXPIRED:
			_push_timer.stop()
			_push())
	_js_keep.append(on_hide)
	JavaScriptBridge.get_interface("document").addEventListener("visibilitychange", on_hide)


func _read_url_flags() -> void:
	var raw: Variant = JavaScriptBridge.get_interface("__adAcct").flags()
	var flags: Variant = JSON.parse_string(str(raw))
	if typeof(flags) == TYPE_DICTIONARY:
		_pending_error = String(flags.get("error", ""))


func _web_transport(method: String, path: String, body: String, done: Callable) -> void:
	_js_seq += 1
	var id := _js_seq
	var cb := JavaScriptBridge.create_callback(func(args: Array) -> void:
		_js_callbacks.erase(id)
		var res: JavaScriptObject = args[0]
		done.call(int(res.status), str(res.text)))
	# create_callback's object must outlive the request or the browser calls into freed memory.
	_js_callbacks[id] = cb
	var promise: JavaScriptObject = JavaScriptBridge.get_interface("__adAcct").req(
		method, path, body if not body.is_empty() else null)
	promise.then(cb)


# ============================================================================ UI seams

func _ui_layer() -> CanvasLayer:
	if _layer == null:
		_layer = CanvasLayer.new()
		_layer.layer = 90
		add_child(_layer)
	return _layer


func _ask_with_ui(kind: String, info: Dictionary, done: Callable) -> void:
	AccountUI.show_choice(_ui_layer(), kind, info, done)


func _toast_with_ui(code: String) -> void:
	AccountUI.show_toast(_ui_layer(), code)


# ============================================================================ desktop sign-in

## Set by tests (and by a future setting) to switch the desktop path off.
var desktop_enabled_override := true
var _dt: DesktopTransport
var _auth: DesktopAuth


func _desktop_enabled() -> bool:
	return desktop_enabled_override and not DisplayServer.get_name() == "headless"


func server_url() -> String:
	return String(ProjectSettings.get_setting("axie/server_url", "https://axiedice.fun"))


## Called on desktop boot: tokens from a previous sign-in turn the service on straight away.
func _desktop_boot() -> void:
	_ensure_dt()
	_dt.tokens = DeviceTokens.load_tokens()
	if _dt.is_signed_in():
		start(_dt.request)


func _ensure_dt() -> void:
	if _dt != null:
		return
	_dt = DesktopTransport.new()
	_dt.server_url = server_url()
	add_child(_dt)
	_dt.signed_out.connect(func() -> void:
		# Server refused the refresh token: same as an expired web session, local save keeps working.
		status = Status.EXPIRED
		_pending_error = "session_expired"
		changed.emit())


## Opens the system browser and waits for the loopback callback. The login screen is lane U's;
## it calls this and listens to `changed` (and `toast` for a failure).
func begin_desktop_sign_in() -> void:
	if not _desktop_enabled() or (_auth != null and is_instance_valid(_auth)):
		return
	_ensure_dt()
	_auth = DesktopAuth.new()
	_auth.server_url = server_url()
	_auth.exchange = func(url: String, body: String, done: Callable) -> void:
		_dt.raw.call("POST", url, PackedStringArray(["Content-Type: application/json"]), body, done)
	add_child(_auth)
	_auth.finished.connect(_on_desktop_auth)
	var err := _auth.begin()
	if err != OK:
		_auth.queue_free()
		_auth = null
		toast.call("network") if toast.is_valid() else null


func cancel_desktop_sign_in() -> void:
	if _auth != null and is_instance_valid(_auth):
		_auth.cancel()


func _on_desktop_auth(ok: bool, tokens: Dictionary, error: String) -> void:
	if _auth != null:
		_auth.queue_free()
		_auth = null
	if not ok:
		if error != "cancelled":
			_pending_error = error if error != "" else "token"
			if toast.is_valid():
				toast.call(_pending_error)
		return
	_dt.tokens = {"access": tokens["access"], "refresh": tokens["refresh"],
		"device_id": String(tokens.get("device_id", ""))}
	DeviceTokens.save(_dt.tokens)
	_session_known = false
	start(_dt.request)


func _desktop_sign_out() -> void:
	var device := String(_dt.tokens.get("device_id", ""))
	var finish := func() -> void:
		DeviceTokens.clear()
		_dt.tokens = {}
		_become_guest()
	if device.is_empty():
		finish.call()
		return
	# Revoke this device server-side first; offline, stay signed in so the next boot is not silently re-auth'd.
	transport.call("POST", "/auth/devices", JSON.stringify({"id": device}), func(code: int, _t: String) -> void:
		if code == 200 or code == 401:
			finish.call()
		else:
			toast.call("sign_out_failed"))
