extends BoTestBase
## design 3.7 / 3.10.1 / 8.1 t_bo_overcast: Overcast is +0.50 in the M bag (no own x1.5), refusals, no reroll, no Hold.

func run() -> void:
	_name = "t_bo_overcast"
	set_knobs("nominal")
	var e := engine([], 10)
	# MD 22/10: Overcast = +0.40 (knob overcast.add) on EVERY die of the Set. Nominal knobs: three Horns 1 + 0.3 + 0.4 = 1.7 -> 5 becomes 9
	force(e, [1, 1, 1, 2, 3])
	eq(e.overcast_preview(e.party[0]), [7, 9], "preview 7 -> 9 (x1.3 -> x1.7, rounded up)")
	var m0 := e.mana
	ok(e.overcast(e.party[0].uid), "overcast accepted")
	eq(e.mana, m0 - 3, "costs 3")
	eq(e._face_value(e.party[0], 1), 9, "5 with a Set of three + Overcast = 9")
	for i in 3:
		eq(e.m100_for(e.party[i]), 170, "member %d M 1.70" % i)
	eq(e.m100_for(e.party[3]), 100, "loose die untouched")
	# four + overcast = 1 + 1.2 + 0.4 = 2.60
	var e4 := engine([], 10)
	force(e4, [1, 1, 1, 1, 3], face("dmg", 6))
	e4.overcast(e4.party[3].uid)   # any member works
	for i in 4:
		eq(e4.m100_for(e4.party[i]), 260, "four + overcast = 2.60 on member %d" % i)
	# five + overcast hits the cap (nominal 3.5: 1 + 1.6 + 0.4 = 3.0 -> no clamp; shipped cap 3.0 also 3.0)
	var e5 := engine([], 10)
	force(e5, [1, 1, 1, 1, 1], face("dmg", 6))
	e5.overcast(e5.party[0].uid)
	eq(e5.m100_for(e5.party[4]), 300, "five + overcast = 3.00")
	# no Set -> refused, mana untouched, reason says Set
	var eo := engine([], 10)
	force(eo, [0, 1, 2, 3, 4])
	var m_eo := eo.mana
	eq(eo.overcast_block_reason(eo.party[0].uid), "Needs a Set", "no Set reason")
	ok(not eo.overcast(eo.party[0].uid), "no Set: refused")
	eq(eo.mana, m_eo, "no Set: mana untouched")
	# a pair is not a Set
	force(eo, [1, 1, 2, 3, 4])
	ok(not eo.overcast(eo.party[0].uid), "a pair is not a Set")
	# not rerollable, not holdable (whole Set)
	eq(e._rerollable([e.party[0].uid, e.party[1].uid]).size(), 0, "overcast dice cannot be rerolled")
	ok(not e.can_stash(e.party[2].uid), "overcast die cannot be held")
	# refusals leave mana unchanged
	var er := engine([], 10)
	var m_er := er.mana
	force(er, [1, 1, 1, 3, 4], [face("mana", 2), face("dmg", 0), face("dmg", 5), face("dmg", 5), face("debuff", 2)])
	er.party[2].frozen = true
	er.party[3].custom_state["phantom"] = true
	for i in 5:
		ok(not er.overcast(er.party[i].uid), "refused on die %d" % i)
	eq(er.mana, m_er, "mana untouched by refusals")
	var e2 := engine([], 10, 7, 2)
	force(e2, [1, 1, 1, 3, 4])
	ok(not e2.overcast(e2.party[0].uid), "stage 2 refuses Overcast")
	# storage: the Set is locked at the moment of use (flag on each member). A Wild Face die joining later does NOT get it.
	var ew := engine([], 10)
	force(ew, [1, 1, 1, 2, 4])
	ew.overcast(ew.party[0].uid)
	ew.mana = 10
	ok(ew.wild_face(ew.party[3].uid, 1), "wild 3 -> 4 after Overcast")
	eq(ew.m100_for(ew.party[3]), 100 + ew.bo_add100(4) - 0, "the late fourth die has the Set add only, no Overcast")
	eq(ew.m100_for(ew.party[0]), 100 + ew.bo_add100(4) + 40, "locked members keep Overcast and see the new Set size")
	# Overcast + Crack on a Set member
	var ec := engine([], 10)
	force(ec, [1, 1, 1, 3, 4])
	ec.party[0].cracked = true   # a cracked die does not count: the pair left is no Set
	ec._snap_bo()
	ok(not ec.overcast(ec.party[1].uid), "cracked die broke the Set: no Overcast")
	# default knobs: three + overcast = 1.30 + 0.40 = 1.70
	set_knobs("default")
	var ed := engine([], 10)
	force(ed, [1, 1, 1, 2, 3])
	ed.overcast(ed.party[0].uid)
	eq(ed.m100_for(ed.party[0]), 170, "default: three + overcast = 1.70")
