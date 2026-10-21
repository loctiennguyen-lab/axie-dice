extends Node
## Overcast HUD (lane OC): button disabled with a reason, enabled with "6 > 9" preview, press -> engine overcast, chip on the die.
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
	RunState.power_level = 4
	RunState.enter_node("r5_c0", "elite")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 60:
		await get_tree().process_frame
	v._land_dice_now()
	var c: CombatEngine = v._combat
	var hud: CombatHud = v._hud_frame
	var ob: Button = hud.overcast_button
	_check(ob != null and ob.visible and ob.disabled and ob.text.contains("pick"), "disabled without a die, says why: %s" % ob.text)
	var us: Array = v._party_dice_units()
	for i in 3:   # MD 22/10: Overcast needs a Set: three dice on the horn (part 1)
		us[i].die[1] = {"type": "dmg", "value": 6, "keywords": [], "part": "horn"}
		us[i].set_roll(1, false)
		us[i].overcast = false
	us[3].set_roll(2, false)
	us[4].set_roll(4, false)
	c._snap_bo()
	var u: Unit = us[0]
	# a die outside the Set: greyed with "Needs a Set"
	c.mana = 5
	v._selected_die_uid = us[3].uid
	v._rebuild_all()
	_check(ob.disabled and ob.text.contains("Needs a Set") and ob.tooltip_text.contains("Set"), "no Set: grey + Needs a Set: %s / %s" % [ob.text, ob.tooltip_text])
	c.mana = 1
	v._selected_die_uid = u.uid
	v._rebuild_all()
	_check(ob.disabled and ob.text.contains("mana"), "low mana: disabled with reason: %s" % ob.text)
	c.mana = 5
	v._rebuild_all()
	_check(not ob.disabled and ob.text.contains("→") and ob.text.count("→") == 3 and ob.text.contains("2 MP"), "enabled shows the whole group (3 values) and price: %s" % ob.text)
	ob.pressed.emit()
	await get_tree().process_frame
	_check(c.by_uid(u.uid).overcast and c.by_uid(us[2].uid).overcast and not c.by_uid(us[3].uid).overcast and c.mana == 3, "button -> engine overcast on the whole Set, mana paid")
	_check(ob.disabled, "second overcast disabled")
	print("=== t_overcast_ui: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	_guard.restore()
	if _fails.is_empty():
		print("t_overcast_ui: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_overcast_ui: FAIL - %s" % f)
	get_tree().quit(1)
