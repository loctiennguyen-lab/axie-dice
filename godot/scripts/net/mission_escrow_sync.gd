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
				done.call("applied" if MetaState.apply_mission_settlement(s) else "unknown")
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
	reconcile_status(func(st: String) -> void:
		if st == "no_record":
			MetaState.settle_mission_stake(false, true)
		if done.is_valid():
			done.call(st))


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
