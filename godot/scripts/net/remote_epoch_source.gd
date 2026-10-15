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
## Tests: replaces the local-save lookup. Returns the run_id of the saved run that can be resumed, or "".
var local_run_id: Callable = Callable()
## Set by resume(): this source was rebuilt from a save, so the session is NOT attached to the run yet.
var _resumed := false
var _attached := true
var _reconnecting := false
var _waiters: Array = []   # EpochReply of reconnect() callers waiting for the answer


func _init(p_session: RunSession = null, rules_version: String = "") -> void:
	session = p_session
	_rules_version = rules_version if rules_version != "" else ActionLog.RULES_VERSION


## Project setting `axie/epoch_source`; "local" (default) keeps LocalEpochSource. RunState.begin_run picks
## `RemoteEpochSource.new(RunSession)` only when this returns true (lane I wires it; see report).
static func flag_on() -> bool:
	return String(ProjectSettings.get_setting("axie/epoch_source", "local")) == "remote"


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
	if params.has("team_keys"):
		body["team_keys"] = params["team_keys"]   # Ranked: the server refuses imported (vault) Axies
	if params.has("mission_offer_id"):
		body["mission_offer_id"] = params["mission_offer_id"]
	_create(params, body, nonce, reply, false)
	return reply


## POST /api/run. The server allows ONE open run per player, so a stale run (an earlier attempt that died
## before the first battle, or a run another device left behind) answers 409 run_open on every Begin.
## `recovered` makes sure we abandon at most once and retry the create at most once: never a loop.
func _create(params: Dictionary, body: Dictionary, nonce: String, reply: EpochReply, recovered: bool) -> void:
	session.create_run(body, func(ok: bool, data: Dictionary) -> void:
		if not ok:
			var code := String(data.get("code", "server"))
			if code == "run_open" and not recovered:
				_recover_open_run(func(res: String) -> void:
					if res == "retry":
						_create(params, body, nonce, reply, true)
					else:
						_started = false
						reply.settle(false, 0, res))
				return
			_started = false
			reply.settle(false, 0, _map_http_code(code))
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
			reply.settle(true, inner.seed, "", extra)))


## Asks the server which run holds the slot. done(result): "retry" = the slot is free now (try the create
## once more); anything else is the final EpochReply code:
##   "run_in_progress"  a local save that can resume that very run exists: do NOT abandon it (UI offers Continue)
##   "run_open"         the stale run could not be abandoned
##   other              open_existing failed (offline, unauthenticated, ...)
func _recover_open_run(done: Callable) -> void:
	session.open_existing(func(ok: bool, d: Dictionary) -> void:
		if not ok:
			done.call(_map_http_code(String(d.get("code", "server"))))
			return
		var open_id := String(d.get("run_id", ""))
		if open_id == "":
			done.call("retry")   # the slot was freed between the two calls
			return
		var local_id: String = local_run_id.call() if local_run_id.is_valid() else _saved_resumable_run_id()
		if local_id != "" and local_id == open_id:
			session.release()
			done.call("run_in_progress")
			return
		session.abandon(func(abandoned: bool) -> void:
			if abandoned:
				done.call("retry")
			else:
				session.release()
				done.call("run_open")))


## Local save that can resume a run: its run_id, or "" (no save, not resumable under this RULES_VERSION,
## or a save from before server-rolled dice). Reads through RunState/SaveStore, never the file directly.
static func _saved_resumable_run_id() -> String:
	if not bool(RunState.saved_run_status()["resumable"]):
		return ""
	var parsed: Variant = JSON.parse_string(SaveStore.read_text(RunState.SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	var run: Variant = (parsed as Dictionary).get("run", {})
	return String((run as Dictionary).get("run_id", "")) if typeof(run) == TYPE_DICTIONARY else ""


func request(kind: String, args: Dictionary) -> EpochReply:
	return _gated(func() -> EpochReply: return _request_now(kind, args))


func _request_now(kind: String, args: Dictionary) -> EpochReply:
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
	return _gated(func() -> EpochReply: return _aid_now(aid_id, args))


func _aid_now(aid_id: String, args: Dictionary) -> EpochReply:
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
	return _gated(func() -> EpochReply: return _close_now(outcome, summary))


func _close_now(outcome: String, summary: Dictionary) -> EpochReply:
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
	_resumed = true
	_attached = false


## True when a source rebuilt from a save has not (or no longer has) a live session on its run.
func needs_reconnect() -> bool:
	if not _resumed or _closed:
		return false
	return not _attached or session.state == "idle" or session.state == "closed" or session.run_id != _run_id


## Runs `op` (which builds the real request) once the session is attached to the saved run. A request made while
## the reconnect is still going waits for it instead of failing; if the reconnect fails, the request fails with
## the reconnect's code (offline, unauthenticated, run_gone) and the next try reconnects again.
func _gated(op: Callable) -> EpochReply:
	if not needs_reconnect():
		return op.call()
	var reply := EpochReply.new()
	var rc := reconnect()
	_when_done(rc, func() -> void:
		if not rc.ok:
			reply.settle(false, 0, rc.code)
			return
		var inner: EpochReply = op.call()
		_when_done(inner, func() -> void:
			reply.settle(inner.ok, inner.seed, inner.code, inner.extra)))
	return reply


## Reconnects the session to the saved run: GET /api/run/open, the run_id must be the saved one, then attach()
## (the socket's hello{last_seq} fetches whatever the server did after our last save). Concurrent callers share
## one attempt. Settles ok, or:
##   run_gone   the server has no open run, or another one: this save cannot continue online (caller discards it)
##   offline / unauthenticated / ...   open_existing failed: nothing changed, try again later
func reconnect() -> EpochReply:
	var reply := EpochReply.new()
	if not needs_reconnect():
		reply.settle(true, 0)
		return reply
	_attached = false
	_waiters.append(reply)
	if _reconnecting:
		return reply
	_reconnecting = true
	var saved_id := _run_id
	session.open_existing(func(ok: bool, d: Dictionary) -> void:
		var code := ""
		if not ok:
			code = _map_http_code(String(d.get("code", "server")))
		else:
			var open_id := String(d.get("run_id", ""))
			if open_id == "":
				code = "run_gone"
			elif open_id != saved_id:
				session.release()   # open_existing attached us to a run we do not own here: let it go
				code = "run_gone"
			else:
				session.note_acked(_seq - 1)
				_attached = true
		_reconnecting = false
		var waiting := _waiters
		_waiters = []
		for w in waiting:
			(w as EpochReply).settle(code == "", 0, code))
	return reply


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
		# Each of these has its own message in RunSetup; a generic "rejected" told the player nothing.
		"run_open", "daily_cap", "daily_tries", "not_available", "newcomer_locked", "vault_banned", \
		"unauthenticated", "forbidden", "rate_limited":
			return c
	return "rejected"


func _when_done(r: EpochReply, cb: Callable) -> void:
	if r.done:
		cb.call()
	else:
		r.resolved.connect(cb, CONNECT_ONE_SHOT)


static func _random_hex(n: int) -> String:
	return Crypto.new().generate_random_bytes(n).hex_encode()
