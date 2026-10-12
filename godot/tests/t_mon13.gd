extends Node
## MON-13 static guard: the rules in `scripts/core` must not read per-run Aid / Continue / Boon
## STATE (`aid_*`, `continue_used`, `boon_used`). Those live in RunState and the ledger and are
## replayed from the action log (`aid_use`, `continue`); a rule that branched on them would make
## the verifier depend on state the log cannot reconstruct. `boon_id` is the loadout chosen at the
## start of a run, so ONLY `_reward_count` may read it. String literals (the action names
## "aid_use" and friends) and comments are ignored. It is a text scan, not a proof: it catches
## the easy way to break the rule, which is the way people actually break it.

const DIR := "res://scripts/core"
const FORBIDDEN := "\\b(continue_used|boon_used|aid_[a-z_0-9]*)\\b"
const BOON_ID := "\\bboon_id\\b"
const BOON_ID_OK_FUNC := "_reward_count"


func _ready() -> void:
	var bad: Array[String] = []
	var scanned := 0
	var forbidden := RegEx.create_from_string(FORBIDDEN)
	var boon := RegEx.create_from_string(BOON_ID)
	var strings := RegEx.create_from_string("\"[^\"]*\"|'[^']*'")
	var dir := DirAccess.open(DIR)
	for name in dir.get_files():
		if not String(name).ends_with(".gd"):
			continue
		scanned += 1
		var cur_func := ""
		var n := 0
		for raw in FileAccess.get_file_as_string("%s/%s" % [DIR, name]).split("\n"):
			n += 1
			var line := String(raw)
			var t := line.strip_edges()
			if t.begins_with("func ") or t.begins_with("static func "):
				cur_func = t.split("func ")[1].split("(")[0]
			if t.begins_with("#"):
				continue
			var code := strings.sub(line, "", true)
			var hash_at := code.find("#")
			if hash_at >= 0:
				code = code.substr(0, hash_at)
			if forbidden.search(code) != null:
				bad.append("%s:%d reads Aid/Continue/Boon state: %s" % [name, n, t])
			if boon.search(code) != null and cur_func != BOON_ID_OK_FUNC:
				bad.append("%s:%d reads boon_id outside %s: %s" % [name, n, BOON_ID_OK_FUNC, t])
	if scanned == 0:
		print("t_mon13: FAIL — scanned no files, the gate is blind")
		get_tree().quit(1)
		return
	if bad.is_empty():
		print("t_mon13: PASS — %d rule files read no Aid/Continue/Boon state (MON-13)" % scanned)
		get_tree().quit(0)
		return
	for b in bad:
		print("t_mon13: FAIL — %s" % b)
	get_tree().quit(1)
