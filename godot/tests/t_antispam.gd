extends BoTestBase
## Anti-spam v5 (design/proposals/anti-spam-v5.md): A Mana Heat, B Shell, C Chain. Each block alone does the numbers of the proposal;
## switched off (or absent) the fight is identical; undo and save/load keep the per-turn tally.

func _init() -> void:
	_name = "t_antispam"


func _tune(block: String, vals: Dictionary) -> void:
	var b: Dictionary = (ContentDB.combat_tune.get(block, {}) as Dictionary).duplicate(true)
	for k in vals:
		b[k] = vals[k]
	ContentDB.combat_tune[block] = b


func _fresh() -> void:
	ContentDB.combat_tune = _tune_backup.duplicate(true)


func _eng(kind: String = "battle", mana: int = 0, anchor: String = "", awake: bool = false, pw: int = 2) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup_new({"node_id": "as", "kind": kind, "pw": pw, "ascension": 0, "roster_snapshot": CoreTestUtil.roster(["plant1", "beast1", "aqua1", "reptile1", "bug1"]),
		"relic_ids": [], "combat_seed": 7, "start_mana": mana, "depth_stage": 3, "anchor_id": anchor, "anchor_awakened": awake})
	return e


## Distinct part per die so no Set (BO) forms; one big dummy enemy without Plating / Shield.
func _prep(faces: Array) -> CombatEngine:
	var e := _eng()
	var fl: Array = []
	for i in faces.size():
		var f: Dictionary = (faces[i] as Dictionary).duplicate(true)
		f["part"] = "p%d" % i
		fl.append(f)
	force(e, range(faces.size()), fl)
	_dummy(e)
	return e


func _dummy(e: CombatEngine) -> void:
	for t in e.enemies:
		var u := t as Unit
		u.hp = 999
		u.max_hp = 999
		u.shield = 0
		u.plating = 0


func _fv(e: CombatEngine, i: int) -> int:
	var u: Unit = e.party[i]
	return e._face_value(u, u.roll_face_index())


func _play(e: CombatEngine, turns: int) -> void:
	for t in turns:
		for u in e.party:
			var tg: Array = e.alive_enemies()
			if tg.is_empty() or e.won or e.lost:
				break
			if (u as Unit).hp > 0 and (u as Unit).has_rolled() and not (u as Unit).roll_used():
				e.use_die((u as Unit).uid, (tg[0] as Unit).uid)
		if e.won or e.lost:
			break
		e.end_turn(11 + t)


func run() -> void:
	_test_off_is_identical()
	_test_chain()
	_test_heat()
	_test_shell()


func _test_off_is_identical() -> void:
	_fresh()
	for k in ["mana_heat", "shell", "chain"]:
		ContentDB.combat_tune.erase(k)
	var a := _eng("elite", 6, "a_mana_mine", true, 4)
	_play(a, 5)
	_fresh()
	for k in ["mana_heat", "shell", "chain"]:
		ok(not CombatEngine.antispam_on(k), "%s ships disabled" % k)
	var b := _eng("elite", 6, "a_mana_mine", true, 4)
	_play(b, 5)
	var da: Dictionary = JSON.parse_string(digest(a))
	var db: Dictionary = JSON.parse_string(digest(b))
	da.erase("antispam_turn")
	db.erase("antispam_turn")
	eq(JSON.stringify(da), JSON.stringify(db), "blocks absent vs disabled: same fight to the last field")
	ok(a.stat["turns"] >= 1, "sample fight ran")
	ok(not (a.enemies[0] as Unit).custom_state.has("shell"), "no shell when off")


