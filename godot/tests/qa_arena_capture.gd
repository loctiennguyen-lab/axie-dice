extends Node
## One-off capture (run WITHOUT --headless): each biome arena with 3 enemies + 5 party Axies,
## saved from the game viewport as <out>/arena_<biome>.png, plus average FPS per biome.
## `-- <out dir> [biome,biome...]`

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp"
	var biomes: Array = CombatArena3D.registry().get("journey", [])
	if args.size() > 1:
		biomes = Array(args[1].split(","))
	var stage: Node = (load("res://scenes/shared/CombatStage3D.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(stage)
	await get_tree().process_frame
	await get_tree().process_frame
	var enemy_keys := ["slime", "chomper", "bruiser"]
	var classes := ["plant", "beast", "aqua", "reptile", "bug"]
	for i in 5:
		stage.spawn_unit(i + 1, classes[i], false, i, 5)
	for i in 3:
		stage.spawn_unit(10 + i, "bug", true, i, 3, false, enemy_keys[i])
	for b in biomes:
		var t_build := Time.get_ticks_msec()
		var ok: bool = stage.set_arena(String(b))
		var build_ms := Time.get_ticks_msec() - t_build
		for _i in 30:
			await get_tree().process_frame
		var t0 := Time.get_ticks_msec()
		var frames := 0
		while Time.get_ticks_msec() - t0 < 2000:
			await get_tree().process_frame
			frames += 1
		print("ARENA ", b, " ok=", ok, " build_ms=", build_ms, " fps=", snappedf(frames / 2.0, 0.1),
			" draw_calls=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			" prims=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		get_tree().root.get_texture().get_image().save_png("%s/arena_%s.png" % [out, b])
	get_tree().quit(0)
