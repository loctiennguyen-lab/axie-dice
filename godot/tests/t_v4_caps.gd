extends BoTestBase
## Depth v4 review fixes: thorn.shield_transfer_cap (N5), poison.face_cap / stack_cap (3.10.7), Lieu is never discounted by hollow_core /
## cheap_mana (rmode in on_reroll_paid), reroll_refusal tells max_total from hard_cap.

func run() -> void:
	_name = "t_v4_caps"
	set_knobs("default")
	_thorn()
	_poison()
	_relic_poison()
	_lieu_discount()
	_codes()


func _thorn() -> void:
	var cap := int(CombatEngine.tune_knob("thorn", "shield_transfer_cap", 6.0))
	eq(cap, 6, "thorn cap knob")
	var e := engine(["c_thorn_shield"], 0)
	e.party[1].shield = 30
	e.party[2].shield = 9
	var t1: int = int(e.party[1].status.get("thorns", 0))
	var t2: int = int(e.party[2].status.get("thorns", 0))
	RelicHooks.fire(e, "on_turn_end", {"combat": e})
	eq(int(e.party[1].status.get("thorns", 0)) - t1, 6, "30 shield -> only 6 thorns")
	eq(e.party[1].shield, 30 - 12, "only the converted shield is spent")
	eq(int(e.party[2].status.get("thorns", 0)) - t2, 4, "9 shield -> 4 thorns (under the cap)")


func _poison() -> void:
	var e := engine([], 0)
	force(e, [0, 1, 2, 3, 4], face("poison", 30))
	var u: Unit = e.party[0]
	eq(e._face_value(u, 0), 8, "poison face capped at poison.face_cap")
	force(e, [0, 1, 2, 3, 4], face("dmg", 30))
	ok(e._face_value(e.party[0], 0) > 8, "dmg face not capped")
	var foe: Unit = e.enemies[0]
	for i in 5:
		StatusEngine.add_status(e, foe, ["poison:8"], null)
	eq(int(foe.status.get("poison", 0)), 15, "poison stack capped at stack_cap")


## Relics that put +1 Poison straight on the status dict (sporegale, fumeblossom) obey poison.stack_cap too.
func _relic_poison() -> void:
	var e := engine(["r_sporegale", "r_fumeblossom"], 0)
	var a: Unit = e.enemies[0]
	var b: Unit = e.enemies[1]
	a.status["poison"] = 15
	b.status["poison"] = 15
	RelicHooks.fire(e, "on_status_tick", {"combat": e, "tgt": a, "kind": "poison"})
	eq(int(b.status.get("poison", 0)), 15, "sporegale tick: neighbour already at cap stays 15")
	RelicHooks.fire(e, "on_status_tick", {"combat": e, "tgt": a, "kind": "burn"})
	eq(int(a.status.get("poison", 0)), 15, "fumeblossom burn tick: at cap stays 15")
	b.status["poison"] = 14
	RelicHooks.fire(e, "on_status_tick", {"combat": e, "tgt": a, "kind": "poison"})
	eq(int(b.status.get("poison", 0)), 15, "sporegale tick: 14 -> 15 (still adds under the cap)")
	b.status["poison"] = 20
	RelicHooks.fire(e, "on_status_tick", {"combat": e, "tgt": a, "kind": "poison"})
	eq(int(b.status.get("poison", 0)), 20, "stack already above cap is not cut")


func _lieu_discount() -> void:
	for core in ["c_hollow_core", "rule_cheap_mana"]:
		var e := engine([core], 50, 5)
		var all: Array = e.party.map(func(u): return u.uid)
		ok(e.reroll_dice(all, -1, false, 0), core + ": Lieu 1")
		eq(e.reroll_paid_k, 1, core + ": Lieu counts")
		ok(e.reroll_dice(all, -1, false, 0), core + ": Lieu 2")
		eq(e.reroll_paid_k, 2, core + ": Lieu is not discounted (paid_k 2, no core refund)")
		var s := engine([core], 50, 5)
		ok(s.reroll_dice(all, -1, false, 1), core + ": Safe 1")
		if core == "rule_cheap_mana":
			eq(s.reroll_paid_k, 0, core + ": first Safe is discounted")
		else:
			ok(s.reroll_dice(all, -1, false, 1), core + ": Safe 2")
			eq(s.reroll_paid_k, 1, core + ": every second Safe is discounted")


func _codes() -> void:
	var e := engine([], 50, 5)
	var all: Array = e.party.map(func(u): return u.uid)
	e.reroll_dice(all)
	e.reroll_dice(all, -1, false, 0)
	e.reroll_dice(all, -1, false, 0)
	eq(e.reroll_refusal(all, false, 0), "max_total", "chosen limit is max_total")
	var r := engine([], 50, 5)
	r.rerolls += 2
	for i in 3:
		r.reroll_dice(all)
	r.reroll_dice(all, -1, false, 0)
	eq(r.reroll_refusal(all, false, 0), "hard_cap", "all-sources cap is hard_cap")
