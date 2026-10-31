class_name SettingsView
extends Control
## M11 Settings (Esc on the hub), Round 3. Spec: design/handoffs/ui-02-round3 README M11, frames M11a-d.
## UI-05 (frames 26-settings*): SectionIndex (settings_index_w) + one column (max settings_col_w), SettingRow settings_row_h, switches print On/Off, sliders 200.
## Every control here is wired to something real: music/sfx/mute (MetaState + CombatAudioDirector),
## reduce flashing (CombatView.flashes_suppressed), replay tutorial, abandon run, account.
## Not drawn, because nothing backs them yet: text size, UI scale, spending presets, hide-Aid, language,
## About. Controls = rebindable keyboard shortcuts (KeyBindings). Gamepad row dropped on purpose (no gamepad). Spending limit shows only the L1 note.
## ABANDON RUN asks twice and is absent (not greyed) when there is no saved run; with a mission stake
## in escrow it warns the stake is lost and settles it (MetaState.settle_mission_stake(false)).
## In-run mode (opened from the combat menu): set `SettingsView.in_run = true` and `return_scene`
## before changing to Settings.tscn; Back reads "Back to run", the Run section goes first.

const Parts := preload("res://scenes/settings/ui5/SettingsParts.gd")

static var in_run: bool = false
static var return_scene: String = ""

var _content: VBoxContainer
var _abandon_status: Label = null
var _sections: Dictionary = {}   # section title -> section plate
var _scroll: ScrollContainer
var _first_focus: Control = null
var _shell: Dictionary = {}
var _tabs: Dictionary = {}   # section title -> IndexRow button
var _capturing: StringName = &""   # action waiting for a key press ("" = none)
var _key_buttons: Dictionary = {}  # action -> KeyButton
var _controls_status: Label = null
var _cur: VBoxContainer = null   # body of the section being built
var _switches: Dictionary = {}   # &"mute" / &"reduce_flash" / &"reduce_motion" -> Ui5Switch
var _sliders: Dictionary = {}    # &"music" / &"sfx" -> Ui5Slider
var abandon_button: Button = null
var abandon_check: CheckBox = null


