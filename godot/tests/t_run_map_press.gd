extends Node
## Run map mouse rule: the first press on a reachable node only selects it; a second press on the
## same node within the window (or a double-click) travels. Never for a node you cannot reach, and
## A -> B -> A single clicks never travel.

var _fails: Array[String] = []
var _checks := 0
var _travelled: Array[String] = []
var _guard := SaveGuard.new()


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _nd(id: String, row: int, col: int, t: String, nxt: Array) -> Dictionary:
	return {"id": id, "row": row, "col": col, "node_type": t, "next_ids": nxt, "visited": false, "locked": false}


func _click(m: Node, id: String, dbl := false) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.double_click = dbl
	m.call("_on_token_input", ev, id)
	await get_tree().process_frame
	await get_tree().process_frame


func _ready() -> void:
	await get_tree().process_frame
	_guard.capture()
	RunState.reset()
	RunState.map_graph = RunMapGraph.from_data({"rows": [
		[_nd("n1", 1, 0, "battle", ["n2a", "n2b"])],
		[_nd("n2a", 2, 0, "event", []), _nd("n2b", 2, 1, "battle", []), _nd("n2c", 2, 2, "shop", [])],
		[_nd("n3a", 3, 0, "shop", [])],
	], "boss_rows": [3], "elite_rows": [], "start_node_id": "n1"}).to_data()
	RunState.current_node_id = "n1"
	RunState.visited_node_ids = ["n1"]
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	m.set("no_travel", true)
	add_child(m)
	await get_tree().process_frame
	m.connect("travel_requested", func(id: String) -> void: _travelled.append(id))

	await _click(m, "n2a")
	_check(_travelled.is_empty() and m.get("_selected_id") == "n2a", "first press only selects")
	await _click(m, "n2a")
	_check(_travelled == ["n2a"], "second press on the same node travels")
	_travelled.clear()

	await _click(m, "n2b")
	await _click(m, "n2a")
	await _click(m, "n2b")
	await _click(m, "n2a")
	_check(_travelled.is_empty(), "A -> B -> A -> B -> A single clicks never travel")

	await _click(m, "n2b")
	m.set("_pressed_once_ms", int(m.get("_pressed_once_ms")) - 1000)
	await _click(m, "n2b")
	_check(_travelled.is_empty(), "a second press after the window only selects")

	await _click(m, "n2a", true)
	_check(_travelled == ["n2a"], "double-click travels at once")
	_travelled.clear()

	await _click(m, "n2c")
	await _click(m, "n2c")
	await _click(m, "n3a", true)
	_check(_travelled.is_empty(), "a node you cannot reach never travels")

	_guard.restore()
	if _fails.is_empty():
		print("t_run_map_press: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_run_map_press: FAIL - " + f)
		get_tree().quit(1)
