extends Node
## THE GATE THE CUTOVER NEEDS: play a fight, write down only what the player decided, then
## rebuild the fight from the seed and those decisions alone — and prove the two end states are
## identical down to the RNG cursor.
##
## The live JS build never trusts a submitted score: `api/submit-run.js` replays the client's
## action list server-side and computes the score from what the replay actually produced. Nothing
## in the Godot port could do that, and that missing piece is the declared gate for letting this
## port replace the live game. Whatever anti-cheat design is chosen later, all of them stand on
## the property this file measures: **same seed + same decisions => same run**. If that is false,
## no amount of signing or server logic can make a score verifiable.
##
## The dispatch table in `_apply()` is deliberately small and explicit. It is the list a future
## verifier must implement, and it is the reason ActionLog keeps an allow-list: an action that
## cannot be replayed must not be recordable in the first place.
##
## NEGATIVE CONTROLS ARE PART OF THE GATE. A comparison that cannot fail proves nothing, so this
## file also corrupts the log on purpose — drops an action, retargets one, swaps two — and
## requires each corruption to produce a DIFFERENT end state. If an injection ever stops making a
## difference, this gate has gone blind and says so.

## Puts the player's real meta and run saves back before quitting (see save_guard.gd).
var _guard := SaveGuard.new()

const COMBAT_SEED := 424242
const MAX_TURNS := 200
## A seed t_full_run_loop walks to the final row, so the recorded run covers combats, rewards,
## and whatever events/shops/treasures the map lays out rather than three fights and a death.
const RUN_SEED := 991237
const MAX_NODES := 40
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]

const EXPECTED_TESTS: Array[String] = [
	"test_the_same_decisions_replay_into_the_same_run",
	"test_a_corrupted_log_replays_into_a_different_run",
	"test_the_log_survives_the_json_round_trip_it_will_travel_as",
	"test_the_log_refuses_what_a_verifier_could_not_replay",
	"test_recording_is_off_while_replaying",
	"test_an_undone_move_replays_like_it_never_happened",
	"test_a_whole_run_is_rebuilt_from_its_log_by_the_referee",
	"test_the_referee_knows_every_action_the_log_can_hold",
	"test_a_stashed_die_replays_and_a_tampered_stash_does_not",
	"test_a_plating_charge_affix_elite_fight_replays_deterministically",
]

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []


func _ready() -> void:
	_guard.capture()
	print("=== t_replay: start ===")
	await get_tree().process_frame

	test_the_same_decisions_replay_into_the_same_run()
	test_a_corrupted_log_replays_into_a_different_run()
	test_the_log_survives_the_json_round_trip_it_will_travel_as()
	test_the_log_refuses_what_a_verifier_could_not_replay()
	test_recording_is_off_while_replaying()
	test_an_undone_move_replays_like_it_never_happened()
	test_a_whole_run_is_rebuilt_from_its_log_by_the_referee()
	test_the_referee_knows_every_action_the_log_can_hold()
	test_a_stashed_die_replays_and_a_tampered_stash_does_not()
	test_a_plating_charge_affix_elite_fight_replays_deterministically()

	for test_name in EXPECTED_TESTS:
		if not _completed.has(test_name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted it "
				+ "part-way and every assertion after that point was skipped") % test_name)

	print("=== t_replay: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_replay: PASS — %d checks OK" % _checks)
		_guard.restore()
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_replay: FAIL — %s" % f)
	_guard.restore()
	get_tree().quit(1)


# ===========================================================================
# The gate
# ===========================================================================

