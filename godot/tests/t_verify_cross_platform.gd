extends Node
## SR-V: tất định chéo nền tảng. Chơi vài run bằng bot, replay bằng RunVerifier, so (score, outcome, nodes,
## sha256 của state cuối) với file vàng `tests/fixtures/verify_golden.json` sinh trên arm64 macOS.
## Chạy cùng test này trên linux x86_64 và web (wasm) rồi so: lệch = có chỗ float/hash khác nền tảng.
## Ghi lại file vàng (chỉ khi luật đổi có chủ ý): ... t_verify_cross_platform.tscn -- --write-golden
## Cũng in dòng `XPLAT_DIGEST <platform> <sha256 của cả bảng>` để so bằng mắt giữa các máy.
## Lưu ý: golden gắn với RULES_VERSION; đổi luật mà không sinh lại golden thì test báo "golden cũ" chứ không đỏ giả.

var _guard := SaveGuard.new()
const GOLDEN := "res://tests/fixtures/verify_golden.json"
const CASES := [["short", 5], ["short", 77], ["short", 991237], ["full", 42], ["full", 9]]


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	var rows := {}
	for c in CASES:
		var played := RunBot.play_run(int(c[1]), RunBot.DEFAULT_TEAM, String(c[0]))
		var v := RunVerifier.verify(played["log"], played["tape"])
		var key := "%s-%d" % [c[0], c[1]]
		rows[key] = {"ok": bool(v["ok"]), "score": int(v["score"]), "won": bool(v["won"]),
			"played_score": int(played["score"]), "nodes": int(played["nodes"]),
			"state_sha": JSON.stringify(v["state"], "", true).sha256_text()}
	var table := {"rules_version": ActionLog.RULES_VERSION, "rows": rows}
	print("XPLAT_DIGEST %s %s" % [OS.get_name(), JSON.stringify(table, "", true).sha256_text()])
	var fails: Array[String] = []
	for k in rows:
		if not bool(rows[k]["ok"]) or int(rows[k]["score"]) != int(rows[k]["played_score"]):
			fails.append("%s: replay disagrees with the play on this machine: %s" % [k, str(rows[k])])
	if "--write-golden" in OS.get_cmdline_user_args():
		var f := FileAccess.open(GOLDEN, FileAccess.WRITE)
		f.store_string(JSON.stringify(table, "  ", true))
		f.close()
		print("t_verify_cross_platform: golden written")
	elif not FileAccess.file_exists(GOLDEN):
		fails.append("no golden file")
	else:
		var g: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN))
		if String(g["rules_version"]) != ActionLog.RULES_VERSION:
			print("t_verify_cross_platform: golden cũ (%s != %s), bỏ qua so sánh; sinh lại bằng --write-golden" % [g["rules_version"], ActionLog.RULES_VERSION])
		else:
			for k in rows:
				var gr: Dictionary = g["rows"].get(k, {})
				for f2 in ["score", "nodes", "state_sha", "won"]:
					if _norm(gr.get(f2, "")) != _norm(rows[k][f2]):
						fails.append("%s.%s differs from golden: %s vs %s" % [k, f2, str(gr.get(f2)), str(rows[k][f2])])
	for m in fails:
		print("t_verify_cross_platform: FAIL — %s" % m)
	if fails.is_empty():
		print("t_verify_cross_platform: PASS — %d runs match" % rows.size())
	_guard.restore()
	get_tree().quit(0 if fails.is_empty() else 1)


## JSON đọc lại trả số nguyên thành float ("60.0"); chuẩn hoá để so.
func _norm(v: Variant) -> String:
	return str(int(v)) if (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT) else str(v)
