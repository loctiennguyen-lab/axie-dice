class_name MissionEscrowSync
extends RefCounted
## Mission stake, server side (L1 option A). The Worker holds the stake from POST /api/run and settles it when
## the run closes; the local MetaState.mission_escrow is only a mirror, bound to the server run by `run_id`.
## reconcile() asks GET /api/missions/escrow and closes the local mirror from the SERVER's settlement
## (won / lost / refunded and its payout), never from local math. Called after a run closes, on Land and on
## the Missions screen (that covers "next launch"). Offline or nothing settled yet: the mirror stays open.

## Tests: replaces AccountService.transport. Callable(method, path, body_text, done(code:int, text:String)).
static var transport_override: Callable = Callable()
static var _busy := false
static var _unlocks_busy := false
## The last settlement applied to the local mirror ({run_id, tier, state: won|lost|refunded, payout}); the
## Missions screen reads it once (take_applied) to say "Old run, stake refunded". Empty = nothing new.
static var last_applied: Dictionary = {}


static func _transport() -> Callable:
	return transport_override if transport_override.is_valid() else AccountService.transport


## True when a server settlement could be waiting: remote dice on, and the mirror is bound to a server run.
static func needed() -> bool:
	return RemoteEpochSource.flag_on() and not String(MetaState.mission_escrow.get("run_id", "")).is_empty()


## done(applied: bool). `force` skips the remote-flag check (tests).
static func reconcile(done: Callable = Callable(), force := false) -> void:
	reconcile_status(func(st: String) -> void:
		if done.is_valid():
			done.call(st == "applied"), force)


## Same request, but says what the server answered. done(status: String):
##   "applied"   the server had settled this run: the mirror is closed from its payout.
##   "open"      the server still holds the stake open (run live, or not written back yet): mirror untouched.
##   "no_record" the server answered and has no record of this run_id: the caller may fall back to a local loss.
##   "unknown"   offline, error, busy, no transport: mirror untouched, ask again later. NEVER treat as a loss.
##   "none"      nothing to ask (no mirror, not bound to a server run, or remote dice off).
static func reconcile_status(done: Callable, force := false) -> void:
	var run_id := String(MetaState.mission_escrow.get("run_id", ""))
	var t := _transport()
	if run_id.is_empty() or (not force and not RemoteEpochSource.flag_on()):
		done.call("none")
		return
	if not t.is_valid() or _busy:
		done.call("unknown")
		return
	_busy = true
	t.call("GET", "/api/missions/escrow", "", func(code: int, text: String) -> void:
		_busy = false
		var j: Variant = JSON.parse_string(text) if code == 200 and not text.is_empty() else null
		if typeof(j) != TYPE_DICTIONARY:
			done.call("unknown")
			return
		var settled: Variant = (j as Dictionary).get("settled", [])
		for s in (settled as Array if typeof(settled) == TYPE_ARRAY else []):
			if typeof(s) == TYPE_DICTIONARY and String((s as Dictionary).get("run_id", "")) == run_id:
				var tier_before := String(MetaState.mission_escrow.get("tier", ""))
				var ok := MetaState.apply_mission_settlement(s)
				if ok:
					last_applied = {"run_id": run_id, "tier": tier_before, "state": String(s.get("state", "")),
						"payout": int(s.get("payout", 0))}
				done.call("applied" if ok else "unknown")
				return
		var open: Variant = (j as Dictionary).get("open", null)
		if typeof(open) == TYPE_DICTIONARY and String((open as Dictionary).get("run_id", "")) == run_id:
			done.call("open")
			return
		done.call("no_record"))


