extends Node
## Manual visual QA for gacha moments (non-headless): tools/shot.sh res://tests/qa_gacha_moments_capture.tscn 1280x720
var _guard := SaveGuard.new()
var rm: Node


func _snap(name: String) -> void:
	var tag := "%dx%d" % [int(DisplayServer.window_get_size().x), int(DisplayServer.window_get_size().y)]
	var dir := QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/gacha_pick_%s_%s.png" % [dir, name, tag])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _open(tier: int, seed := 13) -> void:
	if rm != null:
		rm.queue_free()
	UI3Gacha.reset_seen()
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await get_tree().process_frame
	await get_tree().process_frame
	RunState.pending_rewards = CoreOffer.build_offer(Rng.new(seed), tier, RunState._core_ctx(), 3)
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
	await _open(1)
	await _wait(1.8)
	rm._on_core_card_reroll(0)
	await _wait(0.75)
	_snap("reroll")
	await _wait(1.0)
	_guard.restore()
	get_tree().quit(0)
