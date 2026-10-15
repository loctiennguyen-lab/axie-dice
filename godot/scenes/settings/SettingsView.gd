class_name SettingsView
extends Control
## M11 Settings (Esc on the hub), Round 3. Spec: design/handoffs/ui-02-round3 README M11, frames M11a-d.
## Section index (260) + one column (max 960), rows >= 56, toggles print On/Off, sliders 300.
## Every control here is wired to something real: music/sfx/mute (MetaState + CombatAudioDirector),
## reduce flashing (CombatView.flashes_suppressed), replay tutorial, abandon run, account.
## Not drawn, because nothing backs them yet: text size, UI scale, spending presets, hide-Aid, language,
## keyboard map, About. Gamepad row dropped on purpose (no gamepad). Spending limit shows only the L1 note.
## ABANDON RUN asks twice and is absent (not greyed) when there is no saved run; with a mission stake
## in escrow it warns the stake is lost and settles it (MetaState.settle_mission_stake(false)).
## In-run mode (opened from the combat menu): set `SettingsView.in_run = true` and `return_scene`
## before changing to Settings.tscn; Back reads "Back to run", the Run section goes first.

const BG_TEXTURE := "res://assets/backgrounds/origins/scene/4-entrance.jpg"
const INDEX_W := 260.0
const COL_MAX := 960.0
const ROW_MIN := 56.0

static var in_run: bool = false
static var return_scene: String = ""

var _content: VBoxContainer
var _abandon_status: Label = null
var _sections: Dictionary = {}   # name -> header Label
var _scroll: ScrollContainer
var _first_focus: Control = null


func _ready() -> void:
	var shell := DangoScreen.build(self, load(BG_TEXTURE), DangoTheme.Scrim.DEFAULT, true)
	var content: Control = shell["content"]
	var footer: HBoxContainer = shell["footer"]

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var order: Array[String] = ["Audio", "Accessibility", "Aid and spending", "How to play", "Run", "Account"]
	if in_run:
		order = ["Run", "Audio", "Accessibility", "Aid and spending", "How to play", "Account"]
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

	var h := _settings_max_height()
	_scroll = DangoScreen.fit_or_scroll(_content, h)
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	top.add_child(DangoTheme.display_label("Settings", 34, DangoTheme.CREAM_RAISED, 800, 0.02))
	top.add_child(DangoTheme.prose_label(
		"Opened from the combat menu. The run is paused." if in_run else "Every toggle states On / Off in words.",
		14, DangoTheme.CREAM_RAISED, 600))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	cols.add_child(_build_index(order))
	var col_wrap := MarginContainer.new()
	col_wrap.custom_minimum_size.x = 0
	col_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_wrap.add_child(_scroll)
	cols.add_child(col_wrap)
	top.add_child(cols)
	content.add_child(top)
	_content.custom_minimum_size.x = 0

	DangoScreen.add_back_button(footer, _on_back).text = "BACK TO RUN" if in_run else "BACK"
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


func _unhandled_key_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_ESCAPE:
		_on_back()
		get_viewport().set_input_as_handled()


func _settings_max_height() -> float:
	return get_viewport_rect().size.y - DangoScreen.SAFE * 2.0 - DangoScreen.FOOTER_H - 80.0


