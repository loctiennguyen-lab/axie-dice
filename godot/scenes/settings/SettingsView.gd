class_name SettingsView
extends Control
## M11 Settings (Esc on the hub), Round 3. Spec: design/handoffs/ui-02-round3 README M11, frames M11a-d.
## Section index (260) + one column (max 960), rows >= 56, toggles print On/Off, sliders 300.
## Every control here is wired to something real: music/sfx/mute (MetaState + CombatAudioDirector),
## reduce flashing (CombatView.flashes_suppressed), replay tutorial, abandon run, account.
## Not drawn, because nothing backs them yet: text size, UI scale, spending presets, hide-Aid, language,
## About. Controls = rebindable keyboard shortcuts (KeyBindings). Gamepad row dropped on purpose (no gamepad). Spending limit shows only the L1 note.
## ABANDON RUN asks twice and is absent (not greyed) when there is no saved run; with a mission stake
## in escrow it warns the stake is lost and settles it (MetaState.settle_mission_stake(false)).
## In-run mode (opened from the combat menu): set `SettingsView.in_run = true` and `return_scene`
## before changing to Settings.tscn; Back reads "Back to run", the Run section goes first.

const BG_TEXTURE := "res://assets/backgrounds/origins/scene/4-entrance.jpg"
const INDEX_W := 260.0
const COL_MAX := 960.0
const ROW_MIN := 72.0   # components.md: Slider / Toggle rows 72 high

static var in_run: bool = false
static var return_scene: String = ""

var _content: VBoxContainer
var _abandon_status: Label = null
var _sections: Dictionary = {}   # name -> header Label
var _scroll: ScrollContainer
var _first_focus: Control = null
var _shell: Dictionary = {}
var _tabs: Dictionary = {}   # section name -> tab Button
var _capturing: StringName = &""   # action waiting for a key press ("" = none)
var _key_buttons: Dictionary = {}  # action -> Button showing its keys
var _controls_status: Label = null


func _ready() -> void:
	# UI-03 26-settings on the UI3Meta shell: header (title plate with back, tabs), then the scrolling column.
	var shell := UI3Meta.build(self, "Settings",
		"Opened from the combat menu. The run is paused." if in_run else "Every toggle states On / Off in words.",
		_on_back)
	_shell = shell
	var back := shell["back"] as Button
	back.name = "BackButton"
	back.tooltip_text = "Back to run · Esc" if in_run else UI3Meta.BACK_HINT
	(shell["panel"] as Control).name = "PlateHost"   # t_ui_laws L0
	var currencies := find_child("Currencies", true, false)
	if currencies != null:
		currencies.visible = false   # Settings spec: no wallet here

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 16)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var order: Array[String] = ["Audio", "Accessibility", "Controls", "Aid and spending", "How to play", "Run", "Account"]
	if in_run:
		order = ["Run", "Audio", "Accessibility", "Controls", "Aid and spending", "How to play", "Account"]
	for sec in order:
		_section(sec)
		match sec:
			"Audio": _build_audio()
			"Accessibility": _build_accessibility()
			"Aid and spending":
				_row("Spending limit (monthly)", "Applies when purchases open.")
			"How to play": _build_tutorial()
			"Run": _build_abandon_section()
			"Account": _build_account_section()

	_build_index(order, shell["header_right"] as Control)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.get_v_scroll_bar().custom_minimum_size.x = 12.0   # visible overflow (t_ui_laws L2)
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.custom_minimum_size.x = COL_MAX
	center.add_child(_content)
	_scroll.add_child(center)
	(shell["col"] as Control).add_child(_scroll)
	_scroll.get_v_scroll_bar().value_changed.connect(func(_v: float) -> void: _sync_tabs())
	_sync_tabs.call_deferred()
	if _first_focus != null:
		_first_focus.call_deferred("grab_focus")


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
		(_key_buttons[a] as Button).text = KeyBindings.text_all(a)
	if _controls_status != null:
		_controls_status.text = msg


func _save_bindings() -> void:
	MetaState.key_bindings = KeyBindings.overrides()
	MetaState.save_to_disk()


func _build_controls() -> void:
	KeyBindings.ensure()
	_controls_status = _body("Click a shortcut, then press the new key. Esc cancels.")
	_controls_status.name = "ControlsStatus"
	for group in KeyBindings.GROUPS:
		var title := UI3.label(group, "LabelDisplay")
		title.name = "ControlsGroup_" + group
		_content.add_child(title)
		for d in KeyBindings.DEFS:
			if d["group"] != group:
				continue
			var action: StringName = d["id"]
			var b := UI3.button(KeyBindings.text_all(action), &"secondary", &"M")
			b.name = "Key_" + String(action)
			b.custom_minimum_size = Vector2(220, 56)
			b.tooltip_text = "Click, then press a key. Esc cancels."
			b.pressed.connect(func() -> void:
				if _capturing != &"":
					_end_capture("")
				_capturing = action
				b.text = "Press a key..."
				if _controls_status != null:
					_controls_status.text = "Press a key for \"%s\". Esc cancels." % _label_of(action))
			_key_buttons[action] = b
			_row(String(d["label"]), "", b)
	var reset := UI3.button("Reset to defaults", &"secondary", &"M")
	reset.name = "ResetKeysButton"
	reset.pressed.connect(func() -> void:
		KeyBindings.reset_all()
		_save_bindings()
		_end_capture("All shortcuts are back to their defaults."))
	_row("Reset shortcuts", "Puts every key back to its default.", reset)


