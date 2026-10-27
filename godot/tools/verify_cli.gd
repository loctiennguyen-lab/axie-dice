class_name VerifyCli
extends RefCounted
## Phần "não" của CLI verifier (SR-V): nhận chuỗi JSON của một run log, replay, trả kết quả theo
## schema CỐ ĐỊNH. Tách khỏi verify_run.gd để test gọi thẳng trong tiến trình, không cần spawn.
##
## Schema kết quả (đúng 8 khoá, kiểu cố định, chuỗi có trần độ dài):
##   ok: bool · reason: String ("" khi ok, còn lại là mã lỗi của RunVerifier hoặc mã input)
##   rules_version: String · outcome: "won" | "lost" | "rejected" | "invalid"
##   score: int · nodes: int (số enter_node đã replay) · log_len: int · ms: int
## Verifier KHÔNG tin bất cứ thứ gì client khai; thông điệp tự do (message) cố ý KHÔNG nằm trong
## kết quả để kênh ra là hữu hạn và máy móc đọc được.
##
## Dùng: var r := VerifyCli.run(text); r["result"] là Dictionary schema trên, r["code"] là exit code.

const EXIT_OK := 0
const EXIT_REJECTED := 1
const EXIT_INPUT := 2

## Trần (kiểm cứng, đừng nới mà không báo security): input tối đa và số action tối đa.
const MAX_INPUT_BYTES := 8_000_000
const MAX_LOG_LEN := 20_000
const MAX_REASON_LEN := 64
const KEYS := ["ok", "reason", "rules_version", "outcome", "score", "nodes", "log_len", "ms"]


static func run(raw: String) -> Dictionary:
	var t0 := Time.get_ticks_msec()
	if raw.length() > MAX_INPUT_BYTES:
		return _done(_invalid("input_too_large", 0), t0, EXIT_INPUT)
	var jp := JSON.new()   # không dùng JSON.parse_string: nó in ERROR ra log khi input hỏng
	var parsed: Variant = jp.data if jp.parse(raw) == OK else null
	if not (parsed is Dictionary):
		return _done(_invalid("bad_json", 0), t0, EXIT_INPUT)
	var data := parsed as Dictionary
	# Job shape (verifier/JOB_SCHEMA.md): {log, tape, server_header, server_loadout}. A bare log bundle (header/entries/tape at the
	# top level) still works, as before.
	var server_header: Variant = null
	var server_loadout: Variant = null
	if data.get("log") is Dictionary:
		server_header = data.get("server_header", null)
		server_loadout = data.get("server_loadout", null)
		if (server_header != null and not (server_header is Dictionary)) or (server_loadout != null and not (server_loadout is Dictionary)):
			return _done(_invalid("bad_job", 0), t0, EXIT_INPUT)
		var job_tape: Variant = data.get("tape", null)
		data = (data["log"] as Dictionary).duplicate()
		if job_tape != null:
			data["tape"] = job_tape
	var entries: Variant = data.get("entries", [])
	var n := (entries as Array).size() if entries is Array else 0
	if n > MAX_LOG_LEN:
		return _done(_invalid("log_too_long", n), t0, EXIT_INPUT)
	var tape: Variant = data.get("tape", [])
	if not (tape is Array):
		return _done(_invalid("bad_tape", n), t0, EXIT_INPUT)

	var alog := ActionLog.from_data(data)
	var nodes := _count_nodes(entries)
	if server_header is Dictionary:
		if header_diff(server_header as Dictionary, alog.header) != "":
			var rej := {"ok": false, "reason": "header_mismatch", "rules_version": ActionLog.RULES_VERSION,
				"outcome": "rejected", "score": 0, "nodes": nodes, "log_len": n, "ms": 0}
			return _done(rej, t0, EXIT_REJECTED)
	var lo: Dictionary = {}
	if server_loadout is Dictionary:
		lo = merge_loadout(server_loadout as Dictionary, alog.header)
	var verdict := RunVerifier.verify(alog, tape as Array, lo)
	var ok := bool(verdict.get("ok", false))
	var res := {
		"ok": ok,
		"reason": "" if ok else String(verdict.get("error", "unknown")).left(MAX_REASON_LEN),
		"rules_version": ActionLog.RULES_VERSION,
		"outcome": ("won" if bool(verdict.get("won", false)) else "lost") if ok else "rejected",
		"score": int(verdict.get("score", 0)) if ok else 0,
		"nodes": nodes,
		"log_len": n,
		"ms": 0,
	}
	return _done(res, t0, EXIT_OK if ok else EXIT_REJECTED)


