extends BoTestBase
## Depth v4 3.10.2 (N2/N3): the (rmode, uids, rsrc) lock per (turn, k); undo / save-load cannot re-choose; tamper of reroll actions on replay;
## the local epoch source pins (rmode, uids) too (pin_mismatch). design/gdd/dice-depth-v4.md, QA T1/T9.

const KEYS := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func run() -> void:
	_name = "t_reroll_pin"
	set_knobs("default")
	for s in [4, 15]:
		_undo_lock(s)
	_saveload()
	_tamper()
	_epoch_pin()
	_contract()


func _uids(e: CombatEngine, skip: int = -1) -> Array:
	var out: Array = []
	for u in e.party:
		if (u as Unit).uid != skip:
			out.append((u as Unit).uid)
	return out


func _play(e: CombatEngine, uid: int) -> bool:
	for t in e.alive_enemies():
		if e.use_die(uid, (t as Unit).uid):
			return true
	for t in e.party:
		if e.use_die(uid, (t as Unit).uid):
			return true
	return false


func _faces(e: CombatEngine) -> String:
	return JSON.stringify(e.party.map(func(u): return [u.roll_face_index(), u.cracked]))


func _undo_lock(seed_v: int) -> void:
	var e := engine(["r_infinitedie"], 20, seed_v)   # safeReroll: undo survives a reroll
	e.rerolls = 1   # the relic also gives free charges; keep exactly the base one
	var b: int = _uids(e)[1]
	ok(e.reroll_dice(_uids(e)), "[%d] free reroll k1" % seed_v)
	var snap_ok := _play(e, b)   # snapshot with reroll_k = 1
	ok(snap_ok, "[%d] play die B" % seed_v)
	var list := _uids(e, b)
	ok(e.reroll_dice(list, -1, false, 0), "[%d] Lieu at k2" % seed_v)
	var seen := _faces(e)
	eq(e.reroll_k, 2, "k2")
	ok(e.undo_last(), "[%d] undo (safeReroll keeps the stack through the reroll)" % seed_v)
	eq(e.reroll_k, 1, "undo rewinds reroll_k")
	ok(e.reroll_lock.has(2), "lock survives undo")
	# switching to Safe, to another list, or to Aid at the same k is refused, nothing changes
	var before := digest(e)
	eq(e.reroll_refusal(list, false, 1), "pin_mismatch", "undo then Safe refused")
	ok(not e.reroll_dice(list, -1, false, 1), "[%d] reroll_dice Safe after pin returns false" % seed_v)
	eq(e.reroll_refusal(_uids(e), false, 0), "pin_mismatch", "undo then another uid list refused")
	eq(e.reroll_refusal(list, true, 1), "pin_mismatch", "undo then Aid (rsrc) refused")
	eq(digest(e), before, "refusals leave the state untouched")
	# N2: use one of the locked dice -> the list cannot repeat; undo is the way out
	var c: int = list[0]
	ok(_play(e, c), "play a locked die")
	eq(e.reroll_refusal(list, false, 0), "pin_mismatch", "N2: used die in the locked list -> false, no k jump")
	eq(e.reroll_k, 1, "k did not move")
	ok(e.undo_last(), "undo the play")
	# exact repeat gives the same faces and Crack
	ok(e.reroll_dice(list, -1, false, 0), "[%d] exact repeat allowed" % seed_v)
	eq(_faces(e), seen, "[%d] same faces and Crack on the repeat" % seed_v)


func _saveload() -> void:
	var e := engine(["r_infinitedie"], 20, 4)
	e.rerolls = 1
	var all := _uids(e)
	e.reroll_dice(all)
	e.reroll_dice(all, -1, false, 0)
	var seen := _faces(e)
	var e2 := CombatEngine.new()
	e2.from_data(JSON.parse_string(JSON.stringify(e.to_data())))
	eq(_faces(e2), seen, "load keeps faces and Crack")
	ok(e2.reroll_lock.has(2) and e2.reroll_lock.has(1), "lock keys are ints again after load")
	eq(e2.reroll_paid_k, 1, "paid_k saved")
	eq(e2.reroll_total_turn, 2, "total saved")
	# a load that rewound reroll_k (state of k=1 but lock of k=2) cannot switch mode
	var d: Dictionary = JSON.parse_string(JSON.stringify(e.to_data()))
	d["reroll_k"] = 1
	d["rerolls"] = 0
	d["reroll_paid_k"] = 0
	d["reroll_total_turn"] = 1
	var e3 := CombatEngine.new()
	e3.from_data(d)
	eq(e3.reroll_refusal(all, false, 1), "pin_mismatch", "save/load then Safe at the locked k refused")
	ok(e3.can_reroll(all, false, 0), "save/load then the same Lieu is still allowed")


