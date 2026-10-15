extends Node
## L1 lane C (L6) QA capture: real combats in the 3D arena at 1920x1080 for several biomes + a boss,
## plus the victory run-through (frames). Run NOT headless, through with_lock:
##   with_lock.sh Godot --path godot --resolution 1920x1080 res://tests/qa_l6_capture.tscn -- <out dir> <tag> [rows,csv]
## Files: <out>/<tag>-<name>.png

var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "/tmp"
	var tag: String = args[1] if args.size() > 1 else "shot"
	var rows: Array = [1, 4, 7, 10, 13, 16]
	if args.size() > 2:
		rows = []
		for s in String(args[2]).split(","):
			rows.append(int(s))
	DirAccess.make_dir_recursive_absolute(out)
	if tag.ends_with("tutorial"):
		var tut: Node = (load("res://scenes/tutorial/Tutorial.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(tut)
		for _i in 150:
			await get_tree().process_frame
		get_tree().root.get_texture().get_image().save_png("%s/%s.png" % [out, tag])
		_guard.restore()
		get_tree().quit(0)
		return
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(424242, team, "short", 6, false)
	await get_tree().process_frame
	var graph := RunMapGraph.from_data(RunState.map_graph)
	for r in rows:
		var row: Array = graph.get_row(r)
		if row.is_empty():
			continue
		var node: RunMapNode = null
		for n in row:
			if ["battle", "elite", "boss"].has((n as RunMapNode).node_type):
				node = n
				break
		if node == null:
			continue
		var kind := node.node_type
		RunState.power_level = 3
		RunState.enter_node(node.id, kind)
		var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(scene)
		for _i in 90:
			await get_tree().process_frame
		get_tree().root.get_texture().get_image().save_png("%s/%s-row%d-%s.png" % [out, tag, r, kind])
		print("QA: saved row ", r, " ", kind)
		if args.size() > 3 and String(args[3]) == "march":
			await _march(scene, out, tag, r)
		scene.queue_free()
		await get_tree().process_frame
	_guard.restore()
	get_tree().quit(0)


func _march(scene: Node, out: String, tag: String, r: int) -> void:
	var c: CombatEngine = scene._combat
	for e in c.enemies:
		e.hp = 0
	scene._finish(true)
	for i in 8:
		for _k in 10:
			await get_tree().process_frame
		get_tree().root.get_texture().get_image().save_png("%s/%s-row%d-march%d.png" % [out, tag, r, i])
