extends Node
## Manual visual QA (non-headless): the combat dice thrown with 3 skins, mid-roll and settled in the tray, on
## Savannah and Luna. Env QA_SKINS (comma list) overrides the skins. Writes cos3d-dice-*.png.
var _guard := SaveGuard.new()


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var out := QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(out)
	var w := DisplayServer.window_get_size()
	get_tree().root.get_texture().get_image().save_png("%s/cos3d-dice-%s-%dx%d.png" % [out, name, w.x, w.y])
	print("QA: saved ", name)


func _ready() -> void:
	_guard.capture()
	var skins: Array = ["die_c_reed", "die_r_aqua", "die_l_gold"]
	if OS.get_environment("QA_SKINS") != "":
		skins = OS.get_environment("QA_SKINS").split(",")
	var rows := {"savannah": 1, "luna": 16}
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	for skin in skins:
		for biome in rows:
			MetaState.equipped_die_skin = skin
			RunState.start_new_run(424242, team, "long", 6, false)
			await get_tree().process_frame
			RunState.power_level = 3
			var graph := RunMapGraph.from_data(RunState.map_graph)
			var ri := clampi(int(rows[biome]), 1, graph.rows.size()) - 1
			RunState.enter_node((graph.rows[ri][0] as RunMapNode).id, "battle")
			var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
			get_tree().root.add_child(scene)
			var t0 := Time.get_ticks_msec()
			var marks := {"midair": 700, "settled": 3800}
			for k in marks:
				while Time.get_ticks_msec() - t0 < int(marks[k]):
					await get_tree().process_frame
				await _shot("%s-%s-%s" % [skin, biome, k])
			scene.queue_free()
			await get_tree().process_frame
	MetaState.equipped_die_skin = ""
	_guard.restore()
	get_tree().quit(0)
