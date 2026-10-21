extends Node
## Overcast capture (run NOT headless): button with "6 > 9" preview, then the die after Overcast (chip, boosted faces).
var _guard := SaveGuard.new()
var _out := ""

func _ready() -> void:
	_guard.capture()
	_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	await get_tree().process_frame
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().size = size
		for _i in 5:
			await get_tree().process_frame
		RunState.power_level = 4
		RunState.enter_node("r5_c0", "elite")
		var s: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(s)
		for _i in 90:
			await get_tree().process_frame
		s._land_dice_now()
		var u: Unit = s._party_dice_units()[0]
		u.die[0] = {"type": "dmg", "value": 6, "keywords": []}
		u.set_roll(0, false)
		s._combat.mana = 5
		s._selected_die_uid = u.uid
		s._rebuild_all()
		await _shot("overcast_preview", size)
		s._on_overcast_pressed()
		await _shot("overcast_active", size)
		s.queue_free()
		await get_tree().process_frame
	_guard.restore()
	get_tree().quit(0)

func _shot(name: String, size: Vector2i) -> void:
	for _i in 90:
		await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [_out, name, size.x, size.y])
	print("QA: saved ", name)
