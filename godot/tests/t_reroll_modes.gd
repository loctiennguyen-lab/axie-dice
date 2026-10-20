extends BoTestBase
## Depth v4 3.5 / 3.10.3 (N1): Lieu / Safe modes, max_total through reroll_paid_k, hard_cap, Aid, Crack. design/gdd/dice-depth-v4.md.

func run() -> void:
	_name = "t_reroll_modes"
	set_knobs("default")
	_modes()
	_caps()
	_crack()
	_aid()
	_stage()


func _uids(e: CombatEngine) -> Array:
	var out: Array = []
	for u in e.party:
		out.append((u as Unit).uid)
	return out


func _modes() -> void:
	var e := engine([], 0, 11)
	var all := _uids(e)
	# free charge: rmode 0 is turned into Safe (1) and never cracks
	var log := ActionLog.new()
	log.begin(11, ["plant1"], "short", 0, "test")
	e.action_log = log
	eq(e.effective_rmode(false, 0), 1, "a free charge forces rmode 1")
	ok(e.reroll_dice(all, -1, false, 0), "free reroll with rmode 0 requested")
	eq(int((log.entries[0]["args"] as Array)[2]), 1, "free reroll logs rmode 1")
	var cracked := 0
	for u in e.party:
		if (u as Unit).cracked:
			cracked += 1
	eq(cracked, 0, "free reroll never cracks")
	eq(e.reroll_paid_k, 0, "free reroll does not count against max_total")
	# Lieu: 0 mana, counted in paid_k
	var m0 := e.mana
	eq(e.reroll_mana_cost(false, 0), 0, "Lieu costs no mana")
	ok(e.can_reroll(all, false, 0), "Lieu legal with 0 mana")
	ok(e.reroll_dice(all, -1, false, 0), "Lieu reroll")
	ok(e.mana >= m0, "Lieu spends no mana")
	eq(int((log.entries[1]["args"] as Array)[2]), 0, "Lieu logs rmode 0")
	eq(e.reroll_paid_k, 1, "Lieu counts as a chosen reroll")
	# Safe after Lieu: second chosen reroll costs mana_cost_3
	eq(e.reroll_mana_cost(false, 1), 3, "second chosen reroll costs 3")
	e.mana = 2
	eq(e.reroll_refusal(all, false, 1), "mana", "Safe with 2 mana refused for the 3-mana reroll")
	eq(e.reroll_refusal(all, false, 5), "bad_rmode", "rmode outside 0/1 refused")
	# Safe first: costs 2
	var e2 := engine([], 0, 11)
	e2.reroll_dice(all, -1, false, 1)
	eq(e2.reroll_mana_cost(false, 1), 2, "first chosen reroll costs 2")
	e2.mana = 1
	ok(not e2.can_reroll(all, false, 1), "Safe without mana refused")
	ok(e2.can_reroll(all, false, 0), "Lieu is still open with no mana")


func _caps() -> void:
	var all: Array
	# base: free + two chosen = max_total 3, then refused
	var e := engine([], 50, 5)
	all = _uids(e)
	ok(e.reroll_dice(all) and e.reroll_dice(all, -1, false, 0) and e.reroll_dice(all, -1, false, 0), "free + 2 Lieu")
	eq(e.reroll_refusal(all, false, 0), "max_total", "third chosen refused (max_total 3)")
	eq(e.reroll_paid_k, 2, "paid_k 2")
	# N1: relic +1 free -> 1 + 1 + 2 chosen = 4 = hard_cap, fifth refused
	var r := engine([], 50, 5)
	r.rerolls += 1
	ok(r.reroll_dice(all) and r.reroll_dice(all), "base + relic free")
	eq(r.reroll_paid_k, 0, "relic free rerolls do not touch reroll_paid_k")
	ok(r.reroll_dice(all, -1, false, 0) and r.reroll_dice(all, -1, false, 0), "two chosen after relic free")
	eq(r.reroll_total_turn, 4, "4 rerolls")
	ok(not r.can_reroll(all, false, 0) and not r.can_reroll(all, false, 1), "hard_cap 4 stops the fifth")
	# relic +2: 3 free + 1 chosen = 4; fifth refused although paid_k < 2 (hard_cap cuts it)
	var r2 := engine([], 50, 5)
	r2.rerolls += 2
	for i in 3:
		ok(r2.reroll_dice(all), "free %d" % i)
	ok(r2.reroll_dice(all, -1, false, 0), "one chosen")
	eq(r2.reroll_paid_k, 1, "paid_k 1")
	eq(r2.reroll_refusal(all, false, 0), "hard_cap", "relic +2: fifth cut by hard_cap")
	# reset on the next roll
	r2.end_turn()
	if not (r2.won or r2.lost):
		eq(r2.reroll_paid_k + r2.reroll_total_turn, 0, "counters reset at roll_all")


