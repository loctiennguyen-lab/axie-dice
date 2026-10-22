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
## Test hook: >= 0 makes the bot pay one Aid R5 swap on that Pact card before taking card 0.
static var swap_pact_slot: int = -1


## Core test hook: when true the bot rerolls card 0 of its first Core offer, and sells the first sellable Core when the
## slots are full (depth v3 lane B). Off: it just takes card 0.
static var core_script: bool = false
static var _core_rerolled: bool = false
## Core test hook: when set, drain_core_offers() takes the Core card with this id whenever it is on offer (else card 0).
static var core_pick_id: String = ""
## Gacha test hook: when true drain_core_offers() takes a Core card that completes a combo Pair/Full, else a card that belongs to
## some combo, else card 0 (so a seed walk can assemble combos through the real take_reward path).
static var combo_script: bool = false


## Takes every Core / Run Rule offer that is open (a pick can open the next one), calling after_node() as the screens do.
## Anchor test hook: -2 = the bot ignores Anchors (old behaviour); -1 = decline; 0..2 = pick that card of the offer.
static var anchor_pick_index: int = -2


static func drain_core_offers() -> void:
	var guard := 0
	while guard < 16:
		if RunState._anchor_waiting and anchor_pick_index > -2:
			guard += 1
			if not RunState.replay_pick_anchor(anchor_pick_index):
				break
			continue
		if not ((RunState._core_offer_active or RunState._rule_offer_active) and not RunState.pending_rewards.is_empty()):
			break
		guard += 1
		if core_script and not _core_rerolled and RunState._core_offer_active and RunState.core_can_reroll(0):
			_core_rerolled = true
			RunState.reroll_pending_rewards(-1, 0)
		var card: Dictionary = RunState.pending_rewards[0]
		if core_pick_id != "":
			for c in RunState.pending_rewards:
				if String((c as Dictionary).get("key", "")) == core_pick_id:
					card = c
		if combo_script and RunState._core_offer_active:
			card = _combo_card(RunState.pending_rewards, card)
		var sell := ""
		if not bool(card.get("rule", false)):
			var chk := RelicSlots.check_add(RunState.owned_relic_ids, RunState.relic_stickers, String(card["key"]), RunState.ascension, false)
			if bool(chk["ok"]) and bool(chk["needs_sell"]) and core_script:
				sell = String((chk["sell_from"] as Array)[0])
		if not RunState.apply_chosen_reward(card, sell):
			break
		RunState.after_node()


static func _combo_card(cards: Array, fallback: Dictionary) -> Dictionary:
	var owned := RunState.combo_owned_ids()
	for c in cards:
		if not bool((c as Dictionary).get("rule", false)) and not CoreCombos.card_completes(owned, String(c["key"])).is_empty():
			return c
	for c in cards:
		var k := String((c as Dictionary).get("key", ""))
		for r in CoreCombos.all(owned):
			if CoreCombos.members(r).has(k):
				return c
	return fallback


static func play_run(seed_value: int, team: Array[String] = DEFAULT_TEAM,
		mode: String = "short", ascension: int = 0, extra: Dictionary = {}) -> Dictionary:
	if extra.is_empty():
		RunState.start_new_run(seed_value, team, mode, ascension, true)
	else:
		# Non-default start (Anchor tests): `extra` is merged into the run params; ranked defaults to false here.
		var params := {"team_keys": team.duplicate(), "mode": mode, "ascension": ascension, "ranked": false}
		params.merge(extra, true)
		RunState.start_run_with_epoch(LocalEpochSource.new(PackedByteArray(), seed_value), params, seed_value)
	_core_rerolled = false
	drain_core_offers()
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
				if RunState.phase == RunState.RunPhase.PACT and swap_pact_slot >= 0 and RunState.pact_swap_possible(swap_pact_slot):
					RunState.reroll_pact_slot(swap_pact_slot)
				if RunState.phase == RunState.RunPhase.PACT and not RunState.take_pact(0):
					RunState.skip_pact()
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
		drain_core_offers()
		if node.next_ids.is_empty():
			break
		node = graph.find_node(String(node.next_ids[0]))

	var won := RunState.phase == RunState.RunPhase.WON
	return {
		"log": RunState.action_log,
		"tape": RunState.epoch.tape() if RunState.epoch != null else [],
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
	if overcast_script:
		try_overcast(engine)
	if wild_script:
		try_wild(engine)
	var guard := 0
	while guard < 64:
		guard += 1
		var acted := false
		for move in legal_moves(engine):
			if engine.use_die(int(move[0]), int(move[1])):
				acted = true
				if wild_script:
					try_wild(engine)
		if not acted:
			break
	if wild_script:
		try_wild(engine)
	engine.end_turn()


## Depth v4 test hook: when true the bot takes one Overcast (on any Set member) at the start of each turn when it can.
static var overcast_script: bool = false


## Takes the first legal Overcast, if any. Returns true when one was taken (and so logged).
static func try_overcast(engine: CombatEngine) -> bool:
	for u in engine.party:
		if engine.overcast((u as Unit).uid):
			return true
	return false


## Depth v4 test hook: when true the bot takes one Mat Tam (wild_face) per turn the moment any (die, slot) is legal.
static var wild_script: bool = false


## Takes the first legal Mat Tam, if any. Returns true when one was taken (and so logged).
static func try_wild(engine: CombatEngine) -> bool:
	if engine.wild_used >= engine.wild_per_battle() or engine.mana < engine.wild_cost():
		return false
	for u in engine.party:
		for slot in 6:
			if engine.wild_face((u as Unit).uid, slot):
				return true
	return false


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
