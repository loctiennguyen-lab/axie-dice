extends Node
## SR0 (PB input lock): while ONE seed request is in flight, a second reroll / End turn / Continue is refused
## ("busy") and nothing reaches the epoch source or the action log. The log after the late reply is the same as
## a run where the reply came at once. No network: the epoch source is a fake whose replies settle on demand.

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


class SlowRemote extends EpochSource:
	var reqs: Array = []
	var pending: Array[EpochReply] = []
	var delay := true
	func is_remote() -> bool:
		return true
	func request(kind: String, args: Dictionary) -> EpochReply:
		reqs.append([kind, args.duplicate(true)])
		var seed := 7000 + reqs.size()
		if not delay:
			return EpochReply.ok_reply(seed)
		var r := EpochReply.new()
		r.set_meta("seed", seed)
		pending.append(r)
		return r
	func settle_next() -> void:
		var r: EpochReply = pending.pop_front()
		r.settle(true, int(r.get_meta("seed")))


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _engine(src: EpochSource) -> CombatEngine:
	var roster: Array = []
	for i in TEAM.size():
		var mh := int(ContentDB.heroes[TEAM[i]]["max_hp"])
		roster.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1, "max_hp": mh, "muts": [], "growth": {}, "bonus_hp": 0})
	var e := CombatEngine.new()
	e.setup_new({"node_id": "r1_c0", "kind": "battle", "pw": 1, "ascension": 0,
		"roster_snapshot": roster, "relic_ids": [], "combat_seed": 5})
	e.action_log = ActionLog.new()
	e.action_log.begin(0, TEAM, "short", 0)
	e.set_epoch(src)
	return e


func _ready() -> void:
	_guard.capture()
	# Reference: the reply comes at once.
	var fast := SlowRemote.new()
	fast.delay = false
	var ef := _engine(fast)
	var uids := _party(ef)
	var rr_fast: Dictionary = await ef.request_reroll_dice(uids)
	var len_fast := ef.action_log.size()

	# Slow: press reroll, then reroll again, End turn and Continue while the first is in flight.
	var slow := SlowRemote.new()
	var es := _engine(slow)
	var first := {}
	(func() -> void: first["r"] = await es.request_reroll_dice(uids)).call()   # suspends on the pending reply
	_check(es.epoch_pending, "a request is in flight after the first press")
	var again: Dictionary = await es.request_reroll_dice(uids)
	_check(String(again["code"]) == "busy" and not bool(again["ok"]), "second reroll while waiting is refused (busy)")
	var et: Dictionary = await es.request_begin_end_turn()
	_check(String(et["code"]) == "busy", "End turn while waiting is refused (busy)")
	var co: Dictionary = await es.request_continue_after_wipe()
	_check(String(co["code"]) == "busy", "Continue while waiting is refused (busy)")
	_check(slow.reqs.size() == 1, "only ONE request reached the source, nothing queued (got %d)" % slow.reqs.size())
	_check(es.action_log.size() == 0, "nothing logged before the seed is known")
	slow.settle_next()
	var res: Dictionary = first.get("r", {"ok": false})
	_check(first.has("r"), "the first press finished once its seed arrived")
	_check(bool(res["ok"]) == bool(rr_fast["ok"]), "late reply gives the same verdict as an instant one")
	_check(not es.epoch_pending, "lock released after the reply")
	_check(es.action_log.size() == len_fast, "log_len after a late reply equals the instant case (%d vs %d)" % [es.action_log.size(), len_fast])
	_check(slow.reqs.size() == 1, "still exactly one request after settling")

	_guard.restore()
	if _fails.is_empty():
		print("PASS t_run_session_race (%d checks)" % _checks)
	else:
		for f in _fails:
			print("FAIL: ", f)
		print("FAIL t_run_session_race")
	get_tree().quit(0 if _fails.is_empty() else 1)


func _party(e: CombatEngine) -> Array:
	var out: Array = []
	for u in e.party:
		out.append((u as Unit).uid)
	return out
