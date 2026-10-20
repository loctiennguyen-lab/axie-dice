extends Node
## Depth v3 Hold (`stash`), design/proposals/depth-v3-design.md 3.2.

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	_basic()
	_refusals()
	_undo()
	print("=== t_stash: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("t_stash: FAIL - %s" % f)
	if _failures.is_empty():
		print("t_stash: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


func _engine(seed_value: int = 777) -> CombatEngine:
	var roster: Array = []
	for i in TEAM.size():
		roster.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var e := CombatEngine.new()
	e.setup_new({"node_id": "stash_node", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": roster, "relic_ids": [], "combat_seed": seed_value})
	return e


func _first_stashable(e: CombatEngine, skip: int = -1) -> Unit:
	for u in e.party:
		if (u as Unit).uid != skip and e.can_stash((u as Unit).uid):
			return u
	return null


func _basic() -> void:
	var e := _engine()
	var u := _first_stashable(e)
	_check(u != null, "no stashable die")
	if u == null:
		return
	var fi := u.roll_face_index()
	_check(e.stash(u.uid), "stash refused")
	_check(not e.use_die(u.uid, e.enemies[0].uid), "held die was usable")
	_check(e._rerollable([u.uid]).is_empty(), "held die was rerollable")
	_check(_first_stashable(e, u.uid) == null, "cap 1 not enforced")
	_check(e.stash_count() == 1, "stash_count")
	e.end_turn()
	if e.won or e.lost:
		return
	_check(u.roll_face_index() == fi and not u.roll_used(), "held die did not keep its face")
	_check(not u.held and u.stash_carry, "flags after turn change")
	_check(not e.can_stash(u.uid), "same die stashed two turns running")
	e.end_turn()
	if not (e.won or e.lost):
		_check(not u.stash_carry, "stash_carry not cleared after a normal roll")


func _refusals() -> void:
	var e := _engine()
	var u := _first_stashable(e)
	if u == null:
		return
	var fi := u.roll_face_index()
	var face: Dictionary = (u.die[fi] as Dictionary).duplicate(true)
	var kws: Array = (face.get("keywords", []) as Array).duplicate()
	kws.append("cantrip")
	face["keywords"] = kws
	u.die[fi] = face
	_check(not e.can_stash(u.uid), "cantrip die was stashable")
	kws.erase("cantrip")
	face["keywords"] = kws
	u.die[fi] = face
	u.frozen = true
	_check(not e.can_stash(u.uid), "frozen die was stashable")
	u.frozen = false
	u.mark_used()
	_check(not e.can_stash(u.uid), "used die was stashable")
	_check(not e.can_stash(999999), "unknown uid stashable")


func _undo() -> void:
	var e := _engine()
	var u := _first_stashable(e)
	if u == null:
		return
	_check(e.stash(u.uid), "stash")
	_check(e.undo_last(), "undo")
	var u2 := e.by_uid(u.uid)
	_check(not u2.held, "undo did not release the held die")


func _check(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)
