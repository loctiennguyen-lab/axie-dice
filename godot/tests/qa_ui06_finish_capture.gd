extends Node
## QA-only, UI-06 finish: 03-run-map--node-icons (open node), 03-run-map--boss-next (real RunState walk to the pre-boss node),
## 13-treasure--opened (real treasure rewards), 49-anchor-awaken--after (map). UI6_PROBE_SCALE=1 / 0.6667, UI6_SHOT_TAG=1920 / 1280,
## UI6_SHOT_DIR = absolute output dir.
var _guard := SaveGuard.new()


func _snap(name: String) -> void:
	var dir := OS.get_environment("UI6_SHOT_DIR")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/%s--%s.png" % [dir, name, OS.get_environment("UI6_SHOT_TAG")])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _new_map() -> Node:
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	await _wait(0.6)
	return m


func _free_map(m: Node) -> void:
	m.queue_free()
	await _wait(0.2)


## Walk: visit every node on rows < `row`, stand on a node of row `row` (the first whose next list holds a boss when `pre_boss`).
func _stand(row: int, pre_boss: bool) -> void:
	var g := RunMapGraph.from_data(RunState.map_graph)
	var vis: Array[String] = []
	var here := ""
	for r in g.rows:
		for raw in r:
			var n: RunMapNode = raw
			if n.row < row:
				vis.append(n.id)
			elif n.row == row and here == "":
				if pre_boss:
					for nid in n.next_ids:
						var nx := g.find_node(nid)
						if nx != null and nx.node_type == "boss":
							here = n.id
				else:
					here = n.id
	RunState.visited_node_ids.assign(vis)
	RunState.current_node_id = here
	RunState.phase = RunState.RunPhase.MAP   # no reward / offer overlay over the map
	RunState.pending_rewards.assign([])
	if not RunState.visited_node_ids.has(here) and here != "":
		RunState.visited_node_ids.append(here)


func _ready() -> void:
	_guard.capture()
	var want := OS.get_environment("UI6_PROBE_SCALE")
	UI3Theme.set_scale_override(float(want) if want != "" else 1.0)
	UI3Theme.sync_scale()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	RunState.owned_relic_ids.assign(["c_bastion", "c_backline_glow", "r_ironvow"])
	RunState.shards_this_run = 40
	RunState.pending_rewards.assign([])
	RunState.anchor_offer = []
	var g := RunMapGraph.from_data(RunState.map_graph)
	var boss_row := 0
	for r in g.rows:
		for raw in r:
			if (raw as RunMapNode).node_type == "boss":
				boss_row = maxi(boss_row, (raw as RunMapNode).row)
	# node-icons: mid-run, the current node open (nothing in fog around it)
	_stand(4, false)
	var m := await _new_map()
	_snap("03-run-map--node-icons")
	await _free_map(m)
	# boss-next: standing on the pre-boss node, the boss reachable
	_stand(boss_row - 1, true)
	m = await _new_map()
	_snap("03-run-map--boss-next")
	# treasure with real rewards
	RunState.generate_treasure_rewards(RunState.current_node_id)
	m.call("_build_treasure", true)
	await _wait(0.8)
	_snap("13-treasure--opened")
	await _free_map(m)
	# awaken after (map): Awakened chip + AnchorTile double frame
	var hc: Array = AnchorAdapter.house_cores("a_volley")
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "awakened": true, "owned": [hc[1], hc[2]]}
	_stand(4, false)
	m = await _new_map()
	_snap("49-anchor-awaken--after")
	await _free_map(m)
	AnchorAdapter.test_state = null
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit()
