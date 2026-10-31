extends Node
## UI-05 b23 lane M2 capture: anchor-awaken (pill, hint, disc) and core-reveal (name punch) mid-moment. Not headless:
##   ADT_EVIDENCE_DIR=$PWD/production/qa/ui05-b23/m2 godot/tools/shot.sh res://tests/qa_ui5_moments_b2_capture.tscn 1920x1080
var _guard := SaveGuard.new()
var _out := ""


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	_out = OS.get_environment("ADT_EVIDENCE_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b23/m2").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	MetaState.reduce_motion = false
	MetaState.reduce_flash = false
	var size := get_window().size
	UI3Theme.set_scale_override(1.0 if size.x >= 1600 else 2.0 / 3.0)
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(host)
	var bg := ColorRect.new()
	bg.color = UI3Theme.color("bg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(bg)
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "awakened": true, "owned": []}
	AnchorFx.played_run = ""
	AnchorFx.arm("a_volley")
	await get_tree().process_frame
	var fx := AnchorFx.play(host, "a_volley")
	await _wait(0.9)
	await _shot("anchor-awaken-mid")
	await _wait(1.0)
	await _shot("anchor-awaken-rest")
	fx.skip()
	host.queue_free()
	AnchorAdapter.test_state = {}
	await get_tree().process_frame
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": true})
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	for _i in 8:
		await get_tree().process_frame
	rm._select_reward(1)
	await get_tree().process_frame
	rm._take_selected_reward()
	await _wait(1.3)
	await _shot("core-reveal-a")
	await _wait(0.5)
	await _shot("core-reveal-b")
	await _wait(2.0)
	await _shot("core-reveal-rest")
	_guard.restore()
	get_tree().quit()
