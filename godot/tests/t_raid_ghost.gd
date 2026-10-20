extends Node
## Raid R1 (lane RV): a defence snapshot becomes valid AI enemies, the engine plays a full fight against them,
## and the same snapshot + seed is deterministic. No network.

var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fails.append(msg)


func _roster(keys: Array) -> Array:
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1, "max_hp": 0, "muts": [], "growth": {}, "bonus_hp": 0})
	return out


func _fight(team: Array, seed_value: int) -> CombatEngine:
	var c := CombatEngine.new()
	c.setup_new({"node_id": "raid", "kind": "battle", "pw": 0, "ascension": 0, "roster_snapshot": _roster(["plant1", "beast1", "aqua1"]),
		"relic_ids": [], "combat_seed": seed_value, "ghost_team": team})
	return c


func _ready() -> void:
	print("=== t_raid_ghost: start ===")
	var team := RaidGhost.snapshot_team(["plant1", "beast1", "aqua1", "reptile1", "bug1", "", "nope_key"])
	_ok(team.size() == 5, "5 known keys -> 5 units (empty + unknown dropped), got %d" % team.size())
	_ok(RaidGhost.is_valid_team(team), "snapshot passes its own validator")
	for u in team:
		_ok((u["die"] as Array).size() == 6 and int(u["hp"]) >= 1, "unit %s has 6 faces and hp" % u["key"])
		_ok(RaidGhost.CLASSES.has(u["cls"]), "class known")
	_ok(RaidGhost.snapshot_team([]).is_empty() and RaidGhost.snapshot_team(["x"]).is_empty(), "nothing usable -> empty")
	var six := RaidGhost.snapshot_team(["plant1", "plant1", "plant1", "plant1", "plant1", "plant1"])
	_ok(six.size() == 5, "capped at 5 units")
	_ok(RaidGhost.power_hint(team) > 0 and RaidGhost.power_hint(team) <= 9999, "power hint in range")
	# validator refuses bad shapes (a bad server row must not crash a fight)
	_ok(not RaidGhost.is_valid_team([]) and not RaidGhost.is_valid_team("x") and not RaidGhost.is_valid_team([{"cls": "dragon"}]), "bad teams refused")
	var short: Array = [team[0].duplicate(true)]
	(short[0]["die"] as Array).pop_back()
	_ok(not RaidGhost.is_valid_team(short), "5-face die refused")
	var odd: Array = [team[0].duplicate(true)]
	odd[0]["die"][0]["type"] = "explode"
	_ok(not RaidGhost.is_valid_team(odd), "unknown face type refused")
	_ok(RaidGhost.make_enemy(odd[0], 1).die[0]["type"] == "blank", "unknown face type becomes blank on an enemy")
	# snapshot is JSON-safe and keeps the Worker contract (key regex, kw regex, value range)
	var j: Variant = JSON.parse_string(JSON.stringify(team))
	_ok(j is Array and (j as Array).size() == team.size(), "JSON round trip")
	var key_re := RegEx.create_from_string("^[a-z0-9_]{1,32}$")
	for u in team:
		_ok(key_re.search(String(u["key"])) != null, "key matches the Worker regex")
		for f in u["die"]:
			_ok(int(f["value"]) >= 0 and int(f["value"]) <= 99 and String(f["type"]).length() > 0, "face in range")

	# enemies
	var c := _fight(team, 4242)
	_ok(c.enemies.size() == 5, "engine built 5 ghost enemies, got %d" % c.enemies.size())
	var uids := {}
	for e in c.enemies:
		uids[e.uid] = true
		_ok(e.side == "e" and e.hp == e.max_hp and e.hp > 0 and e.die.size() == 6, "enemy shape")
		_ok(e.role != "" and e.has_rolled() and not e.intent.is_empty(), "enemy rolled an intent via the normal AI")
		_ok(String(e.custom_state.get("ghost_key", "")) != "", "ghost key kept")
	_ok(uids.size() == 5, "unique uids")
	_ok(c.party.size() == 3, "attacker party untouched")
	# a normal fight (no ghost) still generates its own encounter
	var plain := CombatEngine.new()
	plain.setup_new({"node_id": "p", "kind": "battle", "pw": 0, "ascension": 0, "roster_snapshot": _roster(["plant1"]), "relic_ids": [], "combat_seed": 1})
	_ok(plain.enemies.size() >= 1 and not plain.enemies[0].custom_state.has("ghost_key"), "no ghost_team -> normal encounter")

	# play: end turns until someone wins; must terminate and be deterministic
	var a := _play(team, 99)
	var b := _play(team, 99)
	_ok(a["done"], "fight reaches an end")
	_ok(a["sig"] == b["sig"], "same snapshot + seed = same fight")
	# save/restore keeps ghost enemies
	var r := CombatEngine.new()
	r.from_data(_fight(team, 5).to_data())
	_ok(r.enemies.size() == 5 and r.enemies[0].die.size() == 6, "to_data/from_data keeps ghost enemies")

	if _fails.is_empty():
		print("t_raid_ghost: PASS (%d checks)" % _checks)
	else:
		print("t_raid_ghost: FAIL")
		for f in _fails:
			print("  FAIL: ", f)
	get_tree().quit(0 if _fails.is_empty() else 1)


func _play(team: Array, seed_value: int) -> Dictionary:
	var c := _fight(team, seed_value)
	var guard := 0
	while not (c.won or c.lost) and guard < 80:
		guard += 1
		for u in c.party:
			if u.hp > 0 and u.has_rolled() and not u.roll_used():
				var tgt := -1
				var f: Dictionary = u.current_face()
				if String(f.get("type", "")) in ["dmg", "poison", "debuff"]:
					var es := c.alive_enemies()
					if es.size() > 0:
						tgt = es[0].uid
				else:
					tgt = u.uid
				c.use_die(u.uid, tgt)
		c.end_turn(guard)
	var sig := "%s|%d|%d" % [c.won, c.turn, c.alive_party().size()]
	return {"done": c.won or c.lost, "sig": sig}
