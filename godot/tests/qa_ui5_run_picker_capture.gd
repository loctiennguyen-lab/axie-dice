extends Node
## QA-only, UI-05 b23 lane S3b: shots of the 8 Run setup modal frames. Scale pinned from the window.
##   ADT_EVIDENCE_DIR=production/qa/ui05-b23/s3b godot/tools/shot.sh res://tests/qa_ui5_run_picker_capture.tscn 1280x720
var _guard := SaveGuard.new()
var _dir := QaPaths.evidence_dir()


func _shot(frame: String, small: bool) -> void:
	for _i in 14:
		await get_tree().process_frame
	var path := "%s/%s%s.png" % [_dir, frame, "--1280" if small else ""]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui5_run_picker_capture: saved ", path)


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_dir)
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	MetaState.team_presets = []
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	var s: RunSetup = load("res://scenes/run_setup/RunSetup.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	add_child(s)
	await get_tree().process_frame
	var vk := MetaState.vault_key({"axie_id": "9001"})
	ContentDB.heroes[vk] = (ContentDB.heroes["bird1"] as Dictionary).duplicate(true)
	ContentDB.heroes[vk]["n"] = "Vault Bird"
	MetaState.vault = [{"axie_id": "9001", "schema": MetaState.VAULT_SCHEMA}]
	s.party = ["plant1", vk, "aqua1", "reptile1", ""]
	s._refresh_party()
	s._refresh_footer()
	s.open_picker(4)
	for _i in 10:
		await get_tree().process_frame
	for b in s.find_children("AxieTile*", "Button", true, false):
		if String(b.get_meta("hero_key")) == vk:
			b.mouse_entered.emit()
	await _shot("06-run-setup--picker", small)
	ContentDB.heroes.erase(vk)
	MetaState.vault = []
	s._picker_tab = "vault"
	s._show_picker()
	await _shot("06-run-setup--picker-empty", small)
	s.close_modal()
	s.party = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	s._refresh_party()
	var sample := ["bird1", "beast1", "bug1", "bird1", "aqua1"]
	TeamPresets.add("Team A", sample)
	TeamPresets.add("Team B", sample)
	MetaState.team_presets[1]["party"] = ["plant1", "beast1", "aqua1", "reptile1", "vault_missing"]
	s.open_load_presets()
	await _shot("06-run-setup--presets-load", small)
	s.open_save_preset()
	await _shot("06-run-setup--presets-save", small)
	var st := LeaderboardSourceStub.new()
	s.lb_source = st
	st.boards[LeaderboardSource.query_key({"asc": s.ascension, "period": "season"})] = {"rows": [
		{"rank": 1, "name": "Player One", "score": 9000}, {"rank": 2, "name": "Player Two", "score": 8000}, {"rank": 3, "name": "Player Three", "score": 7000}],
		"me": {"rank": 9, "name": "Me", "score": 100}, "updated": "14:05"}
	st.pending = true
	s.open_leaderboard()
	await _shot("06-run-setup--lb-loading", small)
	st.release()
	await _shot("06-run-setup--lb-rows", small)
	st.boards.clear()
	st.boards[LeaderboardSource.query_key({"asc": s.ascension, "period": "season"})] = {"rows": []}
	st.pending = false
	s.open_leaderboard()
	await _shot("06-run-setup--lb-empty", small)
	st.fail_reason = "offline"
	s.open_leaderboard()
	await _shot("06-run-setup--lb-error", small)
	_guard.restore()
	get_tree().quit(0)