## Fields the server's header decides. header_diff returns the first one that differs from the log header, "" if all match.
## A field the server did not send is not compared. Missing log values take the engine defaults.
const HEADER_FIELDS := ["rules_version", "mode", "ascension", "ranked", "depth_stage", "kind", "mission"]


static func header_diff(server: Dictionary, log_header: Dictionary) -> String:
	var lm: Dictionary = {}
	if log_header.get("mission", {}) is Dictionary:
		lm = log_header["mission"] as Dictionary
	var is_ranked := bool(log_header.get("ranked", false))
	var mine := {
		"rules_version": String(log_header.get("rules_version", "")),
		"mode": String(log_header.get("mode", "short")),
		"ascension": int(log_header.get("ascension", 0)),
		"ranked": is_ranked,
		"depth_stage": int(log_header.get("depth_stage", 3)),
		# The log header stores no kind: it is "mission" with a mission header, else "ranked" / "normal".
		"kind": String(log_header.get("kind", "mission" if not lm.is_empty() else ("ranked" if is_ranked else "normal"))),
	}
	for k in HEADER_FIELDS:
		if not server.has(k):
			continue
		var sv: Variant = server[k]
		if k == "mission":
			if not (sv is Dictionary) or not RunVerifier._mission_same(sv as Dictionary, lm):
				return k
		elif k == "ranked":
			if not (sv is bool) or bool(sv) != is_ranked:
				return k
		elif k == "ascension" or k == "depth_stage":
			if not (sv is int or sv is float) or float(sv) != float(int(mine[k])):
				return k
		elif not (sv is String) or String(sv) != String(mine[k]):
			return k
	return ""


## The server's loadout wins outright. Only anchor / rules_on / core_off / boon_id, which the server does not send, are kept from the
## log header. No `bonuses` from the server means zero bonuses, never the verifier's own MetaState (RunState would read that otherwise).
static func merge_loadout(server_loadout: Dictionary, log_header: Dictionary) -> Dictionary:
	var lo: Dictionary = server_loadout.duplicate(true)
	var hl: Dictionary = {}
	if log_header.get("loadout", {}) is Dictionary:
		hl = log_header["loadout"] as Dictionary
	for k in ["anchor", "rules_on", "core_off", "boon_id"]:
		if not lo.has(k) and hl.has(k):
			lo[k] = hl[k]
	if not lo.has("bonuses"):
		lo["bonuses"] = {}
	return lo


static func _count_nodes(entries: Variant) -> int:
	var nodes := 0
	for e in (entries as Array if entries is Array else []):
		if e is Dictionary and String((e as Dictionary).get("fn", "")) == "enter_node":
			nodes += 1
	return nodes


static func _invalid(reason: String, n: int) -> Dictionary:
	return {"ok": false, "reason": reason, "rules_version": ActionLog.RULES_VERSION,
		"outcome": "invalid", "score": 0, "nodes": 0, "log_len": n, "ms": 0}


static func _done(res: Dictionary, t0: int, code: int) -> Dictionary:
	res["ms"] = Time.get_ticks_msec() - t0
	return {"result": res, "code": code}


## Kiểm schema: đúng 8 khoá, đúng kiểu, trong trần. Trả "" nếu hợp lệ, ngược lại mô tả lỗi.
static func check_schema(res: Dictionary) -> String:
	if res.size() != KEYS.size():
		return "key count %d" % res.size()
	for k in KEYS:
		if not res.has(k):
			return "missing " + k
	if typeof(res["ok"]) != TYPE_BOOL: return "ok type"
	if typeof(res["reason"]) != TYPE_STRING or String(res["reason"]).length() > MAX_REASON_LEN: return "reason"
	if typeof(res["rules_version"]) != TYPE_STRING: return "rules_version type"
	if not ["won", "lost", "rejected", "invalid"].has(String(res["outcome"])): return "outcome"
	for k in ["score", "nodes", "log_len", "ms"]:
		# Đọc lại từ JSON thì số nguyên thành float; chấp nhận nếu nguyên.
		var v: Variant = res[k]
		var is_int: bool = typeof(v) == TYPE_INT or (typeof(v) == TYPE_FLOAT and floorf(float(v)) == float(v))
		if not is_int or int(v) < 0: return k + " type/neg"
	return ""
