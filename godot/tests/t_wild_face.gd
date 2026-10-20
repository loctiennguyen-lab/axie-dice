extends BoTestBase
## design 3.6 / 3.10.5 / 3.10.10 t_wild_face: Mat Tam (wild_face). Price 2, 1 per turn, refusals leave mana alone, only the Set part changes,
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
	force(e, [1, 1, 2, 3, 4])
	eq(e.bo.size(), 0, tag + ": no Set yet")
	var face_before := JSON.stringify(e.party[2].die[2])
	var m0 := e.mana
	ok(e.wild_face(e.party[2].uid, 1), tag + ": wild_face accepted")
	eq(e.mana, m0 - 2, tag + ": costs wild.cost")
	eq(e.wild_used, 1, tag + ": wild_used")
	eq(e.party[2].wild_slot, 1, tag + ": slot stored")
	eq(e.bo.size(), 1, tag + ": Set of three appears")
	eq(int(e.bo[0]["part"]), 1, tag + ": part is the Mat Tam slot")
	eq((e.bo[0]["uids"] as Array).size(), 3, tag + ": three members")
	ok((e.bo[0]["uids"] as Array).has(e.party[2].uid), tag + ": wild die is a member")
	eq(JSON.stringify(e.party[2].die[2]), face_before, tag + ": real face untouched")
	eq(e.party[2].roll_face_index(), 2, tag + ": roll index untouched")
	eq(e._face_value(e.party[2], 2), int(ceil(5.0 * e.m100_for(e.party[2]) / 100.0)), tag + ": member gets the M bag")
	# preview is pure and matches (checked on a twin before the action)
	var pv_e := engine([], 10)
	force(pv_e, [1, 1, 2, 3, 4])
	var snap := digest(pv_e)
	var pv := pv_e.preview_wild(pv_e.party[2].uid, 1)
	eq(digest(pv_e), snap, tag + ": preview_wild leaves state alone")
	ok(bool(pv["ok"]) and pv["bo_label"] == "BỘ BA", tag + ": preview label")
	eq(int(round(float(pv["mult"]) * 100.0)), int(e.bo[0]["m100"]), tag + ": preview mult = real M")
	ok(not bool(pv_e.preview_wild(pv_e.party[2].uid, 5)["ok"]), tag + ": preview flags a useless slot")
	# one per turn
	var m1 := e.mana
	ok(not e.wild_face(e.party[3].uid, 1), tag + ": second Mat Tam refused")
	eq(e.mana, m1, tag + ": mana kept")
	# no reroll, no Hold
	eq(e._rerollable([e.party[2].uid]).size(), 0, tag + ": wild die not rerollable")
	ok(not e.can_stash(e.party[2].uid), tag + ": wild die not holdable")
	# Overcast on the same die is allowed (5 mana total)
	ok(e.overcast(e.party[2].uid), tag + ": overcast on wild die")


func _refusals() -> void:
	var e := engine([], 10)
	force(e, [1, 1, 2, 3, 4])
	var m := e.mana
	ok(not e.wild_face(e.party[2].uid, 6), "slot 6 refused")
	ok(not e.wild_face(e.party[2].uid, -1), "slot -1 refused")
	ok(not e.wild_face(e.party[2].uid, 2), "own part refused")
	ok(not e.wild_face(e.party[2].uid, 5), "slot with n<3 after attach refused (useless)")
	ok(not e.wild_face(999, 1), "unknown uid refused")
	ok(not e.wild_face(e.enemies[0].uid, 1), "enemy refused")
	eq(e.mana, m, "refusals keep mana")
	# state refusals, one die each, each on a fresh board
	var cases := {
		"used": func(x: CombatEngine): x.party[2].rolled[0]["used"] = true,
		"held": func(x: CombatEngine): x.party[2].held = true,
		"cracked": func(x: CombatEngine): x.party[2].cracked = true,
		"phantom": func(x: CombatEngine): x.party[2].custom_state["phantom"] = true,
		"token": func(x: CombatEngine): x.party[2].is_token = true,
		"dead": func(x: CombatEngine): x.party[2].hp = 0,
		"cantrip": func(x: CombatEngine): x.party[2].die[2]["keywords"] = ["cantrip"],
	}
	for k in cases:
		var x := engine([], 10)
		var m10 := x.mana
		force(x, [1, 1, 2, 3, 4], null, false)
		(cases[k] as Callable).call(x)
		x._snap_bo()
		ok(not x.wild_face(x.party[2].uid, 1), k + " refused")
		eq(x.mana, m10, k + ": mana kept")
	var xm := engine([], 1)
	xm.mana = 1
	force(xm, [1, 1, 2, 3, 4])
	ok(not xm.wild_face(xm.party[2].uid, 1), "1 mana refused")
	eq(xm.mana, 1, "mana never negative")
	var xs := engine([], 10, 7, 1)
	force(xs, [1, 1, 2, 3, 4])
	ok(not xs.wild_face(xs.party[2].uid, 1), "stage 1 refused")
	var x2 := engine([], 10, 7, 2)
	force(x2, [1, 1, 2, 3, 4])
	ok(x2.wild_face(x2.party[2].uid, 1), "stage 2 allowed")
	# already wild
	var xw := engine([], 10)
	force(xw, [1, 1, 2, 2, 2])
	ok(xw.wild_face(xw.party[4].uid, 1), "wild on a die already in a Set")
	# Concord: only the first die of a class counts; the other is refused
	var xc := engine(["c_concord"], 10, 7, 3, ["plant1", "plant1", "beast1", "aqua1", "reptile1"])
	var mc := xc.mana
	force(xc, [1, 1, 2, 3, 4])
	ok(not xc.wild_face(xc.party[1].uid, 2), "Concord-excluded second plant refused")
	eq(xc.mana, mc, "Concord refusal keeps mana")


