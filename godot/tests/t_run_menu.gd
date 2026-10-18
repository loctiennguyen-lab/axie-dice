extends Node
## L1 C3: the in-run menu (Esc / gear / MENU) opens Settings in in-run mode and coming back resumes
## the same state; abandoning from there clears the run and leaves for Land.

var _failures: Array[String] = []
var _checks := 0
var _tree: SceneTree
var _guard := SaveGuard.new()


func _assert(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)


func _ready() -> void:
	print("=== t_run_menu: start ===")
	_tree = get_tree()
	_guard.capture()
	await get_tree().process_frame
	await _combat_roundtrip()
	await _map_roundtrip()
	await _pause_menu()
	LandNav.dry_run = true   # abandon -> back_to_land would load Land, which touches the save after restore()
	await _abandon_from_run()
	LandNav.dry_run = false
	_guard.restore()
	print("=== t_run_menu: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_run_menu: PASS — %d checks OK" % _checks)
		_tree.quit(0)
	else:
		for f in _failures:
			print("FAIL: " + f)
		_tree.quit(1)


func _new_combat() -> Node:
	var c: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(c)
	for i in 5:
		await get_tree().process_frame
	return c


func _combat_roundtrip() -> void:
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(777, team, "short", 0, false)
	RunState.enter_node("r1_c0", "battle")
	var c := await _new_combat()
	var before: Dictionary = c._combat.to_data()
	c.prepare_run_menu()
	_assert(SettingsView.in_run and SettingsView.return_scene == "res://scenes/combat/Combat.tscn",
		"combat menu did not set in-run Settings")
	_assert(not RunState.resume_combat.is_empty(), "combat snapshot not stored for resume")
	c.queue_free()
	await get_tree().process_frame
	var c2 := await _new_combat()    # what "Back to run" does: reload Combat.tscn
	_assert(JSON.stringify(c2._combat.to_data()) == JSON.stringify(before),
		"combat state changed across the menu round trip")
	c2.queue_free()
	SettingsView.in_run = false
	SettingsView.return_scene = ""


func _map_roundtrip() -> void:
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(778, team, "short", 0, false)
	var m: Node = (load("res://scenes/run_map/RunMap.tscn") as PackedScene).instantiate()
	add_child(m)
	await get_tree().process_frame
	await get_tree().process_frame
	_assert(m.find_child("RunMenuButton", true, false) != null, "run map has no MENU button")
	var node_before := RunState.current_node_id
	var data_before := JSON.stringify(RunState.to_data())
	m.prepare_run_menu()
	_assert(SettingsView.in_run and SettingsView.return_scene == "res://scenes/run_map/RunMap.tscn",
		"map menu did not set in-run Settings")
	_assert(RunState.has_saved_run(), "map menu did not save the run")
	_assert(RunState.current_node_id == node_before and JSON.stringify(RunState.to_data()) == data_before,
		"opening the map menu changed run state")
	m.queue_free()
	SettingsView.in_run = false
	SettingsView.return_scene = ""


