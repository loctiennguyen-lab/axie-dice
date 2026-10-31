extends Node
## QA-only (UI-05 b23 lane S6): Result frames 10-result--win / new-title / combos / loss / mission-lost.
## Run through qa_ui5_pin at 1280:  QA_PIN_SCENE=res://tests/qa_ui5_result_capture.tscn godot/tools/shot.sh res://tests/qa_ui5_pin.tscn 1280x720
var _guard := SaveGuard.new()
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bird1"]


func _shot(tag: String, id: String) -> void:
	for i in 10:
		await get_tree().process_frame
	var dir := OS.get_environment("S6_OUT") if OS.get_environment("S6_OUT") != "" else QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/%s-%s.png" % [dir, id, tag])


func _stage(won: bool, ranked: bool, mission: bool, power: int) -> Node:
	RunState.start_new_run(777001, TEAM, "short", 5, ranked)
	RunState.power_level = power
	RunState.shards_this_run = 87
	RunState.owned_relic_ids.assign(["r_claw", "r_carapace", "r_pierceall"])
	RunState.run_stats = {"dmg": 913, "dmg_dealt_clamped": 913, "taken": 140, "turns": 41, "kills": 23, "max_hit": 31}
	if mission:
		RunState.mission = {"mission_id": "m_cap", "condition": ""}
		MetaState.mission_escrow = {"mission_id": "m_cap", "tier": "N3", "stake": 800, "payout": 7240, "stone": 14}
	else:
		RunState.mission = {}
		MetaState.mission_escrow = {}
	RunState.set_phase(RunState.RunPhase.WON if won else RunState.RunPhase.LOST)
	var v: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(v)
	return v


func _ready() -> void:
	_guard.capture()
	var tag := "%d" % int(DisplayServer.window_get_size().x)
	MetaState.best = 3
	var v := _stage(true, true, false, 14)
	await _shot(tag, "10-result--win")
	var row: Control = v.call("_build_title_unlock", {"new_titles": [String(TitleNames.ascension_titles()[0]["id"])]})
	var outer := v.find_child("ResultPlate", true, false).get_child(0)
	outer.add_child(row)
	outer.move_child(row, 1)
	await _shot(tag, "10-result--new-title")
	v.queue_free()
	await get_tree().process_frame
	v = _stage(false, false, false, 6)
	await _shot(tag, "10-result--loss")
	v.queue_free()
	await get_tree().process_frame
	v = _stage(false, false, true, 6)
	await _shot(tag, "10-result--mission-lost")
	v.queue_free()
	RunState.mission = {}
	MetaState.mission_escrow = {}
	_guard.restore()
	get_tree().quit(0)
