class_name TapeEpochSource
extends EpochSource
## Plays back a recorded tape `[{seq, kind, args, seed, extra}]` (tutorial, RunVerifier, resume).
##
## Strict on purpose: the n-th request must have the same kind and args as the n-th entry, and when
## the entry carries `extra.h` / `extra.log_len` AND a log is bound, the hash of the log replayed so
## far must equal the recorded one. A log edited after the fact therefore fails here with
## "rejected" instead of silently replaying into some other run.

var _entries: Array = []
var _pos := 0


func _init(p_tape: Array = []) -> void:
	for e in p_tape:
		var d: Dictionary = (e as Dictionary).duplicate(true)
		d["seq"] = int(d.get("seq", 0))
		d["seed"] = int(d.get("seed", 0))
		d["args"] = ActionLog._restore_ints(d.get("args", {}))
		d["extra"] = ActionLog._restore_ints(d.get("extra", {}))
		_entries.append(d)


func start_run(_params: Dictionary) -> EpochReply:
	if _pos != 0 or _entries.is_empty() or String(_entries[0].get("kind", "")) != "run_start":
		return EpochReply.fail("out_of_order")
	var run_id := String((_entries[0]["extra"] as Dictionary).get("run_id", ""))
	if run_id == "":
		return EpochReply.fail("bad_request")
	_chain_begin(run_id)
	return _take("run_start", null)


func request(kind: String, args: Dictionary) -> EpochReply:
	if _pos == 0:
		return EpochReply.fail("out_of_order")
	return _take(kind, args)


func _take(kind: String, args: Variant) -> EpochReply:
	if _pos >= _entries.size():
		return EpochReply.fail("out_of_order", {"error": "tape exhausted"})
	var e: Dictionary = _entries[_pos]
	if String(e.get("kind", "")) != kind:
		return EpochReply.fail("rejected", {"error": "kind %s, tape has %s" % [kind, e.get("kind", "?")]})
	if args != null:
		var a := EpochCanon.request({"args": args}, true)
		var b := EpochCanon.request({"args": e.get("args", {})}, true)
		if not bool(a["ok"]) or not bool(b["ok"]) or String(a["canon"]) != String(b["canon"]):
			return EpochReply.fail("rejected", {"error": "args differ from tape at seq %d" % _pos})
	var peek := _chain_peek()
	if not bool(peek["ok"]):
		return EpochReply.fail("bad_request", {"error": String(peek["error"])})
	var ex: Dictionary = e["extra"]
	if _log != null and ex.has("h"):
		if String(ex["h"]) != String(peek["h"]) or int(ex.get("log_len", -1)) != int(peek["log_len"]):
			return EpochReply.fail("rejected", {"error": "log does not match the tape at seq %d" % _pos})
	_chain_commit(peek)
	_pos += 1
	return EpochReply.ok_reply(int(e["seed"]), ex.duplicate(true))


func tape() -> Array:
	return _entries.slice(0, _pos).duplicate(true)


## True when every recorded epoch was consumed (the verifier checks this at the end).
func exhausted() -> bool:
	return _pos >= _entries.size()
