extends BoTestBase
## Anchor awakenings round 2: Unison (Kin), Passed Flame (Embers), Sixth Hand (Big Hand) + undo, save/load, deterministic re-run.

func _init() -> void:
	_name = "t_anchor_awaken2"


func _eng(anchor: String, mana: int, awake: bool, seed_v: int = 7, stage: int = -1) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup_new({"node_id": "bo", "kind": "battle", "pw": 2, "ascension": 0, "roster_snapshot": CoreTestUtil.roster(["plant1", "beast1", "aqua1", "reptile1", "bug1"]),
		"relic_ids": [], "combat_seed": seed_v, "start_mana": mana, "depth_stage": stage if stage > 0 else _st, "anchor_id": anchor, "anchor_awakened": awake})
	return e


func _reload(e: CombatEngine) -> CombatEngine:
	var r := CombatEngine.new()
	r.from_data(JSON.parse_string(JSON.stringify(e.to_data())))
	return r


func _faces(e: CombatEngine) -> Array:
	var o: Array = []
	for u in e.party:
		o.append((u as Unit).roll_face_index())
	return o


## Unison on a fixed roll (cantrip rerolls in roll_all come later and are not Unison's business): parts 0..4 on five dice of one class.
func _unison_run(awake: bool, turn_no: int) -> Array:
	var e := _eng("a_kin", 0, awake, 3)
	var d5 := face("dmg", 5)
	BoTestBase.force(e, [0, 1, 2, 3, 4], [d5, d5, d5, d5, d5], false)
	for u in e.party:
		(u as Unit).cls = "plant"
	e.turn = turn_no
	e._anchor_unison()
	return _faces(e)


var _st := 3   ## depth stage of the engines; the whole body runs at stage 3 and at stage 2 (Wild and Hold are open there)


func run() -> void:
	for st in [3, 2]:
		_st = st
		_body()
	_cantrip_stream()


