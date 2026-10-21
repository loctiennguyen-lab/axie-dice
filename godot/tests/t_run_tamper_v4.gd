extends BoTestBase
## Depth v4 QA T2 / T3 / T5 (+ T6 / T7 in the stage half): tampers of Mat Tam (wild_face) through the FULL replay path, RunVerifier over a whole
## run's log + tape, not just the engine. A refused action must be named at its own index.

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
const SEEDS := [991237, 991238, 991239, 991240, 991241, 991242, 991243, 991244]


func run() -> void:
	_name = "t_run_tamper_v4"
	var played := _find_run()
	ok(not played.is_empty(), "found a run whose bot took a Mat Tam")
	if played.is_empty():
		return
	var log: ActionLog = played["log"]
	var tape: Array = played["tape"]
	var wi := _first(log, "wild_face")
	var honest := RunVerifier.verify(log, tape)
	ok(bool(honest["ok"]), "honest run with a Mat Tam verifies (%s %s)" % [str(honest["error"]), str(honest["message"])])
	eq(int(honest["score"]), int(played["score"]), "referee score = played score")
	_t2(log, tape, wi, honest)
	_t3(log, tape, wi)
	_t5(log, tape)
	_md(log, tape, wi, honest)
	_stage(log, tape, wi)
	_oc_outside_set()


func _find_run() -> Dictionary:
	RunBot.wild_script = true
	var out := {}
	for s in SEEDS:
		var r := RunBot.play_run(int(s), TEAM)
		var l := _clone(r["log"])
		if _first(l, "wild_face") >= 0:
			out = {"log": l, "tape": (r["tape"] as Array).duplicate(true), "score": r["score"], "seed": s}
			break
	RunBot.wild_script = false
	return out


func _clone(source: ActionLog) -> ActionLog:
	return ActionLog.from_data(JSON.parse_string(JSON.stringify(source.to_data())))


func _first(l: ActionLog, fn: String) -> int:
	for i in l.entries.size():
		if String((l.entries[i] as Dictionary).get("fn", "")) == fn:
			return i
	return -1


## T2: another slot for the same Mat Tam. Out-of-range is refused AT that action; any legal alternative either fails somewhere or scores differently.
func _t2(log: ActionLog, tape: Array, wi: int, honest: Dictionary) -> void:
	var args: Array = (log.entries[wi] as Dictionary)["args"]
	var bad := _clone(log)
	(bad.entries[wi] as Dictionary)["args"] = [args[0], 9]
	var v := RunVerifier.verify(bad, tape)
	ok(not bool(v["ok"]) and String(v["error"]) == RunVerifier.ERR_REJECTED and int(v["action_index"]) == wi, "T2: slot 9 refused at the wild_face (%s @%s)" % [str(v["error"]), str(v["action_index"])])
	var caught := 0
	for slot in 6:
		if slot == int(args[1]):
			continue
		var alt := _clone(log)
		(alt.entries[wi] as Dictionary)["args"] = [args[0], slot]
		var r := RunVerifier.verify(alt, tape)
		if not bool(r["ok"]) or int(r["score"]) != int(honest["score"]) or JSON.stringify(r["state"]) != JSON.stringify(honest["state"]):
			caught += 1
	eq(caught, 5, "T2: every other slot is detected (refused, or a different run)")


## T3: a second wild_face in the same turn.
func _t3(log: ActionLog, tape: Array, wi: int) -> void:
	var dup := _clone(log)
	dup.entries.insert(wi + 1, (dup.entries[wi] as Dictionary).duplicate(true))
	var v := RunVerifier.verify(dup, tape)
	ok(not bool(v["ok"]) and int(v["action_index"]) == wi + 1, "T3: second wild_face in the turn refused at its own index (%s @%s)" % [str(v["error"]), str(v["action_index"])])
	var other := _clone(log)
	var a: Array = (other.entries[wi] as Dictionary)["args"]
	other.entries.insert(wi + 1, {"fn": "wild_face", "args": [a[0], (int(a[1]) + 1) % 6]})
	var v2 := RunVerifier.verify(other, tape)
	ok(not bool(v2["ok"]) and int(v2["action_index"]) == wi + 1, "T3: second wild_face with another slot refused too")


## MD 22/10 tampers through RunVerifier: (a) the Mat Tam moved onto another die (a pair / loose die cannot make 3 -> 4), (b) a second Mat Tam
## in the same fight (a later turn: after the honest one, a copy at the end of the log's next end_turn), (c) an overcast inserted on every die
## right after the Mat Tam (a die outside a Set, or no mana, is refused at its own index; never accepted with a different outcome unnoticed).
func _md(log: ActionLog, tape: Array, wi: int, honest: Dictionary) -> void:
	var args: Array = (log.entries[wi] as Dictionary)["args"]
	var caught := 0
	var tried := 0
	for uid in range(1, 7):
		if uid == int(args[0]):
			continue
		var t := _clone(log)
		(t.entries[wi] as Dictionary)["args"] = [uid, args[1]]
		var r := RunVerifier.verify(t, tape)
		tried += 1
		if not bool(r["ok"]) or int(r["score"]) != int(honest["score"]) or JSON.stringify(r["state"]) != JSON.stringify(honest["state"]):
			caught += 1
	eq(caught, tried, "MD: Mat Tam moved to another die is detected (refused or a different run)")
	var ni := -1
	for i in range(wi + 1, log.entries.size()):
		if String((log.entries[i] as Dictionary)["fn"]) == "end_turn":
			ni = i
			break
	if ni >= 0 and ni + 1 < log.entries.size():
		var late := _clone(log)
		late.entries.insert(ni + 1, (late.entries[wi] as Dictionary).duplicate(true))
		var v := RunVerifier.verify(late, tape)
		ok(not bool(v["ok"]) and int(v["action_index"]) == ni + 1, "MD: a 2nd Mat Tam in a later turn of the same fight is refused at its index (%s @%s)" % [str(v["error"]), str(v["action_index"])])
	var oc_caught := 0
	for uid in range(1, 7):
		var o := _clone(log)
		o.entries.insert(wi + 1, {"fn": "overcast", "args": [uid]})
		var r2 := RunVerifier.verify(o, tape)
		if not bool(r2["ok"]) or int(r2["score"]) != int(honest["score"]):
			oc_caught += 1
	ok(oc_caught >= 1, "MD: inserted overcasts are refused or change the run (%d of 6)" % oc_caught)


