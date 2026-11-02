extends Node
## UI-06 L3 capture (Drop B): 48-anchor-pick none / picked / locked, 49 awaken moment (end state), ShopCoreCard.
## Not headless: UI6_PROBE_SCALE=1.0 (1920) or 0.6667 (1280) forces the scale (Retina DPR 2), UI6_SHOT_TAG names the files.
## Run: UI6_PROBE_SCALE=1 UI6_SHOT_TAG=1920 godot/tools/shot.sh res://tests/qa_ui06_l3_capture.tscn 1920x1080
var _guard := SaveGuard.new()


func _snap(name: String) -> void:
	var dir := ProjectSettings.globalize_path("res://").path_join("../production/qa/ui06/l3").simplify_path()
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png("%s/%s--%s.png" % [dir, name, OS.get_environment("UI6_SHOT_TAG")])


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _host() -> Control:
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.theme = UI3Theme.get_theme()
	var bg := ColorRect.new()
	bg.color = Color("#4b3a5c")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(bg)
	add_child(host)
	return host


func _pick(ids: Array, reasons: Dictionary, pick: int, name: String) -> void:
	AnchorAdapter.test_state = {"open": true, "offer": ids, "reasons": reasons, "picked": []}
	var host := _host()
	var v := AnchorPick.new()
	host.add_child(v)
	v.setup(ids, true)
	if pick >= 0:
		v.select(pick)
	await _wait(1.5)
	_snap(name)
	host.queue_free()
	await _wait(0.1)


func _ready() -> void:
	_guard.capture()
	var want := OS.get_environment("UI6_PROBE_SCALE")
	UI3Theme.set_scale_override(float(want) if want != "" else 1.0)
	UI3Theme.sync_scale()
	UI3Gacha.instant_override = 1
	await _pick(["a_volley", "a_gambler", "a_kin"], {}, -1, "48-anchor-pick--none")
	await _pick(["a_kin", "a_embers", "a_big_hand"], {}, 0, "48-anchor-pick--picked")
	await _pick(["a_volley", "a_gambler", "a_mana_mine"], {"a_mana_mine": "stage_locked"}, -1, "48-anchor-pick--locked")
	var hc: Array = AnchorAdapter.house_cores("a_volley")
	AnchorAdapter.test_state = {"anchor_id": "a_volley", "awakened": true, "owned": [hc[1], hc[2]]}
	var host := _host()
	UI3Gacha.instant_override = 0
	var fx := AnchorFx.play(host, "a_volley")
	await _wait(1.0)
	fx._show_final()
	await _wait(0.3)
	_snap("49-anchor-awaken--moment")
	host.queue_free()
	AnchorAdapter.test_state = null
	await _run_screens()
	UI3Theme.set_scale_override(-1.0)
	UI3Gacha.instant_override = -1
	_guard.restore()
	get_tree().quit(0)


func _item(key: String, bought: bool) -> Dictionary:
	var def = RelicRegistry.get_def(key)
	return {"kind": "relic", "key": key, "title": String(def.name), "desc": RewardGenerator.relic_desc(def),
		"rar": def.rarity, "cost": RewardGenerator.RELIC_SHOP_COST[clampi(int(def.rarity), 0, 4)], "bought": bought}


func _new_map() -> Node:
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	for _i in 8:
		await get_tree().process_frame
	return m


func _free_map(m: Node) -> void:
	m.queue_free()
	for _i in 3:
		await get_tree().process_frame


## shop, treasure, event, reward, map: one run state, frames named like Drop B data-names.
func _run_screens() -> void:
	ProjectSettings.set_setting("axie/epoch_source", "local")
	RunState.start_new_run_seeded(424242, {"team_keys": ["plant1", "beast1", "aqua1", "reptile1", "bug1"],
		"mode": "short", "ascension": 0, "ranked": false, "rules_on": false})
	RunState.owned_relic_ids.assign(["c_bastion", "c_backline_glow", "r_ironvow"])
	RunState.shards_this_run = 100
	RunState.pending_rewards.assign([])   # no opening Core offer over the map
	RunState.anchor_offer = []
	var m := await _new_map()
	await _wait(0.5)
	_snap("03-run-map--node-icons")
	# boss-next: every node before the last row visited, standing on the last pre-boss node
	var nodes: Array = (RunState.map_graph.get("nodes", []) as Array)
	var last := 0
	for n in nodes:
		last = maxi(last, int((n as Dictionary).get("row", 0)))
	var vis: Array[String] = []
	for n in nodes:
		if int((n as Dictionary).get("row", 0)) < last - 1:
			vis.append(String((n as Dictionary).get("id", "")))
		elif int((n as Dictionary).get("row", 0)) == last - 1 and RunState.current_node_id == "":
			RunState.current_node_id = String((n as Dictionary).get("id", ""))
	RunState.visited_node_ids.assign(vis)
	await _free_map(m)
	m = await _new_map()
	await _wait(0.5)
	_snap("03-run-map--boss-next")
	var a: Array[Dictionary] = [_item("c_bastion", false), _item("c_backline_glow", true),
		{"kind": "heal", "title": "Serum", "desc": "One Axie gains 10 Max HP", "cost": RewardGenerator.HEAL_ITEM_COST, "bought": false, "rar": 0},
		{"kind": "core", "tier": 0, "title": "Core Pick", "desc": "Choose 1 of 3 Moss Cores", "cost": 60, "bought": false, "rar": 0}]
	RunState.shop_items.assign(a)
	m.call("_render_shop")
	await _wait(0.5)
	_snap("shop--stock")
	for k in ContentDB.events.keys():
		RunState.event_key = String(k)
		if RunState.event_options().size() >= 3:
			break
	m.call("_on_event_node", "x")
	await _wait(0.5)
	_snap("event--choices")
	RunState.pending_rewards.assign([
		{"t": "relic", "key": "x0", "rar": 0, "title": "MAX HP", "desc": "Reward one", "sub": "A stand-in reward."},
		{"t": "relic", "key": "x1", "rar": 1, "title": "REROLL", "desc": "Reward two", "sub": "A stand-in reward."},
		{"t": "relic", "key": "x2", "rar": 2, "title": "TIER UP", "desc": "Reward three", "sub": "A stand-in reward."}])
	m.call("_build_treasure", false)
	await _wait(0.5)
	_snap("13-treasure--closed")
	m.call("_build_treasure", true)
	await _wait(0.5)
	_snap("13-treasure--opened")
	await _free_map(m)
	var rng := Rng.new(77)
	var none: Array[Dictionary] = []
	var chaos := RewardGenerator._make_chaos_reward(rng, RunState.owned_relic_ids, none)
	var curse := RewardGenerator._make_curse_reward(none)
	var relics := ["c_thorn_shield", "c_concord"].map(func(id: String) -> Dictionary:   # real Cores (live reward offers are Cores)
		var d = RelicRegistry.get_def(id)
		return {"t": "relic", "key": id, "rar": d.rarity, "title": "RELIC", "desc": d.name, "sub": RewardGenerator.relic_desc(d)})
	for pair in [["reward--pick", [relics[0], relics[1], relics[0]]], ["reward--chaos", [relics[0], chaos, curse]]]:
		RunState.pending_rewards.assign((pair[1] as Array).filter(func(x): return not (x as Dictionary).is_empty()))
		var m2 := await _new_map()
		m2.call("_show_reward_overlay", "CHOOSE ONE REWARD")
		await _wait(0.8)
		_snap(String(pair[0]))
		await _free_map(m2)
	RunState.pending_rewards.assign([])
