class_name EpochReply
extends RefCounted
## Answer to one EpochSource call (L1 contract 1, production/l1-interfaces.md §1.2).
## Local/Tape sources return it already `done`; a remote source emits `resolved` later.

signal resolved

var done: bool = false
var ok: bool = false
## 32-bit seed: first 4 bytes of the HMAC, big-endian (ADR-RNG §4.1).
var seed: int = 0
## "" | bad_request | out_of_order | rejected | expired | version | offline | timeout | busy
var code: String = ""
## Data riding with the kind: row_types, run_id, commit, h, log_len, ...
var extra: Dictionary = {}


static func ok_reply(p_seed: int, p_extra: Dictionary = {}) -> EpochReply:
	var r := EpochReply.new()
	r.done = true
	r.ok = true
	r.seed = p_seed
	r.extra = p_extra
	return r


static func fail(p_code: String, p_extra: Dictionary = {}) -> EpochReply:
	var r := EpochReply.new()
	r.done = true
	r.ok = false
	r.code = p_code
	r.extra = p_extra
	return r


## For remote sources: settle later and wake whoever is awaiting `resolved`.
func settle(p_ok: bool, p_seed: int, p_code: String = "", p_extra: Dictionary = {}) -> void:
	ok = p_ok
	seed = p_seed
	code = p_code
	extra = p_extra
	done = true
	resolved.emit()
