extends Node
## Depth v3 lane D capture (NOT headless): foe Plating chip, 4 -> 1 preview, coach line, Plating off.
var _guard := SaveGuard.new()

func _ready() -> void:
	_guard.capture()
	var out := ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().size = size
		RunState.power_level = 6
		RunState.enter_node("r2_c0", "battle")
		var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(v)
		for _i in 90:
			await get_tree().process_frame
		v._land_dice_now()
		var c: CombatEngine = v._combat
		c.newcomer = true
		c.enemies[0].plating = 3
		var u: Unit = v._party_dice_units()[0]
		u.die[0] = {"type": "dmg", "value": 4, "keywords": []}
		u.set_roll(0, false)
		v._selected_die_uid = u.uid
		v._rebuild_all()
		for _i in 10:
			await get_tree().process_frame
		get_tree().root.get_texture().get_image().save_png("%s/depthv3_plating_preview_%dx%d.png" % [out, size.x, size.y])
		c.enemies[0].plating_off = 2
		v._on_plating_off(c.enemies[0].uid, 2)
		for _i in 10:
			await get_tree().process_frame
		get_tree().root.get_texture().get_image().save_png("%s/depthv3_plating_off_%dx%d.png" % [out, size.x, size.y])
		v.queue_free()
		await get_tree().process_frame
		RunState.set_phase(RunState.RunPhase.MAP)
	_guard.restore()
	get_tree().quit(0)
