extends Node
## Depth v3 6.7b team_can_break (pure) + A.13 guarantee_tank.

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	var pure := _roster(["plant1", "aqua1", "plant1", "aqua1", "plant1"])
	_check(not CombatTraits.team_can_break(pure), "Aqua/Plant-only team cannot break")
	# aqua2 has an aoe dmg face, so use tier-1 only for the negative case.
	var neg := _roster(["plant1", "aqua1", "plant1", "aqua1", "beast1"])
	_check(not CombatTraits.team_can_break(neg), "plant/aqua/beast tier 1 (no keyword): false")
	for k in ["bug1", "bird1", "reptile1", "bug2", "reptile3"]:
		_check(CombatTraits.team_can_break(_roster(["plant1", "aqua1", "plant1", "aqua1", k])), "one %s makes it true" % k)
	_check(CombatTraits.team_can_break([[{"type": "dmg", "value": 3, "keywords": ["stun"]}]]), "stun keyword")
	_check(CombatTraits.team_can_break([[{"type": "dmg", "value": 3, "keywords": ["poison:2"]}]]), "poison:N keyword")
	_check(not CombatTraits.team_can_break([[{"type": "dmg", "value": 3, "keywords": ["cleave"]}]]), "cleave alone is not enough")
	_check(not CombatTraits.team_can_break([]), "empty team")
	var before := str(pure)
	CombatTraits.team_can_break(pure)
	_check(str(pure) == before, "does not touch its input")
	# guarantee_tank
	var avail := ["warden", "jellyfin", "spikelet", "slime"]
	var out := CombatTraits.guarantee_tank(["warden", "jellyfin", "slime"], avail)
	_check(out.size() == 3 and out[0] == "spikelet", "swaps the last for the cheapest tank and moves it to slot 0: %s" % str(out))
	var keep := CombatTraits.guarantee_tank(["warden", "slime", "thornback"], ["warden", "thornback", "spikelet", "slime"])
	_check(keep[0] == "thornback" and keep.size() == 3 and keep.count("warden") == 1, "existing tank is moved to slot 0: %s" % str(keep))
	_check(CombatTraits.guarantee_tank(["slime"], ["slime"]) == ["slime"], "no tank available: unchanged")
	# in a real fight: the early cap (1 trait) keeps the tank
	var c := CombatEngine.new()
	c.setup_new({"node_id": "g", "kind": "battle", "pw": 8, "ascension": 0, "roster_snapshot": _roster(["plant1", "aqua1"]),
		"relic_ids": [], "combat_seed": 3, "before_first_elite": true, "guarantee_tank": true})
	var tanks := 0
	for e in c.enemies:
		if (e as Unit).plating > 0:
			tanks += 1
	_check(tanks == 1, "fight has exactly one plating tank (got %d)" % tanks)
	print("=== t_team_can_break: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f in _failures:
		print("t_team_can_break: FAIL - %s" % f)
	if _failures.is_empty():
		print("t_team_can_break: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


func _roster(keys: Array) -> Array:
	var r: Array = []
	for i in keys.size():
		r.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return r


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)
