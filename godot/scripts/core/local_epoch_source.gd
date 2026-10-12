class_name LocalEpochSource
extends EpochSource
## Epoch seeds computed on this machine with the SAME formula the server uses (ADR-RNG §4.1),
## but with S_run derived from a test key + a per-run secret. For tests, dev, bots and sim only:
## it is NOT secret, so a run played on it proves nothing to a server.
##
## Because it hashes the real action log into every request, a Local run is bound to the
## decisions made so far exactly like a remote one — which is what lets TapeEpochSource later
## detect a log that was edited after the fact.

const DEFAULT_KEY := "axiedice-local-test-key"
const DOMAIN_RUN := "axiedice/local/v1"

var _key: PackedByteArray
var _secret: int
var _s_run: PackedByteArray = PackedByteArray()
var _nonce: String = ""
var _started := false
var _seq := 0
var _rules_version := ""
var _tape: Array = []
var _pins: Dictionary = {}
var _last_node_seq := 0


## `local_run_secret` plays the role the old `run_seed` did in tests: same secret, same run.
func _init(local_key: PackedByteArray = PackedByteArray(), local_run_secret: int = 0,
		rules_version: String = "") -> void:
	_key = local_key if not local_key.is_empty() else DEFAULT_KEY.to_utf8_buffer()
	_secret = local_run_secret
	_rules_version = rules_version if rules_version != "" else ActionLog.RULES_VERSION
	var b := (DOMAIN_RUN).to_utf8_buffer()
	b.append_array(_key)
	b.append_array(("|%d" % _secret).to_utf8_buffer())
	_s_run = EpochCanon.sha256(b)
	_nonce = EpochCanon.sha256(("axiedice/localnonce/v1|%d" % _secret).to_utf8_buffer()).slice(0, 16).hex_encode()


func start_run(params: Dictionary) -> EpochReply:
	if _started:
		return EpochReply.fail("out_of_order")
	var run_id := "local_" + _s_run.slice(0, 8).hex_encode()
	_chain_begin(run_id)
	_started = true
	var args := {"mode": String(params.get("mode", "short")), "ascension": int(params.get("ascension", 0))}
	var reply := _answer("run_start", args)
	if not reply.ok:
		return reply
	reply.extra["run_id"] = run_id
	reply.extra["client_nonce"] = _nonce
	reply.extra["commit"] = EpochCanon.commit(run_id, _s_run).hex_encode()
	reply.extra["header"] = {"newcomer": false, "loadout": (params.get("loadout", {}) as Dictionary).duplicate(true)}
	(_tape[_tape.size() - 1] as Dictionary)["extra"] = reply.extra.duplicate(true)
	return reply


## Continues a saved Local run: restores the sequence, the hash chain position and the reroll pins
## from the tape that was saved with it.
func resume(p_tape: Array) -> void:
	_tape = p_tape.duplicate(true)
	_started = not _tape.is_empty()
	_seq = _tape.size()
	_pins = {}
	_last_node_seq = 0
	if _tape.is_empty():
		return
	var first: Dictionary = _tape[0]
	_chain_begin(String((first.get("extra", {}) as Dictionary).get("run_id", "")))
	var last: Dictionary = _tape[_tape.size() - 1]
	var lx: Dictionary = last.get("extra", {})
	_prev_h = String(lx.get("h", "")).hex_decode()
	_sent_len = int(lx.get("log_len", 0))
	_first_epoch = false
	for e in _tape:
		var ed: Dictionary = e
		var a: Dictionary = ed.get("args", {})
		if String(ed.get("kind", "")) == "node":
			_last_node_seq = int(ed["seq"])
		elif String(ed.get("kind", "")) == "reroll":
			_pins["%d|%d|%d|%d" % [_last_node_seq, int(a.get("attempt", 0)), int(a.get("turn", 0)), int(a.get("k", 0))]] = int(ed["seed"])


func request(kind: String, args: Dictionary) -> EpochReply:
	if not _started or kind == "run_start":
		return EpochReply.fail("out_of_order")
	return _answer(kind, args)


func _answer(kind: String, args: Dictionary) -> EpochReply:
	var peek := _chain_peek()
	if not bool(peek["ok"]):
		return EpochReply.fail("bad_request", {"error": String(peek["error"])})
	var attempt := int(args.get("attempt", 0))
	var req := {
		"run_id": _run_id, "seq": _seq, "kind": kind, "args": args, "h": String(peek["h"]),
		"log_len": int(peek["log_len"]), "rules_version": _rules_version, "attempt": attempt,
		"client_nonce": _nonce,
	}
	var c := EpochCanon.request(req)
	if not bool(c["ok"]):
		return EpochReply.fail("bad_request", {"error": String(c["error"])})
	var seed_value := EpochCanon.seed_from(_s_run, String(c["canon"]))
	if kind == "reroll":
		# ADR-RNG §4.4: the first request for a (battle, attempt, turn, k) key fixes the seed;
		# asking again after an undo returns the same one.
		var pin := "%d|%d|%d|%d" % [_last_node_seq, attempt, int(args.get("turn", 0)), int(args.get("k", 0))]
		if _pins.has(pin):
			seed_value = int(_pins[pin])
		else:
			_pins[pin] = seed_value
	elif kind == "node":
		_last_node_seq = _seq
	var extra := {"h": String(peek["h"]), "log_len": int(peek["log_len"])}
	_tape.append({"seq": _seq, "kind": kind, "args": args.duplicate(true), "seed": seed_value, "extra": extra.duplicate(true)})
	_chain_commit(peek)
	_seq += 1
	return EpochReply.ok_reply(seed_value, extra)


func tape() -> Array:
	return _tape.duplicate(true)
