extends Node
## v5 real flow: a Run Rule and a Core taken through the real reward overlay show up in the real Combat scene.
## Rule Pack Alpha: exactly one enemy wears the LEADER badge. Core Golden Thread: Wild Face costs 1 less than without it.

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
var _fail := 0
var _checks := 0
var _guard := SaveGuard.new()
var rm: Node = null


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail += 1
		print("FAIL: ", msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _map() -> void:
	if rm != null:
		rm.free()
	UI3Gacha.reset_seen()
	rm = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)


func _offer_with(keys: Array) -> void:
	await _map()
	var cards: Array[Dictionary] = []
	for i in keys.size():
		cards.append(CoreOffer.card_of(RelicRegistry.get_def(String(keys[i])), i))
	RunState.pending_rewards = cards
	RunState._core_offer_active = true
	RunState.set_phase(RunState.RunPhase.REWARD)
	rm._show_reward_overlay("x")
	await _frames(3)


func _fight(kind := "battle") -> Node:
	if rm != null:
		rm.free()
		rm = null
	RunState.set_phase(RunState.RunPhase.MAP)
	RunState.enter_node("r1_c0", kind)
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(v)
	await _frames(40)
	return v


func _new_run(seed: int, rules_on: bool) -> void:
	RunState.start_new_run_seeded(seed, {"team_keys": TEAM, "mode": "short", "ascension": 0, "ranked": false, "rules_on": rules_on})
	await _frames(2)


func _test_alpha() -> void:
	print("step: alpha")
	var idx := -1
	for sd in range(1, 400):
		await _new_run(sd, true)
		for i in RunState.pending_rewards.size():
			if String((RunState.pending_rewards[i] as Dictionary).get("key", "")) == "rule_pack_alpha":
				idx = i
		if idx >= 0:
			break
	_ok(idx >= 0, "found a seed whose Run Rule offer holds Pack Alpha")
	if idx < 0:
		return
	_ok(RunState._rule_offer_active, "rule offer active")
	await _map()
	rm._select_reward(idx)
	await _frames(2)
	rm._take_selected_reward()
	await _frames(8)
	_ok(RunState.run_rule == "rule_pack_alpha", "run rule is Pack Alpha (%s)" % RunState.run_rule)
	# the Core offer that follows the rule: take the first card through the overlay too
	if not RunState.pending_rewards.is_empty():
		rm._select_reward(0)
		rm._take_selected_reward()
		await _frames(8)
	var v: Node = await _fight("battle")
	var e: CombatEngine = v._combat
	_ok(e.enemies.size() >= 2, "ordinary fight has 2+ enemies (%d)" % e.enemies.size())
	_ok(e.relic_ids.has("rule_pack_alpha") if "relic_ids" in e else true, "Alpha rule is in the fight")
	var leaders := 0
	for en in e.enemies:
		v._update_portrait(en)
		var p := v._portraits.get((en as Unit).uid) as UnitPortrait
		if p != null and p.is_leader():
			leaders += 1
			_ok(bool((en as Unit).custom_state.get("alpha", false)), "badge sits on the marked Alpha")
	_ok(leaders == 1, "exactly one LEADER badge (%d)" % leaders)
	v.free()
	await _frames(2)


func _wild_in_fight(v: Node) -> int:
	return (v._combat as CombatEngine).wild_cost()


func _test_thread() -> void:
	print("step: golden thread")
	await _new_run(424242, false)
	RunState.depth_stage = 2
	await _fight_plain_cost_probe()


func _fight_plain_cost_probe() -> void:
	var v0: Node = await _fight("battle")
	var base := _wild_in_fight(v0)
	v0.free()
	await _frames(2)
	await _new_run(424242, false)
	RunState.depth_stage = 2
	await _offer_with(["c_golden_thread", "c_kindle", "c_dewdrop"])
	rm._select_reward(0)
	rm._take_selected_reward()
	await _frames(15)
	_ok(RunState.owned_relic_ids.has("c_golden_thread"), "Golden Thread owned via the overlay")
	var v1: Node = await _fight("battle")
	var withc := _wild_in_fight(v1)
	_ok(base >= 1, "base Wild cost is positive (%d)" % base)
	_ok(withc == maxi(1, base - 1), "Wild cost with Golden Thread %d = base %d - 1 (floor 1)" % [withc, base])
	v1.free()
	await _frames(2)


func _ready() -> void:
	print("=== t_v5_flow_core_rule: start ===")
	_guard.capture()
	CombatView.disable_juice_for_tests = true
	ProjectSettings.set_setting("axie/epoch_source", "local")
	UI3Gacha.instant_override = 1
	AnchorAdapter.test_state = null
	await _test_alpha()
	await _test_thread()
	UI3Gacha.instant_override = -1
	CombatView.disable_juice_for_tests = false
	_guard.restore()
	print("=== t_v5_flow_core_rule: %d checks, %d failure(s) ===" % [_checks, _fail])
	if _fail == 0:
		print("t_v5_flow_core_rule: PASS")
	get_tree().quit(0 if _fail == 0 else 1)
