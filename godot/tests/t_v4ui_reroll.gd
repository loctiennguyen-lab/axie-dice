extends Node
## v4 UI item 2: Gamble / Safe bar, % line, preselected dice outside a Set, Crack chip, refusal words, right rmode.
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
	_check(V4Ui.crack_pct(1, 30.0) == 30 and V4Ui.crack_pct(2, 30.0) == 51 and V4Ui.crack_pct(3, 30.0) == 66 \
		and V4Ui.crack_pct(4, 30.0) == 76 and V4Ui.crack_pct(5, 30.0) == 83, "crack pct table 30/51/66/76/83")
	for code in V4Ui.REFUSAL_CODES:
		var t := V4Ui.refusal_text(code, 2, 1)
		_check(t != "" and not t.contains("undefined") and not t.contains("NaN"), "refusal text for %s: %s" % [code, t])
	_check(V4Ui.refusal_text("mana", 2, 1) == "Need 2 mana (you have 1)", "mana refusal wording")
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
	for u in units:
		u.set_roll(2, false)
	units[3].set_roll(1, false)
	units[4].set_roll(4, false)
	c._snap_bo()
	c.rerolls = 0
	c.mana = 5
	v._rebuild_all()
	_check(v._hud_frame.reroll_button.text.begins_with("Reroll"), "button still says Reroll: %s" % v._hud_frame.reroll_button.text)
	v._hud_frame.reroll_button.pressed.emit()
	await get_tree().process_frame
	_check(v._rr_mode and v._rr_bar.visible, "paid reroll at stage 3 opens the pick bar")
	var want: Array = [units[3].uid, units[4].uid]
	_check(v._rr_sel == want, "preselect = dice outside the Set: %s vs %s" % [str(v._rr_sel), str(want)])
	_check(v._rr_bar.line.text == "At least 1 die Cracks: 51%", "pct line for 2 dice: %s" % v._rr_bar.line.text)
	_check(not v._rr_bar.gamble_button.disabled and not v._rr_bar.safe_button.disabled, "both modes enabled")
	_check(v._rr_bar.safe_button.text == "Safe · 1 MP", "safe shows price: %s" % v._rr_bar.safe_button.text)
	v._rr_toggle(units[4].uid)
	_check(v._rr_bar.line.text == "At least 1 die Cracks: 30%", "pct updates on deselect: %s" % v._rr_bar.line.text)
	v._rr_toggle(units[4].uid)
	v._rr_toggle(units[3].uid)
	v._rr_toggle(units[4].uid)
	_check(v._rr_sel.is_empty() and v._rr_bar.line.text.begins_with("Pick dice"), "empty pick says so: %s" % v._rr_bar.line.text)
	_check(v._rr_bar.gamble_button.disabled and v._rr_bar.safe_button.disabled, "none picked: both disabled")
	v._rr_toggle(units[3].uid)
	c.mana = 0
	v._rebuild_all()
	_check(v._rr_bar.safe_button.disabled and v._rr_bar.line.text.contains("Need 1 mana (you have 0)"), "safe disabled says why: %s" % v._rr_bar.line.text)
	_check(not v._rr_bar.gamble_button.disabled, "gamble needs no mana")
	var k0: int = c.reroll_k
	v._rr_bar.gamble_button.pressed.emit()
	for _i in 10:
		await get_tree().process_frame
	_check(c.reroll_k == k0 + 1 and int(c.reroll_lock[k0 + 1]["rmode"]) == 0, "Gamble called reroll with rmode 0")
	_check(not v._rr_mode, "mode closed after the roll")
	# a Cracked die shows the chip
	var u2: Unit = v._party_dice_units()[0]
	u2.cracked = true
	v._rebuild_all()
	_check(v._die_slot_buttons[0].find_child("CrackChip", true, false) != null and v._die_slot_buttons[0].find_child("CrackChip", true, false).visible, "Crack chip on a cracked die")
	print("=== t_v4ui_reroll: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	_guard.restore()
	if _fails.is_empty():
		print("t_v4ui_reroll: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_v4ui_reroll: FAIL - %s" % f)
	get_tree().quit(1)
