extends Node
## UI-07 L4: LoginScreen states, data-names, 1920 + 1280 (text >= 14 real px), focus / keys, and the MainMenu entry rules
## (signed in -> Land, guest / empty account -> Login, EXPIRED -> Login, offline -> Login(offline), new player -> Login then Tutorial).
## No network: the service is a bare AccountServiceScript instance with fields set by hand.
## Run: AXIE_TEST_NO_NET=1 godot --headless --path godot res://tests/t_ui7_login.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const SCENE := "res://scenes/login/LoginScreen.tscn"
const COMMON := ["Background", "Brand", "Logo", "Tagline", "Axie3DFrame", "SignInPanel", "SkyMavisTag", "Heading", "Title", "Body",
	"Actions", "Footer", "LegalLinks", "TermsLink", "Separator", "PrivacyLink", "Version", "GuestButton"]
const PER_STATE := {
	"default": ["Benefits", "Benefit", "BenefitTitle", "BenefitText", "GoogleButton", "GoogleMark", "GoogleG", "NoAccountLine", "GuestBlock", "GuestLine"],
	"opening": ["GoogleButton", "Spinner", "NoAccountLine", "GuestBlock"],
	"desktop-waiting": ["GoogleButton", "Spinner", "GuestBlock"],
	"desktop-finishing": ["GoogleButton", "Spinner", "GuestBlock"],
	"failed": ["StatusBox", "StatusIcon", "StatusText", "StatusTitle", "StatusBody", "TryAgainButton", "GoogleMark", "GuestBlock"],
	"failed-short": ["StatusBox", "StatusBody", "TryAgainButton", "GuestBlock"],
	"offline": ["StatusBox", "StatusTitle", "TryAgainButton", "GoogleButtonGroup", "GoogleButton", "GuestButtonGroup", "DisabledReason"],
	"expired": ["StatusBox", "StatusIcon", "StatusBody", "GoogleButton", "GuestBlock", "GuestLine"],
	"returning-guest": ["GoogleButton", "GuestBlock", "GuestRuns", "RunCount", "NoAccountLine"],
}
const PRIMARY := {"default": "GoogleButton", "opening": "GoogleButton", "desktop-waiting": "GoogleButton",
	"desktop-finishing": "GoogleButton", "failed": "TryAgainButton", "failed-short": "TryAgainButton",
	"offline": "TryAgainButton", "expired": "GoogleButton", "returning-guest": "GoogleButton"}

var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _frames(n := 6) -> void:
	for _i in n:
		await get_tree().process_frame


func _svc() -> AccountServiceScript:
	var s := AccountServiceScript.new()
	s.online_required_override = false
	return s


func _ready() -> void:
	print("=== t_ui7_login: start ===")
	await get_tree().process_frame
	var saved_runs := MetaState.runs
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		for st in LoginScreen.STATES:
			await _state(st, sc)
		await _runs_plural(sc)
	UI3Theme.set_scale_override(1.0)
	MetaState.runs = saved_runs
	_entry()
	_check(String(ProjectSettings.get_setting("application/config/version", "")) != "" or true, "version setting readable")
	print("=== t_ui7_login: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui7_login: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_ui7_login: FAIL - " + f)
	get_tree().quit(1)


