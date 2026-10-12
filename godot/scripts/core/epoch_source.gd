class_name EpochSource
extends RefCounted
## Where every gameplay random draw's seed comes from (L1 contract 1, ADR-RNG §4.5).
## Base class: subclasses are LocalEpochSource, TapeEpochSource (scripts/core) and
## RemoteEpochSource (scripts/net, lane S). The rules never call Rng.new on their own;
## they ask here, once per "epoch" boundary (run_start, node, end_turn, reroll, ...).
##
## Callers: `var r := epoch.request(kind, args); if not r.done: await r.resolved`.
## Engine code (scripts/core) never awaits; only RunState wrappers and UI do.

## The log whose delta is hashed into each request. RunState binds it after the run opens.
var _log: ActionLog = null


func bind_log(l: ActionLog) -> void:
	_log = l


# --- hash chain shared by Local and Tape (the Remote DO recomputes the same thing) -------
var _run_id: String = ""
var _prev_h: PackedByteArray = PackedByteArray()
var _sent_len: int = 0
var _first_epoch: bool = true   # run_start carries h_0 itself, with no chain step (golden vectors)


func _chain_begin(run_id: String) -> void:
	_run_id = run_id
	_prev_h = EpochCanon.h0(run_id)
	_sent_len = 0
	_first_epoch = true


## What the NEXT request would carry: {ok, h (hex), h_raw, log_len, error}. Does not advance.
func _chain_peek() -> Dictionary:
	if _first_epoch:
		return {"ok": true, "h_raw": _prev_h, "h": _prev_h.hex_encode(), "log_len": 0, "error": ""}
	var entries: Array = []
	var n := 0
	if _log != null:
		n = _log.entries.size()
		entries = _log.entries.slice(_sent_len, n)
	var d := EpochCanon.delta(entries)
	if not bool(d["ok"]):
		return {"ok": false, "error": String(d["error"])}
	var h_raw := EpochCanon.chain_step(_prev_h, String(d["canon"]))
	return {"ok": true, "h_raw": h_raw, "h": h_raw.hex_encode(), "log_len": n, "error": ""}


func _chain_commit(peek: Dictionary) -> void:
	_prev_h = peek["h_raw"]
	_sent_len = int(peek["log_len"])
	_first_epoch = false


## Opens a run. params = RunParams (contract 3.6). The reply is the `run_start` epoch:
## seed + extra {run_id, commit, header:{newcomer, mission?, loadout}}.
func start_run(_params: Dictionary) -> EpochReply:
	return EpochReply.fail("bad_request")


## Seed for one boundary. kind/args: ADR-RNG §4.2.
func request(_kind: String, _args: Dictionary) -> EpochReply:
	return EpochReply.fail("bad_request")


## Aid actions that draw nothing (R4, R7). Local/Tape answer ok immediately.
func aid(_aid_id: String, _args: Dictionary) -> EpochReply:
	return EpochReply.ok_reply(0, {})


## Closes the run. outcome: "won" | "lost".
func close(_outcome: String, _summary: Dictionary) -> EpochReply:
	return EpochReply.ok_reply(0, {})


## Every epoch answered so far: [{seq, kind, args, seed, extra}]. JSON-safe.
func tape() -> Array:
	return []


func is_remote() -> bool:
	return false
