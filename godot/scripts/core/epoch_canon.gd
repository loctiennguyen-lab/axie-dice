class_name EpochCanon
extends RefCounted
## Canonical byte form, hash chain and seed formula of the epoch protocol.
##
## Spec: docs/architecture/server-authoritative-rng.md §4.1 (ADR-RNG), L1 contract 1
## (production/l1-interfaces.md §1.1-1.5). Pure static functions, no state, no RNG.
##
## The Worker (lane S) implements the same thing in JS and the two sides are held together by ONE
## file of golden vectors, `res://tests/data/epoch_golden.json` (its `spec` array is the exact
## wording of every rule). Change a rule here => regenerate that file and tell lane S. Do not
## "fix" a function without a vector that proves the change.
##
## Where this file makes a choice the ADR left open (all recorded in the golden file's `spec`):
##  - The in-game ActionLog is POSITIONAL (`{fn, args:[...]}`), so a log line is
##    `fn|p0=v0|p1=v1...` with parameters named by position.
##  - Strings may also contain '-' (the ADR set was [a-z0-9_] but `rules_version` has hyphens).
##  - bool / float / null / empty string / nested arrays are not canonicalisable: they return an
##    error instead of being coerced, so a client can never send something the server rejects.
##  - Whole-number floats are accepted as ints because JSON.parse_string turns every number into
##    a float on the way back in; 1.5 is still refused.

const DOMAIN_LOG := "axiedice/log/v1"
const DOMAIN_COMMIT := "axiedice/commit/v1"
const MAX_POSITIONAL := 10


# ---------------------------------------------------------------------------
# Values
# ---------------------------------------------------------------------------

## True for a non-empty ASCII string made only of [a-z0-9_-].
static func is_canon_string(s: String) -> bool:
	if s.is_empty():
		return false
	for i in s.length():
		var c := s.unicode_at(i)
		var ok := (c >= 97 and c <= 122) or (c >= 48 and c <= 57) or c == 95 or c == 45
		if not ok:
			return false
	return true


## One scalar or flat array -> its canonical text, or null when it cannot be canonicalised.
static func value_text(v: Variant) -> Variant:
	match typeof(v):
		TYPE_INT:
			return str(int(v))
		TYPE_FLOAT:
			var f: float = v
			if f == floor(f) and absf(f) < 9.0e15:
				return str(int(f))
			return null
		TYPE_STRING, TYPE_STRING_NAME:
			var s := String(v)
			return s if is_canon_string(s) else null
		TYPE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY:
			var parts: PackedStringArray = []
			for x in (v as Array if typeof(v) == TYPE_ARRAY else Array(v)):
				var t = x
				if typeof(t) == TYPE_ARRAY or typeof(t) == TYPE_DICTIONARY:
					return null
				var xt: Variant = value_text(t)
				if xt == null:
					return null
				parts.append(String(xt))
			return ",".join(parts)
	return null


## Row of a node id `r<row>_c<col>` (row >= 1, col >= 0, no leading zeros), or -1 when the id does
## not have that shape. The DO uses the row to refuse row-skipping (ADR-RNG §4.2, M7).
static func node_row(node_id: String) -> int:
	var re := RegEx.new()
	re.compile("^r([1-9][0-9]*)_c(0|[1-9][0-9]*)$")
	var m := re.search(node_id)
	return -1 if m == null else int(m.get_string(1))


# ---------------------------------------------------------------------------
# Log lines and deltas
# ---------------------------------------------------------------------------

## `fn|p0=v0|p1=v1\n`. Returns {ok, canon, error}.
static func action_line(fn: String, args: Array) -> Dictionary:
	if fn.is_empty() or not _is_fn_name(fn):
		return _err("bad action name '%s'" % fn)
	if args.size() > MAX_POSITIONAL:
		return _err("action '%s' has %d parameters (max %d)" % [fn, args.size(), MAX_POSITIONAL])
	var s := fn
	for i in args.size():
		var t: Variant = value_text(args[i])
		if t == null:
			return _err("action '%s' parameter %d cannot be canonicalised" % [fn, i])
		s += "|p%d=%s" % [i, String(t)]
	return {"ok": true, "canon": s + "\n", "error": ""}