## A mirror that follows a server run must be closed from the SERVER's settlement. For the places that used to
## settle a dead run's mirror as a loss on the spot (the saved run is gone or unusable): bound + remote -> ask
## the server and apply its answer; only a server that has no record falls back to the local loss; offline /
## still open leaves the mirror open for the next Land / Missions reconcile. Unbound or local dice: the old
## local loss. done(status) is optional ("local" when it settled locally).
static func settle_dead_run_mirror(done: Callable = Callable()) -> void:
	if MetaState.mission_escrow.is_empty():
		if done.is_valid():
			done.call("none")
		return
	if not needed():
		MetaState.settle_mission_stake(false, true)
		if done.is_valid():
			done.call("local")
		return
	# The saved run was made under other rules (a bump): the client can never resume it. The server refunds such
	# a run when it is abandoned, so abandon it there (the stake is not lost for our bump), then read the result.
	# ONLY when the old-rules save IS the run the mirror follows (same run_id). A mirror can come from another
	# device through the cloud save: abandoning that run would forfeit a live stake on current rules.
	var run_id := String(MetaState.mission_escrow.get("run_id", ""))
	var stale_rules := run_id != "" and _stale_save_run_id() == run_id
	reconcile_status(func(st: String) -> void:
		if st == "open" and stale_rules and not run_id.is_empty():
			abandon_on_server(run_id, func() -> void:
				reconcile_status(func(st2: String) -> void:
					if st2 == "no_record":
						MetaState.settle_mission_stake(false, true)
					if done.is_valid():
						done.call(st2)))
			return
		if st == "no_record":
			MetaState.settle_mission_stake(false, true)
		if done.is_valid():
			done.call(st))


## run_id inside the local run save when that save was made under other rules (cannot be resumed), else "".
static func _stale_save_run_id() -> String:
	if String(RunState.saved_run_status().get("reason", "")) != "rules":
		return ""
	var parsed: Variant = JSON.parse_string(SaveStore.read_text(RunState.SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return ""
	var run: Variant = (parsed as Dictionary).get("run", {})
	return String((run as Dictionary).get("run_id", "")) if typeof(run) == TYPE_DICTIONARY else ""


## POST /api/run/<id>/abandon for a run this device can no longer play. done() runs whatever the answer was
## (offline included): the caller reads the settlement afterwards; nothing here treats an error as a loss.
static func abandon_on_server(run_id: String, done: Callable) -> void:
	var t := _transport()
	if run_id.is_empty() or not t.is_valid():
		done.call()
		return
	t.call("POST", "/api/run/%s/abandon" % run_id, "", func(_code: int, _text: String) -> void:
		done.call())


## Returns and clears `last_applied` ({} when nothing new).
static func take_applied() -> Dictionary:
	var d := last_applied
	last_applied = {}
	return d


## GET /api/missions/unlocks -> MissionBoard.apply_unlocks (MetaState.mission_unlock_cache). done(ok: bool).
## `force` skips the remote-flag check (tests). Offline / error / busy: the cache stays as it was, ok = false.
static func fetch_unlocks(done: Callable = Callable(), force := false) -> void:
	var t := _transport()
	if (not force and not RemoteEpochSource.flag_on()) or not t.is_valid() or _unlocks_busy:
		if done.is_valid():
			done.call(false)
		return
	_unlocks_busy = true
	t.call("GET", "/api/missions/unlocks", "", func(code: int, text: String) -> void:
		_unlocks_busy = false
		var j: Variant = JSON.parse_string(text) if code == 200 and not text.is_empty() else null
		var ok := MissionBoard.apply_unlocks(MetaState, j)
		if done.is_valid():
			done.call(ok))


class Waiter extends RefCounted:
	signal finished(value: String)
	var done := false
	var value := ""

	func set_value(v: String) -> void:
		done = true
		value = v
		finished.emit(v)


const MSG_SYNCING := "Syncing your last mission…"
const MSG_STILL_OPEN := "Your last mission is still open on the server. Continue or abandon it first."


## Before a NEW stake is taken while an old mirror is still open and its run is gone from this device.
## Returns a Waiter; its value is "" (go ahead: the mirror is closed or was never a server stake) or the
## message that blocks the new stake. Never settles a server-bound mirror as a loss on its own.
static func prepare_new_stake() -> Waiter:
	var w := Waiter.new()
	if MetaState.mission_escrow.is_empty() or not needed():
		w.set_value("")
		return w
	reconcile_status(func(st: String) -> void:
		if st == "applied" or st == "none":
			w.set_value("")
		elif st == "no_record":
			MetaState.settle_mission_stake(false, true)
			w.set_value("")
		elif st == "open":
			w.set_value(MSG_STILL_OPEN)
		else:
			w.set_value(MSG_SYNCING))
	return w
