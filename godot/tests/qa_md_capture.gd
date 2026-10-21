extends Node
## v4 UI capture (run NOT headless): states per item, MD mana rules, 1280x720 -> production/qa/evidence/md_*.png
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
	# three horns (Set of 3) + back + eyes: Overcast on a Set die, then Wild 3 -> 4
	for i in 3:
		units[i].set_roll(1, false)
	units[3].set_roll(2, false)
	units[4].set_roll(4, false)
	c._snap_bo()
	c.rerolls = 0
	c.mana = 6
	s._selected_die_uid = units[0].uid
	s._rebuild_all()
	await _shot("md_overcast_set3", size)
	# no Set: grey + Needs a Set
	s._selected_die_uid = units[3].uid
	s._rebuild_all()
	await _shot("md_overcast_noset", size)
	# Wild 3 -> 4 picker
	s._selected_die_uid = -1
	s._rebuild_all()
	s._enter_wild_mode()
	s._wild_pick_die(units[3].uid)
	await _shot("md_wild_3to4", size)
	s._exit_wild_mode()
	# only a pair: Wild button grey
	units[2].set_roll(2, false)
	c._snap_bo()
	s._rebuild_all()
	await _shot("md_wild_pair_grey", size)

func _shot(name: String, size: Vector2i) -> void:
	for _i in 30:
		await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [_out, name, size.x, size.y])
	print("QA: saved ", name)

