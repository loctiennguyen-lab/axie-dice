extends Node
## v4 UI item 4: hide by stage (1/2/3), coach C1-C7 one line per turn, once.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	V4Coach.reset_for_tests()
	V4Coach.enabled_in_tests = true
	_guard.capture()
	# pure ordering
	var base := {"stage": 3, "rolled": true, "pair": false, "bo": false, "free_left": 1, "payable": true, "mana": 5, "reroll_cost": 2, "wild_cost": 2, "oc_cost": 3}
	_check(V4Coach.next_id(base) == "C1", "C1 first")
	V4Coach.mark("C1")
	_check(V4Coach.next_id(base) == "C7", "C7 (>= 3 mana, stage 3) once free reroll is not the issue: %s" % V4Coach.next_id(base))
	var st1 := base.duplicate()
	st1["stage"] = 1
	_check(V4Coach.next_id(st1) == "", "stage 1 never gets C5-C7")
	for id in V4Coach.ORDER:
		_check(V4Coach.text_for(id) != "" and not V4Coach.text_for(id).contains("\n"), "one sentence for %s" % id)
	for stage in [1, 2, 3]:
		RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
		await get_tree().process_frame
		RunState.enter_node("r1_c0", "battle")
		var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(v)
		for _i in 60:
			await get_tree().process_frame
		v._land_dice_now()
		var c: CombatEngine = v._combat
		c.depth_stage = stage
		c.mana = 5
		c.rerolls = 0
		v._rebuild_all()
		var hud: CombatHud = v._hud_frame
		_check(hud.wild_button.visible == (stage >= 2), "stage %d wild visible=%s" % [stage, hud.wild_button.visible])
		_check(hud.overcast_button.visible == (stage >= 3), "stage %d overcast visible=%s" % [stage, hud.overcast_button.visible])
		# no crack/gamble words at stage 1 anywhere on the buttons
		var words := hud.reroll_button.text + hud.reroll_button.tooltip_text + hud.wild_button.text + hud.overcast_button.text
		if stage == 1:
			_check(not words.to_lower().contains("gamble") and not words.to_lower().contains("crack"), "stage 1 has no Gamble/Crack words")
			hud.reroll_button.pressed.emit()
			await get_tree().process_frame
			_check(not v._rr_mode, "stage 1 paid reroll goes straight through (no Gamble bar)")
		_check(v.coach_shown_id != "", "stage %d coach shown: %s" % [stage, v.coach_shown_id])
		v.queue_free()
		await get_tree().process_frame
	print("=== t_v4ui_stage_coach: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	_guard.restore()
	if _fails.is_empty():
		print("t_v4ui_stage_coach: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_v4ui_stage_coach: FAIL - %s" % f)
	get_tree().quit(1)
