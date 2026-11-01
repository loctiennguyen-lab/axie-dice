class_name LoginScreen
extends Control
## UI-07 sign-in screen. Shown by MainMenu at every game start while nobody is signed in (or the session expired),
## before the Tutorial. Source: design/handoffs/ui-07-login/round-1/_zip/ui07 (README, ui07-login.html, motion-ui07.md).
## It only reads AccountService (status, account, gate_reason, desktop_phase) and calls sign_in / play_as_guest / check.
## The desktop browser modal (a09-a12) is drawn by the service itself on top of this screen.
## States: default, opening, desktop-waiting, desktop-finishing, failed, offline, expired, returning-guest.
## ("failed-short" is `failed` with a short reason.) A Button's text is the frame's ButtonLabel.

const Parts := preload("res://scenes/account/ui5/AccountParts.gd")
const PanelParts := preload("res://scenes/shared/ui5/PanelParts.gd")
const SpaceCap := preload("res://scenes/shared/ui5/SpaceCap.gd")
const BG_1920 := "res://assets/ui7/bg_login_1920.png"
const BG_1280 := "res://assets/ui7/bg_login_1280.png"
const LOGO := "res://assets/ui7/logo_axiedice.png"
const G_MARK := "res://assets/ui7/google_g.svg"
const STATES: Array[String] = ["default", "opening", "desktop-waiting", "desktop-finishing", "failed", "failed-short",
	"offline", "expired", "returning-guest"]
const TAGLINE := "Build your team and destroy everything"
const GUEST_LINE := "Guest plays the tutorial and normal runs. No ranked, no Missions, and nothing is saved to the cloud."

## Emitted instead of changing scene when `no_scene_change` is set (tests, capture).
signal proceeded

var service: Node = null
var no_scene_change := false
var skip_intro := false
var state := "default"
var _fail_text := ""
var _opening := false
var _panel: PanelContainer
var _col: VBoxContainer
var _primary: Button
var _intro: Tween
var _intro_nodes: Array = []
var _owns_toast := false


## The state the service says we are in (transient flags `opening` / failed are the screen's own).
static func state_for(svc: Node) -> String:
	if svc.gate_reason() != "":
		return "offline"
	var phase := String(svc.get("desktop_phase"))
	if phase == "waiting":
		return "desktop-waiting"
	if phase == "finishing":
		return "desktop-finishing"
	if int(svc.get("status")) == AccountServiceScript.Status.EXPIRED and svc.account.is_empty() == false \
			and phase != "signed_in":
		return "expired"
	return "returning-guest" if MetaState.runs > 0 else "default"


static func runs_text(n: int) -> String:
	return "run on this device" if n == 1 else "runs on this device"


func _ready() -> void:
	theme = UI3Theme.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if service == null:
		service = AccountService
	mouse_filter = Control.MOUSE_FILTER_STOP
	if service.has_signal("changed"):
		service.changed.connect(_on_changed)
	if service == AccountService:
		_owns_toast = true
		service.toast = _on_toast
	state = state_for(service)
	_build()
	if service == AccountService:
		service.show_pending_error()
	if not skip_intro:
		_play_intro.call_deferred()


func _exit_tree() -> void:
	if is_instance_valid(service) and service.has_signal("changed") and service.changed.is_connected(_on_changed):
		service.changed.disconnect(_on_changed)
	if _owns_toast and is_instance_valid(service):
		service.toast = Callable(service, "_toast_with_ui")


## Show a state by name (capture + tests). `reason` only matters for failed.
func show_state(s: String, reason := "") -> void:
	_opening = s == "opening"
	if s == "failed-short":
		_fail_text = reason if reason != "" else "You closed Google before signing in."
	elif s == "failed":
		_fail_text = reason if reason != "" else "Sign-in didn't work. Try again."
	else:
		_fail_text = ""
	state = s
	_build()


func _on_toast(code: String) -> void:
	if code == "session_expired" or code == "save_failed" or code == "sign_out_failed":
		return
	_fail_text = AccountService.error_message(code)
	_opening = false
	_refresh()


