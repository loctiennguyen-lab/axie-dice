extends Node
## UI-05 b1 QA fixes (29/10):
##   B9  a name that does not fit ends in "…" even when it is short ("Pomodoro" was cut to "Pomodor"): Ui5Ellipsis
##       on its own, then the real DieCard OwnerName.
##   B7  the hit number / BIG HIT tag of a killing blow stays on screen: head() keeps the last known point of a unit
##       whose 3D slot was hidden, falls back to the plate CENTRE (not its top), and the tag is clamped into the overlay.
##   B8  the fight ending while the Your turn band runs clears that band (no Victory band on top of it).
##   B4  the ToolKey words and the StatusLine sit on a `chip` pill, readable on any biome (contrast on the chip).
## Run: godot --headless --path godot res://tests/t_ui5_qa_fixes.tscn
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []


func _t(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	UI3Theme.set_scale_override(1.0)
	_b9_fit()
	await _b9_die_card()
	await _combat_cases()
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	print("=== t_ui5_qa_fixes: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_qa_fixes: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_ui5_qa_fixes: FAIL - " + f)
	get_tree().quit(1)


# ---------------------------------------------------------------- B9

func _b9_fit() -> void:
	var f := UI3Theme.font_body()
	var px := UI3Theme.size_of("text_body")
	var full_w := f.get_string_size("Pomodoro", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	_t(Ui5Ellipsis.fit("Pomodoro", f, px, full_w + 1.0) == "Pomodoro", "fits: the whole name")
	for short_by: float in [1.0, 6.0, 12.0, 30.0]:
		var avail := full_w - short_by
		var s := Ui5Ellipsis.fit("Pomodoro", f, px, avail)
		_t(s.ends_with("…") and s.length() >= 2, "%.0f px short: '%s' ends in an ellipsis" % [short_by, s])
		_t(f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= avail + 0.5, "%.0f px short: '%s' fits %.1f" % [short_by, s, avail])
	_t(Ui5Ellipsis.fit("Pomodoro", f, px, -1.0) == "Pomodoro", "not laid out yet: no cut")
	_t(Ui5Ellipsis.fit("Elite Bulwark", f, px, f.get_string_size("Elite Bu", HORIZONTAL_ALIGNMENT_LEFT, -1, px).x + 1.0).ends_with("…"),
		"two words: cut + ellipsis too")


func _b9_die_card() -> void:
	for sc: float in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		var btn := Button.new()
		btn.toggle_mode = true
		add_child(btn)
		var content := TrayColumn.build(btn)
		btn.size = Vector2(TrayColumn.card_w(), TrayColumn.card_h())
		TrayColumn.update(content, {"name": "Pomodoro", "hp": 14, "max_hp": 14, "faces": [{"type": "dmg", "value": 2}],
			"rolled": 0, "alive": true, "part_text": "BACK", "part_word": "Back", "part_tex": UI3.icon("face_dmg")})
		for _i in 3:
			await get_tree().process_frame
		var card: DieCard = content["card"]
		var l := card.owner_name
		var f := l.get_theme_font("font")
		var px := l.get_theme_font_size("font_size")
		var drawn := f.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var tag := "DieCard %.3f" % sc
		print("t_ui5_qa_fixes: %s OwnerName shows '%s' (%.0f px in %.0f)" % [tag, l.text, drawn, l.size.x])
		_t(Ui5Ellipsis.full_text(l) == "Pomodoro", "%s: the full name is kept (%s)" % [tag, Ui5Ellipsis.full_text(l)])
		_t(l.text == "Pomodoro" or l.text.ends_with("…"), "%s: OwnerName is the whole name or ends in '…' ('%s', %.0f in %.0f)" % [tag, l.text, drawn, l.size.x])
		_t(drawn <= l.size.x + 0.5, "%s: OwnerName '%s' fits its box (%.1f in %.1f)" % [tag, l.text, drawn, l.size.x])
		btn.queue_free()
		await get_tree().process_frame
	UI3Theme.set_scale_override(1.0)


# ---------------------------------------------------------------- combat: B7, B8, B4

func _combat_cases() -> void:
	var was_juice := CombatView.disable_juice_for_tests
	CombatView.disable_juice_for_tests = false
	MetaState.runs_with_battle = 99
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 0, false)
	RunState.power_level = 3
	RunState.enter_node("r4_c0", "battle")
	var v: CombatView = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(v)
	for _i in 6:
		await get_tree().process_frame
	var vp := get_viewport().get_visible_rect()

	# B8: a Your turn band is up (the turn just started); the fight is won -> the band goes.
	U5Moments.turn_banner(v, true)
	await get_tree().process_frame
	var r := U5Moments.root(v)
	_t(_live_bands(r) >= 1, "B8 setup: a turn band is showing")
	U5Moments.victory(v)
	await get_tree().process_frame
	_t(_live_bands(r) == 0, "B8: Victory clears the Your turn band (%d still up)" % _live_bands(r))
	var vb := 0
	for c in r.get_children():
		if c is U5VictoryBand and not c.is_queued_for_deletion():
			vb += 1
	_t(vb == 1, "B8: the Victory band shows (%d)" % vb)
	U5Moments.end_victory(v)

	# B7: head of a unit whose slot got hidden (killing blow).
	var e: Unit = v._combat.enemies[0]
	var st: CombatStage3D = v._stage3d
	var before := U5Moments.head(v, e.uid)
	var slot: Node3D = (st._units.get(e.uid, {}) as Dictionary).get("slot")
	_t(slot != null, "B7 setup: the enemy has a 3D slot")
	if slot != null:
		slot.visible = false
		_t(U5Moments.head(v, e.uid).is_equal_approx(before), "B7: hidden slot -> the last known head point (%s)" % before)
	var e2: Unit = v._combat.enemies[mini(1, v._combat.enemies.size() - 1)]
	var slot2: Node3D = (st._units.get(e2.uid, {}) as Dictionary).get("slot")
	if slot2 != null and e2.uid != e.uid:
		slot2.visible = false   # never asked before: no last point, falls back to the plate
		var at := U5Moments.head(v, e2.uid)
		var pr := (v._portraits.get(e2.uid) as Control).get_global_rect()
		_t(at.is_equal_approx(pr.get_center()), "B7: no last point -> the plate centre, not its top (%s, plate %s)" % [at, pr])
		slot2.visible = true
	# The big hit tag over a unit at the top edge of the screen stays inside the overlay.
	v.set_meta(U5Moments.HEAD_META, {"%d:%.2f" % [e.uid, 1.0]: Vector2(vp.size.x - 30.0, 20.0)})
	U5Moments.on_hit(v, e.uid, "big_hit")
	await get_tree().process_frame
	var tag := r.find_child("BigHitTag", true, false) as Control
	_t(tag != null, "B7: the BIG HIT tag was made")
	if tag != null:
		_t(vp.encloses(tag.get_global_rect()), "B7: BIG HIT tag on screen (%s in %s)" % [tag.get_global_rect(), vp])
	var num := Label.new()
	num.text = "88"
	num.add_theme_font_size_override("font_size", 56)
	r.add_child(num)
	U5Moments._place_center(num, Vector2(vp.size.x * 0.5, -120.0))
	_t(vp.encloses(num.get_global_rect()), "B7: a number placed at y -120 is pulled on screen (%s)" % num.get_global_rect())
	var rise := U5Moments._rise_of(UI3Motion.layer("big_hit", "number"))
	U5Moments._place_center(num, Vector2(vp.size.x * 0.5, -120.0), rise)
	_t(rise >= 40.0 and num.get_global_rect().position.y - rise >= 0.0,
		"B7: the hit number keeps room for its %.0f px rise (top %.1f)" % [rise, num.get_global_rect().position.y])
	num.queue_free()
	if slot != null:
		slot.visible = true

	# B4: words on the 3D view sit on a chip.
	var hud: CombatHud = v._hud_frame
	var chip := UI3Theme.color("chip")
	var labels: Array[Label] = []
	for k in ["UndoKey", "HoldKey", "WildKey", "OvercastKey"]:
		var key := hud.find_child(k, true, false) as Ui5ToolKey
		if key != null:
			labels.append(key.word)
	var hint := hud.get("_hint") as Label
	hint.text = CombatHud.PICK_TEXT
	hud.layout()
	labels.append(hint)
	for l in labels:
		var sb := l.get_theme_stylebox("normal") as StyleBoxFlat
		_t(sb != null and sb.bg_color == chip, "B4: '%s' has the chip pill behind it" % l.text)
		var ratio := UI3Theme.contrast_ratio(l.get_theme_color("font_color"), chip, chip)
		_t(ratio >= 4.5, "B4: '%s' contrast on the chip %.1f:1" % [l.text, ratio])
	hint.text = ""
	hud.layout()
	_t(not (hint.get_theme_stylebox("normal") is StyleBoxFlat), "B4: an empty StatusLine draws no chip")
	CombatView.disable_juice_for_tests = was_juice
	v.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _live_bands(r: Node) -> int:
	var n := 0
	for c in r.get_children():
		if (c is U5TurnBanner or c is U5BossBand) and (c as CanvasItem).visible and not c.is_queued_for_deletion():
			n += 1
	return n
