class_name CoreCombos
extends RefCounted
## Gacha pack: named Core combos, two tiers (design/proposals/core-pick-excitement-brainstorm.md 2.B, contract
## production/gacha-contract.md). Pure + static, no rng. Data: assets/data/rules/core_combos.json.
##
## Row: {id, name_en, name_vi, enabled, jackpot, pair:[a,b]|null, full:core_c|null, jackpot_set:[a,b,c] (jackpot only),
##       hide_if_rules:[rule ids], rule_synergy: rule id ("fits the rule" border, not a member)}.
## Tier "pair" = both pair Cores owned; "full" = pair + third owned. A jackpot has no pair tier: all 3 = "full".
## A combo is hidden when enabled=false, any member Core is missing/disabled, the held Run Rule is in
## hide_if_rules, or a member Core's `excludes` names "rule:<held rule>". `owned` is an owned-id Array and carries
## the held Run Rule (it is an owned def), exactly like CoreOffer ctx.owned_ids. Quest Cores that finished and left
## the slots must still be in `owned` (RunState.owned_relic_ids / quest-done list): the caller passes them.

const PATH := "res://assets/data/rules/core_combos.json"
static var _rows: Array = []
static var _loaded := false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if data is Array:
		_rows = data


## Test hook: drop the cache.
static func reload() -> void:
	_loaded = false
	_rows = []


static func members(row: Dictionary) -> Array:
	if bool(row.get("jackpot", false)):
		return (row.get("jackpot_set", []) as Array).duplicate()
	var out: Array = []
	if row.get("pair") != null:
		out.append_array(row["pair"])
	if row.get("full") != null and String(row["full"]) != "":
		out.append(String(row["full"]))
	return out


static func _visible(row: Dictionary, held_rule: String) -> bool:
	if not bool(row.get("enabled", true)):
		return false
	if held_rule != "" and (row.get("hide_if_rules", []) as Array).has(held_rule):
		return false
	for id in members(row):
		var d = RelicRegistry.get_def(String(id))
		if d == null or d.disabled:
			return false
		if held_rule != "" and (d.excludes as PackedStringArray).has("rule:" + held_rule):
			return false
	return true


static func _held_rule(owned: Array) -> String:
	return CoreOffer.held_rule_id(owned)


## Combos active for a run holding `owned` (null = RunState.owned_relic_ids).
static func all(owned = null) -> Array:
	_load()
	if owned == null:
		owned = RunState.owned_relic_ids
	var rule := _held_rule(owned)
	var out: Array = []
	for r in _rows:
		if _visible(r, rule):
			out.append(r)
	return out


static func get_combo(combo_id: String) -> Dictionary:
	_load()
	for r in _rows:
		if String(r["id"]) == combo_id:
			return r
	return {}


static func _tier_of(row: Dictionary, owned: Array) -> String:
	if bool(row.get("jackpot", false)):
		for id in members(row):
			if not owned.has(id):
				return ""
		return "full"
	var pair: Array = row.get("pair", []) if row.get("pair") != null else []
	if pair.size() < 2 or not (owned.has(pair[0]) and owned.has(pair[1])):
		return ""
	var third := String(row.get("full", "")) if row.get("full") != null else ""
	return "full" if (third != "" and owned.has(third)) else "pair"


## combo id -> "pair" | "full" for every visible combo the owned Cores form.
static func state(owned: Array) -> Dictionary:
	var out := {}
	for r in all(owned):
		var t := _tier_of(r, owned)
		if t != "":
			out[String(r["id"])] = t
	return out


## {id, tier} if taking `core_id` raises a combo to Pair/Full (first one found; Full beats Pair), else {}.
static func card_completes(owned: Array, core_id: String) -> Dictionary:
	if owned.has(core_id):
		return {}
	var after := owned.duplicate()
	after.append(core_id)
	var best := {}
	for r in all(owned):
		if not members(r).has(core_id):
			continue
		var before := _tier_of(r, owned)
		var now := _tier_of(r, after)
		if now == "" or now == before:
			continue
		if best.is_empty() or (now == "full" and best["tier"] == "pair"):
			best = {"id": String(r["id"]), "tier": now}
	return best


## Up to 2 owned Cores that share a visible combo with `core_id` ("Works with" chips). Combo order, then member order.
static func matches(owned: Array, core_id: String) -> Array:
	var out: Array = []
	for r in all(owned):
		var m := members(r)
		if not m.has(core_id):
			continue
		for id in m:
			if id != core_id and owned.has(id) and not out.has(id):
				out.append(id)
				if out.size() >= 2:
					return out
	return out