func test_the_same_decisions_replay_into_the_same_run() -> void:
	var log := ActionLog.new()
	log.begin(COMBAT_SEED, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 0, "test")
	var played := _play_recorded(log)

	_assert(log.size() > 0, "the bot played a whole fight and recorded nothing — the log is not "
		+ "wired into CombatEngine, and every other check here would pass vacuously")
	_assert(log.is_complete(),
		"the log reports itself incomplete (overflow=%s, rejected=%s)"
		% [log.overflowed, str(log.rejected)])
	_assert(bool(played["finished"]),
		"the recorded fight never finished, so there is no end state to compare")

	var replay := _replay(log)
	_assert(bool(replay["ok"]), str(replay.get("why", "")))
	_assert(_digest(replay["snapshot"]) == _digest(played["snapshot"]),
		"REPLAY DIVERGED. Same seed, same %d decisions, different end state. Anything built on "
		% log.size() + "top of this log — server verification, signed scores, leaderboards — "
		+ "would be verifying the wrong run.\n  played: %s\n  replayed: %s"
		% [_brief(played["snapshot"]), _brief(replay["snapshot"])])
	# The RNG cursor is the sharpest half of that comparison: two runs can reach the same hit
	# points having consumed different amounts of randomness, and the next action would then
	# diverge. Compared explicitly so a failure names the cause instead of the symptom.
	_assert(int((replay["snapshot"] as Dictionary).get("rng_state", -1))
			== int((played["snapshot"] as Dictionary).get("rng_state", -2)),
		"the replay ended on a different RNG cursor (%s vs %s) — the runs consumed different "
		% [str((replay["snapshot"] as Dictionary).get("rng_state", "?")),
			str((played["snapshot"] as Dictionary).get("rng_state", "?"))]
		+ "randomness even if their visible numbers happen to match")
	print("  replayed %d decisions; end state identical (rng_state=%s)"
		% [log.size(), str((played["snapshot"] as Dictionary).get("rng_state", "?"))])
	_done("test_the_same_decisions_replay_into_the_same_run")


## Three ways to corrupt a log, each of which a cheat would do. Each must change the outcome —
## otherwise the comparison above is not actually reading the log.
func test_a_corrupted_log_replays_into_a_different_run() -> void:
	var log := ActionLog.new()
	log.begin(COMBAT_SEED, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 0, "test")
	var played := _play_recorded(log)
	var honest := _digest(played["snapshot"])

	var use_indices: Array[int] = []
	for i in log.entries.size():
		if String((log.entries[i] as Dictionary).get("fn", "")) == "use_die":
			use_indices.append(i)
	_assert(use_indices.size() >= 2,
		"the recorded fight has fewer than two use_die actions, so these injections cannot be "
		+ "built — the bot or the encounter changed")
	if use_indices.size() < 2:
		_done("test_a_corrupted_log_replays_into_a_different_run")
		return

	var injections := {
		"a dropped action": _without(log, use_indices[0]),
		"a retargeted die": _retargeted(log, use_indices[0]),
		"two actions swapped": _swapped(log, use_indices[0], use_indices[use_indices.size() - 1]),
	}
	for label in injections:
		var tampered: ActionLog = injections[label]
		var out := _replay(tampered)
		# Either the replay refuses the tampered action outright (an illegal move in the state it
		# now lands in) or it finishes somewhere else. Both are detections; finishing in exactly
		# the same place is not.
		var differs: bool = (not bool(out["ok"])) or _digest(out["snapshot"]) != honest
		_assert(differs,
			"injection '%s' replayed to the SAME end state as the honest log. This gate cannot "
			% label + "tell a tampered log from a real one, which is the only thing it is for.")
	_done("test_a_corrupted_log_replays_into_a_different_run")


func test_the_log_survives_the_json_round_trip_it_will_travel_as() -> void:
	var log := ActionLog.new()
	log.begin(7, ["plant1"], "short", 2, "test")
	log.record("use_die", [11, 22])
	log.record("reroll_dice", [[11, 12]])
	log.record("end_turn", [])

	var wire := JSON.stringify(log.to_data())
	var back_data: Dictionary = JSON.parse_string(wire)
	var back := ActionLog.from_data(back_data)
	_assert(back.size() == log.size(), "the log lost entries crossing JSON (%d -> %d)"
		% [log.size(), back.size()])
	_assert(JSON.stringify(back.to_data()) == wire,
		"the log did not survive JSON unchanged — it will travel to a verifier this way, so a "
		+ "field that mutates in transit is a field the verifier reads differently than it was "
		+ "written")
	_assert(int(back.header.get("local_secret", -1)) == 7 and int(back.header.get("ascension", -1)) == 2,
		"the header lost the local secret/ascension a replay has to start from")
	# Nested arrays are the shape most likely to come back wrong (reroll_dice carries one), so
	# it is checked by value rather than trusted to the round trip above.
	var rr: Dictionary = back.entries[1]
	_assert((rr.get("args", []) as Array)[0] == [11, 12],
		"reroll_dice's nested uid array came back as %s" % str((rr.get("args", []) as Array)))
	_done("test_the_log_survives_the_json_round_trip_it_will_travel_as")


