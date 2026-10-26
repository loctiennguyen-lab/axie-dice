extends Node
## SR0 part 2 (PB, Liam 26/10): the dice are thrown BEFORE the seed is back, the seed lands while they roll.
## Real CombatView + a fake epoch source whose reply comes after 0 / 800 / 2500 ms (no network).
## Checks: the pre-throw is recorded while the request is still open and the engine has not changed yet;
## the final faces and the action log are identical whatever the delay; the roller API (roll_pending /
## resolve) keeps dice waiting until they get a result. The real 3D flight is visual (headless skips it).

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


class DelayedSource extends EpochSource:
	var host: Node
	var delay_ms := 0
	var reqs := 0
	func is_remote() -> bool:
		return true
	func request(_kind: String, _args: Dictionary) -> EpochReply:
		reqs += 1
		var seed := 9100 + reqs
		if delay_ms <= 0:
			return EpochReply.ok_reply(seed)
		var r := EpochReply.new()
		host.get_tree().create_timer(delay_ms / 1000.0).timeout.connect(func() -> void: r.settle(true, seed))
		return r


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1, "max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [], "growth": {}, "bonus_hp": 0})
	return out


## One reroll through the real view with a source that answers after `delay_ms`. Returns the facts to compare.
func _run(delay_ms: int) -> Dictionary:
	RunState.pending_combat = {"node_id": "pre_throw_node", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 4242}
	var view := load("res://scenes/combat/Combat.tscn").instantiate() as Node2D
	add_child(view)
	await get_tree().process_frame
	await get_tree().process_frame
	var eng: CombatEngine = view._combat
	var src := DelayedSource.new()
	src.host = self
	src.delay_ms = delay_ms
	eng.set_epoch(src)
	var uids: Array = view._auto_reroll_uids()
	var faces_before: Array = []
	for u in eng.party:
		faces_before.append((u as Unit).roll_face_index())
	var len_before := eng.action_log.size()
	var t0 := Time.get_ticks_msec()
	var done := [false]
	(func() -> void:
		await view._do_reroll(uids, 1)
		done[0] = true).call()   # started, not awaited here: we look at the state while it waits
	var out := {"delay": delay_ms}
	out["pre_recorded"] = not view.last_pre_throw.is_empty() and (view.last_pre_throw["uids"] as Array).size() == uids.size()
	out["pending_at_start"] = eng.epoch_pending
	out["faces_unchanged_at_start"] = true
	if delay_ms > 0:
		await get_tree().create_timer(0.1).timeout
		for i in eng.party.size():
			if (eng.party[i] as Unit).roll_face_index() != faces_before[i]:
				out["faces_unchanged_at_start"] = false
		out["pending_mid"] = eng.epoch_pending
		out["log_mid"] = eng.action_log.size() == len_before
	while not done[0]:
		await get_tree().process_frame
	out["elapsed_ms"] = Time.get_ticks_msec() - t0
	out["pending_end"] = eng.epoch_pending
	var faces: Array = []
	for u in eng.party:
		faces.append((u as Unit).roll_face_index())
	out["faces"] = faces
	out["log_len"] = eng.action_log.size() - len_before   # entries this reroll added (the log object is shared between runs)
	out["reqs"] = src.reqs
	view.queue_free()
	await get_tree().process_frame
	return out


func _arm(view: Node, uids: Array) -> DiceRoller3D:
	var roller: DiceRoller3D = view._stage3d.get_dice_roller()
	var faces6: Array = []
	for k in 6:
		faces6.append({"type": "attack", "value": k + 1})
	var es: Array = []
	for u in uids:
		es.append({"faces": faces6, "face_type": "attack", "value": 1, "result_index": 0, "uid": u})
	roller.roll_pending(es, func(_i: int) -> Vector2: return Vector2.ZERO)
	view._pre_throw_uids = uids.duplicate()
	return roller


