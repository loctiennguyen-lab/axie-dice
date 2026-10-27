extends Node
## SR-V: CLI verifier. Log hợp lệ -> ok + score khớp; log bị sửa / thiếu / hỏng -> từ chối với mã
## rõ; kết quả luôn đúng schema cố định (VerifyCli.check_schema); trần input được giữ; và một lần
## chạy thật qua tiến trình con (đúng lệnh `Godot --headless ... verify_run.tscn -- --in --out`).
## Không mạng. Log mẫu: RunBot.play_run (cùng nguồn t_replay).

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0

const SEED := 991237
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _ready() -> void:
	_guard.capture()
	print("=== t_verify_cli: start ===")
	await get_tree().process_frame
	var played := RunBot.play_run(SEED, TEAM)
	var bundle: Dictionary = (played["log"] as ActionLog).to_data()
	bundle["tape"] = played["tape"]
	var good := JSON.stringify(bundle)

	# 1. hợp lệ
	var r := VerifyCli.run(good)
	_schema(r, "honest")
	_check(int(r["code"]) == 0 and bool(r["result"]["ok"]), "honest run verified: %s" % str(r["result"]))
	_check(int(r["result"]["score"]) == int(played["score"]), "score matches the played run")
	_check(String(r["result"]["outcome"]) == ("won" if bool(played["won"]) else "lost"), "outcome matches")
	_check(int(r["result"]["nodes"]) > 0 and int(r["result"]["log_len"]) > 10, "nodes/log_len filled")
	var honest_score := int(r["result"]["score"])

	# 2. tamper: đổi lựa chọn phần thưởng -> không được vừa ok vừa cùng điểm
	var t: Dictionary = JSON.parse_string(good)
	var bumped := false
	for e in (t["entries"] as Array):
		if String(e.get("fn", "")) == "take_reward":
			e["args"] = [int((e["args"] as Array)[0]) + 1]
			bumped = true
			break
	_check(bumped, "log has a take_reward to tamper with")
	r = VerifyCli.run(JSON.stringify(t))
	_schema(r, "tampered")
	_check(not bool(r["result"]["ok"]) or int(r["result"]["score"]) != honest_score, "tampered reward changes the verdict")
	if not bool(r["result"]["ok"]):
		_check(int(r["code"]) == 1 and String(r["result"]["outcome"]) == "rejected", "rejected -> exit 1")

	# 3. tamper: cắt đuôi log (bỏ action cuối) và chèn action lạ
	t = JSON.parse_string(good)
	(t["entries"] as Array).append({"fn": "hack_gold", "args": [999]})
	r = VerifyCli.run(JSON.stringify(t))
	_schema(r, "unknown action")
	_check(not bool(r["result"]["ok"]) and int(r["code"]) == 1, "unknown action refused")

	# 4. thiếu tape, sai rules_version
	t = JSON.parse_string(good)
	t.erase("tape")
	r = VerifyCli.run(JSON.stringify(t))
	_schema(r, "no tape")
	_check(not bool(r["result"]["ok"]), "no tape refused (%s)" % String(r["result"]["reason"]))
	t = JSON.parse_string(good)
	(t["header"] as Dictionary)["rules_version"] = "zz"
	r = VerifyCli.run(JSON.stringify(t))
	_schema(r, "rules version")
	_check(String(r["result"]["reason"]) == RunVerifier.ERR_RULES_VERSION, "wrong rules_version -> %s" % String(r["result"]["reason"]))

	# 5. input hỏng / vượt trần
	for pair in [["", "bad_json"], ["[1,2]", "bad_json"], ["{\"tape\": 5}", "bad_tape"]]:
		r = VerifyCli.run(String(pair[0]))
		_schema(r, "bad input")
		_check(int(r["code"]) == 2 and String(r["result"]["reason"]) == String(pair[1]) and String(r["result"]["outcome"]) == "invalid",
			"input '%s' -> %s" % [pair[0], pair[1]])
	t = JSON.parse_string(good)
	var many: Array = []
	many.resize(VerifyCli.MAX_LOG_LEN + 1)
	many.fill({"fn": "end_turn", "args": []})
	t["entries"] = many
	r = VerifyCli.run(JSON.stringify(t))
	_check(int(r["code"]) == 2 and String(r["result"]["reason"]) == "log_too_long", "log length cap")

	# 5b. job có server_header / server_loadout
	_job_checks(good, honest_score)

	# 6. lệnh thật qua tiến trình con
	_cli_smoke(good, honest_score)

	print("=== t_verify_cli: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("t_verify_cli: FAIL — %s" % f)
	if _failures.is_empty():
		print("t_verify_cli: PASS — %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


## A schema-1 job payload (verifier/JOB_SCHEMA.md) made from a played log: what the Worker would send for it.
func _make_job(b: Dictionary) -> Dictionary:
	var h: Dictionary = b["header"]
	var hl: Dictionary = h.get("loadout", {}) as Dictionary
	var ranked := bool(h.get("ranked", false))
	var mission: Dictionary = h.get("mission", {}) as Dictionary
	return {"schema": 1,
		"server_header": {"rules_version": h["rules_version"], "kind": "mission" if not mission.is_empty() else ("ranked" if ranked else "normal"),
			"mode": h["mode"], "ascension": h["ascension"], "ranked": ranked, "depth_stage": h.get("depth_stage", 3),
			"newcomer": bool(h.get("newcomer", false)), "mission": mission if not mission.is_empty() else null, "header_mismatch": false},
		"server_loadout": {"bonuses": (hl.get("bonuses", {}) as Dictionary).duplicate(true), "forced": {}, "server_unknown": ["anchor", "rules_on", "core_off", "boon_id"]},
		"client_header": {"team_keys": h["team_keys"], "content_version": h["content_version"], "local_secret": h.get("local_secret", 0),
			"loadout": {"anchor": hl.get("anchor", false), "rules_on": hl.get("rules_on", true), "core_off": hl.get("core_off", false), "boon_id": hl.get("boon_id", "")}},
		"client_claim": {"outcome": "won", "score": 1},
		"entries": b["entries"], "tape": b["tape"]}


func _job_checks(good: String, honest_score: int) -> void:
	var b: Dictionary = JSON.parse_string(good)
	var job := _make_job(b)
	var r := VerifyCli.run(JSON.stringify(job))
	_schema(r, "job honest")
	_check(bool(r["result"]["ok"]) and int(r["result"]["score"]) == honest_score, "schema-1 job verifies to the played score: %s" % str(r["result"]))
	# header_mismatch flag, and a kind that contradicts the mission / ranked fields
	var j := job.duplicate(true)
	j["server_header"]["header_mismatch"] = true
	r = VerifyCli.run(JSON.stringify(j))
	_schema(r, "header_mismatch flag")
	_check(String(r["result"]["reason"]) == "header_mismatch" and String(r["result"]["outcome"]) == "rejected" and int(r["code"]) == 1, "header_mismatch=true -> reject header_mismatch")
	j = job.duplicate(true)
	j["server_header"]["kind"] = "mission"
	r = VerifyCli.run(JSON.stringify(j))
	_check(String(r["result"]["reason"]) == "header_mismatch", "kind mission without a mission -> header_mismatch")
	j = job.duplicate(true)
	j["server_header"]["kind"] = "ranked" if String(job["server_header"]["kind"]) != "ranked" else "normal"
	r = VerifyCli.run(JSON.stringify(j))
	_check(String(r["result"]["reason"]) == "header_mismatch", "kind contradicting ranked -> header_mismatch")
	# the server wins on its header fields: another ascension is not replayed as the client's
	j = job.duplicate(true)
	j["server_header"]["ascension"] = int(job["server_header"]["ascension"]) + 3
	r = VerifyCli.run(JSON.stringify(j))
	_schema(r, "server ascension")
	_check(not bool(r["result"]["ok"]) or int(r["result"]["score"]) != honest_score, "server ascension differs -> verdict changes (%s)" % String(r["result"]["reason"]))
	# missing client fields -> bad_header
	j = job.duplicate(true)
	j["client_header"].erase("team_keys")
	r = VerifyCli.run(JSON.stringify(j))
	_check(String(r["result"]["reason"]) == "bad_header" and int(r["code"]) == 1, "no team_keys -> bad_header")
	j = job.duplicate(true)
	j["client_header"]["content_version"] = ""
	r = VerifyCli.run(JSON.stringify(j))
	_check(String(r["result"]["reason"]) == "bad_header", "no content_version -> bad_header")
	# bonuses: the server's count, never the client's
	j = job.duplicate(true)
	(j["client_header"]["loadout"] as Dictionary)["bonuses"] = {"bonus_reroll": 9, "hp_bonus": 50, "start_relic_max_rarity": 1, "reward_reroll_max": 5}
	r = VerifyCli.run(JSON.stringify(j))
	_check(bool(r["result"]["ok"]) and int(r["result"]["score"]) == honest_score, "bonuses in client_header.loadout are ignored")
	j = job.duplicate(true)
	j["server_loadout"]["bonuses"] = {"bonus_reroll": 9, "hp_bonus": 50, "start_relic_max_rarity": 1, "reward_reroll_max": 5}
	r = VerifyCli.run(JSON.stringify(j))
	_check(not bool(r["result"]["ok"]) or int(r["result"]["score"]) != honest_score, "server bonuses change the replay (they are the ones used)")
	# loadout assembly: client flags kept, forced wins, no bonuses from the server = zero
	var built := VerifyCli.build_from_job({"server_header": {"kind": "ranked", "ranked": true}, "client_header": {"team_keys": ["a"], "content_version": "c",
		"loadout": {"anchor": true, "rules_on": false, "core_off": true, "boon_id": "x"}},
		"server_loadout": {"forced": {"rules_on": true, "core_off": false, "anchor": false}}, "entries": []})
	var lo: Dictionary = built["loadout"]
	_check(String(built["error"]) == "" and lo["rules_on"] == true and lo["core_off"] == false and lo["anchor"] == false and lo["boon_id"] == "x" and (lo["bonuses"] as Dictionary).is_empty(),
		"loadout: forced overrides the client flags, boon_id kept, bonuses default empty")
	# bad shape
	r = VerifyCli.run(JSON.stringify({"schema": 1, "server_header": 5}))
	_check(int(r["code"]) == 2 and String(r["result"]["reason"]) == "bad_job", "non-object server_header -> bad_job")


func _cli_smoke(good: String, honest_score: int) -> void:
	var dir := OS.get_user_data_dir().path_join("verify_cli_test")
	DirAccess.make_dir_recursive_absolute(dir)
	var inp := dir.path_join("in.json")
	var outp := dir.path_join("out.json")
	var f := FileAccess.open(inp, FileAccess.WRITE)
	f.store_string(good)
	f.close()
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"res://tools/verify_run.tscn", "--", "--in=" + inp, "--out=" + outp], output, true)
	_check(code == 0, "CLI exit 0 on honest log (got %d)" % code)
	var res: Variant = JSON.parse_string(FileAccess.get_file_as_string(outp))
	_check(res is Dictionary and VerifyCli.check_schema(res as Dictionary) == "", "CLI --out file has the fixed schema")
	if res is Dictionary:
		_check(bool(res["ok"]) and int(res["score"]) == honest_score, "CLI score equals the played score")
	# input không đọc được -> exit 2
	code = OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"res://tools/verify_run.tscn", "--", "--in=" + dir.path_join("nope.json"), "--out=" + outp], output, true)
	_check(code == 2, "CLI exit 2 on unreadable input (got %d)" % code)
	DirAccess.remove_absolute(inp)
	DirAccess.remove_absolute(outp)


func _schema(r: Dictionary, label: String) -> void:
	var s := VerifyCli.check_schema(r["result"] as Dictionary)
	_check(s == "", "%s: fixed schema (%s)" % [label, s])


func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)
