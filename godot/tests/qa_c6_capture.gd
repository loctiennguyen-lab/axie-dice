extends Node
## C6 screenshots: Team presets + Leaderboard -> production/qa/evidence/l1-c6-*.png.
## Run WITHOUT --headless:  ... res://tests/qa_c6_capture.tscn -- <height>
var _guard := SaveGuard.new()


func _shot(name: String, h: int) -> void:
	for i in 12:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(
		ProjectSettings.globalize_path("res://../production/qa/evidence/l1-c6-%s-%d.png" % [name, h]))


func _ready() -> void:
	_guard.capture()
	var h := 1080
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		h = int(args[0])
	DisplayServer.window_set_size(Vector2i(1920, h))
	MetaState.asc_max = 6
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	MetaState.team_presets = []
	TeamPresets.add("Thorn Wall", ["plant1", "beast1", "aqua1", "reptile1", "bug1"])
	TeamPresets.add("Fang Rush", ["beast1", "reptile1", "bug1", "bird1", "aqua1"])
	MetaState.team_presets.append({"name": "Bloom Guard", "party": ["plant1", "beast1", "vault_1", "reptile1", "bug1"]})
	var s: TeamPresetsScreen = load("res://scenes/team_presets/TeamPresets.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	add_child(s)
	await _shot("presets", h)
	s.queue_free()
	var stub := LeaderboardSourceStub.new()
	var rows: Array = []
	var lands := ["Mystic", "Arctic", "Arctic", "Forest", "Arctic", "Forest", "Savannah", "Forest", "Savannah", "Savannah", "Savannah"]
	for i in 11:
		rows.append({"rank": i + 1, "name": ["Kito", "Mara_v", "Tamsin", "Okonkwo", "lunarfox", "Bao Tran", "Hikari", "Petra", "dicegoblin", "Quang", "Ines R."][i],
			"land": lands[i], "aid": "Aid" if i in [1, 5] else "", "score": 2480 - i * 61, "mode": "Short · ranked", "date": "%d Oct 2026" % (11 - i % 4),
			"detail": {"summary": "Won · Full · A6 · 52 turns", "party": ["plant1", "beast1", "aqua1"], "aid_note": "Aid used 2"}})
	stub.boards["6|season"] = {"rows": rows, "me": {"rank": 48, "name": "Liam", "land": "Savannah", "aid": "", "score": 1612, "mode": "Short · ranked", "date": "10 Oct 2026"}}
	var lb: LeaderboardScreen = load("res://scenes/leaderboard/Leaderboard.tscn").instantiate()
	lb.use_account = false
	lb.no_scene_change = true
	lb.source = stub
	add_child(lb)
	await _shot("leaderboard", h)
	lb.open_detail(2)
	await _shot("leaderboard-detail", h)
	_guard.restore()
	get_tree().quit(0)
