extends Node
## UI-05 b23 lane S6: the Result screen against frames 10-result--* (ui05-meta1-screens.html).
## 1. Every data-name of the win / loss / mission / ranked / copied states exists as a node of that name.
## 2. Win and loss, with and without a new title, at 1920 (scale 1.0) and 1280 (scale 2/3): plate width is the
##    result_plate_w token (640 / 520), the plate stays inside the window, text is >= 14 real px at 1280.
## 3. Icon / label centring is measured (> 0 pairs) in the Shard card.
## 4. Numbers come from the run, not from the design: no filler string of the HTML is in the scene.
## 5. "Shards" (not "Shard") for amounts in the stake box and the Defeat panel source.
## Run: godot --headless --path godot res://tests/t_ui5_result.tscn

const Align := preload("res://tests/ui5_align_check.gd")
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bird1"]
const FILLER := ["777006", "4,967", "7,240", "[A5 title]", "Leaf Tumble", "420 XP"]
const WIN_NAMES := ["ResultBackground_or_PlateHost", "Scrim", "ResultPlate", "Title", "SubLine", "PartyRow", "StatGrid", "CardScroll",
	"ShardCard", "PassCard", "XpDisc", "CoresCard", "CombosCard", "Actions", "RunAgainButton", "CopyButton", "BackButton", "KeyCap"]

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _stage(won: bool, ranked: bool, mission: bool, power: int) -> Node:
	RunState.start_new_run(777001, TEAM, "short", 5, ranked)
	RunState.power_level = power
	RunState.shards_this_run = 87
	RunState.run_stats = {"dmg": 913, "dmg_dealt_clamped": 913, "taken": 140, "turns": 41, "kills": 23, "max_hit": 31}
	if mission:
		RunState.mission = {"mission_id": "m_t", "condition": ""}
		MetaState.mission_escrow = {"mission_id": "m_t", "tier": "N3", "stake": 800, "payout": 7240, "stone": 14}
	else:
		RunState.mission = {}
		MetaState.mission_escrow = {}
	RunState.set_phase(RunState.RunPhase.WON if won else RunState.RunPhase.LOST)
	var v: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(v)
	for _i in 6:
		await get_tree().process_frame
	return v


func _free(v: Node) -> void:
	v.queue_free()
	await get_tree().process_frame
	RunState.mission = {}
	MetaState.mission_escrow = {}


func _texts(n: Node, out: Array) -> void:
	if n is Label:
		out.append((n as Label).text)
	elif n is Button:
		out.append((n as Button).text)
	for c in n.get_children():
		_texts(c, out)


func _geometry(v: Node, tag: String, scale: float) -> void:
	var plate := v.find_child("ResultPlate", true, false) as Control
	var vp := (v as Control).get_viewport_rect().size
	var want := UI3Theme.size_of("result_plate_w")
	_check(absf(plate.size.x - want) <= 1.0, "%s: plate is result_plate_w wide (%s vs %s)" % [tag, plate.size.x, want])
	_check(plate.global_position.y >= 0.0 and plate.global_position.y + plate.size.y <= vp.y + 0.5, "%s: plate inside the window" % tag)
	var foot := v.find_child("Actions", true, false) as Control
	_check(foot.global_position.y + foot.size.y <= vp.y + 0.5, "%s: actions inside the window" % tag)
	var back := v.find_child("BackButton", true, false) as Button
	_check(back.has_focus(), "%s: Back has focus" % tag)
	var cap := v.find_child("KeyCap", true, false) as Control
	_check(cap != null and cap.get_global_rect().end.x <= back.get_global_rect().end.x, "%s: keycap inside the Back button" % tag)
	var psb := plate.get_theme_stylebox("panel")
	_check(psb is StyleBoxFlat and (psb as StyleBoxFlat).border_width_left > 0 and (psb as StyleBoxFlat).bg_color.a > 0.85, "%s: plate keeps the dialog look (rim, opaque)" % tag)
	var bsb := back.get_theme_stylebox("normal")
	_check(bsb is StyleBoxFlat and (bsb as StyleBoxFlat).bg_color == UI3Theme.color("accent"), "%s: Back keeps the amber fill" % tag)
	_check(psb.content_margin_left == 24 and psb.content_margin_right == 24 and psb.content_margin_top == 24 and psb.content_margin_bottom == 20, "%s: plate padding 24/24/20" % tag)
	var bf := back.get_theme_font("font")
	var tw := bf.get_string_size(back.text, HORIZONTAL_ALIGNMENT_LEFT, -1, back.get_theme_font_size("font_size")).x
	var group_l := back.global_position.x + (cap.global_position.x - back.global_position.x) - UI3Theme.space("12") - tw
	var group_r := cap.get_global_rect().end.x
	_check(absf((group_l + group_r) / 2.0 - back.get_global_rect().get_center().x) <= 2.0, "%s: label + keycap group centred on the button (%.1f vs %.1f)" % [tag, (group_l + group_r) / 2.0, back.get_global_rect().get_center().x])
	_check(float(back.get_theme_font_size("font_size")) * scale >= 14.0 - 0.01, "%s: button text >= 14 real px" % tag)
	var small := 0
	var low := ""
	for l in v.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.is_visible_in_tree() and lab.text != "" and float(lab.get_theme_font_size("font_size")) * scale < 14.0 - 0.01:
			small += 1
			low = lab.text
	_check(small == 0, "%s: %d label(s) under 14 real px, e.g. '%s'" % [tag, small, low])
	# nothing drawn outside the plate sideways
	for l in v.find_children("*", "Label", true, false):
		var lab := l as Label
		if lab.is_visible_in_tree() and lab.text != "" and lab.name != "VersionTag":
			var r := lab.get_global_rect()
			if r.size.x > 1.0 and (r.position.x < plate.global_position.x - 1.0 or r.end.x > plate.global_position.x + plate.size.x + 1.0):
				_check(false, "%s: '%s' leaves the plate sideways" % [tag, lab.text.left(30)])
				break


