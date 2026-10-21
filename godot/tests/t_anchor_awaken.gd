extends BoTestBase
## Anchor awakenings (production/anchor-2b-brief.md): Thorn Storm, Second Wind (+ undo/save), Double Beat.

func _init() -> void:
	_name = "t_anchor_awaken"


func _eng(anchor: String, mana: int, awake: bool) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup_new({"node_id": "bo", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": CoreTestUtil.roster(["plant1", "beast1", "aqua1", "reptile1", "bug1"]),
		"relic_ids": [], "combat_seed": 7, "start_mana": mana, "depth_stage": 3, "anchor_id": anchor, "anchor_awakened": awake})
	return e


func _prep_volley(awake: bool) -> CombatEngine:
	var e := _eng("a_volley", 0, awake)
	var d5 := face("dmg", 5)
	BoTestBase.force(e, [1, 1, 1, 2, 3], [d5, d5, d5, d5, d5])
	for t in e.enemies:
		(t as Unit).hp = 90
		(t as Unit).max_hp = 90
		(t as Unit).shield = 50
	return e


func run() -> void:
	# --- Thorn Storm ---
	for awake in [false, true]:
		var e := _prep_volley(awake)
		var other := e.enemies[0] as Unit
		var tgt := e.enemies[1] as Unit
		e.use_die(e.party[0].uid, tgt.uid)
		eq(other.hp, 90, "first blast stopped by Shield (awake=%s)" % awake)
		e.use_die(e.party[1].uid, tgt.uid)
		eq(other.hp, 90, "not every SET die used: no second blast (awake=%s)" % awake)
		e.use_die(e.party[2].uid, tgt.uid)
		eq(other.hp, 86 if awake else 90, "last SET die: second blast pierces Shield only when awakened")
		eq(other.shield, 50 - 4, "first blast hit the Shield, second did not touch it again")
	var pl := _prep_volley(true)
	(pl.enemies[0] as Unit).plating = 3
	(pl.enemies[0] as Unit).shield = 0
	pl.use_die(pl.party[0].uid, (pl.enemies[1] as Unit).uid)
	pl.use_die(pl.party[1].uid, (pl.enemies[1] as Unit).uid)
	var before := (pl.enemies[0] as Unit).hp
	pl.use_die(pl.party[2].uid, (pl.enemies[1] as Unit).uid)
	eq(before - (pl.enemies[0] as Unit).hp, 1, "Plating still cuts the second blast (4 - 3 = 1)")
	var sv := _prep_volley(true)   # undo: tally rewinds, blast fires again
	sv.use_die(sv.party[0].uid, (sv.enemies[1] as Unit).uid)
	sv.use_die(sv.party[1].uid, (sv.enemies[1] as Unit).uid)
	var s3 := sv.to_data()
	sv.use_die(sv.party[2].uid, (sv.enemies[1] as Unit).uid)
	ok(bool(sv.anchor_turn["vol2"]), "second blast flagged")
	sv.undo_last()
	ok(not bool(sv.anchor_turn["vol2"]), "undo rewinds the second-blast flag")
	var ld := CombatEngine.new()
	ld.from_data(JSON.parse_string(JSON.stringify(s3)))
	ok(bool(ld.anchor_turn["vol_fired"]) and (ld.anchor_turn["vol_uids"] as Array).size() == 3 and ld.anchor_awakened, "save/load keeps Volley state")

	# --- Second Wind ---
	var seed_c := -1
	for s in 400:
		var g := _gamble(true)
		g.reroll_dice([g.party[0].uid, g.party[1].uid], s, false, 0)
		var plain := _gamble(false)
		plain.reroll_dice([plain.party[0].uid, plain.party[1].uid], s, false, 0)
		if plain.party[0].cracked or plain.party[1].cracked:
			seed_c = s
			break
	ok(seed_c >= 0, "found a Cracking seed")
	var w := _gamble(true)
	var p := _gamble(false)
	var uids: Array = [w.party[0].uid, w.party[1].uid]
	var snap := w.to_data()
	p.reroll_dice([p.party[0].uid, p.party[1].uid], seed_c, false, 0)
	ok(w.reroll_dice(uids, seed_c, false, 0), "Gamble accepted")
	var crack_uid: int = p.party[0].uid if p.party[0].cracked else p.party[1].uid
	ok(not (w.by_uid(crack_uid) as Unit).cracked, "Second Wind cleared the Crack")
	eq(w.reroll_k, 2, "reroll_k went up for the free reroll")
	ok(bool(w.anchor_turn["sw_used"]), "once-per-turn flag set")
	eq(w.rerolls, p.rerolls, "free: no extra charge or mana spent")
	eq(w.reroll_total_turn, 1, "free reroll not counted against the cap")
	eq(w.mana, p.mana, "no mana spent")
	var ru := w.by_uid(crack_uid) as Unit
	eq(ru.roll_face_index(), Rng.new(seed_c ^ 2).next_int(6), "face comes from seed ^ (k+1)")
	# same result again from the same snapshot (undo / re-Gamble)
	var w2 := CombatEngine.new()
	w2.from_data(snap)
	w2.reroll_dice(uids, seed_c, false, 0)
	var same := true
	for i in 5:
		same = same and w2.party[i].roll_face_index() == w.party[i].roll_face_index() and w2.party[i].cracked == w.party[i].cracked
	ok(same, "re-Gamble after restore gives the identical result")
	# save/load mid turn keeps the flag, no second Wind this turn
	var w3 := CombatEngine.new()
	w3.from_data(JSON.parse_string(JSON.stringify(w.to_data())))
	ok(bool(w3.anchor_turn["sw_used"]), "sw_used survives save/load")
	# not awakened: Crack stays
	ok(p.party[0].cracked or p.party[1].cracked, "not awakened: Crack stays")

	# --- Double Beat ---
	for awake in [false, true]:
		var e := _eng("a_mana_mine", 12, awake)
		var d5 := face("dmg", 5)
		BoTestBase.force(e, [1, 1, 1, 2, 3], [d5, d5, d5, d5, d5])
		e.anchor_turn["mine"] = false
		e.mana = 12
		var m0 := e.m100_for(e.party[0])
		ok(e.overcast(e.party[0].uid), "first Overcast")
		eq(e.mana, 10, "first costs 2")
		eq(e.m100_for(e.party[0]), m0 + 50, "first adds +0.50")
		if awake:
			ok(e.overcast(e.party[0].uid), "second Overcast accepted when awakened")
			eq(e.mana, 8, "second costs 2")
			eq(e.m100_for(e.party[1]), m0 + 100, "second stacks +0.50 on the whole SET")
			ok(not e.overcast(e.party[0].uid), "no third")
			var s := e.to_data()
			var r := CombatEngine.new()
			r.from_data(JSON.parse_string(JSON.stringify(s)))
			eq(r.m100_for(r.party[1]), m0 + 100, "stack survives save/load")
			e.undo_last()
			eq(e.m100_for(e.party[1]), m0 + 50, "undo removes the second stack")
		else:
			ok(not e.overcast(e.party[0].uid), "not awakened: one Overcast a turn")


func _gamble(awake: bool) -> CombatEngine:
	var e := _eng("a_gambler", 3, awake)
	e.rerolls = 0
	BoTestBase.force(e, [0, 1, 2, 3, 4], face("dmg", 5))
	for i in 5:
		e.party[i].die[i] = face("dmg", 5)
	return e
