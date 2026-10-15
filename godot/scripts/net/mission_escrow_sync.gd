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
	var run_id := String(MetaState.mission_escrow.get("run_id", ""))
	var t := _transport()
	if run_id.is_empty() or (not force and not RemoteEpochSource.flag_on()) or not t.is_valid() or _busy:
		if done.is_valid():
			done.call(false)
		return
	_busy = true
	t.call("GET", "/api/missions/escrow", "", func(code: int, text: String) -> void:
		_busy = false
		var applied := false
		var j: Variant = JSON.parse_string(text) if code == 200 and not text.is_empty() else null
		if typeof(j) == TYPE_DICTIONARY:
			for s in ((j as Dictionary).get("settled", []) as Array):
				if typeof(s) == TYPE_DICTIONARY and String((s as Dictionary).get("run_id", "")) == run_id:
					applied = MetaState.apply_mission_settlement(s)
					break
		if done.is_valid():
			done.call(applied))
