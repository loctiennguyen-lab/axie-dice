extends BoTestBase
## design 3.3 / 8.1 t_bo_timing: the snapshot changes only at roll_all, reroll_dice, wild_face, tweak/loaded/hold_pick; never when a die is
## used, dies, or is held. Also: the Set is snapshotted AFTER cantrips (roll_all clears it first, so cantrips read M = 1).

func run() -> void:
	_name = "t_bo_timing"
	set_knobs("nominal")
	_mid_turn_does_not_change()
	_roll_all_and_reroll_change()
	_tweak_changes()


func _mid_turn_does_not_change() -> void:
	var e := engine([], 0)
	force(e, [1, 1, 1, 2, 3])
	var before := JSON.stringify(e.bo)
	var foe: Unit = e.alive_enemies()[0]
	e.use_die(e.party[0].uid, foe.uid)
	eq(JSON.stringify(e.bo), before, "using a die does not change the Set")
	e.party[1].hp = 0
	e.party[1].clear_roll()
	eq(JSON.stringify(e.bo), before, "a die dying does not change the Set")
	# the dead member still carries the Set M until the next snapshot (design: no puzzle about order)
	ok(e.m100_for(e.party[2]) > 100, "survivors keep M")
	var e2 := engine([], 0)
	force(e2, [1, 1, 1, 2, 3])
	var b2 := JSON.stringify(e2.bo)
	if e2.can_stash(e2.party[0].uid):
		e2.stash(e2.party[0].uid)
	eq(JSON.stringify(e2.bo), b2, "Hold does not change the Set")


func _roll_all_and_reroll_change() -> void:
	var e := engine([], 0)
	force(e, [1, 1, 1, 2, 3])
	eq(e.bo.size(), 1, "forced Set present")
	e.end_turn()
	eq(JSON.stringify(e.bo), JSON.stringify(e.recompute_bo()), "after roll_all the snapshot equals recompute_bo()")
	# reroll: snapshot equals recompute after it
	var e3 := engine([], 5, 11)
	var uids: Array = []
	for u in e3.party:
		uids.append((u as Unit).uid)
	e3.reroll_dice(uids, 123)
	eq(JSON.stringify(e3.bo), JSON.stringify(e3.recompute_bo()), "after reroll_dice the snapshot equals recompute_bo()")


func _tweak_changes() -> void:
	var e := engine(["r_flipside"], 0)
	force(e, [1, 1, 1, 2, 3])
	e.party[0].die[(1 + RelicSlots.tuning().flip_offset) % 6] = face("dmg", 5)
	var had := e.bo.size()
	eq(had, 1, "Set before the flip")
	ok(e.tweak("flip", e.party[0].uid, -1), "flip accepted")
	eq(JSON.stringify(e.bo), JSON.stringify(e.recompute_bo()), "after a tweak the snapshot is retaken")
	eq(e.bo.size(), 0, "the flipped die left the Set (face changed by an effect)")
	# the flipped die must not keep the old group's M
	eq(e.m100_for(e.party[0]), 100, "flipped die no longer in the old group")
