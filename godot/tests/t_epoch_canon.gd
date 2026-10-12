extends Node
## EpochCanon against the shared golden vectors (res://tests/data/epoch_golden.json).
## Lane S copies the same file to worker/test/ and checks its JS against it.

var _fails: Array[String] = []
var _checks := 0

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _ready() -> void:
	var f := FileAccess.open("res://tests/data/epoch_golden.json", FileAccess.READ)
	var g: Dictionary = JSON.parse_string(f.get_as_text())
	var s_run := String(g["s_run_hex"]).hex_decode()
	var run_id := String(g["run_id"])

	_check(EpochCanon.commit(run_id, s_run).hex_encode() == String(g["commit"]), "commit")
	_check(EpochCanon.h0(run_id).hex_encode() == String(g["h0"]), "h0")

	for row in g["action_lines"]:
		var a: Dictionary = row["action"]
		var r := EpochCanon.action_line(String(a["fn"]), a["args"])
		_check(bool(r["ok"]) and String(r["canon"]) == String(row["canon"]), "action line %s" % a["fn"])

	var prev := EpochCanon.h0(run_id)
	for st in g["chain"]:
		var d := EpochCanon.delta(st["delta"])
		_check(bool(d["ok"]) and String(d["canon"]) == String(st["canon"]), "delta canon")
		prev = EpochCanon.chain_step(prev, String(d["canon"]))
		_check(prev.hex_encode() == String(st["h"]), "chain h")

	for ep in g["epochs"]:
		var r := EpochCanon.request(ep["request"])
		_check(bool(r["ok"]) and String(r["canon"]) == String(ep["canon"]),
			"request canon seq %d" % int(ep["request"]["seq"]))
		_check(EpochCanon.seed_from(s_run, String(r["canon"])) == int(ep["seed"]),
			"seed seq %d" % int(ep["request"]["seq"]))

	for inv in g["invalid"]:
		var a2: Dictionary = inv["action"]
		var r2 := EpochCanon.action_line(String(a2["fn"]), a2["args"])
		_check(not bool(r2["ok"]), "must be refused: %s" % inv["why"])

	for n in g["node_ids"]:
		_check(EpochCanon.node_row(String(n["id"])) == int(n["row"]), "node_row %s" % n["id"])

	for rt in g["rowtypes"]:
		_check(EpochCanon.rowtype_digest(s_run, run_id, int(rt["row"])).hex_encode() == String(rt["digest"]),
			"rowtype row %d" % int(rt["row"]))

	# uids are NOT seed input: same canon, same seed whatever order or content (ADR-RNG 4.4).
	var e2: Dictionary = g["epochs"][2]
	var e3: Dictionary = g["epochs"][3]
	_check(String(EpochCanon.request(e2["request"])["canon"]) == String(EpochCanon.request(e3["request"])["canon"]),
		"uid order must not change the canon")
	_check(int(e2["seed"]) == int(e3["seed"]), "golden: different uids, same seed")
	_check(String(EpochCanon.request(e2["request"], true)["canon"]) != String(EpochCanon.request(e3["request"], true)["canon"]),
		"with include_uids the lists differ")

	if _fails.is_empty():
		print("t_epoch_canon: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for m in _fails:
			print("t_epoch_canon: FAIL — %s" % m)
		get_tree().quit(1)