func _on_changed() -> void:
	if _check_proceed():
		return
	if String(service.get("desktop_phase")) == "error":
		var copy: Array = AccountScreen.error_copy(String(service.get("desktop_error")))
		_fail_text = String(copy[1])
	# The service shows its own toast on a failure; the status box already says it.
	if service == AccountService:
		var layer: CanvasLayer = service._ui_layer()
		for c in layer.get_children():
			if c.name == "AccountToastHost":
				c.queue_free()
	_refresh()


func _refresh() -> void:
	var s := state_for(service)
	if s in ["default", "returning-guest"]:
		if _fail_text != "":
			s = "failed"
		elif _opening:
			s = "opening"
	_opening = _opening and s == "opening"
	state = s
	_build()


## True once the player may leave: signed in (not expired), cloud save settled, server reachable.
func _check_proceed() -> bool:
	if not MainMenu.login_needed(service) and service.gate_reason() == "" and not bool(service.get("reconciling")):
		_proceed()
		return true
	return false


func _proceed() -> void:
	MainMenu.login_passed = true
	proceeded.emit()
	if not no_scene_change and is_inside_tree():
		get_tree().change_scene_to_file.call_deferred(AccountService.MAIN_MENU)


# ============================================================================ build

func _small() -> bool:
	return UI3Theme.layout_scale() < 0.99


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_primary = null
	_intro_nodes.clear()
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.texture = load(BG_1280 if _small() else BG_1920)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_intro_nodes.append(["bg", bg])
	_build_brand()
	_build_panel()
	_focus_primary.call_deferred(_primary)


func _focus_primary(b: Button) -> void:
	if is_instance_valid(b) and b.is_inside_tree() and not b.disabled:
		b.grab_focus()


func _edge() -> int:
	return 60 if _small() else UI3Theme.space("40") * 4


func _build_brand() -> void:
	var w := UI3Theme.size_of("login_logo_w")
	var brand := VBoxContainer.new()
	brand.name = "Brand"
	brand.add_theme_constant_override("separation", UI3Theme.space("16"))
	brand.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	brand.offset_left = _edge()
	brand.offset_right = _edge() + w
	brand.grow_vertical = Control.GROW_DIRECTION_BOTH
	brand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(brand)
	var tex := load(LOGO) as Texture2D
	var slot := Control.new()
	slot.name = "LogoSlot"
	slot.custom_minimum_size = Vector2(w, w * float(tex.get_height()) / float(tex.get_width()))
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand.add_child(slot)
	var logo := TextureRect.new()
	logo.name = "Logo"
	logo.texture = tex
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(logo)
	var tag := Ui5Text.label(TAGLINE, "text_title", "text_on_viewport", true)
	tag.name = "Tagline"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.add_theme_color_override("font_shadow_color", UI3Theme.color("text_shadow"))
	tag.add_theme_constant_override("shadow_offset_y", 2)
	brand.add_child(tag)
	# TODO(UI-07): the 5 class Axies as live 3D models go in this frame (they are placed later). Left empty on purpose.
	var frame := Control.new()
	frame.name = "Axie3DFrame"
	frame.custom_minimum_size = Vector2(0, UI3Theme.size_of("login_axie_h"))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand.add_child(frame)
	_intro_nodes.append(["logo", logo])
	_intro_nodes.append(["tagline", tag])
	_intro_nodes.append(["axie", frame])


