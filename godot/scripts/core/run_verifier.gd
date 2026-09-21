class_name RunVerifier
extends Object
## The referee. Rebuilds a whole run from its seed and its action log, and computes the score
## from what the replay actually produced — never from anything the client claimed.
##
## This is the Godot equivalent of `api/submit-run.js`, and deliberately the same shape: that
## file loads the real `src/engine.js` into a Node VM and replays; this loads nothing, because
## it already IS the real rules. One implementation, so the referee can never drift from the
## game (the failure mode that killed the "re-implement it in TypeScript" option — see
## ADR-0004).
##
## WHERE THIS RUNS
## ---------------
## Anywhere a Godot build runs: inside the game (as a test gate, which is how `t_replay` uses
## it) and headless on a server (`godot/tools/verify_run.gd`). A Vercel Function cannot run it;
## that hosting consequence is the whole content of ADR-0004.
##
## IT TAKES OVER `RunState`
## ------------------------
## Verification replays into the live `RunState` singleton, because that singleton IS the rules.
## In the server build nothing else is using it. In a test, whatever was there is gone
## afterwards — call `RunState.reset()` and rebuild if you needed it.
##
## ONLY RANKED RUNS CAN BE VERIFIED
## --------------------------------
## An unranked run starts with the player's unlocks — bonus rerolls, bonus HP, a starting relic
## — which exist only in their local save. Replaying one elsewhere produces a different run.
## `MetaState.run_bonuses(true)` returns all zeroes for a ranked run precisely so that a ranked
## run is a function of its seed and nothing else.

## Every failure a verification can end in. Strings, not ints, because they travel as JSON to
## something that has to explain itself to a player.
const ERR_INCOMPLETE := "log_incomplete"
const ERR_RULES_VERSION := "rules_version_mismatch"
const ERR_CONTENT_VERSION := "content_version_mismatch"
const ERR_NOT_RANKED := "not_ranked"
const ERR_BAD_HEADER := "bad_header"
const ERR_REJECTED := "action_rejected"
const ERR_UNKNOWN_ACTION := "unknown_action"