func test_the_log_refuses_what_a_verifier_could_not_replay() -> void:
	var log := ActionLog.new()
	log.begin(1, ["plant1"], "short", 0, "test")
	_assert(not log.record("grant_shards", [99999]),
		"an action outside the allow-list was recorded. A log may only contain moves a replay "
		+ "knows how to make; anything else is a claim the verifier has to take on faith")
	_assert(not log.is_complete(),
		"the log still calls itself complete after refusing an action — a caller checking "
		+ "is_complete() would treat a log with a hole in it as evidence")
	_assert(log.size() == 0, "the refused action was recorded anyway")

	var full := ActionLog.new()
	full.begin(1, ["plant1"], "short", 0, "test")
	for i in ActionLog.MAX_ACTIONS + 5:
		full.record("end_turn", [])
	_assert(full.size() == ActionLog.MAX_ACTIONS,
		"the log grew past its own ceiling (%d entries)" % full.size())
	_assert(full.overflowed and not full.is_complete(),
		"a truncated log did not report itself truncated — it would replay to a lower score and "
		+ "read as a losing run rather than as a broken record")
	_done("test_the_log_refuses_what_a_verifier_could_not_replay")


func test_recording_is_off_while_replaying() -> void:
	var log := ActionLog.new()
	log.begin(COMBAT_SEED, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 0, "test")
	_play_recorded(log)

	var watcher := ActionLog.new()
	watcher.begin(COMBAT_SEED, ["plant1"], "short", 0, "test")
	watcher.replaying = true
	var engine := _fresh_engine()
	engine.action_log = watcher
	for e in log.entries:
		_apply(engine, String((e as Dictionary).get("fn", "")), (e as Dictionary).get("args", []))
	_assert(watcher.size() == 0,
		"replaying appended %d entries to the log being replayed. A verifier reading a log while "
		% watcher.size() + "the engine writes into it would grow the very list it is iterating.")
	_done("test_recording_is_off_while_replaying")


## Undo is the one move where a snapshot and an action-replay could disagree without anyone
## noticing, because Godot's undo restores the RNG cursor and the JS build's does not. Nothing
## exercised it: the bot never presses undo, so the whole path was asserted by comment only —
## found by a security review of this file, not by the file itself.
func test_an_undone_move_replays_like_it_never_happened() -> void:
	var log := ActionLog.new()
	log.begin(COMBAT_SEED, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 0, "test")
	var engine := _fresh_engine()
	engine.action_log = log

	# Use a die, take it back, then use a DIFFERENT die. The first move consumed randomness and
	# the undo has to give it back, or the second move lands on a stream the replay cannot find.
	#
	# The moves are chosen the way the bot chooses them — a blank face cannot be spent at all,
	# and a heal aimed at an enemy is refused — so this tests undo rather than accidentally
	# testing targeting rules.
	var moves := _legal_moves(engine)
	_assert(moves.size() >= 2,
		"need two usable party dice to test undo; this roll offered %d" % moves.size())
	if moves.size() < 2:
		_done("test_an_undone_move_replays_like_it_never_happened")
		return

	_assert(engine.use_die(int(moves[0][0]), int(moves[0][1])),
		"the first die refused a target the bot's own rule picked")
	_assert(engine.undo_last(), "undo did nothing after a die was used")
	_assert(engine.use_die(int(moves[1][0]), int(moves[1][1])),
		"the second die refused a target the bot's own rule picked")
	engine.end_turn()
	var played := engine.to_data()

	var kinds: Array[String] = []
	for e in log.entries:
		kinds.append(String((e as Dictionary).get("fn", "")))
	_assert(kinds.has("undo_last"),
		"the undo was not recorded, so a replay would repeat the move it took back: %s"
		% str(kinds))

	var replay := _replay(log)
	_assert(bool(replay["ok"]), str(replay.get("why", "")))
	_assert(_digest(replay["snapshot"]) == _digest(played),
		"a combat containing an undo did not replay to the same state.\n  played: %s\n  replayed: %s"
		% [_brief(played), _brief(replay["snapshot"])])
	_done("test_an_undone_move_replays_like_it_never_happened")


