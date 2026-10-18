extends Node
## QA: capture a UI-03 meta screen. Not headless.
## godot --path godot --resolution 1920x1080 res://tests/qa_ui3_meta_capture.tscn -- --screen=presets --out=/path/x.png
var _guard := SaveGuard.new()


func _ready() -> void:
	_guard.capture()
	var screen := "presets"
	var out := "user://meta.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screen="):
			screen = a.get_slice("=", 1)
		elif a.begins_with("--out="):
			out = a.get_slice("=", 1)
	MetaState.tutorial_seen = true
	MetaState.asc_max = 6
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	var node: Node = await _make(screen)
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("META_CAPTURE ", screen, " ", get_viewport().get_visible_rect().size)
	_guard.restore()
	get_tree().quit(0)


func _make(screen: String) -> Node:
	if screen.begins_with("presets"):
		MetaState.team_presets = []
		if screen != "presets-empty":
			TeamPresets.add("Thorn Wall", ["plant1", "beast1", "aqua1", "reptile1", "bug1"])
			TeamPresets.add("Fang Rush", ["beast1", "reptile1", "bug1", "bird1", "aqua1"])
			MetaState.team_presets.append({"name": "Bloom Guard", "party": ["plant1", "beast1", "vault_1", "reptile1", "bug1"]})
		var s: TeamPresetsScreen = load("res://scenes/team_presets/TeamPresets.tscn").instantiate()
		s.use_account = false
		s.no_scene_change = true
		add_child(s)
		await get_tree().process_frame
		if screen == "presets-editor":
			s.open_editor(0)
		elif screen == "presets-samples":
			s.switch_tab("samples")
		elif screen == "presets-delete":
			s.request_delete(0)
		return s
	if screen.begins_with("upgrade"):
		MetaState.land_tier = 1
		MetaState.stone = 1200 if screen == "upgrade-short" else 41200
		var u: LandUpgradeScreen = load("res://scenes/land_upgrade/LandUpgrade.tscn").instantiate()
		u.no_scene_change = true
		add_child(u)
		await get_tree().process_frame
		return u
	return null
