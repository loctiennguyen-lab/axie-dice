extends Node
## QA capture of the 3D dice throw: mid-air and settled. NOT headless. Run through with_lock.sh /
## shot.sh res://tests/qa_dice_throw_capture.tscn. Writes ui3-dice-*.png to $ADT_EVIDENCE_DIR.
var _guard := SaveGuard.new()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	var out := OS.get_environment("ADT_EVIDENCE_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	img.save_png("%s/ui3-dice-%s.png" % [out, name])
	print("QA: saved ui3-dice-%s" % name)


func _ready() -> void:
	_guard.capture()
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(424242, team, "short", 6, false)
	await get_tree().process_frame
	get_window().size = Vector2i(1920, 1080)
	RunState.power_level = 3
	RunState.enter_node("r4_c0", "battle")
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	var t0 := Time.get_ticks_msec()
	var marks := {"midair": 750, "flying": 1950, "settled": 4000}
	for k in marks:
		while Time.get_ticks_msec() - t0 < int(marks[k]):
			await get_tree().process_frame
		await _shot(k)
	_guard.restore()
	get_tree().quit(0)