func _ready() -> void:
	var shell := UI3Meta.build(self, "Settings",
		"Opened from the combat menu. The run is paused." if in_run else "Every toggle states On / Off in words.",
		_on_back)
	_shell = shell
	var back := shell["back"] as Button
	back.name = "BackButton"
	back.tooltip_text = "Back to run · Esc" if in_run else UI3Meta.BACK_HINT
	(shell["sub"] as Control).name = "SubLine"
	(shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	var hr := shell["header_right"] as Control
	hr.get_parent().remove_child(hr)
	hr.queue_free()
	var currencies := find_child("Currencies", true, false)
	if currencies != null:
		currencies.visible = false   # Settings spec: no wallet here

	var order: Array[String] = ["Audio", "Accessibility", "Controls", "Aid and spending", "How to play", "Run", "Account"]
	if in_run:
		order = ["Run", "Audio", "Accessibility", "Controls", "Aid and spending", "How to play", "Account"]

	var body := HBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override("separation", UI3Theme.space("16"))
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	(shell["col"] as Control).add_child(body)
	var idx := Parts.index_plate()
	body.add_child(idx["plate"])

	_content = VBoxContainer.new()
	_content.name = "Column"
	_content.add_theme_constant_override("separation", UI3Theme.space("16"))
	_content.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for sec in order:
		_section(sec)
		match sec:
			"Audio": _build_audio()
			"Accessibility": _build_accessibility()
			"Controls": _build_controls()
			"Aid and spending":
				var r := Parts.row("SettingRow", "Spending limit (monthly)", "Applies when purchases open.")
				var v := Ui5Text.label("—", "text_body", "text_muted")
				(r["h"] as Control).add_child(v)
				_add(r["row"])
			"How to play": _build_tutorial()
			"Run": _build_abandon_section()
			"Account": _build_account_section()

	_build_index(order, idx["rows"] as Control)
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.get_v_scroll_bar().custom_minimum_size.x = 12.0   # visible overflow (t_ui_laws L2)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var wrap := HBoxContainer.new()
	wrap.name = "ColumnWrap"
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(_content)
	_scroll.add_child(wrap)
	body.add_child(_scroll)
	_scroll.resized.connect(_fit_column)
	_fit_column.call_deferred()
	_scroll.get_v_scroll_bar().value_changed.connect(func(_v: float) -> void: _sync_tabs())
	_sync_tabs.call_deferred()
	if _first_focus != null:
		_first_focus.call_deferred("grab_focus")


## The column fills what the scroll leaves, up to settings_col_w.
func _fit_column() -> void:
	if _scroll == null or _content == null:
		return
	var avail := _scroll.size.x - 12.0 - 4.0
	_content.custom_minimum_size.x = minf(avail, float(UI3Theme.size_of("settings_col_w")))


func _on_back() -> void:
	if in_run and return_scene != "":
		var to := return_scene
		in_run = false
		return_scene = ""
		get_tree().change_scene_to_file(to)
		return
	LandNav.back_to_land()


## While an action waits for a key, the next key press is the new binding. Runs before the GUI and the
## Esc-back handler, so Esc cancels the capture instead of leaving the screen.
func _input(ev: InputEvent) -> void:
	if _capturing == &"":
		return
	var k := ev as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	get_viewport().set_input_as_handled()
	var action := _capturing
	if k.keycode == KEY_ESCAPE:
		_end_capture("Cancelled. %s keeps %s." % [_label_of(action), KeyBindings.text_all(action)])
		return
	if not KeyBindings.bindable(int(k.keycode)):
		return   # a bare Shift / Ctrl: keep waiting
	_apply_binding(action, int(k.keycode))


func _label_of(action: StringName) -> String:
	return String(KeyBindings.def_of(action).get("label", action))


## Binds `keycode` to `action`. A key another action in the same group already uses is swapped: that action
## takes this action's old key, so nothing is left unbound. The status line says what happened.
func _apply_binding(action: StringName, keycode: int) -> void:
	var old := KeyBindings.keys_of(action)
	var msg := "%s is now %s." % [_label_of(action), KeyBindings.key_name(keycode)]
	for other in KeyBindings.conflicts(action, keycode):
		var rest: Array = KeyBindings.keys_of(other).filter(func(c: Variant) -> bool: return int(c) != keycode)
		if rest.is_empty():
			rest = [old[0]] if not old.is_empty() else []
		KeyBindings.set_keys(other, rest)
		msg = "%s was on %s. %s is now %s, and %s took %s." % [KeyBindings.key_name(keycode), _label_of(other),
			_label_of(action), KeyBindings.key_name(keycode), _label_of(other), KeyBindings.text_all(other)]
	KeyBindings.set_keys(action, [keycode])
	_save_bindings()
	_end_capture(msg)


func _end_capture(msg: String) -> void:
	_capturing = &""
	for a in _key_buttons:
		var kb := _key_buttons[a] as Button
		kb.text = KeyBindings.text_all(a)
		Parts.set_key_on(kb, false)
	if _controls_status != null:
		_controls_status.text = msg
		_controls_status.visible = msg != ""


func _save_bindings() -> void:
	MetaState.key_bindings = KeyBindings.overrides()
	MetaState.save_to_disk()


func _build_controls() -> void:
	KeyBindings.ensure()
	var hint := Ui5Text.label("Click a shortcut, then press the new key. Esc cancels.", "text_body", "text_muted")
	hint.name = "ControlsHint"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cur.add_child(hint)
	_controls_status = Ui5Text.label("", "text_body", "text_muted")
	_controls_status.name = "ControlsStatus"
	_controls_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_controls_status.visible = false
	_cur.add_child(_controls_status)
	for group in KeyBindings.GROUPS:
		var gl := Parts.group_label(group)
		_cur.add_child(gl, true)
		for d in KeyBindings.DEFS:
			if d["group"] != group:
				continue
			var action: StringName = d["id"]
			var r := Parts.row("ShortcutRow", String(d["label"]))
			var b := Parts.key_button(KeyBindings.text_all(action))
			b.tooltip_text = "Click, then press a key. Esc cancels."
			b.pressed.connect(func() -> void:
				if _capturing != &"":
					_end_capture("")
				_capturing = action
				b.text = "Press a key…"
				Parts.set_key_on(b, true)
				if _controls_status != null:
					_controls_status.text = "Press a key for \"%s\". Esc cancels." % _label_of(action)
					_controls_status.visible = true)
			_key_buttons[action] = b
			(r["h"] as Control).add_child(b)
			_add(r["row"])
	var reset := UI3.button("Reset to defaults", &"secondary", &"M")
	reset.name = "ResetButton"
	reset.pressed.connect(func() -> void:
		KeyBindings.reset_all()
		_save_bindings()
		_end_capture("All shortcuts are back to their defaults."))
	var rr := Parts.row("SettingRow", "Reset shortcuts", "Puts every key back to its default.")
	(rr["h"] as Control).add_child(reset)
	_add(rr["row"])


func _unhandled_key_input(ev: InputEvent) -> void:
	if UI3Meta.esc_back(ev, _shell, _on_back):
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


## SectionIndex: one IndexRow per section; the one at the top of the column shows as selected.
func _build_index(order: Array[String], host: Control) -> void:
	for sec in order:
		var b := Parts.index_row(sec)
		b.pressed.connect(func() -> void:
			var hdr: Control = _sections.get(sec)
			if hdr != null:
				_scroll.scroll_vertical = int(hdr.global_position.y - _content.global_position.y)
			_sync_tabs(sec))
		host.add_child(b, true)
		_tabs[sec] = b


func _sync_tabs(forced := "") -> void:
	if _scroll == null:
		return
	var active := forced
	if active == "":
		var best := -1.0e9
		for sec in _sections:
			var hdr: Control = _sections[sec]
			var y := hdr.global_position.y - _content.global_position.y - float(_scroll.scroll_vertical)
			if y <= 8.0 and y > best:
				best = y
				active = String(sec)
		if active == "" and not _sections.is_empty():
			active = String(_sections.keys()[0])
		var vb := _scroll.get_v_scroll_bar()
		if vb.value >= vb.max_value - vb.page - 1.0 and vb.max_value > vb.page and not _sections.is_empty():
			active = String(_sections.keys()[-1])   # scrolled to the end: the last section is the one in view
	for sec in _tabs:
		Parts.style_index_row(_tabs[sec] as Button, sec == active)


func _build_audio() -> void:
	_slider(&"music", "Music", MetaState.audio_music_volume, func(v: float) -> void:
		MetaState.audio_music_volume = v
		MetaState.save_to_disk()
		_apply_audio())
	_slider(&"sfx", "Sound effects", MetaState.audio_sfx_volume, func(v: float) -> void:
		MetaState.audio_sfx_volume = v
		MetaState.save_to_disk()
		_apply_audio())
	_toggle(&"mute", "Mute everything", "", MetaState.audio_muted, func(on: bool) -> void:
		MetaState.audio_muted = on
		MetaState.save_to_disk()
		_apply_audio())


func _build_accessibility() -> void:
	_toggle(&"reduce_flash", "Reduce flashing and screen shake",
		"Turns off the screen shake on a hit and the colour flash on a resonant Axie. Dice, actions and damage numbers are untouched, because those tell you what happened.",
		MetaState.reduce_flash, func(on: bool) -> void:
			MetaState.reduce_flash = on
			MetaState.save_to_disk())
	_toggle(&"reduce_motion", "Reduce motion", "No shaking, no particles, quicker transitions",
		MetaState.reduce_motion, func(on: bool) -> void:
			MetaState.reduce_motion = on
			MetaState.save_to_disk())
	var r := Parts.row("SettingRow", "Colour-blind-safe glyphs", "Always on: every mechanic colour ships with its glyph and word.")
	(r["h"] as Control).add_child(Ui5Text.label("Always on", "text_body", "text_muted"))
	_add(r["row"])


func _build_tutorial() -> void:
	var btn := UI3.button("Replay the tutorial", &"secondary")
	btn.name = "ReplayButton"
	btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/tutorial/Tutorial.tscn"))
	var r := Parts.row("SettingRow", "Replay tutorial", "One turn end to end: roll, spend, target, end. Replaying it changes nothing you own.")
	(r["h"] as Control).add_child(btn)
	_add(r["row"])


## Pushes the stored levels at the running audio buses immediately, so a slider is audible
## while the player is still holding it rather than after the next scene change.
##
## `CombatAudioDirector.apply_settings()` is static precisely so a settings screen can drive
## the buses with no combat running — its own comment says so. Nothing new was added here.
func _apply_audio() -> void:
	CombatAudioDirector.apply_settings()


func _build_abandon_section() -> void:
	var has_run := RunState.has_saved_run()
	var stake := int(MetaState.mission_escrow.get("stake", 0)) if has_run else 0
	var warn := "No run in progress."
	if has_run:
		warn = ("You will lose your stake (%d Shards). This cannot be undone." % stake) if stake > 0 \
			else "A run is saved. Abandoning it deletes that save. The Axies, Cores and Gene Shard in it are gone, and Gene Shard already banked from finished runs is not affected."
	var btn := UI3.button("Abandon run", &"secondary")
	btn.name = "AbandonButton"
	abandon_button = btn
	var r := Parts.row("SettingRow", "Abandon mission run" if stake > 0 else "Abandon run", warn)
	_add(r["row"])
	if not has_run:
		btn.disabled = true
		btn.tooltip_text = "No run in progress."
		(r["h"] as Control).add_child(btn)
		return
	var cr := Parts.row("ConfirmRow")
	var confirm := Ui5SettingsCheck.new()
	confirm.setup("Yes, I want to abandon the saved run")
	abandon_check = confirm
	(cr["txt"] as Control).add_child(confirm)
	btn.disabled = true
	(cr["h"] as Control).add_child(btn)
	_add(cr["row"])
	confirm.toggled.connect(func(on: bool) -> void:
		btn.disabled = not on
		btn.theme_type_variation = "ButtonDanger" if on else "ButtonSecondary")
	btn.pressed.connect(func() -> void:
		abandon_current_run()
		if in_run:
			# Nothing to go back to: leave in-run mode and head to Land (L1 C3).
			in_run = false
			return_scene = ""
			LandNav.back_to_land()
			return
		btn.disabled = true
		btn.theme_type_variation = "ButtonSecondary"
		confirm.disabled = true
		confirm.button_pressed = false
		if _abandon_status != null:
			_abandon_status.text = "The saved run has been deleted."
			_abandon_status.visible = true)
	_abandon_status = _body("")
	_abandon_status.visible = false


## The abandon steps shared by Settings and the in-run pause menu: settle the mission stake as a loss, close the run
## on the server, delete the save, reset RunState. Callers navigate afterwards.
static func abandon_current_run() -> void:
	if RunState.has_saved_run():
		MetaState.settle_mission_stake(false)   # lane E: abandon = mission loss (no-op without escrow)
	# Online: close the run on the server too, or it stays `open` and the next Begin hits run_open
	# (Liam 15/10). Fire and forget: if this fails (offline), Begin's run_open recovery abandons it later.
	if RemoteEpochSource.flag_on() and RunState.session != null and RunState.session.run_id != "":
		RunState.session.abandon(func(_ok: bool) -> void: pass)
	RunState.clear_saved_run()
	RunState.reset()


## Settings → Account (claude/ACCOUNT_SYSTEM_v1.md §7 C). The only place with Sign out and
## Switch account. Sign out takes two presses: the first says what happens, the second does it.
func _build_account_section() -> void:
	if not AccountService.enabled:
		if SaveStore.is_web() or not AccountService.desktop_enabled_override:
			_signed_out_row("Accounts are available in the web version at axiedice.fun. Progress here stays "
				+ "on this computer.", null)
			return
		# Desktop, signed out: the Account screen (B3) owns the browser flow, waiting and errors.
		var open_acct := _big_primary("Account", "AccountButton")
		open_acct.pressed.connect(func() -> void: LandNav.open(&"account"))
		_signed_out_row("You're signed out. You can browse and play the tutorial; runs need an account. Progress stays on this computer. Sign in with Google to "
			+ "keep it on every device.", open_acct)
		return
	if not AccountService.is_signed_in():
		var sign_in := _big_primary("Continue with Google", "SignInButton")
		sign_in.pressed.connect(func() -> void:
			if SaveStore.is_web():
				AccountService.sign_in()
			else:
				LandNav.open(&"account"))
		_signed_out_row("You're signed out. You can browse and play the tutorial; runs need an account. Progress stays on this browser only. Sign in with "
			+ "Google to keep it on every device. Your Sky Mavis work account works too.", sign_in)
		return

	if AccountService.status == AccountServiceScript.Status.EXPIRED:
		# Frame 26-settings--account-expired: notice + Sign in, nothing else.
		var er := Parts.row("ExpiredRow")
		(er["h"] as HBoxContainer).add_child(Ui5ToneDisc.make(&"error"))
		(er["h"] as HBoxContainer).move_child((er["h"] as HBoxContainer).get_child(-1), 0)
		var el := Ui5Text.label("Your session expired. Sign in again to keep saving. Your progress is safe on this device.", "text_body", "text")
		el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(er["txt"] as Control).add_child(el)
		var again := _big_primary("Sign in", "SignInButton")
		again.pressed.connect(func() -> void:
			if SaveStore.is_web():
				AccountService.sign_in()
			else:
				LandNav.open(&"account"))
		(er["h"] as Control).add_child(again)
		_add(er["row"])
		return

	var who := Parts.row("AccountRow")
	var h := who["h"] as HBoxContainer
	var name_text := AccountService.display_name()
	h.add_child(Parts.avatar(name_text))
	h.move_child(h.get_child(-1), 0)
	var nm := HBoxContainer.new()
	nm.add_theme_constant_override("separation", UI3Theme.space("8"))
	var name_lbl := Ui5Text.label(name_text, "text_body", "text", true)
	nm.add_child(name_lbl)
	if bool(AccountService.account.get("sky_mavis", false)):
		nm.add_child(AccountUI.sky_mavis_badge())
	(who["txt"] as Control).add_child(nm)
	(who["txt"] as Control).add_child(Ui5Text.label("%s · Google" % String(AccountService.account.get("email", "")), "text_body", "text_muted"))
	var status_lbl := Ui5Text.label("", "text_body", "text_muted")
	status_lbl.name = "CloudStatus"
	h.add_child(status_lbl)
	_add(who["row"])
	var refresh := func() -> void:
		var line: Array = AccountUI.status_line(AccountService)
		var text: String = "Cloud save: " + String(line[0])
		if AccountService.status == AccountServiceScript.Status.SAVED and AccountService.last_synced > 0:
			text = "Cloud save: Saved " + AccountUI.ago(AccountService.last_synced)
		status_lbl.text = text
	refresh.call()
	AccountService.changed.connect(refresh)
	tree_exiting.connect(func() -> void:
		if AccountService.changed.is_connected(refresh):
			AccountService.changed.disconnect(refresh))

	var confirm_lbl := Ui5Text.label("", "text_body", "text_muted")
	confirm_lbl.name = "SignOutNote"
	confirm_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_lbl.visible = false
	_cur.add_child(confirm_lbl)
	var br := Parts.row("ButtonRow")
	var bh := br["h"] as HBoxContainer
	(br["txt"] as Control).queue_free()
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(sp)
	var switch_btn := UI3.button("Switch account", &"secondary", &"S")
	switch_btn.name = "SwitchButton"
	switch_btn.pressed.connect(func() -> void: AccountService.sign_in(true))
	bh.add_child(switch_btn)
	var out_btn := UI3.button("Sign out", &"secondary", &"S")
	out_btn.name = "SignOutButton"
	bh.add_child(out_btn)
	_add(br["row"])
	var armed := [false]
	out_btn.pressed.connect(func() -> void:
		if not armed[0]:
			armed[0] = true
			var unsynced: bool = AccountService.has_unsynced_changes()
			out_btn.text = "Sync and sign out" if unsynced else "Confirm sign out"
			out_btn.theme_type_variation = "ButtonDanger"
			confirm_lbl.text = "You will need to sign in again to start a run. Your progress stays saved." if not unsynced \
				else "Your latest progress uploads first, then you are signed out."
			confirm_lbl.visible = true
			return
		out_btn.disabled = true
		switch_btn.disabled = true
		AccountService.sign_out())


func _big_primary(text: String, node_name: String) -> Button:
	var b := UI3.button(text, &"primary")
	b.name = node_name
	b.add_theme_font_size_override("font_size", UI3Theme.size_of("text_title"))
	return b


func _signed_out_row(text: String, btn: Button) -> void:
	var r := Parts.row("SignedOutRow")
	var l := Ui5Text.label(text, "text_body", "text")
	l.name = "Body"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(r["txt"] as Control).add_child(l)
	if btn != null:
		(r["h"] as Control).add_child(btn)
	_add(r["row"])


# --- small builders ---------------------------------------------------------

func _section(title: String) -> void:
	var sec := Parts.section(title)
	_content.add_child(sec["plate"])
	_cur = sec["body"]
	_sections[title] = sec["plate"]


func _add(c: Control) -> void:
	_cur.add_child(c, true)


## Plain info text under a row group (transient status lines).
func _body(text: String) -> Label:
	var lbl := Ui5Text.label(text, "text_body", "text_muted")
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cur.add_child(lbl)
	return lbl


## A switch row: label (+ description) on the left, "On" / "Off" word and Ui5Switch on the right.
func _toggle(id: StringName, label: String, desc: String, pressed: bool, on_toggle: Callable) -> void:
	var r := Parts.row("SettingRow", label, desc)
	var c := Parts.switch_cell(pressed)
	var sw := c["switch"] as Ui5Switch
	sw.toggled.connect(func(on: bool) -> void: on_toggle.call(on))
	(r["h"] as Control).add_child(c["cell"])
	_add(r["row"])
	_switches[id] = sw


## A slider with its value on screen.
func _slider(id: StringName, label: String, value: float, on_change: Callable) -> void:
	var r := Parts.row("SettingRow", label)
	var c := Parts.slider_cell(value)
	var sl := c["slider"] as Ui5Slider
	sl.value_changed.connect(func(v: float) -> void: on_change.call(v))
	(r["h"] as Control).add_child(c["cell"])
	_add(r["row"])
	_sliders[id] = sl
