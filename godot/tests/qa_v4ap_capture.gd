extends Node
## v4 UI capture (run NOT headless): states per item, A+ tiers, 1280x720 -> production/qa/evidence/v4ap_*.png
var _guard := SaveGuard.new()
var _out := ""

func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	await get_tree().process_frame
	for size in [Vector2i(1280, 720)]:
		get_window().size = size
		for _i in 5:
			await get_tree().process_frame
		RunState.enter_node("r1_c0", "battle")
		var s: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(s)
		for _i in 90:
			await get_tree().process_frame
		s._land_dice_now()
		await _states(s, size)
		s.queue_free()
		await get_tree().process_frame
	_guard.restore()
	get_tree().quit(0)

func _states(s: Node, size: Vector2i) -> void:
	var c: CombatEngine = s._combat
	var units: Array = s._party_dice_units()
	for u in units:
		u.set_roll(2, false)
	units[3].set_roll(1, false)
	units[4].set_roll(4, false)
	c._snap_bo()
	c.mana = 5
	s._rebuild_all()
	await _shot("v4ap_bo3", size)
	units[3].set_roll(2, false)
	c._snap_bo()
	await _shot("v4ap_bo4", size)
	# four horns + one other: Wild on the fifth die would make five -> refused
	for i in 4:
		units[i].set_roll(1, false)
	units[4].set_roll(4, false)
	c._snap_bo()
	c.mana = 5
	s._rebuild_all()
	await _shot("v4ap_wild_set5_btn", size)
	# two horns + back: Wild on a third die -> three
	units[2].set_roll(2, false)
	units[3].set_roll(5, false)
	c._snap_bo()
	c.rerolls = 0
	c.mana = 1
	s._rebuild_all()
	await _shot("v4ap_wild_mana1", size)
	c.mana = 5
	s._rebuild_all()
	s._enter_wild_mode()
	s._wild_pick_die(units[2].uid)
	await _shot("v4ap_wild_picker", size)
	s._exit_wild_mode()
	s._enter_rr_mode()
	await _shot("v4ap_safe_1mp", size)

func _shot(name: String, size: Vector2i) -> void:
	for _i in 30:
		await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [_out, name, size.x, size.y])
	print("QA: saved ", name)

