class_name RemoteEpochSource
extends EpochSource
## EpochSource whose seeds come from the server (L1 contract 1, ADR-RNG 4.6). Behind the project
## setting `axie/epoch_source` = "remote"; the default stays "local" until lane I flips it.
##
## All hash-chain bookkeeping is the base class's (`_chain_peek` / `_chain_commit`), so this file only
## builds the wire messages and hands them to RunSession. A failed request does NOT advance the chain
## or the seq: the caller may ask again and the server answers a repeated seq with the same seed.
##
## Usage (from RunState): `var r := epoch.request(kind, args); if not r.done: await r.resolved`.

var session: RunSession
var _seq := 0
var _tape: Array = []
var _rules_version := ""
var _started := false
var _closed := false


func _init(p_session: RunSession = null, rules_version: String = "") -> void:
	session = p_session
	_rules_version = rules_version if rules_version != "" else ActionLog.RULES_VERSION


func is_remote() -> bool:
	return true


## params = RunParams (contract 3.6): mode short|full, ascension, kind, loadout, mission_offer_id.
func start_run(params: Dictionary) -> EpochReply:
	if _started:
		return EpochReply.fail("out_of_order")
	_started = true
	var reply := EpochReply.new()
	var nonce := _random_hex(16)
	var body := {
		"rules_version": _rules_version, "kind": String(params.get("kind", "normal")),
		"ascension": int(params.get("ascension", 0)), "client_nonce": nonce,
	}
	if params.has("mission_offer_id"):
		body["mission_offer_id"] = params["mission_offer_id"]
	session.create_run(body, func(ok: bool, data: Dictionary) -> void:
		if not ok:
			_started = false
			reply.settle(false, 0, _map_http_code(String(data.get("code", "server"))))
			return
		_chain_begin(String(data["run_id"]))
		var args := {"mode": String(params.get("mode", "short")), "ascension": int(params.get("ascension", 0))}
		var peek := _chain_peek()
		var msg := {"t": "epoch_req", "seq": _seq, "kind": "run_start", "args": args, "log_delta": [],
			"h": String(peek["h"]), "log_len": 0}
		var inner := EpochReply.new()
		session.submit(msg, inner)
		_when_done(inner, func() -> void:
			if not inner.ok:
				_started = false
				reply.settle(false, 0, inner.code)
				return
			_chain_commit(peek)
			var header: Dictionary = (data.get("header", {}) as Dictionary).duplicate(true)
			header["loadout"] = (params.get("loadout", {}) as Dictionary).duplicate(true)
			var extra := {"run_id": String(data["run_id"]), "client_nonce": nonce,
				"commit": String(data.get("commit", "")), "header": header,
				"h": String(peek["h"]), "log_len": 0}
			_record("run_start", args, inner.seed, extra)
			reply.settle(true, inner.seed, "", extra))
	return reply


func request(kind: String, args: Dictionary) -> EpochReply:
	if not _started or kind == "run_start" or _closed:
		return EpochReply.fail("out_of_order")
	var peek := _chain_peek()
	if not bool(peek["ok"]):
		return EpochReply.fail("bad_request", {"error": String(peek["error"])})
	var reply := EpochReply.new()
	var msg := {"t": "epoch_req", "seq": _seq, "kind": kind, "args": args,
		"log_delta": _delta_entries(int(peek["log_len"])), "h": String(peek["h"]), "log_len": int(peek["log_len"])}
	var inner := EpochReply.new()
	session.submit(msg, inner)
	_when_done(inner, func() -> void:
		if not inner.ok:
			reply.settle(false, 0, inner.code)
			return
		_chain_commit(peek)
		var extra := inner.extra.duplicate(true)
		extra["h"] = String(peek["h"])
		extra["log_len"] = int(peek["log_len"])
		if extra.has("row_types"):
			extra["row_types"] = _rows_to_ints(extra["row_types"])
		_record(kind, args, inner.seed, extra)
		reply.settle(true, inner.seed, "", extra))
	return reply


## Aid that draws nothing (R4 Hoan dong ho, R7 Scout). The server appends the `aid_use` line to the
## chain itself and returns the new h / log_len; the CALLER must record `aid_use` in its ActionLog
## right after, so the next request's delta (which starts at the server's position) matches.
func aid(aid_id: String, args: Dictionary) -> EpochReply:
	if not _started or _closed:
		return EpochReply.fail("out_of_order")
	var peek := _chain_peek()
	if not bool(peek["ok"]):
		return EpochReply.fail("bad_request", {"error": String(peek["error"])})
	var reply := EpochReply.new()
	var msg := {"t": "aid_req", "seq": _seq, "aid": aid_id, "args": args,
		"log_delta": _delta_entries(int(peek["log_len"])), "h": String(peek["h"]), "log_len": int(peek["log_len"])}
	var inner := EpochReply.new()
	session.submit(msg, inner)
	_when_done(inner, func() -> void:
		if not inner.ok:
			reply.settle(false, 0, inner.code)
			return
		var h_hex := String(inner.extra.get("h", ""))
		_prev_h = h_hex.hex_decode()
		_sent_len = int(inner.extra.get("log_len", 0))
		_first_epoch = false
		var extra := inner.extra.duplicate(true)
		if extra.has("row_types"):
			extra["row_types"] = _rows_to_ints(extra["row_types"])
		_record("aid", {"aid": aid_id, "args": args}, 0, extra)
		reply.settle(true, 0, "", extra))
	return reply


func close(outcome: String, summary: Dictionary) -> EpochReply:
	if not _started or _closed:
		return EpochReply.fail("out_of_order")
	var peek := _chain_peek()
	if not bool(peek["ok"]):
		return EpochReply.fail("bad_request", {"error": String(peek["error"])})
	var reply := EpochReply.new()
	var msg := {"t": "run_close", "seq": _seq, "log_delta": _delta_entries(int(peek["log_len"])),
		"h": String(peek["h"]), "log_len": int(peek["log_len"]), "outcome": outcome, "summary": summary}
	var inner := EpochReply.new()
	session.submit(msg, inner)
	_when_done(inner, func() -> void:
		if inner.ok:
			_closed = true
			_chain_commit(peek)
			_seq += 1
		reply.settle(inner.ok, 0, inner.code))
	return reply


func tape() -> Array:
	return _tape.duplicate(true)


## Continue a saved run after an app restart: restores seq and chain position from the tape, then
## RunSession.open_existing()/attach() reconnects and `hello{last_seq}` fetches whatever was missed.
func resume(p_tape: Array, p_session: RunSession) -> void:
	session = p_session
	_tape = p_tape.duplicate(true)
	_started = not _tape.is_empty()
	_seq = _tape.size()
	if _tape.is_empty():
		return
	var first_extra: Dictionary = (_tape[0] as Dictionary).get("extra", {})
	_chain_begin(String(first_extra.get("run_id", "")))
	var lx: Dictionary = (_tape[_tape.size() - 1] as Dictionary).get("extra", {})
	_prev_h = String(lx.get("h", "")).hex_decode()
	_sent_len = int(lx.get("log_len", 0))
	_first_epoch = false


# ---------------------------------------------------------------------------

func _record(kind: String, args: Dictionary, seed_value: int, extra: Dictionary) -> void:
	_tape.append({"seq": _seq, "kind": kind, "args": args.duplicate(true), "seed": seed_value, "extra": extra.duplicate(true)})
	_seq += 1


func _delta_entries(upto: int) -> Array:
	if _log == null or upto <= _sent_len:
		return []
	return _log.entries.slice(_sent_len, upto)


## JSON object keys are strings; the engine wants {row:int -> Array}.
static func _rows_to_ints(rows: Variant) -> Dictionary:
	var out := {}
	if typeof(rows) == TYPE_DICTIONARY:
		for k in (rows as Dictionary).keys():
			out[int(k)] = (rows as Dictionary)[k]
	return out


## POST /api/run error -> EpochReply code.
func _map_http_code(c: String) -> String:
	match c:
		"offline", "server":
			return "offline"
		"version":
			return "version"
		"bad_request":
			return "bad_request"
	return "rejected"   # run_open, daily_cap, not_available, unauthenticated, ...


func _when_done(r: EpochReply, cb: Callable) -> void:
	if r.done:
		cb.call()
	else:
		r.resolved.connect(cb, CONNECT_ONE_SHOT)


static func _random_hex(n: int) -> String:
	return Crypto.new().generate_random_bytes(n).hex_encode()
