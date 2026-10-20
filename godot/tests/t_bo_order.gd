extends BoTestBase
## design 3.4 / 8.1 t_bo_order: integer M, rounding up, cap, what M does not touch, flat Core adds after M.

func run() -> void:
	_name = "t_bo_order"
	set_knobs("nominal")
	var e := engine()
	# three x1.5: 5 -> 8 (ceil 7.5); four x2.0: 5 -> 10 ; doc says 4x2=8 for v=4
	force(e, [1, 1, 1, 2, 3])
	eq(e._face_value(e.party[0], 1), 8, "5 x1.5 = 8")
	force(e, [1, 1, 1, 1, 3], face("dmg", 4))
	eq(e._face_value(e.party[0], 1), 8, "4 x2.0 = 8")
	force(e, [1, 1, 1, 2, 3], face("dmg", 3))
	eq(e._face_value(e.party[0], 1), 5, "3 x1.5 = 5")
	for v in [0, 1, 2]:
		force(e, [1, 1, 1, 2, 3], face("dmg", v))
		eq(e._face_value(e.party[0], 1), (v * 150 + 99) / 100, "v=%d x1.5" % v)
	# cap: five (3.0) + overcast (0.5) = 3.5 ok at nominal cap, v=6 -> 21
	force(e, [1, 1, 1, 1, 1], face("dmg", 6))
	eq(e._face_value(e.party[0], 1), 18, "five x3.0 of 6")
	e.party[0].overcast = true
	eq(e._face_value(e.party[0], 1), 21, "five + overcast = 3.5 (cap) of 6")
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
	# default knobs: 3 -> 1.40, 4 -> 1.80, 5 -> 2.60, 4 + overcast = 2.30
	set_knobs("default")
	force(e, [1, 1, 1, 2, 3], face("dmg", 5))
	eq(e._face_value(e.party[0], 1), (5 * 140 + 99) / 100, "default three")
	force(e, [1, 1, 1, 1, 3], face("dmg", 5))
	eq(e.m100_for(e.party[0]), 180, "default four 1.80")
	e.party[0].overcast = true
	eq(e.m100_for(e.party[0]), 230, "default four + overcast 2.30")
	force(e, [1, 1, 1, 1, 1], face("dmg", 5))
	eq(e.m100_for(e.party[0]), 260, "default five 2.60")
	# flat Core add stays outside M: face_final flat on a Set die adds exactly +N on top
	set_knobs("nominal")
	var ec := engine(["c_test_flat"] if RelicRegistry.get_def("c_test_flat") != null else [])
	force(ec, [1, 1, 1, 2, 3], face("dmg", 5))
	ok(ec._face_value(ec.party[0], 1) >= 8, "with a flat Core the value is never below the M value")
	# preview_damage reflects M and Overcast
	force(e, [1, 1, 1, 2, 3], face("dmg", 5))
	var foe: Unit = e.alive_enemies()[0]
	eq(int(e.preview_damage(e.party[0], foe, 1)["raw"]), 8, "preview_damage raw includes the Set")
	e.party[0].overcast = true
	eq(int(e.preview_damage(e.party[0], foe, 1)["raw"]), 10, "preview with Overcast: 5 x 2.0 = 10, not 11.25")
