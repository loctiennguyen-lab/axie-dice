extends Node
## One-off capture: the Venom Chimera (3D, rigged) in a real boss fight, reached through the
## real flow (Short run, final boss row -> agony, which now wears chimera_venom_01.glb).
##
##   ADT_EVIDENCE_DIR=/some/dir godot/tools/shot.sh res://tests/qa_feral_boss.tscn 1920x1080
##
## Saves idle / attack / hit / cast / roar frames as feral_<W>_<state>.png. Not part of the suite
## (no t_ prefix): it needs a real renderer. Real save is borrowed and restored (SaveGuard).

var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(424242, team, "short", 0, false)
	await get_tree().process_frame
	RunState.power_level = 9
	# The final boss row of a Short run is always agony (RunState._build_boss_plan). Read the
	# row off the generated map instead of hardcoding it: the map was rescaled once already.
	var graph := RunMapGraph.from_data(RunState.map_graph)
	var final_row: int = graph.boss_rows[graph.boss_rows.size() - 1]
	var node_id := String((graph.get_row(final_row)[0] as RunMapNode).id)
	RunState.enter_node(node_id, "boss")
	RunState.pending_combat["boss_key"] = "mirror"
	print("QA: boss_key = ", RunState.pending_combat.get("boss_key", "<none>"))
	await get_tree().process_frame
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for i in 150:
		await get_tree().process_frame
	var stage: CombatStage3D = scene._stage3d
	var boss_uid := -1
	for e in scene._combat.enemies:
		print("QA: enemy key=%s is_boss=%s hp=%d" % [e.key, e.is_boss, e.max_hp])
		if e.is_boss:
			boss_uid = e.uid
	var target: int = (scene._combat.party[0] as Unit).uid
	var w := get_viewport().get_visible_rect().size.x
	var tag := "feral_%d" % int(DisplayServer.window_get_size().x)
	_save(tag + "_idle")
	await _wait(0.9)
	_save(tag + "_idle2")
	if boss_uid >= 0:
		stage.play_action(boss_uid, "", target)
		await _wait(0.28)
		_save(tag + "_attack_windup")
		await _wait(0.2)
		_save(tag + "_attack")
		await _wait(1.6)
		stage.play_hit_reaction(boss_uid)
		await _wait(0.1)
		_save(tag + "_hit")
		await _wait(1.2)
		var entry: Dictionary = stage._units[boss_uid]
		stage._atia_play(entry["atia"], "cast")
		await _wait(0.6)
		_save(tag + "_cast")
		await _wait(1.2)
		stage._atia_play(entry["atia"], "roar")
		await _wait(0.75)
		_save(tag + "_roar")
		await _wait(1.6)
		stage.play_death(boss_uid)
		await _wait(1.2)
		_save(tag + "_dead")
	print("QA: feral capture done (viewport %d)" % w)
	_guard.restore()
	get_tree().quit(0)


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _save(name: String) -> void:
	get_tree().root.get_texture().get_image().save_png(QaPaths.evidence_dir() + "/" + name + ".png")
	print("QA: saved ", name)
