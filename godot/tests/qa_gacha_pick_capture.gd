extends Node
## Manual visual QA for the gacha Core pick (run non-headless: tools/shot.sh res://tests/qa_gacha_pick_capture.tscn 1280x720).
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
	get_viewport().get_texture().get_image().save_png("%s/gacha_pick_%s_%s.png" % [dir, name, tag])


func _open(tier: int) -> void:
	if rm != null:
		rm.queue_free()
	UI3Gacha.reset_seen()
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await get_tree().process_frame
	await get_tree().process_frame
	RunState.pending_rewards = CoreOffer.build_offer(Rng.new(11 + tier), tier, RunState._core_ctx(), 3)
	RunState._core_offer_active = true
	RunState.set_phase(RunState.RunPhase.REWARD)
	rm._show_reward_overlay("x")


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Gacha.instant_override = 0
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	await _open(2)
	await _wait(1.0)
	_snap("facedown")
	await _wait(1.6)
	_snap("flip_crystal")
	UI3Gacha.combo_provider = FakeCombos.new()
	await _open(2)
	await _wait(2.45)
	_snap("jackpot")
	UI3Gacha.combo_provider = null
	_guard.restore()
	get_tree().quit(0)
