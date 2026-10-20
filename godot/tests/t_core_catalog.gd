extends Node
## Depth v3 lane C: every Core (design 2.7, 2.10) is well formed. Enabled Cores have text, a real hook, a valid
## tier/axis; disabled Cores say why. Counts the 2.10 thresholds on enabled + waiting-for-hook Cores.
const AXES := ["stat", "dice", "pos", "mana", "quest", "rule"]
var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _ready() -> void:
	var enabled := 0
	var waiting := 0
	var cut := 0
	var nonattack := 0
	var convert := 0
	var trade := 0
	var tiers := [0, 0, 0]
	var ids := {}
	for d in RelicRegistry.all_defs_sorted():
		var def: RelicDef = d
		if def.core_axis == "" or def.run_rule:
			continue
		var id := String(def.id)
		_ok(id.begins_with("c_") and not ids.has(id), "%s: id unique and c_ prefixed" % id)
		ids[id] = true
		_ok(AXES.has(def.core_axis), "%s: valid axis (%s)" % [id, def.core_axis])
		_ok(def.rarity >= 0 and def.rarity <= 2, "%s: tier 0..2" % id)
		_ok(def.description.length() > 10 and def.name != "", "%s: has name and text" % id)
		_ok(def.tags.size() <= 2, "%s: at most 2 tags" % id)
		if def.disabled:
			_ok(def.hidden_from_pool and def.needs_hook != "", "%s: disabled needs hidden_from_pool + needs_hook" % id)
			if def.needs_hook.begins_with("cut"):
				cut += 1
				continue
			waiting += 1
		else:
			enabled += 1
			tiers[def.rarity] += 1
			var hk := String(def.hook_key)
			if def.quest.is_empty() and id != "c_fossil" and id != "c_dim_stone":
				_ok(hk != "" and RelicHooks.TABLE.has(hk) and not (RelicHooks.TABLE[hk] as Dictionary).is_empty(), "%s: hook exists in TABLE" % id)
			if def.core_axis == "quest":
				_ok(not def.quest.is_empty() and (def.quest["steps"] as Array).size() >= 1, "%s: quest data" % id)
		if def.tags.has("nonattack"):
			nonattack += 1
		if def.tags.has("convert_to_dmg"):
			convert += 1
		if def.tags.has("tradeoff"):
			trade += 1
	print("t_core_catalog: enabled=%d waiting_for_hook=%d cut=%d tiers(R/H/T)=%s" % [enabled, waiting, cut, str(tiers)])
	print("t_core_catalog: threshold 2.10 nonattack=%d (>=24) convert=%d (>=6) tradeoff=%d (>=3)" % [nonattack, convert, trade])
	_ok(nonattack >= 24, "2.10: non-attack face Cores >= 24, got %d" % nonattack)
	_ok(convert >= 6, "2.10: Cores turning support faces into damage >= 6, got %d" % convert)
	_ok(trade >= 3, "2.10: trade-off Cores >= 3, got %d" % trade)
	_ok(enabled + waiting + cut == 50, "50 Cores in the catalog, got %d" % (enabled + waiting + cut))
	print("=== t_core_catalog: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_core_catalog: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_core_catalog: FAIL — %s" % f)
	get_tree().quit(1)
