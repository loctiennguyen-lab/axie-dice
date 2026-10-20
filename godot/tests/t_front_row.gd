extends Node
## Depth v3 rows (design 4): single-target enemy attacks pick the front row (roster 0-1) while one lives;
## AoE/pierce ignore rows; the Assassin keeps hunting the weakest of the whole party; Eggs stand in the back.

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	_run()
	print("=== t_front_row: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("t_front_row: FAIL - %s" % f)
	if _failures.is_empty():
		print("t_front_row: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


func _engine() -> CombatEngine:
	var roster: Array = []
	for i in TEAM.size():
		roster.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var e := CombatEngine.new()
	e.setup_new({"node_id": "row_node", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": roster, "relic_ids": [], "combat_seed": 31337})
	return e


## Rigs enemy 0 with a one-face die and returns the uids it targets over `n` rolls of the intent.
func _targets(e: CombatEngine, role: String, kws: Array, n: int = 60) -> Dictionary:
	var en: Unit = e.enemies[0]
	en.role = role
	en.die = [{"type": "dmg", "value": 3, "keywords": kws, "name": "t", "part": "mouth"}]
	en.set_roll(0, false)
	var seen := {}
	for i in n:
		e._pick_enemy_intent(en)
		seen[int(en.intent["target_uid"])] = true
	return seen


func _run() -> void:
	var e := _engine()
	_check(e.row_of(e.party[0]) == 0 and e.row_of(e.party[1]) == 0, "roster 0,1 are the front row")
	_check(e.row_of(e.party[2]) == 1 and e.row_of(e.party[4]) == 1, "roster 2..4 are the back row")
	var front := [e.party[0].uid, e.party[1].uid]
	var seen := _targets(e, "bruiser", [])
	for uid in seen:
		_check(front.has(uid), "single-target hit a back-row Axie while the front lives (uid %d)" % uid)
	seen = _targets(e, "", [])
	_check(seen.size() == 2, "both front Axies should be reachable, got %d" % seen.size())
	seen = _targets(e, "", ["aoe"], 200)
	_check(seen.size() > 2, "AoE intent should not be row-limited")
	seen = _targets(e, "", ["pierce"], 200)
	_check(seen.size() > 2, "pierce intent should not be row-limited")
	# Assassin: weakest of the whole party, even in the back row.
	e.party[4].hp = 1
	e.party[4].shield = 0
	seen = _targets(e, "assassin", [])
	_check(seen.size() == 1 and seen.has(e.party[4].uid), "assassin must keep targeting the weakest overall")
	e.party[4].hp = e.party[4].max_hp
	# Eggs are back row.
	var egg: Unit = e._mk_ally()
	e.party.append(egg)
	_check(egg.roster_index == -1 and e.row_of(egg) == 1, "an Egg stands in the back row")
	seen = _targets(e, "", [])
	_check(not seen.has(egg.uid), "an Egg was targeted while the front row lives")
	# Front row down: the back row becomes reachable.
	e.party[0].hp = 0
	e.party[1].hp = 0
	seen = _targets(e, "", [], 200)
	_check(seen.size() >= 3 and not front.any(func(u): return seen.has(u)), "with the front row down the back must be targetable")


func _check(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_failures.append(m)