func _build_index(order: Array[String]) -> Control:
	var v := VBoxContainer.new()
	v.name = "SectionIndex"
	v.custom_minimum_size.x = INDEX_W
	v.add_theme_constant_override("separation", 6)
	for sec in order:
		var b := Button.new()
		b.name = "Index_" + sec.replace(" ", "")
		b.text = sec
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(INDEX_W, 48)
		DangoTheme.style_button(b, false)
		b.pressed.connect(func() -> void:
			var hdr: Control = _sections.get(sec)
			if hdr != null:
				_scroll.scroll_vertical = int(hdr.position.y))
		v.add_child(b)
	return v


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
	var btn := Button.new()
	btn.name = "ReplayTutorialButton"
	btn.text = "REPLAY THE TUTORIAL"
	btn.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(btn, false)
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
	var btn := Button.new()
	btn.text = "ABANDON RUN"
	btn.custom_minimum_size = Vector2(0, 44)
	btn.disabled = true
	DangoTheme.style_button(btn, false, true)
	confirm.toggled.connect(func(on: bool) -> void:
		btn.disabled = not on)
	btn.pressed.connect(func() -> void:
		if RunState.has_saved_run():
			MetaState.settle_mission_stake(false)   # lane E: abandon = mission loss (no-op without escrow)
		# Online: close the run on the server too, or it stays `open` and the next Begin hits run_open
		# (Liam 15/10). Fire and forget: if this fails (offline), Begin's run_open recovery abandons it later.
		if RemoteEpochSource.flag_on() and RunState.session != null and RunState.session.run_id != "":
			RunState.session.abandon(func(_ok: bool) -> void: pass)
		RunState.clear_saved_run()
		RunState.reset()
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
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.add_child(confirm)
	box.add_child(btn)
	_row("Abandon mission run" if stake > 0 else "Abandon run", warn, box)
	_abandon_status = _body("")
	_abandon_status.visible = false


## Settings → Account (claude/ACCOUNT_SYSTEM_v1.md §7 C). The only place with Sign out and
## Switch account. Sign out takes two presses: the first says what happens, the second does it.
func _build_account_section() -> void:
	if not AccountService.enabled:
		if SaveStore.is_web() or not AccountService.desktop_enabled_override:
			_body("Accounts are available in the web version at axiedice.fun. Progress here stays "
				+ "on this computer.")
			return
		# Desktop, signed out: the Account screen (B3) owns the browser flow, waiting and errors.
		_body("You're playing as a guest. Progress stays on this computer. Sign in with Google to "
			+ "keep it on every device.")
		var open_acct := Button.new()
		open_acct.name = "OpenAccountButton"
		open_acct.text = "ACCOUNT"
		open_acct.custom_minimum_size = Vector2(0, 44)
		DangoTheme.style_button(open_acct, true)
		open_acct.pressed.connect(func() -> void: LandNav.open(&"account"))
		_content.add_child(open_acct)
		return
	if not AccountService.is_signed_in():
		_body("You're playing as a guest. Progress stays on this browser only. Sign in with "
			+ "Google to keep it on every device. Your Sky Mavis work account works too.")
		var sign_in := Button.new()
		sign_in.name = "SignInButton"
		sign_in.text = "CONTINUE WITH GOOGLE"
		sign_in.custom_minimum_size = Vector2(0, 44)
		DangoTheme.style_button(sign_in, true)
		sign_in.pressed.connect(func() -> void:
			if SaveStore.is_web():
				AccountService.sign_in()
			else:
				LandNav.open(&"account"))
		_content.add_child(sign_in)
		return

	var who := HBoxContainer.new()
	who.add_theme_constant_override("separation", 10)
	var name_lbl := DangoTheme.display_label(AccountService.display_name(), 22, DangoTheme.CREAM_RAISED)
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
		var again := Button.new()
		again.text = "SIGN IN"
		again.custom_minimum_size = Vector2(0, 44)
		DangoTheme.style_button(again, true)
		again.pressed.connect(func() -> void:
			if SaveStore.is_web():
				AccountService.sign_in()
			else:
				LandNav.open(&"account"))
		_content.add_child(again)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_content.add_child(row)
	var switch_btn := Button.new()
	switch_btn.name = "SwitchAccountButton"
	switch_btn.text = "SWITCH ACCOUNT"
	switch_btn.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(switch_btn, false)
	switch_btn.pressed.connect(func() -> void: AccountService.sign_in(true))
	row.add_child(switch_btn)

	var out_btn := Button.new()
	out_btn.name = "SignOutButton"
	out_btn.text = "SIGN OUT"
	out_btn.custom_minimum_size = Vector2(0, 44)
	DangoTheme.style_button(out_btn, true, true)
	row.add_child(out_btn)
	var confirm_lbl := _body("")
	confirm_lbl.visible = false
	var armed := [false]
	out_btn.pressed.connect(func() -> void:
		if not armed[0]:
			armed[0] = true
			var unsynced: bool = AccountService.has_unsynced_changes()
			out_btn.text = "SYNC AND SIGN OUT" if unsynced else "CONFIRM SIGN OUT"
			confirm_lbl.text = ("Sign out? Your progress is saved to your account. This browser "
				+ "goes back to guest mode.") if not unsynced else ("Sign out? Your latest "
				+ "progress uploads first, then this browser goes back to guest mode.")
			confirm_lbl.visible = true
			return
		out_btn.disabled = true
		switch_btn.disabled = true
		AccountService.sign_out())


# --- small builders ---------------------------------------------------------

func _section(text: String) -> void:
	var lbl := DangoTheme.display_label(text, 22, DangoTheme.CREAM_RAISED, 800, 0.02)
	lbl.name = "Section_" + text.replace(" ", "")
	_content.add_child(lbl)
	_sections[text] = lbl


## Plain info text under a row group (also used for transient status lines).
func _body(text: String) -> Label:
	var lbl := DangoTheme.prose_label(text, 14, DangoTheme.CREAM_RAISED, 600)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(lbl)
	return lbl


## One settings row: title + optional description on the left, `ctrl` (optional) on the right. Min 56.
func _row(title: String, desc: String = "", ctrl: Control = null) -> HBoxContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, ROW_MIN)
	card.add_theme_stylebox_override("panel", DangoTheme.surface_style(DangoTheme.Surface.CREAM, 12, 2, 0.0, Vector2(16, 8)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	card.add_child(h)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var t := DangoTheme.display_label(title, 17, DangoTheme.INK, 800, 0.02)
	left.add_child(t)
	if desc != "":
		var d := DangoTheme.prose_label(desc, 13, DangoTheme.INK_ON_CREAM_MUTED, 600)
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
	var value_lbl := DangoTheme.prose_label("%d%%" % roundi(value * 100.0), 16, DangoTheme.INK, 700)
	value_lbl.custom_minimum_size = Vector2(56, 0)
	box.add_child(value_lbl)
	slider.value_changed.connect(func(v: float) -> void:
		value_lbl.text = "%d%%" % roundi(v * 100.0)
		on_change.call(v))
	_row(label, "", box)
	if _first_focus == null:
		_first_focus = slider
