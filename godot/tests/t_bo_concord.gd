extends BoTestBase
## design 3.2 / 8.1 t_bo_concord: with Concord only the first eligible die of each class counts; without it all count.

func run() -> void:
	_name = "t_bo_concord"
	set_knobs("nominal")
	var keys := ["plant1", "plant1", "plant1", "beast1", "aqua1"]
	var e := engine([], 0, 7, 3, keys)
	force(e, [1, 1, 1, 2, 3])
	eq(e.bo.size(), 1, "no Concord: three plants make a Set")
	var c := engine(["c_concord"], 0, 7, 3, keys)
	force(c, [1, 1, 1, 2, 3])
	eq(c.bo.size(), 0, "Concord: one plant counts, no Set")
	# filter happens before wild_slot: cracked first plant -> second plant is the counted one
	var c2 := engine(["c_concord"], 0, 7, 3, keys)
	force(c2, [1, 1, 1, 1, 1], null, false)
	c2.party[0].cracked = true
	c2._snap_bo()
	eq(c2.bo.size(), 1, "plant, beast, aqua: one die per class still makes a Set of 3")
	var u2: Array = c2.bo[0]["uids"]
	ok(not u2.has(c2.party[0].uid) and u2.has(c2.party[1].uid) and not u2.has(c2.party[2].uid), "cracked first plant skipped, second plant counts, third excluded")
	# Concord + wild: two classes' counted dice can be pulled to one part with wild_slot
	var c3 := engine(["c_concord"], 0, 7, 3, ["plant1", "plant1", "beast1", "aqua1", "reptile1"])
	force(c3, [1, 1, 1, 2, 3], null, false)
	c3.party[3].wild_slot = 1
	c3._snap_bo()
	eq(c3.bo.size(), 1, "plant + beast + wild aqua = Set of three on Horn")
	eq((c3.bo[0]["uids"] as Array).has(c3.party[1].uid), false, "the second plant is NOT in the Set")
	# the excluded second plant may not have a Wild-Face attached later either: it never counts
	eq(c3.m100_for(c3.party[1]), 100, "excluded die has no M")
