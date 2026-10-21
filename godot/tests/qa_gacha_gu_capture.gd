extends Node
## Manual visual QA for the GU fixes (non-headless): tools/shot.sh res://tests/qa_gacha_gu_capture.tscn 1920x1080
## GU_ONLY=jackpot,banner,... limits the sections. Images: production/qa/evidence/gu_<name>_<WxH>.png
var _guard := SaveGuard.new()
var rm: Node


class FakeCombos extends RefCounted:
	func card_completes(_owned: Array, core_id: String) -> Dictionary:
		return {"id": "fake_combo", "tier": "pair"} if core_id != "" else {}
	func matches(_owned: Array, _core_id: String) -> Array:
		return []
	func all() -> Array:
		return [{"id": "fake_combo", "name_en": "Fortress"}]


func _snap(name: String) -> void:
	var tag := "%dx%d" % [int(DisplayServer.window_get_size().x), int(DisplayServer.window_get_size().y)]
	var dir := QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/gu_%s_%s.png" % [dir, name, tag])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


## Bounded poll: waits until `cond` is true, at most `max_s` seconds.
func _until(cond: Callable, max_s: float) -> bool:
	var t := 0.0
	while t < max_s:
		if cond.call():
			return true
		await get_tree().process_frame
		t += get_process_delta_time()
	return cond.call()


func _want(name: String) -> bool:
	var only := OS.get_environment("GU_ONLY")
	return only == "" or only.split(",").has(name)


func _fresh() -> void:
	if rm != null:
		rm.queue_free()
	UI3Gacha.reset_seen()
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await get_tree().process_frame
	await get_tree().process_frame


func _open_tier(tier: int, seed := 11) -> void:
	await _fresh()
	RunState.pending_rewards = CoreOffer.build_offer(Rng.new(seed + tier), tier, RunState._core_ctx(), 3)
	RunState._core_offer_active = true
	RunState.core_rerolled_slots = []
	RunState.core_reroll_left = 2
	RunState.set_phase(RunState.RunPhase.REWARD)
	rm._show_reward_overlay("x")


func _open_keys(keys: Array) -> void:
	await _fresh()
	var cards: Array[Dictionary] = []
	for i in keys.size():
		cards.append(CoreOffer.card_of(RelicRegistry.get_def(String(keys[i])), i))
	RunState.pending_rewards = cards
	RunState._core_offer_active = true
	RunState.core_rerolled_slots = []
	RunState.core_reroll_left = 2
	RunState.set_phase(RunState.RunPhase.REWARD)
	rm._show_reward_overlay("x")


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Gacha.instant_override = 0
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	await get_tree().process_frame
	if _want("jackpot"):
		await _jackpot()
	if _want("banner"):
		await _banner()
	if _want("spin"):
		await _spin()
	if _want("combat"):
		await _combat()
	if _want("result"):
		await _result()
	if _want("nearmiss"):
		await _nearmiss()
	if _want("title"):
		await _title_codex()
	_guard.restore()
	get_tree().quit(0)


func _jackpot() -> void:
	UI3Gacha.combo_provider = FakeCombos.new()
	await _open_tier(2)
	await _until(func(): return rm._reveal != null and rm._reveal.events.has("aura"), 3.0)
	await _wait(1.0)
	_snap("jackpot_before")
	await _until(func(): return rm._reveal.events.has("jackpot"), 6.0)
	await _wait(0.12)
	_snap("jackpot_shake")
	await _wait(0.5)
	_snap("jackpot_sparkle")
	UI3Gacha.combo_provider = null


func _banner() -> void:
	RunState.owned_relic_ids.append("c_nest")
	await _open_keys(["c_golden_egg", "c_kindle", "c_dewdrop"])
	await _wait(2.2)
	_snap("card_pair")
	rm._select_reward(0)
	rm._take_selected_reward()
	await _wait(0.6)
	_snap("banner_pair")
	await _wait(1.6)
	RunState.owned_relic_ids.append("c_golden_egg")
	await _open_keys(["c_spore_burst", "c_kindle", "c_dewdrop"])
	await _wait(2.2)
	rm._select_reward(0)
	rm._take_selected_reward()
	await _wait(0.6)
	_snap("banner_full")
	await _wait(2.4)


func _nearmiss() -> void:
	RunState.owned_relic_ids.assign(["c_cascade", "c_blood_sign", "c_deep_current"])
	RunState.core_tier_chain = [2, 2, 2, 2, 2, 2]
	RunState._core_offer_pick = 1
	RunState.core_pick_index = 2
	await _open_tier(1)
	await _until(func(): return rm._reveal != null and rm._reveal.events.has("aura"), 4.0)
	for _i in 25:   # frames, not seconds: the first frames after a scene load can stall for a second
		await get_tree().process_frame
	print("nearmiss before: crack=", rm._reveal.events.has("crack"))
	_snap("nearmiss_before")
	await _until(func(): return rm._reveal.events.has("crack"), 4.0)
	await _wait(0.35)
	_snap("nearmiss_after_crack")
	await _wait(2.0)
	_snap("nearmiss_flipped")


func _spin() -> void:
	await _open_keys(["c_dim_stone", "c_kindle", "c_dewdrop"])
	await _wait(2.2)
	rm._select_reward(0)
	rm._take_selected_reward()
	await _wait(0.9)
	_snap("spin_mid")
	await _wait(1.2)
	_snap("spin_late")
	await _wait(2.0)


func _combat() -> void:
	RunState.enter_node("r5_c0", "battle")
	var scene: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	for _i in 90:
		await get_tree().process_frame
	scene._combo_named.clear()
	scene._spawn_combo_name("Golden Turtle Fortress")
	scene._spawn_combo_name("Lunacia Rain")
	scene._on_core_fired("c_kindle", scene._party_dice_units()[0].uid, 4, "dmg")
	await _wait(0.5)
	_snap("combat_combo")
	scene.queue_free()
	await get_tree().process_frame


func _result() -> void:
	ComboAdapter.test_combos = [
		{"id": "t_pair", "name_en": "Golden Turtle Fortress", "pair": ["c_bastion", "c_fissure"], "full": null, "jackpot": false},
		{"id": "t_full", "name_en": "Iron Tide", "pair": ["c_bastion", "c_plague_spread"], "full": "c_fissure", "jackpot": false}]
	ComboAdapter.test_done = {"t_pair": "pair", "t_full": "full"}
	ComboAdapter.test_skipped = ["c_bastion", "c_fissure", "c_plague_spread"]
	RunState.start_new_run(777001, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	RunState.owned_relic_ids.append("c_bastion")
	RunState.set_phase(RunState.RunPhase.WON)
	var v: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 30:
		await get_tree().process_frame
	await _wait(1.0)
	_snap("result")
	v.queue_free()
	ComboAdapter.test_combos = []
	ComboAdapter.test_done = {}
	ComboAdapter.test_skipped = []


## GU 8: pinned Core title with 1 / 2 rerolls left, and the Codex combo + Core tabs.
func _title_codex() -> void:
	for n in [2, 1]:
		await _open_tier(0)
		RunState.core_reroll_left = n
		rm._show_reward_overlay("x")
		await _wait(2.2)
		_snap("title_%d" % n)
	if rm != null:
		rm.queue_free()
	var codex: Node = load("res://scenes/codex/Codex.tscn").instantiate()
	add_child(codex)
	await get_tree().process_frame
	for tab in ["combos", "cores"]:
		codex.call("_select_tab", tab)
		await _wait(0.4)
		_snap("codex_" + tab)
	codex.queue_free()
