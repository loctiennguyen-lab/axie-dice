extends Node
## UI-05 b23 lane S14: Settings (frames 26-settings*). data-names exist, 1920 + 1280 sizes come from tokens, key buttons are
## >= key_btn_w and never clip their text, text >= 14 real px at 1280, keypad keys are listed by text_all, no illustrative values.
## Run: godot --headless --path godot res://tests/t_ui5_settings.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const NAMES := ["Header", "BackButton", "Title", "SubLine", "Body", "SectionIndex", "IndexRow", "Column",
	"SectionAudio", "SectionAccessibility", "SectionControls", "SectionAidAndSpending", "SectionHowToPlay", "SectionRun",
	"SectionAccount", "SettingRow", "SwitchButton", "ShortcutRow", "KeyButton", "ResetButton", "ReplayButton",
	"ConfirmRow", "Checkbox", "AbandonButton", "SignedOutRow"]
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_ui5_settings: start ===")
	_guard.capture()
	await get_tree().process_frame
	KeyBindings.reset_all()
	_check(KeyBindings.text_all(&"land_run") == "Enter, Num Enter", "text_all land_run: " + KeyBindings.text_all(&"land_run"))
	_check(KeyBindings.text_all(&"die_1") == "1, Num 1", "text_all die_1: " + KeyBindings.text_all(&"die_1"))
	_check(KeyBindings.text_all(&"combat_end_turn") == "Space, E", "text_all end turn: " + KeyBindings.text_all(&"combat_end_turn"))
	_check(KeyBindings.text_all(&"boss_intro_skip") == "Space, Enter, Num Enter", "text_all boss skip")
	RunState.start_new_run(4242, ["plant1", "beast1", "aqua1", "reptile1", "bird1"], "short", 0, false)
	RunState.save_run({})
	for sc in [1.0, 2.0 / 3.0]:
		await _screen(sc)
	RunState.clear_saved_run()
	UI3Theme.set_scale_override(1.0)
	await _accounts()
	UI3Theme.set_scale_override(1.0)
	var v := await _open()
	_check(v.abandon_button != null and v.abandon_button.disabled, "no run: AbandonButton shown and disabled")
	v.queue_free()
	await get_tree().process_frame
	_guard.restore()
	print("=== t_ui5_settings: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_settings: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_ui5_settings: FAIL - " + f)
	get_tree().quit(1)


func _open() -> Node:
	var view: Node = (load("res://scenes/settings/Settings.tscn") as PackedScene).instantiate()
	add_child(view)
	for _i in 6:
		await get_tree().process_frame
	return view


func _screen(sc: float) -> void:
	UI3Theme.set_scale_override(sc)
	var tag := "%.2f" % sc
	var v := await _open()
	for n in NAMES:
		_check(v.find_child(n + "*", true, false) != null, "[%s] node '%s' exists" % [tag, n])
	_check(v.find_children("IndexRow*", "Button", true, false).size() == 7, "[%s] 7 IndexRows" % tag)
	var idx := v.find_child("SectionIndex", true, false) as Control
	_check(idx != null and idx.custom_minimum_size.x == float(UI3Theme.size_of("settings_index_w")), "[%s] SectionIndex wide settings_index_w" % tag)
	var rows := v.find_children("SettingRow*", "PanelContainer", true, false)
	var ok_h := not rows.is_empty()
	for r in rows:
		ok_h = ok_h and (r as Control).size.y >= float(UI3Theme.size_of("settings_row_h")) - 0.5
	_check(ok_h, "[%s] SettingRow >= settings_row_h" % tag)
	var kw := float(UI3Theme.size_of("key_btn_w"))
	if sc < 1.0:
		_check(absf(kw * sc - 160.0) < 0.6, "1280: key_btn_w is 160 real px (%s logical)" % kw)
	var keys := v.find_children("KeyButton*", "Button", true, false)
	_check(keys.size() == KeyBindings.DEFS.size(), "[%s] one KeyButton per action (%d)" % [tag, keys.size()])
	for b in keys:
		var bb := b as Button
		var f := bb.get_theme_font("font")
		var w := f.get_string_size(bb.text, HORIZONTAL_ALIGNMENT_LEFT, -1, bb.get_theme_font_size("font_size")).x
		_check(bb.size.x >= kw - 0.5, "[%s] KeyButton '%s' >= key_btn_w (%s)" % [tag, bb.text, bb.size.x])
		_check(bb.size.x >= w + 2.0 * UI3Theme.space("16") - 0.5, "[%s] KeyButton '%s' text not clipped" % [tag, bb.text])
	var all := ""
	for n in v.find_children("*", "", true, false):
		if n is Label and (n as Label).is_visible_in_tree():
			all += (n as Label).text + "\n"
			if sc < 1.0:
				_check(float((n as Label).get_theme_font_size("font_size")) * sc >= 14.0 - 0.01,
					"1280: '%s' >= 14 real px" % (n as Label).text.left(24))
	var key_texts: Array[String] = []
	for b in keys:
		key_texts.append((b as Button).text)
	_check(key_texts.has("Enter, Num Enter") and key_texts.has("Space, Enter, Num Enter") and key_texts.has("1, Num 1")
		and key_texts.has("Space, E"), "[%s] KeyButtons list every key incl. keypad: %s" % [tag, key_texts.slice(0, 3)])
	var sl := v._sliders[&"music"] as Control
	if sc >= 1.0:
		_check(sl != null and absf(sl.size.x - 300.0) < 0.6, "[1920] slider is 300 wide (%s)" % (sl.size.x if sl != null else -1.0))
	var fo := get_viewport().gui_get_focus_owner()
	_check(fo != null and String(fo.name).begins_with("IndexRow"), "[%s] initial focus is the first IndexRow (%s)" % [tag, fo.name if fo != null else "none"])
	for n in v.find_children("*", "BaseButton", true, false):
		var bt := n as BaseButton
		if bt.is_visible_in_tree() and sc < 1.0:
			_check(float(bt.get_theme_font_size("font_size")) * sc >= 14.0 - 0.01, "1280: button '%s' >= 14 real px (%d logical)" % [bt.get("text"), bt.get_theme_font_size("font_size")])
	for bad in ["liam@gmail.com", "Saved just now", "800 Shards", "Liam"]:
		_check(not all.contains(bad), "[%s] no illustrative value '%s'" % [tag, bad])
	_check(v.abandon_check != null and v.abandon_button != null, "[%s] ConfirmRow checkbox + button" % tag)
	var pairs := Align.pairs(v)
	print("t_ui5_settings: align pairs [%s] = %d" % [tag, pairs])
	var probs := Align.check(v)
	_check(probs.is_empty(), "[%s] icon/label alignment: %s" % [tag, "; ".join(probs)])
	v.queue_free()
	await get_tree().process_frame