func _build_panel() -> void:
	var pad := 48 if _small() else UI3Theme.space("40")
	var st := UI3Theme.flat(UI3Theme.color("plate"), UI3Theme.radius("xl"), UI3Theme.stroke("rim"), UI3Theme.color("plate_rim"),
		Vector4(pad, pad, pad, pad), PanelParts.lip(UI3Theme.color("plate_ink")))
	_panel = PanelParts.panel(st, "SignInPanel")
	var w := UI3Theme.size_of("login_panel_w")
	_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_panel.offset_right = -_edge()
	_panel.offset_left = -_edge() - w
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 24 if _small() else UI3Theme.space("20"))
	_panel.add_child(_col)
	_intro_nodes.append(["panel", _panel])

	var tag := UI3Meta.tag("SKY MAVIS")
	tag.name = "SkyMavisTag"
	tag.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_col.add_child(tag)
	var head := VBoxContainer.new()
	head.name = "Heading"
	head.add_theme_constant_override("separation", UI3Theme.space("4"))
	var title := Ui5Text.label("Save your progress", "text_banner", "text", true)
	title.name = "Title"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(title)
	head.add_child(Parts.body("Sign in with Google to keep your Axies, Shards and runs on any device. "
		+ "Your Sky Mavis work account works too. No new registration needed.", false, "Body"))
	_col.add_child(head)

	var kind := _status_kind()
	if kind != "":
		_col.add_child(_status_box(kind))
	if state != "offline":
		_col.add_child(_benefits())
	_col.add_child(_actions())
	_col.add_child(_footer())


func _status_kind() -> String:
	match state:
		"failed", "failed-short":
			return "danger"
		"offline":
			return "warn"
		"expired":
			return "info"
	return ""


func _status_box(kind: String) -> PanelContainer:
	var bg := UI3Theme.color("danger_bg") if kind == "danger" else UI3Theme.color("plate_raised")
	var rim := UI3Theme.color("danger_rim") if kind == "danger" else \
		(UI3Theme.color("accent") if kind == "warn" else UI3Theme.color("plate_rim"))
	var st := UI3Theme.flat(bg, UI3Theme.radius("m"), UI3Theme.stroke("rim"), rim,
		Vector4(UI3Theme.space("16"), UI3Theme.space("16"), UI3Theme.space("16"), UI3Theme.space("16")))
	var p := PanelParts.panel(st, "StatusBox")
	p.set_meta("kind", kind)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("12"))
	p.add_child(row)
	var disc := Ui5ToneDisc.make(&"error" if kind == "danger" else (&"warn" if kind == "warn" else &"info"), "StatusIcon")
	disc.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(disc)
	var col := VBoxContainer.new()
	col.name = "StatusText"
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", UI3Theme.space("4"))
	row.add_child(col)
	var body := ""
	match state:
		"failed", "failed-short":
			var t := Ui5Text.label("Sign-in didn't finish", "text_body", "text", true)
			t.name = "StatusTitle"
			col.add_child(t)
			body = _fail_text
		"offline":
			var t := Ui5Text.label("Can't reach the game server", "text_body", "text", true)
			t.name = "StatusTitle"
			col.add_child(t)
			body = "Axie Dice needs an internet connection for every mode. Check your connection and try again. " \
				+ "Nothing is lost: your progress is kept on the server."
		"expired":
			body = "Your session expired. Sign in again. Your progress on this device is safe."
	col.add_child(Parts.body(body, false, "StatusBody"))
	return p


func _benefits() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Benefits"
	row.add_theme_constant_override("separation", UI3Theme.space("12"))
	for b in [["Vault", "your imported Axies"], ["Shards & Pass", "every unlock you earned"],
			["Continue", "pick up a run on another device"]]:
		var p := PanelParts.panel(PanelParts.cell_box(UI3Theme.space("12" if _small() else "16"), UI3Theme.space("16"), "m"), "Benefit")
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.custom_minimum_size.y = UI3Theme.size_of("benefit_h")
		var c := VBoxContainer.new()
		c.add_theme_constant_override("separation", UI3Theme.space("4"))
		p.add_child(c)
		var l := Ui5Text.label(b[0], "text_body", "text", true)
		l.name = "BenefitTitle"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		c.add_child(l)
		c.add_child(Parts.body(b[1], true, "BenefitText"))
		row.add_child(p)
	return row