func _tamper() -> void:
	# a recorded turn: free, Lieu, Safe (mana 20)
	var log := ActionLog.new()
	log.begin(8, KEYS, "short", 0, "test")
	var e := engine([], 20, 8)
	e.action_log = log
	var all := _uids(e)
	ok(e.reroll_dice(all) and e.reroll_dice(all, -1, false, 0) and e.reroll_dice(all, -1, false, 1), "record free, Lieu, Safe")
	var played := digest(e)
	var good := _replay(log.entries, 20)
	ok(bool(good["ok"]), "honest replay accepted")
	eq(good["digest"], played, "honest replay = live digest")
	# T1: rmode of the Lieu flipped to 1 (more mana spent / no Crack)
	var t1 := _copy(log.entries)
	(t1[1]["args"] as Array)[2] = 1
	var r1 := _replay(t1, 20)
	ok(not bool(r1["ok"]) or r1["digest"] != played, "T1 flipped rmode changes the replay")
	var r1b := _replay(t1, 0)
	ok(not bool(r1b["ok"]), "T1 flipped rmode with no mana is refused at that action")
	ok(bool(r1b["ok"]) or int(r1b["at"]) == 1 or int(r1b["at"]) == 2, "T1 refused at the tampered action (or the next paid one)")
	# missing mana: the paid Safe reroll with 0 mana
	var r2 := _replay(log.entries, 0)
	ok(not bool(r2["ok"]) and int(r2["at"]) == 2, "no mana: the Safe reroll is refused at action 2")
	# over max_total: a fourth chosen reroll appended
	var t3 := _copy(log.entries)
	t3.append({"fn": "reroll_dice", "args": [all.duplicate(), 0, 0]})
	var r3 := _replay(t3, 20)
	ok(not bool(r3["ok"]) and int(r3["at"]) == 3, "over max_total refused at the extra action")
	# hard_cap: extra Aid beyond 4
	var t4 := _copy(log.entries)
	t4.append({"fn": "reroll_dice", "args": [all.duplicate(), 1, 1]})
	t4.append({"fn": "reroll_dice", "args": [all.duplicate(), 1, 1]})
	var r4 := _replay(t4, 20)
	ok(not bool(r4["ok"]) and int(r4["at"]) == 4, "hard_cap 4 refused at the 5th reroll")
	# T9: other uids on the Lieu change the Crack/faces
	var t9 := _copy(log.entries)
	t9[1]["args"][0] = _uids(e).slice(0, 3)
	var r9 := _replay(t9, 20)
	ok(not bool(r9["ok"]) or r9["digest"] != played, "T9 other uids change the replay")
	# fake Crack: a Lieu entry written as Safe-with-free (rmode 1) cannot reproduce a Crack
	var cracked_live := 0
	for u in e.party:
		cracked_live += 1 if (u as Unit).cracked else 0
	ok(cracked_live == 0 or r1["digest"] != played, "no way to keep a Crack without a Lieu entry")


func _copy(entries: Array) -> Array:
	return JSON.parse_string(JSON.stringify(entries))


func _replay(entries: Array, mana: int) -> Dictionary:
	var r := engine([], mana, 8)
	var i := 0
	for en in entries:
		if not RunVerifier._apply_combat(r, String(en["fn"]), en["args"]):
			return {"ok": false, "at": i, "digest": ""}
		i += 1
	return {"ok": true, "at": -1, "digest": digest(r)}


func _epoch_pin() -> void:
	var s := LocalEpochSource.new()
	# the local source is covered by t_epoch_source for chain setup; here we poke the pin helper directly
	var sig_a := s._pin_sig({"uids": [1, 2], "rmode": 0})
	eq(sig_a, s._pin_sig({"uids": [1, 2], "rmode": 0}), "same signature")
	ok(sig_a != s._pin_sig({"uids": [1, 2], "rmode": 1}), "rmode is part of the pin signature")
	ok(sig_a != s._pin_sig({"uids": [2, 1], "rmode": 0}), "uid order is part of the pin signature")
	eq(s._pin_sig({"uids": [1]}), s._pin_sig({"uids": [1], "rmode": 1}), "missing rmode = 1")


func _contract() -> void:
	# t_depth_epoch_args_contract: the shared JSON knows rmode for reroll only, with int values 0/1, and keeps `mode` as short/full
	var f := FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../worker/src/epoch_args.json"), FileAccess.READ)
	ok(f != null, "epoch_args.json readable")
	if f == null:
		return
	var spec: Dictionary = JSON.parse_string(f.get_as_text())
	var rm: Dictionary = spec["args"]["rmode"]
	eq(JSON.stringify((rm["values"] as Array).map(func(v): return int(v))), "[0,1]", "rmode enum 0/1")
	eq(JSON.stringify(spec["args"]["mode"]["values"]), '["short","full"]', "mode stays short/full")
	for kind in spec["kinds"]:
		eq((spec["kinds"][kind]["keys"] as Array).has("rmode"), kind == "reroll", "rmode only in reroll (%s)" % kind)
	ok(not (spec["kinds"]["reroll"]["required"] as Array).has("rmode"), "rmode optional (older logs)")
	# the engine sends exactly the keys the spec allows
	var e := engine([], 0, 3)
	var args := e._reroll_args(_uids(e), false, 0)
	for k in args:
		ok((spec["kinds"]["reroll"]["keys"] as Array).has(k), "engine arg %s is in the vocabulary" % k)
	eq(int(args["rmode"]), 1, "free charge sends rmode 1 even if 0 asked")
