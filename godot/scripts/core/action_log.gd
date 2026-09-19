class_name ActionLog
extends RefCounted
## The ordered list of every decision a player made in a run, and nothing else.
##
## WHY THIS EXISTS
## ---------------
## The live JS build never trusts a score. The client sends
## `{seed, teamKeys, mode, ascension, actions: [{fn, args}]}` and `api/submit-run.js` REPLAYS
## those exact calls server-side through the real engine, then computes the score from what the
## replay actually produced (see that file's header). A forged score is not rejected — it is
## never read. The Godot port has no equivalent yet, and that gap is the declared gate for
## letting this port replace the live game.
##
## This class is the first half of closing it, and the half that is useful on its own: whatever
## anti-cheat design wins later (server replay, signed logs, local attestation), ALL of them need
## a faithful, ordered, replayable record of player intent. Building it first is not a bet on any
## one of them.
##
## WHAT BELONGS IN HERE — AND WHAT MUST NOT
## ----------------------------------------
## Player DECISIONS only. Never outcomes, never dice values, never damage numbers. The whole
## point is that the outcome is re-derived; a log that carried results would be a log you had to
## trust, which is the thing being replaced. If a number the replay needs is not reproducible
## from `header.seed` plus this list, that is a determinism bug to fix in the engine, not a field
## to add here.
##
## RECORDED WHERE THE STATE CHANGES, NOT WHERE THE BUTTON IS
## ---------------------------------------------------------
## The JS build calls `logAction()` at each UI callsite (client.html:4630 and ~12 more). That
## works, but every new screen is a new chance to forget one, and a forgotten call does not fail
## — it silently produces a log that replays into a different run. Here the recording lives
## inside the state-changing functions themselves (CombatEngine.use_die, RunState.enter_node, …),
## so a new UI path cannot miss it and a test driving the engine directly records the same log a
## player would.
##
## ONLY SUCCESSFUL CALLS ARE RECORDED
## ----------------------------------
## `use_die` / `play_active` / `reroll_dice` / `undo_last` all return false when the move was
## illegal. Those are not decisions, they are misclicks, and the JS server treats the same four
## as return-checked (`RETURN_CHECKED_FNS`, submit-run.js:29). Recording them would put entries in
## the log that a replay evaluates in a different state.

## Bump when the RULES change in a way that makes an older log replay differently — new face
## behaviour, changed damage math, different turn order. Not for UI, not for art. A log whose
## version does not match the engine replaying it is not a suspicious log, it is an unreadable
## one, and must be reported as such rather than replayed and disbelieved (the JS server answers
## 409 for exactly this, submit-run.js:112).
const RULES_VERSION := "godot-2026-09-19-a"

## Mirrors `ALLOWED_FNS` in api/submit-run.js, in this port's own vocabulary. A verifier reads
## this list to know what it must implement; anything absent from it is refused at record time,
## so an unreviewed new action cannot reach a log by accident.
##
##   this port          live JS            what it is
##   ---------          -------            ----------
##   enter_node         chooseNode         which map node was entered
##   use_die            playerUseDie       a rolled face spent on a target
##   play_active        playerUseRelic     an active relic used
##   reroll_dice        doReroll           which dice were re-rolled
##   end_turn           endTurn            turn handed to the enemies
##   undo_last          undo               one action taken back
##   take_reward        takeReward         which reward card was chosen
##   reroll_rewards     (none — port only) the reward offer re-rolled
##   event_choose       eventChoose        which event option was picked
##   event_done         eventDone          event screen dismissed
##   shop_buy           shopBuy            which shop slot was bought
##   shop_done          shopDone           shop left
const ALLOWED_FNS: Array[String] = [
	"enter_node", "use_die", "play_active", "reroll_dice", "end_turn", "undo_last",
	"take_reward", "reroll_rewards", "event_choose", "event_done", "shop_buy", "shop_done",
]

## Same ceiling as the JS server (submit-run.js:30). A real run lands far below it; the limit is
## against log-spam, not against long games.
const MAX_ACTIONS := 3000

## {seed, team_keys, mode, ascension, rules_version, content_version}. Everything a replay needs
## to rebuild the starting state, and nothing it could get from the actions themselves.
var header: Dictionary = {}

var entries: Array[Dictionary] = []

## True once MAX_ACTIONS was hit. The log then stops growing and SAYS SO. A truncated log that
## still looked complete would replay to a lower score and read as a losing run rather than as a
## broken record.
var overflowed: bool = false

