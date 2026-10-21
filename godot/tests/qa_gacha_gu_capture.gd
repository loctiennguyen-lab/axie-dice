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
