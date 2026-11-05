extends "res://tools/sim_balance.gd"
## QA p5 (5/11): replays seed ADT seed (default 1013, mixed_std, expert bot, auto Anchor: see qa_p5_anchor_run.gd) node by node
## and takes real-window shots of: shop, Make room sheet, boss intro, post-boss screen. Needs a window (not --headless):
##   AXIE_P5_SEED=1013 ADT_EVIDENCE_DIR=production/qa/p5-qa godot/tools/shot.sh res://tests/qa_p5_shots.tscn 1920x1080   (and 1280x720)
## The loop is a copy of sim_balance._play_run (same bot rng init) with awaits at the interesting moments.
var _dir := QaPaths.evidence_dir()
var _res := ""
var _done := {}


func _snap(name: String) -> void:
	for _i in 12:
		await get_tree().process_frame
	var p := "%s/%s_%s.png" % [_dir, name, _res]
	get_viewport().get_texture().get_image().save_png(p)
	print("P5SHOT ", p)


func _map() -> Node:
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	for _i in 8:
		await get_tree().process_frame
	return m


func _drain_async() -> void:
	var guard := 0
	while guard < 16 and (RunState._core_offer_active or RunState._rule_offer_active) and not RunState.pending_rewards.is_empty():
		if not _done.has("room"):
			for c in RunState.pending_rewards:
				if bool((c as Dictionary).get("rule", false)):
					continue
				var chk := RelicSlots.check_add(RunState.owned_relic_ids, RunState.relic_stickers, String((c as Dictionary)["key"]), RunState.ascension, false)
				if bool(chk["ok"]) and bool(chk["needs_sell"]):
					_done["room"] = true
					var saved_rewards: Array = RunState.pending_rewards.duplicate(true)
					var m := await _map()
					RunState.pending_rewards = [c]
					m.call("_show_reward_overlay", "CHOOSE A REWARD")
					for _i in 3:
						await get_tree().process_frame
					m.call("_select_reward", 0)
					m.call("_take_selected_reward")
					await _snap("make_room")
					print("P5INFO make room for ", (c as Dictionary).get("key"), " owned=", RunState.owned_relic_ids)
					m.queue_free()
					await get_tree().process_frame
					RunState.pending_rewards = saved_rewards
					break
		guard += 1
		_drain_core_offers()
		break
	_drain_core_offers()


func _ready() -> void:
	var sd := int(OS.get_environment("AXIE_P5_SEED")) if OS.get_environment("AXIE_P5_SEED") != "" else 1013
	_res = "%dx%d" % [get_window().size.x, get_window().size.y]
	DirAccess.make_dir_recursive_absolute(_dir)
	var guard := SaveGuard.new()
	guard.capture()
	_mx_hook()
	_anchor_mode = "auto"
	_stage = 3
	_nohold = true
	_policy = "expert"
	_core_policy = "random"
	_mx_ft = 0.0
	_abl = {}
	_met = {"turns": 0, "dmg": 0.0, "v0": 0.0, "v1": 0.0, "dsq": 0.0, "boss_n": 0, "boss_turns": 0, "boss_won": 0, "boss_hp": 0.0}
	for k in MX_KEYS:
		_met["mx_" + k] = 0.0
	_rng = Rng.new(sd ^ SALT)
	_brng.seed = sd * 7919 + 13
	_fights = []
	_offered = {}
	_core_fired_seen = {}
	_picked = []
	_trig = {}
	_anchor_aw_node = -1
	_anchor_aw_turn = -1
	_anchor_mut = {}
	_turns_total = 0
	_forced_mut = false
	var team: Array[String] = []
	for k in TEAMS["mixed_std"]:
		team.append(String(k))
	_team_keys = team.duplicate()
	var params := {"team_keys": team, "mode": "short", "ascension": 0, "ranked": false, "rules_on": true,
		"newcomer": false, "bonuses": {}, "anchor": true, "depth_stage": _stage}
	RunState.start_run_with_epoch(LocalEpochSource.new(PackedByteArray(), sd), params, sd)
	await _drain_async()
	_poll_anchor(0)
	var graph := RunMapGraph.from_data(RunState.map_graph)
	var node := graph.find_node(graph.start_node_id)
	var walked := 0
	while node != null and walked < MAX_NODES:
		walked += 1
		RunState.enter_node(node.id, node.node_type)
		match node.node_type:
			"battle", "elite", "boss":
				var eng := CombatEngine.new()
				eng.setup_new(RunState.pending_combat)
				if node.node_type == "boss" and not _done.has("boss"):
					_done["boss"] = true
					var intro := BossIntro.new()
					var key := String(RunState.pending_combat.get("boss_key", ""))
					print("P5INFO boss key=", key)
					if intro.setup(key):
						add_child(intro)
						while intro.elapsed_ms < 2000:
							await get_tree().process_frame
						await _snap("boss_intro")
						intro.queue_free()
				var owned_snap: Array = RunState.owned_relic_ids.duplicate()
				_turns_total += _play_combat(eng)
				RunState.apply_combat_result(eng.get_result())
				if node.node_type == "boss":
					var tag := "boss_result_%s" % ("won" if eng.won else "lost")
					if not _done.has(tag):
						_done[tag] = true
						var m2 := await _map()
						await _snap(tag)
						print("P5INFO boss ", "WON" if eng.won else "LOST", " phase=", RunState.phase)
						m2.queue_free()
						await get_tree().process_frame
				if RunState.phase == RunState.RunPhase.PACT:
					_settle_pact()
				if not RunState.pending_rewards.is_empty():
					RunState.apply_chosen_reward(_pick_plain_reward())
			"event":
				var n_opt := RunState.event_options().size()
				if n_opt > 0:
					RunState.choose_event_option(_rng.next_int(n_opt))
			"shop":
				if not _done.has("shop"):
					_done["shop"] = true
					var m3 := await _map()
					RunState.call("_noop") if false else null
					m3.call("_render_shop")
					await _snap("shop")
					print("P5INFO shop items=", RunState.shop_items.size(), " shards=", RunState.shards_this_run)
					m3.queue_free()
					await get_tree().process_frame
				for j in RunState.shop_items.size():
					var ok := RunState.try_buy_shop_item(j)
					print("P5INFO buy ", j, " ", (RunState.shop_items[j] as Dictionary).get("kind"), " ", ok, " owned=", RunState.owned_relic_ids.size())
			"treasure":
				RunState.generate_treasure_rewards(node.id)
				if not RunState.pending_rewards.is_empty():
					RunState.apply_chosen_reward(_pick_plain_reward())
		if RunState.phase == RunState.RunPhase.WON or RunState.phase == RunState.RunPhase.LOST:
			break
		RunState.after_node()
		await _drain_async()
		_poll_anchor(walked)
		if node.next_ids.is_empty():
			break
		node = graph.find_node(String(node.next_ids[_rng.next_int(node.next_ids.size())]))
	print("P5INFO end phase=", RunState.phase, " done=", _done.keys())
	guard.restore()
	get_tree().quit(0)
