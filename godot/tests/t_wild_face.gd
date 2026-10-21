extends BoTestBase
## design 3.6 / 3.10.5 / 3.10.10 t_wild_face: Mat Tam (wild_face). MD 22/10: price 2, 1 per FIGHT, only 3 -> 4 (need_set3), never 5 (set5), refusals leave mana alone, only the Set part changes,
## no reroll / Hold, undo, save/load, expires at roll_all, replay tamper (missing mana, 2nd use, bad die, slot out of range).

func run() -> void:
	_name = "t_wild_face"
	for knobs in ["nominal", "default"]:
		set_knobs(knobs)
		_core(knobs)
	set_knobs("default")
	_refusals()
	_undo_save_expire()
	_replay_tamper()


func _core(tag: String) -> void:
	# two Horns (part 1) + three others: a third Horn via Mat Tam makes Set of three
	var e := engine([], 10)
	force(e, [1, 1, 1, 2, 3])
	eq(e.bo.size(), 1, tag + ": the Set of three exists before Mat Tam")
	var face_before := JSON.stringify(e.party[3].die[2])
	eq(e.bo.size(), 1, tag + ": Set of three already there")
	var m0 := e.mana
	ok(e.wild_face(e.party[3].uid, 1), tag + ": wild_face accepted")
	eq(e.mana, m0 - e.wild_cost(), tag + ": costs wild.cost")
	eq(e.wild_used, 1, tag + ": wild_used")
	eq(e.party[3].wild_slot, 1, tag + ": slot stored")
	eq(e.bo.size(), 1, tag + ": still one Set")
	eq(int(e.bo[0]["part"]), 1, tag + ": part is the Mat Tam slot")
	eq((e.bo[0]["uids"] as Array).size(), 4, tag + ": three became four")
	ok((e.bo[0]["uids"] as Array).has(e.party[3].uid), tag + ": wild die is a member")
	eq(JSON.stringify(e.party[3].die[2]), face_before, tag + ": real face untouched")
	eq(e.party[3].roll_face_index(), 2, tag + ": roll index untouched")
	eq(e._face_value(e.party[3], 2), int(ceil(5.0 * e.m100_for(e.party[3]) / 100.0)), tag + ": member gets the M bag")
	# preview is pure and matches (checked on a twin before the action)
	var pv_e := engine([], 10)
	force(pv_e, [1, 1, 1, 2, 3])
	var snap := digest(pv_e)
	var pv := pv_e.preview_wild(pv_e.party[3].uid, 1)
	eq(digest(pv_e), snap, tag + ": preview_wild leaves state alone")
	ok(bool(pv["ok"]) and pv["bo_label"] == "BỘ BỐN", tag + ": preview label")
	eq(int(round(float(pv["mult"]) * 100.0)), int(e.bo[0]["m100"]), tag + ": preview mult = real M")
	ok(not bool(pv_e.preview_wild(pv_e.party[3].uid, 5)["ok"]) and pv_e.preview_wild(pv_e.party[3].uid, 5)["reason"] == "need_set3", tag + ": preview flags a slot with no Set of three")
	# one per turn
	var m1 := e.mana
	ok(not e.wild_face(e.party[4].uid, 1), tag + ": second Mat Tam refused")
	eq(e.mana, m1, tag + ": mana kept")
	# no reroll, no Hold
	eq(e._rerollable([e.party[3].uid]).size(), 0, tag + ": wild die not rerollable")
	ok(not e.can_stash(e.party[3].uid), tag + ": wild die not holdable")
	# Overcast on the now four-strong Set is allowed
	ok(e.overcast(e.party[3].uid), tag + ": overcast on the Set with the wild die")


