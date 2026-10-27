extends Node
## QA (not headless): Missions board with the new offer card, a locked tier, and the "out of date" modal.
## godot/tools/shot.sh res://tests/qa_mission_nc_capture.tscn 1920x1080 -> production/qa/evidence/nc_*.png
var _guard := SaveGuard.new()


func _snap(name: String) -> void:
	for i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var sz := Vector2(img.get_width(), img.get_height())
	var dir := OS.get_environment("ADT_EVIDENCE_DIR")
	if dir == "":
		dir = "user://"
	img.save_png("%s/ux_%s_%s.png" % [dir, name, OS.get_environment("QA_TAG")])


func _ready() -> void:
	_guard.capture()
	MetaState.tutorial_seen = true
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	MetaState.shard_pool = 4200
	MetaState.starter_shard_locked = 0
	MetaState.mission_escrow = {}
	MetaState.set_mission_unlocks(["N1", "N2", "N3"], false)
	var ms: MissionsScreen = load("res://scenes/missions/MissionsScreen.tscn").instantiate()
	ms.use_account = false
	ms.no_scene_change = true
	ms.remote_on = false
	add_child(ms)
	await get_tree().process_frame
	ms.select_tier("N1")
	await _snap("missions_n1_open")
	ms.select_tier("N5")
	await _snap("missions_n5_locked")
	ms.remote_on = true
	ms.set_state("guest")
	ms.select_tier("N1")
	await _snap("missions_guest")
	ms.queue_free()
	RunState.start_new_run(777002, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 3, false)
	RunState.mission = {"mission_id": "m_q", "tier": 3}
	MetaState.mission_escrow = {"mission_id": "m_q", "tier": "N3", "stake": 800, "payout": 5200, "stone": 14}
	RunState.set_phase(RunState.RunPhase.LOST)
	var rv: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	add_child(rv)
	await _snap("result_lost")
	_guard.restore()
	get_tree().quit(0)
