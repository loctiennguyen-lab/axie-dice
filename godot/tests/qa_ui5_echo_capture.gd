extends Node
## QA-only, UI-05 b23 lane S9a: shots of the 15 Echo Box frames (20-echo--*, minus the ceremony). Scale pinned from the window.
##   ADT_EVIDENCE_DIR=production/qa/ui05-b23/s9a godot/tools/shot.sh res://tests/qa_ui5_echo_capture.tscn 1280x720
var _guard := SaveGuard.new()
var _dir := QaPaths.evidence_dir()
var _small := false


func _shot(frame: String) -> void:
	for _i in 12:
		await get_tree().process_frame
	var path := "%s/%s%s.png" % [_dir, frame, "--1280" if _small else ""]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui5_echo_capture: saved ", path)


func _make(tickets: int, state := "normal", remote := false) -> EchoBoxScreen:
	MetaState.tickets["normal"] = tickets
	var s: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	s.instant = true
	s.remote_on = remote
	s.state = state
	add_child(s)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return s


func _drop(s: Node) -> void:
	s.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_dir)
	_small = get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if _small else 1.0)
	MetaState.shard_pool = 5000
	var s := _make(24)
	await _shot("20-echo--idle")
	s._on_open_many(10)
	await _shot("20-echo--open10-confirm")
	s.close_modal()
	s.open_rates()
	await _shot("20-echo--rates")
	s.close_modal()
	s.open_confirm_buy()
	await _shot("20-echo--buy-confirm")
	s.close_modal()
	s.select_tab("seasonal")
	await _shot("20-echo--seasonal")
	s.open_rates()
	await _shot("20-echo--rates-season")
	s.close_modal()
	s.season_confirmed = false
	s._on_season_open(1)
	await _shot("20-echo--seasonal-confirm")
	s.close_modal()
	# a season summary that hit a milestone
	var ms_id := ""
	for m in EchoBox.season_cfg().get("milestones", []):
		ms_id = String((m as Dictionary).get("reward", ""))
		break
	s.results = [{"kind": "stone", "amount": 500, "milestones": [ms_id] if ms_id != "" else []}]
	s.select_tab("regular")
	s.select_tab("seasonal")
	await _shot("20-echo--seasonal-milestone")
	s.results = []
	var sid := String(EchoBox.season_cfg().get("series_id", "s1"))
	var sb: Dictionary = (MetaState.season_box as Dictionary).duplicate(true)
	var ent: Dictionary = sb.get(sid, {})
	ent["day"] = s.today()
	ent["day_pulls"] = s.season_cap_day()
	sb[sid] = ent
	MetaState.season_box = sb
	s.select_tab("regular")
	s.select_tab("seasonal")
	await _shot("20-echo--seasonal-cap")
	await _drop(s)
	s = _make(0)
	await _shot("20-echo--no-tickets")
	await _drop(s)
	for st in ["offline", "guest", "error", "loading", "last_pull"]:
		s = _make(14, st, true)
		s.set_state(st)
		if st == "last_pull":
			s.results = [{"kind": "stone", "amount": 250}, {"kind": "cosmetic", "rarity": "common", "item": "x", "duplicate": false},
				{"kind": "cosmetic", "rarity": "rare", "item": "y", "duplicate": true, "fragments": 10}]
			s.set_state(st)
		await _shot("20-echo--" + st.replace("_", "-"))
		await _drop(s)
	_guard.restore()
	UI3Theme.set_scale_override(1.0)
	get_tree().quit(0)