## Account states of the real AccountService, set by field (no server: transport is a stub that records the path).
func _accounts() -> void:
	var svc := AccountService
	var keep := [svc.enabled, svc.status, svc.account, svc.transport, svc.last_synced, svc.desktop_enabled_override]
	var calls: Array[String] = []
	svc.transport = func(_m: String, path: String, _b: String, _cb: Callable) -> void: calls.append(path)
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		var tag := "acct %.2f" % sc
		# signed out: desktop button, web button
		svc.enabled = false
		svc.account = {}
		svc.desktop_enabled_override = true
		var v := await _open()
		_check(v.find_child("SignedOutRow*", true, false) != null and v.find_child("AccountButton", true, false) != null, "[%s] signed out (desktop): SignedOutRow + AccountButton" % tag)
		v.queue_free()
		await get_tree().process_frame
		svc.enabled = true
		v = await _open()
		var si := v.find_child("SignInButton", true, false) as Button
		_check(si != null and si.text == "Continue with Google", "[%s] signed out (web copy): Continue with Google" % tag)
		v.queue_free()
		await get_tree().process_frame
		# signed in
		svc.status = AccountService.Status.SAVED
		svc.account = {"name": "Test Player", "email": "test.player@example.test", "sky_mavis": true}
		svc.last_synced = int(Time.get_unix_time_from_system())
		v = await _open()
		var all := _texts(v)
		_check(v.find_child("Avatar", true, false) != null, "[%s] account-in: Avatar" % tag)
		_check(all.contains("Test Player") and all.contains("SKY MAVIS") and all.contains("test.player@example.test · Google"), "[%s] account-in: name, SKY MAVIS tag, email" % tag)
		_check(all.contains("Cloud save: Saved"), "[%s] account-in: Cloud save line" % tag)
		var sw := v.find_children("SwitchButton*", "Button", true, false)
		var out := v.find_child("SignOutButton", true, false) as Button
		_check(sw.size() == 1 and (sw[0] as Button).theme_type_variation == &"ButtonSecondaryS", "[%s] Switch account is secondary S" % tag)
		_check(out != null and out.theme_type_variation == &"ButtonSecondaryS" and out.text == "Sign out", "[%s] Sign out is secondary S" % tag)
		calls.clear()
		out.pressed.emit()
		_check(out.text == "Confirm sign out" and out.theme_type_variation == &"ButtonDanger", "[%s] account-confirm: Confirm sign out, danger" % tag)
		var note := v.find_child("SignOutNote", true, false) as Label
		_check(note != null and note.visible and note.text.begins_with("You will need to sign in again"), "[%s] account-confirm: warning line" % tag)
		_check(calls.is_empty(), "[%s] first press does not sign out" % tag)
		out.pressed.emit()
		_check(calls.has("/auth/logout"), "[%s] second press signs out (stub got %s)" % [tag, calls])
		v.queue_free()
		await get_tree().process_frame
		# expired
		svc.status = AccountService.Status.EXPIRED
		v = await _open()
		var disc := v.find_child("ToneDisc", true, false) as Control
		var row := v.find_child("ExpiredRow*", true, false)
		var lbl: Label = null
		for l in row.find_children("*", "Label", true, false):
			if (l as Label).text.begins_with("Your session expired"):
				lbl = l
		_check(disc != null and lbl != null and v.find_child("SignInButton", true, false) != null, "[%s] account-expired: ToneDisc + text + SignInButton" % tag)
		_check(v.find_child("SignOutButton", true, false) == null, "[%s] account-expired: no sign out row (frame)" % tag)
		if disc != null and lbl != null:
			var dy := disc.get_global_rect().get_center().y
			var ty: float = Align.text_center(lbl).y
			_check(absf(dy - ty) <= 1.5 or lbl.get_visible_line_count() > 1, "[%s] ToneDisc centred on the text (%.1f vs %.1f)" % [tag, dy, ty])
		# Align checker: the error disc carries a "!" label, not an icon, so it is measured by hand above; the checker still runs.
		_check(Align.check(v).is_empty(), "[%s] expired: align_check clean" % tag)
		print("t_ui5_settings: align pairs expired [%s] = %d" % [tag, Align.pairs(v)])
		v.queue_free()
		await get_tree().process_frame
	svc.enabled = keep[0]
	svc.status = keep[1]
	svc.account = keep[2]
	svc.transport = keep[3]
	svc.last_synced = keep[4]
	svc.desktop_enabled_override = keep[5]


func _texts(root: Node) -> String:
	var all := ""
	for n in root.find_children("*", "Label", true, false):
		if (n as Label).is_visible_in_tree():
			all += (n as Label).text + "\n"
	return all
