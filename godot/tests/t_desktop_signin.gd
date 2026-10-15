extends Node
## After the browser calls back, the player must SEE it: the waiting overlay appears, a second click
## starts no second flow, /cb answers with a real page, the service flips to signed in, and a Run Setup
## that was showing "Sign in to play" re-evaluates (no stale guest state). No network: fake browser on
## the real loopback, fake token exchange and server. Guarded: this shares user:// with the desktop app.

const SVC := "res://autoload/AccountService.gd"
const ID := "google:t-signin"

var _fails := 0
var _guard := SaveGuard.new()
var _svc: Node
var _opened: Array = []


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	_svc = load(SVC).new()
	_svc.desktop_enabled_override = false   # keep _ready() off the real device tokens
	add_child(_svc)
	_svc.desktop_enabled_override = true
	_svc.desktop_test_mode = true
	_svc.toast = func(_c: String) -> void: pass
	_svc.ask = func(_k: String, _i: Dictionary, done: Callable) -> void: done.call("cloud")
	_svc.desktop_open_url = func(u: String) -> void: _opened.append(u)
	_svc._ensure_dt()
	var calls: Array = []
	_svc._dt.raw = func(method: String, url: String, _h: PackedStringArray, _b: String, done: Callable) -> void:
		calls.append("%s %s" % [method, url])
		if url.ends_with("/auth/desktop/token"):
			done.call(200, JSON.stringify({"access": "A", "refresh": "R", "expires_in": 1200, "device_id": "dev1"}))
		elif url.ends_with("/api/me"):
			done.call(200, JSON.stringify({"id": ID, "email": "liam@example.com", "name": "Liam"}))
		elif url.ends_with("/api/save"):
			done.call(200, JSON.stringify({"rev": 0, "meta": null, "run": null}))
		else:
			done.call(404, "")

	# Run Setup open as a guest, remote dice on: the "Sign in to play" state
	var rs: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	rs.account_service = _svc
	rs.remote_on = true
	rs.no_scene_change = true
	rs.daily_info_hook = func(cb: Callable) -> void: cb.call(true, {"used": 0, "max": 3})
	add_child(rs)
	await get_tree().process_frame
	_check(rs.state == "guest" and rs.begin_block_reason() != "", "Run Setup starts in guest state, Begin blocked")

	# 4. waiting state, one flow only
	rs._on_sign_in()
	_svc.sign_in()
	_svc.sign_in()
	await get_tree().process_frame
	_check(_opened.size() == 1, "three sign-in clicks open the browser once (got %d)" % _opened.size())
	_check(_svc.desktop_phase == "waiting", "phase waiting")
	var flow: Node = _svc._ui_layer().get_node_or_null("DesktopSignInFlow")
	_check(flow != null, "waiting overlay is on screen")
	_check(flow != null and (flow.find_child("Title", true, false) as Label).text.begins_with("Waiting for the browser"), "overlay says Waiting for the browser")
	_check(flow != null and flow.find_child("Cancel", true, false) != null and flow.find_child("OpenAgain", true, false) != null, "overlay has Cancel and Open browser again")
	(flow.find_child("OpenAgain", true, false) as Button).pressed.emit()
	_check(_opened.size() == 2 and _opened[0] == _opened[1], "Open browser again re-opens the same URL, no new flow")

	# cancel closes it, a new flow can start
	(flow.find_child("Cancel", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(_svc.desktop_phase == "idle" and _svc._ui_layer().get_node_or_null("DesktopSignInFlow") == null, "Cancel returns to idle and removes the overlay")
	_opened.clear()
	_svc.sign_in()
	await get_tree().process_frame
	_check(_opened.size() == 1 and _svc.desktop_phase == "waiting", "sign-in after cancel starts a fresh flow")

	# the browser calls back
	var url := String(_opened[0])
	var port := int(url.split("port=")[1].split("&")[0])
	var state := url.split("state=")[1]
	var c := StreamPeerTCP.new()
	c.connect_to_host("127.0.0.1", port)
	for _i in 200:
		c.poll()
		if c.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			break
		await get_tree().process_frame
	c.put_data(("GET /cb?code=ONETIME&state=%s HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n" % state).to_utf8_buffer())
	var body := ""
	for _i in 300:
		c.poll()
		var n := c.get_available_bytes()
		if n > 0:
			body += c.get_utf8_string(n)
		if _svc.desktop_phase == "signed_in" and body.contains("</html>"):
			break
		await get_tree().process_frame
	_check(body.begins_with("HTTP/1.1 200") and body.contains("text/html"), "/cb answers 200 text/html")
	_check(body.contains("you can return to Axie Dice") and body.contains("<style>") and body.contains("<h1>"), "/cb page says the return message, styled")
	_check(_svc.desktop_phase == "signed_in", "phase signed_in after the exchange")
	_check(_svc.is_signed_in() and _svc.display_name() == "Liam", "AccountService is signed in as Liam")
	_check(int(_svc.status) != AccountService.Status.GUEST, "status is no longer GUEST")
	_check(calls.count("POST https://axiedice.fun/auth/desktop/token") == 1, "exactly one token exchange")
	flow = _svc._ui_layer().get_node_or_null("DesktopSignInFlow")
	_check(flow != null and (flow.find_child("Title", true, false) as Label).text == "Signed in as Liam", "overlay shows Signed in as Liam")
	_check(rs.state == "normal" and rs.begin_block_reason() == "", "Run Setup left guest state, Begin allowed")
	_check(rs.find_child("SignInButton", true, false) == null, "no stale Sign in to play button")
	(flow.find_child("Continue", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(_svc.desktop_phase == "idle" and _svc._ui_layer().get_node_or_null("DesktopSignInFlow") == null, "Continue dismisses the overlay")

	# the page itself
	_check(DesktopAuth.page_html("T", "D", true).contains("<h1>T</h1>"), "page_html renders title")

	c.disconnect_from_host()
	rs.queue_free()
	_svc.queue_free()
	await get_tree().process_frame
	SaveStore.profile = ""
	SaveStore.on_changed = Callable()
	for p in [MetaState.SAVE_PATH, RunState.SAVE_PATH, AccountServiceScript.ACCOUNT_PATH, AccountServiceScript.SYNC_PATH]:
		SaveStore.erase_as(ID, p)
	DeviceTokens.clear()
	_guard.restore()
	print("t_desktop_signin: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)
