extends Node
## UI-05 b23 lane M3 capture (not headless): mid-moment frames of the meta moments on the real screens.
##   ADT_EVIDENCE_DIR=<abs>/production/qa/ui05-b23/m3 godot/tools/shot.sh res://tests/qa_ui5_moments_b3_capture.tscn 1920x1080
var _guard := SaveGuard.new()
var _out := ""
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bird1"]


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_out.path_join(name + ".png"))


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _cos(rarity: String, dup := false) -> Dictionary:
	var box: Dictionary = ((EchoBox._cfg().get("boxes", {}) as Dictionary).get("normal", {})) as Dictionary
	var best := ""
	for id in EchoBox.pool_ids(box, rarity):
		var a := Cosmetics.art_id(String(id))
		if a != "" and Cosmetics.slot_of(a) == Cosmetics.SLOT_DIE and CosmeticTile.any_name(String(id)) != "":
			best = String(id)
			break
	return {"ok": true, "kind": "cosmetic", "item": best, "rarity": rarity, "duplicate": dup, "fragments": 10 if dup else 0}


func _echo(res: Array, waits: Array, names: Array) -> void:
	var s: EchoBoxScreen = load("res://scenes/echobox/EchoBoxScreen.tscn").instantiate()
	s.use_account = false
	s.remote_on = true
	s.no_scene_change = true
	s.instant = false
	add_child(s)
	for i in 6:
		await get_tree().process_frame
	s.pull_hook = func(_n: int) -> Array: return res
	s.pull(res.size())
	var t := 0.0
	for k in waits.size():
		await _wait(float(waits[k]) - t)
		t = float(waits[k])
		await _shot(String(names[k]))
	s.queue_free()
	await get_tree().process_frame


func _result(won: bool, name: String) -> void:
	RunState.start_new_run(777001, TEAM, "short", 5, false)
	RunState.power_level = 14
	RunState.shards_this_run = 87
	RunState.run_stats = {"dmg": 913, "dmg_dealt_clamped": 913, "taken": 140, "turns": 41, "kills": 23, "max_hit": 31}
	RunState.set_phase(RunState.RunPhase.WON if won else RunState.RunPhase.LOST)
	var v: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	add_child(v)
	await _wait(0.9)
	await _shot(name + "-mid")
	await _wait(1.2)
	await _shot(name + "-rest")
	v.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	_guard.capture()
	ProjectSettings.set_setting("axie/epoch_source", "local")
	_out = OS.get_environment("ADT_EVIDENCE_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui05-b23/m3").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	MetaState.reduce_motion = false
	MetaState.reduce_flash = false
	UI3Theme.set_scale_override(1.0)
	MetaState.tickets = {"normal": 30, "season": 0}
	MetaState.echobox_pity = {}
	var stone := {"ok": true, "kind": "stone", "amount": 500, "rarity": "", "item": "", "duplicate": false, "fragments": 0}
	await _echo([_cos("mythic")], [1.3, 1.75], ["echo-open-mythic-tint", "echo-open-mythic-flip"])
	await _echo([_cos("legendary")], [1.1, 1.45], ["echo-open-rare-tint", "echo-open-rare-flip"])
	var ten: Array = []
	for r in ["", "common", "", "common", "", "", "uncommon", "", "common", "epic"]:
		ten.append(stone if r == "" else _cos(r))
	await _echo(ten, [1.5, 2.0], ["open-10-mid-a", "open-10-mid-b"])
	await _result(true, "run-end-win")
	await _result(false, "run-end-lose")
	# land-tier-up: the Land banner after an upgrade
	MetaState.tutorial_seen = true
	LandNav.dry_run = true
	LandHub.qa = {"guest": false}
	MetaState.land_gift_granted = true
	MetaState.land_tier = 2
	MetaState.land_tier_banner_seen = 1
	var h := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate()
	add_child(h)
	await _wait(0.5)
	await _shot("land-tier-up-mid")
	await _wait(1.0)
	await _shot("land-tier-up-rest")
	h.queue_free()
	LandHub.qa = {}
	await get_tree().process_frame
	# pass-level-up
	var lv := 10
	MetaState.pass_season = PassV2.new_state("s1")
	MetaState.pass_season["xp"] = int(PassV2.level_def(lv - 1).get("xp_total", 0))
	var p: PassView = load("res://scenes/pass/Pass.tscn").instantiate()
	PassView.seen_level = lv - 1
	add_child(p)
	await _wait(0.4)
	MetaState.pass_season["xp"] = int(PassV2.level_def(lv).get("xp_total", 0)) + 40
	p.refresh()
	await _wait(0.45)
	await _shot("pass-level-up-mid")
	p.queue_free()
	await get_tree().process_frame
	# daily-claim
	MetaState.daily_date = ""
	var d: DailyScreen = load("res://scenes/daily/DailyScreen.tscn").instantiate()
	d.use_account = false
	d.state = "normal"
	d.no_scene_change = true
	d.test_mode = true
	d.day_override = MetaState.today_utc()
	add_child(d)
	await _wait(0.4)
	d.claim_daily()
	await _wait(0.3)
	await _shot("daily-claim-mid")
	d.queue_free()
	_guard.restore()   # the Result / Pass / Daily moments write the save; put it back (t_vault)
	get_tree().quit(0)
