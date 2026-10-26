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
	# Mission runs (soak 26/10: the verifier replayed them as normal runs and ~85% diverged): M rules + Anchor must replay ok.
	var mrecs: Array = sim.run_batch({"runs": 2, "seed": 500000, "asc": "0", "policies": "random_legal", "teams": "all", "cores": "mix", "verify": 1,
		"anchor": "auto", "rules": "M1,M5", "kind": "mission", "stage": 3})
	for r in mrecs:
		_assert(String((r as Dictionary).get("verify", "")) == "ok", "mission run verifies ok: %s (%s)" % [str(r.get("verify")), str(r.get("vdetail"))])
	var mb: Dictionary = (sim.last_bundle as Dictionary).duplicate(true)
	var mtape: Array = mb["tape"]
	var mlog := ActionLog.from_data(mb.duplicate(true))
	_assert(not (mlog.header.get("mission", {}) as Dictionary).is_empty() and not ((mlog.header["mission"] as Dictionary).get("rules", []) as Array).is_empty(), "mission log carries tier + M rules")
	_assert(bool(RunVerifier.verify(mlog, mtape, {}, true)["ok"]), "untouched mission log verifies")
	# Header lie: the tape (server) says one mission, the log another -> bad_header.
	var tt: Array = (JSON.parse_string(JSON.stringify(mtape)) as Array)
	var th: Dictionary = ((tt[0] as Dictionary).get("extra", {}) as Dictionary).get("header", {}) as Dictionary
	th["mission"] = {"mission_id": "x", "tier": 1, "rules": []}
	var lied := RunVerifier.verify(ActionLog.from_data(mb.duplicate(true)), tt, {}, true)
	_assert(String(lied.get("error", "")) == RunVerifier.ERR_BAD_HEADER, "mission header differing from the tape is refused: " + str(lied.get("error")))
	# Server mode (no allow_unranked): the tape's mission header is the only truth. Add / drop / alter -> bad_header.
	var srv_tape: Array = (JSON.parse_string(JSON.stringify(mtape)) as Array)
	var srv_h: Dictionary = ((srv_tape[0] as Dictionary).get("extra", {}) as Dictionary).get("header", {}) as Dictionary
	var lm: Dictionary = (mlog.header["mission"] as Dictionary)
	srv_h["mission"] = {"mission_id": str(lm.get("mission_id", "")), "tier": lm.get("tier"), "rules": (lm.get("rules", []) as Array).duplicate()}
	_assert(bool(RunVerifier.verify(ActionLog.from_data(mb.duplicate(true)), srv_tape)["ok"]), "server mode: tape mission == log mission verifies")
	# Key order and int-vs-float do not matter (JSON round trip turns ints into floats).
	var rt: Dictionary = JSON.parse_string(JSON.stringify(mb))
	var rl := ActionLog.from_data(rt)
	var rtape: Array = JSON.parse_string(JSON.stringify(srv_tape))
	_assert(bool(RunVerifier.verify(rl, rtape)["ok"]), "server mode: JSON round trip (floats, key order) still verifies")
	var odd_tape: Array = JSON.parse_string(JSON.stringify(srv_tape))
	var oh: Dictionary = ((odd_tape[0] as Dictionary).get("extra", {}) as Dictionary).get("header", {}) as Dictionary
	var om: Dictionary = oh["mission"]
	oh["mission"] = {"rules": om["rules"], "tier": om["tier"], "mission_id": om["mission_id"]}   # other key order
	_assert(bool(RunVerifier.verify(ActionLog.from_data(mb.duplicate(true)), odd_tape)["ok"]), "server mode: different key order verifies")
	# log has no mission but the tape does
	var nom: Dictionary = mb.duplicate(true)
	(nom["header"] as Dictionary).erase("mission")
	_assert(String(RunVerifier.verify(ActionLog.from_data(nom), srv_tape).get("error", "")) == RunVerifier.ERR_BAD_HEADER, "server mode: log drops the mission -> bad_header")
	# tape has no mission but the log does (server mode)
	_assert(not bool(RunVerifier.verify(ActionLog.from_data(mb.duplicate(true)), mtape)["ok"]), "server mode: log adds a mission the tape lacks -> refused")
	# tier / rules altered in the log
	var alt: Dictionary = mb.duplicate(true)
	((alt["header"] as Dictionary)["mission"] as Dictionary)["tier"] = "N1" if str(lm.get("tier")) != "N1" else "N2"
	_assert(String(RunVerifier.verify(ActionLog.from_data(alt), srv_tape).get("error", "")) == RunVerifier.ERR_BAD_HEADER, "server mode: altered tier -> bad_header")
	var alr: Dictionary = mb.duplicate(true)
	((alr["header"] as Dictionary)["mission"] as Dictionary)["rules"] = []
	_assert(String(RunVerifier.verify(ActionLog.from_data(alr), srv_tape).get("error", "")) == RunVerifier.ERR_BAD_HEADER, "server mode: altered rules -> bad_header")
	var swp: Dictionary = mb.duplicate(true)
	var sr: Array = (((swp["header"] as Dictionary)["mission"] as Dictionary)["rules"] as Array)
	if sr.size() > 1:
		sr.reverse()
		_assert(String(RunVerifier.verify(ActionLog.from_data(swp), srv_tape).get("error", "")) == RunVerifier.ERR_BAD_HEADER, "server mode: rules order matters")
	# ranked + mission -> bad_header
	var rk: Dictionary = mb.duplicate(true)
	(rk["header"] as Dictionary)["ranked"] = true
	var rkv := RunVerifier.verify(ActionLog.from_data(rk), srv_tape)
	_assert(String(rkv.get("error", "")) == RunVerifier.ERR_BAD_HEADER, "ranked + mission -> bad_header: " + str(rkv.get("error")) + str(rkv.get("message")))
	# Empty tape must refuse, not crash.
	var empty := RunVerifier.verify(ActionLog.from_data(mb.duplicate(true)), [], {}, true)
	_assert(not bool(empty.get("ok", true)), "empty tape is refused without crashing")
	sim.free()
	_guard.restore()
	if _failures.is_empty():
		print("t_soak_verify: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_soak_verify: FAIL — %s" % f)
	get_tree().quit(1)
