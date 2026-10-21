class_name TComboFired
extends Node
## Lane GM B5: combo_fired -> name float once per fight, both Core slots pulse and a bar joins them (first time only).
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

const COMBO := {"id": "t_pair", "name_en": "Stone Wall", "name_vi": "Tuong Da", "pair": ["c_bastion", "c_fissure"], "full": null, "jackpot": false}

## Until lane GD merges the signal, add it so the adapter has something to connect to.
static func ensure_signal() -> void:
	if not EventBus.has_signal("combo_fired"):
		EventBus.add_user_signal("combo_fired", [{"name": "combo_id", "type": TYPE_STRING}])
	ComboAdapter.test_combos = [COMBO]

func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	ensure_signal()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	for id in ["c_bastion", "c_fissure"]:
		RunState.owned_relic_ids.append(id)
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 60:
		await get_tree().process_frame
	var cp: CorePanel = v._hud_frame.core_panel
	EventBus.emit_signal("combo_fired", "t_pair")
	await get_tree().process_frame
	_check(v.combo_float_log == ["Stone Wall"], "name shown once: %s" % str(v.combo_float_log))
	_check(int((cp._slot_by_id["c_bastion"] as Node).get_meta("pulsed", 0)) == 1, "slot A pulsed")
	_check(int((cp._slot_by_id["c_fissure"] as Node).get_meta("pulsed", 0)) == 1, "slot B pulsed")
	_check(cp.combo_links == 1 and cp.combo_link_ids == ["c_bastion", "c_fissure"], "bar joins the pair")
	EventBus.emit_signal("combo_fired", "t_pair")
	await get_tree().process_frame
	_check(v.combo_float_log.size() == 1, "second fire: no name again")
	_check(cp.combo_links == 1, "second fire: no bar again")
	_check(int((cp._slot_by_id["c_bastion"] as Node).get_meta("pulsed", 0)) == 2, "second fire: icon still lights")
	# Name Tag: custom_state.nick replaces the nameplate text, the original name stays in the tooltip.
	var foe = v._combat.enemies[0]
	foe.custom_state["nick"] = "Steve"
	v._rebuild_all()
	var pt: UnitPortrait = v._portraits[foe.uid]
	_check(pt._name_label.text == "Steve", "nick on nameplate: %s" % pt._name_label.text)
	_check(pt._click_catcher.tooltip_text.contains(foe.n), "original name in tooltip")
	foe.custom_state.erase("nick")
	v._rebuild_all()
	_check(pt._name_label.text == foe.n, "nick removed restores the name")
	v.queue_free()
	ComboAdapter.test_combos = null
	_guard.restore()
	for m in _fails:
		print("t_combo_fired: FAIL — %s" % m)
	if _fails.is_empty():
		print("t_combo_fired: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
