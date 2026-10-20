extends Node
## Depth v3 lane D: reward_kind + Elite affix stamped on map nodes (own rng, deterministic), carried into
## pending_combat, and drawn on the map (badge + affix caption).
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _ready() -> void:
	_guard.capture()
	RunState.start_new_run(777, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	var g1: Dictionary = RunState.map_graph.duplicate(true)
	var shape1 := _shape(g1)
	RunState.start_new_run(777, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	_check(JSON.stringify(g1) == JSON.stringify(RunState.map_graph), "same seed -> same map incl. extras")
	var elites := 0
	var kinds_ok := true
	var affix_ok := true
	var other_clean := true
	var elite_id := ""
	for row in RunState.map_graph["rows"]:
		for n in row:
			var t := String(n["node_type"])
			if t == "battle" or t == "elite":
				kinds_ok = kinds_ok and ["level", "hp", "face", "shard"].has(String(n["reward_kind"]))
			else:
				other_clean = other_clean and String(n.get("reward_kind", "")) == ""
			if t == "elite":
				elites += 1
				elite_id = String(n["id"])
				affix_ok = affix_ok and ContentDB.elite_affixes.has(String(n["affix"]))
			elif String(n.get("affix", "")) != "":
				affix_ok = false
	_check(elites > 0 and affix_ok, "every elite has a real affix, others none")
	_check(kinds_ok and other_clean, "reward_kind on battle/elite only")
	# Map shape unchanged by the extras: same graph without them (stripped) is the shape of a plain generate.
	var plain := RunMapGenerator.generate(Rng.new(1), "short", 0).to_data()
	var stamped := RunMapGenerator.assign_extras(plain.duplicate(true), 5)
	_check(_shape(plain) == _shape(stamped), "assign_extras does not change the shape")
	# Different seeds vary.
	var s2 := JSON.stringify(RunMapGenerator.assign_extras(plain.duplicate(true), 6))
	_check(s2 != JSON.stringify(stamped), "seed changes extras")
	# Carried into the fight.
	RunState.enter_node(elite_id, "elite")
	_check(String(RunState.pending_combat.get("affix", "")) != "", "affix in pending_combat")
	# Map view shows badge + affix.
	RunState.start_new_run(777, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	var scene: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(scene)
	for _i in 10:
		await get_tree().process_frame
	_check(scene.find_child("RewardKind", true, false) != null, "reward badge on a node")
	scene.queue_free()
	_guard.restore()
	for f in _fails:
		print("t_depthv3_map: FAIL — %s" % f)
	if _fails.is_empty():
		print("t_depthv3_map: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)

func _shape(g: Dictionary) -> String:
	var out := []
	for row in g["rows"]:
		for n in row:
			out.append([n["id"], n["node_type"], n["next_ids"]])
	return JSON.stringify(out)
