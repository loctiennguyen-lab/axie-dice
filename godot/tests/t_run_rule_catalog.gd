extends Node
## Depth v3 lane C: 13 Run Rules (design 2b.2). Weights R10/R12/R13 = 2, total 16; enabled rules have a hook.
var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _ready() -> void:
	var n := 0
	var total := 0
	var off := 0
	for d in RelicRegistry.all_defs_sorted():
		var def: RelicDef = d
		if not def.run_rule or def.id == "rule_none":
			continue
		var id := String(def.id)
		n += 1
		total += def.weight
		_ok(id.begins_with("rule_") and def.core_axis == "run_rule", "%s: rule id/axis" % id)
		_ok(def.description.length() > 10, "%s: text" % id)
		var heavy := ["rule_old_forest", "rule_hard_shell", "rule_balance"].has(id)
		_ok(def.weight == (2 if heavy else 1), "%s: weight %d" % [id, def.weight])
		if def.disabled:
			off += 1
			_ok(def.hidden_from_pool and def.needs_hook != "", "%s: disabled has needs_hook" % id)
			_ok(not def.rule_knobs.is_empty(), "%s: knobs declared for the lane that owns them" % id)
		elif id != "rule_crow":
			_ok(RelicHooks.TABLE.has(String(def.hook_key)), "%s: hook" % id)
		_ok(not def.rule_knobs.is_empty(), "%s: rule_knobs" % id)
	var none = RelicRegistry.get_def("rule_none")
	_ok(none != null and none.weight == 0, "rule_none weight 0")
	_ok(n == 13, "13 rules, got %d" % n)
	_ok(total == 16, "total weight 16, got %d" % total)
	print("t_run_rule_catalog: rules=%d disabled(waiting engine)=%d total_weight=%d" % [n, off, total])
	print("=== t_run_rule_catalog: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_run_rule_catalog: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_run_rule_catalog: FAIL — %s" % f)
	get_tree().quit(1)
