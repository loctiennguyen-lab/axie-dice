extends Node
## THROWAWAY probe (prototype standards): how many Gene Shard does a run produce?
## Same loop as tools/run_bot.gd (legal moves only, first branch every time), plus bookkeeping.
## Writes to the real save via RunState.end_run(): back up user data before running.
##   godot --headless --path godot res://prototypes/economy_probe/probe_shards.tscn -- --mode=short --seeds=40 --shop=none

const REWARD := {"battle": 25, "elite": 45, "boss": 90}


func _ready() -> void:
	var mode := "short"
	var seeds := 40
	var shop := "none"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			mode = a.get_slice("=", 1)
		elif a.begins_with("--seeds="):
			seeds = int(a.get_slice("=", 1))
		elif a.begins_with("--shop="):
			shop = a.get_slice("=", 1)
	var rows: Array = []
	for s in range(1, seeds + 1):
		rows.append(_play(1000 + s * 7919, mode, shop))
	_report(rows, mode, shop)
	get_tree().quit()


func _play(seed_value: int, mode: String, shop: String) -> Dictionary:
	RunState.start_new_run(seed_value, RunBot.DEFAULT_TEAM, mode, 0, false)
	var graph := RunMapGraph.from_data(RunState.map_graph)
	# Node types on the whole first-branch path, fought or not: what a full clear would pay.
	var path_types: Array = []
	var n := graph.find_node(graph.start_node_id)
	while n != null:
		path_types.append(n.node_type)
		if n.next_ids.is_empty():
			break
		n = graph.find_node(String(n.next_ids[0]))
	var full_clear := 0
	for t in path_types:
		full_clear += int(REWARD.get(t, 0))

	var combat := 0
	var event := 0
	var spent := 0
	var fights := 0
	var node := graph.find_node(graph.start_node_id)
	var walked := 0
	while node != null and walked < RunBot.MAX_NODES:
		walked += 1
		RunState.enter_node(node.id, node.node_type)
		var before := RunState.shards_this_run
		match node.node_type:
			"battle", "elite", "boss":
				var engine := CombatEngine.new()
				engine.setup_new(RunState.pending_combat)
				engine.action_log = RunState.action_log
				RunBot.play_combat(engine)
				RunState.apply_combat_result(engine.get_result())
				combat += RunState.shards_this_run - before
				fights += 1
				if not RunState.pending_rewards.is_empty():
					RunState.apply_chosen_reward(RunState.pending_rewards[0])
			"event":
				if not RunState.event_options().is_empty():
					RunState.choose_event_option(0)
				event += RunState.shards_this_run - before
			"shop":
				if shop == "all":
					for i in RunState.shop_items.size():
						RunState.try_buy_shop_item(i)
				spent += before - RunState.shards_this_run
			"treasure":
				RunState.generate_treasure_rewards(node.id)
				if not RunState.pending_rewards.is_empty():
					RunState.apply_chosen_reward(RunState.pending_rewards[0])
		if RunState.phase == RunState.RunPhase.WON or RunState.phase == RunState.RunPhase.LOST:
			break
		RunState.after_node()
		if node.next_ids.is_empty():
			break
		node = graph.find_node(String(node.next_ids[0]))
	var won := RunState.phase == RunState.RunPhase.WON
	var counts := {}
	for t in path_types:
		counts[t] = int(counts.get(t, 0)) + 1
	return {"won": won, "nodes": walked, "fights": fights, "combat": combat, "event": event,
		"spent": spent, "net": RunState.shards_this_run, "full_clear": full_clear, "path": counts,
		"xp": RunState.compute_run_xp(won)}


func _report(rows: Array, mode: String, shop: String) -> void:
	var wins := rows.filter(func(r): return r["won"])
	var losses := rows.filter(func(r): return not r["won"])
	print("PROBE mode=%s shop=%s runs=%d wins=%d" % [mode, shop, rows.size(), wins.size()])
	for label in ["all", "wins", "losses"]:
		var group: Array = rows if label == "all" else (wins if label == "wins" else losses)
		if group.is_empty():
			continue
		var line := "PROBE %-6s n=%2d" % [label, group.size()]
		for k in ["nodes", "fights", "combat", "event", "spent", "net", "full_clear", "xp"]:
			var sum := 0.0
			for r in group:
				sum += float(r[k])
			line += "  %s=%.0f" % [k, sum / group.size()]
		print(line)
	var agg := {}
	for r in rows:
		for t in r["path"]:
			agg[t] = int(agg.get(t, 0)) + int(r["path"][t])
	var comp := ""
	for t in agg:
		comp += "%s=%.1f " % [t, float(agg[t]) / rows.size()]
	print("PROBE path composition per run (first branch): ", comp)
