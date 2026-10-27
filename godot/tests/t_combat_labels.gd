extends Node
## Combat HUD labels (QA2 S3-12/S3-23/S4-6/S4-8/S4-9): enemy name suffixes, ELITE/LEADER tag choice, big-hit flag,
## attrition banner timing, blank intent wording, End turn key cap + hint.

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
	_ok(p._intent_action.text == "IDLE" and p._intent_num.text == "-", "blank intent wording")
	p.set_intent({"show": true, "type": "dmg", "num": 24, "label": "ATTACK", "target": "Rex", "big_hit": true})
	_ok(p._intent_next.text.begins_with("!"), "big-hit glyph")

	var host := Control.new()
	host.size = Vector2(1280, 720)
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
	_ok(hud._hint.text == "5 dice unused", "hint has no key prefix")
	_ok(hud._end_cap.visible and hud._end_cap_label.text != "", "key cap shown")
	hud.layout()
	var sbx: StyleBox = e1.get_theme_stylebox("normal")
	var capw: float = hud._end_cap.get_combined_minimum_size().x
	_ok(sbx.content_margin_right >= capw + 20.0, "End label keeps 8 px + edge before the cap")
	var tw: float = e1.get_theme_font("font").get_string_size(e1.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	_ok(tw + sbx.content_margin_right + maxf(sbx.content_margin_left, 0.0) <= e1.size.x, "End label fits left of cap (%.0f + %.0f in %.0f)" % [tw, sbx.content_margin_right, e1.size.x])
	hud.set_seed_wait(true)
	_ok(hud._hint.text == "Waiting for server…", "seed wait still works")
	hud.set_seed_wait(false)
	_ok(hud._hint.text == "5 dice unused", "seed wait restores hint")

	print("t_combat_labels: %d checks, %d failure(s)" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_combat_labels: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_combat_labels: FAIL — %s" % f)
	get_tree().quit(1)
