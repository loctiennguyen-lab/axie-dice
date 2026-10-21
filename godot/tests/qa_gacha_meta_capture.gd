extends Node
## Lane GM capture (NOT headless, tools/shot.sh): combo burst in combat. Saves gacha_meta_combat_WxH.png.
var _guard := SaveGuard.new()

func _ready() -> void:
	_guard.capture()
	var out := OS.get_environment("ADT_EVIDENCE_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	var cid := "combo_turtle_fort"
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 3, false)
	for id in ["c_living_wall", "c_gatekeeper", "c_backline_glow"]:
		RunState.owned_relic_ids.append(id)
	RunState.combo_done = {cid: "pair", "combo_golden_nest": "full"}
	RunState.core_skipped_t.assign(["c_prism", "c_finisher"])
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 90:
		await get_tree().process_frame
	v._land_dice_now()
	var ally: int = v._combat.party[0].uid
	var foe: int = v._combat.enemies[0].uid
	EventBus.core_fired.emit("c_living_wall", ally, 6, "block")
	EventBus.core_fired.emit("c_gatekeeper", foe, 5, "dmg")
	EventBus.combo_fired.emit(cid)
	await get_tree().create_timer(0.5).timeout
	await _shot(out, "gacha_meta_combat")
	v.queue_free()
	# Result
	RunState.set_phase(RunState.RunPhase.WON)
	var r: Node = (load("res://scenes/result/Result.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(r)
	for _i in 30:
		await get_tree().process_frame
	var sc := r.find_children("*", "ScrollContainer", true, false)
	if not sc.is_empty():
		(sc[0] as ScrollContainer).scroll_vertical = 100000
		await get_tree().process_frame
		await get_tree().process_frame
	await _shot(out, "gacha_meta_result")
	r.queue_free()
	# Codex Combos
	MetaState.core_codex = {"c_living_wall": {"seen": true, "picked": true}, "c_gatekeeper": {"seen": true, "picked": true}, "c_prism": {"seen": true, "picked": false}}
	MetaState.combo_codex = {cid: {"pair": true, "full": false}, "combo_golden_nest": {"pair": true, "full": true}}
	var cx: Node = (load("res://scenes/codex/Codex.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(cx)
	for _i in 10:
		await get_tree().process_frame
	cx.call("_select_tab", "combos")
	for _i in 10:
		await get_tree().process_frame
	await _shot(out, "gacha_meta_codex")
	cx.queue_free()
	# Daily
	RunState.combo_done = {}
	MetaState.combo_daily = {"day": "", "done": false, "count": 0}
	var d: Node = (load("res://scenes/daily/DailyScreen.tscn") as PackedScene).instantiate()
	d.use_account = false
	d.no_scene_change = true
	get_tree().root.add_child(d)
	for _i in 20:
		await get_tree().process_frame
	await _shot(out, "gacha_meta_daily")
	_guard.restore()
	get_tree().quit(0)

func _shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s_%dx%d.png" % [out, name, img.get_width(), img.get_height()])
	print("QA: saved ", name)
