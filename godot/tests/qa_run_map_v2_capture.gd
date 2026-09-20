extends Node
## Manual VISUAL QA capture for the v2 Run Map redesign (docs/design-handoff-v2, "RUN MAP" /
## "RUN MAP · left rail and header" screens). NOT part of the automated regression suite — see
## qa_anim_capture.gd's header for why (Visual/Feel evidence is ADVISORY per
## coding-standards.md's Test Evidence table). MUST run non-headless: --headless's dummy
## rasterizer returns no texture from get_texture() (same limitation every other
## qa_*_capture.gd in this directory documents).
##
## Drives real RunState + a real RunMap.tscn instance, walking the map forward a few nodes and
## granting a relic so the left rail's PARTY/RELICS sections have real content to render, then
## screenshots the actual rendered 1920x1080 window — directly comparable to
## docs/design-handoff-v2 (bundle screenshots/02-run-map.png, minus its 72px scaffolding tab
## bar — see that bundle's README).
##
## Run: /path/to/Godot --path godot tests/qa_run_map_v2_capture.tscn
## Do not point this at a terminal/window the user (or another agent) is actively using.

var _EVIDENCE_DIR := QaPaths.evidence_dir()
const _TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
const _SEED := 555001

var _shot_index := 0
var _map: Node

## Borrows the player's real save file and puts it back byte for byte (this drives a real run,
## same reasoning qa_reward_loop_capture.gd's own guard comment gives).
var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)

	RunState.start_new_run(_SEED, _TEAM, "short", 0, false)
	# A relic or two so the RELICS section isn't empty in the screenshot.
	for id in ["r_bastionplate", "r_ember"]:
		if RelicRegistry.get_def(id) != null:
			RunState.owned_relic_ids.append(id)
	RunState.shards_this_run = 200
	# Give one Axie a partial-looking (but still, per the map's own full-rest rule, currently
	# full) bonus_hp so the party row's HP figure isn't just the base number.
	if not RunState.roster.is_empty():
		RunState.roster[0]["bonus_hp"] = 3

	_walk_forward(3)

	var scene: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(scene)
	_map = scene
	await _settle(10)
	_shot("run_map_v2")

	print("qa_run_map_v2_capture: done, %d frame(s) written to %s" % [_shot_index, _EVIDENCE_DIR])
	_guard.restore()
	get_tree().quit(0)


## Walks the map `steps` rows deep along its own start_node_id -> next_ids chain, marking each
## node visited and advancing current_node_id — enough to give the screenshot a real "history
## behind, open row ahead" board instead of the flat bootstrap state.
func _walk_forward(steps: int) -> void:
	var graph := RunMapGraph.from_data(RunState.map_graph)
	var cur_id := graph.start_node_id
	for i in steps:
		var node := graph.find_node(cur_id)
		if node == null or node.next_ids.is_empty():
			break
		RunState.visited_node_ids.append(cur_id)
		node.visited = true
		cur_id = node.next_ids[0]
	RunState.current_node_id = cur_id
	var final_node := graph.find_node(cur_id)
	if final_node != null:
		final_node.visited = true
	RunState.map_graph = graph.to_data()


func _settle(frames: int = 6) -> void:
	for i in frames:
		await get_tree().process_frame


func _shot(tag: String) -> void:
	var vp := get_viewport()
	if vp == null:
		return
	var img := vp.get_texture().get_image()
	var path := "%s/%s_%s.png" % [_EVIDENCE_DIR, _today(), tag]
	img.save_png(path)
	_shot_index += 1
	print("qa_run_map_v2_capture: saved %s" % path)


## Today, as `YYYY-MM-DD`, for naming the files this capture writes — see
## qa_reward_loop_capture.gd's own copy of this comment for why it's stamped at run time.
func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
