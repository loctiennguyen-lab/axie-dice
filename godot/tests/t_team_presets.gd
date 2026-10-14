extends Node
## M2 Team presets: data layer (limits, sanitising, persistence round trip through MetaState /
## SaveStore), the screen (empty / grid / locked slots / missing Axie / editor / delete confirm /
## samples / guest) and the Run Setup hooks (Load preset, Save as preset, Leaderboard button).

var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _screen() -> TeamPresetsScreen:
	var s: TeamPresetsScreen = load("res://scenes/team_presets/TeamPresets.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	add_child(s)
	await get_tree().process_frame
	return s


func _party(a := "plant1", b := "beast1", c := "aqua1", d := "reptile1", e := "bug1") -> Array:
	return [a, b, c, d, e]


func _ready() -> void:
	print("=== t_team_presets: start ===")
	_guard.capture()
	MetaState.team_presets = []
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	MainMenu.pending_team = []

	# ---- data layer
	_ok(TeamPresets.slots_for_tier(1) == 3 and TeamPresets.slots_for_tier(2) == 6 and TeamPresets.slots_for_tier(3) == 9, "slots by tier 3/6/9")
	_ok(TeamPresets.slot_count() == 3, "Savannah has 3 slots")
	for t in [[1, 3], [2, 6], [3, 9]]:
		TeamPresets.tier_override = t[0]
		_ok(TeamPresets.slot_count() == t[1], "tier %d -> %d slots" % [t[0], t[1]])
	TeamPresets.tier_override = 0
	_ok(TeamPresets.add("Thorn Wall", _party()) == "", "add ok")
	_ok(TeamPresets.add("", _party()) != "", "empty name refused")
	_ok(TeamPresets.add("x", ["plant1", "", "", "", ""]) != "", "incomplete party refused")
	_ok(TeamPresets.add("x", _party("plant1", "plant1")) != "", "duplicate seat refused")
	_ok(TeamPresets.add("A very long preset name indeed", _party()) == "", "long name accepted (trimmed)")
	_ok(String((MetaState.team_presets[1] as Dictionary)["name"]).length() == 16, "name trimmed to 16")
	_ok(TeamPresets.add("Third", _party()) == "", "third fits")
	_ok(TeamPresets.add("Fourth", _party()) != "", "no room at Savannah")
	_ok(TeamPresets.copy(0) != "", "copy refused when full")
	TeamPresets.remove(2)
	_ok(TeamPresets.copy(0) == "" and String((MetaState.team_presets[2] as Dictionary)["name"]) == "Thorn Wall 2", "copy into free slot")
	_ok(TeamPresets.move(2, -1) == 1 and String((MetaState.team_presets[1] as Dictionary)["name"]) == "Thorn Wall 2", "move up")
	_ok(TeamPresets.move(0, -1) == 0, "cannot move past the top")
	_ok(TeamPresets.update(0, "Renamed", _party()) == "" and String((MetaState.team_presets[0] as Dictionary)["name"]) == "Renamed", "update")
	_ok(TeamPresets.sanitize_list([{"name": "A", "party": ["plant1"]}, 5, {"name": "", "party": []}]).size() == 1, "sanitize drops junk")
	_ok((TeamPresets.sanitize_list([{"name": "A", "party": ["plant1"]}])[0]["party"] as Array).size() == 5, "sanitize pads to 5")

	# ---- persistence: write to disk, reload, same list
	MetaState.save_to_disk()
	var before := JSON.stringify(MetaState.team_presets)
	MetaState.team_presets = []
	MetaState.reload_from_store()
	_ok(JSON.stringify(MetaState.team_presets) == before and MetaState.team_presets.size() == 3, "presets survive reload_from_store")

	# ---- missing Vault Axie
	var ghost := ["plant1", "beast1", "vault_999999", "reptile1", "bug1"]
	_ok(TeamPresets.missing_count({"party": ghost}) == 1, "unknown vault key counts as missing")
	_ok(TeamPresets.usable_party({"party": ghost})[2] == "", "missing seat blanked")
	_ok(TeamPresets.has_nft({"party": ghost}), "vault key = NFT tag")

	# ---- screen: grid
	var s := await _screen()
	_ok(s.find_child("Grid", true, false) != null, "grid built")
	_ok(s.find_child("Preset0", true, false) != null and s.find_child("Preset2", true, false) != null, "3 preset cards")
	_ok(s.find_child("Locked4", true, false) != null and s.find_child("Locked9", true, false) != null, "slots 4..9 drawn locked")
	_ok((s.find_child("Locked4", true, false).find_children("*", "Label", true, false).any(func(l): return (l as Label).text == "Opens at Forest Land")), "slot 4 names Forest")
	_ok((s.find_child("Locked7", true, false).find_children("*", "Label", true, false).any(func(l): return (l as Label).text == "Opens at Arctic Land")), "slot 7 names Arctic")
	# use for next run
	_ok(s.use_preset(0), "use_preset ok")
	_ok(MainMenu.pending_team.size() == 5 and MainMenu.pending_team[0] == "plant1", "party handed to Run Setup")
	# delete confirm: focus on Keep it, decline leaves data
	s.request_delete(1)
	await get_tree().process_frame
	await get_tree().process_frame
	var keep := s.find_child("Keep", true, false) as Button
	_ok(keep != null and keep.has_focus(), "delete confirm focuses Keep it")
	_ok(is_equal_approx(s.find_child("Confirm", true, false).find_children("*", "PanelContainer", true, false)[0].custom_minimum_size.x, 600.0), "confirm 600 wide")
	keep.pressed.emit()
	_ok(TeamPresets.count() == 3, "Keep it keeps")
	s.request_delete(1)
	(s.find_child("Do", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_ok(TeamPresets.count() == 2, "Delete removes")
	# editor
	s.open_editor(-1)
	await get_tree().process_frame
	_ok(s.view == "editor" and (s.find_child("Save", true, false) as Button).disabled, "new editor: Save disabled")
	_ok((s.find_child("Save", true, false) as Button).text.contains("Give the team a name"), "reason shown: name")
	s.set_edit_name("Fresh")
	_ok(s.save_block_reason() == "Fill slot 1 first", "reason: slot 1")
	for i in 4:
		_ok(s.set_edit_seat(i, _party()[i]), "seat %d set" % i)
	_ok(s.save_block_reason() == "Fill slot 5 first", "reason: slot 5")
	_ok(not s.set_edit_seat(4, "plant1"), "duplicate seat refused in editor")
	_ok(not s.set_edit_seat(4, "vault_1"), "unplayable seat refused")
	_ok(s.set_edit_seat(4, "bug1") and s.save_block_reason() == "", "complete -> can save")
	_ok(s.save_editor() and TeamPresets.count() == 3 and s.view == "grid", "saved, back to grid")
	# full: editor refuses new
	s.open_editor(-1)
	s.set_edit_name("Nope")
	for i in 5:
		s.set_edit_seat(i, _party()[i])
	_ok(s.save_block_reason() == "All preset slots are used", "no room reason")
	s.cancel_editor()
	# replace missing
	MetaState.team_presets[0]["party"] = ghost
	s.refresh()
	_ok((s.find_child("Preset0", true, false).find_child("Use", true, false) as Button).text == "Pick a replacement", "missing -> Pick a replacement")
	_ok(not s.use_preset(0), "cannot use a preset with a missing Axie")
	s.open_editor(0)
	_ok(s.edit_party[2] == "", "editor shows the gap")
	s.cancel_editor()
	# samples tab
	s.switch_tab("samples")
	_ok(s.find_children("UseSample", "Button", true, false).size() == 4, "four sample teams")
	s.use_sample(0)
	_ok(MainMenu.pending_team.size() == 5, "sample handed to Run Setup")
	# reorder
	s.switch_tab("mine")
	var first := String((MetaState.team_presets[0] as Dictionary)["name"])
	s.reorder(0, 1)
	_ok(String((MetaState.team_presets[1] as Dictionary)["name"]) == first, "reorder 0 -> 1")
	# keyboard: E edits the focused preset, S / M switch tab
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_S
	s._unhandled_key_input(ev)
	_ok(s.tab == "samples", "S opens Sample teams")
	ev = InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_M
	s._unhandled_key_input(ev)
	_ok(s.tab == "mine", "M opens My teams")
	s._focus_idx = 1
	ev = InputEventKey.new()
	ev.pressed = true
	ev.keycode = KEY_E
	s._unhandled_key_input(ev)
	_ok(s.view == "editor" and s.edit_index == 1, "E edits the focused preset")
	s.cancel_editor()
	# more slots at higher tier
	TeamPresets.tier_override = 2
	s.refresh()
	_ok(s.find_child("Open4", true, false) != null and s.find_child("Locked7", true, false) != null, "tier 2: slots 4-6 open, 7+ locked")
	TeamPresets.tier_override = 0
	s.queue_free()

	# ---- empty + guest
	MetaState.team_presets = []
	var e := await _screen()
	_ok(e.find_child("Empty", true, false) != null and e.find_child("BuildFirst", true, false) != null, "empty state")
	_ok(e.find_child("Banner", true, false) == null, "no banner when signed in")
	e.guest = true
	e.refresh()
	_ok(e.find_child("Banner", true, false) != null, "guest banner")
	e.queue_free()

	# ---- Run Setup hooks
	MetaState.team_presets = []
	MetaState.asc_max = 3
	MainMenu.pending_team = []
	var rs: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	rs.use_account = false
	rs.no_scene_change = true
	add_child(rs)
	await get_tree().process_frame
	_ok(not (rs.find_child("LoadPreset", true, false) as Button).disabled, "Load preset enabled")
	_ok(not (rs.find_child("SavePreset", true, false) as Button).disabled, "Save preset enabled")
	_ok(not (rs.find_child("LeaderboardBtn", true, false) as Button).disabled, "Leaderboard enabled for non-newcomer")
	_ok(rs.save_preset("Run Setup team") == "" and TeamPresets.count() == 1, "save current party")
	rs.clear_slot(2)
	_ok(rs.save_preset("Half") != "", "incomplete party cannot be saved")
	_ok(rs.load_preset(0) and rs.filled_count() == 5, "load fills party")
	rs.open_save_preset()
	await get_tree().process_frame
	var sv := rs.find_child("ConfirmSavePreset", true, false) as Button
	_ok(sv != null and not sv.disabled, "save modal ready with full party")
	rs.close_modal()
	rs.clear_slot(0)
	rs.open_save_preset()
	await get_tree().process_frame
	_ok((rs.find_child("ConfirmSavePreset", true, false) as Button).disabled, "save modal disabled with a gap")
	rs.open_load_presets()
	await get_tree().process_frame
	_ok(rs.find_child("Preset0", true, false) != null, "load modal lists the preset")
	rs.queue_free()
	# newcomer: Leaderboard stays locked
	MetaState.runs = 0
	MetaState.runs_with_battle = 0
	var nb: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	nb.use_account = false
	nb.no_scene_change = true
	add_child(nb)
	await get_tree().process_frame
	_ok((nb.find_child("LeaderboardBtn", true, false) as Button).disabled, "newcomer: Leaderboard locked in Run Setup")
	nb.queue_free()

	# ---- routing
	_ok(LandNav.resolve(&"team_presets") == "res://scenes/team_presets/TeamPresets.tscn", "LandNav team_presets")
	_ok(LandNav.resolve(&"leaderboard") == "res://scenes/leaderboard/Leaderboard.tscn", "LandNav leaderboard")

	_guard.restore()
	for m in _fail:
		print("FAIL: ", m)
	if _fail.is_empty():
		print("PASS: t_team_presets (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		get_tree().quit(1)