## While replaying, the very functions that record are the ones being driven, so recording has to
## be off or the replay would append a second copy of the log it is reading.
var replaying: bool = false

## Set when `record()` was handed something not on the allow-list, or arguments that are not
## JSON-round-trippable. Kept as state instead of thrown: a run in progress must not die because
## of a logging fault, but the log must never afterwards claim to be complete.
var rejected: Array[String] = []


## Opens a log for a run. `content_version` ties it to the balance data it was played under —
## part_faces.json carries its own `engineVersion`, and a log replayed against different face
## values is as wrong as one replayed against different rules.
func begin(seed_value: int, team_keys: Array, mode: String, ascension: int,
		content_version: String = "") -> void:
	header = {
		"seed": seed_value,
		"team_keys": Array(team_keys).duplicate(),
		"mode": mode,
		"ascension": ascension,
		"rules_version": RULES_VERSION,
		"content_version": content_version,
	}
	entries = []
	overflowed = false
	rejected = []


## Appends one decision. Returns false when it was refused — callers ignore that (gameplay must
## not depend on logging), but `is_complete()` will report it afterwards.
func record(fn: String, args: Array = []) -> bool:
	if replaying:
		return false
	if not ALLOWED_FNS.has(fn):
		rejected.append("unknown action '%s'" % fn)
		return false
	if entries.size() >= MAX_ACTIONS:
		overflowed = true
		return false
	# Arguments must survive JSON, because that is how this log will travel to any verifier.
	# Checking at record time names the offending action; checking at submit time names nothing.
	#
	# The CHECK is round-tripped; the STORED value is not. Keeping what JSON handed back looks
	# tidier and is wrong: JSON has exactly one number type, so a unit id of 11 comes back as
	# 11.0 and the log in memory stops matching the log on the wire. That breaks nothing while
	# the replay casts with int(), and breaks everything the moment anyone hashes or signs a log
	# and compares it to the one they received — measured, not imagined: t_replay caught it.
	var probe: Variant = JSON.parse_string(JSON.stringify(args))
	if not (probe is Array):
		rejected.append("action '%s' has arguments that do not survive JSON" % fn)
		return false
	entries.append({"fn": fn, "args": args.duplicate(true)})
	return true


## A log is evidence only if nothing was dropped from it.
func is_complete() -> bool:
	return not overflowed and rejected.is_empty()


func size() -> int:
	return entries.size()


func to_data() -> Dictionary:
	return {
		"header": header.duplicate(true),
		"entries": entries.duplicate(true),
		"overflowed": overflowed,
		"rejected": rejected.duplicate(),
	}


## Restores a log from JSON, INCLUDING the integer-ness JSON does not carry.
##
## Every argument this log can hold is an id, an index or a list of ids — `ALLOWED_FNS` is what
## makes that true, and it is why this coercion is safe here and would not be in a general JSON
## reader. Without it a round-tripped log is unequal to the log it came from, and any scheme that
## compares, hashes or signs one rejects an honest player.
static func _restore_ints(value: Variant) -> Variant:
	if value is float:
		var f: float = value
		return int(f) if f == floor(f) and absf(f) < 9.0e15 else value
	if value is Array:
		var arr: Array = []
		for v in (value as Array):
			arr.append(_restore_ints(v))
		return arr
	if value is Dictionary:
		var d: Dictionary = {}
		for k in (value as Dictionary):
			d[k] = _restore_ints((value as Dictionary)[k])
		return d
	return value


static func from_data(data: Dictionary) -> ActionLog:
	var out_log := ActionLog.new()
	out_log.header = (data.get("header", {}) as Dictionary).duplicate(true)
	out_log.header["seed"] = int(out_log.header.get("seed", 0))
	out_log.header["ascension"] = int(out_log.header.get("ascension", 0))
	var raw: Array = data.get("entries", []) as Array
	var out: Array[Dictionary] = []
	for e in raw:
		if e is Dictionary:
			var entry: Dictionary = (e as Dictionary).duplicate(true)
			entry["args"] = _restore_ints(entry.get("args", []))
			out.append(entry)
	out_log.entries = out
	out_log.overflowed = bool(data.get("overflowed", false))
	var rej: Array[String] = []
	for r in (data.get("rejected", []) as Array):
		rej.append(str(r))
	out_log.rejected = rej
	return out_log
