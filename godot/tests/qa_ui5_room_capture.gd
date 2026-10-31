extends Node
## QA-only, UI-05 b23 lane R4: shots of 47-core-offer--make-room and --combo-banner.
##   ADT_EVIDENCE_DIR=production/qa/ui05-b23/r4 godot/tools/shot.sh res://tests/qa_ui5_room_capture.tscn 1280x720
var _guard := SaveGuard.new()
var _dir := QaPaths.evidence_dir()


func _shot(frame: String, small: bool) -> void:
	for _i in 10:
		await get_tree().process_frame
	var path := "%s/%s%s.png" % [_dir, frame, "--1280" if small else ""]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui5_room_capture: saved ", path)


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_dir)
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(798, team, "short", 0, false)
	RunState.owned_relic_ids.assign(["r_claw", "r_carapace", "r_pierceall", "r_cleaveall", "r_bloodmouth", "r_gorehook", "r_barbedhide", "r_heart"])
	RunState.relic_stickers = {"r_heart": "eternal"}
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	for _i in 8:
		await get_tree().process_frame
	RunState.pending_rewards = [{"t": "relic", "key": "r_seedling", "rar": 0, "title": "RELIC", "desc": "Seedling", "sub": ""}]
	m.call("_show_reward_overlay", "CHOOSE A REWARD")
	await get_tree().process_frame
	m.call("_take_selected_reward")
	await _shot("47-core-offer--make-room", small)
	var cid := ""
	for r in CoreCombos.all():
		cid = String(r.get("id", ""))
		if AnchorAdapter.house_of_combo(cid) != "":
			break
	UI3Gacha.instant_override = 0
	var house := AnchorAdapter.house_of_combo(cid)
	m.call("_close_overlay")
	var layer: Node = m.get("_overlay_layer")
	preload("res://scenes/run_map/ui5/ComboBand.gd").build(layer, "full", UI3Gacha.combo_name(cid), house, house != "")
	await get_tree().create_timer(1.5).timeout
	await _shot("47-core-offer--combo-banner", small)
	_guard.restore()
	get_tree().quit(0)
