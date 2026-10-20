extends BoTestBase
## design 3.7 / 3.10.1 / 8.1 t_bo_overcast: Overcast is +0.50 in the M bag (no own x1.5), refusals, no reroll, no Hold.

func run() -> void:
	_name = "t_bo_overcast"
	set_knobs("nominal")
	var e := engine([], 10)
	# three Horns + Overcast: M = 1 + 0.5 + 0.5 = 2.0 -> 5 becomes 10 (old rule: 7.5 x 1.5 = 12 or 11.25)
	force(e, [1, 1, 1, 2, 3])
	eq(e.overcast_preview(e.party[0]), [8, 10], "preview 8 -> 10")
	var m0 := e.mana
	ok(e.overcast(e.party[0].uid), "overcast accepted")
	eq(e.mana, m0 - 3, "costs 3")
	eq(e._face_value(e.party[0], 1), 10, "5 with a Set of three + Overcast = 10")
	# four + overcast = 2.50 (nominal)
	var e4 := engine([], 10)
	force(e4, [1, 1, 1, 1, 3], face("dmg", 6))
	e4.overcast(e4.party[0].uid)
	eq(e4.m100_for(e4.party[0]), 250, "four + overcast = 2.50")
	# outside a Set: 1.50
	var eo := engine([], 10)
	force(eo, [0, 1, 2, 3, 4])
	eo.overcast(eo.party[0].uid)
	eq(eo.m100_for(eo.party[0]), 150, "no Set: 1.50")
	eq(eo._face_value(eo.party[0], 0), 8, "5 x1.5 = 8")
	# not rerollable, not holdable
	eq(eo._rerollable([eo.party[0].uid]).size(), 0, "overcast die cannot be rerolled")
	ok(not eo.can_stash(eo.party[0].uid), "overcast die cannot be held")
	# refusals leave mana unchanged
	var er := engine([], 10)
	var m_er := er.mana
	force(er, [0, 1, 2, 3, 4], [face("mana", 2), face("dmg", 0), face("dmg", 5), face("dmg", 5), face("debuff", 2)])
	er.party[2].frozen = true
	er.party[3].custom_state["phantom"] = true
	for i in 5:
		ok(not er.overcast(er.party[i].uid), "refused on die %d" % i)
	eq(er.mana, m_er, "mana untouched by refusals")
	var e2 := engine([], 10, 7, 2)
	force(e2, [0, 1, 2, 3, 4])
	ok(not e2.overcast(e2.party[0].uid), "stage 2 refuses Overcast")
	# Overcast + wild_slot on one die, Overcast + Crack
	var ew := engine([], 10)
	force(ew, [1, 1, 2, 3, 4], null, false)
	ew.party[2].wild_slot = 1
	ew._snap_bo()
	ok(ew.overcast(ew.party[2].uid), "overcast on a Wild-Face die")
	eq(ew.m100_for(ew.party[2]), 200, "set three + overcast on the wild die")
	var ec := engine([], 10)
	force(ec, [0, 1, 2, 3, 4])
	ec.party[0].cracked = true
	ok(ec.overcast(ec.party[0].uid), "overcast on a cracked die")
	eq(ec._face_value(ec.party[0], 0), 5, "cracked 5 -> 3, x1.5 = 5")
	# default knobs: three + overcast = 1.40 + 0.50
	set_knobs("default")
	var ed := engine([], 10)
	force(ed, [1, 1, 1, 2, 3])
	ed.overcast(ed.party[0].uid)
	eq(ed.m100_for(ed.party[0]), 190, "default: three + overcast = 1.90")
