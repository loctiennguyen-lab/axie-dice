extends Node
## UI-05 b23 lane S2: Edit Land panel (frames e01-e05) and Land upgrade (u01-u05), 1920 and 1280 (scale 0.667).
## Data-names exist, states (short / ready / confirm / current-tier 3 / max; place / craft / rewards / empty), no preselect
## on the buy button, disabled buttons say why, initial focus of the confirm is the safe Keep Stone, text >= 14 real px
## (Label + Button), everything inside 1920 logical, icon/label centring measured on > 0 pairs, no HTML illustration values.
## Run: AXIE_TEST_NO_NET=1 godot --headless --path godot res://tests/t_ui5_land_edit.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const Eco := preload("res://scripts/meta/economy_db.gd")
const UP_NAMES := ["Header", "BackButton", "Title", "StoneChip", "Body", "TierList", "TierHeader", "StoneBar", "TierRow1", "TierRow2",
	"TierRow3", "TierRow4", "TierRow5", "TierRow6", "TierSwatch", "Name", "Adds", "RowButton", "DetailPlate", "TierArt", "StateTag",
	"CostRow", "UpgradeButton"]
const EDIT_NAMES := ["EditLandPanel", "Title", "AestheticLine", "PlacedLine", "Tabs", "PlaceTab", "CraftTab", "RewardsTab", "List",
	"Tools", "RotateButton", "StoreButton", "DoneButton"]
