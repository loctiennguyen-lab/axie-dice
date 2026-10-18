extends Node
## Manual visual QA for the UI-03 Reward screen (07). Run non-headless via tools/shot.sh.
var _EVIDENCE_DIR := QaPaths.evidence_dir()
var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	RunState.start_new_run(555001, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 0, false)
	RunState.shards_this_run = 40
	RunState.reward_reroll_charges = 1
	var size := get_viewport().get_visible_rect().size
	var tag := "%dx%d" % [int(DisplayServer.window_get_size().x), int(DisplayServer.window_get_size().y)]
	var rng := Rng.new(77)
	var none: Array[Dictionary] = []
	var rost: Array = RunState.roster
	var chaos := RewardGenerator._make_chaos_reward(rng, RunState.owned_relic_ids, none)
	var curse := RewardGenerator._make_curse_reward(none)
	var lvl := RewardGenerator._make_level_reward(rng, rost, none)
	var asc := RewardGenerator._make_ascend_reward(rng, rost, none)
	var hp := RewardGenerator._make_reward("hp", [0, 1], 2, rng, [], rost, none)
	var rr := RewardGenerator._make_reward("reroll", [0, 1], 2, rng, [], rost, none)
	var relics := ["r_bastionplate", "r_ember"].map(func(id: String) -> Dictionary:
		var d = RelicRegistry.get_def(id)
		return {"t": "relic", "key": id, "rar": d.rarity, "title": "RELIC", "desc": d.name, "sub": RewardGenerator.relic_desc(d)})
	var sets := {
		"relic": [relics[0], relics[1], relics[0]],
		"hp": [hp, rr, lvl],
		"ascend": [asc, hp, rr],
		"chaos": [relics[0], chaos, curse],
		"chaos-confirm": [relics[0], chaos, curse],
	}
	for key in sets:
		RunState.pending_rewards.assign((sets[key] as Array).filter(func(x): return not (x as Dictionary).is_empty()))
		var scene: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
		add_child(scene)
		for i in 8:
			await get_tree().process_frame
		scene.call("_show_reward_overlay", "CHOOSE ONE REWARD")
		for i in 10:
			await get_tree().process_frame
		if key == "chaos-confirm":
			scene.call("_select_reward", 1)
			scene.call("_take_selected_reward")
			for i in 6:
				await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var path := "%s/ui3-reward-%s-%s.png" % [_EVIDENCE_DIR, key, tag]
		img.save_png(path)
		print("qa_ui3_reward_capture: saved %s" % path)
		scene.queue_free()
		for i in 3:
			await get_tree().process_frame
	_guard.restore()
	get_tree().quit(0)
