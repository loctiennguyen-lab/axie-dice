extends Node
## UI-05 b23 lane S10: Season Pass (round-3 frames 21-pass--*), 1920 and 1280 (scale 0.667).
## Data-names exist, nothing picked at first, states (live, claimed, popup, loop, over, offline, guest, before),
## text >= 14 real px, icon/label centring measured on > 0 pairs, no illustration value of the HTML frames in the script.
## Run: AXIE_TEST_NO_NET=1 godot --headless --path godot res://tests/t_ui5_pass.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const NAMES := ["Header", "BackButton", "Title", "SubLine", "Body", "LevelCard", "ClaimAllButton", "TasksTitle", "Tasks",
	"TaskCard", "TrackGrid", "PassTile", "TileButton", "PremiumRow", "LoopRow", "LoopClaimButton", "DetailPlate"]
const ILLUSTRATION := ["Vine Wreath", "100 / 900", "90 Gem", "Level 10"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_ui5_pass: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	ProjectSettings.set_setting("axie/gem_wallet", "local")
	for sc: float in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _pass(sc, "1920" if sc == 1.0 else "1280")
	UI3Theme.set_scale_override(1.0)
	_source_check()
	_guard.restore()
	if _fails.is_empty():
		print("t_ui5_pass: PASS (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui5_pass: FAIL - ", f)
		get_tree().quit(1)


func _make(sc: float, day: String, xp: int, claimed: Array, state := "normal") -> PassView:
	MetaState.pass_season = PassV2.new_state("s1")
	MetaState.pass_season["xp"] = xp
	MetaState.pass_season["claimed_free"] = claimed.duplicate()
	var host := Control.new()
	host.size = Vector2(1920, 1080) * sc
	add_child(host)
	var s: PassView = load("res://scenes/pass/Pass.tscn").instantiate()
	s.use_account = false
	s.state = state
	s.no_scene_change = true
	s.today_override = day
	host.add_child(s)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 4:
		await get_tree().process_frame
	return s


func _settle() -> void:
	for i in 3:
		await get_tree().process_frame


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


func _audit(s: Node, sc: float, tag: String) -> void:
	_text(s, sc, tag)
	for pr in Align.check(s, 1.5, tag + ": "):
		_check(false, pr)


func _texts(root: Node) -> String:
	var out := ""
	for l in root.find_children("*", "Label", true, false):
		out += (l as Label).text + "\n"
	for b in root.find_children("*", "Button", true, false):
		out += (b as Button).text + "\n"
	return out


func _pass(sc: float, tag: String) -> void:
	# live: level 10 (xp_total 6800 is level 10 or more in the table), 1-7 claimed
	var lvl10 := int(PassV2.level_def(10).get("xp_total", 0))
	var s := await _make(sc, "2026-11-10", lvl10 + 100, [1, 2, 3, 4, 5, 6, 7])
	for n in NAMES:
		_check(s.find_child(n, true, false) != null, "%s: node %s exists" % [tag, n])
	_check(s.find_children("PassTile*", "PanelContainer", true, false).size() == 30, "%s: 30 PassTile" % tag)
	_check(s.find_children("TileButton*", "Button", true, false).size() == 30, "%s: 30 TileButton" % tag)
	_check(s.find_children("TaskCard*", "PanelContainer", true, false).size() == 3, "%s: 3 TaskCard" % tag)
	var dp := s.find_child("DetailPlate", true, false) as Ui5DetailPlate
	_check(dp.is_empty() and dp.title.text == "Pick a level", "%s: opens with 'Pick a level'" % tag)
	_check(s.selected_lv == 0, "%s: nothing preselected" % tag)
	_check(Ui5Keycap.all_under(dp).is_empty(), "%s: no keycap on the disabled primary" % tag)
	var ca := s.find_child("ClaimAllButton", true, false) as Button
	var n := s.claimable_count()
	_check(n == 3 and not ca.disabled and ca.text == "Claim all · 3 levels", "%s: Claim all '%s'" % [tag, ca.text])
	_check(get_viewport().gui_get_focus_owner() != null, "%s: initial focus exists" % tag)
	_check(s.tile_button(1).text == "Claimed" and s.tile_button(1).disabled and s.tile_button(1).icon != null, "%s: claimed = tick + Claimed" % tag)
	_check(s.tile_button(8).text == "Claim" and not s.tile_button(8).disabled, "%s: ready tile says Claim" % tag)
	_check(s.tile_button(8).theme_type_variation != &"ButtonPrimary", "%s: tile Claim is secondary while Claim all is live" % tag)
	_check(s.tile_button(20).text == "Reach Level 20", "%s: locked tile text" % tag)
	_check(s.tile_button(11).text.begins_with("Next · needs "), "%s: next tile text" % tag)
	_audit(s, sc, tag + " live")
	# pick a level
	s.select_level(9)
	await _settle()
	var cl := s.find_child("ClaimLevelButton", true, false) as Button
	_check(cl != null and cl.text == "Claim level 9" and not cl.disabled, "%s: ClaimLevelButton for 9" % tag)
	_check(not dp.is_empty() and dp.title.text == "Level 9", "%s: detail title" % tag)
	_check(Align.pairs(s) > 0, "%s: align check measured no icon / label pair" % tag)
	_audit(s, sc, tag + " picked")
	s.select_level(20)
	await _settle()
	cl = s.find_child("ClaimLevelButton", true, false) as Button
	_check(cl.disabled and cl.text == "Reach Level 20" and Ui5Keycap.all_under(cl).is_empty(), "%s: locked level says why, no keycap" % tag)
	s.select_level(1)
	await _settle()
	cl = s.find_child("ClaimLevelButton", true, false) as Button
	_check(cl.disabled and cl.text == "Claimed", "%s: claimed level: 'Claimed'" % tag)
	# popup
	s.open_reward(8)
	await _settle()
	var pop := s.find_child("LevelPopup", true, false)
	_check(pop != null and pop.find_child("CloseButton", true, false) != null and pop.find_child("ClaimButton", true, false) != null, "%s: popup has Close + Claim" % tag)
	var pc := pop.find_child("ClaimButton", true, false) as Button
	_check(not Ui5Keycap.all_under(pc).is_empty() and Ui5Keycap.text_of(Ui5Keycap.all_under(pc)[0] as PanelContainer) == "Space", "%s: popup Claim has the Space keycap" % tag)
	_check(Ui5Keycap.all_under(pop.find_child("CloseButton", true, false)).is_empty(), "%s: Close has no keycap" % tag)
	_audit(s, sc, tag + " popup")
	(pop.find_child("CloseButton", true, false) as Button).pressed.emit()
	await _settle()
	_check(s.find_child("LevelPopup", true, false) == null, "%s: Close closes the popup" % tag)
	# claim all -> ResultLine
	ca = s.find_child("ClaimAllButton", true, false) as Button
	ca.pressed.emit()
	await _settle()
	_check(s.find_child("ResultLine", true, false) != null and s.find_child("ResultLine", true, false).find_child("ToneDisc", true, false) != null, "%s: ResultLine with ToneDisc" % tag)
	ca = s.find_child("ClaimAllButton", true, false) as Button
	_check(ca.disabled and ca.text == "Claim all · Nothing to claim", "%s: Claim all off, says nothing to claim" % tag)
	_audit(s, sc, tag + " claimed")
	# weekly states
	var wk := PassV2.week_key("2026-11-10")
	MetaState.pass_season["weekly"] = {wk: {"runs": 5, "wins": 2, "boss": 0, "claimed": ["win_runs"]}}
	s.refresh()
	await _settle()
	_check(s.task_button("play_runs").text == "Claim" and not s.task_button("play_runs").disabled, "%s: task ready" % tag)
	_check(s.task_button("win_runs").text == "Claimed" and s.task_button("win_runs").disabled, "%s: task claimed" % tag)
	_check(s.task_button("reach_boss").text == "Claim · Task not finished", "%s: task unfinished reason" % tag)
	s.queue_free()
	s.get_parent().queue_free()
	# loop
	var lp := await _make(sc, "2026-11-10", 200000, range(1, 31))
	var lb := lp.find_child("LoopClaimButton", true, false) as Button
	_check(not lb.disabled and lb.text.begins_with("Claim ") and lb.text.ends_with(" Shards"), "%s: loop claim '%s'" % [tag, lb.text])
	_check(lp.find_child("LoopText", true, false).text.contains("Shards"), "%s: loop text says Shards" % tag)
	_audit(lp, sc, tag + " loop")
	lp.get_parent().queue_free()
	# over / offline / guest / before
	var o := await _make(sc, "2027-01-05", lvl10 + 100, [1, 2, 3])
	_check(o.find_child("Banner", true, false) != null and o.tile_button(30).text == "Not claimed", "%s: over: banner, Not claimed" % tag)
	_check(o.task_button("play_runs").text == "Claim · The season is not running", "%s: over: task reason" % tag)
	_audit(o, sc, tag + " over")
	o.get_parent().queue_free()
	for st in ["offline", "guest"]:
		var g := await _make(sc, "2026-11-10", lvl10 + 100, [1, 2, 3], st)
		_check(g.find_child("Banner", true, false) != null and g.find_child("Banner", true, false).find_child("ToneDisc", true, false) != null, "%s: %s banner with ToneDisc" % [tag, st])
		_audit(g, sc, tag + " " + st)
		g.get_parent().queue_free()
	var b := await _make(sc, "2026-10-12", 0, [])
	_check(b.find_child("Banner", true, false) != null and (b.find_child("ClaimAllButton", true, false) as Button).disabled, "%s: before: banner, Claim all off" % tag)
	_check((b.task_button("play_runs") as Button).text == "Claim · The season is not running", "%s: before: task reason" % tag)
	_audit(b, sc, tag + " before")
	b.get_parent().queue_free()
	await get_tree().process_frame


func _source_check() -> void:
	for p in ["res://scenes/pass/PassView.gd", "res://scenes/pass/ui5/PassParts.gd"]:
		var src := FileAccess.get_file_as_string(p)
		for w in ILLUSTRATION:
			_check(not src.contains(w), "%s has no illustration value '%s'" % [p, w])
		for old in ["Reach LV", "\"CLAIM\"", "Shard\""]:
			_check(not src.contains(old), "%s has no old string %s" % [p, old])
