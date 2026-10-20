extends Node
## Depth v3 6.7b anti-stall: a team of Aqua/Plant that only presses dmg faces (nothing breaks Plating) still
## beats an Elite with Giap Sat + Hoi Ngat in a finite number of turns (Plating wears from turn 7, Mend has a fight cap).

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "aqua1", "plant1", "aqua1", "plant1"]
## Design 6.7 asks <= 14 turns for a dmg-only bot. Before lane E this pinned 40 (measured 27-33, then 41+ with the
## elite's companions alive); now the elite must die within 14 (measured 8-12 with plating decay_turn 3,
## shield_decay_pct 100, mend fight cap 25%). The party is topped up each turn (real HP wipes a tier-1 team in 1-5
## turns at pw 8), the companions stay and fight, the bot only presses dmg faces at the elite.
const MAX_TURNS := 14


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	_check(not CombatTraits.team_can_break(_roster()), "the test team really cannot break")
	for sd in [1, 2, 3, 4, 5]:
		_expect(sd, "iron", "mend")
	_expect(6, "iron", "")
	_mend_cap()
	print("=== t_anti_stall: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("t_anti_stall: FAIL - %s" % f)
	if _failures.is_empty():
		print("t_anti_stall: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


func _roster() -> Array:
	var r: Array = []
	for i in TEAM.size():
		r.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return r


## Bot: only dmg faces, always at the elite, real party HP, the elite's companions stay and fight like a real
## battle. Returns the turn the elite died (0 = it did not within the guard).
func _run(sd: int, a: String, b: String) -> int:
	var c := CombatEngine.new()
	c.setup_new({"node_id": "as", "kind": "elite", "pw": 8, "ascension": 0, "roster_snapshot": _roster(),
		"relic_ids": [], "combat_seed": sd, "affix": a, "affix2": b})
	var e: Unit = c.enemies[0]
	var elite_dead_turn := 0
	var guard := 0
	while not c.won and not c.lost and guard < 40:
		guard += 1
		for p in c.party:   # real HP wipes a tier-1 team in 1-5 turns at pw 8 (measured), so top up: this isolates the stall
			(p as Unit).max_hp = 999
			(p as Unit).hp = 999
		for p in c.party:
			var u: Unit = p
			if u.hp > 0 and not u.roll_used() and not u.frozen and e.hp > 0:
				var f: Dictionary = u.die[u.roll_face_index()]
				if String(f.get("type", "")) == "dmg":
					c.use_die(u.uid, e.uid)
		if e.hp <= 0 and elite_dead_turn == 0:
			elite_dead_turn = c.turn
		if c.won:
			break
		c.end_turn(100 + guard)
	if OS.has_environment("AXIE_DBG"): print("DBG seed %d %s+%s: elite dead turn %d, won %s lost %s, turn %d, party alive %d" % [sd, a, b, elite_dead_turn, c.won, c.lost, c.turn, c.alive_party().size()])
	return elite_dead_turn


func _expect(sd: int, a: String, b: String) -> void:
	var t := _run(sd, a, b)
	_check(t > 0 and t <= MAX_TURNS, "seed %d %s+%s: the elite dies within %d turns (turn %d, 0 = never)" % [sd, a, b, MAX_TURNS, t])


func _mend_cap() -> void:
	var c := CombatEngine.new()
	c.setup_new({"node_id": "as", "kind": "elite", "pw": 8, "ascension": 0, "roster_snapshot": _roster(),
		"relic_ids": [], "combat_seed": 9, "affix": "mend"})
	var e: Unit = c.enemies[0]
	e.max_hp = 40
	var cap := int(floor(40.0 * CombatTraits.knob("mend", "fight_cap_pct", 0.5)))
	var total := 0
	for _i in 30:
		e.hp = 1
		var before := e.hp
		CombatTraits.enemy_phase_start(c)
		total += e.hp - before
	_check(total <= cap and total == cap, "mend over 30 turns heals exactly the fight cap (%d of %d)" % [total, cap])


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)
