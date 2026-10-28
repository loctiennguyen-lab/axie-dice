extends Node
## Guard (28/10): live_smoke must never copy, move, delete or write anything of the desktop app's session
## (its user dir "Axie Dice"). Until 27/10 it copied the app's device_tokens.dat and wrote the rotated file back;
## a lost write-back made the server revoke the app's device and Liam was signed out. The smoke tool has its own
## device session now. This is a static check of tools/live_smoke.sh and live_smoke.gd (no network, no Godot run).
## Run: godot --headless --path godot res://tests/t_live_smoke_isolation.tscn

var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)
		printerr("FAIL: ", msg)


func _ready() -> void:
	print("=== t_live_smoke_isolation: start ===")
	var sh := FileAccess.get_file_as_string("res://tools/live_smoke.sh")
	var gd := FileAccess.get_file_as_string("res://tools/live_smoke.gd")
	_check(sh != "" and gd != "", "tool files readable")
	var mutating := RegEx.create_from_string("(^|[\\s;&|(])(cp|mv|rm|tee|touch|ln|install|dd)\\s")
	var n_src := 0
	for raw in sh.split("\n"):
		var line := raw.strip_edges()
		if line.begins_with("#"):
			continue
		if line.contains("$SRC") or line.contains("${SRC") or line.contains("LIVE_SMOKE_SRC_DIR"):
			n_src += 1
			_check(mutating.search(line) == null, "live_smoke.sh must not modify the app dir: " + line)
			_check(not line.contains("> \"$SRC") and not line.contains(">\"$SRC"), "no redirect into the app dir: " + line)
	_check(n_src > 0, "the refuse-guards that mention the app dir still exist")
	_check(not sh.contains("LIVE_SMOKE_NO_WRITEBACK"), "no write-back to the app (old opt-out gone)")
	_check(sh.contains("--login") and sh.contains("TOK_DIR"), "own smoke token store + --login present")
	_check(sh.contains("must not be the desktop app's dir"), "tokens dir refuses the app dir")
	_check(not gd.contains("app_userdata") and not gd.contains("Axie Dice"), "live_smoke.gd never names the app's dir")
	if _fails.is_empty():
		print("PASS t_live_smoke_isolation (%d checks)" % _checks)
	else:
		printerr("FAIL t_live_smoke_isolation: ", _fails.size(), " of ", _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
