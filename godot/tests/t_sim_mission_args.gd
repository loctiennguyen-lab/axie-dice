extends Node
## N-S: the Mission flags of tools/sim_balance.gd. Parse (no run), then 1-2 tiny real runs: the header RunState really
## carries Ascension + Mission Rules, the seed list is shared across configs, the same seed twice gives the same records,
## --force_run_rule reaches a disabled rule, Wilson CI. Local epoch only, no network; the real save is held by SaveGuard.

var _fails := 0


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fails += 1
		print("  FAIL: ", what)


func _ready() -> void:
	var guard := SaveGuard.new()
	guard.capture()
	var sim = load("res://tools/sim_balance.gd").new()
	_parse(sim)
	_runs(sim)
	_wilson()
	guard.restore()
	sim.free()
	print("t_sim_mission_args: ", "PASS" if _fails == 0 else "FAIL (%d)" % _fails)
	get_tree().quit(0 if _fails == 0 else 1)


func _parse(sim) -> void:
	var none: Dictionary = sim.parse_mission_args({"runs": 1, "asc": "0", "_asc_default": true})
	_check(none["error"] == "" and (none["configs"] as Array).is_empty(), "no mission flag: no configs (old behaviour)")
	var n3: Dictionary = sim.parse_mission_args({"mission": "N3", "asc": "0", "_asc_default": true})
	var c: Dictionary = (n3["configs"] as Array)[0]
	_check(c["asc"] == 3 and c["rules"] == ["M5", "M6"] and c["mode"] == "short" and c["kind"] == "mission" and c["label"] == "N3", "N3 = A3 + M5 + M6, short, kind mission")
	var all: Dictionary = sim.parse_mission_args({"mission": "N1,n2,N3,N4,N5,N6"})
	var cs: Array = all["configs"]
	_check(cs.size() == 6 and cs[5]["mode"] == "full" and cs[5]["asc"] == 6 and cs[5]["rules"] == ["M1", "M5", "M6", "M7"], "six tiers in order, N6 = full A6 M1 M5 M6 M7")
	_check(cs[0]["asc"] == 0 and (cs[0]["rules"] as Array).is_empty() and cs[1]["asc"] == 1 and cs[1]["rules"] == ["M6"], "N1 = A0 standard only, N2 = A1 + M6")
	_check(cs[3]["asc"] == 4 and cs[3]["rules"] == ["M1", "M7"] and cs[4]["asc"] == 6 and cs[4]["rules"] == ["M2", "M4", "M5"], "N4 and N5 rows")
	var ov: Dictionary = sim.parse_mission_args({"mission": "N3", "asc": "4,5", "rules": "m1,M5", "mode": "full", "kind": "normal"})
	var ocs: Array = ov["configs"]
	_check(ocs.size() == 2 and ocs[0]["asc"] == 4 and ocs[1]["asc"] == 5 and ocs[0]["rules"] == ["M1", "M5"] and ocs[0]["mode"] == "full" and ocs[0]["kind"] == "normal", "--asc list / --rules / --mode / --kind override")
	_check(String(ocs[0]["label"]) != "N3" and String(ocs[0]["label"]) != String(ocs[1]["label"]), "an overridden config gets its own label")
	var nr: Dictionary = sim.parse_mission_args({"mission": "N3", "rules": "none"})
	_check((nr["configs"][0]["rules"] as Array).is_empty(), "--rules=none empties the rules")
	var cu: Dictionary = sim.parse_mission_args({"rules": "M2", "asc": "3"})
	_check(cu["configs"].size() == 1 and cu["configs"][0]["tier"] == "custom" and cu["configs"][0]["asc"] == 3 and cu["configs"][0]["rules"] == ["M2"], "--rules alone = one custom config")
	_check(String(sim.parse_mission_args({"mission": "N7"})["error"]) != "", "unknown tier is an error")
	_check(String(sim.parse_mission_args({"mission": "N1", "rules": "M9"})["error"]) != "", "unknown rule is an error")
	_check(String(sim.parse_mission_args({"mode": "medium"})["error"]) != "", "bad --mode is an error")
	_check(String(sim.parse_mission_args({"mission": "N1", "kind": "ranked"})["error"]) != "", "bad --kind is an error")


