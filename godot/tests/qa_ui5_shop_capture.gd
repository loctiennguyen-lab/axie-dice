extends Node
## QA-only, UI-05 b23 lane R5a: shots of shop--stock / --sold-out / --cant-afford. Scale pinned from the window.
##   ADT_EVIDENCE_DIR=production/qa/ui05-b23/r5a godot/tools/shot.sh res://tests/qa_ui5_shop_capture.tscn 1280x720
var _guard := SaveGuard.new()
var _dir := QaPaths.evidence_dir()


func _shot(frame: String, small: bool) -> void:
	for _i in 10:
		await get_tree().process_frame
	var path := "%s/%s%s.png" % [_dir, frame, "--1280" if small else ""]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui5_shop_capture: saved ", path)


func _item(key: String, bought: bool) -> Dictionary:
	var def = RelicRegistry.get_def(key)
	return {"kind": "relic", "key": key, "title": String(def.name), "desc": RewardGenerator.relic_desc(def),
		"rar": def.rarity, "cost": RewardGenerator.RELIC_SHOP_COST[clampi(int(def.rarity), 0, 4)], "bought": bought}


func _supplies(sold_core: bool) -> Array:
	return [
		{"kind": "heal", "title": "Serum", "desc": "One Axie gains 10 Max HP", "cost": RewardGenerator.HEAL_ITEM_COST, "bought": false, "rar": 0},
		{"kind": "reroll", "title": "Instinct", "desc": "1 extra maximum Reroll", "cost": RewardGenerator.REROLL_ITEM_COST, "bought": false, "rar": 0},
		{"kind": "core", "tier": 0, "title": "Core Pick", "desc": "Choose 1 of 3 Moss Cores (after you leave the shop)", "cost": 60, "bought": sold_core, "rar": 0},
	]


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_dir)
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(796, team, "short", 0, false)
	RunState.owned_relic_ids.assign(["c_bastion", "c_backline_glow", "r_ironvow"])
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	for _i in 8:
		await get_tree().process_frame
	var a: Array[Dictionary] = [_item("c_bastion", false), _item("c_backline_glow", false)]
	a.append_array(_supplies(false))
	RunState.shards_this_run = 100
	RunState.shop_items.assign(a)
	m.call("_render_shop")
	await _shot("shop--stock", small)
	var b: Array[Dictionary] = [_item("c_bastion", true), _item("c_backline_glow", false)]
	b.append_array(_supplies(true))
	RunState.shards_this_run = 25
	RunState.shop_items.assign(b)
	m.call("_render_shop")
	await _shot("shop--sold-out", small)
	RunState.shards_this_run = 10
	m.call("_render_shop")
	await _shot("shop--cant-afford", small)
	_guard.restore()
	get_tree().quit(0)
