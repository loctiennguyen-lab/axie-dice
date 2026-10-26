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
var _cpu0 := false
var _held_save: Callable = Callable()
var _hold_save := false
var _exchanges := 0


## True if a TCP connection to the loopback `port` is accepted (a closed port is refused).
func _port_open(port: int) -> bool:
	var c := StreamPeerTCP.new()
	c.connect_to_host("127.0.0.1", port)
	var ok := false
	for _i in 60:
		c.poll()
		var st := c.get_status()
		if st == StreamPeerTCP.STATUS_CONNECTED:
			# macOS reports a REFUSED loopback connect as CONNECTED for one frame, then NONE (measured with a probe:
			# closed port -> [CONNECTING, CONNECTED, NONE, ...]; real listener -> CONNECTED stays). So "connected" only
			# counts if it is still connected a few frames later. The assert itself is unchanged.
			for _k in 6:
				await get_tree().process_frame
				c.poll()
			ok = c.get_status() == StreamPeerTCP.STATUS_CONNECTED
			break
		if st == StreamPeerTCP.STATUS_ERROR or st == StreamPeerTCP.STATUS_NONE:
			break
		await get_tree().process_frame
	c.disconnect_from_host()
	return ok


func _port_of(url: String) -> int:
	return int(url.split("port=")[1].split("&")[0])


## A bare DesktopAuth with a fake browser and exchange; returns it already begun.
func _bare_auth() -> DesktopAuth:
	var a := DesktopAuth.new()
	a.open_url = func(u: String) -> void: _opened.append(u)
	a.raise_window = func() -> void: pass
	a.exchange = func(_u: String, _b: String, done: Callable) -> void:
		_exchanges += 1
		done.call(200, JSON.stringify({"access": "A", "refresh": "R", "expires_in": 1200, "device_id": "d"}))
	add_child(a)
	return a


func _send_cb(port: int, state: String) -> void:
	var c := StreamPeerTCP.new()
	c.connect_to_host("127.0.0.1", port)
	for _i in 100:
		c.poll()
		if c.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			break
		await get_tree().process_frame
	if c.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		c.put_data(("GET /cb?code=LATE&state=%s HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n" % state).to_utf8_buffer())
		for _i in 10:
			await get_tree().process_frame
	c.disconnect_from_host()


func _bare_auth_tests() -> void:
	# success: power settings come back, port closes
	OS.low_processor_usage_mode = true
	var a := _bare_auth()
	var done_ok := [false]
	a.finished.connect(func(ok: bool, _t: Dictionary, _e: String) -> void: done_ok[0] = ok)
	_check(a.begin() == OK, "bare auth begins")
	var port := a.listen_port()
	var state := String(_opened[_opened.size() - 1]).split("state=")[1]
	_check(not OS.low_processor_usage_mode, "full-rate loop while waiting")
	_check(await _port_open(port), "port accepts while waiting")
	var c := StreamPeerTCP.new()
	c.connect_to_host("127.0.0.1", port)
	for _i in 100:
		c.poll()
		if c.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			break
		await get_tree().process_frame
	c.put_data(("GET /cb?code=OK&state=%s HTTP/1.1\r\nHost: x\r\n\r\n" % state).to_utf8_buffer())
	for _i in 100:
		if done_ok[0]:
			break
		await get_tree().process_frame
	c.disconnect_from_host()
	_check(done_ok[0], "bare auth succeeds")
	_check(OS.low_processor_usage_mode, "low_processor_usage_mode restored after success")
	_check(not DisplayServer.screen_is_kept_on(), "keep_screen_on off after success")
	_check(not await _port_open(port), "port closed after success")
	a.queue_free()

	# cancel: port refuses, a late /cb is ignored
	OS.low_processor_usage_mode = true
	_exchanges = 0
	a = _bare_auth()
	var res: Array = []
	a.finished.connect(func(ok: bool, _t: Dictionary, e: String) -> void: res.append([ok, e]))
	a.begin()
	port = a.listen_port()
	state = String(_opened[_opened.size() - 1]).split("state=")[1]
	a.cancel()
	_check(res.size() == 1 and res[0][1] == "cancelled", "cancel finishes once with 'cancelled'")
	_check(OS.low_processor_usage_mode, "low_processor_usage_mode restored after cancel")
	_check(not DisplayServer.screen_is_kept_on(), "keep_screen_on off after cancel")
	_check(not await _port_open(port), "port refuses connection after Cancel")
	await _send_cb(port, state)
	_check(_exchanges == 0 and res.size() == 1, "late /cb after Cancel is ignored (no exchange, no second finish)")
	a.queue_free()

	# timeout
	OS.low_processor_usage_mode = true
	a = _bare_auth()
	res.clear()
	a.finished.connect(func(ok: bool, _t: Dictionary, e: String) -> void: res.append([ok, e]))
	a.begin()
	port = a.listen_port()
	a._age = DesktopAuth.LOGIN_TIMEOUT_S + 1.0
	for _i in 5:
		await get_tree().process_frame
	_check(res.size() == 1 and res[0][1] == "timeout", "timeout finishes with 'timeout'")
	_check(OS.low_processor_usage_mode, "low_processor_usage_mode restored after timeout")
	_check(not DisplayServer.screen_is_kept_on(), "keep_screen_on off after timeout")
	_check(not await _port_open(port), "port closed after timeout")
	a.queue_free()

	# freed mid-flow
	OS.low_processor_usage_mode = true
	a = _bare_auth()
	a.begin()
	port = a.listen_port()
	_check(not OS.low_processor_usage_mode, "waiting again takes the full-rate loop")
	remove_child(a)
	a.free()
	_check(OS.low_processor_usage_mode, "freed mid-flow restores low_processor_usage_mode")
	_check(not await _port_open(port), "freed mid-flow closes the port")
	await get_tree().process_frame


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("FAIL ", what)


