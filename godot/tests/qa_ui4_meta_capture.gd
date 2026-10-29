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
		"result_won":
			_result(true, false, false)
		"result_lost_stake":
			_result(false, true, false)
		"result_mission_lost":
			_result(false, true, true)
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

## Result screen (UI-04 10): "result_won" (mission win), "result_lost_stake" (mission lost, 800 stake),
## "result_mission_lost" (mission lost, fullest case: Cores that fired).
func _result(won: bool, stake: bool, full: bool) -> void:
	RunState.start_new_run(777001, TEAM, "short", 5, false)
	RunState.power_level = 2
	RunState.shards_this_run = 87
	RunState.owned_relic_ids.assign(["r_claw", "r_carapace", "r_pierceall", "r_bloodmouth", "r_heart"])
	RunState.run_stats = {"dmg": 913, "dmg_dealt_clamped": 913, "taken": 140, "turns": 41, "kills": 23, "max_hit": 31}
	if full:
		RunState.core_impact = {"r_claw": {"n": 4, "by": {"dmg": 120}}, "r_heart": {"n": 2, "by": {"dmg": 30}}}
	RunState.mission = {"mission_id": "m_cap", "condition": ""}
	MetaState.mission_escrow = {"mission_id": "m_cap", "tier": "N3", "stake": 800, "payout": 1600 if (stake or won) else 0, "stone": 0}
	MetaState.shard_pool = 794
	RunState.set_phase(RunState.RunPhase.WON if won else RunState.RunPhase.LOST)
	var v: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	add_child(v)
