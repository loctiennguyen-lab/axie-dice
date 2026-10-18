class_name AccountScreen
extends Control
## M13 Account (B3, desktop sign-in). Spec: ui-02-round3 README section 2 M13, frames M13a (choose),
## M13b (waiting), M13e (signed in), M13f (errors sheet). Drawn: signed_out, waiting, signed_in,
## error (cancelled / timed out / no network / company workspace / generic), expired.
## Not drawn here: M13c/d (first sign-in move + conflict) stay in AccountUI.show_choice.
## The screen only shows what the service says and calls it; it never owns sign-in state.
## `service` is injectable so tests can stub it (no browser, no network).

const PANEL_W := 560.0

var service: Node
var no_scene_change := false
## "signed_out" | "waiting" | "finishing" | "signed_in" | "error" | "expired"
var state := ""
var _host: VBoxContainer
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
			return ["Sign-in was cancelled", "You closed the Google window before finishing.", "Try again"]
		"timeout", "expired", "state":
			return ["Sign-in timed out", "We waited 5 minutes and did not hear back from the browser.", "Start again"]
		"network", "token":
			return ["No network", "Can't reach sign-in. Check your connection. You can keep playing as a guest.", "Try again"]
		"admin_policy_enforced", "org_internal":
			return ["Workspace blocked", "This Google account belongs to a workspace that does not allow game sign-in.", "Use another account"]
	return ["Sign-in didn't work", AccountService.error_message(code), "Try again"]


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		if state == "waiting":
			service.cancel_desktop_sign_in()
		else:
			_on_back()
		get_viewport().set_input_as_handled()


func _on_back() -> void:
	if is_inside_tree() and not no_scene_change:
		LandNav.back_to_land()


func _build() -> void:
	# UI-03 16-boot: dusk backdrop, centred column (title, 560 w plate pad 32 gap 20), version bottom-right.
	theme = UI3Theme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.name = "PlateHost"  # t_ui_laws L0: the screen paints on a plate
	bg.color = UI3Theme.color("bg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var back := UI3.button("← Back  Esc", &"quiet")
	back.name = "Back"
	back.position = Vector2(40, 40)
	back.pressed.connect(_on_back)
	add_child(back)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 48)
	center.add_child(col)
	var logo := UI3.label("AXIE DICE", "LabelScreenTitle")
	logo.name = "Logo"
	logo.add_theme_font_size_override("font_size", 64)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(logo)
	var panel := UI3.plate(&"dialog")
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(PANEL_W, 0)
	col.add_child(panel)
	_host = VBoxContainer.new()
	_host.add_theme_constant_override("separation", 20)
	panel.add_child(_host)
	var ver := UI3.label(String(ProjectSettings.get_setting("application/config/version", "")), "LabelMuted")
	ver.name = "Version"
	ver.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.offset_left = -240
	ver.offset_right = -24
	ver.offset_top = -40
	ver.offset_bottom = -16
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(ver)


func _refresh() -> void:
	var next := derive_state()
	if next != "signed_in":
		_sign_out_armed = false
	state = next
	for c in _host.get_children():
		_host.remove_child(c)
		c.queue_free()
	match state:
		"waiting":
			_draw_waiting()
		"finishing":
			_title("Signing you in…")
			_text("Google said yes. Checking your account.")
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
	# focus order: primary first, then the secondary (Esc handled in _unhandled_key_input)
	for c in _host.get_children():
		if c is Button:
			(c as Button).grab_focus.call_deferred()
			break


func _draw_signed_out() -> void:
	_title("Save your progress")
	_text("Sign in with Google to keep your game on every device. Your Sky Mavis work account works too.")
	_row_btn("SignInButton", "Continue with Google", true, func() -> void: service.sign_in())
	_row_btn("GuestButton", "Play as guest", false, _play_guest)
	_text("Guest means progress stays on this computer.", true)


func _draw_waiting() -> void:
	_title("Finish signing in")
	_text("Finish signing in in your browser.\nThen come back here; the game picks it up by itself.")
	var sp := UI3.Spinner.new()
	sp.name = "Spinner"
	_host.add_child(sp)
	_row_btn("OpenAgainButton", "Open browser again", false, func() -> void: service.reopen_desktop_browser())
	_row_btn("CancelButton", "Cancel", false, func() -> void: service.cancel_desktop_sign_in())


func _draw_signed_in() -> void:
	_title("Signed in")
	var who := HBoxContainer.new()
	who.add_theme_constant_override("separation", 12)
	var av := UI3.chip(String(service.display_name()).left(1).to_upper())
	av.name = "Avatar"
	who.add_child(av)
	var col := VBoxContainer.new()
	var nm := _text(String(service.display_name()))
	nm.name = "AccountName"
	nm.get_parent().remove_child(nm)
	col.add_child(nm)
	var mail := _text("%s · Google" % String(service.account.get("email", "")), true)
	mail.get_parent().remove_child(mail)
	col.add_child(mail)
	var line: Array = AccountUI.status_line(service)
	var st := _text("Cloud save: " + String(line[0]), true)
	st.name = "SaveStatus"
	st.get_parent().remove_child(st)
	col.add_child(st)
	who.add_child(col)
	_host.add_child(who)
	if _sign_out_armed:
		var warn := _text("Your progress stays on this computer. You will play as a guest until you sign in again.")
		warn.name = "SignOutWarn"
	_row_btn("SignOutButton", "Press again to sign out" if _sign_out_armed else "Sign out", false, _press_sign_out)


func _draw_error() -> void:
	var code := String(service.get("desktop_error"))
	var copy := error_copy(code)
	_title(String(copy[0])).add_theme_color_override("font_color", UI3Theme.color("hp_enemy"))
	_text(String(copy[1]))
	_row_btn("RetryButton", String(copy[2]), true, func() -> void: service.sign_in(code in ["admin_policy_enforced", "org_internal"]))
	_row_btn("GuestButton", "Play as guest", false, _play_guest)


func _draw_expired() -> void:
	_title("Session expired")
	_text("Please sign in again. Your progress on this computer is safe.")
	_row_btn("SignInButton", "Sign in", true, func() -> void: service.sign_in())
	_row_btn("GuestButton", "Later", false, _play_guest)


func _press_sign_out() -> void:
	if not _sign_out_armed:
		_sign_out_armed = true
		_refresh()
		return
	_sign_out_armed = false
	service.sign_out()


func _play_guest() -> void:
	if service.has_method("clear_desktop_error"):
		service.clear_desktop_error()
	service.play_as_guest()
	_on_back()


func _title(t: String) -> Label:
	var l := UI3.label(t, "LabelScreenTitle")
	l.name = "Title"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_host.add_child(l)
	return l


func _text(t: String, muted := false) -> Label:
	var l := UI3.label(t, "LabelMuted" if muted else "")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(PANEL_W - 64, 0)
	_host.add_child(l)
	return l


func _row_btn(btn_name: String, text: String, primary: bool, cb: Callable) -> Button:
	var b := UI3.button(text, &"primary" if primary else &"secondary", &"L" if primary else &"M")
	b.name = btn_name
	b.pressed.connect(cb)
	_host.add_child(b)
	return b
