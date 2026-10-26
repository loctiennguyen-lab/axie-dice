extends Node
## AT step 2: how many monster types a normal fight can draw at each pw, by the real rule
## (combat_engine.gd _available_normal_keys: min <= pw+1, cost DESC, ties by pool index, draw from ceil(0.7*n)).
## Before the 6 new Atia monsters: 3 / 3 / 5 / 12 at pw 0 / 1 / 2 / 10. Now 5 / 5 / 7 / 15.
## Run: godot --headless --path godot res://tests/t_pool_diversity.tscn

const NEW_NORMAL := ["anemone", "shiitake", "slimes_04", "pangolord"]
const NEW_ELITE := ["e_golem", "e_seahorse"]
const FLOOR := {0: 5, 1: 5, 2: 7, 10: 15}

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	var c := CombatEngine.new()
	var seen := {}
	for pw in FLOOR.keys():
		var avail: Array = c._available_normal_keys(pw)
		var n := int(ceil(avail.size() * 0.7))
		_assert(n >= int(FLOOR[pw]), "pw %d: %d drawable types, need >= %d" % [pw, n, FLOOR[pw]])
		for k in avail.slice(0, n):
			seen[k] = true
	for k in NEW_NORMAL:
		_assert(seen.has(k), "new monster '%s' is never drawable at pw 0/1/2/10" % k)
	for k in NEW_NORMAL + NEW_ELITE:
		_assert(ContentDB.enemies.has(k), "'%s' missing from ContentDB.enemies" % k)
	for k in NEW_ELITE:
		_assert(ContentDB.elite_pool.has(k), "'%s' not in elite_pool" % k)
	_assert(ContentDB.elite_pool.size() == 6, "elite_pool should have 6 keys")
	# real draws: the new normals show up in actual encounters
	var hit := {}
	for s in range(1, 60):
		for pw in [0, 2, 10]:
			var e := CombatEngine.new()
			e.setup_new({"node_id": "t_pool", "kind": "battle", "pw": pw, "ascension": 0,
				"roster_snapshot": [{"persistent_id": 1, "hero_key": "plant1", "tier": 1,
					"max_hp": ContentDB.heroes["plant1"]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0}],
				"relic_ids": [], "combat_seed": s, "bonus_reroll": 0, "boss_key": ""})
			for u in e.enemies:
				hit[String((u as Unit).key)] = true
	for k in ["anemone", "shiitake", "slimes_04"]:
		_assert(hit.has(k), "'%s' never drawn in 180 real encounters" % k)
	_assert(hit.has("pangolord"), "'pangolord' never drawn in 180 real encounters")
	var elite_hit := {}
	for s in range(1, 80):
		var e := CombatEngine.new()
		e.setup_new({"node_id": "t_pool", "kind": "elite", "pw": 9, "ascension": 0,
			"roster_snapshot": [{"persistent_id": 1, "hero_key": "plant1", "tier": 1,
				"max_hp": ContentDB.heroes["plant1"]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0}],
			"relic_ids": [], "combat_seed": s, "bonus_reroll": 0, "boss_key": ""})
		for u in e.enemies:
			elite_hit[String((u as Unit).key)] = true
	for k in NEW_ELITE:
		_assert(elite_hit.has(k), "'%s' never drawn in 79 elite encounters" % k)
	print("t_pool_diversity: %d checks, %d failure(s)" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_pool_diversity: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_pool_diversity: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)