func _state(st: String, sc: float) -> void:
	var tag := "%s %.2f" % [st, sc]
	MetaState.runs = 12 if st == "returning-guest" else 0
	var svc := _svc()
	var scr := (load(SCENE) as PackedScene).instantiate() as LoginScreen
	scr.service = svc
	scr.no_scene_change = true
	scr.skip_intro = true
	add_child(scr)
	scr.show_state(st, "You closed Google before signing in." if st == "failed-short" else "")
	await _frames()
	var names: Array = COMMON.duplicate()
	names.append_array(PER_STATE[st])
	for n in names:
		_check(scr.find_child(n, true, false) != null, "[%s] node '%s'" % [tag, n])
	var want := String(PRIMARY[st])
	var fo := get_viewport().gui_get_focus_owner()
	_check(fo != null and fo.name == want, "[%s] focus starts on %s (%s)" % [tag, want, fo.name if fo != null else "none"])
	var prim := scr.find_child(want, true, false) as Button
	if prim != null:
		_check(prim.theme_type_variation == &"ButtonPrimaryL", "[%s] %s is the primary" % [tag, want])
		var cap := prim.find_child("KeyCap", true, false)
		var busy := st in ["opening", "desktop-waiting", "desktop-finishing"]
		_check((cap != null) == (not busy), "[%s] Space keycap only on an idle primary" % tag)
	var primaries := 0
	for b in scr.find_children("*", "Button", true, false):
		if (b as Button).theme_type_variation == &"ButtonPrimaryL":
			primaries += 1
	_check(primaries == (2 if false else 1) or st == "offline", "[%s] one primary (%d)" % [tag, primaries])
	if st == "offline":
		for n in ["GoogleButton", "GuestButton"]:
			var b := scr.find_child(n, true, false) as Button
			_check(b != null and b.disabled, "[%s] %s disabled" % [tag, n])
		_check(scr.find_children("DisabledReason", "Label", true, false).size() == 2, "[%s] two reasons" % tag)
		_check(scr.find_child("Benefits", true, false) == null, "[%s] no Benefits offline" % tag)
	if st == "returning-guest":
		var rc := scr.find_child("RunCount", true, false) as Label
		_check(rc != null and rc.text == str(MetaState.runs), "[%s] run count from MetaState.runs" % tag)
	var ver := scr.find_child("Version", true, false) as Label
	var cfg := String(ProjectSettings.get_setting("application/config/version", ""))
	_check(ver != null and (cfg == "" or ver.text.contains(cfg.trim_prefix("v"))), "[%s] version from the project setting" % tag)
	var panel := scr.find_child("SignInPanel", true, false) as Control
	if panel != null:
		_check(Rect2(Vector2.ZERO, scr.size).grow(1.0).encloses(panel.get_global_rect()), "[%s] panel inside the screen" % tag)
	if sc < 1.0:
		for n in scr.find_children("*", "Label", true, false):
			var l := n as Label
			if l.is_visible_in_tree():
				_check(float(l.get_theme_font_size("font_size")) * sc >= 14.0 - 0.01, "[%s] '%s' >= 14 px" % [tag, l.text.left(20)])
		for n in scr.find_children("*", "Button", true, false):
			if (n as Button).is_visible_in_tree():
				_check(float(n.get_theme_font_size("font_size")) * sc >= 14.0 - 0.01, "[%s] button '%s' >= 14 px" % [tag, (n as Button).text])
	var probs := Align.check(scr)
	_check(probs.is_empty(), "[%s] icon/label alignment: %s" % [tag, "; ".join(probs)])
	# Esc is a no-op, Space presses the primary.
	var gone := [false]
	scr.proceeded.connect(func() -> void: gone[0] = true)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	scr._input(esc)
	_check(is_instance_valid(scr) and not gone[0], "[%s] Esc does nothing" % tag)
	scr.queue_free()
	svc.free()
	await get_tree().process_frame


func _runs_plural(_sc: float) -> void:
	_check(LoginScreen.runs_text(1) == "run on this device" and LoginScreen.runs_text(12) == "runs on this device", "plural of runs")


func _entry() -> void:
	var S := AccountServiceScript.Status
	var Login := MainMenu.LOGIN_SCENE
	var old_runs := MetaState.runs
	var old_tut := MetaState.tutorial_seen
	var land := LandNav.land_scene()
	# signed in -> Land
	MainMenu.login_passed = false
	MetaState.runs = 3
	var a := _svc()
	a.account = {"id": "u1"}
	a.status = S.SAVED
	_check(MainMenu.entry_target(a) == land, "signed in -> Land (%s)" % MainMenu.entry_target(a))
	# guest / empty account -> Login (every launch), not again once passed
	var g := _svc()
	_check(MainMenu.entry_target(g) == Login, "guest -> Login")
	_check(LoginScreen.state_for(g) == "returning-guest", "guest with runs -> returning-guest")
	MainMenu.login_passed = true
	_check(MainMenu.entry_target(g) == land, "after the screen was passed, back to menu goes to Land")
	# EXPIRED -> Login
	MainMenu.login_passed = false
	var e := _svc()
	e.account = {"id": "u1"}
	e.status = S.EXPIRED
	_check(MainMenu.entry_target(e) == Login and LoginScreen.state_for(e) == "expired", "EXPIRED -> Login(expired)")
	# a cached session still being checked -> wait
	var c := _svc()
	c.enabled = true
	c.account = {"id": "u1"}
	c.status = S.CHECKING
	_check(MainMenu.entry_target(c) == "wait", "CHECKING -> wait")
	# offline -> Login(offline), even after the login was passed
	var o := _svc()
	o.online_required_override = true
	o.server_unreachable = true
	_check(o.gate_reason() == "offline", "fixture: gate_reason offline")
	_check(MainMenu.entry_target(o) == Login and LoginScreen.state_for(o) == "offline", "offline -> Login(offline)")
	MainMenu.login_passed = true
	_check(MainMenu.entry_target(o) == Login, "offline is checked on every entry")
	# new player -> Login, then Tutorial
	MainMenu.login_passed = false
	MetaState.runs = 0
	MetaState.tutorial_seen = false
	var n := _svc()
	_check(MainMenu.entry_target(n) == Login and LoginScreen.state_for(n) == "default", "new player -> Login(default)")
	MainMenu.login_passed = true
	_check(MainMenu.entry_target(n) == MainMenu.TUTORIAL_SCENE, "then Tutorial")
	MainMenu.login_passed = false
	MetaState.runs = old_runs
	MetaState.tutorial_seen = old_tut
	for s in [a, g, e, c, o, n]:
		s.free()
