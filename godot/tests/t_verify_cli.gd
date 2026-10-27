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


func _job(bundle: Dictionary, sh: Variant, sl: Variant) -> String:
	var tape: Variant = bundle["tape"]
	var lg: Dictionary = bundle.duplicate(true)
	lg.erase("tape")
	var job := {"log": lg, "tape": tape}
	if sh != null:
		job["server_header"] = sh
	if sl != null:
		job["server_loadout"] = sl
	return JSON.stringify(job)


func _job_checks(good: String, honest_score: int) -> void:
	var b: Dictionary = JSON.parse_string(good)
	var h: Dictionary = b["header"]
	var sh := {"rules_version": h["rules_version"], "mode": h["mode"], "ascension": h["ascension"], "ranked": h["ranked"],
		"depth_stage": h.get("depth_stage", 3), "kind": "ranked" if bool(h["ranked"]) else "normal", "mission": h.get("mission", {})}
	# job without server_* = same as the bare bundle
	var r := VerifyCli.run(_job(b, null, null))
	_schema(r, "job plain")
	_check(bool(r["result"]["ok"]) and int(r["result"]["score"]) == honest_score, "job form without server_* verifies: %s" % str(r["result"]))
	# matching server header -> ok
	r = VerifyCli.run(_job(b, sh, null))
	_check(bool(r["result"]["ok"]) and int(r["result"]["score"]) == honest_score, "matching server_header verifies: %s" % str(r["result"]))
	# each field differs -> header_mismatch
	var bad := {"rules_version": "zz", "mode": "full" if String(h["mode"]) == "short" else "short", "ascension": int(h["ascension"]) + 1,
		"ranked": not bool(h["ranked"]), "depth_stage": int(h.get("depth_stage", 3)) % 3 + 1,
		"kind": "daily", "mission": {"tier": 1, "rules": ["m1"]}}
	for k in bad:
		var sh2: Dictionary = sh.duplicate(true)
		sh2[k] = bad[k]
		r = VerifyCli.run(_job(b, sh2, null))
		_schema(r, "header_mismatch " + k)
		_check(String(r["result"]["reason"]) == "header_mismatch" and String(r["result"]["outcome"]) == "rejected" and int(r["code"]) == 1 and int(r["result"]["score"]) == 0,
			"server_header.%s differs -> header_mismatch (%s)" % [k, String(r["result"]["reason"])])
	# server loadout wins over the header's: poison the log header bonuses, send the real loadout
	var real_lo: Dictionary = (h.get("loadout", {}) as Dictionary).duplicate(true)
	var lo_for_server: Dictionary = real_lo.duplicate(true)
	lo_for_server.erase("anchor"); lo_for_server.erase("rules_on"); lo_for_server.erase("core_off"); lo_for_server.erase("boon_id")
	var poisoned: Dictionary = b.duplicate(true)
	var ph: Dictionary = poisoned["header"]
	var pl: Dictionary = (ph.get("loadout", {}) as Dictionary).duplicate(true)
	pl["bonuses"] = {"bonus_reroll": 9, "hp_bonus": 50, "start_relic_max_rarity": 1, "reward_reroll_max": 5}
	ph["loadout"] = pl
	var without := VerifyCli.run(_job(poisoned, null, null))
	_check(not bool(without["result"]["ok"]) or int(without["result"]["score"]) != honest_score, "poisoned header bonuses change the verdict when the server sends none")
	r = VerifyCli.run(_job(poisoned, null, lo_for_server))
	_check(bool(r["result"]["ok"]) and int(r["result"]["score"]) == honest_score, "server_loadout overrides the header bonuses: %s" % str(r["result"]))
	# keys the server does not send come from the log header
	var m := VerifyCli.merge_loadout({"bonuses": {"bonus_reroll": 1}}, {"loadout": {"anchor": "x", "rules_on": true, "core_off": false, "boon_id": "b", "bonuses": {"bonus_reroll": 7}}})
	_check(m["anchor"] == "x" and m["rules_on"] == true and m["core_off"] == false and m["boon_id"] == "b" and int(m["bonuses"]["bonus_reroll"]) == 1, "merge_loadout keeps anchor/rules_on/core_off/boon_id, server bonuses win")
	m = VerifyCli.merge_loadout({"anchor": "y"}, {"loadout": {"anchor": "x"}})
	_check(m["anchor"] == "y" and (m["bonuses"] as Dictionary).is_empty(), "server anchor wins; no server bonuses = zero bonuses")
	# bad job shape
	r = VerifyCli.run(JSON.stringify({"log": b, "server_header": 5}))
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