const ILLUSTRATION := ["3,200", "26,500", "64,000", "41,200", "16,800", "Placed 4 of 32", "Aesthetic 12"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_ui5_land_edit: start ===")
	_guard.capture()
	Eco.get_table("land_tiers")["upgrade_enabled"] = true
	for sc: float in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _upgrade(sc, "1920" if sc == 1.0 else "1280")
		await _edit(sc, "1920" if sc == 1.0 else "1280")
	UI3Theme.set_scale_override(1.0)
	_source_check()
	_guard.restore()
	if _fails.is_empty():
		print("t_ui5_land_edit: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui5_land_edit: FAIL - ", f)
		get_tree().quit(1)


func _text(n: Node, sc: float, tag: String) -> void:
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return
	if n is Label or n is Button:
		var txt := (n as Label).text if n is Label else (n as Button).text
		if txt.strip_edges() != "":
			var fs := (n as Control).get_theme_font_size("font_size")
			_check(float(fs) * sc >= 13.99, "%s: '%s' is %.1f real px (< 14)" % [tag, txt.left(20), fs * sc])
	for ch in n.get_children():
		_text(ch, sc, tag)


func _inside(root: Control, sc: float, tag: String) -> void:
	var lim := Rect2(Vector2.ZERO, Vector2(1920, 1080) * sc).grow(1.0)
	for c in root.find_children("*", "Control", true, false):
		var ctl := c as Control
		if not ctl.is_visible_in_tree() or ctl is ScrollContainer or ctl.get_parent() is ScrollContainer:
			continue
		if ctl.get_parent() is Container and ctl.get_parent().get_parent() is ScrollContainer:
			continue
		var r := ctl.get_global_rect()
		if r.size.x > 0.0 and r.size.y > 0.0 and not ctl.name.begins_with("ScrollCol"):
			var par := ctl
			var skip := false
			while par != null and par != root:
				if par is ScrollContainer:
					skip = true
				par = par.get_parent() as Control
			if not skip:
				_check(lim.encloses(r), "%s: %s outside the %d frame (%s)" % [tag, ctl.name, int(1920 * sc), str(r)])


func _settle() -> void:
	for i in 4:
		await get_tree().process_frame


func _host(sc: float) -> Control:
	var host := Control.new()
	host.size = Vector2(1920, 1080) * sc
	add_child(host)
	return host


func _upgrade(sc: float, tag: String) -> void:
	MetaState.land_tier = 1
	MetaState.ledger = []
	for state in ["short", "ready", "confirm", "tier3", "max"]:
		var t := "%s upgrade %s" % [tag, state]
		match state:
			"short":
				MetaState.stone = 3200
			"ready", "confirm":
				MetaState.stone = Eco.land_tier_cost(1) + 6500
			"tier3":
				MetaState.land_tier = 3
				MetaState.stone = 64000
			"max":
				MetaState.land_tier = 6
				MetaState.stone = 41200
		var host := _host(sc)
		var s: LandUpgradeScreen = load("res://scenes/land_upgrade/LandUpgrade.tscn").instantiate()
		s.no_scene_change = true
		host.add_child(s)
		s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await _settle()
		for n in UP_NAMES:
			_check(s.find_child(n, true, false) != null, "%s: node %s exists" % [t, n])
		var up := s.find_child("UpgradeButton", true, false) as Button
		match state:
			"short":
				_check(up.disabled and up.text == "Need %s more Stone" % UI3.fmt(Eco.land_tier_cost(1) - 3200), "%s: UpgradeButton disabled with reason '%s'" % [t, up.text])
				_check(Ui5Keycap.all_under(up).is_empty(), "%s: no keycap on the disabled primary" % t)
			"ready":
				_check(not up.disabled and up.text == "Upgrade" and s.find_child("AfterRow", true, false) != null, "%s: Upgrade enabled, AfterRow" % t)
				_check(s.find_child("TierRow2", true, false).find_child("RowButton", true, false) is Button, "%s: row button" % t)
			"confirm":
				s._ask(2)
				await _settle()
				for n in ["Scrim", "UpgradeConfirm", "Title", "Body", "Footer", "KeepStoneButton", "UpgradeToButton"]:
					_check(s.find_child(n, true, false) != null, "%s: node %s exists" % [t, n])
				var keep := s.find_child("KeepStoneButton", true, false) as Button
				_check(keep.has_focus(), "%s: initial focus is Keep Stone" % t)
				_check(not Ui5Keycap.all_under(keep).is_empty() and Ui5Keycap.all_under(s.find_child("UpgradeToButton", true, false)).is_empty(), "%s: Space keycap on Keep only" % t)
				_check(MetaState.land_tier == 1, "%s: nothing bought by opening the confirm" % t)
			"tier3":
				_check(up.disabled and up.text.begins_with("Need"), "%s: tier 4 short, reason" % t)
				_check((s.find_child("TierRow1", true, false).find_child("RowButton", true, false) as Button).text == "Owned", "%s: Owned" % t)
			"max":
				_check(s.find_child("TopLine", true, false) != null and s.find_child("UpgradeButton", true, false) == null, "%s: TopLine, no button" % t)
		_text(s, sc, t)
		_inside(s, sc, t)
		_check(Align.pairs(s) > 0, "%s: centring measured no pair" % t)
		for pr in Align.check(s, 1.5, t + ": "):
			_check(false, pr)
		host.queue_free()
		await get_tree().process_frame
	# a later row names the tier to buy first
	MetaState.land_tier = 1
	MetaState.stone = 100
	var h2 := _host(sc)
	var s2: LandUpgradeScreen = load("res://scenes/land_upgrade/LandUpgrade.tscn").instantiate()
	s2.no_scene_change = true
	h2.add_child(s2)
	await _settle()
	s2._select(3)
	await _settle()
	_check((s2.find_child("UpgradeButton", true, false) as Button).text == "Upgrade Forest first", "%s: later tier reason" % tag)
	h2.queue_free()
	await get_tree().process_frame


func _edit(sc: float, tag: String) -> void:
	MetaState.land_tier = 4
	MetaState.shard_pool = 500
	MetaState.land_decor_owned = {"decor_sav_tree": 3, "decor_sav_rock": 2}
	MetaState.land_decor_placed = []
	var host := _host(sc)
	var ed := LandEdit.new()
	add_child(ed)
	ed.setup(Node3D.new(), host, null, Callable(), Callable(), Callable(), func(_a, _b = 0, _c = 0) -> void: pass, func() -> float: return 1.0)
	ed.build_ui()
	ed.enter()
	await _settle()
	for tab in ["place", "craft", "rewards", "empty"]:
		var t := "%s edit %s" % [tag, tab]
		if tab == "empty":
			MetaState.land_decor_owned = {}
			ed._set_tab("place")
		else:
			ed._set_tab(tab)
		await _settle()
		for n in EDIT_NAMES:
			_check(host.find_child(n, true, false) != null, "%s: node %s exists" % [t, n])
		var row := {"place": "DecorRow", "craft": "CraftRow", "rewards": "RewardRow", "empty": "EmptyState"}[tab]
		_check(host.find_child(row, true, false) != null, "%s: %s exists" % [t, row])
		var rot := host.find_child("RotateButton", true, false) as Button
		_check(rot.disabled and rot.text == "Rotate · pick a decor" and Ui5Keycap.all_under(rot).is_empty(), "%s: Rotate disabled, says why" % t)
		_check((host.find_child("StoreButton", true, false) as Button).text == "Store · pick a decor", "%s: Store reason" % t)
		_check(host.find_child("DoneButton", true, false).get_node_or_null("KeyCap") == null, "%s: no key printed on Done" % t)
		_text(host, sc, t)
		_check(Align.pairs(host) >= 0, "%s: align ran" % t)
		for pr in Align.check(host, 1.5, t + ": "):
			_check(false, pr)
		if tab == "place":
			_inside(host, sc, t)
	# picking a stored decor: Rotate opens, the ghost line names it
	MetaState.land_decor_owned = {"decor_sav_tree": 3}
	ed._set_tab("place")
	ed._sel_id = "decor_sav_tree"
	ed.refresh()
	await _settle()
	_check(not (host.find_child("RotateButton", true, false) as Button).disabled, "%s: Rotate enabled when a decor is picked" % tag)
	ed._show_why("", Vector2(100, 100))
	_check((host.find_child("GhostHint", true, false) as Control).visible and (host.find_child("Placing", true, false) as Label).text.begins_with("Placing: "), "%s: GhostHint says Placing" % tag)
	ed.exit()
	host.queue_free()
	ed.queue_free()
	await get_tree().process_frame


func _source_check() -> void:
	for p in ["res://scenes/land/LandEdit.gd", "res://scenes/land/ui5/LandEditParts.gd", "res://scenes/land_upgrade/LandUpgradeScreen.gd",
			"res://scenes/land_upgrade/ui5/LandUpgradeParts.gd"]:
		var src := FileAccess.get_file_as_string(p)
		for ill in ILLUSTRATION:
			_check(not src.contains(ill), "%s holds the illustration value '%s'" % [p.get_file(), ill])
