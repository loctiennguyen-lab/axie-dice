extends Node
## Polish 3/11 #2 (RULES_VERSION -w): old relics / pacts never count Cores or the Run Rule against their
## 8 passive / 3 active slots (design 2.1: Cores have 6 + 1 Run Rule of their own).

const CORES := ["c_bastion", "c_backline_glow", "c_bloodline_ward", "c_descend", "c_gatekeeper", "c_growing_shell"]
const RULE := "rule_cheap_mana"
const SEVENTH_CORE := "c_living_wall"
const PASSIVES := ["r_claw", "r_carapace", "r_pierceall", "r_cleaveall", "r_bloodmouth", "r_gorehook",
	"r_barbedhide", "r_heart"]

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	RelicRegistry.legacy_unhide_for_tests()
	for id in CORES + [RULE, SEVENTH_CORE]:
		_assert(RelicSlots.is_core(RelicRegistry.get_def(id)), "%s is a Core/rule def" % id)
	var base: Array = CORES + [RULE]
	# 6 Cores + rule + 7 passives: the 8th passive fits, no sale
	var r := RelicSlots.check_add(base + PASSIVES.slice(0, 7), {}, PASSIVES[7], 0, false)
	_assert(r["ok"] and not r["needs_sell"], "6 Cores + rule + 7 passives: 8th passive is free")
	# 8 passives: the 9th needs a sale, sell_from has no Core
	var owned: Array = base + PASSIVES
	var r9 := RelicSlots.check_add(owned, {}, "r_seedling", 0, false)
	_assert(r9["ok"] and r9["needs_sell"], "8 passives + Cores: 9th needs a sale")
	var sf: Array = r9["sell_from"]
	_assert(sf.size() == 8, "sell_from is exactly the 8 passives, got %d" % sf.size())
	for id in sf:
		_assert(not RelicSlots.is_core(RelicRegistry.get_def(String(id))), "sell_from has no Core: %s" % id)
	# Cores only (no old relics): old relic never needs a sale
	var r0 := RelicSlots.check_add(base, {}, "r_seedling", 0, false)
	_assert(r0["ok"] and not r0["needs_sell"], "Cores alone never fill passive slots")
	# A8 cramped: 7 passives full even with Cores around
	var ra8 := RelicSlots.check_add(base + PASSIVES.slice(0, 6), {}, "r_seedling", 8, false)
	_assert(ra8["ok"] and not ra8["needs_sell"], "A8: 6 passives + Cores: 7th is free")
	# 7th Core still goes through the Core rule
	var rc := RelicSlots.check_add(base + PASSIVES, {}, SEVENTH_CORE, 0, false)
	_assert(rc["ok"] and rc["needs_sell"], "7th Core needs a sale")
	var cf: Array = rc["sell_from"]
	_assert(cf.size() == 6, "7th Core sell_from = the 6 Cores, got %d" % cf.size())
	for id in cf:
		_assert(CORES.has(String(id)), "7th Core sells only Cores: %s" % id)
	# second Run Rule is refused
	var rr := RelicSlots.check_add(base, {}, "rule_dry_steppe", 0, false)
	_assert(not rr["ok"] and String(rr["reason"]) == "rule_slot_full", "second Run Rule refused")
	print("t_relic_slots_cores: %d checks, %d failure(s)" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_relic_slots_cores: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_relic_slots_cores: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)