## T5: a wild_face with no mana: the first thing in a fresh fight (mana 0 at turn 1).
func _t5(log: ActionLog, tape: Array) -> void:
	var n := -1
	for i in log.entries.size() - 1:
		if String((log.entries[i] as Dictionary)["fn"]) == "enter_node" and String(((log.entries[i] as Dictionary)["args"] as Array)[1]) in ["battle", "elite", "boss"]:
			n = i
			break
	ok(n >= 0, "found a fight node")
	if n < 0:
		return
	var refused := 0
	var tried := 0
	for uid in range(1, 7):
		var t := _clone(log)
		t.entries.insert(n + 1, {"fn": "wild_face", "args": [uid, 1]})
		var v := RunVerifier.verify(t, tape)
		tried += 1
		if not bool(v["ok"]) and int(v["action_index"]) == n + 1 and String(v["error"]) == RunVerifier.ERR_REJECTED:
			refused += 1
	eq(refused, tried, "T5: a Mat Tam with 0 mana is refused at its own index, whatever the die")


## T6 / T7: the stage comes from the server's tape (run_start extra.header.depth_stage), never from the log header.
func _stage(log: ActionLog, tape: Array, wi: int) -> void:
	eq(int(log.header.get("depth_stage", -1)), 3, "header carries depth_stage (local default 3)")
	var low_tape := tape.duplicate(true)
	var hdr: Dictionary = ((low_tape[0] as Dictionary)["extra"] as Dictionary)["header"]
	hdr["depth_stage"] = 1
	# T6: the server said stage 1; the log (header agreed) still holds a wild_face. Refused at its own index.
	var low_log := _clone(log)
	low_log.header["depth_stage"] = 1
	var v6 := RunVerifier.verify(low_log, low_tape)
	ok(not bool(v6["ok"]) and String(v6["error"]) == RunVerifier.ERR_REJECTED and int(v6["action_index"]) == wi, "T6: wild_face in a stage-1 run refused at its index (%s @%s)" % [str(v6["error"]), str(v6["action_index"])])
	# T7: the server said stage 1, the log header was edited up to 3.
	var v7 := RunVerifier.verify(log, low_tape)
	eq(String(v7["error"]), RunVerifier.ERR_STAGE_MISMATCH, "T7: header stage 3 vs server stage 1 -> stage_mismatch")
	# and the other way round
	var up_log := _clone(log)
	up_log.header["depth_stage"] = 1
	eq(String(RunVerifier.verify(up_log, tape)["error"]), RunVerifier.ERR_STAGE_MISMATCH, "header stage 1 vs server stage 3 -> stage_mismatch")
	# stage 2: wild_face is allowed (it opens at 2)
	var mid_tape := tape.duplicate(true)
	(((mid_tape[0] as Dictionary)["extra"] as Dictionary)["header"] as Dictionary)["depth_stage"] = 2
	var mid_log := _clone(log)
	mid_log.header["depth_stage"] = 2
	var v2 := RunVerifier.verify(mid_log, mid_tape)
	ok(String(v2["error"]) != RunVerifier.ERR_STAGE_MISMATCH, "stage 2 header agreeing with its tape is not a stage mismatch")


## MD review: an Overcast aimed at a die that is NOT in a Set is refused at its own index through RunVerifier. Bot hook overcast_script takes honest
## Overcasts; for the first one, every other die is tried: a Set member verifies, anything else must be ERR_REJECTED at that index (>= 1 such die).
func _oc_outside_set() -> void:
	RunBot.overcast_script = true
	var found := {}
	for s in SEEDS:
		var r := RunBot.play_run(int(s), TEAM)
		var l := _clone(r["log"])
		if _first(l, "overcast") >= 0:
			found = {"log": l, "tape": (r["tape"] as Array).duplicate(true)}
			break
	RunBot.overcast_script = false
	ok(not found.is_empty(), "found a run whose bot took an Overcast")
	if found.is_empty():
		return
	var log: ActionLog = found["log"]
	var tape: Array = found["tape"]
	var oi := _first(log, "overcast")
	ok(bool(RunVerifier.verify(log, tape)["ok"]), "honest run with an Overcast verifies")
	var real := int(((log.entries[oi] as Dictionary)["args"] as Array)[0])
	var refused := 0
	for uid in range(1, 7):
		if uid == real:
			continue
		var t := _clone(log)
		(t.entries[oi] as Dictionary)["args"] = [uid]
		var v := RunVerifier.verify(t, tape)
		if not bool(v["ok"]) and int(v["action_index"]) == oi:
			ok(String(v["error"]) == RunVerifier.ERR_REJECTED, "Overcast on die %d outside the Set is ERR_REJECTED at its own index" % uid)
			refused += 1
		else:
			# accepted at oi = another Set member (same or different Set); it may only break LATER, never earlier
			ok(bool(v["ok"]) or int(v["action_index"]) > oi, "Overcast on die %d accepted at oi: any failure comes later (%s @%s)" % [uid, str(v["error"]), str(v["action_index"])])
	ok(refused >= 1, "at least one die outside the Set was refused (%d)" % refused)