## The whole point, end to end: a RUN — map, combats, rewards, events, shops — rebuilt by
## `RunVerifier` from nothing but the seed and the decisions, scoring itself the way the live
## JS server scores a submitted run today.
func test_a_whole_run_is_rebuilt_from_its_log_by_the_referee() -> void:
	var played := _play_recorded_run(RUN_SEED)
	var log: ActionLog = played["log"]
	_assert(log.size() > 10,
		"the walk recorded only %d actions; a run that short proves nothing" % log.size())
	_assert(log.is_complete(),
		"the run's log reports itself incomplete (overflow=%s, rejected=%s)"
		% [log.overflowed, str(log.rejected)])

	var verdict := RunVerifier.verify(log, played["tape"])
	_assert(bool(verdict["ok"]),
		"the referee refused an honest run: %s — %s (action %s)"
		% [str(verdict["error"]), str(verdict["message"]), str(verdict["action_index"])])
	if not bool(verdict["ok"]):
		_done("test_a_whole_run_is_rebuilt_from_its_log_by_the_referee")
		return

	_assert(int(verdict["score"]) == int(played["score"]),
		"the referee scored %d for a run the game scored %d. This IS the anti-cheat: the score "
		% [int(verdict["score"]), int(played["score"])]
		+ "the server writes to a leaderboard is the one this replay computes.")
	_assert(bool(verdict["won"]) == bool(played["won"]),
		"the referee disagrees about whether the run was won")
	_assert(_run_digest(verdict["state"]) == _run_digest(played["state"]),
		"the rebuilt run differs from the played one somewhere outside the score:\n  played:  %s\n  rebuilt: %s"
		% [_run_brief(played["state"]), _run_brief(verdict["state"])])

	# A tampered run-level log must not score. Bumping a reward pick is the cheapest possible
	# lie — "I took the strong one" — and the referee re-derives the offer, so it either lands
	# on a different reward or on nothing.
	var tampered := _clone(log)
	var bumped := false
	for i in tampered.entries.size():
		var e: Dictionary = tampered.entries[i]
		if String(e.get("fn", "")) == "take_reward":
			e["args"] = [int((e.get("args", []) as Array)[0]) + 1]
			tampered.entries[i] = e
			bumped = true
			break
	if bumped:
		var bad := RunVerifier.verify(tampered, played["tape"])
		_assert((not bool(bad["ok"])) or int(bad["score"]) != int(verdict["score"]),
			"editing which reward was taken changed nothing the referee could see")

	# And a log that admits it is incomplete must be refused before it is even replayed.
	var holed := _clone(log)
	holed.rejected.append("a deliberate hole")
	var refused := RunVerifier.verify(holed, played["tape"])
	_assert(not bool(refused["ok"]) and String(refused["error"]) == RunVerifier.ERR_INCOMPLETE,
		"an incomplete log was accepted (error was '%s')" % str(refused["error"]))

	print("  run seed %d: %d actions, score %d, won=%s — referee agreed"
		% [RUN_SEED, log.size(), int(verdict["score"]), str(verdict["won"])])
	_done("test_a_whole_run_is_rebuilt_from_its_log_by_the_referee")


## An action the log can record but the referee cannot replay is a run that can never be
## scored — and the player would never find out why. The live JS build has exactly this bug
## today: `client.html:4624` lists ten logged verbs in a comment that calls itself "kept in sync
## manually", and there are eleven. `eventDone` is missing from it.
##
## Two lists, one commit apart, is all it takes. This gate refuses to let them separate.
func test_the_referee_knows_every_action_the_log_can_hold() -> void:
	# A real tape, so the probe gets past the "no tape" refusal and reaches the dispatch.
	var tape: Array = (_play_recorded_run(RUN_SEED))["tape"]
	for fn in ActionLog.ALLOWED_FNS:
		var probe := ActionLog.new()
		probe.begin(RUN_SEED, TEAM, "short", 0,
			String(ContentDB.part_faces.get("engineVersion", "")), true)
		# One action, in a state where it is almost certainly illegal. Being REFUSED is fine and
		# expected; being UNKNOWN is the failure — that is the referee saying it has never heard
		# of a move the game can write down.
		probe.entries = [{"fn": fn, "args": _sample_args(fn)}]
		var verdict := RunVerifier.verify(probe, tape)
		_assert(String(verdict["error"]) != RunVerifier.ERR_UNKNOWN_ACTION,
			"the log can record '%s' and the referee does not know what it is. Any run "
			% fn + "containing it can never be scored, and the player is told nothing.")
	_done("test_the_referee_knows_every_action_the_log_can_hold")


