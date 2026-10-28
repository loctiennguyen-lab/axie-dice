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
		"echobox", "echobox_new", "echobox_dupe":
			MetaState.shard_pool = 4200
			MetaState.tickets = {"normal": 12, "season": 0}
			MetaState.echobox_pity = {"fragments": 0, "since_rare": 17, "since_epic": 8, "since_legendary": 31, "since_mythic": 44}
			var eb: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
			eb.use_account = false
			eb.remote_on = false
			eb.no_scene_change = true
			eb.instant = true
			add_child(eb)
			await get_tree().process_frame
			var ids := EchoBox.pool_ids(eb.box_cfg(), "common")
			var item := String(ids[0])
			if screen == "echobox":
				eb.set_last_open({"ok": true, "kind": "cosmetic", "item": item, "rarity": "common", "duplicate": true, "fragments": 5})
			elif screen == "echobox_new":
				eb.pull_hook = func(_n: int) -> Array:
					return [{"ok": true, "kind": "cosmetic", "item": item, "rarity": "common", "duplicate": false}]
				eb.pull(1)
			else:
				MetaState.echobox_pity["fragments"] = 5
				eb.pull_hook = func(_n: int) -> Array:
					return [{"ok": true, "kind": "cosmetic", "item": item, "rarity": "common", "duplicate": true, "fragments": 5}]
				eb.pull(1)
			await get_tree().process_frame
