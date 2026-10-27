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
	# Job payload (schema 1, verifier/JOB_SCHEMA.md): header from server_header + client_header, entries, tape. A bare log bundle
	# (header/entries/tape at the top level) still works, as before.
	var is_job: bool = data.has("server_header")
	var job_loadout: Dictionary = {}
	var job_error := ""
	if is_job:
		if not (data["server_header"] is Dictionary) or int(data.get("schema", 0)) != 1 or not (data.get("entries", []) is Array):
			return _done(_invalid("bad_job", 0), t0, EXIT_INPUT)
		var built := build_from_job(data)
		var job_tape: Variant = data.get("tape", [])
		job_error = String(built["error"])
		job_loadout = built["loadout"]
		data = (built["data"] as Dictionary).duplicate()
		data["tape"] = job_tape
		if job_error != "":
			data["entries"] = (parsed as Dictionary).get("entries", [])
	var entries: Variant = data.get("entries", [])
	var n := (entries as Array).size() if entries is Array else 0
	if n > MAX_LOG_LEN:
		return _done(_invalid("log_too_long", n), t0, EXIT_INPUT)
	var tape: Variant = data.get("tape", [])
	if not (tape is Array):
		return _done(_invalid("bad_tape", n), t0, EXIT_INPUT)

	var alog := ActionLog.from_data(data)
	var nodes := _count_nodes(entries)
	if job_error != "":
		var rej := {"ok": false, "reason": job_error, "rules_version": ActionLog.RULES_VERSION,
			"outcome": "rejected", "score": 0, "nodes": nodes, "log_len": n, "ms": 0}
		return _done(rej, t0, EXIT_REJECTED)
	var verdict := RunVerifier.verify(alog, tape as Array, job_loadout)
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


## Job payload (schema 1, see verifier/JOB_SCHEMA.md) -> {"data": {header, entries}, "loadout": Dictionary, "error": String}.
## The server's header wins on every field it owns (rules_version, mode, ascension, ranked, depth_stage, mission, newcomer).
## team_keys / content_version / local_secret come from client_header (the server cannot know them). The loadout is the server's
## bonuses plus client_header.loadout (anchor, rules_on, core_off, boon_id) with server_loadout.forced on top; the client never
## supplies bonuses. `error` is "header_mismatch" or "bad_header" when the job cannot be replayed.
static func build_from_job(job: Dictionary) -> Dictionary:
	var sh: Dictionary = job["server_header"] as Dictionary
	var ch: Dictionary = job.get("client_header", {}) as Dictionary if job.get("client_header", {}) is Dictionary else {}
	var sl: Dictionary = job.get("server_loadout", {}) as Dictionary if job.get("server_loadout", {}) is Dictionary else {}
	var out := {"data": {}, "loadout": {}, "error": ""}
	var mission: Dictionary = sh.get("mission", {}) as Dictionary if sh.get("mission", null) is Dictionary else {}
	var kind := String(sh.get("kind", ""))
	# kind "mission" <=> a mission header; a ranked kind agrees with the ranked flag. Anything else the server says is inconsistent.
	if bool(sh.get("header_mismatch", false)) or (kind == "mission") != (not mission.is_empty()) \
			or (kind == "ranked") != bool(sh.get("ranked", false)):
		out["error"] = "header_mismatch"
		return out
	var team: Variant = ch.get("team_keys", null)
	if not (team is Array) or (team as Array).is_empty() or String(ch.get("content_version", "")) == "":
		out["error"] = "bad_header"
		return out
	var lo: Dictionary = {}
	var bonuses: Dictionary = sl.get("bonuses", {}) as Dictionary if sl.get("bonuses", {}) is Dictionary else {}
	lo["bonuses"] = bonuses.duplicate(true)
	var cl: Dictionary = ch.get("loadout", {}) as Dictionary if ch.get("loadout", {}) is Dictionary else {}
	# Client claims: coerced to plain bool / short String, nothing else is read.
	for k in ["anchor", "rules_on", "core_off"]:
		if cl.has(k):
			lo[k] = _as_bool(cl[k])
	if cl.has("boon_id"):
		lo["boon_id"] = String(cl["boon_id"]).left(40) if (cl["boon_id"] is String) else ""
	var forced: Dictionary = sl.get("forced", {}) as Dictionary if sl.get("forced", {}) is Dictionary else {}
	for k in forced:
		lo[k] = forced[k]
	var header := {
		"team_keys": (team as Array).duplicate(), "content_version": String(ch.get("content_version", "")),
		"local_secret": int(ch.get("local_secret", 0)),
		"rules_version": String(sh.get("rules_version", "")), "mode": String(sh.get("mode", "short")),
		"ascension": int(sh.get("ascension", 0)), "ranked": bool(sh.get("ranked", false)),
		"depth_stage": int(sh.get("depth_stage", 3)), "newcomer": bool(sh.get("newcomer", false)),
		"mission": mission.duplicate(true), "loadout": lo.duplicate(true),
	}
	out["data"] = {"header": header, "entries": job.get("entries", [])}
	out["loadout"] = lo
	return out



static func _as_bool(v: Variant) -> bool:
	if v is bool:
		return v
	if v is int or v is float:
		return float(v) != 0.0
	return false


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
