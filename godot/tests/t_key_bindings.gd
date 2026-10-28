extends Node
## Rebindable keys: defaults are InputMap actions, a rebind changes what a key does on the real Land hub,
## overrides survive a MetaState save/reload, hints read the binding, Settings > Controls captures a key,
## warns on a conflict and resets; the combat HUD draws only the End turn key and names the others in tooltips. Run: godot --headless --path godot res://tests/t_key_bindings.tscn

var _fails: Array[String] = []
var _checks := 0
var _save_guard := SaveGuard.new()


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)
		printerr("FAIL: ", msg)


func _ev(k: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = k as Key
	e.pressed = true
	return e


func _ready() -> void:
	print("=== t_key_bindings: start ===")
	_save_guard.capture()
	await get_tree().process_frame
	MetaState.key_bindings = {}
	KeyBindings.reset_registration()

	# defaults
	for d in KeyBindings.DEFS:
		_check(InputMap.has_action(d["id"]), "action registered: %s" % d["id"])
	_check(_ev(KEY_R).is_action_pressed(&"combat_reroll"), "R rerolls by default")
	_check(_ev(KEY_SPACE).is_action_pressed(&"combat_end_turn") and _ev(KEY_E).is_action_pressed(&"combat_end_turn"),
		"Space and E end the turn by default")
	_check(_ev(KEY_KP_3).is_action_pressed(&"die_3"), "numpad 3 picks die 3")
	_check(KeyBindings.text(&"combat_end_turn") == "Space" and KeyBindings.text(&"land_new_run") == "N", "hint text")
	_check(KeyBindings.overrides().is_empty(), "no overrides at default")

	# rebind + conflict query
	KeyBindings.set_keys(&"combat_reroll", [KEY_T])
	_check(not _ev(KEY_R).is_action_pressed(&"combat_reroll") and _ev(KEY_T).is_action_pressed(&"combat_reroll"), "rebind moves the key")
	_check(KeyBindings.text(&"combat_reroll") == "T", "hint follows the binding")
	_check(KeyBindings.conflicts(&"combat_undo", KEY_T) == [&"combat_reroll"], "conflict found inside a group")
	_check(KeyBindings.conflicts(&"land_codex", KEY_T).is_empty(), "same key in another group is not a conflict")
	_check(not KeyBindings.bindable(KEY_ESCAPE) and not KeyBindings.bindable(KEY_SHIFT) and KeyBindings.bindable(KEY_Q), "Esc and modifiers are not bindable")

	# persistence through MetaState (SaveStore) and reload
	MetaState.key_bindings = KeyBindings.overrides()
	_check(MetaState.key_bindings.has("combat_reroll"), "override recorded")
	MetaState.save_to_disk()
	MetaState.key_bindings = {}
	KeyBindings.reset_all()
	MetaState.reload_from_store()
	_check(KeyBindings.keys_of(&"combat_reroll") == [KEY_T], "binding survives save + reload_from_store")
	_check(KeyBindings.keys_of(&"combat_undo") == [KEY_Z], "untouched action keeps its default")

	# the real Land hub obeys the binding
	KeyBindings.reset_all()
	KeyBindings.set_keys(&"land_codex", [KEY_X])
	MetaState.tutorial_seen = true   # in memory only: Land redirects to the tutorial otherwise
	LandNav.dry_run = true
	LandHub.qa = {"guest": false, "offline": false}
	var hub := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate()
	add_child(hub)
	for i in 5:
		await get_tree().process_frame
	_check(not hub.call("_handle_key", KEY_C), "old key does nothing after rebind")
	_check(hub.call("_handle_key", KEY_X), "new key is used")
	KeyBindings.set_keys(&"land_new_run", [KEY_J])
	_check(hub.call("_tip_text", "portal").contains("1"), "portal tooltip shows its key")
	hub.queue_free()
	await get_tree().process_frame

	# Settings > Controls
	KeyBindings.reset_all()
	MetaState.key_bindings = {}
	SettingsView.in_run = false
	var st := (load("res://scenes/settings/Settings.tscn") as PackedScene).instantiate()
	add_child(st)
	for i in 4:
		await get_tree().process_frame
	var btn := st.find_child("Key_combat_reroll", true, false) as Button
	_check(btn != null and btn.text == "R", "Controls lists Reroll with R")
	btn.pressed.emit()
	_check(btn.text == "Press a key...", "click waits for a key")
	st.call("_input", _ev(KEY_ESCAPE))
	_check(btn.text == "R" and KeyBindings.keys_of(&"combat_reroll") == [KEY_R], "Esc cancels, binding unchanged")
	btn.pressed.emit()
	st.call("_input", _ev(KEY_Z))   # Z belongs to Undo: swap + warning
	_check(KeyBindings.keys_of(&"combat_reroll") == [KEY_Z], "reroll now on Z")
	_check(KeyBindings.keys_of(&"combat_undo") == [KEY_R], "undo swapped onto the old key")
	var status := (st.find_child("ControlsStatus", true, false) as Label).text
	_check(status.contains("was on") , "conflict warning shown: " + status)
	_check(MetaState.key_bindings.has("combat_reroll"), "Settings saved the change")
	(st.find_child("ResetKeysButton", true, false) as Button).pressed.emit()
	_check(KeyBindings.keys_of(&"combat_reroll") == [KEY_R] and MetaState.key_bindings.is_empty(), "Reset restores defaults and clears the save")
	st.queue_free()

	# Combat HUD (UI-05, Liam 28/10): only Space is drawn on screen; every other key lives in a tooltip and
	# follows the binding.
	await _combat_hud_keys()

	KeyBindings.reset_all()
	_save_guard.restore()
	MetaState.reload_from_store()
	if _fails.is_empty():
		print("=== t_key_bindings: PASS (%d checks) ===" % _checks)
		get_tree().quit(0)
	else:
		printerr("=== t_key_bindings: FAIL (%d/%d) ===" % [_fails.size(), _checks])
		get_tree().quit(1)


func _combat_hud_keys() -> void:
	KeyBindings.reset_all()
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var hud := CombatHud.new()
	host.add_child(hud)
	hud.adopt_right_zone(Button.new(), Button.new(), Button.new())
	var on := {"show": true, "enabled": true, "text": "Hold", "tip": "Hold the picked die (%s)." % KeyBindings.text(&"combat_hold")}
	hud.update_right({"enabled": true}, {"n": 1, "max": 3, "enabled": true}, {"sub": "5 dice unused", "enabled": true}, on, {}, {})
	await get_tree().process_frame
	_check(hud.undo_button.tooltip_text.contains("(Z)") and hud.reroll_button.tooltip_text.contains("(R)")
		and hud.end_turn_button.tooltip_text.contains("(Space)"),
		"combat tooltips name the keys: %s / %s / %s" % [hud.undo_button.tooltip_text, hud.reroll_button.tooltip_text,
		hud.end_turn_button.tooltip_text])
	hud.update_right({"enabled": false}, {"n": 1, "max": 3, "enabled": true}, {"sub": "5 dice unused", "enabled": true}, on, {}, {})
	_check(hud.undo_button.tooltip_text.contains("(Z)"), "disabled Undo still names its key: %s" % hud.undo_button.tooltip_text)
	var caps := Ui5Keycap.all_under(hud)
	_check(caps.size() == 1 and Ui5Keycap.text_of(caps[0] as PanelContainer) == "Space", "combat HUD shows one key cap, Space (%d)" % caps.size())
	KeyBindings.set_keys(&"combat_reroll", [KEY_T])
	KeyBindings.set_keys(&"combat_end_turn", [KEY_E])
	hud.update_right({"enabled": true}, {"n": 1, "max": 3, "enabled": true}, {"sub": "5 dice unused", "enabled": true}, on, {}, {})
	_check(hud.reroll_button.tooltip_text.contains("(T)") and hud.end_turn_button.tooltip_text.contains("(E)")
		and Ui5Keycap.text_of(caps[0] as PanelContainer) == "E", "rebinds reach the tooltips and the End turn cap")
	_check(_ev(KEY_T).is_action_pressed(&"combat_reroll") and _ev(KEY_E).is_action_pressed(&"combat_end_turn"), "the rebound keys still fire the actions")
	KeyBindings.reset_all()
	host.queue_free()
	await get_tree().process_frame
