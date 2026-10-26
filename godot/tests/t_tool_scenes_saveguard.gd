extends Node
## The two tool scenes that play real runs (record_sample_run, verify_run) drive RunState/MetaState, which
## write the player's real save. Proof that each one: captures a SaveGuard before touching anything, restores it
## before EVERY quit, and that its .tscn really loads that script. Source-level check, because the scenes quit
## the tree and cannot be run inside a test. (Beta plan V5 item 4; l1-lanes.md, 12/10.)

const TOOLS := {
	"res://tools/record_sample_run.gd": "res://tools/record_sample_run.tscn",
	"res://tools/verify_run.gd": "res://tools/verify_run.tscn",
}
var _fails := 0


func _ready() -> void:
	for gd in TOOLS:
		var src := FileAccess.get_file_as_string(gd)
		_check(not src.is_empty(), "%s readable" % gd)
		_check(src.contains("var _guard := SaveGuard.new()"), "%s declares a SaveGuard" % gd)
		var lines := src.split("\n")
		var cap := -1
		var first_play := -1
		for i in lines.size():
			var l: String = lines[i]
			if cap < 0 and l.contains("_guard.capture()"):
				cap = i
			if first_play < 0 and (l.contains("RunBot.") or l.contains("RunVerifier.") or l.contains("RunState.")):
				first_play = i
		_check(cap >= 0 and (first_play < 0 or cap < first_play), "%s captures before it touches RunState" % gd)
		var quits := 0
		for i in lines.size():
			if String(lines[i]).contains("get_tree().quit("):
				quits += 1
				var ok := false
				for j in range(maxi(0, i - 3), i):
					if String(lines[j]).contains("_guard.restore()"):
						ok = true
				_check(ok, "%s line %d: restore() right before quit" % [gd, i + 1])
		_check(quits > 0, "%s has a quit to check" % gd)
		var tscn := FileAccess.get_file_as_string(TOOLS[gd])
		_check(tscn.contains(gd), "%s loads %s" % [TOOLS[gd], gd])
	print("t_tool_scenes_saveguard: ", "PASS" if _fails == 0 else "FAILED (%d)" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("  FAIL ", what)
