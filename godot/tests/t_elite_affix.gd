extends Node
## Depth v3 6.4 Elite affixes (assets/data/rules/elite_affixes.json). Trom Mana is not in the table (Liam dropped it).

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
var _enemy_acts := 0
var _enemy_uid := -1


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	_table()
	_shell_thorns_chill()
	_mults()
	_swarm()
	_rush()
	_fang()
	_ambush()
	_echo()
	print("=== t_elite_affix: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("t_elite_affix: FAIL - %s" % f)
	if _failures.is_empty():
		print("t_elite_affix: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


func _combat(affix_id: String, kind: String = "elite") -> CombatEngine:
	var roster: Array = []
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	for i in keys.size():
		roster.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var c := CombatEngine.new()
	c.setup_new({"node_id": "af", "kind": kind, "pw": 6, "ascension": 0, "roster_snapshot": roster,
		"relic_ids": [], "combat_seed": 99, "affix": affix_id})
	return c


func _dmg_intent(c: CombatEngine, target: Unit, value: int = 3) -> Unit:
	var e: Unit = c.enemies[0]
	e.die = [{"type": "dmg", "value": value, "keywords": [], "name": "t", "part": "mouth"}]
	e.set_roll(0, false)
	e.intent = {"face_index": 0, "target_uid": target.uid}
	return e


func _table() -> void:
	var t := ContentDB.elite_affixes
	_check(t.size() == 9, "nine affixes expected (Trom Mana dropped), got %d" % t.size())
	for id in ["echo", "shell", "frenzy", "swarm", "thorns", "rush", "fang", "ambush", "chill"]:
		_check(t.has(id), "missing affix %s" % id)
	_check(not _combat("shell", "battle").enemies[0].custom_state.has("affix"), "affix must only apply to elite fights")
	_check(_combat("").enemies[0].custom_state.get("affix", "") == "", "no affix = none")
	_check(String(_combat("shell").to_data()["affix"]) == "shell", "affix lost in to_data")


func _shell_thorns_chill() -> void:
	var c := _combat("shell")
	var e: Unit = c.enemies[0]
	_check(e.shield == int(round(e.max_hp * 0.4)) and e.shield > 0, "shell: shield = 40%% max hp, got %d/%d" % [e.shield, e.max_hp])
	var g := _combat("thorns")
	_check(int(g.enemies[0].status.get("thorns", 0)) == 3, "thorns: 3 at start")
	g.enemies[0].status["thorns"] = 0
	g._affix_turn_start()
	_check(int(g.enemies[0].status.get("thorns", 0)) == 3, "thorns: restored each turn")
	var ch := _combat("chill")
	var n := 0
	for u in ch.party:
		if u.frozen:
			n += 1
	_check(n == 1, "chill: exactly one die frozen on turn 1, got %d" % n)


func _mults() -> void:
	var c := _combat("frenzy")
	var e: Unit = c.enemies[0]
	_check(c.affix_dealt_mult(e) == 1.0, "frenzy: no bonus at full hp")
	e.hp = int(e.max_hp * 0.4)
	_check(absf(c.affix_dealt_mult(e) - 1.25) < 0.001, "frenzy: +25%% under 50%%")
	var ec := _combat("echo")
	_check(absf(ec.affix_dealt_mult(ec.enemies[0]) - 0.7) < 0.001, "echo: -30%% damage")


func _swarm() -> void:
	var c := _combat("swarm")
	var n0 := c.enemies.size()
	c._check_end()
	_check(c.enemies.size() == n0, "swarm: nothing above 50%")
	c.enemies[0].hp = int(c.enemies[0].max_hp * 0.4)
	c._check_end()
	_check(c.enemies.size() == n0 + 2, "swarm: 2 adds under 50%%, got %d" % (c.enemies.size() - n0))
	c._check_end()
	_check(c.enemies.size() == n0 + 2, "swarm fires only once")


func _on_face(uid: int, side: String, _t: int, _a: bool, _p: String, _n: String, _ty: String) -> void:
	if uid == _enemy_uid and side == "e":
		_enemy_acts += 1


func _rush() -> void:
	var c := _combat("rush")
	_check(c.turn == 1 and not c.affix_state()["double_now"] and not c.affix_state()["double_next"], "rush: quiet turn 1")
	c.turn = 2
	_check(bool(c.affix_state()["double_next"]), "rush: announced one turn early")
	c.turn = 3
	_check(bool(c.affix_state()["double_now"]), "rush: double on turn 3")
	for u in c.party:
		u.hp = 9999
		u.max_hp = 9999
	_dmg_intent(c, c.party[0])
	for e in c.enemies:
		if e != c.enemies[0]:
			e.hp = 0
	_enemy_uid = c.enemies[0].uid
	_enemy_acts = 0
	EventBus.face_used.connect(_on_face)
	c.begin_end_turn()
	c.step_end_turn_action(0)
	EventBus.face_used.disconnect(_on_face)
	_check(_enemy_acts == 2, "rush: elite should act twice on turn 3, acted %d" % _enemy_acts)


func _fang() -> void:
	var c := _combat("fang")
	var t: Unit = c.party[0]
	t.shield = 0
	t.hp = t.max_hp
	_dmg_intent(c, t)
	c.begin_end_turn()
	c.step_end_turn_action(0)
	_check(int(t.status.get("poison", 0)) >= 2, "fang: poison when the hit lands on HP")
	var d := _combat("fang")
	var s: Unit = d.party[0]
	s.shield = 500
	_dmg_intent(d, s)
	d.begin_end_turn()
	d.step_end_turn_action(0)
	_check(int(s.status.get("poison", 0)) == 0, "fang: no poison when the shield absorbs it")


func _ambush() -> void:
	var c := _combat("ambush")
	c.party[0].hp = 1   # weakest overall but FRONT row
	c.party[3].hp = 2   # weakest of the BACK row
	var e: Unit = c.enemies[0]
	e.die = [{"type": "dmg", "value": 3, "keywords": [], "name": "t", "part": "mouth"}]
	e.set_roll(0, false)
	c._pick_enemy_intent(e)
	_check(int(e.intent["target_uid"]) == c.party[3].uid, "ambush: weakest of the back row")


func _echo() -> void:
	var c := _combat("echo")
	var e: Unit = c.enemies[0]
	e.die = [{"type": "dmg", "value": 3, "keywords": [], "name": "a", "part": "mouth"},
		{"type": "shield", "value": 2, "keywords": [], "name": "b", "part": "back"}]
	e.custom_state["last_face"] = 1
	e.set_roll(0, false)
	c._affix_echo(e)
	_check(e.roll_face_index() == 1, "echo: repeats last turn's face")


func _check(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)
