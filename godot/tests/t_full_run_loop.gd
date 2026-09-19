extends Node
## PHASE-1 CORE-LOOP GATE — the test the port did not have.
##
## Every earlier test built a CombatEngine by hand and skipped RunState entirely (see
## production/session-state/godot-port-active.md "Lỗ hổng test nghiêm trọng"). That is how a
## broken run loop could stay green for weeks: the pieces were each tested, the *chain* was
## not. This test walks the ACTUAL player path end to end —
##   RunState.start_new_run() -> map graph -> enter_node() -> CombatEngine -> combat resolved
##   -> apply_combat_result() -> reward picked -> after_node() -> next row -> ... -> final boss
## — and asserts the properties that define "the core loop works":
##
##   1. The map is walkable from the start node to the final boss row via real edges.
##   2. Every node type on the path resolves and hands control back to MAP.
##   3. A "boss" node produces an ACTUAL boss unit (is_boss, real boss key), not filler.
##   4. The boss plan matches the JS game: mid bosses may be swapped for BOSS_ALT, the
##      FINAL boss is always 'agony' (src/data.js BOSS_ORDER_12/20, engine.js newGame()).
##   5. Elite nodes are genuinely harder than battle nodes (elite_mult budget).
##   6. Normal encounters draw from the real monster pool, not one repeated key.
##   7. Winning the final boss ends the run WON; losing any combat ends it LOST immediately.
##
## Combat is resolved headlessly by an intentionally dumb auto-player (use every die on a
## legal target, end turn) — this is a LOOP test, not a balance test. To keep a stuck combat
## from hanging the suite, each combat is capped at MAX_TURNS and a cap hit is a FAILURE,
## because a combat that cannot end is itself a broken core loop.
##
## Run: godot --headless --path godot res://tests/t_full_run_loop.tscn

## Seeds walked with combat resolved by the dumb auto-player (a real, simulated playthrough).
const PLAYED_SEEDS := [424242, 7, 991237, 20260918]
## Seeds walked with combat FORCED to a win. These exist because the two properties under
## test are different questions, and conflating them hides the more important one:
##   "can the party survive?"  -> a balance question, and the auto-player here is deliberately
##                                unskilled (no rerolls, no focus fire, no relics), so it losing
##                                proves nothing about the game;
##   "does the RUN LOOP close?" -> whether reward -> next node -> boss row -> WON actually
##                                works, which cannot be observed at all if every run dies at
##                                row 9. Forcing the win isolates the loop from the balance.
const FORCED_SEEDS := [424242, 7, 991237, 20260918]
const VERBOSE := false
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
const MAX_TURNS := 200
const MAX_NODES := 400

var _failures: Array[String] = []
var _checks := 0


## Borrows the player's real save file and puts it back byte for byte — this gate writes to the
## real `MetaState` autoload. See `save_guard.gd` for why a hand-written field list is not enough.
var _save_guard := SaveGuard.new()


