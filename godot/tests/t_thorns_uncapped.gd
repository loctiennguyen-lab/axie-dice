extends Node
## Depth v3 (Liam 21/10): thorns have no cap for either side (combat_tune thorns.cap = 0), never decay,
## and reflect exactly the stacked amount. The Core +10/face cap must not touch thorns.

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	_party_side()
	_enemy_side()
	_deterministic()
	_knob()
	print("=== t_thorns_uncapped: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("t_thorns_uncapped: FAIL - %s" % f)
	if _failures.is_empty():
		print("t_thorns_uncapped: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


func _engine() -> CombatEngine:
	var roster: Array = []
	for i in TEAM.size():
		roster.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var c := CombatEngine.new()
	c.setup_new({"node_id": "th", "kind": "battle", "pw": 5, "ascension": 0, "roster_snapshot": roster,
		"relic_ids": [], "combat_seed": 7, "boss_key": ""})
	return c


func _hit(c: CombatEngine, src: Unit, tgt: Unit, v: int) -> void:
	DamagePipeline.resolve({"combat": c, "src": src, "tgt": tgt, "value": v, "attack": true, "single": true, "face_type": "dmg"})


func _party_side() -> void:
	var c := _engine()
	var a: Unit = c.party[0]
	var e: Unit = c.enemies[0]
	e.max_hp = 500
	e.hp = 500
	e.plating = 0
	e.shield = 0
	a.max_hp = 500
	a.hp = 500
	StatusEngine.add_status(c, a, ["thorns:5"])
	StatusEngine.add_status(c, a, ["thorns:6"])
	_check(int(a.status["thorns"]) == 11, "Axie stacks past 8, got %d" % int(a.status["thorns"]))
	_hit(c, e, a, 3)
	_check(e.hp == 500 - 11, "enemy takes exactly 11 back, lost %d" % (500 - e.hp))
	StatusEngine.tick_status(c)
	_check(int(a.status["thorns"]) == 11, "thorns do not decay")


func _enemy_side() -> void:
	var c := _engine()
	var a: Unit = c.party[0]
	var e: Unit = c.enemies[0]
	a.max_hp = 500
	a.hp = 500
	a.shield = 0
	e.max_hp = 500
	e.hp = 500
	StatusEngine.add_status(c, e, ["thorns:7"])
	StatusEngine.add_status(c, e, ["thorns:7"])
	_check(int(e.status["thorns"]) == 14, "monster stacks past 8, got %d" % int(e.status["thorns"]))
	_hit(c, a, e, 2)
	_check(a.hp == 500 - 14, "Axie takes exactly 14 back, lost %d" % (500 - a.hp))


func _run_once() -> Array:
	var c := _engine()
	var a: Unit = c.party[0]
	var e: Unit = c.enemies[0]
	a.max_hp = 500
	a.hp = 500
	e.max_hp = 500
	e.hp = 500
	e.plating = 0
	for i in 4:
		StatusEngine.add_status(c, a, ["thorns:4"])
		_hit(c, e, a, 1)
	return [a.status["thorns"], e.hp, a.hp]


func _deterministic() -> void:
	var r1 := _run_once()
	var r2 := _run_once()
	_check(r1 == r2, "same inputs give the same result twice (%s vs %s)" % [str(r1), str(r2)])
	_check(int(r1[0]) == 16 and int(r1[1]) == 500 - (4 + 8 + 12 + 16), "16 thorns, reflected 4+8+12+16, got %s" % str(r1))


func _knob() -> void:
	_check(int(CombatEngine.tune_knob("thorns", "cap", -1.0)) == 0, "thorns.cap defaults to 0 (no cap)")
	_check(StatusEngine.clamp_thorns(99) == 99, "clamp_thorns passes 99 through when cap = 0")


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)
