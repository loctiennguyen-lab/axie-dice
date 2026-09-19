extends Node
## Headless logic gate for RunMapController's node-classification functions
## (_reachable_now_ids/_current_row/_node_tier/_is_fogged — design/ux/
## combat-screen-shroom-gloom-inspired.md §5.4, Decision 4). Per coding-standards.md's test-type
## table, this is "Logic (state machine)" — BLOCKING, not the "Visual/Feel" ADVISORY tier the
## screenshot evidence already covers for this same feature; this test is the missing blocking
## piece for the classification MATH specifically (current/reachable/visited/fog priority + the
## "2+ rows beyond" arithmetic), independent of rendering.
##
## Builds a small hand-authored RunMapGraph (NOT RunMapGenerator output — test-standards.md:
## "test data must be defined in the test ... never shared mutable state") shaped specifically to
## exercise every branch:
##   row1: n1 (start, next_ids=[n2a,n2b,n_far])
##   row2: n2a, n2b (both IN n1.next_ids), n2c (NOT in n1.next_ids — an inert unchosen sibling)
##   row3: n3a, n3b (2 rows beyond n1 — the fog boundary)
##   row5: n_far (4 rows beyond n1, but reachable via next_ids anyway — regression-tests that
##         current/reachable ALWAYS override the raw row-distance fog test, no matter how far)
##
## White-box access via .call()/.get() on the real RunMap.tscn instance — same established
## pattern as t_stage3d_facing.gd (`stage.get("_units")`) / t_combatview_smoke.gd
## (`_view.call("_on_die_slot_pressed", idx)`).
##
## Run: godot --headless --path godot tests/t_run_map_fog.tscn

var _anomaly := ""


func _ready() -> void:
	var tree := get_tree()
	RunState.reset()
	RunState.map_graph = _build_synthetic_graph().to_data()
	RunState.current_node_id = ""
	RunState.visited_node_ids = []

	var runmap: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(runmap)
	await tree.process_frame   # let _ready()/_refresh(false) run against the synthetic graph

	var graph: RunMapGraph = runmap.get("_graph")
	_check(graph != null, "RunMapController never built _graph from RunState.map_graph")
	if _anomaly != "":
		_fail(tree)
		return

	# --- Scenario A: bootstrap (current_node_id == "") ---
	var reachable: Array = runmap.call("_reachable_now_ids")
	_check(reachable.size() == 1 and reachable[0] == "n1",
		"bootstrap reachable_now_ids() expected [n1], got %s" % [reachable])
	_check(int(runmap.call("_current_row")) == 0,
		"bootstrap _current_row() expected 0, got %d" % int(runmap.call("_current_row")))

	_assert_tier(runmap, graph, "n1", "reachable", "bootstrap: start node")
	_assert_tier(runmap, graph, "n2a", "fog", "bootstrap: row2 (2 rows beyond row0)")
	_assert_tier(runmap, graph, "n_far", "fog", "bootstrap: row5, not yet reachable")

	# --- Scenario B: current_node_id = n1 (picked + resolved, mirrors after_node()) ---
	RunState.current_node_id = "n1"
	RunState.visited_node_ids = ["n1"]

	reachable = runmap.call("_reachable_now_ids")
	_check(reachable.size() == 3 and reachable[0] == "n2a" and reachable[1] == "n2b" and reachable[2] == "n_far",
		"post-pick reachable_now_ids() expected [n2a,n2b,n_far], got %s" % [reachable])
	_check(int(runmap.call("_current_row")) == 1,
		"post-pick _current_row() expected 1 (n1's row), got %d" % int(runmap.call("_current_row")))

	_assert_tier(runmap, graph, "n1", "current",
		"post-pick: n1 is current_node_id (and visited) — current check must win over visited")
	_assert_tier(runmap, graph, "n2a", "reachable", "post-pick: in n1.next_ids")
	_assert_tier(runmap, graph, "n2b", "reachable", "post-pick: in n1.next_ids")
	_assert_tier(runmap, graph, "n_far", "reachable",
		"post-pick: row5 is 4 rows beyond row1 (would fog by raw distance) but IS in " +
		"next_ids — reachable must override the row-distance fog test")
	_assert_tier(runmap, graph, "n2c", "dim",
		"post-pick: row2 (only 1 row beyond), not visited/current/reachable -> dim, NOT fogged")
	_assert_tier(runmap, graph, "n3a", "fog", "post-pick: row3 is 2 rows beyond row1 -> fog")
	_assert_tier(runmap, graph, "n3b", "fog", "post-pick: row3 is 2 rows beyond row1 -> fog")

	# --- Scenario C: a node 2+ rows out that was nonetheless visited (edge case) must read as
	# "dim", never "fog" — "the player's own past is never mysterious" (spec §5.4 rule 3) has to
	# win over the raw row-distance test, same priority-ordering concern as scenario B's n_far.
	var n3a: RunMapNode = graph.find_node("n3a")
	n3a.visited = true
	_check(not bool(runmap.call("_is_fogged", n3a, int(runmap.call("_current_row")), reachable)),
		"n3a.visited=true must never be fogged, regardless of row distance")
	_assert_tier(runmap, graph, "n3a", "dim", "post-pick + visited: visited overrides fog")

	if _anomaly == "":
		print("t_run_map_fog: PASS — _reachable_now_ids/_current_row/_node_tier/_is_fogged all " +
			"resolve current > reachable > visited > row-distance-fog in the correct priority")
		tree.quit(0)
	else:
		_fail(tree)


func _assert_tier(runmap: Node, graph: RunMapGraph, node_id: String, expected_tier: String, context: String) -> void:
	var node: RunMapNode = graph.find_node(node_id)
	var current_row := int(runmap.call("_current_row"))
	var reachable: Array = runmap.call("_reachable_now_ids")
	var tier: String = runmap.call("_node_tier", node, current_row, reachable)
	_check(tier == expected_tier,
		"%s: _node_tier(%s) expected '%s', got '%s'" % [context, node_id, expected_tier, tier])
	var fogged: bool = runmap.call("_is_fogged", node, current_row, reachable)
	_check(fogged == (expected_tier == "fog"),
		"%s: _is_fogged(%s) expected %s, got %s" % [context, node_id, expected_tier == "fog", fogged])


## Hand-authored graph shape — see file header for why each node exists.
func _build_synthetic_graph() -> RunMapGraph:
	var rows_data: Array = [
		[_node_data("n1", 1, 0, "battle", ["n2a", "n2b", "n_far"])],
		[
			_node_data("n2a", 2, 0, "event", ["n3a"]),
			_node_data("n2b", 2, 1, "battle", ["n3a", "n3b"]),
			_node_data("n2c", 2, 2, "shop", []),
		],
		[
			_node_data("n3a", 3, 0, "shop", []),
			_node_data("n3b", 3, 1, "boss", []),
		],
		[],
		[_node_data("n_far", 5, 0, "treasure", [])],
	]
	return RunMapGraph.from_data({
		"rows": rows_data, "boss_rows": [3], "elite_rows": [], "start_node_id": "n1",
	})


func _node_data(id: String, row: int, col: int, node_type: String, next_ids: Array) -> Dictionary:
	return {
		"id": id, "row": row, "col": col, "node_type": node_type,
		"next_ids": next_ids, "visited": false, "locked": false,
	}


func _check(cond: bool, msg: String) -> void:
	if not cond and _anomaly == "":
		_anomaly = msg


func _fail(tree: SceneTree) -> void:
	push_error("t_run_map_fog: FAIL — %s" % _anomaly)
	print("t_run_map_fog: FAIL — %s" % _anomaly)
	tree.quit(1)