func _refusals() -> void:
	var e := engine([], 10)
	force(e, [1, 1, 1, 2, 3])
	var m := e.mana
	ok(not e.wild_face(e.party[3].uid, 6), "slot 6 refused")
	ok(not e.wild_face(e.party[3].uid, -1), "slot -1 refused")
	ok(not e.wild_face(e.party[3].uid, 2), "own part refused")
	eq(e.wild_block_reason(e.party[3].uid, 5), "need_set3", "slot with no Set of three refused")
	eq(e.wild_block_reason(e.party[4].uid, 2), "need_set3", "a pair becoming three is refused (3 -> 4 only)")
	ok(not e.wild_face(999, 1), "unknown uid refused")
	ok(not e.wild_face(e.enemies[0].uid, 1), "enemy refused")
	eq(e.mana, m, "refusals keep mana")
	# state refusals, one die each, each on a fresh board
	var cases := {
		"used": func(x: CombatEngine): x.party[3].rolled[0]["used"] = true,
		"held": func(x: CombatEngine): x.party[3].held = true,
		"cracked": func(x: CombatEngine): x.party[3].cracked = true,
		"phantom": func(x: CombatEngine): x.party[3].custom_state["phantom"] = true,
		"token": func(x: CombatEngine): x.party[3].is_token = true,
		"dead": func(x: CombatEngine): x.party[3].hp = 0,
		"cantrip": func(x: CombatEngine): x.party[3].die[2]["keywords"] = ["cantrip"],
	}
	for k in cases:
		var x := engine([], 10)
		var m10 := x.mana
		force(x, [1, 1, 1, 2, 3], null, false)
		(cases[k] as Callable).call(x)
		x._snap_bo()
		ok(not x.wild_face(x.party[3].uid, 1), k + " refused")
		eq(x.mana, m10, k + ": mana kept")
	var xm := engine([], 1)
	xm.mana = 1
	force(xm, [1, 1, 1, 2, 3])
	ok(not xm.wild_face(xm.party[3].uid, 1), "1 mana refused")
	eq(xm.mana, 1, "mana never negative")
	var xs := engine([], 10, 7, 1)
	force(xs, [1, 1, 1, 2, 3])
	ok(not xs.wild_face(xs.party[3].uid, 1), "stage 1 refused")
	var x2 := engine([], 10, 7, 2)
	force(x2, [1, 1, 1, 2, 3])
	ok(x2.wild_face(x2.party[3].uid, 1), "stage 2 allowed")
	# Mat Tam from a pair is refused with need_set3 and keeps mana (MD 22/10)
	var xp := engine([], 10)
	force(xp, [1, 1, 2, 3, 4])
	var mp := xp.mana
	eq(xp.wild_block_reason(xp.party[2].uid, 1), "need_set3", "pair + wild = three: need_set3")
	ok(not xp.wild_face(xp.party[2].uid, 1), "pair -> three refused")
	eq(xp.mana, mp, "need_set3 keeps mana")
	eq(xp.wild_used, 0, "need_set3 does not use the fight's Wild")
	# A+ (Liam 22/10): Wild Face can never make a Set of five (four natural + wild = five refused, mana kept)
	var x5 := engine([], 10)
	force(x5, [1, 1, 1, 1, 3])
	var m5 := x5.mana
	eq(x5.wild_block_reason(x5.party[4].uid, 1), "set5", "four + wild = five: reason set5")
	ok(not x5.wild_face(x5.party[4].uid, 1), "Set of five via Wild Face refused")
	eq(x5.mana, m5, "set5 refusal keeps mana")
	eq(x5.wild_used, 0, "set5 refusal does not use the turn's Wild")
	var pv5 := x5.preview_wild(x5.party[4].uid, 1)
	ok(not bool(pv5["ok"]) and pv5["reason"] == "set5", "preview_wild reflects set5")
	# three -> four is still fine
	var x4 := engine([], 10)
	force(x4, [1, 1, 1, 2, 3])
	ok(x4.wild_face(x4.party[3].uid, 1), "three + wild = four allowed")
	eq(int(x4.bo[0]["size"]), 4, "Set of four")
	# Concord: only the first die of a class counts; the other is refused
	var xc := engine(["c_concord"], 10, 7, 3, ["plant1", "plant1", "beast1", "aqua1", "reptile1"])
	var mc := xc.mana
	force(xc, [1, 1, 1, 2, 3])
	ok(not xc.wild_face(xc.party[1].uid, 2), "Concord-excluded second plant refused")
	eq(xc.mana, mc, "Concord refusal keeps mana")