func _crack() -> void:
	var seeds_with_crack := 0
	var total := 0
	var cracked_total := 0
	for s in range(1, 41):
		var e := engine([], 0, s)
		var all := _uids(e)
		e.reroll_dice(all)
		ok(e.reroll_dice(all, -1, false, 0), "Lieu seed %d" % s)
		for u in e.party:
			total += 1
			if (u as Unit).cracked:
				cracked_total += 1
				for g in e.bo:
					ok(not (g["uids"] as Array).has((u as Unit).uid), "cracked die is outside the Set")
		if cracked_total > 0:
			seeds_with_crack += 1
	ok(cracked_total > 0 and cracked_total < total, "Crack happens sometimes (%d of %d)" % [cracked_total, total])
	# determinism: same seed + same call = same Crack; exactly one extra draw per uid, from the reroll seed
	var a := engine([], 0, 21)
	var b := engine([], 0, 21)
	var all := _uids(a)
	a.reroll_dice(all)
	b.reroll_dice(all)
	a.reroll_dice(all, 777, false, 0)
	b.reroll_dice(all, 777, false, 0)
	eq(JSON.stringify([a.party.map(func(u): return u.cracked)]), JSON.stringify([b.party.map(func(u): return u.cracked)]), "Crack is deterministic from the seed")
	var c := engine([], 50, 21)
	c.reroll_dice(all)
	c.reroll_dice(all, 777, false, 1)   # Safe, same seed: no crack draws
	var st_safe := c._rng.get_state()
	var probe := Rng.new(st_safe)
	for i in all.size():
		probe.next_int(100)
	eq(probe.get_state(), a._rng.get_state(), "Lieu draws exactly one number per named uid")
	# a Lieu die that is named but dead still consumes its draw
	var d := engine([], 0, 21)
	d.reroll_dice(all)
	d.party[0].hp = 0
	d.reroll_dice(all, 777, false, 0)
	var ds := engine([], 50, 21)
	ds.reroll_dice(all)
	ds.party[0].hp = 0
	ds.reroll_dice(all, 777, false, 1)
	var dp := Rng.new(ds._rng.get_state())
	for i in all.size():
		dp.next_int(100)
	eq(dp.get_state(), d._rng.get_state(), "dead named die: Lieu still draws one number per named uid")
	# crack is wiped by a Safe reroll of that die and by the next roll
	var f := engine([], 50, 21)
	for u in f.party:
		(u as Unit).cracked = true
	f.reroll_dice(_uids(f), -1, false, 1)
	var left := 0
	for u in f.party:
		if (u as Unit).cracked:
			left += 1
	eq(left, 0, "a re-rolled die sheds its old crack")
	var g := engine([], 0, 21)
	g.party[0].cracked = true
	g.end_turn()
	if not (g.won or g.lost):
		ok(not g.party[0].cracked, "Crack ends at the next roll_all")


func _aid() -> void:
	var e := engine([], 0, 9)
	var all := _uids(e)
	e.reroll_dice(all)
	var log := ActionLog.new()
	log.begin(9, ["plant1"], "short", 0, "test")
	e.action_log = log
	var m0 := e.mana
	ok(e.reroll_dice(all, -1, true, 0), "Aid reroll with rmode 0 requested")
	eq(int((log.entries[0]["args"] as Array)[2]), 1, "Aid logs rmode 1")
	var cr := 0
	for u in e.party:
		if (u as Unit).cracked:
			cr += 1
	eq(cr, 0, "Aid never cracks")
	eq(e.reroll_paid_k, 0, "Aid does not count against max_total")
	eq(e.reroll_total_turn, 2, "Aid counts against hard_cap")
	# Aid does not eat the chosen slots: still two chosen after it
	ok(e.reroll_dice(all, -1, false, 0) and e.reroll_dice(all, -1, false, 0), "two chosen rerolls after Aid")   # total 4
	ok(not e.can_reroll(all, true, 1), "Aid cannot pass hard_cap 4")


func _stage() -> void:
	var e := engine([], 0, 3, 1)
	var all := _uids(e)
	e.reroll_dice(all)
	eq(e.reroll_refusal(all, false, 0), "stage", "stage 1 refuses Lieu")
