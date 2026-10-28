extends Node
## Combat HUD labels (QA2 S3-12/S3-23/S4-6/S4-8/S4-9): enemy name suffixes, ELITE/LEADER tag choice, big-hit flag,
## attrition banner timing, blank intent wording, End turn key cap (the one key on screen, UI-05) + StatusLine.

var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _unit(uid: int, nm: String) -> Unit:
	var u := Unit.new()
	u.uid = uid
	u.n = nm
	return u


func _ready() -> void:
	var es := [_unit(1, "Pangolord"), _unit(2, "Slime"), _unit(3, "Pangolord")]
	var d := CombatLabels.enemy_names(es)
	_ok(d[1] == "Pangolord A" and d[3] == "Pangolord B", "dup names suffixed A/B")
	_ok(d[2] == "Slime", "unique name untouched")
	_ok(CombatLabels.tag_for(false, "elite", true, false) == "ELITE", "elite itself")
	_ok(CombatLabels.tag_for(false, "elite", false, false) == "", "companion has no ELITE")
	_ok(CombatLabels.tag_for(false, "elite", true, true) == "", "leader has no ELITE")
	_ok(CombatLabels.tag_for(false, "normal", true, false) == "", "normal fight no tag")
	_ok(CombatLabels.tag_for(true, "boss", true, false) == "BOSS", "boss")
	_ok(CombatLabels.is_big_hit(24, [12, 17]), "24 vs 12/17 is a big hit")
	_ok(not CombatLabels.is_big_hit(8, [12, 17]), "8 is not")
	_ok(CombatLabels.is_big_hit(12, [12, 17]), "equal counts")
	_ok(not CombatLabels.is_big_hit(0, [0]) and not CombatLabels.is_big_hit(5, []), "zero / empty safe")
	var st := {"start_turn": 6, "pct": 0}
	_ok(not CombatLabels.attrition_visible(st, 1), "hidden turn 1")
	_ok(not CombatLabels.attrition_visible(st, 2), "hidden turn 2")
	_ok(CombatLabels.attrition_visible(st, 3), "shown 3 turns before start")
	_ok(CombatLabels.attrition_visible({"start_turn": 6, "pct": 5}, 6), "shown while running")
	_ok(CombatLabels.is_blank_intent("blank") and not CombatLabels.is_blank_intent("dmg"), "blank intent")

	var p := UnitPortrait.new()
	add_child(p)
	p.setup(7, "Elite Bulwark", "", true, false, "ELITE")
	p.set_nick("", "Elite Bulwark")
	_ok(p._name_label.text == "Bulwark", "Elite prefix dropped while ELITE chip shows: %s" % p._name_label.text)
	p.set_leader(true)
	_ok(p._name_label.text == "Elite Bulwark", "leader keeps full name: %s" % p._name_label.text)
	p.set_intent({"show": true, "type": "blank", "num": 0, "label": "BLANK", "target": ""})
	_ok(p._intent_action.text == "IDLE" and p._intent_num.text == "–", "blank intent wording")
	p.set_intent({"show": true, "type": "dmg", "num": 24, "label": "ATTACK", "target": "Rex", "big_hit": true})
	_ok(p.is_big_hit() and p._bang.visible and p._strip.visible, "big-hit badge + strip")

	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var hud := CombatHud.new()
	host.add_child(hud)
	var u1 := Button.new()
	var r1 := Button.new()
	var e1 := Button.new()
	hud.adopt_right_zone(u1, r1, e1)
	await get_tree().process_frame
	hud.update_attrition({"start_turn": 6, "pct": 0}, 1, false)
	_ok(not hud._attr_card.visible, "attrition card hidden turn 1")
	hud.update_attrition({"start_turn": 6, "pct": 0}, 4, false)
	_ok(hud._attr_card.visible, "attrition card shown turn 4")
	_ok(String(hud._attr_card.get_meta("ui3_tip", "")) != "", "attrition tooltip")
	hud.update_right({"enabled": true}, {"n": 1, "max": 3, "enabled": true}, {"sub": "5 dice unused", "enabled": true, "resolving": false})
	_ok(hud._hint.text == "5 dice unused", "StatusLine has no key prefix")
	_ok(hud._end_cap.visible and hud._end_cap_label.text == KeyBindings.text(KeyBindings.COMBAT_END_TURN), "Space key cap shown on End turn")
	_ok(hud._end_cap.get_meta("variant") == &"primary", "key cap on the amber button uses the primary look")
	hud.layout()
	await get_tree().process_frame
	var sbx: StyleBox = e1.get_theme_stylebox("normal")
	var capw: float = hud._end_cap.get_combined_minimum_size().x
	_ok(sbx.content_margin_right >= capw + UI3Theme.space("12"), "End label keeps the 12 px gap + the cap width on the right")
	var tw: float = e1.get_theme_font("font").get_string_size(e1.text, HORIZONTAL_ALIGNMENT_LEFT, -1, e1.get_theme_font_size("font_size")).x
	_ok(tw + sbx.content_margin_right + maxf(sbx.content_margin_left, 0.0) <= e1.size.x, "End label fits left of cap (%.0f + %.0f in %.0f)" % [tw, sbx.content_margin_right, e1.size.x])
	var text_end := (sbx.content_margin_left + e1.size.x - sbx.content_margin_right) * 0.5 + tw * 0.5
	_ok(hud._end_cap.position.x >= text_end + UI3Theme.space("12") - 0.5 and hud._end_cap.position.x + capw <= e1.size.x,
		"cap sits after the label inside the button (cap x %.0f, label ends %.0f)" % [hud._end_cap.position.x, text_end])
	# Text and cap read as one centred group (CSS .btn justify-content center).
	var group_l := text_end - tw
	var group_r := hud._end_cap.position.x + capw
	_ok(absf((group_l + group_r) * 0.5 - e1.size.x * 0.5) <= 1.0, "End turn + Space centred as a group (%.1f vs %.1f)" % [(group_l + group_r) * 0.5, e1.size.x * 0.5])
	hud.set_seed_wait(true)
	_ok(hud._hint.text == CombatHud.WAITING_TEXT and e1.text == CombatHud.WAITING_END, "seed wait: 'Waiting for the server' + End turn 'Waiting…'")
	_ok(hud._end_cap.visible and hud._end_cap.get_meta("variant") == &"disabled", "seed wait: Space cap stays, disabled look")
	hud.set_seed_wait(false)
	_ok(hud._hint.text == "5 dice unused" and e1.text == "End turn", "seed wait restores StatusLine and End turn")
	hud.update_right({"enabled": false}, {"n": 0, "max": 0, "cost": 1, "enabled": false}, {"sub": "0 dice unused", "enabled": false, "resolving": true})
	_ok(e1.text == "Enemy turn" and hud._hint.text == CombatHud.ENEMY_TEXT and hud._end_cap.visible, "enemy turn: 'Enemy turn', 'Enemies are acting', Space stays")
	hud.update_right({"enabled": true}, {"n": 0, "max": 0, "cost": 1, "enabled": false}, {"sub": "5 dice unused", "enabled": true, "resolving": false})
	_ok(r1.text == "Reroll · need 1 MP" and r1.icon == null and not hud._cost_chip.visible and hud._hint.text == "Reroll: need 1 MP",
		"short of mana: 'Reroll · need 1 MP', no glyph/chip, StatusLine says why")
	hud.update_right({"enabled": true}, {"n": 0, "max": 0, "cost": 2, "enabled": true}, {"sub": "5 dice unused", "enabled": true, "resolving": false, "picked": true})
	_ok(r1.text == "Reroll" and hud._cost_chip.visible and (hud._cost_chip.find_child("Amount", true, false) as Label).text == "2" and hud._hint.text == CombatHud.PICK_TEXT,
		"paid reroll: 'Reroll' + mana CostChip 2; a picked die says 'Pick a target'")

	# BossRhythm (02-combat--boss): plate under RunInfo at x 24 / y 108 (screen + run_pill_h + 20), content wide (HTML 362).
	hud.update_foe({"rhythm": {"phase": "prep", "next": "hollow", "tell": "Next turn: Hollow, hit it hard"}})
	await get_tree().process_frame
	await get_tree().process_frame
	var br := hud.get_node("BossRhythm") as Control
	var want_y := float(UI3Theme.space("screen") + UI3Theme.size_of("run_pill_h") + UI3Theme.space("20"))
	_ok(br.visible and br.position.is_equal_approx(Vector2(UI3Theme.space("screen"), want_y)), "BossRhythm at (24, %d): %s" % [int(want_y), br.position])
	_ok(br.size.x > 300.0 and br.size.x < 400.0, "BossRhythm is content wide like the HTML 362 (%.0f)" % br.size.x)
	var steps := br.find_child("RhythmChips", true, false) as Control
	_ok(steps != null and absf(steps.get_child(0).size.y - UI3Theme.size_of("btn_s")) < 0.5, "rhythm steps are btn_s high")
	_ok(br.find_child("NextTag", true, false) != null and (br.find_child("NextTag", true, false) as Label).text == "next", "the next step says 'next'")
	var tell := br.find_child("Tell", true, false) as Label
	_ok(tell != null and tell.get_line_count() == 1, "tell line fits one line")

	print("t_combat_labels: %d checks, %d failure(s)" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_combat_labels: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_combat_labels: FAIL — %s" % f)
	get_tree().quit(1)
