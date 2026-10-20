extends Node
## Depth v3 8.6/A.14: CombatEngine.preview_damage is pure ("4 -> 1") and agrees with the real hit.

var _guard := SaveGuard.new()
var _failures: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "bird1", "bug1"]


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	var r: Array = []
	for i in TEAM.size():
		r.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	var c := CombatEngine.new()
	c.setup_new({"node_id": "pv", "kind": "battle", "pw": 8, "ascension": 0, "roster_snapshot": r, "relic_ids": [], "combat_seed": 5})
	var e: Unit = c.enemies[0]
	e.max_hp = 500
	for u in c.party:
		var fi := 0
		for i in u.die.size():
			if String(u.die[i].get("type", "")) == "dmg":
				fi = i
				break
		if String(u.die[fi].get("type", "")) != "dmg":
			continue
		for setup in ["plain", "plated", "vuln", "plated+vuln"]:
			e.hp = 500
			e.shield = 0
			e.status.clear()
			e.plating = 3 if setup.begins_with("plated") else 0
			e.plating_off = 0
			if setup.ends_with("vuln"):
				e.status["vulnerable"] = 2
			var snap := str(c.to_data())
			var p := c.preview_damage(u, e, fi)
			_check(str(c.to_data()) == snap, "%s %s: preview changes no state" % [u.key, setup])
			var f: Dictionary = u.die[fi]
			var single := not CombatEngine._has_kw(f, "aoe") and not CombatEngine._has_kw(f, "pierce")
			var real := DamagePipeline.resolve({"combat": c, "src": u, "tgt": e, "value": int(p["raw"]), "attack": true,
				"single": single, "face_type": "dmg", "pierce": CombatEngine._has_kw(f, "pierce")})
			_check(int(p["after"]) == real, "%s %s: preview %d == real %d" % [u.key, setup, int(p["after"]), real])
			if setup == "plated" and single and int(p["raw"]) > 1:
				_check(int(p["plating"]) == 3 and int(p["after"]) == maxi(1, int(p["raw"]) - 3), "%s plated: raw %d -> %d" % [u.key, int(p["raw"]), int(p["after"])])
	var rng_state := c._rng.get_state()
	c.preview_damage(c.party[0], e, 0)
	_check(c._rng.get_state() == rng_state, "no rng drawn")
	print("=== t_preview_damage: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f2 in _failures:
		print("t_preview_damage: FAIL - %s" % f2)
	if _failures.is_empty():
		print("t_preview_damage: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)