func _ready() -> void:
	_guard.capture()
	_cpu0 = OS.low_processor_usage_mode
	await get_tree().process_frame
	await _bare_auth_tests()
	_opened.clear()
	OS.low_processor_usage_mode = true   # observable: the service flow must hand it back
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
			var answer := func() -> void: done.call(200, JSON.stringify({"rev": 0, "meta": null, "run": null}))
			if _hold_save:
				_held_save = answer
			else:
				answer.call()
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
	var first_port := _port_of(String(_opened[0]))
	var first_state := String(_opened[0]).split("state=")[1]
	(flow.find_child("Cancel", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(OS.low_processor_usage_mode, "service flow: low_processor_usage_mode restored after Cancel")
	_check(not await _port_open(first_port), "service flow: port refuses connection after Cancel")
	await _send_cb(first_port, first_state)
	_check(_svc.desktop_phase == "idle" and calls.count("POST https://axiedice.fun/auth/desktop/token") == 0 \
		and not _svc.is_signed_in(), "late /cb after Cancel is ignored")
	_check(_svc.desktop_phase == "idle" and _svc._ui_layer().get_node_or_null("DesktopSignInFlow") == null, "Cancel returns to idle and removes the overlay")
	_opened.clear()
	_svc.sign_in()
	await get_tree().process_frame
	_check(_opened.size() == 1 and _svc.desktop_phase == "waiting", "sign-in after cancel starts a fresh flow")

	# the browser calls back
	var url := String(_opened[0])
	var port := int(url.split("port=")[1].split("&")[0])
	var state := url.split("state=")[1]
	_hold_save = true   # the cloud save answers late: signed in is known, the reconcile has not run
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
	_check(OS.low_processor_usage_mode, "service flow: low_processor_usage_mode restored after success")
	_check(not DisplayServer.screen_is_kept_on(), "service flow: keep_screen_on off after success")
	_check(rs.find_child("SignInButton", true, false) == null, "no stale Sign in to play button")
	# CHECKING: the profile has switched but the cloud save is not reconciled yet
	_check(int(_svc.status) == AccountService.Status.CHECKING and _svc.reconciling and _held_save.is_valid(), "cloud save still pending (CHECKING)")
	_check(rs.account_state() == "loading" and rs.state == "loading", "Run Setup is 'loading' while CHECKING")
	_check(rs.begin_block_reason() == "Signing you in…", "Begin reason says Signing you in…")
	var blocked: Dictionary = await rs.begin()
	_check(not bool(blocked.get("ok", true)) and String(blocked.get("code", "")) == "blocked", "Begin refuses during CHECKING")
	_check(_svc.status == AccountService.Status.CHECKING, "refused Begin changed nothing")
	_hold_save = false
	_held_save.call()   # the cloud save arrives; this test scene is not a "safe" screen, so it waits for the menu
	_svc.menu_entered()   # ... which applies it: the reconcile runs now
	await get_tree().process_frame
	_check(not _svc.reconciling and int(_svc.status) in [AccountService.Status.SAVED, AccountService.Status.SAVING], "reconcile done (SAVED, or SAVING while the first upload runs)")
	(flow.find_child("Continue", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(rs.state == "normal" and rs.begin_block_reason() == "", "Run Setup unblocked after reconcile + overlay closed, Begin allowed")
	_check(_svc.desktop_phase == "idle" and _svc._ui_layer().get_node_or_null("DesktopSignInFlow") == null, "Continue dismisses the overlay")

	# what happens to the open screen after a reconcile changed the active save
	var AS: GDScript = load(SVC)
	_check(AS.refresh_action(AccountService.RUN_SETUP_SCENE, null, false) == "skip", "Run Setup: same data, no reload (picked team kept)")
	_check(AS.refresh_action(AccountService.RUN_SETUP_SCENE, null, true) == "reload", "Run Setup: new data, idle, reload")
	_check(AS.refresh_action(AccountService.RUN_SETUP_SCENE, rs, true) == "reload", "Run Setup (real, no modal): reload")
	rs.open_picker(0)
	_check(rs.has_modal() and AS.refresh_action(AccountService.RUN_SETUP_SCENE, rs, true) == "defer", "Run Setup: modal open, reload deferred")
	rs.close_modal()
	_check(AS.refresh_action(AccountService.LAND_SCENE, null, false) == "reload", "Land: reload")
	var fake_land := FakeModalScene.new()
	fake_land.open = true
	_check(AS.refresh_action(AccountService.LAND_SCENE, fake_land, false) == "defer", "Land: modal open, reload deferred")
	fake_land.free()
	_check(AS.refresh_action(AccountService.MAIN_MENU, null, false) == "menu", "other scenes: back to the menu")

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
	OS.low_processor_usage_mode = _cpu0
	_guard.restore()
	print("t_desktop_signin: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)


class FakeModalScene extends Node:
	var open := false

	func has_modal() -> bool:
		return open
