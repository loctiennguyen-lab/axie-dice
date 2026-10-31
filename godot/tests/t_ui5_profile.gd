extends Node
## UI-05 b23 lane S12: Profile (frames 24-profile*). data-names exist per tab, tabs switch, equip of skin / frame / title writes
## MetaState, nothing is preselected except the item really equipped, 1920 + 1280, everything inside the 1920x1080 logical frame,
## text >= 14 real px at 1280, no illustrative values, initial focus on a tab, align check measured > 0 pairs.
## Run: godot --headless --path godot res://tests/t_ui5_profile.tscn

const Align := preload("res://tests/ui5_align_check.gd")

class StubService extends Node:
	signal changed
	var status: int = AccountService.Status.SAVED
	var account: Dictionary = {}
	func is_signed_in() -> bool: return not account.is_empty()
	func display_name() -> String: return String(account.get("name", ""))

const HEAD := ["Header", "BackButton", "Title", "SubLine", "OverviewTab", "CosmeticsTab", "TitlesTab", "Body"]
const OVERVIEW := ["StatTiles", "StatTile_Runs", "LandSection", "RunList", "ProfileCard", "Avatar", "Name", "TitleLine", "SyncChip"]
const COSM := ["CategoryTabs", "DiceTab", "FramesTab", "Grid", "CosmeticTile", "EquippedDisc", "PreviewPlate", "Preview3D", "EquipButton"]
const TITLES := ["TitleGrid", "TitleTile", "UseDefaultButton", "EquipButton", "ProfileCard"]
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
var _svc: StubService


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_ui5_profile: start ===")
	_guard.capture()
	await get_tree().process_frame
	MetaState.reload_from_store()
	MetaState.run_log = []
	MetaState.runs = 0
	MetaState.wins = 0
	MetaState.asc_wins = {}
	MetaState.profile_stats = {"pure_wins": 0, "ms_played": 0, "ms_won": 0}
	MetaState.cosmetics_owned.clear()
	MetaState.equipped_die_skin = ""
	MetaState.equipped_frame = ""
	MetaState.equipped_title = ""
	_svc = StubService.new()
	add_child(_svc)
	for sc in [1.0, 2.0 / 3.0]:
		await _screens(sc)
	UI3Theme.set_scale_override(1.0)
	await _equips()
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	print("=== t_ui5_profile: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_profile: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_ui5_profile: FAIL - " + f)
	get_tree().quit(1)


func _open() -> ProfileView:
	var pv: ProfileView = (load("res://scenes/profile/Profile.tscn") as PackedScene).instantiate()
	pv.service = _svc
	pv.no_scene_change = true
	add_child(pv)
	for _i in 6:
		await get_tree().process_frame
	return pv


func _names(v: Node, names: Array, tag: String) -> void:
	for n in names:
		_check(v.find_child(n + "*", true, false) != null, "[%s] node '%s' exists" % [tag, n])


## Every visible control outside a scroll lies inside the 1920x1080 logical frame; texts are >= 14 real px at 1280.
func _frame_checks(v: Node, sc: float, tag: String) -> void:
	var win := Rect2(0, 0, 1920.0, (v as Control).size.y).grow(1.0)   # headless window height is not 1080: use the view
	var bad: Array[String] = []
	var all := ""
	for n in v.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree():
			continue
		var p := c.get_parent()
		var in_scroll := false
		while p != null and p != v:
			if p is ScrollContainer:
				in_scroll = true
			p = p.get_parent()
		if not in_scroll and c.size.x > 0.0 and not win.encloses(c.get_global_rect()) and not (c is ScrollContainer):
			bad.append("%s %s" % [c.name, c.get_global_rect()])
		if c is Label:
			all += (c as Label).text + "\n"
			if sc < 1.0 and (c as Label).text.strip_edges() != "":
				_check(float((c as Label).get_theme_font_size("font_size")) * sc >= 14.0 - 0.01, "[%s] '%s' >= 14 real px" % [tag, (c as Label).text.left(20)])
		elif c is Button and sc < 1.0:
			_check(float((c as Button).get_theme_font_size("font_size")) * sc >= 14.0 - 0.01, "[%s] button '%s' >= 14 real px" % [tag, (c as Button).text])
	_check(bad.is_empty(), "[%s] inside the frame: %s" % [tag, ", ".join(bad.slice(0, 4))])
	for s in ["Liam", "[A5", "[A10", "12 finished", "58%"]:
		_check(not all.contains(s), "[%s] no illustrative value '%s'" % [tag, s])
	var probs := Align.check(v)
	_check(probs.is_empty(), "[%s] align: %s" % [tag, "; ".join(probs)])


