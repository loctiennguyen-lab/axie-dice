extends Node
## Real flow: RunSetup Begin (no start_hook) -> Run Rule offer -> Anchor pick screen -> Anchor chosen -> first Core offer -> HUD Anchor tile + x/2 chip.
## Stage 2 account: no Anchor screen, the first Core offer opens directly.

var _fail := 0
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail += 1
		print("FAIL: ", msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _begin(completed: int) -> RunSetup:
	MetaState.runs = completed
	MetaState.runs_with_battle = completed
	MetaState.runs_completed = completed
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.state = "normal"
	s.use_account = false
	s.remote_on = false
	s.no_scene_change = true
	add_child(s)
	await _frames(2)
	s._begin_btn.pressed.emit()
	await _frames(6)
	return s


func _cards(rm: Node) -> int:
	var n := 0
	if rm._overlay_root == null or not rm._overlay_root.visible:
		return 0
	for i in 8:
		if rm._overlay_root.find_child("RewardCard%d" % i, true, false) != null:
			n += 1
	return n


func _ready() -> void:
	print("=== t_anchor_flow_start: start ===")
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	ProjectSettings.set_setting("axie/gem_wallet", "local")
	UI3Gacha.instant_override = 1
	AnchorAdapter.test_state = null
	# ---- stage 3
	var s := await _begin(5)
	_ok(MetaState.depth_stage() == 3 and RunState.depth_stage == 3, "stage 3 account")
	_ok(RunState.anchor_wanted, "Begin passed anchor=true to the engine")
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(8)
	if RunState.rules_on and RunState._rule_offer_active:
		_ok(_cards(rm) >= 2, "Run Rule overlay first")
		rm._select_reward(0)
		await _frames(2)
		rm._take_selected_reward()
		await _frames(8)
	_ok(RunState.phase == RunState.RunPhase.REWARD and RunState.pending_rewards.is_empty() and RunState._anchor_waiting, "engine waits for the Anchor")
	var pick := rm.find_child("AnchorPick", true, false) as AnchorPick
	_ok(pick != null and pick.cards.size() == 3, "Anchor pick screen shows 3 cards")
	if pick != null:
		pick.select(0)
		var id := String(pick.cards[0].get_meta("anchor_id"))
		pick.take_button.pressed.emit()
		await _frames(10)
		_ok(RunState.anchor_id == id, "engine holds the chosen Anchor")
		_ok(not RunState.pending_rewards.is_empty() and _cards(rm) >= 3, "first Core offer shown after the pick")
		rm._select_reward(0)
		await _frames(2)
		rm._take_selected_reward()
		await _frames(10)
		var cp: CorePanel = null
		for n in rm.find_children("*", "", true, false):
			if n is CorePanel:
				cp = n
		_ok(cp != null and cp.anchor_slot != null, "HUD has the Anchor tile")
		_ok(rm.find_child("HouseChip", true, false) != null or cp.find_child("HouseChip", true, false) != null, "HUD has the x/2 chip")
	rm.queue_free()
	s.queue_free()
	await _frames(2)
	# ---- stage 2
	var s2 := await _begin(1)
	_ok(MetaState.depth_stage() == 2, "stage 2 account")
	var rm2: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm2)
	await _frames(8)
	if RunState.rules_on and RunState._rule_offer_active:
		rm2._select_reward(0)
		await _frames(2)
		rm2._take_selected_reward()
		await _frames(8)
	_ok(rm2.find_child("AnchorPick", true, false) == null and RunState.anchor_id == "" and not RunState._anchor_waiting, "stage 2: no Anchor screen")
	_ok(not RunState.pending_rewards.is_empty(), "stage 2: Core offer opens directly")
	rm2.queue_free()
	s2.queue_free()
	UI3Gacha.instant_override = -1
	print("=== t_anchor_flow_start: %d checks, %d failure(s) ===" % [_checks, _fail])
	_guard.restore()
	if _fail == 0:
		print("t_anchor_flow_start: PASS")
		get_tree().quit(0)
	else:
		get_tree().quit(1)
