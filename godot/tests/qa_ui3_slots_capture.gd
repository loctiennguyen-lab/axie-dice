extends Node
## Manual visual QA for UI-03 32 (slots full: swap / sell). Run non-headless via tools/shot.sh.
var _EVIDENCE_DIR := QaPaths.evidence_dir()
var _guard := SaveGuard.new()


func _shot(tag: String, name: String) -> void:
	for i in 8:
		await get_tree().process_frame
	var path := "%s/ui3-slots-%s-%s.png" % [_EVIDENCE_DIR, name, tag]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui3_slots_capture: saved %s" % path)


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	RunState.start_new_run(555002, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 0, false)
	RunState.shards_this_run = 40
	var tag := "%dx%d" % [int(DisplayServer.window_get_size().x), int(DisplayServer.window_get_size().y)]
	var passives := ["r_claw", "r_carapace", "r_pierceall", "r_cleaveall", "r_bloodmouth", "r_gorehook", "r_barbedhide", "r_heart"]
	var actives := ["a_pyre", "a_bramblewall", "a_plague"]
	for mode in ["passive", "active", "treasure"]:
		RunState.owned_relic_ids.assign(actives if mode == "active" else passives)
		RunState.relic_stickers = {"r_heart": "eternal"} if mode != "active" else {}
		var key := "a_ult" if mode == "active" else "r_seedling"
		var d = RelicRegistry.get_def(key)
		RunState.pending_rewards.assign([{"t": "relic", "key": key, "rar": d.rarity, "title": "RELIC", "desc": d.name, "sub": RewardGenerator.relic_desc(d)}])
		var scene: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
		add_child(scene)
		for i in 8:
			await get_tree().process_frame
		if mode == "treasure":
			scene.call("_build_treasure", true)
		else:
			scene.call("_show_reward_overlay", "CHOOSE ONE REWARD")
		await get_tree().process_frame
		scene.call("_take_selected_reward")
		await get_tree().process_frame
		var sh := scene.find_child("SlotSwapSheet", true, false)
		if sh != null and mode == "passive":
			(sh.find_child("SlotCell_r_gorehook", true, false) as Button).pressed.emit()
		await _shot(tag, mode)
		scene.queue_free()
		for i in 3:
			await get_tree().process_frame
	# forced pact: no Leave it
	var sheet := UI3.slot_swap_sheet("Make room", "Pact relic", "Forced boss pact: you cannot cancel.", "Passive slots are full (8 of 8). Sell one to take the pact.",
		passives.map(func(id: String) -> Dictionary:
			return {"id": id, "name": id, "kind": "Passive", "sell": 20, "eternal": id == "r_heart"}), true, func(_s): pass, func(): pass)
	add_child(sheet)
	await _shot(tag, "forced")
	_guard.restore()
	get_tree().quit(0)