func _screens(sc: float) -> void:
	UI3Theme.set_scale_override(sc)
	var tag := "%.2f" % sc
	_svc.account = {"name": "Mai", "sky_mavis": true}
	MetaState.record_run_outcome({"mode": "short", "ascension": 5, "kind": "normal", "aid_used": 0, "mission_id": ""}, true)
	MetaState.record_run_outcome({"mode": "full", "ascension": 3, "kind": "ranked", "aid_used": 2, "mission_id": ""}, false)
	MetaState.runs = 2
	MetaState.wins = 1
	var v := await _open()
	_names(v, HEAD + OVERVIEW, tag)
	_check(v.find_children("RunRow_*", "PanelContainer", true, false).size() == 2, "[%s] 2 RunRows" % tag)
	_check(v.find_children("StatTile_*", "PanelContainer", true, false).size() == 5, "[%s] 5 StatTiles" % tag)
	var card := v.find_child("ProfileCard", true, false) as Control
	_check(card != null and absf(card.size.x - float(UI3Theme.size_of("profile_detail_w"))) < 1.0, "[%s] ProfileCard wide profile_detail_w (%s)" % [tag, card.size.x if card != null else -1.0])
	var fo := get_viewport().gui_get_focus_owner()
	_check(fo != null and String(fo.name).ends_with("Tab"), "[%s] initial focus is a tab (%s)" % [tag, fo.name if fo != null else "none"])
	_check(Align.pairs(v) > 0, "[%s] overview align pairs > 0" % tag)
	_frame_checks(v, sc, tag + " overview")
	v.set_tab(1)
	await get_tree().process_frame
	_names(v, COSM, tag)
	var pressed := 0
	for b in v.find_children("CosmeticTile_*", "Button", true, false):
		if (b as Button).button_pressed:
			pressed += 1
	_check(pressed == 1 and (v.find_child("CosmeticTile_default_die", true, false) as Button).button_pressed, "[%s] only the equipped Default tile is picked" % tag)
	var pw := v.find_child("PreviewPlate", true, false) as Control
	_check(pw != null and absf(pw.size.x - float(UI3Theme.size_of("preview_w"))) < 1.0, "[%s] PreviewPlate wide preview_w" % tag)
	_frame_checks(v, sc, tag + " cosmetics")
	(v.find_child("FramesTab", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_check(v.find_child("FramePreview", true, false) != null and v.find_children("CosmeticTile_*", "Button", true, false).size() == ProfileView.catalog("frame").size() + 1, "[%s] frames grid + FramePreview" % tag)
	_frame_checks(v, sc, tag + " frames")
	v.set_tab(2)
	await get_tree().process_frame
	_names(v, TITLES, tag)
	_check(Align.pairs(v) > 0, "[%s] titles align pairs > 0 (lock icon + name)" % tag)
	_frame_checks(v, sc, tag + " titles")
	v.queue_free()
	await get_tree().process_frame
	# empty + guest
	MetaState.run_log = []
	MetaState.runs = 0
	MetaState.wins = 0
	_svc.account = {}
	v = await _open()
	_names(v, ["GuestBanner", "ToneDisc", "SignInButton", "RunsEmpty"], tag)
	_check((v.find_child("StatTile_Runs", true, false).find_child("Value", true, false) as Label).text == "—", "[%s] empty Runs reads —" % tag)
	_check((v.find_child("Name", true, false) as Label).text == "Guest", "[%s] guest name" % tag)
	_frame_checks(v, sc, tag + " guest")
	v.queue_free()
	await get_tree().process_frame
	MetaState.run_log = []


func _equips() -> void:
	_svc.account = {"name": "Mai"}
	var dice := ProfileView.catalog("die")
	var frames := ProfileView.catalog("frame")
	MetaState.cosmetics_owned.append(dice[0])
	MetaState.cosmetics_owned.append(frames[0])
	MetaState.cosmetics_owned.append("title:Gardener")
	var v := await _open()
	v.set_tab(1)
	var eq := v.find_child("EquipButton", true, false) as Button
	_check(eq.disabled and eq.text == "Equip · Equipped", "default equipped: Equip says why")
	(v.find_child("CosmeticTile_" + dice[1], true, false) as Button).pressed.emit()
	eq = v.find_child("EquipButton", true, false) as Button
	_check(eq.disabled and eq.text == "Equip · Locked", "locked pick: Equip · Locked")
	(v.find_child("CosmeticTile_" + dice[0], true, false) as Button).pressed.emit()
	eq = v.find_child("EquipButton", true, false) as Button
	_check(not eq.disabled and eq.text == "Equip", "owned pick: Equip live")
	eq.pressed.emit()
	await get_tree().process_frame
	_check(MetaState.equipped_die_skin == dice[0], "skin equip writes MetaState")
	(v.find_child("FramesTab", true, false) as Button).pressed.emit()
	(v.find_child("CosmeticTile_" + frames[0], true, false) as Button).pressed.emit()
	(v.find_child("EquipButton", true, false) as Button).pressed.emit()
	await get_tree().process_frame
	_check(MetaState.equipped_frame == frames[0], "frame equip writes MetaState")
	# reopening: only the equipped tile is picked
	v.set_tab(0)
	v.set_tab(1)
	var on := []
	for b in v.find_children("CosmeticTile_*", "Button", true, false):
		if (b as Button).button_pressed:
			on.append(b.name)
	_check(on == [StringName("CosmeticTile_" + frames[0])], "reopen (frames category): only the equipped frame is picked %s" % [on])
	v.set_tab(2)
	var gt := v.find_child("TitleTile_title_Gardener", true, false)
	_check(gt != null, "owned Land title tile")
	(gt.find_child("EquipButton", true, false) as Button).pressed.emit()
	_check(MetaState.equipped_title == "title:Gardener", "title equip writes MetaState")
	var none := v.find_child("TitleTile_none", true, false)
	(none.find_child("UseDefaultButton", true, false) as Button).pressed.emit()
	_check(MetaState.equipped_title == "", "Use default clears the title")
	v.queue_free()
	await get_tree().process_frame