func _unhandled_key_input(ev: InputEvent) -> void:
	if UI3Meta.esc_back(ev, _shell, _on_back):
		if is_inside_tree():   # a handler above may have changed scene
			get_viewport().set_input_as_handled()


## Section tabs in the header: the one whose section is at the top of the column shows as selected.
func _build_index(order: Array[String], host: Control) -> void:
	for sec in order:
		var b := UI3Meta.tab(sec, false)
		b.name = "Index_" + sec.replace(" ", "")
		b.pressed.connect(func() -> void:
			var hdr: Control = _sections.get(sec)
			if hdr != null:
				_scroll.scroll_vertical = int(hdr.global_position.y - _content.global_position.y)
			_sync_tabs(sec))
		host.add_child(b)
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
	for sec in _tabs:
		(_tabs[sec] as Button).set_pressed_no_signal(sec == active)


func _build_audio() -> void:
	_slider("Music", MetaState.audio_music_volume, func(v: float) -> void:
		MetaState.audio_music_volume = v
		MetaState.save_to_disk()
		_apply_audio())
	_slider("Sound effects", MetaState.audio_sfx_volume, func(v: float) -> void:
		MetaState.audio_sfx_volume = v
		MetaState.save_to_disk()
		_apply_audio())
	_toggle("Mute everything", "", MetaState.audio_muted, func(on: bool) -> void:
		MetaState.audio_muted = on
		MetaState.save_to_disk()
		_apply_audio())


func _build_accessibility() -> void:
	_toggle("Reduce flashing and screen shake",
		"Turns off the screen shake on a hit and the colour flash on a resonant Axie. Dice, actions and damage numbers are untouched, because those tell you what happened.",
		MetaState.reduce_flash, func(on: bool) -> void:
			MetaState.reduce_flash = on
			MetaState.save_to_disk())
	_row("Colour-blind-safe glyphs", "Always on: every mechanic colour ships with its glyph and word.")


func _build_tutorial() -> void:
	var btn := UI3.button("Replay the tutorial", &"secondary")
	btn.name = "ReplayTutorialButton"
	btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/tutorial/Tutorial.tscn"))
	_row("Replay tutorial", "One turn end to end: roll, spend, target, end. Replaying it changes nothing you own.", btn)


## Pushes the stored levels at the running audio buses immediately, so a slider is audible
## while the player is still holding it rather than after the next scene change.
##
## `CombatAudioDirector.apply_settings()` is static precisely so a settings screen can drive
## the buses with no combat running — its own comment says so. Nothing new was added here.
func _apply_audio() -> void:
	CombatAudioDirector.apply_settings()


