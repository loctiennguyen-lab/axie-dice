extends Node
## QA-only (UI-05 b1 QA): headless seed scan with the plain RunBot, to pick seeds for the UI-driven flow
## (qa_ui5_flow_capture): one the bot WINS (boss + victory + result), ones it LOSES (defeat + Continue).
##   godot/tools/with_lock.sh $GODOT --headless --path godot res://tests/qa_ui5_seedscan.tscn -- --from=1 --n=200 --stage=3
## Prints one line per seed: SEED <seed> won=<b> nodes=<n> kinds=<visited kinds>. Real saves restored by SaveGuard.

var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	var a := {}
	for s in OS.get_cmdline_user_args():
		var kv := String(s).trim_prefix("--").split("=")
		if kv.size() == 2:
			a[kv[0]] = kv[1]
	var from := int(a.get("from", "1"))
	var n := int(a.get("n", "100"))
	var stage := int(a.get("stage", "3"))
	var asc := int(a.get("asc", "0"))
	RunState.submit_hook = func(_id: String) -> void: pass   # ranked close never reaches the network
	var wins := 0
	for i in n:
		_meta(stage)
		var seed := from + i
		var r := RunBot.play_run(seed, RunBot.DEFAULT_TEAM, "short", asc)
		var kinds: Array = []
		for e in (r["log"] as ActionLog).entries:
			if String(e["fn"]) == "enter_node":
				kinds.append(String((e["args"] as Array)[1]).substr(0, 2))
		if bool(r["won"]):
			wins += 1
		print("SEED %d won=%s nodes=%d score=%d kinds=%s" % [seed, r["won"], int(r["nodes"]), int(r["score"]), ",".join(kinds)])
	print("SCAN_DONE wins=%d/%d" % [wins, n])
	_guard.restore()
	get_tree().quit(0)


func _meta(stage: int) -> void:
	MetaState.runs = 10 if stage >= 2 else 0
	MetaState.runs_with_battle = 30 if stage >= 2 else 0
	MetaState.runs_completed = 10 if stage == 3 else (1 if stage == 2 else 0)
