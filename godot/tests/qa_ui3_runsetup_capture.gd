extends Node
## Manual visual QA for UI-03 Run setup (06). Run non-headless via tools/shot.sh.
var _EVIDENCE_DIR := QaPaths.evidence_dir()
var _guard := SaveGuard.new()


func _shot(tag: String) -> void:
	for i in 12:
		await get_tree().process_frame
	var w := DisplayServer.window_get_size()
	get_viewport().get_texture().get_image().save_png("%s/ui3-run-setup-%s-%dx%d.png" % [_EVIDENCE_DIR, tag, w.x, w.y])


func _make(newcomer: bool) -> RunSetup:
	MetaState.asc_max = 6
	MetaState.runs = 2 if newcomer else 9
	MetaState.runs_with_battle = 2 if newcomer else 9
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.no_scene_change = true
	s.use_account = false
	s.ascension = 0 if newcomer else 4
	add_child(s)
	return s


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	var s := _make(false)
	await _shot("normal")
	s.clear_slot(3)
	s.clear_slot(4)
	s.set_state("offline")
	await _shot("empty-offline")
	s.open_picker(3)
	await _shot("picker")
	s.clear_slot(0)
	s._picker_sel = "bird1"
	s._show_picker()
	await _shot("picker-selected")
	s.close_modal()
	var ks: Array = MainMenu.T1_HERO_KEYS.duplicate()
	TeamPresets.add("Plant rush", ks.slice(0, 5))
	ks.reverse()
	TeamPresets.add("Old squad", ks.slice(0, 5))
	s.open_load_presets()
	await _shot("presets-load")
	s.open_save_preset()
	await _shot("presets-save")
	var st := LeaderboardSourceStub.new()
	st.boards[LeaderboardSource.query_key({"asc": s.ascension, "period": "season"})] = {"rows": [
		{"rank": 1, "name": "Liam", "score": 9120}, {"rank": 2, "name": "Mira", "score": 8800},
		{"rank": 3, "name": "Tomo", "score": 8410}, {"rank": 4, "name": "Ana", "score": 7900},
		{"rank": 5, "name": "Bao", "score": 7312}], "me": {"rank": 41, "name": "You", "score": 3200}}
	s.lb_source = st
	s.open_leaderboard()
	await _shot("leaderboard")
	st.fail_reason = "offline"
	s.open_leaderboard()
	await _shot("leaderboard-error")
	s.close_modal()
	s.queue_free()
	await get_tree().process_frame
	s = _make(true)
	await _shot("newcomer")
	s.queue_free()
	await get_tree().process_frame
	s = _make(false)
	s.set_state("open_run")
	await _shot("open-run")
	_guard.restore()
	get_tree().quit(0)
