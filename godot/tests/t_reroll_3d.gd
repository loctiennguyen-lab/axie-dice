extends Node
## Reroll goes through the 3D dice throw (DiceRoller3D), only for the dice that were rerolled, and the
## tray shows the engine's new faces after it. Headless the roller takes its skip path, so the throw
## is recorded in CombatView.last_throw and the tags go up at once. Also: RerollTags rules (MAX, NEW,
## +n, -n), spam R is safe, heavy / frozen dice are not thrown.
## Run: godot --headless --path godot res://tests/t_reroll_3d.tscn

var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		get_viewport().push_input(e, true)
		await get_tree().process_frame


func _ready() -> void:
	_guard.capture()
	print("=== t_reroll_3d: start ===")
	_tag_rules()
	await _flow()
	_guard.restore()
	for f in _fails:
		print("t_reroll_3d: FAIL - %s" % f)
	if _fails.is_empty():
		print("t_reroll_3d: PASS - %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)


func _tag_rules() -> void:
	var faces := [{"type": "dmg", "value": 2}, {"type": "dmg", "value": 5}, {"type": "shield", "value": 3},
		{"type": "dmg", "value": 1}, {"type": "heal", "value": 4}, {"type": "dmg", "value": 5}]
	_check(RerollTags.chip_for(faces, 0, 1).get("text") == "MAX", "best face gives MAX")
	_check(RerollTags.is_max_face(faces, 5) and not RerollTags.is_max_face(faces, 0), "max face test")
	_check(RerollTags.chip_for(faces, 0, 2).get("text") == "NEW", "other type gives NEW")
	_check(RerollTags.chip_for(faces, 3, 0).get("text") == "+1", "same type higher gives +1")
	_check(RerollTags.chip_for(faces, 0, 3).get("text") == "-1", "same type lower gives -1")
	_check(RerollTags.chip_for(faces, 0, 0).is_empty(), "same face gives nothing")
	_check(RerollTags.chip_for(faces, -1, 0).get("text") == "+0" or RerollTags.chip_for(faces, -1, 0).is_empty(),
		"no previous face gives no delta")


func _flow() -> void:
	var tree := get_tree()
	CombatView.disable_juice_for_tests = false
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
	await tree.process_frame
	RunState.power_level = 3
	RunState.enter_node("r4_c0", "battle")
	var view: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	tree.root.add_child(view)
	for _i in 60:
		await tree.process_frame
	view._land_dice_now()
	var combat: CombatEngine = view._combat
	combat.rerolls = 5
	var units: Array = view._party_dice_units()
	var frozen: Unit = units[1]
	frozen.frozen = true
	# v4: the one-button reroll keeps dice that sit in a Set. Give every die its own part so none does.
	for i in units.size():
		(units[i] as Unit).set_roll(i, false)
	combat._snap_bo()
	view.last_throw = {}
	view._on_reroll_pressed()
	for _i in 6:
		await tree.process_frame
	var lt: Dictionary = view.last_throw
	_check(not lt.is_empty() and bool(lt.get("reroll", false)), "reroll goes through the 3D throw")
	_check(not (lt.get("uids", []) as Array).has(frozen.uid), "frozen die is not thrown")
	_check((lt.get("uids", []) as Array).size() >= 3, "the other dice are thrown")
	_check(combat.rerolls == 4, "one reroll spent (got %d)" % combat.rerolls)
	for i in units.size():
		var u: Unit = units[i]
		if u.has_rolled() and u.hp > 0 and not u.roll_used():
			var tile: Node = (view._die_slot_content[i] as Dictionary).get("die_num")
			if tile is Label and u.roll_face_index() >= 0:
				var want := str(view._live_face_value(u, u.roll_face_index()))
				_check((tile as Label).text == want, "tray %d shows the new face value %s (got %s)" % [i, want, (tile as Label).text])
	_check(view._reroll_prev.is_empty(), "pending reroll marks cleared after the throw")
	# spam R and keys during/after a throw
	for _i in 4:
		view._on_reroll_pressed()
	await _key(KEY_R)
	await _key(KEY_1)
	await _key(KEY_Z)
	for _i in 6:
		await tree.process_frame
	_check(combat.rerolls >= 0 and is_instance_valid(view), "spam R and keys stay safe")
	# undo mid-throw: pending dice land first, nothing stays hidden
	view._dice_pending[units[0].uid] = true
	(view._die_slot_buttons[0] as Button).modulate.a = 0.0
	view._on_undo_pressed()
	_check(view._dice_pending.is_empty() and (view._die_slot_buttons[0] as Button).modulate.a == 1.0,
		"undo during a throw lands the dice first")
	frozen.frozen = false
	combat.rerolls = 0
	view.last_throw = {}
	view._on_reroll_pressed()
	for _i in 3:
		await tree.process_frame
	_check(view.last_throw.is_empty(), "no rerolls left: nothing is thrown")
	view.queue_free()
	await tree.process_frame
	CombatView.disable_juice_for_tests = true