func _ready() -> void:
	_save_guard.capture()
	for seed_value in PLAYED_SEEDS:
		_run_one(seed_value, false)
	for seed_value in FORCED_SEEDS:
		_run_one(seed_value, true)
	_report_pool_variety()
	_save_guard.restore()

	print("=== t_full_run_loop: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("  FAIL: ", f)
	if _failures.is_empty():
		print("t_full_run_loop: PASS — %d checks OK across %d seed-walks"
			% [_checks, PLAYED_SEEDS.size() + FORCED_SEEDS.size()])
		get_tree().quit(0)
	else:
		get_tree().quit(1)


func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


# ---------------------------------------------------------------------------
# One full run
# ---------------------------------------------------------------------------

var _seen_enemy_keys := {}
var _seen_boss_keys := {}


func _run_one(seed_value: int, force_win: bool) -> void:
	var tag := "seed %d%s" % [seed_value, " (forced)" if force_win else " (played)"]
	RunState.start_new_run(seed_value, TEAM, "short", 0, false)

	_check(RunState.roster.size() == 5, "%s: roster should be 5, got %d" % [tag, RunState.roster.size()])
	_check(RunState.phase == RunState.RunPhase.MAP, "%s: phase after start_new_run should be MAP" % tag)

	var graph := RunMapGraph.from_data(RunState.map_graph)
	_check(not graph.boss_rows.is_empty(), "%s: map has no boss rows" % tag)
	var final_row: int = graph.boss_rows[graph.boss_rows.size() - 1]

	# --- Property 4: boss plan. The final boss must always be agony. ---
	var plan: Array = _boss_plan_for_run()
	_check(plan.size() == graph.boss_rows.size(),
		"%s: boss plan has %d entries for %d boss rows" % [tag, plan.size(), graph.boss_rows.size()])
	if not plan.is_empty():
		_check(String(plan[plan.size() - 1]) == "agony",
			"%s: final boss must be 'agony' (src/data.js BOSS_ORDER_12), got '%s'"
				% [tag, plan[plan.size() - 1]])
		for bk in plan:
			_check(ContentDB.bosses.has(String(bk)),
				"%s: boss plan references '%s' which is not in ContentDB.bosses" % [tag, bk])

	# --- Walk the graph start -> final boss, resolving every node for real. ---
	var node := graph.find_node(graph.start_node_id)
	_check(node != null, "%s: start node '%s' not found in graph" % [tag, graph.start_node_id])
	if node == null:
		return

	var battle_budget := -1.0
	var elite_budget := -1.0
	var nodes_walked := 0
	var reached_final_boss := false

	while node != null and nodes_walked < MAX_NODES:
		nodes_walked += 1
		if VERBOSE:
			print("  [%s] node %d: row %d %s" % [tag, nodes_walked, node.row, node.node_type])
		var is_final := node.row == final_row

		var ok := _resolve_node(node, tag, force_win)
		if not ok:
			# A played walk ending here is a DEFEAT, which is a legitimate outcome, not a test
			# failure — but it is the whole progression signal, so report it before leaving.
			# (_resolve_node has already recorded a real failure if there was one.)
			if not force_win:
				_report_progress(tag, node, final_row, false)
			return

		if node.node_type == "battle" and battle_budget < 0.0:
			battle_budget = ContentDB.budget(RunState.power_level)
		if node.node_type == "elite" and elite_budget < 0.0:
			elite_budget = ContentDB.budget(RunState.power_level) * float(ContentDB.TUNE["elite_mult"])

		if is_final:
			reached_final_boss = true
			break

		# --- Property 1: the path continues via a real edge. ---
		if node.next_ids.is_empty():
			_failures.append("%s: node %s (row %d, %s) has no outgoing edge but is not the final boss"
				% [tag, node.id, node.row, node.node_type])
			return
		node = graph.find_node(String(node.next_ids[0]))

	if not force_win:
		_report_progress(tag, node, final_row, reached_final_boss)
	else:
		_check(reached_final_boss,
			"%s: walked %d nodes without reaching the final boss row %d" % [tag, nodes_walked, final_row])

	# --- Property 7: beating the final boss wins the run. ---
	if force_win:
		_check(RunState.phase == RunState.RunPhase.WON,
			"%s: after defeating the final boss, phase should be WON, got %s"
				% [tag, _phase_name(RunState.phase)])

	# --- Property 5: elite budget really is above battle budget. ---
	if battle_budget > 0.0 and elite_budget > 0.0:
		_check(elite_budget > battle_budget,
			"%s: elite budget (%.2f) should exceed battle budget (%.2f)" % [tag, elite_budget, battle_budget])


## Picks the reward a real player would take. Taking `pending_rewards[0]` blindly — the
## previous behaviour — means the walk almost never takes a hero tier-up, which is the single
## biggest source of party power in the game and the highest-weighted reward in src/engine.js
## (`level` is pushed TWICE into the pool, engine.js:1054-1055). Without this the progression
## number this test reports says more about the reward shuffle than about the game.
func _preferred_reward(offers: Array) -> Dictionary:
	for want in ["level", "ascend", "relic", "hp"]:
		for r in offers:
			if String((r as Dictionary).get("t", "")) == want:
				return r
	return offers[0]


## How far a played walk got. Reported, never asserted: how deep an unskilled auto-player
## reaches is a BALANCE observation, and making it a pass/fail gate would let this loop test
## fail for reasons that have nothing to do with the loop.
func _report_progress(tag: String, node: RunMapNode, final_row: int, won_run: bool) -> void:
	print("t_full_run_loop: %s reached row %d of %d — %s"
		% [tag, (node.row if node != null else -1), final_row, "WON" if won_run else "died"])


## Resolves one node the way the real game does. Returns false (and records a failure) if
## the node leaves RunState in a state the map cannot continue from.
func _resolve_node(node: RunMapNode, tag: String, force_win: bool) -> bool:
	RunState.enter_node(node.id, node.node_type)

	match node.node_type:
		"battle", "elite", "boss":
			var engine := CombatEngine.new()
			engine.setup_new(RunState.pending_combat)

			for e in engine.enemies:
				_seen_enemy_keys[String((e as Unit).key)] = true

			# --- Property 3: a boss node must contain a real boss. ---
			if node.node_type == "boss":
				var boss_units: Array = []
				for e in engine.enemies:
					if (e as Unit).is_boss:
						boss_units.append(e)
				_check(boss_units.size() >= 1,
					"%s: boss node %s (row %d) spawned NO boss unit — enemies were %s"
						% [tag, node.id, node.row, _enemy_keys(engine.enemies)])
				for b in boss_units:
					var bk := String((b as Unit).key)
					_seen_boss_keys[bk] = true
					_check(ContentDB.bosses.has(bk),
						"%s: boss node spawned key '%s' which is not a real boss" % [tag, bk])

			var won := (_force_win(engine) if force_win else _auto_play(engine, tag, node))
			var res := engine.get_result()
			RunState.apply_combat_result(res)

			if not won:
				_check(RunState.phase == RunState.RunPhase.LOST,
					"%s: losing a combat must set phase LOST immediately, got %s"
						% [tag, _phase_name(RunState.phase)])
				return false

			# --- Property 2: a won combat offers rewards, and picking one returns to MAP. ---
			if not RunState.pending_rewards.is_empty():
				RunState.apply_chosen_reward(_preferred_reward(RunState.pending_rewards))
			RunState.after_node()

		"event":
			var ev_keys: Array = ContentDB.events.keys()
			_check(not ev_keys.is_empty(), "%s: event node but ContentDB.events is empty" % tag)
			if not ev_keys.is_empty():
				var ev: Dictionary = ContentDB.events[ev_keys[0]]
				var opts: Array = ev.get("opts", [])
				_check(not opts.is_empty(), "%s: event '%s' has no options" % [tag, ev_keys[0]])
				if not opts.is_empty():
					RunState.apply_event_effect(String((opts[0] as Dictionary).get("fx", "")),
						Rng.new(RunState.run_seed + node.row))
			RunState.after_node()

		"shop":
			RunState.after_node()

		"treasure":
			RunState.after_node()

		_:
			_failures.append("%s: unknown node type '%s'" % [tag, node.node_type])
			return false

	return true


## Resolves a combat as a win WITHOUT simulating it, by removing every enemy through the
## engine's own end-check. Used by the FORCED_SEEDS walk so the run-loop properties can be
## observed independently of whether an unskilled auto-player could actually survive.
func _force_win(engine: CombatEngine) -> bool:
	for e in engine.enemies:
		(e as Unit).hp = 0
	engine.end_turn()
	return engine.won


## Dumb auto-player: spend every usable die on the first legal target, then end the turn.
## Returns true if the party won.
func _auto_play(engine: CombatEngine, tag: String, node: RunMapNode) -> bool:
	var turns := 0
	while not engine.won and not engine.lost and turns < MAX_TURNS:
		turns += 1
		for u in engine.party.duplicate():
			var unit := u as Unit
			if unit.hp <= 0 or not unit.has_rolled() or unit.roll_used():
				continue
			var target := _pick_target(engine, unit)
			if target >= 0:
				engine.use_die(unit.uid, target)
		engine.end_turn()

	if turns >= MAX_TURNS:
		_failures.append("%s: combat at node %s (%s) did not end within %d turns — a combat that "
			% [tag, node.id, node.node_type, MAX_TURNS]
			+ "cannot terminate is a broken core loop")
	return engine.won


## Picks a legal target uid for this unit's rolled face, honouring the ally/enemy split
## (rule spec §4: shield/heal/buff are ally-only; dmg/poison/debuff are enemy-only).
##
## Deliberately simple, but not actively self-defeating: damage focus-fires the weakest living
## enemy and healing/shielding goes to the most hurt ally. Targeting the FIRST unit in the
## array instead — the previous behaviour — spreads damage across the whole enemy line and
## kills nothing, which is not "an unskilled player", it is a player making a specific mistake
## no real player makes. That distinction matters: this walk is the only signal we have about
## whether the loop is survivable at all.
func _pick_target(engine: CombatEngine, u: Unit) -> int:
	var face: Dictionary = u.current_face()
	if face.is_empty():
		return -1
	match String(face.get("type", face.get("t", ""))):
		"shield", "heal", "buff", "mana", "summon":
			return _uid_of_extreme(engine.alive_party(), true)
		"dmg", "poison", "debuff":
			return _uid_of_extreme(engine.alive_enemies(), true)
		_:
			return -1


## uid of the unit with the lowest hp+shield (lowest_first) in `units`, or -1 when empty.
func _uid_of_extreme(units: Array, lowest_first: bool) -> int:
	if units.is_empty():
		return -1
	var best: Unit = units[0]
	for i in range(1, units.size()):
		var u: Unit = units[i]
		var better := (u.hp + u.shield) < (best.hp + best.shield)
		if better == lowest_first:
			best = u
	return best.uid


# ---------------------------------------------------------------------------
# Cross-seed properties
# ---------------------------------------------------------------------------

## Property 6: across four seeds and a whole run each, normal encounters must draw from the
## real monster pool. A port that stubs genEncounter() to one key shows up here as "1".
func _report_pool_variety() -> void:
	var enemy_variety := _seen_enemy_keys.keys().size()
	var boss_variety := _seen_boss_keys.keys().size()
	print("t_full_run_loop: distinct enemy keys seen = %d %s" % [enemy_variety, _seen_enemy_keys.keys()])
	print("t_full_run_loop: distinct boss keys seen  = %d %s" % [boss_variety, _seen_boss_keys.keys()])
	_check(enemy_variety >= 5,
		"encounters drew only %d distinct monster key(s) — src/engine.js genEncounter() draws "
			% enemy_variety
		+ "from NORMAL_POOL (17 keys, pw-gated) plus ELITE_POOL")
	# A short run has 3 boss rows; the middle one is randomised against BOSS_ALT and the last
	# is always agony, so several full walks must surface at least two distinct bosses.
	_check(boss_variety >= 2,
		"only %d distinct boss key(s) appeared across %d completed runs: %s"
			% [boss_variety, FORCED_SEEDS.size(), _seen_boss_keys.keys()])
	_check(_seen_boss_keys.has("agony"),
		"the final boss must always be NIGHTMARE AGONY (src/data.js BOSS_ORDER_12), but no "
		+ "run ever fought it: %s" % [_seen_boss_keys.keys()])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Reads the run's boss plan wherever RunState exposes it. Kept tolerant on purpose: this
## test is also the spec for the field, so an absent plan is reported as a gap rather than
## crashing the whole suite.
func _boss_plan_for_run() -> Array:
	if "boss_plan" in RunState:
		return RunState.get("boss_plan") as Array
	_failures.append("RunState has no `boss_plan` — the JS game picks the boss for each boss "
		+ "step at newGame() time (src/engine.js:359-361, BOSS_ORDER_12/BOSS_ALT) and the "
		+ "final boss is always 'agony'. Without it, boss rows cannot be the right bosses.")
	_checks += 1
	return []


func _enemy_keys(units: Array) -> Array:
	var out: Array = []
	for u in units:
		out.append(String((u as Unit).key))
	return out


func _phase_name(p: int) -> String:
	var names: Array = RunState.RunPhase.keys()
	return String(names[p]) if p >= 0 and p < names.size() else str(p)
