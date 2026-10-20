extends BoTestBase
## design 8.1 t_bo_replay (engine half): a fight with a Set + Overcast, recorded then re-applied on a fresh engine, ends in the same digest;
## a dropped or retargeted action changes it. The run-level RunVerifier replay of Set fights is covered by t_replay (BO is always live).

const KEYS := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]

func run() -> void:
	_name = "t_bo_replay"
	set_knobs("default")
	var seed_v := _find_seed()
	ok(seed_v >= 0, "found a seed that rolls a Set on turn 1")
	if seed_v < 0:
		return
	var log := ActionLog.new()
	log.begin(seed_v, KEYS, "short", 0, "test")
	var e := engine([], 6, seed_v)
	e.action_log = log
	var member: Unit = e.by_uid(int((e.bo[0]["uids"] as Array)[0]))
	ok(e.overcast(member.uid), "overcast a Set member")
	for u in e.party:
		for t in e.alive_enemies():
			if e.use_die((u as Unit).uid, (t as Unit).uid):
				break
	e.end_turn()
	e.end_turn()
	var played := digest(e)
	var r := _replay(log, seed_v)
	ok(r["ok"], "replay accepted every action")
	eq(r["digest"], played, "replay = live digest, with a Set in play")
	var no_oc := ActionLog.from_data(JSON.parse_string(JSON.stringify(log.to_data())))
	no_oc.entries.remove_at(0)
	var rn := _replay(no_oc, seed_v)
	ok(not rn["ok"] or rn["digest"] != played, "dropping the Overcast changes the outcome")


func _find_seed() -> int:
	for s in range(1, 400):
		var e := engine([], 6, s)
		if not e.bo.is_empty():
			return s
	return -1


func _replay(log: ActionLog, seed_v: int) -> Dictionary:
	var e := engine([], 6, seed_v)
	for en in log.entries:
		var a: Array = en["args"]
		var good := true
		match String(en["fn"]):
			"overcast":
				good = e.overcast(int(a[0]))
			"use_die":
				good = e.use_die(int(a[0]), int(a[1]))
			"end_turn":
				e.end_turn()
		if not good:
			return {"ok": false, "digest": ""}
	return {"ok": true, "digest": digest(e)}
