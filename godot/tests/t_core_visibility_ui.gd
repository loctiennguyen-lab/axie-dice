extends Node
## Depth v3 lane VZ: Cores must be VISIBLE. Fake EventBus.core_fired for 3 Cores -> slot pulses + counts, float note text
## is right and merged per unit, the run stat adds up, and the Result "Cores" card shows the totals + top Core.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

static func setup_cores() -> void:
	for id in ["c_bastion", "c_fissure", "c_plague_spread"]:
		RunState.owned_relic_ids.append(id)

## Fires the fake signals shared by the test and the QA capture. Returns the uid used.
static func fire_fakes(uid: int, uid2: int) -> void:
	EventBus.core_fired.emit("c_bastion", uid, 3, "block")
	EventBus.core_fired.emit("c_bastion", uid, 4, "block")      # same beat, same Core: merges into +7
	EventBus.core_fired.emit("c_fissure", uid2, 5, "dmg")
	EventBus.core_fired.emit("c_plague_spread", uid2, 2, "poison")

func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	setup_cores()
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 60:
		await get_tree().process_frame
	var cp: CorePanel = v._hud_frame.core_panel
	_check(cp.visible and cp.show_counts, "combat HUD panel shows counts")
	var ally: int = v._combat.party[0].uid
	var foe: int = v._combat.enemies[0].uid
	fire_fakes(ally, foe)
	await get_tree().process_frame
	var slot: PanelContainer = cp._slot_by_id.get("c_bastion")
	_check(slot != null and int(slot.get_meta("pulsed", 0)) == 2, "Bastion slot pulsed twice")
	_check(slot.get_node("FireCount").text == "x2" and slot.get_node("FireCount").visible, "Bastion count chip x2")
	_check(int((cp._slot_by_id["c_fissure"] as Node).get_meta("pulsed", 0)) == 1, "Fissure slot pulsed")
	cp.refresh()   # a HUD repaint must not wipe the counters
	_check((cp._slot_by_id["c_bastion"] as Node).get_node("FireCount").text == "x2", "count survives refresh")
	var log: Array = v.core_float_log
	_check(log.size() == 2, "2 notes (one per unit), got %d" % log.size())
	var all := []
	for e in log:
		all.append_array(e["lines"])
	_check(all.has("Bastion +7 Block"), "merged Bastion line: %s" % str(all))
	_check(all.has("Fissure −5"), "Fissure damage line: %s" % str(all))
	_check(all.has("Contagion −2 Poison"), "Contagion poison line: %s" % str(all))
	_check(RunState.core_impact["c_bastion"]["n"] == 2 and RunState.core_impact["c_bastion"]["by"]["block"] == 7, "run stat Bastion")
	_check(RunState.core_impact["c_fissure"]["by"]["dmg"] == 5, "run stat Fissure")
	var rt := RunState.to_data()
	RunState.core_impact = {}
	RunState.from_data(rt)
	_check(RunState.core_impact.get("c_bastion", {}).get("n", 0) == 2, "core_impact survives to_data/from_data")
	v.queue_free()
	await get_tree().process_frame
	var impact := RunState.core_impact.duplicate(true)
	RunState.start_new_run(777003, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	setup_cores()
	RunState.core_impact = impact
	RunState.set_phase(RunState.RunPhase.WON)
	var r: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	add_child(r)
	for _i in 10:
		await get_tree().process_frame
	var b: Node = r.find_child("CoreRow_c_bastion", true, false)
	_check(b != null and b.find_child("CoreImpact", true, false).text.contains("blocked 7"), "Result Bastion row: blocked 7")
	_check(b != null and b.find_child("CoreImpact", true, false).text.begins_with("Most impact"), "Bastion is the top Core")
	var f: Node = r.find_child("CoreRow_c_fissure", true, false)
	_check(f != null and f.find_child("CoreImpact", true, false).text == "5 dmg", "Result Fissure row: 5 dmg")
	r.queue_free()
	_guard.restore()
	for m in _fails:
		print("t_core_visibility_ui: FAIL — %s" % m)
	if _fails.is_empty():
		print("t_core_visibility_ui: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