## Lines concatenated in the order they happened. `entries` = ActionLog.entries-shaped
## ({fn, args}). Empty list -> empty string.
static func delta(entries: Array) -> Dictionary:
	var out := ""
	for e in entries:
		var r := action_line(String((e as Dictionary).get("fn", "")),
			(e as Dictionary).get("args", []) as Array)
		if not bool(r["ok"]):
			return r
		out += String(r["canon"])
	return {"ok": true, "canon": out, "error": ""}


static func _is_fn_name(fn: String) -> bool:
	for i in fn.length():
		var c := fn.unicode_at(i)
		if not ((c >= 97 and c <= 122) or c == 95):
			return false
	return true


# ---------------------------------------------------------------------------
# Epoch request
# ---------------------------------------------------------------------------

## Canon of one epoch request: nested dictionaries flattened with a `parent.` prefix, lines
## `key=value\n` sorted by key. Returns {ok, canon, error}.
## `args.uids` is left OUT unless `include_uids` (ADR-RNG §4.4: the uid list is a commitment recorded
## in the ledger, not seed input). Tape comparison passes true to compare the whole request.
static func request(req: Dictionary, include_uids: bool = false) -> Dictionary:
	var lines: Array = []
	var err := _flatten("", req, lines)
	if err != "":
		return _err(err)
	if not include_uids:
		lines = lines.filter(func(kv): return String(kv[0]) != "args.uids")
	lines.sort_custom(func(a, b): return String(a[0]) < String(b[0]))
	var s := ""
	for kv in lines:
		s += "%s=%s\n" % [kv[0], kv[1]]
	return {"ok": true, "canon": s, "error": ""}


static func _flatten(prefix: String, d: Dictionary, out: Array) -> String:
	for k in d.keys():
		var key := String(k)
		if key.is_empty() or key.contains("-") or not is_canon_string(key):
			return "bad key '%s'" % key
		var v: Variant = d[k]
		if typeof(v) == TYPE_DICTIONARY:
			var e := _flatten(prefix + key + ".", v as Dictionary, out)
			if e != "":
				return e
			continue
		var t: Variant = value_text(v)
		if t == null:
			return "value of '%s%s' cannot be canonicalised" % [prefix, key]
		out.append([prefix + key, String(t)])
	return ""


# ---------------------------------------------------------------------------
# Hashes
# ---------------------------------------------------------------------------

static func sha256(data: PackedByteArray) -> PackedByteArray:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	return ctx.finish()


## h_0 = SHA256("axiedice/log/v1" || run_id)
static func h0(run_id: String) -> PackedByteArray:
	return sha256((DOMAIN_LOG + run_id).to_utf8_buffer())


## h_n = SHA256("axiedice/log/v1" || h_{n-1} || canon(delta_n)); `prev` is the 32 raw bytes.
static func chain_step(prev: PackedByteArray, delta_canon: String) -> PackedByteArray:
	var b := DOMAIN_LOG.to_utf8_buffer()
	b.append_array(prev)
	b.append_array(delta_canon.to_utf8_buffer())
	return sha256(b)


## commit = SHA256("axiedice/commit/v1" || run_id || S_run)
static func commit(run_id: String, s_run: PackedByteArray) -> PackedByteArray:
	var b := (DOMAIN_COMMIT + run_id).to_utf8_buffer()
	b.append_array(s_run)
	return sha256(b)


## seed = first 4 bytes of HMAC-SHA256(S_run, canon), big-endian, unsigned 32-bit.
static func seed_from(s_run: PackedByteArray, canon_text: String) -> int:
	var mac := Crypto.new().hmac_digest(HashingContext.HASH_SHA256, s_run, canon_text.to_utf8_buffer())
	return (int(mac[0]) << 24) | (int(mac[1]) << 16) | (int(mac[2]) << 8) | int(mac[3])


## Digest that decides the node types of one row (M7): HMAC-SHA256(S_run,
## "axiedice/rowtype/v1" 0x7C run_id 0x7C row-as-4-byte-big-endian).
static func rowtype_digest(s_run: PackedByteArray, run_id: String, row: int) -> PackedByteArray:
	var msg := ("axiedice/rowtype/v1|" + run_id + "|").to_utf8_buffer()
	msg.append((row >> 24) & 0xFF)
	msg.append((row >> 16) & 0xFF)
	msg.append((row >> 8) & 0xFF)
	msg.append(row & 0xFF)
	return Crypto.new().hmac_digest(HashingContext.HASH_SHA256, s_run, msg)


static func _err(msg: String) -> Dictionary:
	return {"ok": false, "canon": "", "error": msg}