## Depth v3 Hold: a stash before end_turn must replay identically (the held die skips the next roll, so a
## replay that forgot it would draw a different rng stream), and a stash of another die must NOT.
func test_a_stashed_die_replays_and_a_tampered_stash_does_not() -> void:
	var log := ActionLog.new()
	log.begin(COMBAT_SEED, TEAM, "short", 0, "test")
	var engine := _fresh_engine()
	engine.action_log = log
	var target := -1
	var other := -1
	for u in engine.party:
		if engine.can_stash((u as Unit).uid):
			if target < 0:
				target = (u as Unit).uid
			elif other < 0:
				other = (u as Unit).uid
	_assert(target >= 0 and other >= 0, "need two stashable dice on this seed")
	if target < 0 or other < 0:
		_done("test_a_stashed_die_replays_and_a_tampered_stash_does_not")
		return
	_assert(engine.stash(target), "stash refused a legal die")
	engine.end_turn()
	var played := engine.to_data()
	var replay := _replay(log)
	_assert(bool(replay["ok"]), str(replay.get("why", "")))
	_assert(_digest(replay["snapshot"]) == _digest(played), "a stash did not replay to the same state")
	var bad := _clone(log)
	var e: Dictionary = bad.entries[0]
	e["args"] = [other]
	bad.entries[0] = e
	var rb := _replay(bad)
	_assert(not bool(rb["ok"]) or _digest(rb["snapshot"]) != _digest(played),
		"a stash of a different die produced the same end state")
	# stash of a unit that cannot be stashed (unknown uid) is refused by the referee
	var junk := _clone(log)
	var e2: Dictionary = junk.entries[0]
	e2["args"] = [999999]
	junk.entries[0] = e2
	_assert(not bool(_replay(junk)["ok"]), "an illegal stash was accepted by the replay")
	_done("test_a_stashed_die_replays_and_a_tampered_stash_does_not")


## Depth v3: an Elite with Plating (R12 everywhere), Charged Strike and a second affix. Everything that is new
## (plating cut, charge cycle, affix B summons, enemy-phase hooks) must replay to the identical end state.
var _charge_events := 0


func _elite_engine() -> CombatEngine:
	var engine := CombatEngine.new()
	engine.setup_new({
		"node_id": "replay_elite", "kind": "elite", "pw": 6, "ascension": 0,
		"roster_snapshot": _synthetic_roster(), "relic_ids": [], "combat_seed": COMBAT_SEED,
		"affix": "charge", "affix2": "swarm", "run_rules": ["R12"],
	})
	return engine


func _count_charge(_a = null, _b = null, _c = null) -> void:
	_charge_events += 1


