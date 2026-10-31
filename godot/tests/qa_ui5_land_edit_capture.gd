extends Node
## QA (not headless): frames u01-u05 (Land upgrade) then e01-e05 (Edit Land) of round-3 at the window size (1920x1080 or
## 1280x720, scale pinned like qa_ui5_pin). In-memory state only. Files: <UI5_SHOT_DIR>/<frame id>-WxH.png
##   UI5_SHOT_DIR=.../production/qa/ui05-b23/s2 godot/tools/shot.sh res://tests/qa_ui5_land_edit_capture.tscn 1280x720
const Util := preload("res://tests/qa_ui5_util.gd")
const Eco := preload("res://scripts/meta/economy_db.gd")
var _guard := SaveGuard.new()


func _up(id: String, tier: int, stone: int, confirm := false) -> void:
	MetaState.land_tier = tier
	MetaState.stone = stone
	var s: LandUpgradeScreen = load("res://scenes/land_upgrade/LandUpgrade.tscn").instantiate()
	s.no_scene_change = true
	add_child(s)
	for i in 6:
		await get_tree().process_frame
	if confirm:
		s._ask(tier + 1)
		for i in 6:
			await get_tree().process_frame
	await RenderingServer.frame_post_draw
	Util.save(get_viewport(), id)
	s.queue_free()
	await get_tree().process_frame


func _ready() -> void:
	_guard.capture()
	Eco.get_table("land_tiers")["upgrade_enabled"] = true
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	var sfx := "--1280" if small else ""
	var c1 := Eco.land_tier_cost(1)
	await _up("u01-land-upgrade--short", 1, 3200)
	await _up("u02-land-upgrade--ready", 1, c1 + 6500)
	await _up("u03-land-upgrade--confirm", 1, c1 + 6500, true)
	await _up("u04-land-upgrade--tier3", 3, 64000)
	await _up("u05-land-upgrade--max", 6, 41200)
	MetaState.tutorial_seen = true
	MetaState.land_tier = 4
	MetaState.land_tier_banner_seen = 4
	MetaState.shard_pool = 500
	MetaState.land_decor_owned = {"decor_sav_tree": 3, "decor_sav_rock": 2, "decor_for_flower": 2, "decor_sav_shrub": 2}
	MetaState.land_decor_placed = []
	var hub := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate()
	add_child(hub)
	for i in 20:
		await get_tree().process_frame
	var ed: LandEdit = hub.get("_edit")
	ed.enter()
	for fr in [["e01-edit-land--place", "place", ""], ["e02-edit-land--placing", "place", "decor_sav_shrub"],
			["e03-edit-land--craft", "craft", ""], ["e04-edit-land--rewards", "rewards", ""], ["e05-edit-land--empty", "empty", ""]]:
		ed._cancel_drag()
		ed._sel_id = ""
		ed._sel_idx = -1
		ed._drop_ghost()
		ed._hide_ring()
		ed._why_tip.visible = false
		if fr[1] == "empty":
			MetaState.land_decor_owned = {}
			ed._set_tab("place")
		else:
			ed._set_tab(fr[1])
		ed.refresh()
		if fr[2] != "":
			ed._pick_stored(fr[2])
			ed._on_motion(Vector2(1000, 760))
		for i in 12:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		Util.save(get_viewport(), fr[0])
	_guard.restore()
	get_tree().quit(0)
