extends Node
## UI-06 L2 capture (NOT headless): 03-run-map cores strip + core tooltip + rule hover, menu--cores-owned, 02-combat strip + core-firing + anchor-firing.
## Run: UI6_PROBE_SCALE=1.0 godot/tools/shot.sh res://tests/qa_ui06_l2_capture.tscn 1920x1080   (and 0.667 / 1280x720)
var _guard := SaveGuard.new()


func _shot(name: String, tag: String, pre := 0.5) -> void:
	await get_tree().create_timer(pre).timeout
	var out := OS.get_environment("UI6_SHOT_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/ui06/l2").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, name, tag])


func _ready() -> void:
	_guard.capture()
	var want := OS.get_environment("UI6_PROBE_SCALE")
	if want != "":
		UI3Theme.set_scale_override(float(want))
	UI3Theme.sync_scale()
	var tag := "1920" if UI3Theme.layout_scale() >= 0.99 else "1280"
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	# no Core / Rule / Anchor offer overlay over the map: drop the opening offers start_new_run opened
	RunState.pending_rewards.clear()
	RunState._core_offer_active = false
	RunState._rule_offer_active = false
	RunState.set_phase(RunState.RunPhase.MAP)
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "owned": ["c_bastion"], "awakened": false}
	for id in ["c_bastion", "c_fissure", "c_plague_spread"]:
		RunState.owned_relic_ids.append(id)
	RunState.run_rule = "rule_pack_alpha"
	var scene: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(scene)
	for _i in 20:
		await get_tree().process_frame
	await _shot("03-run-map--cores-strip", tag)
	var slot := scene.find_child("CoreSlot*", true, false) as Control
	CoreTooltip.show_now(slot)
	await _shot("03-run-map--core-tooltip", tag)
	CoreTooltip.hide_all(get_tree())
	CoreTooltip.show_now(scene.find_child("RunRuleSlot", true, false) as Control)
	await _shot("03-run-map--rule-tile-hover", tag)
	CoreTooltip.hide_all(get_tree())
	scene.open_run_menu()
	await get_tree().process_frame
	var pm := scene.find_child("RunPauseMenu", true, false) as RunPauseMenu
	if pm == null:
		for n in scene.find_children("*", "RunPauseMenu", true, false):
			pm = n
	pm.show_side("relics")
	await _shot("menu--cores-owned", tag)
	scene.queue_free()
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 90:
		await get_tree().process_frame
	await _shot("02-combat--cores-strip", tag)
	var ally: int = v._combat.party[0].uid
	var foe: int = v._combat.enemies[0].uid
	EventBus.core_fired.emit("c_bastion", ally, 3, "shield")
	await get_tree().create_timer(0.0).timeout
	await _shot("02-combat--core-firing", tag, 0.13)
	await get_tree().create_timer(1.2).timeout
	EventBus.core_fired.emit("a_volley", foe, 6, "dmg")
	await get_tree().create_timer(0.0).timeout
	await _shot("02-combat--anchor-firing", tag, 0.13)
	_guard.restore()
	AnchorAdapter.test_state = {}
	get_tree().quit(0)
