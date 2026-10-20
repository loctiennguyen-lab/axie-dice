extends Node
## LocalEpochSource determinism + TapeEpochSource replay/tamper detection.

var _fails: Array[String] = []
var _checks := 0

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _run(secret: int, mutate: bool = false) -> Array:
	var src := LocalEpochSource.new(PackedByteArray(), secret)
	var log := ActionLog.new()
	log.begin(0, ["a"], "short", 0)
	src.bind_log(log)
	var out: Array = []
	var r := src.start_run({"mode": "short", "ascension": 0})
	out.append(r.seed)
	log.record("enter_node", ["r1_c0", "battle"])
	out.append(src.request("node", {"node_id": "r1_c0"}).seed)
	log.record("reroll_dice", [[2, 1], 0 if not mutate else 1])
	out.append(src.request("end_turn", {"turn": 1}).seed)
	return [out, src, log]

func _ready() -> void:
	var a := _run(7)
	var b := _run(7)
	var c := _run(8)
	_check(a[0] == b[0], "same secret + same log => same seeds")
	_check(a[0] != c[0], "different secret => different seeds")
	_check(a[0][1] != a[0][2], "different epochs, different seeds")
	var m := _run(7, true)
	_check(m[0][2] != a[0][2], "an edited log changes the next seed")
	_check(m[0][1] == a[0][1], "seeds before the edit are unchanged")

	# Tape replay with an identical log
	var tape: Array = (a[1] as LocalEpochSource).tape()
	var back = JSON.parse_string(JSON.stringify(tape))   # travels as JSON
	var t := TapeEpochSource.new(back)
	var log2 := ActionLog.new()
	log2.begin(0, ["a"], "short", 0)
	t.bind_log(log2)
	_check(t.start_run({}).seed == a[0][0], "tape run_start seed")
	log2.record("enter_node", ["r1_c0", "battle"])
	_check(t.request("node", {"node_id": "r1_c0"}).seed == a[0][1], "tape node seed")
	log2.record("reroll_dice", [[2, 1], 0])
	var r3 := t.request("end_turn", {"turn": 1})
	_check(r3.ok and r3.seed == a[0][2], "tape end_turn seed")
	_check(t.exhausted(), "tape fully consumed")

	# Tape with a tampered log is refused
	var t2 := TapeEpochSource.new(back)
	var log3 := ActionLog.new()
	log3.begin(0, ["a"], "short", 0)
	t2.bind_log(log3)
	t2.start_run({})
	log3.record("enter_node", ["r1_c0", "battle"])
	t2.request("node", {"node_id": "r1_c0"})
	log3.record("reroll_dice", [[2, 1], 1])
	var r4 := t2.request("end_turn", {"turn": 1})
	_check(not r4.ok and r4.code == "rejected", "tampered log is rejected by the tape")

	# Wrong kind / args
	var t3 := TapeEpochSource.new(back)
	t3.start_run({})
	_check(t3.request("end_turn", {"turn": 1}).code == "rejected", "wrong kind rejected")
	var t4 := TapeEpochSource.new(back)
	t4.start_run({})
	_check(t4.request("node", {"node_id": "r2_c0"}).code == "rejected", "wrong args rejected")

	# Reroll pin: same key twice => same seed
	var s := LocalEpochSource.new(PackedByteArray(), 1)
	var lg := ActionLog.new()
	lg.begin(0, ["a"], "short", 0)
	s.bind_log(lg)
	s.start_run({})
	lg.record("enter_node", ["r1_c0", "battle"])
	s.request("node", {"node_id": "r1_c0"})
	var p1 := s.request("reroll", {"turn": 1, "k": 1, "source": "base", "uids": [1]})
	lg.record("undo_last", [])
	var p2 := s.request("reroll", {"turn": 1, "k": 1, "source": "base", "uids": [1]})
	var p3 := s.request("reroll", {"turn": 1, "k": 2, "source": "base", "uids": [1]})
	_check(p1.seed == p2.seed, "pinned reroll key returns the same seed")
	_check(p3.seed != p1.seed, "next reroll key gets a new seed")
	# Depth v4 3.10.2: a pinned key asked again with another rmode or other uids -> pin_mismatch, no new seed
	var q1 := s.request("reroll", {"turn": 2, "k": 1, "source": "base", "uids": [1, 2], "rmode": 0})
	var q2 := s.request("reroll", {"turn": 2, "k": 1, "source": "base", "uids": [1, 2], "rmode": 1})
	var q3 := s.request("reroll", {"turn": 2, "k": 1, "source": "base", "uids": [2, 1], "rmode": 0})
	var q4 := s.request("reroll", {"turn": 2, "k": 1, "source": "base", "uids": [1, 2], "rmode": 0})
	_check(q1.ok and not q2.ok and q2.code == "pin_mismatch", "rmode change on a pinned key -> pin_mismatch")
	_check(not q3.ok and q3.code == "pin_mismatch", "uids change on a pinned key -> pin_mismatch")
	_check(q4.ok and q4.seed == q1.seed, "the identical request still returns the pinned seed")

	if _fails.is_empty():
		print("t_epoch_source: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_epoch_source: FAIL — %s" % f)
		get_tree().quit(1)
