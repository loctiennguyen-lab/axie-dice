extends BoTestBase
## design 3.2 / 8.1 t_bo_groups: grouping by part, 3/4/5, who is excluded, who still counts.

func run() -> void:
	_name = "t_bo_groups"
	for ks in ["nominal", "default"]:
		set_knobs(ks)
		_sizes(ks)
		_exclusions()
		_still_counts()
	_wild_and_phantom()


func _sizes(ks: String) -> void:
	var e := engine()
	force(e, [1, 1, 1, 2, 3])
	eq(e.bo.size(), 1, "three Horns make one Set")
	eq(int(e.bo[0]["size"]), 3, "size 3")
	var scale := 1.0 if ks == "nominal" else 0.8
	eq(int(e.bo[0]["m100"]), 100 + roundi(0.5 * scale * 100.0), "m100 for three (%s)" % ks)
	force(e, [1, 1, 1, 1, 3])
	eq(int(e.bo[0]["size"]), 4, "size 4")
	eq(int(e.bo[0]["m100"]), 100 + roundi(1.0 * scale * 100.0), "m100 for four (%s)" % ks)
	force(e, [4, 4, 4, 4, 4])
	eq(int(e.bo[0]["size"]), 5, "size 5")
	eq(int(e.bo[0]["m100"]), mini(100 + roundi(2.0 * scale * 100.0), e.bo_cap100()), "m100 for five (%s)" % ks)
	force(e, [1, 1, 2, 2, 3])
	eq(e.bo.size(), 0, "two pairs are not a Set")
	force(e, [0, 1, 2, 3, 4])
	eq(e.bo.size(), 0, "all different: no Set")
	eq(e.m100_for(e.party[0]), 100, "outside a Set M = 1.00")


func _exclusions() -> void:
	var e := engine()
	force(e, [1, 1, 1, 1, 3])
	eq(int(e.bo[0]["size"]), 4, "baseline four")
	# blank face
	force(e, [1, 1, 1, 1, 3], [face("dmg", 5), face("dmg", 5), face("dmg", 5), face("blank", 0), face("dmg", 5)])
	eq(int(e.bo[0]["size"]), 3, "blank does not count")
	# cracked
	force(e, [1, 1, 1, 1, 3])
	e.party[3].cracked = true
	e._snap_bo()
	eq(int(e.bo[0]["size"]), 3, "cracked does not count")
	# dead
	force(e, [1, 1, 1, 1, 3])
	e.party[3].hp = 0
	e._snap_bo()
	eq(int(e.bo[0]["size"]), 3, "dead does not count")
	# token
	force(e, [1, 1, 1, 1, 3])
	e.party[3].is_token = true
	e._snap_bo()
	eq(int(e.bo[0]["size"]), 3, "token does not count")
	# asleep (sidelined)
	force(e, [1, 1, 1, 1, 3])
	e.party[3].custom_state["asleep"] = true
	e._snap_bo()
	eq(int(e.bo[0]["size"]), 3, "sidelined does not count")
	# enemies never
	force(e, [0, 0, 0, 0, 0])
	for en in e.enemies:
		(en as Unit).set_roll(1, false)
	eq(e.m100_for(e.enemies[0]), 100, "enemy never gets M")
	for g in e.bo:
		for uid in g["uids"]:
			ok(e.by_uid(int(uid)).side == "p", "only player dice in a Set")


func _still_counts() -> void:
	var e := engine()
	force(e, [1, 1, 1, 2, 3])
	e.party[0].mark_used()
	e.party[1].held = true
	e.party[2].frozen = true
	e._snap_bo()
	eq(e.bo.size(), 1, "used + held + frozen dice still count")
	eq(int(e.bo[0]["size"]), 3, "all three counted")
	force(e, [1, 1, 1, 2, 3])
	eq(e.bo.size(), 1, "recount before the next case")
	for i in 3:
		eq(e.m100_for(e.party[i]) > 100, true, "member %d has M > 1" % i)


func _wild_and_phantom() -> void:
	set_knobs("nominal")
	var e := engine()
	force(e, [1, 1, 2, 3, 4], null, false)
	e.party[2].wild_slot = 1
	e._snap_bo()
	eq(e.bo.size(), 1, "wild_slot completes a Set")
	eq(int(e.bo[0]["part"]), 1, "Set part is the slot")
	# phantom die copies a real Axie but has no is_token
	force(e, [1, 1, 2, 3, 4])
	var ph := Unit.from_data(e.party[0].to_data())
	ph.uid = 9001
	ph.custom_state = {"phantom": true}
	ph.set_roll(1, false)
	e.party.append(ph)
	e._snap_bo()
	eq(e.bo.size(), 0, "phantom does not make a Set")
	ContentDB.combat_tune["bo"]["phantom_counts"] = 1
	e._snap_bo()
	eq(e.bo.size(), 1, "phantom_counts=1 lets it count")
	# part hi: rare face adds 0.25 at stage 3, not at stage 2
	ContentDB.combat_tune["bo"]["phantom_counts"] = 0
	var e3 := engine()
	force(e3, [1, 1, 1, 2, 3], [face("dmg", 5, 2), face("dmg", 5), face("dmg", 5), face("dmg", 5), face("dmg", 5)])
	eq(int(e3.bo[0]["m100"]), 175, "rare part adds +25")
	eq(e3.bo[0]["hi"], true, "hi flag")
	var e2 := engine([], 0, 7, 2)
	force(e2, [1, 1, 1, 2, 3], [face("dmg", 5, 2), face("dmg", 5), face("dmg", 5), face("dmg", 5), face("dmg", 5)])
	eq(int(e2.bo[0]["m100"]), 150, "no part_add below stage 3")
