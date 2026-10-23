extends BoTestBase
## Anchor base rules + prices round 2: Kin, Embers, Big Hand (production/anchor-contract.md; all adds go through m100_for, under bo.m_cap).

func _init() -> void:
	_name = "t_anchor_rules2"


func _k100(key: String) -> int:
	return int(roundf(CombatEngine.tune_knob("anchor", key, 0.0) * 100.0))

func _eng(anchor: String, mana: int = 0, awake: bool = false, stage: int = 3, relics: Array = []) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup_new({"node_id": "bo", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": CoreTestUtil.roster(["plant1", "beast1", "aqua1", "reptile1", "bug1"]),
		"relic_ids": relics, "combat_seed": 7, "start_mana": mana, "depth_stage": stage, "anchor_id": anchor, "anchor_awakened": awake})
	return e


func run() -> void:
	var d5 := face("dmg", 5)
	var all5 := [d5, d5, d5, d5, d5]
	# --- Kin: 3 of one class +0.40, otherwise -0.25 ---
	var k := _eng("a_kin")
	for i in 5:
		(k.party[i] as Unit).cls = "plant" if i < 3 else "beast"
	BoTestBase.force(k, [1, 1, 1, 2, 3], all5)
	eq(k.m100_for(k.party[0]), 130 + _k100("kin_set_add"), "Kin: SET of 3 with 3 same class = 1.30 + 0.40")
	eq(k.m100_for(k.party[3]), 100, "Kin: loose die untouched")
	eq(k.bo_group_m100(k.bo[0]), 130 + _k100("kin_set_add"), "Kin: bo_group_m100 matches member M")
	(k.party[2] as Unit).cls = "beast"
	k._snap_bo()
	eq(k.m100_for(k.party[0]), 130 - 25, "Kin: SET without 3 same class = 1.30 - 0.25")
	BoTestBase.force(k, [1, 1, 1, 1, 3], all5)
	for i in 5:
		(k.party[i] as Unit).cls = "plant" if i != 3 else "beast"
	eq(k.m100_for(k.party[0]), 100 + 120 + _k100("kin_set_add"), "Kin: SET of 4 (add 1.20) + 0.40")
	# cap
	ContentDB.combat_tune["bo"]["m_cap"] = 1.5
	eq(k.m100_for(k.party[0]), 150, "Kin: cap holds (m_cap 1.5)")
	set_knobs("default")
	# --- Big Hand ---
	var b := _eng("a_big_hand")
	BoTestBase.force(b, [1, 1, 1, 2, 3], all5)
	eq(b.m100_for(b.party[0]), 100, "Big Hand: SET of 3 gives no bonus")
	eq(b.bo_group_m100(b.bo[0]), 100, "Big Hand: preview matches")
	var b4 := _eng("a_big_hand")
	BoTestBase.force(b4, [1, 1, 1, 1, 3], all5)
	var plain4 := _eng("")
	BoTestBase.force(plain4, [1, 1, 1, 1, 3], all5)
	eq(b4.m100_for(b4.party[0]), plain4.m100_for(plain4.party[0]) + _k100("big_set45_add"), "Big Hand: SET of 4 +big_set45_add")
	var b5 := _eng("a_big_hand")
	BoTestBase.force(b5, [1, 1, 1, 1, 1], all5)
	var plain5 := _eng("")
	BoTestBase.force(plain5, [1, 1, 1, 1, 1], all5)
	eq(b5.m100_for(b5.party[0]), mini(plain5.m100_for(plain5.party[0]) + _k100("big_set45_add"), b5.bo_cap100()), "Big Hand: SET of 5 +0.40, capped")
	# --- Embers ---
	var m := _eng("a_embers")
	eq(m.stash_cap(), 2, "Embers: Hold 2 dice")
	eq(_eng("").stash_cap(), 1, "no Anchor: Hold 1")
	BoTestBase.force(m, [0, 1, 2, 3, 4], all5)
	ok(m.stash(m.party[0].uid) and m.stash(m.party[1].uid), "two Holds accepted")
	ok(not m.stash(m.party[2].uid), "third Hold refused")
	m.end_turn(1)
	if not (m.party[0] as Unit).stash_carry:
		m.roll_all()
	ok((m.party[0] as Unit).stash_carry and (m.party[1] as Unit).stash_carry, "Held dice carried")
	ok(not (m.party[2] as Unit).stash_carry, "price: only Held dice carry over")
	var loose := _eng("a_embers")
	BoTestBase.force(loose, [0, 1, 2, 3, 4], all5)
	(loose.party[0] as Unit).stash_carry = true
	eq(loose.m100_for(loose.party[0]), 100 + _k100("embers_add"), "Embers: carried die +embers_add")
	eq(loose.m100_for(loose.party[1]), 100, "Embers: not carried = nothing")
	BoTestBase.force(loose, [1, 1, 1, 2, 3], all5)
	(loose.party[0] as Unit).stash_carry = true
	eq(loose.m100_for(loose.party[0]), 130 + _k100("embers_add"), "Embers: carried die in a SET stacks +0.50")
	ContentDB.combat_tune["bo"]["m_cap"] = 1.4
	eq(loose.m100_for(loose.party[0]), 140, "Embers: cap holds")
	set_knobs("default")

	# --- Stage 2 (Anchors open there): same rules, Hold and Wild are open ---
	var k2 := _eng("a_kin", 0, false, 2)
	for i in 5:
		(k2.party[i] as Unit).cls = "plant" if i < 3 else "beast"
	BoTestBase.force(k2, [1, 1, 1, 2, 3], all5)
	eq(k2.m100_for(k2.party[0]), 130 + _k100("kin_set_add"), "stage 2 Kin: +kin_set_add")
	var b2 := _eng("a_big_hand", 0, false, 2)
	BoTestBase.force(b2, [1, 1, 1, 2, 3], all5)
	eq(b2.m100_for(b2.party[0]), 100, "stage 2 Big Hand: SET of 3 no bonus")
	var m2 := _eng("a_embers", 0, false, 2)
	eq(m2.stash_cap(), 2, "stage 2 Embers: Hold 2")
	BoTestBase.force(m2, [0, 1, 2, 3, 4], all5)
	(m2.party[0] as Unit).stash_carry = true
	eq(m2.m100_for(m2.party[0]), 100 + _k100("embers_add"), "stage 2 Embers: carried die +embers_add")

	# --- Kin + Concord: Concord counts one die per class, so Kin's miss penalty is waived; Concord is not offered under Kin ---
	var kc := _eng("a_kin", 0, false, 3, ["c_concord"])
	for i in 5:
		(kc.party[i] as Unit).cls = "plant" if i < 3 else "beast"
	BoTestBase.force(kc, [1, 1, 1, 2, 3], all5)
	for i in 5:
		(kc.party[i] as Unit).cls = ["plant", "beast", "aqua", "reptile", "bug"][i]
	kc._snap_bo()
	var cd = RelicRegistry.get_def("c_concord")
	ok(cd != null, "c_concord exists")
	if cd != null and not kc.bo.is_empty():
		eq(kc.m100_for(kc.party[0]), kc.bo_group_m100(kc.bo[0]), "Kin+Concord: preview = member M")
		eq(kc.m100_for(kc.party[0]), 100 + int((kc.bo[0] as Dictionary)["m100"]) - 100, "Kin+Concord: no -0.25 penalty")
		var kn := _eng("a_kin")
		BoTestBase.force(kn, [1, 1, 1, 2, 3], all5)
		for i in 5:
			(kn.party[i] as Unit).cls = ["plant", "beast", "aqua", "reptile", "bug"][i]
		eq(kn.m100_for(kn.party[0]), 130 - 25, "same SET without Concord: the -0.25 applies")
		eq(kc.m100_for(kc.party[0]) - kn.m100_for(kn.party[0]), 25, "Concord waives exactly the -0.25")
	var cx := CoreTestUtil.ctx([], [], ["plant1", "beast1", "aqua1", "reptile1", "bug1"], 3)
	var base_ok := CoreOffer.is_valid(cd, cx)
	cx["anchor_id"] = "a_kin"
	ok(not CoreOffer.is_valid(cd, cx), "Concord is not offered under Kin")
	cx["anchor_id"] = "a_volley"
	eq(CoreOffer.is_valid(cd, cx), base_ok, "other Anchors do not change Concord's validity")

	# --- bo_group_m100 includes the SET-wide Overcast (UI label), not the per-die parts ---
	var oc := _eng("a_mana_mine", 12)
	BoTestBase.force(oc, [1, 1, 1, 2, 3], all5)
	var g0 := oc.bo_group_m100(oc.bo[0])
	ok(oc.overcast(oc.party[0].uid), "Overcast the SET")
	eq(oc.bo_group_m100(oc.bo[0]), g0 + 50, "group value gains the Overcast +0.50")
	eq(oc.bo_group_m100(oc.bo[0]), oc.m100_for(oc.party[1]), "group value = M of an ordinary SET die")
	eq(oc.bo_group_m100(oc.bo[0]), oc.m100_for(oc.party[0]), "...and of the overcast die itself")
	var oe := _eng("a_embers", 12)
	BoTestBase.force(oe, [1, 1, 1, 2, 3], all5)
	(oe.party[0] as Unit).stash_carry = true
	eq(oe.bo_group_m100(oe.bo[0]), oe.m100_for(oe.party[1]), "per-die Embers carry stays out of the group value")
