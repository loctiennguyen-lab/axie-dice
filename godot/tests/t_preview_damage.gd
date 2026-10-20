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
	_vs_real_use_die()
	print("=== t_preview_damage: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	for f2 in _failures:
		print("t_preview_damage: FAIL - %s" % f2)
	if _failures.is_empty():
		print("t_preview_damage: PASS - %d checks OK" % _checks)
	_guard.restore()
	get_tree().quit(0 if _failures.is_empty() else 1)


var _events := 0


## The preview must equal what the REAL path (use_die -> _do_face) takes off a full-HP target, including the
## first-damage-face bonus and Core flat bonuses, and the preview itself must emit no EventBus signal at all.
func _vs_real_use_die() -> void:
	var variants := [{}, {"first_dmg_face_bonus": 2}, {"relic_ids": ["c_kindle"]}, {"first_dmg_face_bonus": 3, "relic_ids": ["c_kindle"]}]
	for sig in EventBus.get_signal_list():
		EventBus.connect(String(sig["name"]), func(..._a): _events += 1)
	var compared := 0
	for v in variants:
		for ui in TEAM.size():
			var r: Array = []
			for i in TEAM.size():
				r.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
					"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
			var setup := {"node_id": "pv", "kind": "battle", "pw": 8, "ascension": 0, "roster_snapshot": r, "relic_ids": [], "combat_seed": 5}
			setup.merge(v, true)
			var c := CombatEngine.new()
			c.setup_new(setup)
			var u: Unit = c.party[ui]
			for fi in u.die.size():
				var f: Dictionary = u.die[fi]
				if String(f.get("type", "")) != "dmg" or CombatEngine._has_kw(f, "aoe") or CombatEngine._has_kw(f, "crit") \
						or CombatEngine._has_kw(f, "execute"):
					continue
				var cc := CombatEngine.new()
				cc.from_data(c.to_data())
				var e: Unit = cc.enemies[0]
				e.max_hp = 500
				e.hp = 500
				e.shield = 0
				e.status.clear()
				var u2: Unit = cc.party[ui]
				u2.set_roll(fi, false)
				var snap := str(cc.to_data())
				_events = 0
				var pv := cc.preview_damage(u2, e, fi)
				_check(_events == 0, "%s face %d: preview emitted %d event(s)" % [u.key, fi, _events])
				_check(str(cc.to_data()) == snap, "%s face %d %s: preview changed state" % [u.key, fi, str(v.keys())])
				var before := e.hp
				cc.use_die(u2.uid, e.uid)
				_check(before - e.hp == int(pv["after"]), "%s face %d %s: preview %d == use_die %d" % [u.key, fi, str(v.keys()), int(pv["after"]), before - e.hp])
				compared += 1
	_check(compared >= 20, "enough faces compared against the real path (%d)" % compared)


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(msg)
