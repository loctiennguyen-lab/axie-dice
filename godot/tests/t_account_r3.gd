extends Node
## B3 Account screen (M13): each state renders from a stub service (no browser, no network),
## Cancel calls the service cancel, Sign out (two presses) returns to the signed-out state,
## and the real DesktopAuth cancel closes the loopback listener.

class StubService extends Node:
	signal changed
	var status: int = 0
	var account: Dictionary = {}
	var desktop_phase := "idle"
	var desktop_error := ""
	var calls: Array = []
	func is_signed_in() -> bool: return not account.is_empty()
	func display_name() -> String: return String(account.get("name", ""))
	func sign_in(sw: bool = false) -> void: calls.append("sign_in:%s" % sw)
	func cancel_desktop_sign_in() -> void:
		calls.append("cancel")
		desktop_phase = "idle"
		changed.emit()
	func reopen_desktop_browser() -> void: calls.append("reopen")
	func clear_desktop_error() -> void: calls.append("clear")
	func play_as_guest() -> void: calls.append("guest")
	func sign_out() -> void:
		calls.append("sign_out")
		account = {}
		status = 0
		changed.emit()

var _fails := 0


func _ok(cond: bool, what: String) -> void:
	if not cond:
		_fails += 1
		print("  FAIL: ", what)


func _screen(svc: Node) -> AccountScreen:
	var s := AccountScreen.new()
	s.service = svc
	s.no_scene_change = true
	add_child(s)
	return s


func _has(s: Node, n: String) -> bool:
	return s.find_child(n, true, false) != null


func _press(s: Node, n: String) -> void:
	(s.find_child(n, true, false) as Button).pressed.emit()


func _title(s: Node) -> String:
	return (s.find_child("Title", true, false) as Label).text


func _ready() -> void:
	await get_tree().process_frame
	var svc := StubService.new()
	add_child(svc)

	# signed out
	var s := _screen(svc)
	await get_tree().process_frame
	_ok(s.state == "signed_out", "starts signed_out")
	_ok(_has(s, "SignInButton") and _has(s, "GuestButton"), "signed_out has Google + guest")
	_press(s, "SignInButton")
	_ok(svc.calls.has("sign_in:false"), "Continue with Google calls sign_in")
	_press(s, "GuestButton")
	_ok(svc.calls.has("guest"), "guest button calls play_as_guest")

	# waiting
	svc.desktop_phase = "waiting"
	svc.changed.emit()
	_ok(s.state == "waiting" and _title(s) == "Finish signing in", "waiting state")
	_ok(_has(s, "OpenAgainButton") and _has(s, "CancelButton"), "waiting has reopen + cancel")
	_press(s, "OpenAgainButton")
	_ok(svc.calls.has("reopen"), "reopen calls the service")
	_press(s, "CancelButton")
	await get_tree().process_frame
	_ok(svc.calls.has("cancel"), "Cancel calls the service cancel")
	_ok(s.state == "signed_out", "after cancel, back to signed_out")

	# errors
	for code in ["timeout", "access_denied", "network", "admin_policy_enforced", "weird"]:
		svc.desktop_phase = "error"
		svc.desktop_error = code
		svc.changed.emit()
		await get_tree().process_frame
		_ok(s.state == "error" and _has(s, "RetryButton") and _has(s, "GuestButton"), "error state " + code)
		_ok(not _title(s).is_empty(), "error title " + code)
	_ok(_has(s, "ErrorCode"), "error state shows the error code line")
	_ok(_title(s) == "Sign-in didn't work", "unknown code gets the generic title")
	svc.desktop_error = "admin_policy_enforced"
	svc.changed.emit()
	svc.calls.clear()
	_press(s, "RetryButton")
	_ok(svc.calls.has("sign_in:true"), "workspace-blocked retry switches account")
	svc.desktop_phase = "idle"
	svc.desktop_error = ""

	# expired
	svc.status = AccountService.Status.EXPIRED
	svc.account = {"name": "Mai", "email": "m@x.io"}
	svc.changed.emit()
	await get_tree().process_frame
	_ok(s.state == "expired" and _title(s) == "Session expired" and _has(s, "SignInButton"), "expired state")

	# signed in + sign out (two presses)
	svc.status = AccountService.Status.SAVED
	svc.changed.emit()
	await get_tree().process_frame
	_ok(s.state == "signed_in", "signed_in state")
	_ok((s.find_child("AccountName", true, false) as Label).text == "Mai", "shows the name")
	_ok(_has(s, "Avatar"), "shows avatar")
	_press(s, "SignOutButton")
	_ok(not svc.calls.has("sign_out") and _has(s, "SignOutWarn"), "first press only arms")
	await get_tree().process_frame
	_press(s, "SignOutButton")
	await get_tree().process_frame
	_ok(svc.calls.has("sign_out"), "second press signs out")
	_ok(s.state == "signed_out", "sign out returns to signed_out")
	s.queue_free()
	svc.queue_free()

	# the real service: cancel closes the listener and clears the phase
	var auth := DesktopAuth.new()
	var opened: Array = []
	auth.open_url = func(u: String) -> void: opened.append(u)
	add_child(auth)
	var res: Array = []
	auth.finished.connect(func(ok: bool, _t: Dictionary, e: String) -> void: res.append([ok, e]))
	_ok(auth.begin() == OK, "begin listens")
	var port := auth.listen_port()
	auth.reopen()
	_ok(opened.size() == 2 and opened[0] == opened[1], "reopen reuses the same URL")
	auth.cancel()
	_ok(res == [[false, "cancelled"]], "cancel emits cancelled")
	var probe := TCPServer.new()
	_ok(probe.listen(port, "127.0.0.1") == OK, "port is free after cancel (listener stopped)")
	probe.stop()
	auth.queue_free()
	var live: Node = load("res://autoload/AccountService.gd").new()
	add_child(live)
	live.cancel_desktop_sign_in()   # no flow running: must not crash
	live.desktop_phase = "error"
	live.clear_desktop_error()
	_ok(live.desktop_phase == "idle", "clear_desktop_error resets")
	live.free()

	print("t_account_r3: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(0 if _fails == 0 else 1)
