extends Node
## v4 UI capture (run NOT headless): states per item, 1920x1080 + 1280x720 -> production/qa/evidence/v4ui_*.png
var _guard := SaveGuard.new()
var _out := ""

func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	await get_tree().process_frame
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
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
	await _result_shots()
	_guard.restore()
	get_tree().quit(0)

func _result_shots() -> void:
	RunState.start_new_run(777002, ["plant1", "beast1", "aqua1", "reptile1", "bird1"] as Array[String], "short", 0, false)
	RunState.owned_relic_ids = ["r_devilsreroll", "a_aegisfont"] as Array[String]
	RunState.core_impact = {"r_devilsreroll": {"n": 9, "by": {"dmg": 999}}, "a_aegisfont": {"n": 3, "by": {"dmg": 40}}}
	RunState.set_phase(RunState.RunPhase.WON)
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().size = size
		var v: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(v)
		for _i in 10:
			await get_tree().process_frame
		await _shot("v4ui_result", size)
		v.queue_free()
		await get_tree().process_frame

func _states(s: Node, size: Vector2i) -> void:
	var c: CombatEngine = s._combat
	var units: Array = s._party_dice_units()
	for u in units:
		u.set_roll(2, false)
	units[3].set_roll(1, false)
	units[4].set_roll(4, false)
	c._snap_bo()
	s._rebuild_all()
	await _shot("v4ui_bo3", size)
	units[3].set_roll(2, false)
	c._snap_bo()
	await _shot("v4ui_bo4", size)
	units[3].set_roll(1, false)
	units[4].cracked = true
	c._snap_bo()
	c.rerolls = 0
	c.mana = 1
	s._rebuild_all()
	s._enter_rr_mode()
	await _shot("v4ui_reroll_pick", size)
	c.mana = 5
	s._rr_toggle(units[0].uid)
	s._rr_toggle(units[2].uid)
	await _shot("v4ui_gamble_pct", size)
	s._exit_rr_mode()
	units[4].cracked = false
	units[0].set_roll(1, false)
	units[1].set_roll(1, false)
	units[2].set_roll(2, false)
	units[3].set_roll(4, false)
	units[4].set_roll(5, false)
	c._snap_bo()
	c.mana = 5
	s._rebuild_all()
	s._enter_wild_mode()
	s._wild_pick_die(units[2].uid)
	await _shot("v4ui_wild_picker", size)

func _shot(name: String, size: Vector2i) -> void:
	for _i in 30:
		await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [_out, name, size.x, size.y])
	print("QA: saved ", name)