func _undo_save_expire() -> void:
	var e := engine([], 10)
	force(e, [1, 1, 2, 3, 4])
	var bo0 := JSON.stringify(e.bo)
	var m_pre := e.mana
	ok(e.wild_face(e.party[2].uid, 1), "wild")
	var bo1 := JSON.stringify(e.bo)
	var e2 := CombatEngine.new()
	e2.from_data(JSON.parse_string(JSON.stringify(e.to_data())))
	eq(e2.wild_used, 1, "wild_used saved")
	eq(e2.party[2].wild_slot, 1, "wild_slot saved")
	eq(JSON.stringify(e2.bo), bo1, "bo saved")
	eq(digest(e2), JSON.stringify(JSON.parse_string(digest(e))), "state equal after load")
	ok(e.undo_last(), "undo")
	eq(e.mana, m_pre, "undo refunds mana")
	eq(e.wild_used, 0, "undo resets wild_used")
	eq(e.party[2].wild_slot, -1, "undo clears slot")
	eq(JSON.stringify(e.bo), bo0, "undo restores bo")
	ok(e.wild_face(e.party[2].uid, 1), "usable again after undo")
	# expires at the next roll, no refund
	var mana_before := e.mana
	e.roll_all()
	eq(e.party[2].wild_slot, -1, "wild_slot gone after roll_all")
	eq(e.wild_used, 0, "wild_used reset")
	ok(e.mana >= mana_before, "no refund, no extra charge")


func _replay_tamper() -> void:
	var log := ActionLog.new()
	var e := engine([], 10)
	e.action_log = log
	force(e, [1, 1, 2, 3, 4])
	ok(e.wild_face(e.party[2].uid, 1), "recorded wild_face")
	var entry: Dictionary = log.entries[log.entries.size() - 1]
	eq(String(entry["fn"]), "wild_face", "logged as wild_face")
	eq(entry["args"], [e.party[2].uid, 1], "args [uid, slot]")
	ok(ActionLog.ALLOWED_FNS.has("wild_face"), "wild_face in ALLOWED_FNS")
	# replays on a twin
	var t := engine([], 10)
	force(t, [1, 1, 2, 3, 4])
	ok(t.wild_face(int(entry["args"][0]), int(entry["args"][1])), "twin accepts the recorded move")
	eq(digest(t), digest(e), "twin ends equal")
	# tampers: each one is refused by the engine the verifier drives
	var lo := engine([], 1)
	lo.mana = 1
	force(lo, [1, 1, 2, 3, 4])
	ok(not lo.wild_face(lo.party[2].uid, 1), "tamper: not enough mana")
	var twice := engine([], 10)
	force(twice, [1, 1, 2, 2, 2])
	twice.wild_face(twice.party[4].uid, 1)
	ok(not twice.wild_face(twice.party[3].uid, 1), "tamper: second use in a turn")
	var bad := engine([], 10)
	force(bad, [1, 1, 2, 3, 4])
	bad.party[2].held = true
	ok(not bad.wild_face(bad.party[2].uid, 1), "tamper: invalid die")
	ok(not bad.wild_face(bad.party[3].uid, 9), "tamper: slot out of range")
