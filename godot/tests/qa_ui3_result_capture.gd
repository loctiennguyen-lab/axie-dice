extends Node
## Manual visual QA for UI-03 10 (Result). Run non-headless via tools/shot.sh.
var _EVIDENCE_DIR := QaPaths.evidence_dir()
var _guard := SaveGuard.new()
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _shot(tag: String, name: String) -> void:
	for i in 8:
		await get_tree().process_frame
	var path := "%s/ui3-result-%s-%s.png" % [_EVIDENCE_DIR, name, tag]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui3_result_capture: saved %s" % path)


func _stage(won: bool, ranked: bool, mission: bool, power: int) -> Node:
	RunState.start_new_run(777001, TEAM, "short", 5, ranked)
	RunState.power_level = power
	RunState.shards_this_run = 87
	RunState.owned_relic_ids.assign(["r_claw", "r_carapace", "r_pierceall", "r_bloodmouth", "r_heart"])
	RunState.run_stats = {"dmg": 913, "dmg_dealt_clamped": 913, "taken": 140, "turns": 41, "kills": 23, "max_hit": 31}
	if mission:
		RunState.mission = {"mission_id": "m_cap", "condition": ""}
		MetaState.mission_escrow = {"mission_id": "m_cap", "tier": "t1", "stake": 25, "payout": 60, "stone": 0}
	else:
		RunState.mission = {}
		MetaState.mission_escrow = {}
	RunState.set_phase(RunState.RunPhase.WON if won else RunState.RunPhase.LOST)
	var v: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(v)
	return v


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	var tag := "%dx%d" % [int(DisplayServer.window_get_size().x), int(DisplayServer.window_get_size().y)]
	MetaState.best = 3
	var v := _stage(true, false, false, 14)
	await _shot(tag, "win-record")
	v.queue_free()
	MetaState.last_run_new_titles = []
	v = _stage(true, false, true, 2)
	await _shot(tag, "win-stake")
	v.queue_free()
	await get_tree().process_frame
	v = _stage(false, false, true, 6)
	await _shot(tag, "loss-stake")
	v.queue_free()
	await get_tree().process_frame
	v = _stage(false, true, false, 6)
	await get_tree().process_frame
	v.show_submit_notice(false, "offline")
	await _shot(tag, "offline")
	v.queue_free()
	RunState.mission = {}
	MetaState.mission_escrow = {}
	_guard.restore()
	get_tree().quit(0)