func _undo_save_expire() -> void:
	var e := engine([], 10)
	force(e, [1, 1, 1, 2, 3])
	var bo0 := JSON.stringify(e.bo)
	var m_pre := e.mana
	ok(e.wild_face(e.party[3].uid, 1), "wild")
	var bo1 := JSON.stringify(e.bo)
	var e2 := CombatEngine.new()
	e2.from_data(JSON.parse_string(JSON.stringify(e.to_data())))
	eq(e2.wild_used, 1, "wild_used saved")
	eq(e.party[3].wild_slot, 1, "wild slot set")
	eq(e2.party[3].wild_slot, 1, "wild_slot saved")
	eq(JSON.stringify(e2.bo), bo1, "bo saved")
	eq(digest(e2), JSON.stringify(JSON.parse_string(digest(e))), "state equal after load")
	ok(e.undo_last(), "undo")
	eq(e.mana, m_pre, "undo refunds mana")
	eq(e.wild_used, 0, "undo gives the fight's Wild back")
	eq(e.party[3].wild_slot, -1, "undo clears slot")
	eq(JSON.stringify(e.bo), bo0, "undo restores bo")
	ok(e.wild_face(e.party[3].uid, 1), "usable again after undo")
	# expires at the next roll, no refund
	var mana_before := e.mana
	e.roll_all()
	eq(e.party[3].wild_slot, -1, "wild_slot gone after roll_all")
	eq(e.wild_used, 1, "wild_used is per FIGHT: survives roll_all")
	ok(e.mana >= mana_before, "no refund, no extra charge")
	# second turn: refused with `limit` even with a fresh Set of three
	force(e, [1, 1, 1, 2, 3])
	e.mana = 10
	eq(e.wild_block_reason(e.party[3].uid, 1), "limit", "2nd Mat Tam in the same fight: limit")
	ok(not e.wild_face(e.party[3].uid, 1), "2nd Mat Tam in the fight refused")
	# a new fight resets it, and so does a save round trip keep it
	var e3 := CombatEngine.new()
	e3.from_data(JSON.parse_string(JSON.stringify(e.to_data())))
	eq(e3.wild_used, 1, "wild_used saved across turns")
	var fresh := engine([], 10)
	eq(fresh.wild_used, 0, "new fight starts at 0")


func _replay_tamper() -> void:
	var log := ActionLog.new()
	var e := engine([], 10)
	e.action_log = log
	force(e, [1, 1, 1, 2, 3])
	ok(e.wild_face(e.party[3].uid, 1), "recorded wild_face")
	var entry: Dictionary = log.entries[log.entries.size() - 1]
	eq(String(entry["fn"]), "wild_face", "logged as wild_face")
	eq(entry["args"], [e.party[3].uid, 1], "args [uid, slot]")
	ok(ActionLog.ALLOWED_FNS.has("wild_face"), "wild_face in ALLOWED_FNS")
	# replays on a twin
	var t := engine([], 10)
	force(t, [1, 1, 1, 2, 3])
	ok(t.wild_face(int(entry["args"][0]), int(entry["args"][1])), "twin accepts the recorded move")
	eq(digest(t), digest(e), "twin ends equal")
	# tampers: each one is refused by the engine the verifier drives
	var lo := engine([], 1)
	lo.mana = 1
	force(lo, [1, 1, 1, 2, 3])
	ok(not lo.wild_face(lo.party[3].uid, 1), "tamper: not enough mana")
	var twice := engine([], 10)
	force(twice, [1, 1, 1, 2, 3])
	twice.wild_face(twice.party[3].uid, 1)
	ok(not twice.wild_face(twice.party[4].uid, 1), "tamper: second use in a fight")
	var pair := engine([], 10)
	force(pair, [1, 1, 2, 3, 4])
	ok(not pair.wild_face(pair.party[2].uid, 1), "tamper: Mat Tam from a pair")
	var bad := engine([], 10)
	force(bad, [1, 1, 1, 2, 3])
	bad.party[3].held = true
	ok(not bad.wild_face(bad.party[3].uid, 1), "tamper: invalid die")
	ok(not bad.wild_face(bad.party[3].uid, 9), "tamper: slot out of range")
