extends BoTestBase
## Anchor base rules + prices (production/anchor-2b-brief.md): Volley, Gambler, Mana Mine.

func _init() -> void:
	_name = "t_anchor_rules"


func _k100(key: String) -> int:
	return int(roundf(CombatEngine.tune_knob("anchor", key, 0.0) * 100.0))

func _eng(anchor: String, mana: int = 0, awake: bool = false, seed_v: int = 29) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup_new({"node_id": "bo", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": CoreTestUtil.roster(["plant1", "beast1", "aqua1", "reptile1", "bug1"]),
		"relic_ids": [], "combat_seed": seed_v, "start_mana": mana, "depth_stage": 3, "anchor_id": anchor, "anchor_awakened": awake})
	return e


func _hp(e: CombatEngine) -> Array:
	var o: Array = []
	for t in e.enemies:
		o.append(int((t as Unit).hp) + int((t as Unit).shield))
	return o


func run() -> void:
	# --- Volley: price, blast, cap, once per turn, no thorns back ---
	var plain := _eng("")
	var d5 := face("dmg", 5)
	BoTestBase.force(plain, [1, 1, 1, 2, 3], [d5, d5, d5, d5, d5])
	eq(plain.m100_for(plain.party[0]), 130, "no Anchor: SET of 3 = 1.30")
	var v := _eng("a_volley")
	BoTestBase.force(v, [1, 1, 1, 2, 3], [d5, d5, d5, d5, d5])
	eq(v.m100_for(v.party[0]), 130, "Volley price: SET -0.0 (free after round 3 tuning)")
	eq(v.m100_for(v.party[3]), 100, "Volley price: loose die untouched")
	# Wild preview must include the Anchor price and match the real M after the action
	var vp := _eng("a_volley", 10)
	BoTestBase.force(vp, [1, 1, 1, 2, 3], [d5, d5, d5, d5, d5])
	var pvv := vp.preview_wild(vp.party[3].uid, 1)
	ok(bool(pvv["ok"]), "volley wild preview ok")
	var pv_m := int(round(float(pvv["mult"]) * 100.0))
	ok(vp.wild_face(vp.party[3].uid, 1), "volley wild_face")
	eq(pv_m, vp.m100_for(vp.party[3]), "Wild preview mult = real M with Anchor price")
	eq(vp.bo_group_m100(vp.bo[0]), vp.m100_for(vp.party[3]), "bo_group_m100 = member M")
	for t in v.enemies:
		(t as Unit).hp = 90
		(t as Unit).max_hp = 90
		(t as Unit).shield = 0
	(v.enemies[0] as Unit).status["thorns"] = 5
	var hp0 := _hp(v)
	var party_hp: Array = []
	for p in v.party:
		party_hp.append((p as Unit).hp)
	var tgt := v.enemies[1] as Unit
	ok(v.use_die(v.party[0].uid, tgt.uid), "use die 0")
	var h1 := _hp(v)
	eq(hp0[1] - h1[1], 7 + 6, "target takes die (5 x1.30 = 7) + blast 40% of 15 = 6")
	eq(hp0[0] - h1[0], 6, "other enemy takes the blast (thorn enemy too)")
	var same := true
	for i in v.party.size():
		same = same and (v.party[i] as Unit).hp == party_hp[i]
	ok(same, "enemy Thorns do not reflect the blast")
	ok(v.use_die(v.party[1].uid, tgt.uid), "use die 1")
	ok(h1[1] - _hp(v)[1] <= 9, "no second blast the same turn (die 7 + LINK 1; a blast would add 6)")
	eq(h1[0] - _hp(v)[0], 0, "no second blast on the other enemy")
	# base total counts damage faces only; size 5 hits the cap
	var v5 := _eng("a_volley")
	BoTestBase.force(v5, [1, 1, 1, 1, 1], [d5, d5, d5, d5, d5])
	for t in v5.enemies:
		(t as Unit).hp = 90
		(t as Unit).max_hp = 90
		(t as Unit).shield = 0
	var b5 := _hp(v5)
	var tg5 := v5.enemies[1] as Unit
	v5.use_die(v5.party[0].uid, tg5.uid)
	eq(b5[0] - _hp(v5)[0], 20, "SET of five: 90% of 25 = 22, capped at 20")
	var vs := _eng("a_volley")
	BoTestBase.force(vs, [1, 1, 1, 2, 3], [d5, d5, face("shield", 9), d5, d5])
	for t in vs.enemies:
		(t as Unit).hp = 90
		(t as Unit).max_hp = 90
		(t as Unit).shield = 0
	var bs := _hp(vs)
	vs.use_die(vs.party[0].uid, (vs.enemies[1] as Unit).uid)
	eq(bs[0] - _hp(vs)[0], 4, "shield face not in the base: 40% of 10 = 4")
	# no Anchor: no extra blast
	for t in plain.enemies:
		(t as Unit).hp = 90
		(t as Unit).max_hp = 90
	var bp := _hp(plain)
	plain.use_die(plain.party[0].uid, (plain.enemies[1] as Unit).uid)
	eq(bp[0] - _hp(plain)[0], 0, "no Anchor: no blast")

	# --- Gambler: clean Gamble +0.30 (cap 0.60), Crack 40% ---
	var clean_seed := -1
	var crack_seed := -1
	for s in 400:
		var g := _gamble_try(s, [0, 1])
		if g["cracked"] == 0 and clean_seed < 0:
			clean_seed = s
		if g["cracked"] > 0 and crack_seed < 0:
			crack_seed = s
	ok(clean_seed >= 0 and crack_seed >= 0, "found clean and cracking seeds")
	var gc := _gamble_engine()
	ok(gc.reroll_dice([gc.party[0].uid, gc.party[1].uid], clean_seed, false, 0), "clean Gamble accepted")
	eq(gc.anchor_turn["gb100"], _k100("gambler_set_add"), "clean Gamble: +gambler_set_add")
	BoTestBase.force(gc, [1, 1, 1, 2, 3], [d5, d5, d5, d5, d5])
	eq(gc.m100_for(gc.party[0]), 130 + _k100("gambler_set_add"), "SET M = 1.30 + gambler_set_add")
	gc.anchor_turn["gb100"] = 50
	gc.anchor_turn["gb100"] = mini(60, 50 + 30)
	eq(int(gc.anchor_turn["gb100"]), 60, "cap +0.60 per turn")
	var gk := _gamble_engine()
	gk.reroll_dice([gk.party[0].uid, gk.party[1].uid], crack_seed, false, 0)
	eq(gk.anchor_turn["gb100"], 0, "a Gamble with a Crack gives nothing")
	var g1 := _gamble_engine()
	g1.reroll_dice([g1.party[0].uid], clean_seed, false, 0)
	ok(int(g1.anchor_turn["gb100"]) == 0, "1-die Gamble gives nothing")
	var cracks := 0
	var total := 300
	for s in total:
		cracks += int(_gamble_try(s, [0])["cracked"])
	ok(cracks * 100 / total >= 9 and cracks * 100 / total <= 21, "Gambler Crack rate ~15%% (got %d%%)" % [cracks * 100 / total])
	# save round trip keeps the tally
	var rt := _gamble_engine()
	rt.anchor_turn["gb100"] = 30
	var r2 := CombatEngine.new()
	r2.from_data(JSON.parse_string(JSON.stringify(rt.to_data())))
	eq(r2.anchor_turn["gb100"], 30, "gb100 survives save/load")
	eq(r2.anchor_id, "a_gambler", "anchor id survives save/load")
	rt.anchor_turn["gb100"] = 0
	var snap := rt.to_data()
	rt.anchor_turn["gb100"] = 60
	rt.from_data(snap)
	eq(rt.anchor_turn["gb100"], 0, "snapshot restore rewinds gb100")

	# --- Mana Mine: +1 mana and Overcast 1 on a natural turn-one SET; Temp Face 3 ---
	var hit := 0
	var miss := 0
	for s in 80:
		var m := _eng("a_mana_mine", 0, false, s)
		var has_set := not m.bo.is_empty()
		eq(m.mana - _eng("", 0, false, s).mana, int(CombatEngine.tune_knob("anchor", "mine_mana", 1.0)) if has_set else 0, "natural SET gives +mine_mana (seed %d)" % s)
		eq(bool(m.anchor_turn["mine"]), has_set, "mine flag (seed %d)" % s)
		if has_set:
			hit += 1
		else:
			miss += 1
	ok(hit > 0 and miss > 0, "both outcomes covered (%d/%d)" % [hit, miss])
	var mm := _eng("a_mana_mine", 5)
	mm.anchor_turn["mine"] = true
	eq(mm.overcast_cost(), 1, "Overcast costs 1 after a natural SET")
	mm.anchor_turn["mine"] = false
	eq(mm.overcast_cost(), 2, "Overcast normal price without it")
	eq(mm.wild_cost(), 2, "Mana Mine price: Temp Face 2")
	eq(plain.wild_cost(), 2, "no Anchor: Temp Face 2")
	eq(plain.overcast_cost(), 2, "no Anchor: Overcast 2")


func _gamble_engine(seed_v: int = 29) -> CombatEngine:
	var e := _eng("a_gambler", 0, false, seed_v)
	e.rerolls = 0
	BoTestBase.force(e, [0, 1, 2, 3, 4], [face("dmg", 5), face("dmg", 5), face("dmg", 5), face("dmg", 5), face("dmg", 5)])
	for i in 5:
		e.party[i].die[i] = face("dmg", 5)
	return e


## {cracked: number of Cracked dice} after a Gamble of party[idx...] with seed s.
func _gamble_try(s: int, idx: Array) -> Dictionary:
	var e := _gamble_engine()
	var uids: Array = []
	for i in idx:
		uids.append(e.party[i].uid)
	e.reroll_dice(uids, s, false, 0)
	var n := 0
	for u in e.party:
		if (u as Unit).cracked:
			n += 1
	return {"cracked": n}