func _runs(sim) -> void:
	var base := {"runs": 1, "seed": 4242, "policies": "random_legal", "teams": "mixed_std", "cores": "random"}
	# 1) the header the run really starts with
	var a: Dictionary = base.duplicate()
	a["mission"] = "N3"
	var r3: Array = sim.run_batch(a)
	_check(r3.size() == 1 and r3[0]["cfg"] == "N3" and r3[0]["asc"] == 3, "N3 record carries cfg and asc")
	_check(RunState.ascension == 3 and RunState.mission_rules() == ["M5", "M6"] and RunState.run_kind == "mission" and RunState.mode == "short",
		"RunState holds Ascension 3, rules M5 M6, kind mission, short")
	_check(RunState.anchor_id == "" and String(r3[0]["anchor"]) == "", "mission kind: no Anchor (RunState gate), --anchor=auto notwithstanding")
	# 2) shared seeds across configs + determinism
	var b: Dictionary = base.duplicate()
	b["mission"] = "N1,N2"
	b["runs"] = 2
	var x: Array = sim.run_batch(b.duplicate())
	var y: Array = sim.run_batch(b.duplicate())
	_check(x.size() == 4 and x[0]["seed"] == x[2]["seed"] and x[1]["seed"] == x[3]["seed"] and x[0]["cfg"] == "N1" and x[2]["cfg"] == "N2", "both configs run the same seed list")
	_check(var_to_str(x) == var_to_str(y), "same seeds twice give identical records")
	# 3) Full mode really starts a full run
	var f: Dictionary = base.duplicate()
	f["mode"] = "full"
	f["rules"] = "none"
	f["mission"] = "N6"
	var rf: Array = sim.run_batch(f)
	_check(rf.size() == 1 and RunState.mode == "full", "--mode=full / N6 starts a Full run")
	# 4) kind=normal lets the Anchor through
	var k: Dictionary = base.duplicate()
	k["mission"] = "N1"
	k["kind"] = "normal"
	var rk: Array = sim.run_batch(k)
	_check(RunState.mission_rules().is_empty() and not RunState.mission.is_empty() and String(rk[0]["anchor"]) != "", "--kind=normal: header still a mission, Anchor picked")
	# 5) force a disabled Run Rule (works with or without --mission)
	var fr: Dictionary = base.duplicate()
	fr["force_run_rule"] = "rule_set_is_king"
	var rr: Array = sim.run_batch(fr)
	var d = RelicRegistry.get_def("rule_set_is_king")
	_check(d != null and bool(d.disabled), "precondition: rule_set_is_king exists and is disabled")
	_check(rr.size() == 1 and String(rr[0]["rule"]) == "rule_set_is_king" and rr[0]["cfg"] == "", "--force_run_rule gives the disabled rule")
	var bad: Dictionary = base.duplicate()
	bad["force_run_rule"] = "c_prism"
	_check((sim.run_batch(bad) as Array).is_empty(), "--force_run_rule with a non Run Rule id refuses")
	# 6) no flags: the old header (no mission, no kind)
	var old: Array = sim.run_batch(base.duplicate())
	_check(old.size() == 1 and RunState.mission.is_empty() and RunState.run_kind == "normal" and old[0]["cfg"] == "", "no flags: plain normal run, no cfg")


func _wilson() -> void:
	var w0 := SimReport.wilson(0, 4)
	_check(absf(float(w0[0])) < 1e-9 and absf(float(w0[1]) - 0.4899) < 0.001, "Wilson 0/4 = 0..49.0%")
	var w5 := SimReport.wilson(50, 100)
	_check(absf(float(w5[0]) - 0.4038) < 0.001 and absf(float(w5[1]) - 0.5962) < 0.001, "Wilson 50/100 = 40.4..59.6%")
	var recs: Array = []
	for i in 20:
		recs.append({"seed": i, "policy": "p", "asc": 0, "won": i < 10, "cfg": "A"})
		recs.append({"seed": i, "policy": "p", "asc": 1, "won": i < 4, "cfg": "B"})
	var md := SimReport.mission_section(recs)
	_check(md.contains("| A | p | 20 | 10 | 50.0%") and md.contains("| A -> B | p | 20 | 6 | 0 | -30.0"), "report: p per config and the paired difference")