func _ready() -> void:
	print("=== t_ui5_result: start ===")
	_guard.capture()
	await get_tree().process_frame
	CombatView.disable_juice_for_tests = true
	var title_id := String(TitleNames.ascension_titles()[0]["id"])
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		var tag := "1920" if sc == 1.0 else "1280"
		# win + best chip
		MetaState.best = 1
		var v := await _stage(true, true, false, 12)
		for n in WIN_NAMES:
			if n == "ResultBackground_or_PlateHost":
				_check(v.find_child("PlateHost", true, false) != null, "win: backdrop")
			else:
				_check(v.find_child(n, true, false) != null, "%s win: node %s" % [tag, n])
		for n in ["NewBestChip", "SaveRecordButton", "SubmitLine"]:
			_check(v.find_child(n, true, false) != null, "%s ranked win: node %s" % [tag, n])
		_check(v.find_child("StakeBox", true, false) == null, "%s: no stake box on a normal run" % tag)
		_geometry(v, tag + " win", sc)
		var probs := Align.check(v.find_child("ShardCard", true, false), 1.5, tag + ": ")
		_check(Align.pairs(v.find_child("ShardCard", true, false)) > 0, "%s: align check measured no pair" % tag)
		for p in probs:
			_check(false, p)
		var all: Array = []
		_texts(v, all)
		var joined := "\n".join(all)
		for f in FILLER:
			_check(not joined.contains(f), "%s: filler string '%s' on screen" % [tag, f])
		_check(joined.contains("+87") and joined.contains("Seed 777001"), "%s: run numbers come from the run" % tag)
		# save record -> SavedLine; copy -> CopiedLine
		var save := v.find_child("SaveRecordButton", true, false) as Button
		save.pressed.emit()
		await get_tree().process_frame
		_check(v.find_child("SavedLine", true, false) != null and v.find_child("ToneDisc", true, false) != null, "%s: SavedLine with ToneDisc" % tag)
		(v.find_child("CopyButton", true, false) as Button).pressed.emit()
		await get_tree().process_frame
		_check(v.find_child("CopiedLine", true, false) != null, "%s: CopiedLine" % tag)
		# new title row (built the way _ready does, from a real title id)
		var row: Control = v.call("_build_title_unlock", {"new_titles": [title_id]})
		_check(row != null and row.name == "NewTitleRow" and row.size_flags_horizontal == Control.SIZE_FILL, "%s: NewTitleRow stretched" % tag)
		if row != null:
			row.free()
		for f in await _clean_user_files():
			pass
		await _free(v)
		# loss, unranked
		v = await _stage(false, false, false, 7)
		_check((v.find_child("Title", true, false) as Label).text == "Defeated", "%s: loss says Defeated" % tag)
		_check(v.find_child("NewBestChip", true, false) == null and v.find_child("SaveRecordButton", true, false) == null, "%s: loss has no chip / save" % tag)
		_geometry(v, tag + " loss", sc)
		await _free(v)
		# mission won / lost
		v = await _stage(true, false, true, 3)
		var sb := v.find_child("StakeBox", true, false)
		_check(sb != null and sb.get_index() == 0, "%s: StakeBox is the first card" % tag)
		_check(sb != null and (sb.find_child("StakeText", true, false) as Label).text.contains("800 Shards stake"), "%s: stake text says Shards" % tag)
		_geometry(v, tag + " mission", sc)
		await _free(v)
		v = await _stage(false, false, true, 3)
		sb = v.find_child("StakeBox", true, false)
		_check(sb != null and (sb.find_child("StakeText", true, false) as Label).text.contains("lose your 800 Shards stake (−800 Shards)"), "%s: lost stake text" % tag)
		await _free(v)
	UI3Theme.set_scale_override(-1.0)
	# 5. source strings
	for path in ["res://scenes/result/ResultView.gd", "res://scenes/combat/DefeatPanel.gd"]:
		var src := FileAccess.get_file_as_string(path)
		_check(not src.contains("Shard stake"), "%s has no singular 'Shard stake'" % path)
	_guard.restore()
	print("=== t_ui5_result: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_result: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_ui5_result: FAIL - %s" % f)
	get_tree().quit(1)


func _clean_user_files() -> Array:
	for f in DirAccess.get_files_at("user://"):
		if f.begins_with("run_record_"):
			DirAccess.remove_absolute("user://" + f)
	return []
