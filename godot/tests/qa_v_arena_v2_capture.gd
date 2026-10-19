extends Node
## Lane V (arena v2): the real combat screen per biome, old procedural arena vs the Blender
## diorama, both through the real CombatStage3D.set_arena() (arena_v2_enabled off / on).
## CAP_ADDS=n spawns n extra adds in the boss fight (5+ use the second back row) to check props.
## Not headless: godot/tools/with_lock.sh godot/tools/shot.sh res://tests/qa_v_arena_v2_capture.tscn
## Writes <ADT_EVIDENCE_DIR>/v-<biome>-<state>-<old|v2>-<w>x<h>.png.
## CAP_BIOMES=savannah,forest,... (default all six); CAP_ONLY=battle,boss,eggs; CAP_SIZE=1920x1080.

var _guard := SaveGuard.new()
var _out := ""
var _only: PackedStringArray = []


func _ready() -> void:
	_guard.capture()
	_out = OS.get_environment("ADT_EVIDENCE_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	if OS.get_environment("CAP_ONLY") != "":
		_only = OS.get_environment("CAP_ONLY").split(",")
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
	await get_tree().process_frame
	var sizes: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 720)]
	if OS.get_environment("CAP_SIZE") != "":
		var p := OS.get_environment("CAP_SIZE").split("x")
		sizes = [Vector2i(int(p[0]), int(p[1]))]
	var graph := RunMapGraph.from_data(RunState.map_graph)
	var biomes: PackedStringArray = ["savannah", "forest", "arctic", "mystic", "genesis", "luna"]
	if OS.get_environment("CAP_BIOMES") != "":
		biomes = OS.get_environment("CAP_BIOMES").split(",")
	for size in sizes:
		get_window().size = size
		for _i in 5:
			await get_tree().process_frame
		for biome in biomes:
			if _want("battle"):
				await _fight(biome, "battle", _find(graph, 3, "battle"), "battle", size)
			if _want("eggs"):
				await _fight(biome, "eggs", _find(graph, 3, "battle"), "battle", size)
			if _want("boss"):
				await _fight(biome, "boss", _find(graph, int(graph.boss_rows[0]), "boss"), "boss", size)
	_guard.restore()
	get_tree().quit(0)


func _want(s: String) -> bool:
	return _only.is_empty() or _only.has(s)


func _find(graph: RunMapGraph, row: int, kind: String) -> String:
	for n in graph.get_row(row):
		if (n as RunMapNode).node_type == kind:
			return (n as RunMapNode).id
	return (graph.get_row(row)[0] as RunMapNode).id


func _shot(name: String, size: Vector2i) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("%s/v-%s-%dx%d.png" % [_out, name, size.x, size.y])
	print("QA: saved v-%s-%dx%d" % [name, size.x, size.y])


func _fight(biome: String, state: String, node_id: String, kind: String, size: Vector2i) -> void:
	RunState.power_level = 9 if kind == "boss" else 4
	RunState.enter_node(node_id, kind)
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 90:
		await get_tree().process_frame
	scene._land_dice_now()
	if state == "eggs":
		for _k in 3:
			scene._combat.party.append(scene._combat._mk_ally())
		scene._sync_unit_visuals()
		scene._rebuild_all()
	if kind == "boss" and OS.get_environment("CAP_ADDS") != "":
		for _k in int(OS.get_environment("CAP_ADDS")):
			scene._combat.spawn_boss_add(scene._combat.enemies[0], 1.0)
		scene._sync_unit_visuals()
		scene._rebuild_all()
	var stage: CombatStage3D = scene._stage3d
	var boss := kind == "boss"
	stage.arena_v2_enabled = false
	stage.set_arena(biome, boss)
	for _i in 12:
		await get_tree().process_frame
	await _shot("%s-%s-old" % [biome, state], size)
	stage.arena_v2_enabled = true
	stage.set_arena(biome, boss)
	var d := stage.arena_diorama()
	print("QA: %s v2=%s tris %d" % [biome, d != null, d.triangle_count() if d != null else 0])
	for _i in 12:
		await get_tree().process_frame
	await _shot("%s-%s-v2" % [biome, state], size)
	for _i in 10:
		await get_tree().process_frame
	scene.queue_free()
	await get_tree().process_frame
