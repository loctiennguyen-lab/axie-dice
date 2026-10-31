extends Node
## UI-05 b23 lane S8a1: Account screen (a01-a08), DesktopSignIn overlay (a09-a12), AccountToast (a17-a18). Data-names exist per
## state, 1920 + 1280, inside the frame, text >= 14 real px at 1280, initial focus, icon/label alignment measured, no
## illustrative values. The service is a stub (no browser, no network).
## Run: godot --headless --path godot res://tests/t_ui5_account.tscn

const Align := preload("res://tests/ui5_align_check.gd")

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
	func cancel_desktop_sign_in() -> void: calls.append("cancel")
	func reopen_desktop_browser() -> void: calls.append("reopen")
	func clear_desktop_error() -> void: calls.append("clear")
	func dismiss_desktop_result() -> void: calls.append("dismiss")
	func play_as_guest() -> void: calls.append("guest")
	func sync_now() -> void: calls.append("sync")
	func sign_out() -> void: calls.append("sign_out")

var _fails: Array[String] = []
var _checks := 0
var _pairs := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_ui5_account: start ===")
	await get_tree().process_frame
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _screens(sc)
		await _overlays(sc)
		await _toasts(sc)
	UI3Theme.set_scale_override(1.0)
	_check(_pairs > 0, "align_check measured > 0 icon/label pairs (%d)" % _pairs)
	print("=== t_ui5_account: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_account: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_ui5_account: FAIL - " + f)
	get_tree().quit(1)


func _frames(n := 6) -> void:
	for _i in n:
		await get_tree().process_frame


## Common checks on a built subtree: names, text >= 14 px, buttons >= 14 px, alignment, no illustrative strings.
func _common(root: Node, names: Array, tag: String, sc: float) -> void:
	for n in names:
		_check(root.find_child(n + "*", true, false) != null, "[%s] node '%s' exists" % [tag, n])
	var all := ""
	for n in root.find_children("*", "", true, false):
		if n is Label and (n as Label).is_visible_in_tree():
			var l := n as Label
			all += l.text + "\n"
			if sc < 1.0:
				_check(float(l.get_theme_font_size("font_size")) * sc >= 14.0 - 0.01, "[%s] '%s' >= 14 real px" % [tag, l.text.left(24)])
		if n is BaseButton and (n as BaseButton).is_visible_in_tree() and sc < 1.0:
			_check(float(n.get_theme_font_size("font_size")) * sc >= 14.0 - 0.01, "[%s] button '%s' >= 14 real px" % [tag, n.get("text")])
	for bad in ["Liam", "liam@gmail.com", "2 minutes ago"]:
		_check(not all.contains(bad), "[%s] no illustrative value '%s'" % [tag, bad])
	_pairs += Align.pairs(root)
	var probs := Align.check(root)
	_check(probs.is_empty(), "[%s] icon/label alignment: %s" % [tag, "; ".join(probs)])


func _inside(c: Control, within: Rect2, tag: String) -> void:
	var r := c.get_global_rect()
	_check(within.grow(1.0).encloses(r), "[%s] %s inside the frame %s vs %s" % [tag, c.name, r, within])


func _screens(sc: float) -> void:
	var svc := StubService.new()
	add_child(svc)
	var s := AccountScreen.new()
	s.service = svc
	s.no_scene_change = true
	add_child(s)
	await _frames()
	var base := ["Header", "BackButton", "Title", "AccountPanel", "Brand", "Version"]
	var cases := [
		["signed_out", {}, base + ["SignInButton"], "SignInButton"],
		["waiting", {"desktop_phase": "waiting"}, base + ["CancelButton", "OpenBrowserButton"], "OpenBrowserButton"],
		["finishing", {"desktop_phase": "finishing"}, base + ["Spinner"], "BackButton"],
		["error", {"desktop_phase": "error", "desktop_error": "timeout"}, base + ["ToneDisc", "ErrorCode", "TryAgainButton"], "TryAgainButton"],
		["error", {"desktop_phase": "error", "desktop_error": "admin_policy_enforced"}, base + ["ToneDisc", "ErrorCode", "UseAnotherButton"], "UseAnotherButton"],
		["expired", {"status": AccountService.Status.EXPIRED, "account": {"name": "Mai", "email": "m@x.test"}},
			base + ["ToneDisc", "BackToMenuButton", "SignInButton"], "SignInButton"],
		["signed_in", {"status": AccountService.Status.SAVED, "account": {"name": "Mai", "email": "m@x.test"}},
			base + ["Who", "Avatar", "AccountName", "SaveStatus", "SignOutButton"], "SignOutButton"],
	]
	for c in cases:
		svc.desktop_phase = "idle"
		svc.desktop_error = ""
		svc.status = 0
		svc.account = {}
		for k in (c[1] as Dictionary):
			svc.set(k, c[1][k])
		svc.changed.emit()
		await _frames()
		var tag := "%s %s %.2f" % [c[0], c[1].get("desktop_error", ""), sc]
		_check(s.state == c[0], "[%s] state is %s (%s)" % [tag, c[0], s.state])
		_common(s, c[2], tag, sc)
		var fo := get_viewport().gui_get_focus_owner()
		_check(fo != null and fo.name == c[3], "[%s] initial focus is %s (%s)" % [tag, c[3], fo.name if fo != null else "none"])
		_inside(s.find_child("AccountPanel", true, false), Rect2(Vector2.ZERO, s.size), tag)
		_inside(s.find_child("Header", true, false), Rect2(Vector2.ZERO, s.size), tag)
		if c[0] == "signed_in":
			_check((s.find_child("AccountName", true, false) as Label).text == "Mai", "[%s] name comes from the service" % tag)
			(s.find_child("SignOutButton", true, false) as Button).pressed.emit()
			await _frames()
			_check(s.find_child("SignOutWarn", true, false) != null, "[%s] armed shows the warning" % tag)
			var b := s.find_child("SignOutButton", true, false) as Button
			_check(b.text == "Press again to sign out" and b.theme_type_variation == &"ButtonDanger", "[%s] armed: danger button" % tag)
			_common(s, base + ["SignOutWarn"], tag + " armed", sc)
	svc.account = {}
	svc.status = 0
	svc.desktop_phase = "waiting"
	svc.changed.emit()
	await _frames(2)
	svc.calls.clear()
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	Input.parse_input_event(esc)
	await _frames(3)
	_check(svc.calls.has("cancel"), "Esc while waiting cancels the sign-in (%s)" % svc.calls)
	s.queue_free()
	svc.queue_free()
	await get_tree().process_frame


