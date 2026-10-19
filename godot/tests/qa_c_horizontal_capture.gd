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
		for st in ["n2", "n3", "n5", "aelite", "aboss", "an2", "an3", "an5"]:
			if _want(st):
				var arctic: bool = st.begins_with("a")
				var row := 8 if arctic else 3
				var knd := "battle"
				if st == "aelite":
					row = int(graph.elite_rows[2]) if false else 9
					knd = "elite"
				if st == "aboss":
					row = int(graph.boss_rows[0])
					knd = "boss"
				await _fight(st, _find(graph, row, knd), knd, size)
		for st in ["e1", "e3", "e5", "bosssum", "eggs4", "throw11"]:
			if _want(st):
				await _fight(st, _find(graph, int(graph.boss_rows[0]), "boss") if st == "bosssum" else _find(graph, 3, "battle"), "boss" if st == "bosssum" else "battle", size)
		if _want("throw"):
			await _fight("throw", _find(graph, 3, "battle"), "battle", size)
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
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	img.save_png("%s/c-%s-%dx%d.png" % [_out, state, size.x, size.y])
	print("QA: saved c-%s-%dx%d" % [state, size.x, size.y])


func _fight(state: String, node_id: String, kind: String, size: Vector2i) -> void:
	RunState.power_level = 9 if kind == "boss" else 4
	RunState.enter_node(node_id, kind)
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in (14 if state == "throw" else 90):
		await get_tree().process_frame
	if state == "throw11":
		scene._land_dice_now()
		for _k in 4:
			scene._combat.party.append(scene._combat._mk_ally())
		for u in scene._combat.party:
			if u.hp > 0 and not u.has_rolled():
				scene._combat._roll_unit(u)
		scene._sync_unit_visuals()
		for _i in 8:
			await get_tree().process_frame
		scene._last_die_face.clear()
		scene._rebuild_all()
		for _i in 12:
			await get_tree().process_frame
		await _shot("throw11-a", size)
		for _i in 16:
			await get_tree().process_frame
		await _shot("throw11-b", size)
		for _i in 100:
			await get_tree().process_frame
		await _shot("throw11-c", size)
		scene.queue_free()
		await get_tree().process_frame
		return
	if state == "throw":
		await _shot("throw-a", size)
		for _i in 14:
			await get_tree().process_frame
		await _shot("throw-b", size)
		for _i in 14:
			await get_tree().process_frame
		await _shot("throw-c", size)
		scene.queue_free()
		await get_tree().process_frame
		return
	scene._land_dice_now()
	print("QA: gate rect ", scene._stage3d.gate_screen_rect(), " arena pos ", scene._stage3d._arena.position if scene._stage3d._arena != null else "none", " stage size ", scene._stage3d.size)
	if OS.get_environment("CAP_DEBUG") != "":
		var st: Node = scene._stage3d
		for n in st.find_children("*", "Light3D", true, false):
			print("DBG light ", n.get_path(), " e=", (n as Light3D).light_energy, " pos=", (n as Node3D).global_position)
		for n in st.find_children("*", "GPUParticles3D", true, false) + st.find_children("*", "CPUParticles3D", true, false):
			print("DBG particles ", n.get_path(), " emitting=", n.emitting)
	if OS.get_environment("CAP_DEBUG") == "5":
		scene._stage3d.visible = false
		await get_tree().process_frame
		await get_tree().process_frame
		await _shot("nostage", size)
		scene._stage3d.visible = true
		scene._unit_visuals_root.visible = false
		await get_tree().process_frame
		await get_tree().process_frame
		await _shot("novisuals", size)
		scene._unit_visuals_root.visible = true
	if OS.get_environment("CAP_DEBUG") == "4":
		var sv = scene._skill_vfx
		print("DBG skillvfx valid=", is_instance_valid(sv), " children=", (sv.get_child_count() if is_instance_valid(sv) else -1))
	if OS.get_environment("CAP_DEBUG") == "3":
		for uid in scene._stage3d._units:
			var en: Dictionary = scene._stage3d._units[uid]
			var vis: Node3D = en["visual"]
			var bb: AABB = CombatStage3D._model_aabb(vis)
			var raw: Vector2 = CombatStage3D._visual_bounds(vis)
			print("DBG unit ", uid, " enemy=", en["is_enemy"], " boss=", en["is_boss"], " vis_y=", vis.global_position.y, " aabb_y=", bb.position.y, "..", bb.end.y, " raw=", raw, " scale=", vis.scale, " atia=", not (en["atia"] as Dictionary).is_empty())
	if OS.get_environment("CAP_DEBUG") == "2":
		var st2: Node = scene._stage3d
		var roller: Node = st2.get_dice_roller()
		for c in roller.get_children():
			print("DBG roller child ", c.name, " ", c.get_class())
		print("DBG roller class ", roller.get_class(), " parent ", roller.get_parent().name)
		await _shot("dbgA", size)
		var probe := Vector2i(960, 430)
		var base_c: Color = get_tree().root.get_texture().get_image().get_pixelv(probe)
		print("DBG base ", base_c)
		var cands: Array = st2._world.get_children()
		cands.append_array(st2._world.get_node("Slot_100000").get_children())
		for c in cands:
			if not (c is Node3D):
				continue
			var was: bool = (c as Node3D).visible
			(c as Node3D).visible = false
			await get_tree().process_frame
			await get_tree().process_frame
			var col: Color = get_tree().root.get_texture().get_image().get_pixelv(probe)
			print("DBG hide ", c.name, " -> ", col, " delta=", snappedf(absf(col.r - base_c.r) + absf(col.g - base_c.g) + absf(col.b - base_c.b), 0.001))
			(c as Node3D).visible = was
		var ent: Dictionary = st2._units[100000]
		(ent["visual"] as Node3D).visible = false
		await get_tree().process_frame
		await _shot("dbgB", size)
	if state == "aboss":
		scene._stage3d.set_arena("arctic", true)
		for _i in 10:
			await get_tree().process_frame
	if state in ["n2", "n3", "n5", "an2", "an3", "an5"]:
		var want_n := int(state.right(1))
		var ens: Array = scene._combat.enemies
		var keys := ["chomper", "slime", "bugling", "spikelet", "ravenling"]
		while ens.size() < want_n:
			ens.append(scene._combat._mk_monster(keys[ens.size() % keys.size()], 1.0, {}))
		scene._sync_unit_visuals()
		var live: Array = []
		for k in ens.size():
			var uid_k: int = ens[k].uid
			if k < want_n:
				live.append(uid_k)
			else:
				scene._stage3d._units[uid_k]["slot"].visible = false
		scene._stage3d.reseat_side(live, true)
	if state == "e5":
		while scene._combat.enemies.size() < 5:
			scene._combat.enemies.append(scene._combat._mk_monster(["chomper", "slime", "bugling", "spikelet", "ravenling"][scene._combat.enemies.size()], 1.0, {}))
		scene._sync_unit_visuals()
		scene._rebuild_all()
	if state == "e1":
		var first_uid: int = scene._combat.enemies[0].uid
		for k in range(1, scene._combat.enemies.size()):
			var en_uid: int = scene._combat.enemies[k].uid
			scene._stage3d._units[en_uid]["slot"].visible = false
		scene._stage3d.reseat_side([first_uid], true)
	if state == "bosssum":
		scene._combat.spawn_boss_add(scene._combat.enemies[0], 1.0)
		scene._combat.spawn_boss_add(scene._combat.enemies[0], 1.0)
		scene._sync_unit_visuals()
		scene._rebuild_all()
	if state == "eggs" or state == "eggs4":
		for _k in (3 if state == "eggs" else 4):
			scene._combat.party.append(scene._combat._mk_ally())
		scene._sync_unit_visuals()
		scene._rebuild_all()
	for _i in (int(OS.get_environment("CAP_WAIT")) if OS.get_environment("CAP_WAIT") != "" else 12):
		await get_tree().process_frame
	if state == "march" or state == "marchluna":
		scene._play_victory_march()
		await get_tree().create_timer(0.3).timeout
		await _shot(state + "-a", size)
		await get_tree().create_timer(0.3).timeout
		await _shot(state + "-b", size)
		await get_tree().create_timer(0.2).timeout
		await _shot(state + "-c", size)
		scene._stage3d.skip_victory_march()
	else:
		await _shot(state, size)
	for _i in 20:
		await get_tree().process_frame
	scene.queue_free()
	await get_tree().process_frame
