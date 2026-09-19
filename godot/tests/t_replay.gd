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

const COMBAT_SEED := 424242
const MAX_TURNS := 200

const EXPECTED_TESTS: Array[String] = [
	"test_the_same_decisions_replay_into_the_same_run",
	"test_a_corrupted_log_replays_into_a_different_run",
	"test_the_log_survives_the_json_round_trip_it_will_travel_as",
	"test_the_log_refuses_what_a_verifier_could_not_replay",
	"test_recording_is_off_while_replaying",
]

var _failures: Array[String] = []
var _checks := 0
var _completed: Array[String] = []


func _ready() -> void:
	print("=== t_replay: start ===")
	await get_tree().process_frame

	test_the_same_decisions_replay_into_the_same_run()
	test_a_corrupted_log_replays_into_a_different_run()
	test_the_log_survives_the_json_round_trip_it_will_travel_as()
	test_the_log_refuses_what_a_verifier_could_not_replay()
	test_recording_is_off_while_replaying()

	for test_name in EXPECTED_TESTS:
		if not _completed.has(test_name):
			_failures.append(("test '%s' did not run to completion — a runtime error aborted it "
				+ "part-way and every assertion after that point was skipped") % test_name)

	print("=== t_replay: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_replay: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_replay: FAIL — %s" % f)
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
	_assert(int(back.header.get("seed", -1)) == 7 and int(back.header.get("ascension", -1)) == 2,
		"the header lost the seed/ascension a replay has to start from")
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
			return engine.reroll_dice(args[0] as Array)
		"undo_last":
			return engine.undo_last()
		"end_turn":
			engine.end_turn()
			return true
		_:
			return false


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


func _play_one_turn(engine: CombatEngine) -> void:
	var guard := 0
	while guard < 64:
		guard += 1
		var acted := false
		for u in engine.party.duplicate():
			if u.hp <= 0 or not u.has_rolled() or u.roll_used():
				continue
			var fi: int = u.roll_face_index()
			var f: Dictionary = u.die[fi]
			var face_type := String(f.get("type", ""))
			var tgt_uid: int = u.uid
			if face_type in ["dmg", "poison", "debuff"]:
				var es: Array = engine.alive_enemies()
				if es.size() > 0:
					tgt_uid = es[0].uid
			if engine.use_die(u.uid, tgt_uid):
				acted = true
		if not acted:
			break
	engine.end_turn()


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
