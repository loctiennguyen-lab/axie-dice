class_name AccountScreen
extends Control
## M13 Account (B3, desktop sign-in). Spec: ui-02-round3 README section 2 M13, frames M13a (choose),
## M13b (waiting), M13e (signed in), M13f (errors sheet). Drawn: signed_out, waiting, signed_in,
## error (cancelled / timed out / no network / company workspace / generic), expired.
## Not drawn here: M13c/d (first sign-in move + conflict) stay in AccountUI.show_choice.
## The screen only shows what the service says and calls it; it never owns sign-in state.
## `service` is injectable so tests can stub it (no browser, no network).

const Parts := preload("res://scenes/account/ui5/AccountParts.gd")

var service: Node
var no_scene_change := false
## "signed_out" | "waiting" | "finishing" | "signed_in" | "error" | "expired"
var state := ""
var _host: VBoxContainer
var _back: Button
var _focus: Button
var _sign_out_armed := false


func _ready() -> void:
	if service == null:
		service = AccountService
	_build()
	service.changed.connect(_refresh)
	tree_exiting.connect(func() -> void:
		if is_instance_valid(service) and service.changed.is_connected(_refresh):
			service.changed.disconnect(_refresh))
	_refresh()


func derive_state() -> String:
	var phase: String = service.get("desktop_phase") if service.get("desktop_phase") != null else "idle"
	if phase == "waiting":
		return "waiting"
	if phase == "finishing":
		return "finishing"
	if phase == "error":
		return "error"
	if int(service.status) == AccountService.Status.EXPIRED:
		return "expired"
	if service.is_signed_in():
		return "signed_in"
	return "signed_out"


## Error code -> [headline, detail, retry label, retry uses "another account"]; spec M13f copy.
static func error_copy(code: String) -> Array:
	match code:
		"cancelled", "access_denied":
			return ["Sign-in cancelled", "You closed the Google window before finishing.", "Try again"]
		"timeout", "expired", "state":
			return ["Sign-in timed out", "Sign-in timed out. Try again.", "Try again"]
		"token":
			return ["Sign-in didn't finish", "Couldn't finish signing in. Try again.", "Try again"]
		"network":
			return ["No network", "Can't reach sign-in. Check your connection and try again.", "Try again"]
		"admin_policy_enforced", "org_internal":
			return ["Workspace blocked", "This Google account belongs to a workspace that does not allow game sign-in.", "Use another account"]
	return ["Sign-in didn't work", AccountService.error_message(code), "Try again"]


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.is_action_pressed(&"menu_back"):
		if state == "finishing":
			pass  # loading: Esc does nothing
		elif state == "waiting":
			service.cancel_desktop_sign_in()
		else:
			_on_back()
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func _build() -> void:
	# UI-05 a01-a08: dusk backdrop, Header plate top-left (screen margin), AccountPanel centred.
	theme = UI3Theme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.name = "PlateHost"  # t_ui_laws L0: the screen paints on a plate
	bg.color = UI3Theme.color("bg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var bx: Dictionary = Parts.box("AccountPanel")
	center.add_child(bx["panel"])
	_host = bx["col"]
	var m := UI3Theme.space("screen_margin")
	var h: Dictionary = Parts.header("Account", _on_back)
	var hd := h["header"] as Control
	hd.position = Vector2(m, m)
	add_child(hd)
	_back = h["back"]


func _refresh() -> void:
	var next := derive_state()
	if next != "signed_in":
		_sign_out_armed = false
	state = next
	for c in _host.get_children():
		_host.remove_child(c)
		c.queue_free()
	_host.add_child(Parts.brand(String(ProjectSettings.get_setting("application/config/version", ""))))
	_focus = null
	match state:
		"waiting":
			_draw_waiting()
		"finishing":
			_host.add_child(Parts.banner("Signing you in…"))
			_host.add_child(Parts.body("Google said yes. Checking your account."))
			_host.add_child(_spinner())
		"signed_in":
			_draw_signed_in()
			# the flow result has been shown; let the service forget it
			if service.has_method("dismiss_desktop_result") and String(service.get("desktop_phase")) == "signed_in":
				service.dismiss_desktop_result.call_deferred()
		"error":
			_draw_error()
		"expired":
			_draw_expired()
		_:
			_draw_signed_out()
	# initial focus: the primary of the state (or the sign-out button); states with no button keep Back
	(_focus if _focus != null else _back).grab_focus.call_deferred()


func _spinner() -> Control:
	var s := Ui5Spinner.new()
	s.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return s


func _add_btn(b: Button, cb: Callable, focus := false) -> Button:
	b.pressed.connect(cb)
	if focus:
		_focus = b
	return b


func _draw_signed_out() -> void:
	# Round 2: sign-in is required to play (dice are rolled on the server). No guest, no offline play.
	_host.add_child(Parts.banner("Sign in to play"))
	_host.add_child(Parts.body("Dice are rolled on our server, so you need an account to start a run."))
	_host.add_child(_add_btn(Parts.btn("SignInButton", "Sign in", &"primary", &"L", true), func() -> void: service.sign_in(), true))


func _draw_waiting() -> void:
	_host.add_child(Parts.banner("Finish signing in in your browser"))
	_host.add_child(Parts.body("We opened a browser window. Come back here when it says you are done."))
	var cancel := _add_btn(Parts.btn("CancelButton", "Cancel"), func() -> void: service.cancel_desktop_sign_in())
	var again := _add_btn(Parts.btn("OpenBrowserButton", "Open browser again", &"primary", &"M"), func() -> void: service.reopen_desktop_browser(), true)
	_host.add_child(Parts.foot_row(cancel, again))


func _draw_signed_in() -> void:
	_host.add_child(Parts.banner("Signed in"))
	_host.add_child(Parts.who(String(service.display_name()), "%s · Google" % String(service.account.get("email", ""))))
	var line: Array = AccountUI.status_line(service)
	_host.add_child(Parts.kv("Cloud save: " + String(line[0])))
	if _sign_out_armed:
		_host.add_child(Parts.body("You will need to sign in again to start a run. Your progress stays saved.", false, "SignOutWarn"))
	var b := Parts.btn("SignOutButton", "Press again to sign out" if _sign_out_armed else "Sign out",
		&"danger" if _sign_out_armed else &"secondary", &"M")
	_host.add_child(_add_btn(b, _press_sign_out, true))


func _draw_error() -> void:
	var code := String(service.get("desktop_error"))
	var copy := error_copy(code)
	_host.add_child(Parts.banner(String(copy[0]), &"error"))
	_host.add_child(Parts.body(String(copy[1])))
	_host.add_child(Parts.body("Error code: %s" % code, true, "ErrorCode"))
	var other := code in ["admin_policy_enforced", "org_internal"]
	_host.add_child(_add_btn(Parts.btn("UseAnotherButton" if other else "TryAgainButton", String(copy[2]), &"primary", &"L", true),
		func() -> void: service.sign_in(other), true))


func _draw_expired() -> void:
	_host.add_child(Parts.banner("Session expired", &"warn"))
	_host.add_child(Parts.body("Your session expired. Sign in again to continue this run."))
	var back := _add_btn(Parts.btn("BackToMenuButton", "Back to menu"), _on_back)
	var si := _add_btn(Parts.btn("SignInButton", "Sign in", &"primary", &"M"), func() -> void: service.sign_in(), true)
	_host.add_child(Parts.foot_row(back, si))


func _press_sign_out() -> void:
	if not _sign_out_armed:
		_sign_out_armed = true
		_refresh()
		return
	_sign_out_armed = false
	service.sign_out()