func _overlays(sc: float) -> void:
	var svc := StubService.new()
	svc.account = {"name": "Mai"}
	add_child(svc)
	var layer := CanvasLayer.new()
	add_child(layer)
	svc.desktop_phase = "waiting"
	var ov := AccountUI.show_desktop_flow(layer, svc, 0.0)
	var base := ["Scrim", "DesktopSignIn", "Title"]
	var cases := [
		["waiting", "", base + ["Body", "OpenBrowserButton", "CancelButton"], "OpenBrowserButton"],
		["finishing", "", base + ["Body", "Spinner"], ""],
		["signed_in", "", base + ["ToneDisc", "ContinueButton", "KeyCap"], "ContinueButton"],
		["error", "network", base + ["ToneDisc", "Body", "TryAgainButton", "CloseButton"], "TryAgainButton"],
	]
	for c in cases:
		svc.desktop_phase = c[0]
		svc.desktop_error = c[1]
		svc.changed.emit()
		await _frames()
		var tag := "overlay %s %.2f" % [c[0], sc]
		_common(ov, c[2], tag, sc)
		if c[3] != "":
			var fo := get_viewport().gui_get_focus_owner()
			_check(fo != null and fo.name == c[3], "[%s] initial focus is %s (%s)" % [tag, c[3], fo.name if fo != null else "none"])
		var d := ov.find_child("DesktopSignIn", true, false) as Control
		_check(absf(d.size.x - float(UI3Theme.size_of("modal_s_w"))) < 1.0, "[%s] dialog is modal_s_w wide (%s)" % [tag, d.size.x])
		_inside(d, Rect2(Vector2.ZERO, ov.size), tag)
		if c[0] == "signed_in":
			_check((ov.find_child("Title", true, false) as Label).text == "Signed in as Mai", "[%s] title uses the service name" % tag)
			var cap := ov.find_child("KeyCap", true, false)
			_check(cap != null and cap.get_node("Key").text == "Space", "[%s] Continue carries Space" % tag)
	for b in [["error", "network", "TryAgainButton", ["clear", "sign_in:false"]], ["error", "network", "CloseButton", ["clear"]],
			["waiting", "", "OpenBrowserButton", ["reopen"]], ["waiting", "", "CancelButton", ["cancel"]]]:
		svc.desktop_phase = b[0]
		svc.desktop_error = b[1]
		svc.changed.emit()
		await _frames(2)
		svc.calls.clear()
		(ov.find_child(b[2], true, false) as Button).pressed.emit()
		_check(svc.calls == b[3], "overlay %s calls %s (got %s)" % [b[2], b[3], svc.calls])
	svc.desktop_phase = "idle"
	svc.changed.emit()
	await _frames(2)
	_check(not is_instance_valid(ov) or ov.is_queued_for_deletion(), "overlay closes when the phase is idle")
	layer.queue_free()
	svc.queue_free()
	await get_tree().process_frame


func _toasts(sc: float) -> void:
	var svc := StubService.new()
	add_child(svc)
	var layer := CanvasLayer.new()
	svc.add_child(layer)
	for c in [["access_denied", ["TryAgainButton", "ContinueWithoutSigningInButton"], &"error"],
			["session_expired", ["SignInButton"], &"warn"], ["admin_policy_enforced", ["UseAnotherButton"], &"error"]]:
		var h := AccountUI.show_toast(layer, c[0])
		await _frames()
		var tag := "toast %s %.2f" % [c[0], sc]
		_common(h, ["AccountToast", "ToneDisc", "Text", "Acts"] + c[1], tag, sc)
		var disc := h.find_child("ToneDisc", true, false)
		_check(disc != null and disc.get_meta("tone") == c[2], "[%s] tone %s" % [tag, c[2]])
		var t := h.find_child("AccountToast", true, false) as Control
		_check(absf(t.size.x - float(UI3Theme.size_of("toast_max_w"))) < 1.0, "[%s] toast is toast_max_w wide (%s)" % [tag, t.size.x])
		_inside(t, Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size), tag)
		for n in c[1]:
			var b := h.find_child(n, true, false) as Button
			_check(b != null and b.theme_type_variation != &"ButtonPrimaryM", "[%s] %s is secondary" % [tag, n])
		var first := h.find_child(c[1][0], true, false) as Button
		svc.calls.clear()
		first.pressed.emit()
		await _frames(2)
		var want: String = {"TryAgainButton": "sign_in:false", "SignInButton": "sign_in:false", "UseAnotherButton": "sign_in:true"}[c[1][0]]
		_check(svc.calls == [want], "[%s] %s calls the service (%s)" % [tag, c[1][0], svc.calls])
		_check(not is_instance_valid(h) or h.is_queued_for_deletion(), "[%s] pressing an action frees the toast" % tag)
		if is_instance_valid(h):
			h.queue_free()
		await get_tree().process_frame
	layer.queue_free()
	svc.queue_free()
	await get_tree().process_frame
