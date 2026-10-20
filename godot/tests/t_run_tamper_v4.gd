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
