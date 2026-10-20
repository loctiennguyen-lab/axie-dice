extends Node
## Depth v3 lane D capture (NOT headless): run map with reward_kind badges + Elite affix caption + detail plate.
var _guard := SaveGuard.new()

func _ready() -> void:
	_guard.capture()
	var out := ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	RunState.start_new_run(777, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	var graph := RunMapGraph.from_data(RunState.map_graph)
	# Stand on a node whose next row holds the first Elite, so the Elite is reachable.
	var cur := graph.start_node_id
	for row in graph.rows:
		for n in row:
			if (n as RunMapNode).node_type == "elite":
				for r2 in graph.rows:
					for p in r2:
						if (p as RunMapNode).next_ids.has((n as RunMapNode).id):
							cur = (p as RunMapNode).id
				break
		if cur != graph.start_node_id:
			break
	graph.find_node(cur).visited = true
	RunState.current_node_id = cur
	RunState.map_graph = graph.to_data()
	var scene: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(scene)
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().size = size
		for _i in 12:
			await get_tree().process_frame
		var cn := graph.find_node(cur)
		for nid in cn.next_ids:
			var nn := graph.find_node(nid)
			if nn.node_type == "elite":
				scene._select_node(nid) if scene.has_method("_select_node") else null
		for _i in 6:
			await get_tree().process_frame
		get_tree().root.get_texture().get_image().save_png("%s/depthv3_map_%dx%d.png" % [out, size.x, size.y])
	_guard.restore()
	get_tree().quit(0)