func _body() -> void:
	# --- Unison: first turn, same class rolls the same part, up to 4 ---
	var on := _unison_run(true, 1)
	eq(on, [0, 0, 0, 0, 4], "Unison turn 1: four dice show the first die's part, the fifth keeps its own")
	eq(_unison_run(true, 1), on, "Unison deterministic")
	eq(_unison_run(false, 1), [0, 1, 2, 3, 4], "not awakened: faces untouched")
	eq(_unison_run(true, 2), [0, 1, 2, 3, 4], "Unison only on the first turn")
	var mix := _eng("a_kin", 0, true)
	BoTestBase.force(mix, [0, 1, 2, 3, 4], face("dmg", 5), false)
	for i in 5:
		(mix.party[i] as Unit).cls = "plant" if i < 2 else "beast"
	mix._anchor_unison()
	eq(_faces(mix), [0, 0, 2, 2, 2], "Unison works per class")
	var rl0 := _reload(mix)
	ok(rl0.anchor_awakened and rl0.anchor_id == "a_kin", "save/load keeps the awakened Kin")

	# --- Passed Flame: carried Held die = free Temp Face, once a turn ---
	for awake in [false, true]:
		var e := _eng("a_embers", 0, awake)
		var d5 := face("dmg", 5)
		BoTestBase.force(e, [1, 1, 1, 2, 3], [d5, d5, d5, d5, d5])
		(e.party[3] as Unit).stash_carry = true
		(e.party[4] as Unit).stash_carry = true
		eq(e.can_wild_face(e.party[3].uid, 1), awake, "Passed Flame free Temp Face only when awakened (mana 0)")
		if awake:
			var snap := e.to_data()
			var mana0 := e.mana
			ok(e.wild_face(e.party[3].uid, 1), "wild_face on a carried die")
			eq(e.mana, mana0, "no mana spent")
			eq(e.wild_used, 0, "battle Mat Tam not used")
			ok(bool(e.anchor_turn["pf_used"]), "pf_used set")
			eq((e.bo[0] as Dictionary)["size"], 4, "SET of four")
			ok(not e.can_wild_face(e.party[4].uid, 1), "once per turn")
			eq(_reload(e).anchor_turn["pf_used"], true, "pf_used survives save/load")
			e.undo_last()
			ok(not bool(e.anchor_turn["pf_used"]) and (e.bo[0] as Dictionary)["size"] == 3, "undo rewinds the flag and the SET")
			var e2 := CombatEngine.new()
			e2.from_data(snap)
			e2.wild_face(e2.party[3].uid, 1)
			e.wild_face(e.party[3].uid, 1)
			eq(JSON.stringify(e2.bo), JSON.stringify(e.bo), "re-applied action gives the same SET")

	# --- Sixth Hand: a SET of four brings one bonus die, outside the SET ---
	for awake in [false, true]:
		var e := _eng("a_big_hand", 5, awake)
		var d5 := face("dmg", 5)
		BoTestBase.force(e, [1, 1, 1, 2, 3], [d5, d5, d5, d5, d5])
		eq(e.party.size(), 5, "no bonus die with a SET of three")
		var snap := e.to_data()
		ok(e.wild_face(e.party[3].uid, 1), "Mat Tam makes a SET of four")
		if not awake:
			eq(e.party.size(), 5, "not awakened: no bonus die")
			continue
		eq(e.party.size(), 6, "Sixth Hand: one bonus die")
		var ph := e.party[5] as Unit
		ok(ph.custom_state.has("phantom") and ph.has_rolled(), "bonus die is a rolled phantom")
		ok(not (e.bo[0]["uids"] as Array).has(ph.uid), "bonus die is not in the SET")
		ok(bool(e.anchor_turn["sh"]), "sh flag set")
		e._snap_bo()
		eq(e.party.size(), 6, "only one per turn")
		var rl := _reload(e)
		eq(rl.party.size(), 6, "save/load keeps the bonus die")
		ok(bool(rl.anchor_turn["sh"]), "sh survives save/load")
		var face_a := ph.roll_face_index()
		e.undo_last()
		eq(e.party.size(), 5, "undo removes the bonus die")
		ok(not bool(e.anchor_turn["sh"]), "undo clears sh")
		ok(e.wild_face(e.party[3].uid, 1), "redo")
		eq((e.party[5] as Unit).roll_face_index(), face_a, "the redo rolls the same bonus die (own stream)")
		var e2 := CombatEngine.new()
		e2.from_data(snap)
		e2.wild_face(e2.party[3].uid, 1)
		eq(JSON.stringify(e2.to_data().get("party")), JSON.stringify(e.to_data().get("party")), "replay from the same snapshot: identical party")


## Sixth Hand with every spare face a cantrip: the bonus die's rolls must not move the main rng cursor. (Phantoms are sidelined, so
## _resolve_cantrips never resolves a cantrip on them; the cursor check still guards the face roll and any later change there.)
func _cantrip_stream() -> void:
	for sd in [1, 2, 3, 4, 5]:
		var e := _eng("a_big_hand", 5, true, sd)
		var d5 := face("dmg", 5)
		BoTestBase.force(e, [1, 1, 1, 2, 3], [d5, d5, d5, d5, d5])
		var cant := face("dmg", 1, 0, ["cantrip"])
		for u in e.party:
			for fi in [0, 4, 5]:
				(u as Unit).die[fi] = cant.duplicate(true)
		var before := e._rng.get_state()
		ok(e.wild_face(e.party[3].uid, 1), "seed %d: wild_face" % sd)
		eq(e.party.size(), 6, "seed %d: bonus die spawned" % sd)
		eq(e._rng.get_state(), before, "seed %d: main rng cursor did not move (bonus die rolls on its own stream)" % sd)
		var e2 := _eng("a_big_hand", 5, true, sd)
		BoTestBase.force(e2, [1, 1, 1, 2, 3], [d5, d5, d5, d5, d5])
		for u in e2.party:
			for fi in [0, 4, 5]:
				(u as Unit).die[fi] = cant.duplicate(true)
		e2.wild_face(e2.party[3].uid, 1)
		eq(_faces(e2), _faces(e), "seed %d: deterministic" % sd)