func test_a_plating_charge_affix_elite_fight_replays_deterministically() -> void:
	var log := ActionLog.new()
	log.begin(COMBAT_SEED, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 0, "test")
	_charge_events = 0
	EventBus.charge_start.connect(_count_charge)
	EventBus.charge_hit.connect(_count_charge)
	var engine := _elite_engine()
	engine.action_log = log
	var turns := 0
	while not (engine.won or engine.lost) and turns < MAX_TURNS:
		RunBot.play_turn(engine)
		turns += 1
	EventBus.charge_start.disconnect(_count_charge)
	EventBus.charge_hit.disconnect(_count_charge)
	var played := engine.to_data()
	_assert(engine.won or engine.lost, "the elite fight never finished")
	_assert(_charge_events > 0, "the fight never showed a charge: the case does not cover Charged Strike")
	_assert(CombatTraits.plating_of(engine, engine.enemies[0]) >= 0 and (engine.run_rules as Array).has("R12"), "R12 is on")
	var rep_engine := _elite_engine()
	var ok := true
	for e in log.entries:
		if not _apply(rep_engine, String(e["fn"]), e["args"]):
			ok = false
			break
	_assert(ok, "the referee rejected a recorded action of the elite fight")
	_assert(_digest(rep_engine.to_data()) == _digest(played), "plating + charge + affix fight DIVERGED on replay")
	_assert(int(rep_engine.to_data().get("rng_state", -1)) == int(played.get("rng_state", -2)), "different rng cursor on replay")
	# tamper: drop one recorded action, the end state must change
	var bad := _without(log, maxi(0, log.entries.size() / 2))
	var rb := _replay_elite(bad)
	_assert(not bool(rb["ok"]) or _digest(rb["snapshot"]) != _digest(played), "a log with a missing action reached the same end state")
	_done("test_a_plating_charge_affix_elite_fight_replays_deterministically")


func _replay_elite(log: ActionLog) -> Dictionary:
	var en := _elite_engine()
	for e in log.entries:
		if not _apply(en, String(e["fn"]), e["args"]):
			return {"ok": false, "snapshot": en.to_data()}
	return {"ok": true, "snapshot": en.to_data()}


## Shapes that match what each action really records, so the probe above fails on "unknown",
## never on "args were the wrong shape".
func _sample_args(fn: String) -> Array:
	match fn:
		"enter_node":
			return ["r0n0", "battle"]
		"use_die":
			return [1, 2]
		"play_active":
			return ["a_bolt", -1]
		"reroll_dice":
			return [[1]]
		"take_reward", "event_choose", "shop_buy":
			return [0]
		"tweak":
			return ["nudge_up", 1, -1]
		"hold_pick":
			return [1]
		"stash":
			return [1]
		"loaded_pick":
			return [1, 0]
		"sell_relic":
			return ["r_claw"]
		"swap_on_full":
			return ["r_claw", "r_horn"]
		"reorder_party":
			return [[1, 2, 3, 4, 5]]
		"continue":
			return [1]
		"shop_refresh":
			return [1]
		"pact_reroll":
			return [0, 1]
		"aid_use":
			return ["delay_clock", 2]
	return []


# ===========================================================================
# Harness
# ===========================================================================

## The bot from t_vertical_slice: always-legal actions, no randomness of its own, so the
## recorded log is a function of the engine's state and nothing else.
func _play_recorded(log: ActionLog) -> Dictionary:
	var engine := _fresh_engine()
	engine.action_log = log
	var turns := 0
	while not (engine.won or engine.lost) and turns < MAX_TURNS:
		_play_one_turn(engine)
		turns += 1
	return {
		"snapshot": engine.to_data(),
		"finished": engine.won or engine.lost,
		"turns": turns,
	}


## Rebuilds the fight from the seed and applies the log, exactly as a verifier would: it knows
## the setup and the decisions, and nothing about what happened.
func _replay(log: ActionLog) -> Dictionary:
	var engine := _fresh_engine()
	for i in log.entries.size():
		var e: Dictionary = log.entries[i]
		var fn := String(e.get("fn", ""))
		var args: Array = e.get("args", [])
		if not _apply(engine, fn, args):
			# The JS server reports the same way — index, action, and the few actions before it,
			# because a rejection three moves after the real divergence is the usual case
			# (submit-run.js:143).
			return {
				"ok": false, "snapshot": engine.to_data(),
				"why": "replay rejected action %d (%s %s); window: %s"
					% [i, fn, str(args), str(log.entries.slice(maxi(0, i - 3), i + 1))],
			}
	return {"ok": true, "snapshot": engine.to_data(), "why": ""}


## The verifier's whole vocabulary. Kept beside ActionLog.ALLOWED_FNS on purpose: if one grows
## and the other does not, a recordable action becomes an unreplayable one.
func _apply(engine: CombatEngine, fn: String, args: Array) -> bool:
	match fn:
		"use_die":
			return engine.use_die(int(args[0]), int(args[1]))
		"play_active":
			return engine.play_active(String(args[0]), int(args[1]))
		"reroll_dice":
			return engine.reroll_dice(args[0] as Array, -1, args.size() > 1 and int(args[1]) != 0)
		"undo_last":
			return engine.undo_last()
		"stash":
			return args.size() >= 1 and engine.stash(int(args[0]))
		"end_turn":
			engine.end_turn()
			return true
		_:
			return false