## Returns {ok, error, message, score, won, action_index, state} — `state` being the full
## RunState.to_data() the replay arrived at, so a caller can compare or store a digest.
static func verify(log: ActionLog) -> Dictionary:
	var header: Dictionary = log.header

	# --- refuse before replaying, and say which of the refusals it was ------------------
	if not log.is_complete():
		return _fail(ERR_INCOMPLETE,
			"This run's record is incomplete, so it cannot be scored. (overflow=%s, rejected=%s)"
			% [log.overflowed, str(log.rejected)])
	if String(header.get("rules_version", "")) != ActionLog.RULES_VERSION:
		# The JS server answers 409 here and says "refresh and replay" (submit-run.js:112). A log
		# written under different rules is not suspicious, it is unreadable — and treating it as
		# cheating would punish a player for playing before an update.
		return _fail(ERR_RULES_VERSION,
			"This run was played on game rules version '%s'; this referee runs '%s'."
			% [str(header.get("rules_version", "?")), ActionLog.RULES_VERSION])
	var content_version := String(ContentDB.part_faces.get("engineVersion", ""))
	if String(header.get("content_version", "")) != content_version:
		return _fail(ERR_CONTENT_VERSION,
			"This run was played on balance data '%s'; this referee has '%s'."
			% [str(header.get("content_version", "?")), content_version])
	if not bool(header.get("ranked", false)):
		return _fail(ERR_NOT_RANKED,
			"Only a ranked run can be verified. An unranked one starts from unlocks that exist "
			+ "only on the player's own machine.")

	var team: Array[String] = []
	for k in (header.get("team_keys", []) as Array):
		team.append(String(k))
	if team.is_empty():
		return _fail(ERR_BAD_HEADER, "The record names no team.")

	# --- replay -------------------------------------------------------------------------
	RunState.start_new_run(int(header.get("seed", 0)), team, String(header.get("mode", "short")),
		int(header.get("ascension", 0)), true)
	if not RunState.ranked:
		# start_new_run downgrades a ranked run whose team holds a Vault Axie, because a vault
		# die exists only in one save. Reaching here means the log's own team cannot be ranked.
		return _fail(ERR_NOT_RANKED,
			"This team includes an imported Axie, which cannot be rebuilt anywhere but on the "
			+ "machine that imported it.")
	# Replaying must not append to the log it is reading.
	RunState.action_log.replaying = true

	var engine: CombatEngine = null
	var node_open := false

	for i in log.entries.size():
		var e: Dictionary = log.entries[i]
		var fn := String(e.get("fn", ""))
		var args: Array = e.get("args", [])
		match fn:
			"enter_node":
				# A node ends when the next one is entered. Nothing logs "I left the node",
				# and nothing should: leaving is not a decision, it is what the rules do once
				# the decisions run out.
				if node_open:
					RunState.after_node()
					node_open = false
				if args.size() < 2:
					return _fail(ERR_REJECTED, "A node entry is missing its id or kind.", i)
				RunState.enter_node(String(args[0]), String(args[1]))
				node_open = true
				engine = null
				if RunState.phase == RunState.RunPhase.COMBAT:
					engine = CombatEngine.new()
					engine.setup_new(RunState.pending_combat)
					engine.action_log = RunState.action_log
				elif RunState.phase == RunState.RunPhase.TREASURE:
					# The map screen does this on arrival and it is not a decision, so it is not
					# in the log — but the offer has to exist before `take_reward` indexes into
					# it. Deterministic from (run_seed, node_id, salt 503), like every other
					# offer in the run.
					RunState.generate_treasure_rewards(String(args[0]))
			"use_die", "play_active", "reroll_dice", "undo_last", "end_turn":
				if engine == null:
					return _fail(ERR_REJECTED,
						"A combat move was recorded outside a combat.", i)
				if not _apply_combat(engine, fn, args):
					return _fail(ERR_REJECTED,
						"Move %d (%s) is not legal in the state the replay reached." % [i, fn], i)
				# The moment a fight is decided, the run reacts — the same order CombatView
				# uses, and the order the rewards depend on.
				if (engine.won or engine.lost) and RunState.phase == RunState.RunPhase.COMBAT:
					RunState.apply_combat_result(engine.get_result())
					engine = null
			"take_reward":
				var idx := int(args[0]) if args.size() > 0 else -1
				if idx < 0 or idx >= RunState.pending_rewards.size():
					return _fail(ERR_REJECTED,
						"Reward %d was taken from an offer of %d."
						% [idx, RunState.pending_rewards.size()], i)
				RunState.apply_chosen_reward(RunState.pending_rewards[idx])
			"reroll_rewards":
				if not RunState.reroll_pending_rewards():
					return _fail(ERR_REJECTED, "A reward re-roll was recorded with none left.", i)
			"event_choose":
				var opt := int(args[0]) if args.size() > 0 else -1
				if opt < 0 or opt >= RunState.event_options().size():
					return _fail(ERR_REJECTED,
						"Event option %d was chosen from an offer of %d."
						% [opt, RunState.event_options().size()], i)
				RunState.choose_event_option(opt)
			"event_done", "shop_done":
				pass   # screen dismissals; the node closes on the next enter_node
			"shop_buy":
				var slot := int(args[0]) if args.size() > 0 else -1
				if not RunState.try_buy_shop_item(slot):
					return _fail(ERR_REJECTED,
						"Shop slot %d could not be bought in the state the replay reached."
						% slot, i)
			_:
				return _fail(ERR_UNKNOWN_ACTION, "Unknown action '%s'." % fn, i)

	if node_open:
		RunState.after_node()

	var won := RunState.phase == RunState.RunPhase.WON
	return {
		"ok": true, "error": "", "message": "",
		# The SAME function the game itself scores with (src/engine.js runXp, which
		# api/submit-run.js:158 also calls) — the referee must not have its own opinion of what
		# a run is worth.
		"score": RunState.compute_run_xp(won),
		"won": won,
		"action_index": -1,
		"state": RunState.to_data(),
	}


static func _apply_combat(engine: CombatEngine, fn: String, args: Array) -> bool:
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
	return false


static func _fail(error: String, message: String, action_index: int = -1) -> Dictionary:
	return {
		"ok": false, "error": error, "message": message, "score": 0, "won": false,
		"action_index": action_index, "state": {},
	}
