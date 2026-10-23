extends BoTestBase
## Anchor base rules + prices round 2: Kin, Embers, Big Hand (production/anchor-contract.md; all adds go through m100_for, under bo.m_cap).

func _init() -> void:
	_name = "t_anchor_rules2"


func _eng(anchor: String, mana: int = 0, awake: bool = false) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup_new({"node_id": "bo", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": CoreTestUtil.roster(["plant1", "beast1", "aqua1", "reptile1", "bug1"]),
		"relic_ids": [], "combat_seed": 7, "start_mana": mana, "depth_stage": 3, "anchor_id": anchor, "anchor_awakened": awake})
	return e


func run() -> void:
	var d5 := face("dmg", 5)
	var all5 := [d5, d5, d5, d5, d5]
	# --- Kin: 3 of one class +0.40, otherwise -0.25 ---
	var k := _eng("a_kin")
	for i in 5:
		(k.party[i] as Unit).cls = "plant" if i < 3 else "beast"
	BoTestBase.force(k, [1, 1, 1, 2, 3], all5)
	eq(k.m100_for(k.party[0]), 130 + 40, "Kin: SET of 3 with 3 same class = 1.30 + 0.40")
	eq(k.m100_for(k.party[3]), 100, "Kin: loose die untouched")
	eq(k.bo_group_m100(k.bo[0]), 170, "Kin: bo_group_m100 matches member M")
	(k.party[2] as Unit).cls = "beast"
	k._snap_bo()
	eq(k.m100_for(k.party[0]), 130 - 25, "Kin: SET without 3 same class = 1.30 - 0.25")
	BoTestBase.force(k, [1, 1, 1, 1, 3], all5)
	for i in 5:
		(k.party[i] as Unit).cls = "plant" if i != 3 else "beast"
	eq(k.m100_for(k.party[0]), 100 + 120 + 40, "Kin: SET of 4 (add 1.20) + 0.40")
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
	eq(b4.m100_for(b4.party[0]), plain4.m100_for(plain4.party[0]) + 40, "Big Hand: SET of 4 +0.40")
	var b5 := _eng("a_big_hand")
	BoTestBase.force(b5, [1, 1, 1, 1, 1], all5)
	var plain5 := _eng("")
	BoTestBase.force(plain5, [1, 1, 1, 1, 1], all5)
	eq(b5.m100_for(b5.party[0]), mini(plain5.m100_for(plain5.party[0]) + 40, b5.bo_cap100()), "Big Hand: SET of 5 +0.40, capped")
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
	eq(loose.m100_for(loose.party[0]), 150, "Embers: carried die +0.50")
	eq(loose.m100_for(loose.party[1]), 100, "Embers: not carried = nothing")
	BoTestBase.force(loose, [1, 1, 1, 2, 3], all5)
	(loose.party[0] as Unit).stash_carry = true
	eq(loose.m100_for(loose.party[0]), 130 + 50, "Embers: carried die in a SET stacks +0.50")
	ContentDB.combat_tune["bo"]["m_cap"] = 1.4
	eq(loose.m100_for(loose.party[0]), 140, "Embers: cap holds")
	set_knobs("default")
