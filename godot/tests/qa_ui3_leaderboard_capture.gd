extends Node
## QA (not headless): UI-03 Leaderboard states with stub data, no network. Saves
## production/qa/evidence/ui3-leaderboard-<state>-<WxH>.png. Run with --resolution WxH.
var _guard := SaveGuard.new()


func _rows(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append({"rank": i + 1, "name": ["Kito", "Mara", "Tuấn Anh", "Bao", "Linh"][i % 5] + str(i), "land": "Savannah",
			"aid": "Aid" if i % 3 == 1 else "", "score": 2480 - i * 61, "won": i % 4 != 3,
			"mode": "Short · ranked", "date": "11 Oct 2026",
			"detail": {"summary": "Won · Full · A6", "party": ["plant1", "beast1", "aqua1"], "aid_note": "Aid used 2" if i % 3 == 1 else ""}})
	return out


func _shot(name: String) -> void:
	for i in 12:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var sz := get_tree().root.size
	var dir := QaPaths.evidence_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	var path := "%s/ui3-leaderboard-%s-%dx%d.png" % [dir, name, sz.x, sz.y]
	get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)


func _screen(src: LeaderboardSource, setup := {}) -> LeaderboardScreen:
	var s := LeaderboardScreen.new()
	s.use_account = false
	s.no_scene_change = true
	s.source = src
	for k in setup:
		s.set(k, setup[k])
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(s)
	return s


func _ready() -> void:
	_guard.capture()
	MetaState.asc_max = 6
	MetaState.runs = 20
	MetaState.runs_with_battle = 20
	var stub := LeaderboardSourceStub.new()
	var me := {"rank": 48, "name": "Liam", "land": "Savannah", "aid": "", "score": 1612, "won": true, "mode": "Short · ranked", "date": "10 Oct 2026"}
	stub.boards["6|season"] = {"rows": _rows(12), "me": me}
	stub.boards["6|today"] = {"rows": _rows(6), "me": me}
	stub.boards["3|season"] = {"rows": _rows(9), "me": me}
	var s := _screen(stub)
	await _shot("season")
	s.open_detail(1)
	await _shot("season-detail")
	s.set_period("today")
	await _shot("today")
	s.set_period("season")
	s.set_asc(3)
	await _shot("filtered-a3")
	s.set_asc(9)
	await _shot("locked-a9")
	s.set_asc(2)
	await _shot("empty")
	s.queue_free()
	var bad := LeaderboardSourceStub.new()
	bad.fail_reason = "error"
	var e := _screen(bad)
	await _shot("error")
	e.queue_free()
	_guard.restore()
	get_tree().quit(0)
