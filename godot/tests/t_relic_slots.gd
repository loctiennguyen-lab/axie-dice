extends Node
## Lane B skeleton gate (relic-set-v2 §3.1, interfaces §2.4/§2.2): the slot model signatures exist,
## the out-of-combat hook runners are no-ops for the current pool, Unit.slot round-trips, and the
## new RelicDef fields default to "no change". Grows into the real slot-rule tests in the next commit.

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_relic_slots: start ===")
	test_tuning_loads()
	test_new_def_fields_default_to_inert()
	test_run_fire_and_run_value_are_noops_for_old_pool()
	test_unit_slot_roundtrips()
	print("=== t_relic_slots: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_relic_slots: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_relic_slots: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func test_tuning_loads() -> void:
	var t = load(RelicSlots.TUNING_PATH)
	_assert(t is RelicTuning, "relic_tuning.tres loads as RelicTuning")
	_assert(t.passive_slots == 8 and t.active_slots == 3 and t.g_slots == 1 and t.a_slots == 2,
		"tuning has 8 passive / 3 active / 1 G / 2 A")
	_assert(RelicRegistry.get_def("relic_tuning") == null, "tuning file is not registered as a relic")


func test_new_def_fields_default_to_inert() -> void:
	for def in RelicRegistry.all_defs_sorted():
		_assert(not def.hidden_from_pool or String(def.needs_hook) != "" or String(def.id).begins_with("__"),
			"%s: hidden_from_pool needs a reason (needs_hook)" % def.id)


func test_run_fire_and_run_value_are_noops_for_old_pool() -> void:
	var ctx := {"x": 1}
	RelicHooks.run_fire(["r_claw", "r_ember", "no_such_relic"], "shop_relic_count", ctx)
	_assert(ctx == {"x": 1}, "run_fire with no handler leaves ctx untouched")
	var v = RelicHooks.run_value(["r_claw", "no_such_relic"], "shop_relic_count", {}, 2)
	_assert(int(v) == 2, "run_value with no handler returns the base value")
	_assert(RelicHooks.run_value([], "reward_card_count", {}, 3) == 3, "run_value with no relics returns base")


func test_unit_slot_roundtrips() -> void:
	var u := Unit.new()
	_assert(u.slot == -1, "Unit.slot defaults to -1")
	u.slot = 3
	_assert(Unit.from_data(u.to_data()).slot == 3, "Unit.slot survives to_data/from_data")
	var d := u.to_data()
	d.erase("slot")
	_assert(Unit.from_data(d).slot == -1, "old save without slot loads as -1")
