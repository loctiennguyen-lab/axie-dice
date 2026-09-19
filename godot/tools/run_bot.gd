class_name RunBot
extends Object
## An unskilled player that never cheats: it takes only legal actions, in the order the real
## screens take them, and makes no random choices of its own.
##
## It exists so that the replay gate and the fixture recorder drive the game the SAME way. A bot
## living inside one test and copied into a tool is two bots, and the day they drift the gate
## passes on a sequence no recorder can reproduce.
##
## Deliberately bad at the game. It is measuring determinism, not balance — `tools/sim.js` is
## the balance probe.

const MAX_TURNS := 200
const MAX_NODES := 40
const DEFAULT_TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


## Plays a whole run into the live RunState, recording as it goes, and returns
## {log, state, score, won, nodes}. Ranked by default, because an unranked run cannot be
## verified anywhere but on the machine that played it.
static func play_run(seed_value: int, team: Array[String] = DEFAULT_TEAM,
		mode: String = "short", ascension: int = 0) -> Dictionary:
	RunState.start_new_run(seed_value, team, mode, ascension, true)
	var graph := RunMapGraph.from_data(RunState.map_graph)
	var node := graph.find_node(graph.start_node_id)
	var walked := 0
	while node != null and walked < MAX_NODES:
		walked += 1
		RunState.enter_node(node.id, node.node_type)
		match node.node_type:
			"battle", "elite", "boss":
				var engine := CombatEngine.new()
				engine.setup_new(RunState.pending_combat)
				engine.action_log = RunState.action_log
				play_combat(engine)
				RunState.apply_combat_result(engine.get_result())
				if not RunState.pending_rewards.is_empty():
					RunState.apply_chosen_reward(RunState.pending_rewards[0])
			"event":
				if not RunState.event_options().is_empty():
					RunState.choose_event_option(0)
			"shop":
				for i in RunState.shop_items.size():
					RunState.try_buy_shop_item(i)
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
	return {
		"log": RunState.action_log,
		"state": RunState.to_data(),
		"score": RunState.compute_run_xp(won),
		"won": won,
		"nodes": walked,
	}


static func play_combat(engine: CombatEngine) -> int:
	var turns := 0
	while not (engine.won or engine.lost) and turns < MAX_TURNS:
		play_turn(engine)
		turns += 1
	return turns


static func play_turn(engine: CombatEngine) -> void:
	var guard := 0
	while guard < 64:
		guard += 1
		var acted := false
		for move in legal_moves(engine):
			if engine.use_die(int(move[0]), int(move[1])):
				acted = true
		if not acted:
			break
	engine.end_turn()


## Every (unit, target) pair that is legal right now. A blank face cannot be spent at all and a
## heal aimed at an enemy is refused, so a caller that ignores this and targets everything at
## the first enemy is testing targeting rules by accident.
static func legal_moves(engine: CombatEngine) -> Array:
	var out: Array = []
	for u in engine.party:
		if u.hp <= 0 or not u.has_rolled() or u.roll_used():
			continue
		var fi: int = u.roll_face_index()
		if fi < 0:
			continue
		var f: Dictionary = u.die[fi]
		var face_type := String(f.get("type", ""))
		if face_type == "blank":
			continue
		var tgt: int = u.uid
		if face_type in ["dmg", "poison", "debuff"]:
			var es: Array = engine.alive_enemies()
			if es.is_empty():
				continue
			tgt = es[0].uid
		out.append([u.uid, tgt])
	return out
