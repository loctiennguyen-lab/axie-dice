extends BoTestBase
## design 3.3 / 8.1 t_bo_undo + t_bo_saveload (BO part): the snapshot lives in the state dict, survives undo, JSON save/load, and is NOT rebuilt on load.

func run() -> void:
	_name = "t_bo_saveload"
	set_knobs("default")
	var e := engine([], 10)
	force(e, [1, 1, 1, 2, 3])
	var bo0 := JSON.stringify(e.bo)
	var m_start := e.mana
	ok(e.overcast(e.party[0].uid), "overcast")
	eq(e.mana, m_start - 2, "mana paid")
	ok(e.undo_last(), "undo")
	eq(e.mana, m_start, "undo gives the mana back")
	eq(JSON.stringify(e.bo), bo0, "undo keeps the Set")
	ok(not e.party[0].overcast, "undo clears the flag")
	# round trip through JSON text, like a save file
	e.overcast(e.party[1].uid)
	var d = JSON.parse_string(JSON.stringify(e.to_data()))
	var e2 := CombatEngine.new()
	e2.from_data(d)
	eq(JSON.stringify(e2.bo), JSON.stringify(e.bo), "Set survives a JSON round trip (ints stay ints)")
	eq(digest(e2), JSON.stringify(JSON.parse_string(digest(e))), "whole state equal after load (JSON-normalised)")
	for g in e2.bo:
		for uid in g["uids"]:
			ok(typeof(uid) == TYPE_INT, "uid is an int after load")
	# not recomputed on load: change a face behind the engine's back, save, load -> old snapshot kept
	var e3 := engine([], 0)
	force(e3, [1, 1, 1, 2, 3])
	e3.party[0].die[1] = face("blank", 0)
	var e4 := CombatEngine.new()
	e4.from_data(JSON.parse_string(JSON.stringify(e3.to_data())))
	eq(e4.bo.size(), 1, "load does not rebuild the Set")
	eq(e4.depth_stage, 3, "depth_stage saved")
	var e5 := engine([], 0, 7, 2)
	var e6 := CombatEngine.new()
	e6.from_data(JSON.parse_string(JSON.stringify(e5.to_data())))
	eq(e6.depth_stage, 2, "stage 2 survives a save")
