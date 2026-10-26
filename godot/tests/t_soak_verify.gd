extends Node
## Soak tool: sim_balance --verify must replay each run through RunVerifier and say "ok" for a good run, and a hand-edited
## log / a wrong end state must be reported as a mismatch (otherwise the soak could never catch replay drift).
var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _assert(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)


func _ready() -> void:
	_guard.capture()
	var sim: Node = (load("res://tools/sim_balance.gd") as GDScript).new()   # not added to the tree: _ready (a full CLI run) must not fire
	var recs: Array = sim.run_batch({"runs": 2, "seed": 4100, "asc": "0", "policies": "random_legal", "teams": "all", "cores": "mix", "verify": 1, "anchor": "auto"})
	_assert(recs.size() == 2, "2 runs played")
	for r in recs:
		_assert(String((r as Dictionary).get("verify", "")) == "ok", "good run verifies ok: %s (%s)" % [str(r.get("verify")), str(r.get("vdetail"))])
		_assert(String((r as Dictionary).get("end", "")) in ["WON", "LOST"], "run ends WON/LOST: " + str(r.get("end")))
	# A hand-edited log: a ranked run, one move retargeted, must not replay clean.
	MetaState.runs = 1
	var played: Dictionary = RunBot.play_run(991237, TEAM)
	var good := ActionLog.from_data(JSON.parse_string(JSON.stringify((played["log"] as ActionLog).to_data())))
	_assert(bool(RunVerifier.verify(good, played["tape"])["ok"]), "untouched log verifies")
	var bad := ActionLog.from_data(JSON.parse_string(JSON.stringify((played["log"] as ActionLog).to_data())))
	var edited := false
	for e in bad.entries:
		if String(e["fn"]) == "take_reward":
			e["args"] = [(int((e["args"] as Array)[0]) + 1) % 3]
			edited = true
			break
	_assert(edited, "found a reward pick to edit")
	var v := RunVerifier.verify(bad, played["tape"])
	var live := {"phase": 0, "power_level": 0, "relics": [], "visited": [], "shards": 0, "score": 0}
	var differs: bool = not bool(v["ok"]) or sim._verify_diff(v, live, bool(played["won"])) != ""
	_assert(differs, "edited log is reported as a mismatch")
	# And the comparison itself: a replay that scored differently is a diff.
	_assert(sim._verify_diff({"ok": true, "won": true, "score": 5, "state": {}}, {"score": 9}, true) == "diff:score|live=9 replay=5", "score mismatch named")
	sim.free()
	_guard.restore()
	if _failures.is_empty():
		print("t_soak_verify: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_soak_verify: FAIL — %s" % f)
	get_tree().quit(1)
