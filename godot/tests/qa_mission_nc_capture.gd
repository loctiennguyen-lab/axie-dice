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
	img.save_png("%s/nc_%s_%s.png" % [dir, name, OS.get_environment("QA_TAG")])


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
	ms.select_tier("N3")
	await _snap("missions_n3")
	ms.select_tier("N5")
	await _snap("missions_n5_locked")
	ms.select_tier("N6")
	await _snap("missions_n6_locked")
	UpdateRequired.show(self, "version")
	await _snap("update_modal")
	_guard.restore()
	get_tree().quit(0)
