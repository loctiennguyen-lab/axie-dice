extends Node
## Depth v3 lane D capture (NOT headless): CorePanel on map + combat.
var _guard := SaveGuard.new()

func _ready() -> void:
	_guard.capture()
	var out := ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	load("res://tests/t_depthv3_core_panel.gd").grant(["c_test_dice_moss_a", "c_test_mana_amber_a", "c_test_pos_crystal_a", "c_test_quest_amber"])
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().size = size
		var scene: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
		add_child(scene)
		for _i in 12:
			await get_tree().process_frame
		get_tree().root.get_texture().get_image().save_png("%s/depthv3_core_panel_map_%dx%d.png" % [out, size.x, size.y])
		scene.queue_free()
		await get_tree().process_frame
		RunState.enter_node("r1_c0", "battle")
		var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(v)
		for _i in 90:
			await get_tree().process_frame
		get_tree().root.get_texture().get_image().save_png("%s/depthv3_core_panel_combat_%dx%d.png" % [out, size.x, size.y])
		v.queue_free()
		RunState.set_phase(RunState.RunPhase.MAP)
	_guard.restore()
	get_tree().quit(0)