## The run walker lives in `RunBot` (godot/tools/run_bot.gd) so that this gate and the fixture
## recorder drive the game identically — two bots would be two behaviours, and the day they
## drift this gate passes on a sequence nothing can reproduce.
func _play_recorded_run(seed_value: int) -> Dictionary:
	return RunBot.play_run(seed_value, TEAM)


func _fresh_engine() -> CombatEngine:
	var engine := CombatEngine.new()
	engine.setup_new({
		"node_id": "replay_node",
		"kind": "battle",
		"pw": 2,
		"ascension": 0,
		"roster_snapshot": _synthetic_roster(),
		"relic_ids": [],
		"combat_seed": COMBAT_SEED,
	})
	return engine


func _legal_moves(engine: CombatEngine) -> Array:
	return RunBot.legal_moves(engine)


func _play_one_turn(engine: CombatEngine) -> void:
	RunBot.play_turn(engine)


func _synthetic_roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({
			"persistent_id": i + 1,
			"hero_key": keys[i],
			"tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [],
			"growth": {},
			"bonus_hp": 0,
		})
	return out


# ---- log surgery, for the negative controls -------------------------------

func _clone(source: ActionLog) -> ActionLog:
	var data: Dictionary = JSON.parse_string(JSON.stringify(source.to_data()))
	return ActionLog.from_data(data)


func _without(log: ActionLog, index: int) -> ActionLog:
	var out := _clone(log)
	out.entries.remove_at(index)
	return out


func _retargeted(log: ActionLog, index: int) -> ActionLog:
	var out := _clone(log)
	var e: Dictionary = out.entries[index]
	var args: Array = (e.get("args", []) as Array).duplicate()
	args[1] = int(args[1]) + 1   # a neighbouring uid: still plausible, different outcome
	e["args"] = args
	out.entries[index] = e
	return out


func _swapped(log: ActionLog, a: int, b: int) -> ActionLog:
	var out := _clone(log)
	var tmp: Dictionary = out.entries[a]
	out.entries[a] = out.entries[b]
	out.entries[b] = tmp
	return out


# ---- comparison -----------------------------------------------------------

## The whole end state, canonically. Not a hand-picked field list: the point is to catch a
## divergence nobody predicted, and a curated comparison only catches the ones someone did.
## `undo_stack` is excluded deliberately — it is a scratch buffer cleared at every turn boundary,
## not part of the outcome, and a finished fight's stack is an artefact of the last turn only.
func _digest(snapshot) -> String:
	var d: Dictionary = (snapshot as Dictionary).duplicate(true)
	d.erase("undo_stack")
	return JSON.stringify(d)


## A run's end state, minus the things that are not outcomes. `action_log` is not in to_data()
## at all; `shop_items` carries `bought` flags that ARE outcomes and stay in.
func _run_digest(state) -> String:
	# The replay does not append to the log it reads (replaying = true), so the log itself is not
	# part of "the same run"; everything else, including the epoch tape, must match.
	var d: Dictionary = (state as Dictionary).duplicate(true)
	d.erase("action_log")
	return JSON.stringify(d)


func _run_brief(state) -> String:
	var d: Dictionary = state as Dictionary
	return "phase=%s pw=%s shards=%s relics=%s visited=%s" % [
		str(d.get("phase", "?")), str(d.get("power_level", "?")),
		str(d.get("shards_this_run", "?")),
		str((d.get("owned_relic_ids", []) as Array).size()),
		str((d.get("visited_node_ids", []) as Array).size())]


func _brief(snapshot) -> String:
	var d: Dictionary = snapshot as Dictionary
	return "turn=%s won=%s lost=%s stat=%s rng=%s" % [
		str(d.get("turn", "?")), str(d.get("won", "?")), str(d.get("lost", "?")),
		JSON.stringify(d.get("stat", {})), str(d.get("rng_state", "?"))]


func _done(test_name: String) -> void:
	_completed.append(test_name)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)