## UI-03 14: the pause plate opens on the map, Resume closes it, Abandon asks first (focus on Keep playing,
## stake line only for a Mission run) and abandoning clears the run.
func _pause_menu() -> void:
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(780, team, "short", 0, false)
	var m: Node = (load("res://scenes/run_map/RunMap.tscn") as PackedScene).instantiate()
	add_child(m)
	await get_tree().process_frame
	await get_tree().process_frame
	m.open_run_menu()
	await get_tree().process_frame
	var pm := m.find_child("RunPauseMenu", true, false) as RunPauseMenu
	_assert(pm != null, "open_run_menu shows the pause plate")
	if pm != null:
		for k in ["Resume", "Relics", "Map", "Settings", "SaveQuit", "Abandon"]:
			_assert(pm.rows.has(k) and (pm.rows[k] as Button).custom_minimum_size.y >= 64.0, "pause row %s" % k)
		var ab := pm.rows["Abandon"] as Button
		_assert(ab.find_child("Underline", false, false) == null, "Abandon row has no underline")
		_assert(ab.get_theme_color("font_color") == UI3Theme.color("danger_text"), "Abandon is red-8 text")
		_assert(ab.theme_type_variation != &"ButtonPrimaryM" and ab.theme_type_variation != &"ButtonPrimaryL", "Abandon is not primary")
		RunState.owned_relic_ids.assign(["r_claw"])
		pm.show_side("relics")
		var small := pm.find_child("SidePanel", true, false).find_children("*", "Label", true, false).filter(
			func(l): return (l as Label).get_theme_font_size("font_size") < 18)
		_assert(small.is_empty(), "relic panel text is >= 18 px")
		pm.show_side("settings")
		_assert(pm.find_child("InfoMusic", true, false) != null and pm.find_child("OpenSettings", true, false) != null, "settings panel shows the rows that matter")
		_assert((pm.find_child("OpenSettings", true, false) as Button).theme_type_variation == &"ButtonSecondaryS", "Open Settings is secondary-S")
		pm.show_side("map")
		_assert(pm.find_child("InfoFloor", true, false) != null, "map panel shows the run summary")
		_assert(pm.find_child("SidePanel", true, false) != null and pm.side_name == "map", "side panel switches")
		MetaState.mission_escrow = {}
		(pm.rows["Abandon"] as Button).pressed.emit()
		await get_tree().process_frame
		_assert(pm.find_child("ConfirmDialog", true, false) != null, "Abandon asks first")
		var texts := pm.find_child("ConfirmDialog", true, false).find_children("*", "Label", true, false).map(func(l): return (l as Label).text)
		_assert(not texts.any(func(t): return String(t).contains("mission stake")), "no stake line outside Mission runs")
		(pm.find_child("ConfirmKeep", true, false) as Button).pressed.emit()
		await get_tree().process_frame
		MetaState.mission_escrow = {"stake": 25}
		(pm.rows["Abandon"] as Button).pressed.emit()
		await get_tree().process_frame
		texts = pm.find_child("ConfirmDialog", true, false).find_children("*", "Label", true, false).map(func(l): return (l as Label).text)
		_assert(texts.any(func(t): return String(t).contains("You lose your 25 Shard mission stake")), "Mission run shows the stake line")
		(pm.find_child("ConfirmKeep", true, false) as Button).pressed.emit()
		await get_tree().process_frame
		_assert(RunState.roster.size() == 5, "Keep playing leaves the run alone")
		MetaState.mission_escrow = {}
		var resumed := [0]
		pm.resumed.connect(func(): resumed[0] += 1)
		(pm.rows["Resume"] as Button).pressed.emit()
		await get_tree().process_frame
		_assert(resumed[0] == 1 and m.find_child("RunPauseMenu", true, false) == null, "Resume closes the plate")
	m.queue_free()
	await get_tree().process_frame


func _abandon_from_run() -> void:
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(779, team, "short", 0, false)
	RunState.save_run({})
	SettingsView.in_run = true
	SettingsView.return_scene = "res://scenes/run_map/RunMap.tscn"
	var v: Node = (load("res://scenes/settings/Settings.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(v)
	await get_tree().process_frame
	await get_tree().process_frame
	var btn: Button = null
	var confirm: CheckBox = null
	for n in v.find_children("*", "", true, false):
		if n is Button and (n as Button).text == "Abandon run": btn = n
		if n is CheckBox and n.name == "ConfirmAbandonCheck": confirm = n
	_assert(btn != null and confirm != null, "in-run Settings has no Abandon run")
	if btn == null or confirm == null:
		return
	var back: Button = null
	for n in v.find_children("*", "Button", true, false):
		if n.name == "BackButton" and (n as Button).tooltip_text.begins_with("Back to run"): back = n   # UI3Meta back is an arrow; the words live in the tooltip
	_assert(back != null, "in-run Settings Back does not read Back to run")
	confirm.button_pressed = true
	btn.pressed.emit()
	_assert(not RunState.has_saved_run(), "abandon left the save on disk")
	_assert(not SettingsView.in_run and SettingsView.return_scene == "",
		"abandon left in-run mode on (Back would return to a dead run)")
