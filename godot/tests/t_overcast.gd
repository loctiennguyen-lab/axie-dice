extends Node
## Overcast (lane OC): pay mana to power ONE die up for the turn. Effect, price, limits, preview, undo, replay, tamper.
## Knobs: combat_tune.json overcast.mana_cost / add / per_turn. Depth v4 3.7: Overcast adds +overcast.add to the M bag (with the Set), one integer multiply at step 4, before face_final; no own x1.5.

var _guard := SaveGuard.new()
const SEED := 424242
var _fail: Array[String] = []
var _checks := 0


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	_t_effect_price_preview()
	_t_limits()
	_t_undo_and_stash()
	_t_replay_and_tamper()
	print("=== t_overcast: %d checks, %d failure(s) ===" % [_checks, _fail.size()])
	_guard.restore()
	if _fail.is_empty():
		print("t_overcast: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fail:
		print("t_overcast: FAIL - %s" % f)
	get_tree().quit(1)


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _engine(mana: int) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup_new({"node_id": "oc", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": _roster(),
		"relic_ids": [], "combat_seed": SEED, "start_mana": mana})
	return e


func _roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1, "max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [], "growth": {}, "bonus_hp": 0})
	return out


## uids of dice that can be overcast right now (given enough mana).
func _candidates(e: CombatEngine) -> Array:
	var out: Array = []
	for u in e.party:
		if e.can_overcast((u as Unit).uid):
			out.append((u as Unit).uid)
	return out


func _t_effect_price_preview() -> void:
	var e := _engine(5)
	var c := _candidates(e)
	_ok(c.size() >= 2, "need two overcastable dice on this seed (got %d)" % c.size())
	if c.size() < 2:
		return
	var u: Unit = e.by_uid(int(c[0]))
	var pv := e.overcast_preview(u)
	var plain := int(pv[0])
	var base_v := int(e._face_base(u, u.roll_face_index()))
	u.overcast = true
	var m_oc := e.m100_for(u)
	u.overcast = false
	_ok(int(pv[1]) == (base_v * m_oc + 99) / 100, "preview %s is not the M-bag value %d" % [str(pv), (base_v * m_oc + 99) / 100])
	_ok(int(pv[1]) > plain, "overcast must raise the value")
	var rng_before: int = e._rng.get_state()
	var m0 := e.mana
	_ok(e.overcast(u.uid), "overcast refused a legal die")
	_ok(e.mana == m0 - 3, "overcast must cost 3 mana (had %d, now %d)" % [m0, e.mana])
	_ok(u.overcast, "die not flagged")
	_ok(e._face_value(u, u.roll_face_index()) == int(pv[1]), "face value does not match the preview")
	var rng_after: int = e._rng.get_state()
	_ok(rng_before == rng_after, "overcast drew rng")
	# preview_damage reflects it
	var foe: Unit = e.alive_enemies()[0]
	if String(u.current_face().get("type", "")) == "dmg":
		_ok(int(e.preview_damage(u, foe, u.roll_face_index())["raw"]) == int(pv[1]), "preview_damage ignores overcast")
	# real use lands the boosted value
	var hp0 := foe.hp + foe.shield
	if String(u.current_face().get("type", "")) == "dmg" and e.use_die(u.uid, foe.uid):
		_ok(hp0 - (foe.hp + foe.shield) >= int(pv[1]), "boosted dmg not applied")
	# a mana face never takes overcast
	var e2 := _engine(5)
	for x in e2.party:
		if String((x as Unit).current_face().get("type", "")) == "mana":
			_ok(not e2.can_overcast((x as Unit).uid), "overcast allowed on a mana face")


func _t_limits() -> void:
	var e := _engine(1)
	var c := _engine(5)
	_ok(_candidates(e).is_empty(), "overcast allowed with 1 mana")
	var uid_any := (e.party[0] as Unit).uid
	_ok(not e.overcast(uid_any), "overcast with too little mana succeeded")
	_ok(e.overcast_block_reason(uid_any) != "", "disabled overcast has no reason")
	var cand := _candidates(c)
	if cand.size() < 2:
		_ok(false, "need 2 candidates")
		return
	_ok(c.overcast(int(cand[0])), "first overcast refused")
	_ok(not c.overcast(int(cand[1])), "second overcast in one turn accepted")
	_ok(c.overcast_block_reason(int(cand[1])) == "1 Overcast per turn", "wrong reason: %s" % c.overcast_block_reason(int(cand[1])))
	_ok(not c.overcast(int(cand[0])), "same die overcast twice")
	# used die refused
	var d := _engine(5)
	var dc := _candidates(d)
	var u: Unit = d.by_uid(int(dc[0]))
	for t in d.alive_enemies():
		if d.use_die(u.uid, (t as Unit).uid):
			break
	if u.roll_used():
		_ok(not d.overcast(u.uid), "overcast on a used die accepted")
	# next turn clears the flag
	c.end_turn()
	_ok(c.overcast_count() == 0, "flag survived the turn change")


func _t_undo_and_stash() -> void:
	var e := _engine(5)
	var cand := _candidates(e)
	var uid := int(cand[0])
	_ok(e.overcast(uid), "overcast refused")
	_ok(not e.can_stash(uid), "an overcast die can be held")
	_ok(e.undo_last(), "undo refused")
	_ok(e.mana == 5 and not (e.by_uid(uid) as Unit).overcast, "undo did not restore mana/flag")
	# a held die cannot be overcast
	for u in e.party:
		if e.can_stash((u as Unit).uid):
			e.stash((u as Unit).uid)
			_ok(not e.can_overcast((u as Unit).uid), "held die can be overcast")
			break


func _play(e: CombatEngine, log: ActionLog) -> void:
	e.action_log = log
	var cand := _candidates(e)
	e.overcast(int(cand[0]))
	var u: Unit = e.by_uid(int(cand[0]))
	var targets: Array = e.alive_enemies() + e.alive_party()
	for t in targets:
		if e.use_die(u.uid, (t as Unit).uid):
			break
	_ok(u.roll_used(), "test setup: the overcast die could not be used")
	e.end_turn()


func _replay(log: ActionLog, mana: int) -> Dictionary:
	var e := _engine(mana)
	for en in log.entries:
		var fn := String(en["fn"])
		var a: Array = en["args"]
		var ok := true
		match fn:
			"overcast":
				ok = e.overcast(int(a[0]))
			"use_die":
				ok = e.use_die(int(a[0]), int(a[1]))
			"end_turn":
				e.end_turn()
		if not ok:
			return {"ok": false, "digest": ""}
	var d: Dictionary = e.to_data().duplicate(true)
	d.erase("undo_stack")
	return {"ok": true, "digest": JSON.stringify(d)}


func _t_replay_and_tamper() -> void:
	var log := ActionLog.new()
	log.begin(SEED, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 0, "test")
	var e := _engine(5)
	_play(e, log)
	_ok(log.size() >= 2 and String(log.entries[0]["fn"]) == "overcast", "overcast not recorded first")
	var played: Dictionary = e.to_data().duplicate(true)
	played.erase("undo_stack")
	var r := _replay(log, 5)
	_ok(bool(r["ok"]) and String(r["digest"]) == JSON.stringify(played), "overcast did not replay to the same state")
	# tamper 1: not enough mana
	_ok(not bool(_replay(log, 2)["ok"]), "replay accepted an overcast without the mana")
	# tamper 2: drop the overcast, state must differ
	var no_oc := ActionLog.from_data(JSON.parse_string(JSON.stringify(log.to_data())))
	no_oc.entries.remove_at(0)
	var rn := _replay(no_oc, 5)
	_ok(not bool(rn["ok"]) or String(rn["digest"]) != JSON.stringify(played), "dropping the overcast changed nothing")
	# tamper 3: two overcasts in one turn
	var twice := ActionLog.from_data(JSON.parse_string(JSON.stringify(log.to_data())))
	var second: Dictionary = (twice.entries[0] as Dictionary).duplicate(true)
	var other := -1
	for u in e.party:
		if (u as Unit).uid != int(second["args"][0]):
			other = (u as Unit).uid
			break
	second["args"] = [other]
	twice.entries.insert(1, second)
	_ok(not bool(_replay(twice, 9)["ok"]), "replay accepted two overcasts in one turn")
	# tamper 4: overcast of a die already used
	var late := ActionLog.from_data(JSON.parse_string(JSON.stringify(log.to_data())))
	var ov: Dictionary = (late.entries[0] as Dictionary).duplicate(true)
	late.entries.remove_at(0)
	late.entries.insert(1, ov)   # after use_die (entry 0 is now use_die)
	_ok(not bool(_replay(late, 9)["ok"]), "replay accepted an overcast of a used die")
