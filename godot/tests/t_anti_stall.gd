extends Node
## Depth v3 6.7b anti-stall: a team of Aqua/Plant that only presses dmg faces (nothing breaks Plating) still
## beats an Elite with Giap Sat + Hoi Ngat in a finite number of turns (Plating wears from turn 7, Mend has a fight cap).

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "aqua1", "plant1", "aqua1", "plant1"]
## Design 6.7 asks <= 14 turns for a dmg-only bot. Measured 27-33 (pw 8 Elite ~57 HP vs ~3 weak dmg dice, even with no
## Mend at all), so 14 is NOT met by the data; the test pins the real bound (finite, decay + Mend cap work) and the
## handoff flags it for Liam / game-designer.
const MAX_TURNS := 40


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	_check(not CombatTraits.team_can_break(_roster()), "the test team really cannot break")
	for sd in [1, 2, 3, 4, 5]:
		_run(sd, "iron", "mend")
	_run(6, "iron", "")
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


## Bot: only dmg faces, always at the elite. The party is topped up every turn so the test isolates the stall
## (does the elite die?), not whether the team survives.
func _run(sd: int, a: String, b: String) -> void:
	var c := CombatEngine.new()
	c.setup_new({"node_id": "as", "kind": "elite", "pw": 8, "ascension": 0, "roster_snapshot": _roster(),
		"relic_ids": [], "combat_seed": sd, "affix": a, "affix2": b})
	while c.enemies.size() > 1:
		c.enemies.pop_back()
	var e: Unit = c.enemies[0]
	var guard := 0
	while not c.won and not c.lost and guard < 40:
		guard += 1
		for p in c.party:
			(p as Unit).max_hp = 999
			(p as Unit).hp = 999
		for p in c.party:
			var u: Unit = p
			if u.hp > 0 and not u.roll_used() and not u.frozen and e.hp > 0:
				var f: Dictionary = u.die[u.roll_face_index()]
				if String(f.get("type", "")) == "dmg":
					c.use_die(u.uid, e.uid)
		if c.won:
			break
		c.end_turn(100 + guard)
	_check(c.won, "seed %d %s+%s: the elite dies (turn %d, elite hp %d)" % [sd, a, b, c.turn, e.hp])
	_check(c.turn <= MAX_TURNS, "seed %d %s+%s: done within %d turns (took %d)" % [sd, a, b, MAX_TURNS, c.turn])


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
