extends Node
## Lane C (horizontal combat stage): normal fight on Savannah and Luna, elite, boss, a fight with Eggs,
## and the victory march through the gate, at 1920x1080 and 1280x720.
## Not headless: godot/tools/with_lock.sh godot/tools/shot.sh res://tests/qa_c_horizontal_capture.tscn
## Writes <ADT_EVIDENCE_DIR>/c-<state>-<w>x<h>.png. CAP_ONLY=savannah,luna,... limits the states, CAP_SIZE=1920x1080 one size.

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
	var rows := graph.rows.size()
	print("QA: rows=", rows, " boss_rows=", graph.boss_rows, " elite_rows=", graph.elite_rows)
	for size in sizes:
		get_window().size = size
		for _i in 5:
			await get_tree().process_frame
		if _want("savannah"):
			await _fight("savannah", _find(graph, 3, "battle"), "battle", size)
		if _want("luna"):
			await _fight("luna", _find(graph, rows - 1, "battle"), "battle", size)
		if _want("elite"):
			await _fight("elite", _find(graph, int(graph.elite_rows[0]), "elite"), "elite", size)
		if _want("boss"):
			await _fight("boss", _find(graph, int(graph.boss_rows[0]), "boss"), "boss", size)
		if _want("eggs"):
			await _fight("eggs", _find(graph, 3, "battle"), "battle", size)
		if _want("march"):
			await _fight("march", _find(graph, 3, "battle"), "battle", size)
		if _want("marchluna"):
			await _fight("marchluna", _find(graph, rows - 1, "battle"), "battle", size)
	_guard.restore()
	get_tree().quit(0)


func _want(s: String) -> bool:
	return _only.is_empty() or _only.has(s)


func _find(graph: RunMapGraph, row: int, kind: String) -> String:
	for n in graph.get_row(row):
		if (n as RunMapNode).node_type == kind:
			return (n as RunMapNode).id
	push_warning("no %s node in row %d, using first node" % [kind, row])
	return (graph.get_row(row)[0] as RunMapNode).id


func _shot(state: String, size: Vector2i) -> void:
	var img := get_tree().root.get_texture().get_image()
	img.save_png("%s/c-%s-%dx%d.png" % [_out, state, size.x, size.y])
	print("QA: saved c-%s-%dx%d" % [state, size.x, size.y])


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
	if state == "march" or state == "marchluna":
		scene._play_victory_march()
		await get_tree().create_timer(0.6).timeout
		_shot(state + "-a", size)
		await get_tree().create_timer(0.5).timeout
		_shot(state + "-b", size)
		await get_tree().create_timer(0.5).timeout
		_shot(state + "-c", size)
		scene._stage3d.skip_victory_march()
	else:
		_shot(state, size)
	for _i in 20:
		await get_tree().process_frame
	scene.queue_free()
	await get_tree().process_frame
