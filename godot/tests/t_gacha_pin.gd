extends Node
## GU 3: "CHOOSE A CORE" and the Take button keep their position in every reward state (plain, PAIR card, FULL card,
## near-miss, jackpot, mid-spin); the card band is a fixed height (no layout push).
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []
var rm: Node
var _samples: Array = []   # [label, title_pos, take_pos]


class FakeCombos extends RefCounted:
	func card_completes(_owned: Array, core_id: String) -> Dictionary:
		return {"id": "fake_combo", "tier": "pair"} if core_id != "" else {}
	func matches(_owned: Array, _core_id: String) -> Array:
		return []
	func all() -> Array:
		return [{"id": "fake_combo", "name_en": "Fortress"}]


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _fresh() -> void:
	if rm != null:
		rm.queue_free()
	UI3Gacha.reset_seen()
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(4)


func _open(offer: Array) -> void:
	var cards: Array[Dictionary] = []
	cards.assign(offer)
	await _fresh()
	RunState.pending_rewards = cards
	RunState._core_offer_active = true
	RunState.core_rerolled_slots = []
	RunState.core_reroll_left = 2
	RunState.set_phase(RunState.RunPhase.REWARD)
	rm._show_reward_overlay("x")
	await _frames(4)


func _keys(keys: Array) -> Array:
	var out: Array = []
	for i in keys.size():
		out.append(CoreOffer.card_of(RelicRegistry.get_def(String(keys[i])), i))
	return out


func _sample(label: String) -> void:
	await _frames(3)
	var t: Control = rm._overlay_root.find_child("Title", true, false)
	var b: Control = rm._overlay_root.find_child("TakeButton", true, false)
	_check(t != null and b != null, "%s: title + Take exist" % label)
	if t == null or b == null:
		return
	_samples.append([label, t.get_global_rect().position, b.get_global_rect().position])
	for c in rm._reward_cards:
		_check((c as Control).size.y <= UI3Theme.size_of("reward_card_h") + 1.0, "%s: card fits the fixed band (%s)" % [label, (c as Control).size.y])


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Gacha.instant_override = 0
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	await _frames(2)
	await _open(CoreOffer.build_offer(Rng.new(11), 0, RunState._core_ctx(), 3))
	await _sample("plain moss")
	await _open(_keys(["c_dim_stone", "c_kindle", "c_dewdrop"]))
	await _sample("short cards")
	RunState.owned_relic_ids.append("c_nest")
	await _open(_keys(["c_golden_egg", "c_kindle", "c_dewdrop"]))
	await _sample("pair card")
	await get_tree().create_timer(0.3).timeout
	await _sample("pair card mid-reveal")
	UI3Gacha.combo_provider = FakeCombos.new()
	await _open(CoreOffer.build_offer(Rng.new(13), 2, RunState._core_ctx(), 3))
	await _sample("jackpot offer")
	UI3Gacha.combo_provider = null
	RunState.core_tier_chain = [2, 2, 2, 2, 2, 2]
	RunState._core_offer_pick = 1
	RunState.core_pick_index = 2
	await _open(CoreOffer.build_offer(Rng.new(12), 1, RunState._core_ctx(), 3))
	await _sample("near-miss")
	RunState.owned_relic_ids.erase("c_nest")
	if not _samples.is_empty():
		var base: Array = _samples[0]
		for s in _samples:
			_check((s[1] as Vector2).distance_to(base[1]) <= 2.0, "%s: title moved %s vs %s" % [s[0], s[1], base[1]])
			_check((s[2] as Vector2).distance_to(base[2]) <= 2.0, "%s: Take moved %s vs %s" % [s[0], s[2], base[2]])
	UI3Gacha.instant_override = -1
	for f in _fails:
		print("t_gacha_pin: FAIL — %s" % f)
	if _fails.is_empty():
		print("t_gacha_pin: PASS — %d checks OK (%d states)" % [_checks, _samples.size()])
	_guard.restore()
	get_tree().quit(0 if _fails.is_empty() else 1)