func _actions() -> VBoxContainer:
	var a := VBoxContainer.new()
	a.name = "Actions"
	a.add_theme_constant_override("separation", UI3Theme.space("12"))
	match state:
		"offline":
			_primary = _big_button("TryAgainButton", "Try again", true)
			_primary.pressed.connect(func() -> void: service.check())
			a.add_child(_primary)
			var g := _group("GoogleButtonGroup")
			var gb := _big_button("GoogleButton", "Continue with Google", false)
			gb.disabled = true
			g.add_child(gb)
			g.add_child(_reason("Sign-in needs the game server."))
			a.add_child(g)
			var gg := _group("GuestButtonGroup")
			var guest := _guest_button("Play as guest")
			guest.disabled = true
			gg.add_child(guest)
			gg.add_child(_reason("Guest play needs the game server too."))
			a.add_child(gg)
		"failed", "failed-short":
			_primary = _big_button("TryAgainButton", "Try again", true)
			_primary.pressed.connect(_on_google)
			a.add_child(_primary)
			a.add_child(_guest_block("Play as guest", GUEST_LINE))
		_:
			var busy := state in ["opening", "desktop-waiting", "desktop-finishing"]
			var label := "Continue with Google"
			if state == "opening":
				label = "Opening Google…"
			elif busy:
				label = "Waiting for the browser…"
			_primary = _big_button("GoogleButton", label, not busy)
			if busy:
				var sp := Ui5Spinner.new()
				sp.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
				sp.grow_horizontal = Control.GROW_DIRECTION_BEGIN
				sp.grow_vertical = Control.GROW_DIRECTION_BOTH
				sp.offset_right = -UI3Theme.space("16")
				_primary.add_child(sp)
			_primary.pressed.connect(_on_google)
			a.add_child(_primary)
			if state == "expired":
				a.add_child(_guest_block("Keep playing without cloud save", "Your progress stays on this device until you sign in."))
			else:
				var hint := Parts.body("No Google account? You can create one on the next screen.", true, "NoAccountLine")
				hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				a.add_child(hint)
				a.add_child(_guest_block("Play as guest", GUEST_LINE))
	return a


func _group(n: String) -> VBoxContainer:
	var g := VBoxContainer.new()
	g.name = n
	g.add_theme_constant_override("separation", UI3Theme.space("4"))
	return g


func _reason(t: String) -> Label:
	var l := Parts.body(t, true, "DisabledReason")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Primary L button with the white Google disc on the left and (when `cap`) the Space keycap on the right.
func _big_button(n: String, text: String, cap: bool) -> Button:
	var b := Parts.btn(n, text, &"primary", &"L", true)
	b.set_meta("align_not_icon", true)   # a button is not an icon the hint line under it centres on
	var d := UI3Theme.size_of("google_chip")
	var mark := PanelContainer.new()
	mark.name = "GoogleMark"
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.add_theme_stylebox_override("panel", UI3Theme.flat(UI3Theme.color("google_chip"), UI3Theme.radius("pill")))
	mark.custom_minimum_size = Vector2(d, d)
	mark.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	mark.grow_vertical = Control.GROW_DIRECTION_BOTH
	mark.offset_left = UI3Theme.space("16")
	mark.offset_right = UI3Theme.space("16") + d
	var g := TextureRect.new()
	g.name = "GoogleG"
	g.texture = load(G_MARK)
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	g.custom_minimum_size = Vector2.ONE * int(d * 0.6)
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.add_child(g)
	b.add_child(mark)
	if cap:
		SpaceCap.attach(b, UI3Theme.space("32"))
	return b


func _guest_button(text: String) -> Button:
	var g := UI3.button(text, &"quiet", &"S")
	g.name = "GuestButton"
	g.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	g.pressed.connect(_on_guest)
	return g


func _guest_block(button_text: String, line: String) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.name = "GuestBlock"
	b.add_theme_constant_override("separation", UI3Theme.space("4"))
	b.add_child(_guest_button(button_text))
	var l := Parts.body(line, true, "GuestLine")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(l)
	if state == "returning-guest":
		var row := HBoxContainer.new()
		row.name = "GuestRuns"
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", UI3Theme.space("4"))
		var n := Ui5Text.label(str(MetaState.runs), "text_body", "text", true)
		n.name = "RunCount"
		row.add_child(n)
		var t := Ui5Text.label(runs_text(MetaState.runs), "text_body", "text_muted")
		t.name = "RunsText"
		row.add_child(t)
		b.add_child(row)
	return b