func _flight_checks() -> void:
	RunState.pending_combat = {"node_id": "pre_throw_fl", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 4242}
	var view := load("res://scenes/combat/Combat.tscn").instantiate() as Node2D
	add_child(view)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(is_instance_valid(view._stage3d) and view._stage3d.get_dice_roller() != null, "flight: the view has a stage and a roller")
	if not (is_instance_valid(view._stage3d) and view._stage3d.get_dice_roller() != null):
		view.queue_free()
		return
	var a := int((view._combat.party[0] as Unit).uid)
	var b := int((view._combat.party[1] as Unit).uid)
	var roller := _arm(view, [a, b])
	_check(view._pre_throw_matches([{"uid": a}, {"uid": b}]), "match: same uids, same order")
	_check(not view._pre_throw_matches([{"uid": b}, {"uid": a}]), "mismatch: other order")
	_check(not view._pre_throw_matches([{"uid": a}]), "mismatch: other count")
	view._cancel_pre_throw()
	_check(view._pre_throw_uids.is_empty() and not roller.is_rolling(), "cancel: dice land, pre-throw cleared")
	# Leaving the fight while the seed is awaited cancels the pre-throw.
	var eng: CombatEngine = view._combat
	var src := DelayedSource.new()
	src.host = self
	src.delay_ms = 300
	eng.set_epoch(src)
	var done := [false]
	(func() -> void:
		await view._do_reroll(view._auto_reroll_uids(), 1)
		done[0] = true).call()
	roller = _arm(view, [a])
	view._result_shown = true   # the fight ended while waiting
	while not done[0]:
		await get_tree().process_frame
	_check(view._pre_throw_uids.is_empty() and not roller.is_rolling(), "leave while waiting: pre-throw cancelled")
	view.queue_free()
	await get_tree().process_frame

func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	var ref: Dictionary = await _run(0)
	_check(bool(ref["pre_recorded"]), "0 ms: pre-throw recorded for the rerolled dice")
	_check(int(ref["reqs"]) == 1 and not bool(ref["pending_end"]), "0 ms: one request, lock released")
	for ms in [800, 2500]:
		var r: Dictionary = await _run(ms)
		_check(bool(r["pre_recorded"]), "%d ms: pre-throw recorded BEFORE the seed is back" % ms)
		_check(bool(r["pending_mid"]) and bool(r["faces_unchanged_at_start"]) and bool(r["log_mid"]),
			"%d ms: while waiting the lock is on, faces and log are untouched" % ms)
		_check(int(r["elapsed_ms"]) >= ms - 50, "%d ms: the reroll really waited for the seed (%d ms)" % [ms, int(r["elapsed_ms"])])
		_check(r["faces"] == ref["faces"], "%d ms: final faces equal the instant-seed run" % ms)
		_check(int(r["log_len"]) == int(ref["log_len"]), "%d ms: log_len equal (%d vs %d)" % [ms, int(r["log_len"]), int(ref["log_len"])])
		_check(not bool(r["pending_end"]) and int(r["reqs"]) == 1, "%d ms: lock released, one request" % ms)

	# Roller API: dice wait for resolve(). Headless the roller skips the flight, so only the bookkeeping is seen.
	var roller := DiceRoller3D.new()
	add_child(roller)
	var faces6: Array = []
	for k in 6:
		faces6.append({"type": "attack", "value": k + 1})
	var entry := {"faces": faces6, "face_type": "attack", "value": 1, "result_index": 0}
	roller.roll_pending([entry, entry.duplicate()], func(_i: int) -> Vector2: return Vector2.ZERO)
	_check(roller.has_pending(), "roll_pending: dice wait for a result")
	var res := {"faces": faces6, "face_type": "attack", "value": 5, "result_index": 4}
	_check(roller.resolve([res, res.duplicate()]) and not roller.has_pending(), "resolve: pending cleared")
	_check(int(roller._dice[1]["result_index"]) == 4 and int(roller._dice[1]["value"]) == 5, "resolve: the die holds its result")
	roller.skip()
	roller.queue_free()

	# Real-flight bookkeeping (the 3D flight itself is skipped headless, so the roller is armed by hand).
	await _flight_checks()

	# rtt_stats: nearest-rank p50 / p95.
	var rs := RemoteEpochSource.new()
	_check(int(rs.rtt_stats()["n"]) == 0 and int(rs.rtt_stats()["p95"]) == 0, "rtt_stats: empty = zeros")
	for ms in [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 20000]:
		rs.note_rtt("reroll", ms)
	var st := rs.rtt_stats()
	_check(int(st["n"]) == 20 and int(st["p50"]) == 1000 and int(st["p95"]) == 10000, "rtt_stats: p50 1000 / p95 10000 (got %s)" % str(st))

	CombatView.disable_juice_for_tests = false
	_guard.restore()
	if _fails.is_empty():
		print("PASS t_pre_throw (%d checks)" % _checks)
	else:
		for f in _fails:
			print("FAIL: ", f)
		print("FAIL t_pre_throw")
	get_tree().quit(0 if _fails.is_empty() else 1)
