extends Node
## Lane VZ capture (run NOT headless, tools/shot.sh): combat with 3 Cores + fake core_fired, then the Result card.
## Saves core_vis_{combat,result}_WxH.png into ADT_EVIDENCE_DIR.
var _guard := SaveGuard.new()

func _ready() -> void:
	_guard.capture()
	var out := OS.get_environment("ADT_EVIDENCE_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	var team := ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String]
	RunState.start_new_run(424242, team, "short", 3, false)
	await get_tree().process_frame
	TCoreVisibilityUi.setup_cores()
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 90:
		await get_tree().process_frame
	v._land_dice_now()
	var ally: int = v._combat.party[0].uid
	var foe: int = v._combat.enemies[0].uid
	for _k in 3:
		TCoreVisibilityUi.fire_fakes(ally, foe)
	await get_tree().create_timer(0.75).timeout   # past the impact delay, notes still on screen (they live ~1.7 s)
	await _shot(out, "core_vis_combat")
	var impact := RunState.core_impact.duplicate(true)
	v.queue_free()
	await get_tree().process_frame
	RunState.start_new_run(777003, team, "short", 3, false)
	TCoreVisibilityUi.setup_cores()
	RunState.core_impact = impact
	RunState.set_phase(RunState.RunPhase.WON)
	var r: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	add_child(r)
	for _i in 30:
		await get_tree().process_frame
	await _shot(out, "core_vis_result")
	_guard.restore()
	get_tree().quit(0)

func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s_%dx%d.png" % [out, name, img.get_width(), img.get_height()])
	print("QA: saved ", name)
