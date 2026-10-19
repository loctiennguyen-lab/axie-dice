extends Node
## The battle log sits in the LEFT column: under the top-left plate / attrition card, above the info
## panel and Aid plate, and never under the enemy panel (top-right). Run:
## godot --headless --path godot res://tests/t_battle_log_left.tscn

var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	_guard.capture()
	CombatView.disable_juice_for_tests = true
	print("=== t_battle_log_left: start ===")
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
	await get_tree().process_frame
	RunState.power_level = 3
	RunState.enter_node("r4_c0", "battle")
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 30:
		await get_tree().process_frame
	scene._land_dice_now()
	for i in 12:
		scene._append_log("[exec] line %d" % i)
	scene._on_log_toggle_pressed()
	for _i in 5:
		await get_tree().process_frame
	var box: Control = scene._debug_log_container
	var vp := get_tree().root.get_visible_rect().size
	var r := box.get_global_rect()
	_check(box.visible, "log opens")
	_check(r.end.x <= vp.x * 0.25, "log is in the left quarter (x end %f of %f)" % [r.end.x, vp.x])
	var hud: CombatHud = scene._hud_frame
	_check(r.position.y >= hud._top_plate.get_global_rect().end.y, "log is under the top-left plate")
	if hud._attr_card.visible:
		_check(r.position.y >= hud._attr_card.get_global_rect().end.y, "log is under the attrition card")
	_check(not r.intersects(hud.info_panel().get_global_rect()) or not hud.info_panel().visible, "log clears the info panel")
	_check(r.end.y <= scene._aid.top_y(), "log ends above the Aid plate (%f vs %f)" % [r.end.y, scene._aid.top_y()])
	_check(scene._log_panel.get_parent() == box, "log text lives in the left plate")
	CombatView.disable_juice_for_tests = false
	_guard.restore()
	for m in _fails:
		print("t_battle_log_left: FAIL - %s" % m)
	if _fails.is_empty():
		print("t_battle_log_left: PASS - %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
