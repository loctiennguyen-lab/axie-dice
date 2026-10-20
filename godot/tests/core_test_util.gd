class_name CoreTestUtil
extends RefCounted
## Test helper (depth v3 lane B): the c_test_* Cores and rule_test_* Run Rules ship disabled so no player ever sees
## them. Tests that need a pool call enable() once (per-process, Resources are not shared across test runs).

static func enable(rules: bool = true) -> void:
	for def in RelicRegistry.all_defs_sorted():
		var id := String(def.id)
		if id.begins_with("c_test_") or (rules and id.begins_with("rule_test_")):
			def.disabled = false


static func roster(keys: Array = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]) -> Array:
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1, "max_hp": 30, "muts": [], "growth": {}, "bonus_hp": 0})
	return out


static func ctx(owned: Array = [], seen: Array = [], keys: Array = ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		pick: int = 1, first_run: bool = false) -> Dictionary:
	return {"owned_ids": owned, "roster": roster(keys), "seen": seen, "mode": "short",
		"first_run": first_run, "pick_index": pick, "front_size": 2}
