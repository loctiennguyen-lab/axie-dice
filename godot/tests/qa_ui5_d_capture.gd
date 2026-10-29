extends Node
## UI-05 b1 lane D visual capture: the 10 panel frames of ui05-combat-panels.html (30-defeat x4, 31-reward x5,
## boss-intro) at the window size. Not headless:
##   godot/tools/shot.sh res://tests/qa_ui5_d_capture.tscn 1920x1080   (and 1280x720)
## Files: production/qa/ui05-b1/d/<frame id>[--1280].png, named like the HTML frames. The 1280 run forces the
## 0.667 scale (the canvas_items stretch the design assumes), whatever the display's pixel ratio.
## Real saves are restored by SaveGuard.

var _guard := SaveGuard.new()
var _out := ""
var _suffix := ""


func _ready() -> void:
	_guard.capture()
	_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b1/d").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	var small := get_window().size.x < 1600
	_suffix = "--1280" if small else ""
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	await _frames(5)
	var only := OS.get_environment("AXIE_ONLY")
	if only == "" or only == "defeat":
		await _defeat("30-defeat--paid", "battle", "r4_c0", 6, 20, 500, false)
		await _defeat("30-defeat--free", "boss", "r12_c0", 0, 0, 0, false)
		await _defeat("30-defeat--normal", "battle", "r4_c0", 6, 20, 30, false)
		await _defeat("30-defeat--mission", "battle", "r4_c0", 6, 20, 500, true)
	if only == "" or only == "reward":
		await _rewards()
	if only == "" or only == "boss":
		await _boss("frost_lord")
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _save(id: String) -> void:
	var path := "%s/%s%s.png" % [_out, id, _suffix]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui5_d_capture: saved %s" % path)


func _defeat(id: String, kind: String, node_id: String, asc: int, battles: int, gems: int, mission: bool) -> void:
	MetaState.runs_with_battle = battles
	MetaState.free_continue_used = false
	MetaState.gems_cache = gems
	if mission:
		MetaState.mission_escrow = {"stake": 60}
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", asc, false)
	await get_tree().process_frame
	RunState.power_level = 9 if kind == "boss" else 3
	RunState.enter_node(node_id, kind)
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	await _frames(90)
	scene._land_dice_now()
	var combat: CombatEngine = scene._combat
	combat.lost = true
	combat.mission = mission
	for e in combat.enemies:
		if e.is_boss:
			e.hp = int(e.max_hp * 0.5)
	scene._show_defeat_panel()
	await _frames(10)
	await get_tree().create_timer(0.9).timeout   # scrim 240 + panel at +200 must finish
	await _save(id)
	scene.queue_free()
	MetaState.mission_escrow = {}
	await _frames(3)


func _rewards() -> void:
	RunState.start_new_run(555001, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 0, false)
	RunState.shards_this_run = 40
	RunState.reward_reroll_charges = 1
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
		"31-reward--hp": [hp, rr, lvl],
		"31-reward--core": [relics[0], relics[1], relics[0]],
		"31-reward--ascend": [asc, hp, rr],
		"31-reward--chaos": [relics[0], chaos, curse],
		"31-reward--chaos-confirm": [relics[0], chaos, curse],
	}
	for key in sets:
		RunState.pending_rewards.assign((sets[key] as Array).filter(func(x): return not (x as Dictionary).is_empty()))
		var scene: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
		add_child(scene)
		await _frames(8)
		scene.call("_show_reward_overlay", "CHOOSE ONE REWARD")
		await _frames(10)
		if key.begins_with("31-reward--chaos"):
			scene.call("_select_reward", 1)
		if key == "31-reward--chaos-confirm":
			scene.call("_take_selected_reward")
		await _frames(8)
		await _save(key)
		scene.queue_free()
		await _frames(3)
	# Extra (no HTML frame): a real Core offer with the gacha tiers, to check the fixed card holds the Core extras.
	UI3Gacha.instant_override = 1
	RunState._core_offer_active = true
	RunState.pending_rewards = CoreOffer.build_offer(Rng.new(14), 2, RunState._core_ctx(), 3)
	var cs: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(cs)
	await _frames(8)
	cs.call("_show_reward_overlay", "x")
	await _frames(12)
	await _save("extra-core-offer")
	cs.queue_free()
	RunState._core_offer_active = false
	UI3Gacha.instant_override = -1
	await _frames(3)


func _boss(key: String) -> void:
	var intro := BossIntro.new()
	if not intro.setup(key):
		return
	add_child(intro)
	while intro.elapsed_ms < 2200:
		await get_tree().process_frame
	await _save("boss-intro--default")
	intro.queue_free()
	await _frames(3)
