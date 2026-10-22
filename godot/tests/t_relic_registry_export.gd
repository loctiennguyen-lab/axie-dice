extends Node
## RelicRegistry reads res://resources/relics/ by listing the directory. An exported build lists
## `x.tres.remap`, not `x.tres` (found on axiedice.fun 22/10: the web build had no Cores, no Run Rules,
## no Anchor). def_file_name() must map both forms to the loadable .tres and skip everything else.

var _checks := 0
var _fails: Array[String] = []


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fails.append(msg)


func _ready() -> void:
	_ok(RelicRegistry.def_file_name("c_nest.tres") == "c_nest.tres", "editor name kept")
	_ok(RelicRegistry.def_file_name("c_nest.tres.remap") == "c_nest.tres", "exported .remap name maps to the .tres")
	_ok(RelicRegistry.def_file_name("c_nest.tres.import") == "", ".import skipped")
	_ok(RelicRegistry.def_file_name("c_nest.gd") == "", "script skipped")
	_ok(RelicRegistry.def_file_name("c_nest.gd.remap") == "", "non-tres remap skipped")
	_ok(RelicRegistry.def_file_name("") == "", "empty skipped")
	_ok(RelicRegistry.all_defs_sorted().size() > 50, "registry loaded the relic set (%d)" % RelicRegistry.all_defs_sorted().size())
	print("=== t_relic_registry_export: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_relic_registry_export: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_relic_registry_export: FAIL - %s" % f)
	get_tree().quit(1)
