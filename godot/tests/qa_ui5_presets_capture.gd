extends Node
## QA-only, UI-05 b23 lane S4a: shots of t01-t09. Scale pinned from the window.
##   ADT_EVIDENCE_DIR=production/qa/ui05-b23/s4a godot/tools/shot.sh res://tests/qa_ui5_presets_capture.tscn 1280x720
var _guard := SaveGuard.new()
var _dir := QaPaths.evidence_dir()


func _shot(frame: String, small: bool) -> void:
	for _i in 12:
		await get_tree().process_frame
	var path := "%s/%s%s.png" % [_dir, frame, "--1280" if small else ""]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui5_presets_capture: saved ", path)


func _make(setup := {}) -> TeamPresetsScreen:
	var s: TeamPresetsScreen = load("res://scenes/team_presets/TeamPresets.tscn").instantiate()
	s.use_account = false
	s.no_scene_change = true
	for k in setup:
		s.set(k, setup[k])
	add_child(s)
	return s


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_dir)
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	MetaState.team_presets = []
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	var s := _make()
	await _shot("t01-presets--empty", small)
	s.queue_free()
	var party := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	TeamPresets.add("Thorn Wall", party)
	TeamPresets.add("Sky Rush", ["bird1", "beast1", "bug1", "bird1", "aqua1"])
	TeamPresets.add("Third", party)
	MetaState.team_presets[2]["party"] = ["plant1", "beast1", "aqua1", "reptile1", "vault_missing"]
	s = _make()
	await _shot("t02-presets--grid", small)
	s.request_delete(1)
	await _shot("t07-presets--delete", small)
	s.close_modal()
	s.open_editor(0)
	await _shot("t04-presets--editor-edit", small)
	s._show_picker(2)
	await _shot("t05-presets--picker", small)
	s._close_picker()
	s.set_edit_name("Changed")
	s.request_cancel()
	await _shot("t06-presets--discard", small)
	s.queue_free()
	TeamPresets.remove(2)
	s = _make()
	s.open_editor(-1)
	await _shot("t08-presets--editor-new", small)
	s.queue_free()
	s = _make()
	s.switch_tab("samples")
	await _shot("t03-presets--samples", small)
	s.queue_free()
	s = _make({"guest": true})
	await _shot("t09-presets--guest", small)
	s.queue_free()
	_guard.restore()
	get_tree().quit(0)
