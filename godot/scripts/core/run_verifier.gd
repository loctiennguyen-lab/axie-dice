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
const ERR_STAGE_MISMATCH := "stage_mismatch"
const ERR_UNKNOWN_ACTION := "unknown_action"


## Returns {ok, error, message, score, won, action_index, state} — `state` being the full
## RunState.to_data() the replay arrived at, so a caller can compare or store a digest.
## `tape` = the epochs the run was played with ([{seq, kind, args, seed, extra}]), `loadout` = the
## injected bonuses/unlocks (defaults to the header's own `loadout`). Seeds come ONLY from the tape,
## and each one is checked against the hash of the log replayed so far, so an edited log fails with
## `action_rejected` instead of replaying into another run. MetaState is never read for a replay.
static func verify(log: ActionLog, tape: Array = [], loadout: Dictionary = {}) -> Dictionary:
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
	if tape.is_empty():
		return _fail(ERR_BAD_HEADER, "No epoch tape was supplied; seeds cannot be rebuilt without it.")
	var content_version := String(ContentDB.part_faces.get("engineVersion", ""))
	if String(header.get("content_version", "")) != content_version:
		return _fail(ERR_CONTENT_VERSION,
			"This run was played on balance data '%s'; this referee has '%s'."
			% [str(header.get("content_version", "?")), content_version])
	if not bool(header.get("ranked", false)):
		return _fail(ERR_NOT_RANKED,
			"Only a ranked run can be verified. An unranked one starts from unlocks that exist "
			+ "only on the player's own machine.")

	# Depth v4 3.10.9 (T7): the stage is the one the SERVER wrote into the tape's run_start header. A log header that claims another one is a lie
	# (the replay itself plays under the tape's stage, so a stage-gated action in a low-stage run is refused at its own index, T6).
	var tape_stage := int((((tape[0] as Dictionary).get("extra", {}) as Dictionary).get("header", {}) as Dictionary).get("depth_stage", 3))
	if int(header.get("depth_stage", 3)) != tape_stage:
		return _fail(ERR_STAGE_MISMATCH, "The record claims depth stage %d; the server issued stage %d." % [int(header.get("depth_stage", 3)), tape_stage])

	# Anchors are offline-only (anchor-mvp QA #3): an online run that names one is not a run this referee can replay.
	if String(header.get("anchor_id", "")) != "" or String((header.get("loadout", {}) as Dictionary).get("anchor_id", "")) != "":
		return _fail(ERR_BAD_HEADER, "Anchors only exist in offline runs; this record names one.")
	var team: Array[String] = []
	for k in (header.get("team_keys", []) as Array):
		team.append(String(k))
	if team.is_empty():
		return _fail(ERR_BAD_HEADER, "The record names no team.")

	# --- replay -------------------------------------------------------------------------
	var lo: Dictionary = loadout if not loadout.is_empty() else (header.get("loadout", {}) as Dictionary)
	# Ranked cannot dodge the Run Rule (rules_on must be true) and core_off is for tests/tools only.
	if not bool(lo.get("rules_on", false)):
		return _fail(ERR_BAD_HEADER, "A ranked run always plays with the Run Rule on; this record says otherwise.")
	if bool(lo.get("core_off", false)) and not RunState.core_flow_switches_allowed():
		return _fail(ERR_BAD_HEADER, "A ranked run cannot switch the Core flow off.")
	var params := {"team_keys": team, "mode": String(header.get("mode", "short")),
		"ascension": int(header.get("ascension", 0)), "ranked": true, "loadout": lo}
	if lo.has("bonuses"):
		params["bonuses"] = ActionLog._restore_ints(lo["bonuses"])
	var tape_src := TapeEpochSource.new(tape)
	if not RunState.start_run_with_epoch(tape_src, params, int(header.get("local_secret", 0))):
		return _fail(ERR_BAD_HEADER, "The epoch tape does not open a run.")
	# The tape is checked against the log being verified, one entry at a time (see set_visible_len).
	tape_src.bind_log(log)
	tape_src.set_visible_len(0)
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
		tape_src.set_visible_len(i)
		match fn:
			"enter_node":
				if RunState.phase == RunState.RunPhase.PACT:
					return _fail(ERR_REJECTED, "A node was entered before the boss Pact was settled.", i)
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
			"sell_relic":
				if args.size() < 1 or not RunState.sell_relic(String(args[0])):
					return _fail(ERR_REJECTED, "A relic sale was recorded that the replay cannot make.", i)
			"swap_on_full":
				if args.size() < 2 or not RunState.acquire_relic(String(args[1]), "swap", String(args[0])):
					return _fail(ERR_REJECTED, "A relic swap was recorded that the replay cannot make.", i)
			"reorder_party":
				if args.size() < 1 or not RunState.reorder_party(args[0] as Array):
					return _fail(ERR_REJECTED, "A party reorder was recorded that the replay cannot make.", i)
			"aid_use":
				# Written by the server's DO; the replay only needs the effects that touch the rules.
				# delay_clock moves the boss clock; scout/others change what the player knows, not the rules.
				if args.size() < 1:
					return _fail(ERR_REJECTED, "An Aid use has no id.", i)
				if String(args[0]) == "delay_clock":
					if engine == null or args.size() < 2:
						return _fail(ERR_REJECTED, "delay_clock outside a combat.", i)
					engine.delay_clock(int(args[1]))
			"shop_refresh":
				if not RunState.refresh_shop(-1):
					return _fail(ERR_REJECTED, "A shop refresh was recorded that the replay cannot make.", i)
			"use_die", "play_active", "reroll_dice", "undo_last", "end_turn", "tweak", "hold_pick", "loaded_pick", "continue", "stash", "overcast", "wild_face":
				if engine == null:
					return _fail(ERR_REJECTED,
						"A combat move was recorded outside a combat.", i)
				if not _apply_combat(engine, fn, args):
					return _fail(ERR_REJECTED,
						"Move %d (%s) is not legal in the state the replay reached." % [i, fn], i)
				# The moment a fight is decided, the run reacts — the same order CombatView
				# uses, and the order the rewards depend on.
				# A wiped party is not the end of the fight when the very next action is its Continue.
				var continues_next: bool = engine.lost and i + 1 < log.entries.size() \
					and String((log.entries[i + 1] as Dictionary).get("fn", "")) == "continue"
				if (engine.won or engine.lost) and not continues_next and RunState.phase == RunState.RunPhase.COMBAT:
					tape_src.set_visible_len(i + 1)
					RunState.apply_combat_result(engine.get_result())
					engine = null
			"pact_pick":
				var pi := int(args[0]) if args.size() > 0 else -99
				var ok_p := false
				if RunState.phase == RunState.RunPhase.PACT:
					ok_p = RunState.skip_pact() if pi == -1 else RunState.take_pact(pi, String(args[1]) if args.size() > 1 else "")
				if not ok_p:
					return _fail(ERR_REJECTED, "A pact pick was recorded that the replay cannot make.", i)
			"pact_reroll":
				var rs := int(args[0]) if args.size() > 0 else -1
				if RunState.phase != RunState.RunPhase.PACT or not RunState.reroll_pact_slot(rs):
					return _fail(ERR_REJECTED, "A pact swap was recorded that the replay cannot make.", i)
			"take_reward":
				if RunState.phase == RunState.RunPhase.PACT:
					return _fail(ERR_REJECTED, "A reward was taken before the boss Pact was settled.", i)
				# A Core offer after an event/shop node opens when that node closes (after_node), which the UI does
				# on leaving it; here that happens when the log reaches the pick.
				if RunState.pending_rewards.is_empty() and node_open:
					RunState.after_node()
					node_open = false
				var idx := int(args[0]) if args.size() > 0 else -1
				if idx < 0 or idx >= RunState.pending_rewards.size():
					return _fail(ERR_REJECTED,
						"Reward %d was taken from an offer of %d."
						% [idx, RunState.pending_rewards.size()], i)
				var sell_id := String(args[1]) if args.size() > 1 else ""
				if not RunState.apply_chosen_reward(RunState.pending_rewards[idx], sell_id):
					return _fail(ERR_REJECTED, "A reward pick was recorded that the replay cannot make.", i)
				# The UI calls after_node() after every pick: a normal reward closes its node (and may open a Core
				# offer), a Core pick only returns to the map.
				if node_open or RunState._core_close_pending:
					RunState.after_node()
					node_open = false
			"reroll_rewards":
				if RunState.phase == RunState.RunPhase.PACT:
					return _fail(ERR_REJECTED, "Rewards were re-rolled before the boss Pact was settled.", i)
				if RunState.pending_rewards.is_empty() and node_open:
					RunState.after_node()
					node_open = false
				var ridx := int(args[0]) if args.size() > 0 else -1
				if not RunState.reroll_pending_rewards(-1, ridx):
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
			# args[1] = from_aid (0/1); logs written before it existed have only the uids.
			# args[2] = rmode (0 Lieu / 1 Safe); older logs have none = Safe.
			return engine.reroll_dice(args[0] as Array, -1, \
				args.size() > 1 and int(args[1]) != 0, int(args[2]) if args.size() > 2 else 1)
		"undo_last":
			return engine.undo_last()
		"continue":
			return engine.continue_after_wipe(-1, -1)
		"tweak":
			return args.size() >= 3 and engine.tweak(String(args[0]), int(args[1]), int(args[2]))
		"hold_pick":
			return args.size() >= 1 and engine.hold_pick(int(args[0]))
		"stash":
			return args.size() >= 1 and engine.stash(int(args[0]))
		"overcast":
			return args.size() >= 1 and engine.overcast(int(args[0]))
		"wild_face":
			return args.size() >= 2 and engine.wild_face(int(args[0]), int(args[1]))
		"loaded_pick":
			return args.size() >= 2 and engine.loaded_pick(int(args[0]), int(args[1]))
		"end_turn":
			engine.end_turn()
			return true
	return false


static func _fail(error: String, message: String, action_index: int = -1) -> Dictionary:
	return {
		"ok": false, "error": error, "message": message, "score": 0, "won": false,
		"action_index": action_index, "state": {},
	}
