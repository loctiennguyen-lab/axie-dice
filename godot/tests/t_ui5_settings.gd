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
	_check(all.contains("Enter, Num Enter") or v.find_child("KeyButton", true, false) != null, "[%s] keys listed" % tag)
	for bad in ["liam@gmail.com", "Saved just now", "800 Shards", "Liam"]:
		_check(not all.contains(bad), "[%s] no illustrative value '%s'" % [tag, bad])
	_check(v.abandon_check != null and v.abandon_button != null, "[%s] ConfirmRow checkbox + button" % tag)
	var pairs := Align.pairs(v)
	print("t_ui5_settings: align pairs [%s] = %d" % [tag, pairs])
	var probs := Align.check(v)
	_check(probs.is_empty(), "[%s] icon/label alignment: %s" % [tag, "; ".join(probs)])
	v.queue_free()
	await get_tree().process_frame
