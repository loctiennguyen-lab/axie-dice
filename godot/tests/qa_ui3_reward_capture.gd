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
	var sets := {
		"relic": ["r_bastionplate", "r_ember", "r_bastionplate"].map(func(id: String) -> Dictionary:
			var d = RelicRegistry.get_def(id)
			return {"t": "relic", "key": id, "rar": d.rarity, "title": "RELIC", "desc": d.name, "sub": RewardGenerator.relic_desc(d)}),
		"hp": [
			{"t": "hp", "rar": 0, "title": "Gene Vitality", "desc": "All Axies gain +3 max HP for the rest of the run.", "sub": ""},
			{"t": "reroll", "rar": 1, "title": "Spare Dice", "desc": "Gain one extra reroll charge.", "sub": ""},
			{"t": "curse", "rar": 3, "title": "Dark Bargain", "desc": "Gain a powerful relic, but take a curse.", "sub": ""}],
	}
	for key in sets:
		RunState.pending_rewards.assign(sets[key])
		var scene: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
		add_child(scene)
		for i in 8:
			await get_tree().process_frame
		scene.call("_show_reward_overlay", "CHOOSE ONE REWARD")
		for i in 10:
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
