extends "res://tools/sim_balance.gd"
## QA p5 (5/11): scans seeds with the sim's `expert` bot + auto Anchor and reports which runs reach a shop (and buy),
## a Make-room offer (full Core slots) and the boss (won / lost). No game code touched; sim_balance.gd does the playing.
##   AXIE_SKIP_RULES_FINGERPRINT=1 godot/tools/with_lock.sh <Godot> --headless --path godot res://tests/qa_p5_anchor_run.tscn -- --from=1000 --n=40 --team=mixed_std
var room_offers := 0
var room_seen_this_run := false


func _drain_core_offers() -> void:
	if (RunState._core_offer_active or RunState._rule_offer_active) and not RunState.pending_rewards.is_empty():
		for c in RunState.pending_rewards:
			if not bool((c as Dictionary).get("rule", false)):
				var chk := RelicSlots.check_add(RunState.owned_relic_ids, RunState.relic_stickers, String((c as Dictionary)["key"]), RunState.ascension, false)
				if bool(chk["ok"]) and bool(chk["needs_sell"]):
					room_seen_this_run = true
					room_offers += 1
	super._drain_core_offers()


func _ready() -> void:
	var a := {"from": 1000, "n": 40, "team": "mixed_std", "policy": "expert"}
	for s in OS.get_cmdline_user_args():
		if s.begins_with("--") and s.contains("="):
			var kv := s.substr(2).split("=", true, 1)
			a[kv[0]] = kv[1]
	var guard := SaveGuard.new()
	guard.capture()
	_mx_hook()
	_anchor_mode = "auto"
	_stage = 3
	_nohold = true
	var rows: Array[String] = ["seed,anchor,end,nodes,shop_visits,shop_buys,room,boss_fights,boss_won"]
	for i in int(a["n"]):
		var sd := int(a["from"]) + i
		room_seen_this_run = false
		var r := _play_run(sd, String(a["team"]), 0, String(a["policy"]), "random")
		var shops := 0
		var graph := RunMapGraph.from_data(RunState.map_graph)
		for id in RunState.visited_node_ids:
			var nd := graph.find_node(String(id))
			if nd != null and nd.node_type == "shop":
				shops += 1
		var buys := 0
		for e in RunState.action_log.entries:
			if JSON.stringify(e).contains("shop_buy"):
				buys += 1
		var bf := 0
		var bw := 0
		for f in r["fights"]:
			if String((f as Dictionary)["kind"]) == "boss":
				bf += 1
				bw += 1 if bool((f as Dictionary)["won"]) else 0
		rows.append("%d,%s,%s,%d,%d,%d,%d,%d,%d" % [sd, r["anchor"], r["end"], RunState.visited_node_ids.size(), shops, buys, 1 if room_seen_this_run else 0, bf, bw])
	guard.restore()
	for l in rows:
		print("P5ROW ", l)
	get_tree().quit(0)
