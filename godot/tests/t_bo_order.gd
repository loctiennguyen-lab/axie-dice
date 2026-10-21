extends BoTestBase
## design 3.4 / 8.1 t_bo_order: integer M, rounding up, cap, what M does not touch, flat Core adds after M.

func run() -> void:
	_name = "t_bo_order"
	set_knobs("nominal")
	var e := engine()
	# A+ tiers: three x1.3, four x2.2, five x2.6 (ceil)
	force(e, [1, 1, 1, 2, 3])
	eq(e._face_value(e.party[0], 1), 7, "5 x1.3 = 6.5 -> 7")
	force(e, [1, 1, 1, 1, 3], face("dmg", 4))
	eq(e._face_value(e.party[0], 1), 9, "4 x2.2 = 8.8 -> 9")
	force(e, [1, 1, 1, 2, 3], face("dmg", 3))
	eq(e._face_value(e.party[0], 1), 4, "3 x1.3 = 3.9 -> 4")
	for v in [0, 1, 2]:
		force(e, [1, 1, 1, 2, 3], face("dmg", v))
		eq(e._face_value(e.party[0], 1), (v * 130 + 99) / 100, "v=%d x1.3" % v)
	# five (2.6) + overcast (0.4) = 3.0: v=6 -> 18 (cap 3.0 or 3.5 alike)
	force(e, [1, 1, 1, 1, 1], face("dmg", 6))
	eq(e._face_value(e.party[0], 1), 16, "five x2.6 of 6 = 15.6 -> 16")
	e.party[0].overcast = true
	eq(e._face_value(e.party[0], 1), 18, "five + overcast = 3.0 of 6 = 18")
	ContentDB.combat_tune["bo"]["m_cap"] = 3.0
	eq(e._face_value(e.party[0], 1), 18, "m_cap 3.0 clamps")
	set_knobs("nominal")
	# what M does not touch
	force(e, [1, 1, 1, 2, 3], face("mana", 2))
	eq(e._face_value(e.party[0], 1), 2, "mana face not multiplied")
	force(e, [1, 1, 1, 2, 3], face("debuff", 2))
	eq(e._face_value(e.party[0], 1), 2, "debuff face not multiplied")
	force(e, [1, 1, 1, 2, 3], face("shield", 4, 0, ["thorns:3"]))
	eq(e._face_value(e.party[0], 1), 6, "shield multiplied, keyword number is not part of it")
	force(e, [1, 1, 1, 2, 3], face("heal", 4))
	eq(e._face_value(e.party[0], 1), 6, "heal multiplied")
	force(e, [1, 1, 1, 2, 3], face("poison", 4))
	eq(e._face_value(e.party[0], 1), 6, "poison multiplied")
	# Crack halves before M: cracked leaves the Set, so M = 1 on its own
	force(e, [1, 1, 1, 2, 3], face("dmg", 5))
	e.party[3].die[2] = face("dmg", 5)
	e.party[3].cracked = true
	eq(e._face_value(e.party[3], 2), 3, "cracked 5 -> ceil(5/2) = 3")
	e.party[3].die[2] = face("dmg", 1)
	eq(e._face_value(e.party[3], 2), 1, "cracked 1 stays 1")
	e.party[3].die[2] = face("dmg", 0)
	eq(e._face_value(e.party[3], 2), 0, "cracked 0 stays 0")
	e.party[3].die[2] = face("mana", 3)
	eq(e._face_value(e.party[3], 2), 2, "Crack also halves a mana face")
	# default knobs: 3 -> 1.30, 4 -> 2.20, 5 -> 2.60, 4 + overcast = 2.60
	set_knobs("default")
	force(e, [1, 1, 1, 2, 3], face("dmg", 5))
	eq(e._face_value(e.party[0], 1), (5 * 130 + 99) / 100, "default three")
	force(e, [1, 1, 1, 1, 3], face("dmg", 5))
	eq(e.m100_for(e.party[0]), 220, "default four 2.20")
	e.party[0].overcast = true
	eq(e.m100_for(e.party[0]), 260, "default four + overcast 2.60")
	force(e, [1, 1, 1, 1, 1], face("dmg", 5))
	eq(e.m100_for(e.party[0]), 260, "default five 2.60")
	# flat Core add stays outside M: face_final flat on a Set die adds exactly +N on top
	set_knobs("nominal")
	var ec := engine(["c_test_flat"] if RelicRegistry.get_def("c_test_flat") != null else [])
	force(ec, [1, 1, 1, 2, 3], face("dmg", 5))
	ok(ec._face_value(ec.party[0], 1) >= 7, "with a flat Core the value is never below the M value")
	# preview_damage reflects M and Overcast
	force(e, [1, 1, 1, 2, 3], face("dmg", 5))
	var foe: Unit = e.alive_enemies()[0]
	eq(int(e.preview_damage(e.party[0], foe, 1)["raw"]), 7, "preview_damage raw includes the Set")
	e.party[0].overcast = true
	eq(int(e.preview_damage(e.party[0], foe, 1)["raw"]), 9, "preview with Overcast: 5 x 1.8 = 9, not 1.3 x 1.5 after face_final")