func _test_chain() -> void:
	# party index -> face. Beast (1) and Reptile (3) hit for +2 by class, so damage dice sit on 0 / 2 / 4. Use order 0,1,2,4,3.
	var seq := [BoTestBase.face("dmg", 10), BoTestBase.face("shield", 10), BoTestBase.face("dmg", 10), BoTestBase.face("heal", 10), BoTestBase.face("dmg", 10)]
	var order := [0, 1, 2, 4, 3]
	_fresh()
	var off := _prep(seq)
	var offv: Array = []
	for i in order:
		offv.append(_fv(off, i))
	eq(offv, [10, 10, 10, 10, 10], "chain off: values untouched")
	_tune("chain", {"enabled": true})
	var e := _prep(seq)
	var want := [10, 12, 13, 9, 12]   # first 10 | other type +15% | other +30% | same type -10% (chain 0) | other +15%
	var snaps: Array = []
	var tgt := (e.enemies[0] as Unit).uid
	for k in 5:
		var i: int = order[k]
		eq(_fv(e, i), want[k], "chain step %d shows %d" % [k, want[k]])
		var hp0 := (e.enemies[0] as Unit).hp
		var tid2 := tgt if String(seq[i]["type"]) == "dmg" else (e.party[i] as Unit).uid
		ok(e.use_die((e.party[i] as Unit).uid, tid2), "use die %d" % i)
		snaps.append(e.to_data())
		if String(seq[i]["type"]) == "dmg":
			eq(hp0 - (e.enemies[0] as Unit).hp, want[k], "actual damage of step %d = preview" % k)
	eq(String(e.antispam_turn["chain_last"]), "heal", "last type tracked")
	eq(int(e.antispam_turn["chain_n"]), 1, "chain level after the last step")
	e.undo_last()
	eq(String(e.antispam_turn["chain_last"]), "dmg", "undo rewinds the chain type")
	eq(int(e.antispam_turn["chain_n"]), 0, "undo rewinds the chain level")
	eq(_fv(e, 3), 12, "after undo the same face shows the same value")
	var ld := CombatEngine.new()
	ld.from_data(JSON.parse_string(JSON.stringify(snaps[2])))
	eq(String(ld.antispam_turn["chain_last"]), "dmg", "save/load keeps chain type")
	eq(int(ld.antispam_turn["chain_n"]), 2, "save/load keeps chain level")
	eq(_fv(ld, 4), 9, "loaded fight prices the next same-type die with the penalty")
	_tune("chain", {"enabled": true, "step_pct": 200})
	var c := _prep(seq)
	c.use_die((c.party[0] as Unit).uid, (c.enemies[0] as Unit).uid)
	eq(c.m100_for(c.party[1]), c.bo_cap100(), "chain add is clamped by bo.m_cap")
	eq(int(CombatEngine.tune_knob("chain", "max", 0.0)), 3, "chain.max default 3")
	c.end_turn(5)
	eq(String(c.antispam_turn["chain_last"]), "", "tally reset on the next turn")


func _test_heat() -> void:
	_fresh()
	var off := _eng("battle", 9)
	var om := off.mana
	off.begin_end_turn(5)
	eq(off.mana, om, "heat off: mana untouched")
	_tune("mana_heat", {"enabled": true})
	var e := _eng("battle", 6)
	(e.party[0] as Unit).hp = 50
	(e.party[0] as Unit).max_hp = 50
	(e.party[1] as Unit).hp = 60
	(e.party[1] as Unit).max_hp = 60
	(e.party[2] as Unit).hp = 99
	(e.party[2] as Unit).max_hp = 99   # back row: never the target
	var pv := e.mana_heat_preview()
	eq(int(pv["excess"]), e.mana - 3, "preview: excess over keep 3")
	var m0 := e.mana
	var hp1 := (e.party[1] as Unit).hp
	(e.party[1] as Unit).shield = 40
	e.begin_end_turn(5)
	eq(e.mana, 3, "all mana over keep is burned")
	var want := mini((m0 - 3) * 2, 6)
	eq(hp1 - (e.party[1] as Unit).hp, want, "front-row highest-HP Axie takes min(2/pt, cap 6), ignoring Shield")
	eq((e.party[1] as Unit).shield, 40, "pierce: Shield untouched")
	eq(int(e.antispam_turn["heat_dmg"]), want, "tally kept")
	var ld := CombatEngine.new()
	ld.from_data(JSON.parse_string(JSON.stringify(e.to_data())))
	eq(int(ld.antispam_turn["heat_dmg"]), want, "save/load keeps the heat tally")
	eq(int(ld.antispam_turn["heat_uid"]), (e.party[1] as Unit).uid, "and the victim")
	var big := _eng("battle", 30)
	var hb := (big.party[0] as Unit).hp + (big.party[1] as Unit).hp
	big.begin_end_turn(5)
	eq(hb - ((big.party[0] as Unit).hp + (big.party[1] as Unit).hp), 6, "per_turn_cap 6")
	var mine := _eng("battle", 6, "a_mana_mine", true)
	eq(mine.mana_heat_keep(), 5, "awakened Mana Mine keeps 2 more")
	eq(int(mine.mana_heat_preview()["excess"]), maxi(0, mine.mana - 5), "preview follows the Mine keep")
	var low := _eng("battle", 2)
	var lhp := (low.party[0] as Unit).hp
	low.begin_end_turn(5)
	eq(low.mana, low.mana, "no-op sanity")
	eq((low.party[0] as Unit).hp, lhp, "mana at or under keep: nothing happens")


