extends Node
## Depth v4 contract: the error codes `stage_mismatch` and `pin_mismatch` (and the ranked `ranked_stage`) mean the same on
## both sides. The Worker (worker/src/run_core.js, runs.js, leaderboard.js) returns them, the client (RunVerifier,
## LocalEpochSource, NetNotice) recognises them, and the args that the pin compares (rmode, source, uids) are in
## worker/src/epoch_args.json for the reroll kind. Reads the Worker source as text (no network).
## Run: godot --headless --path godot res://tests/t_depth_epoch_args_contract.tscn

var _fails: Array[String] = []
var _checks := 0


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _read(rel: String) -> String:
	var f := FileAccess.open(ProjectSettings.globalize_path("res://").path_join(rel), FileAccess.READ)
	return f.get_as_text() if f != null else ""


func _ready() -> void:
	var core := _read("../worker/src/run_core.js")
	var runs := _read("../worker/src/runs.js")
	var lb := _read("../worker/src/leaderboard.js")
	var spec := JSON.parse_string(_read("../worker/src/epoch_args.json")) as Dictionary
	_check(not core.is_empty() and not runs.is_empty() and not lb.is_empty() and not spec.is_empty(), "Worker sources readable")

	# Worker side: epoch_req and run_close both answer stage_mismatch; reroll pin answers pin_mismatch.
	_check(core.count("fail(seq, 'stage_mismatch')") >= 2, "Worker: stage_mismatch on epoch_req and run_close")
	_check(core.contains("fail(seq, 'pin_mismatch')"), "Worker: pin_mismatch on a pinned reroll key")
	_check(core.contains("fail(seq, 'ranked_stage')") and runs.contains("'ranked_stage'") and lb.contains("'ranked_stage'"), "Worker: ranked_stage on close, create, submit")

	# Client side: same strings.
	_check(RunVerifier.ERR_STAGE_MISMATCH == "stage_mismatch", "RunVerifier code == Worker code")
	_check(NetNotice.text_for("stage_mismatch") == NetNotice.text_for("pin_mismatch") and NetNotice.text_for("pin_mismatch") != NetNotice.text_for("nope"), "NetNotice knows both codes")
	_check(not NetNotice.is_fatal("stage_mismatch") and not NetNotice.is_fatal("pin_mismatch"), "neither is fatal (the move is undone, the run goes on)")

	# The pin compares rmode, source, uids: all three must be legal reroll args in the shared spec.
	var keys: Array = ((spec["kinds"] as Dictionary)["reroll"] as Dictionary)["keys"]
	for k in ["rmode", "source", "uids"]:
		_check(keys.has(k), "epoch_args.json: reroll accepts '%s'" % k)

	# Client pin_mismatch behaves as the Worker's (same pinned key, other rmode / uids / source).
	var lg := ActionLog.new()
	lg.begin(0, ["a"], "short", 0)
	var s := LocalEpochSource.new(PackedByteArray(), 99)
	s.bind_log(lg)
	s.start_run({})
	lg.record("enter_node", ["r1_c0", "battle"])
	s.request("node", {"node_id": "r1_c0"})
	var a := s.request("reroll", {"turn": 1, "k": 1, "source": "base", "uids": [1, 2], "rmode": 1})
	var b := s.request("reroll", {"turn": 1, "k": 1, "source": "base", "uids": [1, 2], "rmode": 0})
	var c := s.request("reroll", {"turn": 1, "k": 1, "source": "base", "uids": [2], "rmode": 1})
	_check(a.ok and not b.ok and b.code == "pin_mismatch", "client: other rmode -> pin_mismatch")
	_check(not c.ok and c.code == "pin_mismatch", "client: other uids -> pin_mismatch")

	if _fails.is_empty():
		print("t_depth_epoch_args_contract: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_depth_epoch_args_contract: FAIL - " + f)
		get_tree().quit(1)
