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
	test_capacity()
	test_passive_full_needs_sell()
	test_eternal_never_sellable()
	test_multiplier_slots()
	test_active_slots()
	test_forced_pact_cannot_cancel()
	test_sell_price_and_is_pact()
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
		_assert(String(def.needs_hook) == "" or String(def.needs_hook).split(",").size() > 0, "%s: needs_hook format" % def.id)


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


const PASSIVES := ["r_claw", "r_carapace", "r_pierceall", "r_cleaveall", "r_bloodmouth", "r_gorehook",
	"r_barbedhide", "r_heart"]


func test_capacity() -> void:
	var c := RelicSlots.capacity(0, [])
	_assert(c == {"passive": 8, "active": 3, "g": 1, "a": 2}, "capacity A0 = 8/3/1/2, got %s" % str(c))
	_assert(int(RelicSlots.capacity(7, [])["passive"]) == 8, "A7 still 8 passive")
	_assert(int(RelicSlots.capacity(8, [])["passive"]) == 7, "A8 cramped = 7 passive")
	_assert(int(RelicSlots.capacity(8, [])["active"]) == 3, "A8 keeps 3 active")
	_assert(int(RelicSlots.capacity(0, ["r_hollowchalice"])["active"]) == 4, "hollowchalice gives 4 active")


func test_passive_full_needs_sell() -> void:
	var seven: Array = PASSIVES.slice(0, 7)
	var r := RelicSlots.check_add(seven, {}, "r_seedling", 0, false)
	_assert(r["ok"] and not r["needs_sell"], "7/8 passive: free slot, no sale")
	var r8 := RelicSlots.check_add(PASSIVES, {}, "r_seedling", 0, false)
	_assert(r8["ok"] and r8["needs_sell"] and (r8["sell_from"] as Array).size() == 8, "8/8: sell any of the 8")
	_assert(r8["can_cancel"], "ordinary relic can be cancelled")
	# A8: 7 slots, so the 8th is already over
	var r_a8 := RelicSlots.check_add(PASSIVES.slice(0, 7), {}, "r_seedling", 8, false)
	_assert(r_a8["needs_sell"], "A8: 7/7 passive needs a sale")
	_assert(not RelicSlots.check_add(PASSIVES, {}, "r_claw", 0, false)["ok"], "owning it already -> not ok")
	_assert(String(RelicSlots.check_add([], {}, "nope", 0, false)["reason"]) == "unknown_relic", "unknown id")


func test_eternal_never_sellable() -> void:
	var st := {"r_claw": "eternal"}
	var r := RelicSlots.check_add(PASSIVES, st, "r_seedling", 0, false)
	_assert(r["needs_sell"] and not (r["sell_from"] as Array).has("r_claw") and (r["sell_from"] as Array).size() == 7,
		"eternal relic excluded from sell_from")
	var all_eternal := {}
	for id in PASSIVES:
		all_eternal[id] = "eternal"
	var r2 := RelicSlots.check_add(PASSIVES, all_eternal, "r_seedling", 0, false)
	_assert(not r2["ok"] and String(r2["reason"]) == "no_sellable", "every relic eternal: card greyed out")


func test_multiplier_slots() -> void:
	# G slot taken by ancientgene; passive slots are NOT full, but bloodpact still needs a G sale.
	var owned := ["r_ancientgene", "r_claw"]
	var r := RelicSlots.check_add(owned, {}, "r_bloodpact", 0, false)
	_assert(r["ok"] and r["needs_sell"] and r["sell_from"] == ["r_ancientgene"],
		"G slot full: must sell the G relic only, got %s" % str(r))
	_assert(RelicSlots.check_add(["r_claw"], {}, "r_bloodpact", 0, false)["needs_sell"] == false, "free G slot: no sale")
	# Two A slots: venomengine + hearthcore. solarcore needs a sale of one of them.
	var a_owned := ["r_venomengine", "r_hearthcore", "r_claw"]
	var ra := RelicSlots.check_add(a_owned, {}, "r_solarcore", 0, false)
	_assert(ra["needs_sell"] and (ra["sell_from"] as Array).size() == 2 and not (ra["sell_from"] as Array).has("r_claw"),
		"A slots full: sell one of the two A relics, got %s" % str(ra))
	_assert(RelicSlots.check_add(["r_venomengine", "r_claw"], {}, "r_solarcore", 0, false)["needs_sell"] == false, "one A free")
	# G and A are separate slot kinds
	_assert(not RelicSlots.check_add(a_owned + ["r_ancientgene"], {}, "r_bloodpact", 0, false)["sell_from"].has("r_venomengine"),
		"G sale never offers an A relic")
	# the only same-axis relic is eternal -> greyed out
	var re := RelicSlots.check_add(owned, {"r_ancientgene": "eternal"}, "r_bloodpact", 0, false)
	_assert(not re["ok"] and String(re["reason"]) == "no_sellable", "G relic eternal: bloodpact greyed out")


func test_active_slots() -> void:
	var acts := ["a_restore", "a_freeze", "a_wall"]
	var r := RelicSlots.check_add(acts + PASSIVES, {}, "a_chaos", 0, false)
	_assert(r["needs_sell"] and (r["sell_from"] as Array).size() == 3, "3/3 active: sell one of the actives, not passives")
	_assert(RelicSlots.check_add(acts + ["r_hollowchalice"], {}, "a_chaos", 0, false)["needs_sell"] == false,
		"hollowchalice opens a 4th active slot")
	_assert(RelicSlots.check_add(acts, {}, "r_claw", 0, false)["needs_sell"] == false, "active slots do not eat passive slots")


func test_forced_pact_cannot_cancel() -> void:
	var r := RelicSlots.check_add(PASSIVES, {}, "r_brittledice", 10, true)
	_assert(r["needs_sell"] and not r["can_cancel"], "forced pact on full slots: mandatory sale, no cancel")
	_assert(RelicSlots.check_add(PASSIVES.slice(0, 3), {}, "r_brittledice", 10, true)["needs_sell"] == false, "forced pact with room: just add")


func test_sell_price_and_is_pact() -> void:
	# 50% of 45/75/120/180, 40% from A1, floored
	_assert(RelicSlots.sell_price("r_claw", 0) == 22, "common sells 22 at A0")
	_assert(RelicSlots.sell_price("r_scentofblood", 0) == 37, "rare sells 37 at A0")
	_assert(RelicSlots.sell_price("r_growthcore", 0) == 60, "epic sells 60 at A0")
	_assert(RelicSlots.sell_price("r_plaguelord", 0) == 90, "legendary sells 90 at A0")
	_assert(RelicSlots.sell_price("r_claw", 1) == 18 and RelicSlots.sell_price("r_plaguelord", 5) == 72, "40% from A1")
	_assert(RelicSlots.sell_price("nope", 0) == 0, "unknown relic sells for 0")
	_assert(RelicSlots.is_pact("r_bloodpact") and RelicSlots.is_pact("r_twinfates") and not RelicSlots.is_pact("r_claw"), "is_pact")
	var pacts := 0
	for d in RelicRegistry.all_defs_sorted():
		if RelicSlots.is_pact(d.id):
			pacts += 1
	_assert(pacts == 9, "9 pacts in the pool, got %d" % pacts)