func _test_shell() -> void:
	_fresh()
	_tune("shell", {"enabled": true})
	var e := _eng("elite", 0, "", false, 4)
	var boss := e.enemies[0] as Unit
	eq(int(boss.custom_state.get("shell", -1)), RulesMath.round_half_up(boss.max_hp * 0.4), "elite shell = 40% max HP")
	ok(not (e.enemies[1] as Unit).custom_state.has("shell") if e.enemies.size() > 1 else true, "escorts have none")
	var n := _eng("battle", 0, "", false, 4)
	ok(not (n.enemies[0] as Unit).custom_state.has("shell"), "normal fight: no shell")
	var b := _eng("boss", 0, "", false, 4)
	var bb := b.enemies[0] as Unit
	ok(int(bb.custom_state.get("shell", 0)) > 0, "boss has a shell")
	# numbers: dummy elite, hand-set shell
	var plain := BoTestBase.face("dmg", 10)
	var pierce := BoTestBase.face("dmg", 10, 0, ["pierce"])
	var faces := [plain, plain, plain, plain, pierce]
	var s := _prep_shell(faces, 8)
	var t := s.enemies[0] as Unit
	var tid := t.uid
	s.use_die((s.party[0] as Unit).uid, tid)
	eq(shell_left(t), 3, "plain dmg face (no Set) counts 50%: 10 -> 5 off the shell 8")
	eq(t.hp, 999, "nothing reached HP")
	var snap := s.to_data()
	s.use_die((s.party[4] as Unit).uid, tid)
	eq(shell_left(t), 0, "pierce counts full: shell gone")
	eq(t.hp, 999 - 7, "pierce 10 vs shell 3: 7 through")
	s.undo_last()
	t = s.enemies[0] as Unit   # undo rebuilds the units
	eq(shell_left(t), 3, "undo restores the shell")
	eq(t.hp, 999, "and HP")
	var ld := CombatEngine.new()
	ld.from_data(JSON.parse_string(JSON.stringify(snap)))
	eq(shell_left(ld.enemies[0]), 3, "save/load keeps the shell")
	# Set die counts full
	var sets := _eng("elite", 0, "", false, 4)
	var sf := [plain, plain, plain, plain, plain]
	force(sets, [0, 0, 0, 1, 2], [_p(plain, "x"), _p(plain, "x"), _p(plain, "x"), _p(plain, "y"), _p(plain, "z")])
	_dummy(sets)
	var st := sets.enemies[0] as Unit
	st.custom_state["shell"] = 8
	var sv := sets._face_value(sets.party[0], 0)
	ok(sv > 10, "three-of-a-part is a Set and multiplies the face")
	sets.use_die((sets.party[0] as Unit).uid, st.uid)
	eq(shell_left(st), 0, "Set die counts full on the shell")
	eq(st.hp, 999 - (sv - 8), "the rest goes to HP")
	# boss Hollow turn: no shell
	var open := false
	bb.custom_state["trait"] = ""   # the Agony boss has no rhythm; this test needs one
	for tn in range(1, 7):
		bb.custom_state["turn_count"] = tn
		if b.boss_is_hollow(bb):
			open = true
			eq(b.shell_absorb(bb, 20.0, false), 20.0, "hollow turn: shell open, damage passes whole")
			ok(b.shell_open(bb), "shell_open on hollow turn")
		else:
			ok(not b.shell_open(bb), "closed on a normal turn %d" % tn)
	ok(open, "found a hollow turn")


func _p(f: Dictionary, part: String) -> Dictionary:
	var d := f.duplicate(true)
	d["part"] = part
	return d


func shell_left(u) -> int:
	return int((u as Unit).custom_state.get("shell", 0))


func _prep_shell(faces: Array, shell: int) -> CombatEngine:
	var e := _eng("elite", 0, "", false, 4)
	var fl: Array = []
	for i in faces.size():
		fl.append(_p(faces[i], "p%d" % i))
	force(e, range(faces.size()), fl)
	_dummy(e)
	(e.enemies[0] as Unit).custom_state["shell"] = shell
	(e.enemies[0] as Unit).custom_state["shell_max"] = shell
	return e
