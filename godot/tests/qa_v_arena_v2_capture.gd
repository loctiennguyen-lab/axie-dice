extends Node
## Lane V (arena v2 proposal): the real combat screen on Savannah, old arena vs the Blender diorama
## (ArenaV2Diorama) swapped in at runtime. Nothing in CombatStage3D / CombatArena3D is changed: the
## capture hides the old arena's ground, path and props (keeps its gate) and adds the diorama under
## the stage world.
## Not headless: godot/tools/with_lock.sh godot/tools/shot.sh res://tests/qa_v_arena_v2_capture.tscn
## Writes <ADT_EVIDENCE_DIR>/v-<state>-<old|v2>-<w>x<h>.png. CAP_ONLY=battle,boss,eggs; CAP_SIZE=1920x1080.

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
	for size in sizes:
		get_window().size = size
		for _i in 5:
			await get_tree().process_frame
		if _want("battle"):
			await _fight("battle", _find(graph, 3, "battle"), "battle", size)
		if _want("eggs"):
			await _fight("eggs", _find(graph, 3, "battle"), "battle", size)
		if _want("boss"):
			await _fight("boss", _find(graph, int(graph.boss_rows[0]), "boss"), "boss", size)
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


## Hides everything the old arena built except its gate, then adds the v2 diorama.
static func swap_in_v2(stage: CombatStage3D) -> ArenaV2Diorama:
	ArenaV2Diorama.hide_old_arena_except_gate(stage._arena)
	var d := ArenaV2Diorama.new()
	d.name = "ArenaV2"
	stage._world.add_child(d)
	stage._world.move_child(d, 0)
	d.build("savannah")
	return d


func _fight(state: String, node_id: String, kind: String, size: Vector2i) -> void:
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
	for _i in 12:
		await get_tree().process_frame
	await _shot(state + "-old", size)
	var stage: CombatStage3D = scene._stage3d
	stage.set_arena("savannah", kind == "boss")
	var d := swap_in_v2(stage)
	print("QA: v2 tris ", d.triangle_count())
	if OS.get_environment("CAP_DEBUG") != "":
		for n in d.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			for s in mi.mesh.get_surface_count():
				var m := mi.mesh.surface_get_material(s)
				print("DBG ", mi.name, " ", m.resource_name if m != null else "none", " ", (m as BaseMaterial3D).shading_mode if m is BaseMaterial3D else -1, " tr=", (m as BaseMaterial3D).transparency if m is BaseMaterial3D else -1, " vc=", (m as BaseMaterial3D).vertex_color_use_as_albedo if m is BaseMaterial3D else false)
	for _i in 12:
		await get_tree().process_frame
	await _shot(state + "-v2", size)
	for _i in 10:
		await get_tree().process_frame
	scene.queue_free()
	await get_tree().process_frame
