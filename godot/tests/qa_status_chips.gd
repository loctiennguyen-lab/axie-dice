extends Node
## One-off capture: over-head status chips on 3D enemies of every size. Boss fight (agony = Venom) and an elite
## fight, every enemy and the party leader carrying a status, shot at the current window size.
##
##   ADT_EVIDENCE_DIR=/some/dir godot/tools/shot.sh res://tests/qa_status_chips.tscn 1280x720
## Writes chips_<W>_boss.png and chips_<W>_elite.png and prints each chip anchor vs the unit's model rect.

var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	for kind in ["boss", "elite"]:
		RunState.start_new_run(424242, team, "short", 0, false)
		await get_tree().process_frame
		RunState.power_level = 9
		var graph := RunMapGraph.from_data(RunState.map_graph)
		var row: int = graph.boss_rows[graph.boss_rows.size() - 1] if kind == "boss" else 1
		var node_id := String((graph.get_row(row)[0] as RunMapNode).id)
		RunState.enter_node(node_id, kind)
		if kind == "boss":
			RunState.pending_combat["boss_key"] = "agony"
		await get_tree().process_frame
		var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(scene)
		for i in 150:
			await get_tree().process_frame
		for e in scene._combat.enemies:
			e.status["weaken"] = 2
			e.status["poison"] = 3
		(scene._combat.party[0] as Unit).status["weaken"] = 2
		scene._layout_unit_visuals()
		await get_tree().process_frame
		await get_tree().process_frame
		var stage: CombatStage3D = scene._stage3d
		var off: Vector2 = stage.position
		for e in scene._combat.enemies:
			var rect := stage.unit_screen_rect(e.uid)
			var head_h: float = stage.head_height_of(e.uid, CombatStage3D.HEAD_HEIGHT)
			var chip := stage.get_unit_screen_pos(e.uid, head_h) + off - Vector2(0, 8)
			print("QA: %s key=%s boss=%s model_rect=%s chip=%s (rect top y=%.0f, chip y=%.0f)" % [kind, e.key, e.is_boss, rect, chip, rect.position.y + off.y, chip.y])
		_save("chips_%d_%s" % [int(DisplayServer.window_get_size().x), kind])
		scene.queue_free()
		await get_tree().process_frame
	_guard.restore()
	get_tree().quit(0)


func _save(name: String) -> void:
	get_tree().root.get_texture().get_image().save_png(QaPaths.evidence_dir() + "/" + name + ".png")
	print("QA: saved ", name)