func _build_abandon_section() -> void:
	if not RunState.has_saved_run():
		_row("Abandon run", "No run in progress.")
		return
	var stake := int(MetaState.mission_escrow.get("stake", 0))
	var warn := ("You will lose your stake (%d Shard). This cannot be undone." % stake) if stake > 0 \
		else "A run is saved. Abandoning it deletes that save. The Axies, relics and Gene Shard in it are gone, and Gene Shard already banked from finished runs is not affected."
	var confirm := CheckBox.new()
	confirm.name = "ConfirmAbandonCheck"
	confirm.text = "Yes, I want to abandon the saved run"
	var btn := UI3.button("Abandon run", &"danger")
	btn.disabled = true

	confirm.toggled.connect(func(on: bool) -> void:
		btn.disabled = not on)
	btn.pressed.connect(func() -> void:
		abandon_current_run()
		if in_run:
			# Nothing to go back to: leave in-run mode and head to Land (L1 C3).
			in_run = false
			return_scene = ""
			LandNav.back_to_land()
			return
		btn.disabled = true
		confirm.disabled = true
		confirm.button_pressed = false
		if _abandon_status != null:
			_abandon_status.text = "The saved run has been deleted."
			_abandon_status.visible = true)
	# Stacked, not side by side: next to a long description a wide checkbox row squeezed it and clipped it.
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.add_child(confirm)
	box.add_child(btn)
	_row("Abandon mission run" if stake > 0 else "Abandon run", warn, box)
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
			_body("Accounts are available in the web version at axiedice.fun. Progress here stays "
				+ "on this computer.")
			return
		# Desktop, signed out: the Account screen (B3) owns the browser flow, waiting and errors.
		_body("You're signed out. You can browse and play the tutorial; runs need an account. Progress stays on this computer. Sign in with Google to "
			+ "keep it on every device.")
		var open_acct := UI3.button("Account", &"primary")
		open_acct.name = "OpenAccountButton"
		open_acct.pressed.connect(func() -> void: LandNav.open(&"account"))
		_content.add_child(open_acct)
		return
	if not AccountService.is_signed_in():
		_body("You're signed out. You can browse and play the tutorial; runs need an account. Progress stays on this browser only. Sign in with "
			+ "Google to keep it on every device. Your Sky Mavis work account works too.")
		var sign_in := UI3.button("Continue with Google", &"primary")
		sign_in.name = "SignInButton"
		sign_in.pressed.connect(func() -> void:
			if SaveStore.is_web():
				AccountService.sign_in()
			else:
				LandNav.open(&"account"))
		_content.add_child(sign_in)
		return

	var who := HBoxContainer.new()
	who.add_theme_constant_override("separation", 10)
	var name_lbl := UI3.label(AccountService.display_name(), "LabelTitle")
	who.add_child(name_lbl)
	if bool(AccountService.account.get("sky_mavis", false)):
		who.add_child(AccountUI.sky_mavis_badge())
	_content.add_child(who)
	_body("%s · Google" % String(AccountService.account.get("email", "")))
	var status_lbl := _body("")
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

	if AccountService.status == AccountServiceScript.Status.EXPIRED:
		_body("Your session expired. Sign in again to keep saving. Your progress is safe on this device.")
		var again := UI3.button("Sign in", &"primary")

		again.pressed.connect(func() -> void:
			if SaveStore.is_web():
				AccountService.sign_in()
			else:
				LandNav.open(&"account"))
		_content.add_child(again)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_content.add_child(row)
	var switch_btn := UI3.button("Switch account", &"secondary")
	switch_btn.name = "SwitchAccountButton"
	switch_btn.pressed.connect(func() -> void: AccountService.sign_in(true))
	row.add_child(switch_btn)

	var out_btn := UI3.button("Sign out", &"danger")
	out_btn.name = "SignOutButton"
	row.add_child(out_btn)
	var confirm_lbl := _body("")
	confirm_lbl.visible = false
	var armed := [false]
	out_btn.pressed.connect(func() -> void:
		if not armed[0]:
			armed[0] = true
			var unsynced: bool = AccountService.has_unsynced_changes()
			out_btn.text = "Sync and sign out" if unsynced else "Confirm sign out"
			confirm_lbl.text = ("Sign out? Your progress is saved to your account. This browser "
				+ "is signed out.") if not unsynced else ("Sign out? Your latest "
				+ "progress uploads first, then this browser is signed out.")
			confirm_lbl.visible = true
			return
		out_btn.disabled = true
		switch_btn.disabled = true
		AccountService.sign_out())


# --- small builders ---------------------------------------------------------

func _section(text: String) -> void:
	var lbl := UI3.label(text, "LabelTitle")
	lbl.name = "Section_" + text.replace(" ", "")
	_content.add_child(lbl)
	_sections[text] = lbl


## Plain info text under a row group (also used for transient status lines).
func _body(text: String) -> Label:
	var lbl := UI3.label(text, "LabelMuted")
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(lbl)
	return lbl


## One settings row: title + optional description on the left, `ctrl` (optional) on the right. Min 56.
func _row(title: String, desc: String = "", ctrl: Control = null) -> HBoxContainer:
	var card := UI3.plate(&"row")
	card.custom_minimum_size = Vector2(0, ROW_MIN)
	# Spec row margin is 12 sides / 0 top: fine for one line, cramped with a description. 16 x 12 here.
	var rsb := UI3Theme.get_theme().get_stylebox("panel", "PanelRow").duplicate() as StyleBoxFlat
	rsb.content_margin_left = 16
	rsb.content_margin_right = 16
	rsb.content_margin_top = 12
	rsb.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", rsb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	card.add_child(h)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var t := UI3.label(title, "LabelDisplay")
	left.add_child(t)
	if desc != "":
		var d := UI3.label(desc, "LabelMuted")
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left.add_child(d)
	h.add_child(left)
	if ctrl != null:
		ctrl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ctrl)
	_content.add_child(card)
	return h


## A toggle that prints On / Off as text next to the check.
func _toggle(label: String, desc: String, pressed: bool, on_toggle: Callable) -> void:
	var box := CheckBox.new()
	box.name = "%sCheck" % label.split(" ")[0]
	box.text = "On" if pressed else "Off"
	box.button_pressed = pressed
	box.toggled.connect(func(on: bool) -> void:
		box.text = "On" if on else "Off"
		on_toggle.call(on))
	_row(label, desc, box)
	if _first_focus == null:
		_first_focus = box


## A slider with its value ON SCREEN (300 wide).
func _slider(label: String, value: float, on_change: Callable) -> void:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	var slider := HSlider.new()
	slider.name = "%sSlider" % label.replace(" ", "")
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(300, 28)
	box.add_child(slider)
	var value_lbl := UI3.label("%d%%" % roundi(value * 100.0))
	value_lbl.custom_minimum_size = Vector2(56, 0)
	box.add_child(value_lbl)
	slider.value_changed.connect(func(v: float) -> void:
		value_lbl.text = "%d%%" % roundi(v * 100.0)
		on_change.call(v))
	_row(label, "", box)
	if _first_focus == null:
		_first_focus = slider
