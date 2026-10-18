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
	if screen.begins_with("missions"):
		MetaState.shard_pool = 1240
		MetaState.starter_shard_locked = 200
		MetaState.asc_wins = {"3": 1, "4": 1}
		MetaState.mission_escrow = {}
		if screen == "missions-newcomer":
			MetaState.runs_with_battle = 2
		var ms: MissionsScreen = load("res://scenes/missions/MissionsScreen.tscn").instantiate()
		ms.use_account = false
		ms.no_scene_change = true
		ms.day_override = "2026-10-12"
		add_child(ms)
		await get_tree().process_frame
		if screen == "missions-confirm":
			ms.open_confirm("N2")
		elif screen == "missions-short":
			MetaState.shard_pool = 350
			ms.select_tier("N2")
		elif screen == "missions-guest":
			ms.set_state("guest")
		return ms
	if screen.begins_with("daily"):
		MetaState.daily_date = ""
		MetaState.gem_gift_day = ""
		MetaState.daily_week = {}
		var ds: DailyScreen = load("res://scenes/daily/DailyScreen.tscn").instantiate()
		ds.use_account = false
		ds.no_scene_change = true
		add_child(ds)
		await get_tree().process_frame
		if screen == "daily-claimed":
			ds.claim_daily()
		elif screen == "daily-cap":
			MetaState.gems_cache = 900
			ds._refresh()
		elif screen == "daily-offline":
			ds.remote_on = true
			ds.set_state("offline")
		elif screen == "daily-guest":
			ds.remote_on = true
			ds.set_state("guest")
		return ds
	if screen.begins_with("echo"):
		MetaState.tickets = {"normal": 3}
		MetaState.shard_pool = 900
		var es: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
		es.use_account = false
		es.no_scene_change = true
		es.instant = true
		add_child(es)
		await get_tree().process_frame
		if screen == "echo-rates":
			es.open_rates()
		elif screen == "echo-seasonal":
			es.select_tab("seasonal")
		elif screen == "echo-none":
			MetaState.tickets = {"normal": 0}
			es._refresh_all()
		elif screen == "echo-reveal":
			MetaState.tickets = {"normal": 10}
			es.pull_hook = func(n: int) -> Array:
				var o: Array = []
				for k in n:
					o.append({"kind": "stone", "amount": 250} if k % 3 == 0 else {"kind": "cosmetic", "rarity": ["common", "rare", "epic"][k % 3], "item": "std_e_003", "duplicate": k % 2 == 0, "fragments": 2})
				return o
			es.pull(10)
			await get_tree().process_frame
			await get_tree().process_frame
		return es
	return null
