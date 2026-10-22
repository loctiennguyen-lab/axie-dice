extends BoTestBase
## Anchor house mutations (houses.json; production/anchor-2b-brief.md): 6 houses x tier 1/2, undo, save/load, no overflow on a won turn.

var _fired: Array = []

func _init() -> void:
	_name = "t_mutation_houses"


func _eng(tiers: Dictionary, mana: int = 0, seed_v: int = 7) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup_new({"node_id": "bo", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": CoreTestUtil.roster(["plant1", "beast1", "aqua1", "reptile1", "bug1"]),
		"relic_ids": [], "combat_seed": seed_v, "start_mana": mana, "depth_stage": 3, "anchor_id": "a_gambler", "anchor_awakened": false, "house_tiers": tiers})
	for t in e.enemies:
		(t as Unit).hp = 90
		(t as Unit).max_hp = 90
		(t as Unit).shield = 0
	for p in e.party:
		(p as Unit).shield = 0
	return e


func _on_fire(id: String, uid: int, amount: int, kind: String) -> void:
	if kind == "mutation":
		_fired.append([id, amount])


func run() -> void:
	EventBus.core_fired.connect(_on_fire)
	var d5 := face("dmg", 5)
	var set3 := [1, 1, 1, 2, 3]
	# --- h_volley Spiked Shield ---
	var shields := {}
	for t in [1, 2]:
		var e := _eng({"h_volley": t})
		BoTestBase.force(e, set3, [face("shield", 9), d5, d5, d5, d5])
		_fired = []
		var u := e.party[0] as Unit
		e.party[0].shield = 0
		var sh_val := e._face_value(u, u.roll_face_index())
		var th := 0
		var b0 := _eng({})
		BoTestBase.force(b0, set3, [face("shield", 9), d5, d5, d5, d5])
		b0.use_die(b0.party[0].uid, b0.party[0].uid)
		var st0 := int((b0.party[0] as Unit).status.get("thorns", 0))   # what the face itself leaves, no mutation
		ok(sh_val >= 9, "SET shield face value %d" % sh_val)
		ok(e.use_die(u.uid, u.uid), "use shield die")
		th = int(u.custom_state.get("tmp_thorns", 0))
		ok(th >= 3 and th <= 4, "tier %d: Thorns = min(4, value/3) = %d" % [t, th])
		shields[t] = u.shield
		if t == 2:
			eq(shields[1] + th, shields[2], "tier 1 Shield is reduced by exactly the Thorns, tier 2 keeps it whole")
		ok(_fired.has(["h_volley", th]), "tier %d: core_fired mutation" % t)
		eq(int(e.anchor_fight["fired"]["h_volley"]), th, "tier %d: fight tally" % t)
		# thorns reflect on an enemy hit
		var foe := e.enemies[0] as Unit
		var fh := foe.hp
		DamagePipeline.resolve({"combat": e, "src": foe, "tgt": u, "value": 1, "attack": true})
		eq(fh - foe.hp, th + st0, "tier %d: temp Thorns reflect" % t)
		eq(int(u.status.get("thorns", 0)), st0, "tier %d: status thorns (and thorns.cap) untouched" % t)
		# save/load keeps tally + temp thorns + tier
		var r := CombatEngine.new()
		r.from_data(JSON.parse_string(JSON.stringify(e.to_data())))
		eq(int((r.party[0] as Unit).custom_state.get("tmp_thorns", 0)), th, "save keeps tmp_thorns")
		eq(int(r.anchor_fight["fired"]["h_volley"]), th, "save keeps fight tally")
		eq(r._mut_tier("h_volley"), t, "save keeps tier")
		# undo
		ok(e.undo_last(), "undo")
		eq(int((e.party[0] as Unit).custom_state.get("tmp_thorns", 0)), 0, "undo removes tmp_thorns")
		eq((e.party[0] as Unit).shield, 0, "undo restores shield")
		ok(not e.anchor_fight["fired"].has("h_volley"), "undo rewinds tally")
		# cleared at the start of the next player turn
		u.custom_state["tmp_thorns"] = 3
		e.roll_all()
		ok(not (e.party[0] as Unit).custom_state.has("tmp_thorns"), "roll_all clears tmp_thorns")
	var nv := _eng({"h_volley": 1})
	BoTestBase.force(nv, [0, 1, 2, 3, 4], [face("shield", 9), d5, d5, d5, d5])
	var nv0 := _eng({})
	BoTestBase.force(nv0, [0, 1, 2, 3, 4], [face("shield", 9), d5, d5, d5, d5])
	nv0.use_die(nv0.party[0].uid, nv0.party[0].uid)
	nv.use_die(nv.party[0].uid, nv.party[0].uid)
	eq((nv.party[0] as Unit).shield, (nv0.party[0] as Unit).shield, "no SET: no mutation")

	# --- h_gambler Crack Mana ---
	var two_seed := -1
	for s in 600:
		var g := _gamble(s, 0)
		if g["cracked"] == 2:
			two_seed = s
			break
	ok(two_seed >= 0, "found a 2-Crack seed")
	for t in [0, 1, 2]:
		var g := _gamble(two_seed, t)
		eq(g["mana"], t, "tier %d: mana from 2 Cracks" % t)
	var gg := _gamble_eng(two_seed, 1)
	var snap := gg.to_data()
	gg.reroll_dice([gg.party[0].uid, gg.party[1].uid], two_seed, false, 0)
	eq(int(gg.anchor_turn["cr_n"]), 1, "tier 1 tally cr_n")
	var rl := CombatEngine.new()
	rl.from_data(JSON.parse_string(JSON.stringify(gg.to_data())))
	eq(int(rl.anchor_turn["cr_n"]), 1, "save keeps cr_n")
	gg.from_data(snap)
	eq(int(gg.anchor_turn["cr_n"]), 0, "snapshot rewinds cr_n")

	# --- h_mana_mine Mana Overflow ---
	for t in [1, 2]:
		var m := _eng({"h_mana_mine": t}, 5)
		m.mana = 5
		var hp0 := (m.enemies[0] as Unit).hp
		_fired = []
		m.begin_end_turn(11)
		eq((m.enemies[0] as Unit).hp, hp0 - (2 if t == 1 else 4), "tier %d: every enemy takes %d" % [t, 2 if t == 1 else 4])
		eq(m.mana, 4, "tier %d: costs 1 mana" % t)
		ok(_fired.size() == 1 and _fired[0][0] == "h_mana_mine", "tier %d: core_fired once" % t)
	var low := _eng({"h_mana_mine": 1}, 2)
	low.mana = 2
	var lh := (low.enemies[0] as Unit).hp
	low.begin_end_turn(11)
	eq((low.enemies[0] as Unit).hp, lh, "under 3 mana: nothing")
	var won := _eng({"h_mana_mine": 1}, 5)
	won.mana = 5
	won.won = true
	won._mut_overflow()
	eq(won.mana, 5, "won turn: no Overflow")
	var clear := _eng({"h_mana_mine": 1}, 5)
	clear.mana = 5
	for en in clear.enemies:
		(en as Unit).hp = 0
	clear._mut_overflow()
	eq(clear.mana, 5, "no enemy standing: no Overflow")

	# --- h_kin Cover ---
	for t in [1, 2]:
		var k := _eng({"h_kin": t})
		k.anchor_fight["kin"] = false
		for p in k.party:
			(p as Unit).shield = 0
			(p as Unit).hp = 30
		(k.party[1] as Unit).hp = 5
		BoTestBase.force(k, set3, [d5, d5, d5, d5, d5])
		eq((k.party[1] as Unit).shield, 6 if t == 1 else 9, "tier %d: weakest front Axie gets %d x 3" % [t, 2 if t == 1 else 3])
		eq((k.party[0] as Unit).shield, 0, "tier %d: others untouched" % t)
		ok(bool(k.anchor_fight["kin"]), "kin flag set")
		BoTestBase.force(k, [0, 1, 2, 3, 4], [d5, d5, d5, d5, d5])
		BoTestBase.force(k, set3, [d5, d5, d5, d5, d5])
		eq((k.party[1] as Unit).shield, 6 if t == 1 else 9, "tier %d: only once a fight" % t)
		var kr := CombatEngine.new()
		kr.from_data(JSON.parse_string(JSON.stringify(k.to_data())))
		ok(bool(kr.anchor_fight["kin"]), "save keeps kin flag")

	# --- h_embers Last Strike ---
	for t in [0, 1, 2]:
		var em := _eng({"h_embers": t} if t > 0 else {})
		BoTestBase.force(em, set3, [d5, d5, d5, d5, d5])
		var m_base := em.m100_for(em.party[0])
		ok(m_base > 100, "tier %d: SET M before the last die (%d)" % [t, m_base])
		_fired = []
		var tg := (em.enemies[1] as Unit).uid
		for i in [1, 2, 3, 4]:
			em.use_die(em.party[i].uid, tg)
		eq(em.m100_for(em.party[0]), m_base + 30 * t, "tier %d: last SET die +%d" % [t, 30 * t])
		em.use_die(em.party[0].uid, tg)
		eq(_fired.has(["h_embers", 30 * t]), t > 0, "tier %d: core_fired" % t)
	var cap := _eng({"h_embers": 2})
	BoTestBase.force(cap, [1, 1, 1, 1, 1], [d5, d5, d5, d5, d5])
	for i in [1, 2, 3, 4]:
		cap.use_die(cap.party[i].uid, (cap.enemies[1] as Unit).uid)
	ok(cap.m100_for(cap.party[0]) <= cap.bo_cap100(), "Embers stays under m_cap")

	# --- h_big_hand Hunt Four ---
	var base := _eng({}, 5)
	base.rerolls = 0
	BoTestBase.force(base, set3, [d5, d5, d5, d5, d5])
	eq(base.reroll_mana_cost(false, 1), 1, "no house: first paid Safe costs 1")
	for t in [1, 2]:
		var b := _eng({"h_big_hand": t}, 5)
		b.rerolls = 0
		BoTestBase.force(b, set3, [d5, d5, d5, d5, d5])
		eq(b.reroll_mana_cost(false, 1), 0, "tier %d: first Safe free" % t)
		_fired = []
		ok(b.reroll_dice([b.party[3].uid], 5, false, 1), "Safe reroll")
		ok(b.mana >= 5, "tier %d: no mana spent (%d)" % [t, b.mana])
		eq(int(b.anchor_turn["safe_n"]), 1, "tier %d: safe_n tally" % t)
		eq(b.reroll_paid_k, 1, "tier %d: still counts toward the 3 rolls" % t)
		ok(_fired.has(["h_big_hand", 1]), "tier %d: core_fired" % t)
		BoTestBase.force(b, set3, [d5, d5, d5, d5, d5])
		eq(b.reroll_mana_cost(false, 1), 3 if t == 1 else 1, "tier %d: second Safe %s" % [t, "normal 3" if t == 1 else "costs 1"])
		var br := CombatEngine.new()
		br.from_data(JSON.parse_string(JSON.stringify(b.to_data())))
		eq(int(br.anchor_turn["safe_n"]), 1, "save keeps safe_n")
	var b4 := _eng({"h_big_hand": 2}, 5)
	b4.rerolls = 0
	BoTestBase.force(b4, [1, 1, 1, 1, 3], [d5, d5, d5, d5, d5])
	eq(b4.reroll_mana_cost(false, 1), 1, "SET of four: no Hunt Four")
	EventBus.core_fired.disconnect(_on_fire)


func _gamble_eng(seed_v: int, tier: int) -> CombatEngine:
	var e := _eng({"h_gambler": tier} if tier > 0 else {}, 0, 7)
	e.rerolls = 0
	BoTestBase.force(e, [0, 1, 2, 3, 4], [face("dmg", 5), face("dmg", 5), face("dmg", 5), face("dmg", 5), face("dmg", 5)])
	return e


func _gamble(seed_v: int, tier: int) -> Dictionary:
	var e := _gamble_eng(seed_v, tier)
	var m0 := e.mana
	e.reroll_dice([e.party[0].uid, e.party[1].uid], seed_v, false, 0)
	var c := 0
	for i in 2:
		if (e.party[i] as Unit).cracked:
			c += 1
	return {"cracked": c, "mana": e.mana - m0}
