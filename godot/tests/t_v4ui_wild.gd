extends Node
## v4 UI item 3: Wild button + picker (6 chips from preview_wild), Overcast preview text (+0.4 on the whole Set).
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 60:
		await get_tree().process_frame
	v._land_dice_now()
	var c: CombatEngine = v._combat
	var units: Array = v._party_dice_units()
	# two dice on the horn (1), one on the back (2): a Wild face on a third die can make a Set of 3 horns
	# MD 22/10: Wild only makes a Set of 3 into 4: three dice on the horn, a fourth (units[3]) on the back
	for i in 3:
		units[i].die[1] = {"type": "dmg", "value": 5, "keywords": [], "part": "horn"}
		units[i].set_roll(1, false)
	units[3].set_roll(2, false)
	units[4].set_roll(4, false)
	c._snap_bo()
	c.mana = 1
	v._rebuild_all()
	var wb: Button = v._hud_frame.wild_button
	_check(wb.visible and wb.disabled and wb.text.contains("need 2 mana"), "wild disabled with reason at 1 mana: %s" % wb.text)
	c.mana = 5
	v._rebuild_all()
	_check(not wb.disabled and wb.text.contains("2 MP") and wb.text.contains("1 left"), "wild enabled, shows price and 1 left: %s" % wb.text)
	wb.pressed.emit()
	await get_tree().process_frame
	_check(v._wild_mode, "wild mode on")
	v._wild_pick_die(units[3].uid)
	await get_tree().process_frame
	var pk: WildPicker = v._wild_picker
	_check(pk.visible and pk.chips.size() == 6, "picker with 6 chips")
	_check(pk.chips[1].text.contains("SET OF 4") and pk.chips[1].text.contains("×2.2"), "horn chip previews the Set: %s" % pk.chips[1].text)
	_check(not pk.chips[1].disabled and pk.chips[1].text.begins_with("★"), "best chip starred")
	_check(pk.chips[2].disabled, "current part chip disabled: %s" % pk.chips[2].text)
	_check(pk.chips[0].disabled and pk.chips[0].text.contains("Needs a set of 3"), "no-Set slot says why: %s" % pk.chips[0].text)
	pk.chips[1].pressed.emit()
	await get_tree().process_frame
	_check(c.by_uid(units[3].uid).wild_slot == 1 and c.mana == 3, "chip -> engine wild_face(uid, 1), mana paid")
	_check(c.bo.size() == 1 and int(c.bo[0]["size"]) == 4, "Set of 4 formed")
	_check(v._die_slot_buttons[3].find_child("WildChip", true, false) != null, "wild badge on the die")
	_check(wb.disabled and wb.text.contains("used this fight"), "second wild: used this fight")
	# Overcast preview text
	units[0].die[1] = {"type": "dmg", "value": 5, "keywords": [], "part": "horn"}
	units[0].set_roll(1, false)
	c._snap_bo()
	c.mana = 5
	v._selected_die_uid = units[0].uid
	v._rebuild_all()
	var ob: Button = v._hud_frame.overcast_button
	_check(ob.tooltip_text.contains("×2.2 → ×2.6") and ob.tooltip_text.contains("+0.4"), "overcast tip: %s" % ob.tooltip_text)
	# A+: a Wild face that would make a Set of 5 is refused with its own short reason
	_check(V4Ui.wild_line({"ok": false, "reason": "set5"}, 0, {}) == "Wild can't make 5", "set5 reason text")
	print("=== t_v4ui_wild: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	_guard.restore()
	if _fails.is_empty():
		print("t_v4ui_wild: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_v4ui_wild: FAIL - %s" % f)
	get_tree().quit(1)
