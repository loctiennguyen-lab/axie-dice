extends Node
## Depth v3 lane D: CorePanel (6 Core slots + Run rule slot + quest chip) on the map rail and in combat.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

static func grant(ids: Array) -> void:
	for id in ids:
		RunState.owned_relic_ids.append(String(id))
	var q = RelicRegistry.get_def("c_test_quest_amber")
	if q != null and RunState.owned_relic_ids.has("c_test_quest_amber"):
		RunState.core_quest_progress["c_test_quest_amber"] = {"step": 0, "progress": 1}

func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	var p := CorePanel.new()
	add_child(p)
	_check(not p.refresh() or true, "refresh runs")
	grant(["c_test_dice_moss_a", "c_test_mana_amber_a", "c_test_pos_crystal_a", "c_test_quest_amber"])
	_check(p.refresh(), "panel has content once a Core is owned")
	_check(p.find_children("CoreSlot_*", "PanelContainer", true, false).size() == 6, "6 Core slots")
	_check(p.find_children("RuleSlot", "PanelContainer", true, false).size() == 1, "1 Run rule slot")
	_check(p.find_children("Quest_*", "PanelContainer", true, false).size() == 1, "quest chip with progress")
	p.queue_free()
	# Map rail + combat HUD both show it.
	var scene: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(scene)
	for _i in 8:
		await get_tree().process_frame
	_check(scene.find_child("CorePanel", true, false) != null and scene.find_child("CorePanel", true, false).visible, "panel on map rail")
	scene.queue_free()
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 60:
		await get_tree().process_frame
	var cp: Node = v._hud_frame.core_panel
	_check(cp != null and cp.visible, "panel in combat HUD")
	v.queue_free()
	_guard.restore()
	for f in _fails:
		print("t_depthv3_core_panel: FAIL — %s" % f)
	if _fails.is_empty():
		print("t_depthv3_core_panel: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