func _footer() -> HBoxContainer:
	var f := HBoxContainer.new()
	f.name = "Footer"
	var links := HBoxContainer.new()
	links.name = "LegalLinks"
	links.add_theme_constant_override("separation", UI3Theme.space("4"))
	for item in [["TermsLink", "Terms", "/terms"], ["", "·", ""], ["PrivacyLink", "Privacy", "/privacy"]]:
		if item[0] == "":
			var s := Ui5Text.label("·", "text_body", "text_muted")
			s.name = "Separator"
			links.add_child(s)
			continue
		var b := UI3.button(item[1], &"quiet", &"S")
		b.name = item[0]
		var path: String = item[2]
		b.pressed.connect(func() -> void: _open_legal(path))
		links.add_child(b)
	f.add_child(links)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.add_child(spacer)
	var v := Ui5Text.label(Parts.version_text(), "text_body", "text_muted")
	v.name = "Version"
	f.add_child(v)
	return f


func _open_legal(path: String) -> void:
	var url := String(ProjectSettings.get_setting("axie/server_url", "https://axiedice.fun")) + path
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.open('%s','_blank')" % path)
	else:
		OS.shell_open(url)


# ============================================================================ actions + input

func _on_google() -> void:
	if state in ["opening", "desktop-waiting", "desktop-finishing"]:
		return
	_fail_text = ""
	if SaveStore.is_web():
		_opening = true
		state = "opening"
		_build()
	service.sign_in()


func _on_guest() -> void:
	if state == "offline":
		return
	if state != "expired":
		service.play_as_guest()
	_proceed()


func _input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.pressed or ev.echo:
		return
	var phase := String(service.get("desktop_phase"))
	if phase in ["waiting", "finishing", "signed_in", "error"] and state.begins_with("desktop"):
		return   # the modal owns the keyboard
	if ev.is_action_pressed(&"menu_back"):
		get_viewport().set_input_as_handled()   # nowhere to go back to
	elif (ev as InputEventKey).keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		if _primary != null and not _primary.disabled:
			_primary.pressed.emit()


# ============================================================================ intro (motion-ui07.md)

func _play_intro() -> void:
	if not is_inside_tree():
		return
	var reduced := UI3Motion.reduced()
	_intro = create_tween().set_parallel(true)
	var half := 0.5 if reduced else 1.0
	for e in _intro_nodes:
		var n: Control = e[1]
		if not is_instance_valid(n):
			continue
		n.modulate.a = 0.0
		var start := 0.0
		var dur := 0.12
		match e[0]:
			"bg":
				start = 0.0
				dur = 0.24
			"logo":
				start = 0.12 * half
				dur = 0.12 if reduced else 0.48
				if not reduced:
					n.position.y = -32.0
					n.pivot_offset = n.size * 0.5
					n.scale = Vector2.ONE * 1.06
					_intro.tween_property(n, "position:y", 0.0, dur).set_delay(start).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					_intro.tween_property(n, "scale", Vector2.ONE, dur).set_delay(start).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			"tagline", "axie":
				start = 0.42 * half
				dur = 0.12 if reduced else 0.2
			"panel":
				start = 0.3 * half
				dur = 0.12 if reduced else 0.36
				if not reduced:
					var y0 := n.position.y
					n.position.y = y0 + 48.0
					_intro.tween_property(n, "position:y", y0, dur).set_delay(start).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		var tw := _intro.tween_property(n, "modulate:a", 1.0, dur).set_delay(start)
		if e[0] == "bg":
			tw.set_trans(Tween.TRANS_LINEAR)
		else:
			tw.set_trans(Tween.TRANS_BACK if e[0] == "logo" and not reduced else Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_intro.finished.connect(func() -> void: _intro = null)
