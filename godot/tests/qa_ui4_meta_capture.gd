extends Node
## UI-04 meta capture (missions, result, echobox, pass, netnotice, update bar). Not headless.
## godot --path godot --resolution 1920x1080 res://tests/qa_ui4_meta_capture.tscn -- --screen=missions --out=/path.png
var _guard := SaveGuard.new()
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _ready() -> void:
	_guard.capture()
	var screen := "missions"
	var out := "user://ui4.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--screen="):
			screen = a.get_slice("=", 1)
		elif a.begins_with("--out="):
			out = a.get_slice("=", 1)
	MetaState.tutorial_seen = true
	MetaState.asc_max = 6
	MetaState.runs = 9
	MetaState.runs_with_battle = 9
	await _make(screen)
	for i in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("UI4_CAPTURE ", screen, " ", get_viewport().get_visible_rect().size)
	_guard.restore()
	get_tree().quit(0)


func _make(screen: String) -> void:
	match screen:
		"missions":
			MetaState.shard_pool = 4200
			MetaState.starter_shard_locked = 0
			MetaState.asc_wins = {"3": 1}
			MetaState.mission_unlock_cache = ["N2", "N3"]
			MetaState.mission_escrow = {}
			var ms: MissionsScreen = load("res://scenes/missions/MissionsScreen.tscn").instantiate()
			ms.use_account = false
			ms.no_scene_change = true
			ms.day_override = "2026-10-12"
			add_child(ms)
			await get_tree().process_frame
			ms.select_tier("N3")
		"pass":
			MetaState.pass_season = PassV2.new_state("s1")
			MetaState.pass_season["xp"] = 4300
			MetaState.pass_season["level"] = 7
			MetaState.pass_season["claimed_free"] = [1, 2, 3]
			var pv: PassView = load("res://scenes/pass/Pass.tscn").instantiate()
			pv.use_account = false
			pv.no_scene_change = true
			pv.today_override = "2026-11-10"
			add_child(pv)
			await get_tree().process_frame
		"netnotice":
			var host := Control.new()
			add_child(host)
			NetNotice.show(host, "offline", func() -> void: pass, "Could not send your turn")
		"updatebar":
			UpdateRequired.web_override = 1
			UpdateRequired.show_bar(get_tree())
