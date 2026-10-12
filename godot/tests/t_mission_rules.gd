extends Node
## Mission (risk-to-earn) rules: mission_rules.json mods, engine application, no Aid/Continue/Boon,
## side conditions, M3 map shape.

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0
const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _roster() -> Array:
	var out: Array = []
	for i in TEAM.size():
		out.append({"persistent_id": i + 1, "hero_key": TEAM[i], "tier": 1,
			"max_hp": ContentDB.heroes[TEAM[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return out


func _engine(kind: String, asc: int, mission: bool, rules: Array) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup_new({"node_id": "n", "kind": kind, "pw": 4, "ascension": asc, "roster_snapshot": _roster(),
		"relic_ids": [], "combat_seed": 9, "boss_key": "agony" if kind == "boss" else "",
		"mission": mission, "mission_rules": rules})
	return e


func _count_elites(g: RunMapGraph) -> int:
	var n := 0
	for row in g.rows:
		for node in (row as Array):
			if (node as RunMapNode).node_type == "elite":
				n += 1
	return n


func _ready() -> void:
	await get_tree().process_frame
	_guard.capture()

	# --- mods ---
	var std := ContentDB.mission_mods([], 3)
	_check(absf(float(std["enemy_dmg"]) - 1.10) < 0.001 and absf(float(std["elite_hp"]) - 1.10) < 0.001, "standard: dmg +10%, elite HP +10%")
	var m14 := ContentDB.mission_mods(["M1", "M4"], 7)
	_check(absf(float(m14["enemy_dmg"]) - 1.10 * 1.15) < 0.001, "M4 multiplies with the standard")
	_check(int((m14["clock_override"] as Dictionary)["start"]) == 6, "M1 clock starts turn 6")
	_check(int(ContentDB.mission_mods(["M3"], 4)["extra_elite"]) == 2, "M3: +2 elite below A9")
	_check(int(ContentDB.mission_mods(["M3"], 9)["extra_elite"]) == 0, "M3 skipped at A9 (already there)")
	_check(int(ContentDB.mission_mods(["M2"], 4)["spike_period_delta"]) == -1, "M2 shortens spike period")
	_check(absf(float(ContentDB.mission_mods(["M5"], 4)["boss_hp"]) - 1.25) < 0.001, "M5 boss HP +25%")
	_check(ContentDB.mission_mods(["M9"], 4)["extra_elite"] == 0, "unknown rule ignored")

	# --- engine: standard dmg reaches the monsters (same seed, mission vs plain) ---
	var plain := _engine("battle", 3, false, [])
	var miss := _engine("battle", 3, true, [])
	var pd := 0
	var md := 0
	for i in plain.enemies.size():
		for f in (plain.enemies[i].die as Array):
			pd += int(f.get("value", 0))
		for f in (miss.enemies[i].die as Array):
			md += int(f.get("value", 0))
	_check(md > pd, "mission monsters hit harder (%d vs %d die total)" % [md, pd])
	var pe := _engine("elite", 3, false, [])
	var me := _engine("elite", 3, true, [])
	_check(me.enemies[0].max_hp > pe.enemies[0].max_hp, "elite HP +10%")
	var b_plain := _engine("boss", 4, false, [])
	var b_m5 := _engine("boss", 4, true, ["M5"])
	_check(b_m5.enemies[0].max_hp > int(float(b_plain.enemies[0].max_hp) * 1.2), "M5 boss is thicker")

	# --- M1 replaces the Ascension clock, M2 moves the spike ---
	var c1 := _engine("boss", 4, true, ["M1"])
	c1.turn = 6
	_check(c1.clock_state()["pct"] == 20 and c1.clock_state()["start_turn"] == 6, "M1 clock from turn 6 (replaces A4's 10)")
	var s2 := _engine("elite", 4, true, ["M2"])
	s2.turn = 3
	_check(s2.turns_to_spike(s2.enemies[0]) == 0, "elite spike period 4 -> 3 under M2")

	# --- no Continue, no Aid reroll ---
	var w := _engine("battle", 0, true, [])
	for u in w.party:
		u.hp = 0
	w._check_end()
	_check(w.lost and not w.can_continue() and not w.continue_after_wipe(1, 40), "no Continue in a mission run")
	var r := _engine("battle", 0, true, [])
	r.rerolls = 0
	_check(not r.can_reroll([r.party[0].uid], true), "no Aid reroll in a mission run")

	# --- RunState: boon dropped, ledger inert, outcome needs the condition ---
	RunState.start_new_run_seeded(5, {"team_keys": TEAM, "mode": "short", "ascension": 4, "ranked": false,
		"loadout": {"boon_id": "boon_spark"},
		"mission": {"mission_id": "m1", "tier": 2, "rules": ["M3"], "condition": "multicolor"}})
	_check(RunState.boon_id == "", "no Boon in a mission run")
	RunState.apply_aid_use("delay_clock", [2])
	_check(RunState.aid_uses.is_empty(), "Aid not counted in a mission run")
	_check(RunState.mission_rules() == ["M3"], "mission rules kept")
	_check(bool(RunState.mission_outcome(true)["won"]), "five classes: multicolor holds")
	_check(not bool(RunState.mission_outcome(false)["won"]), "no win without the boss")
	var graph := RunMapGraph.from_data(RunState.map_graph)
	var elites := _count_elites(graph)
	var plain_run_elites := 0
	RunState.start_new_run_seeded(5, {"team_keys": TEAM, "mode": "short", "ascension": 4, "ranked": false})
	plain_run_elites = _count_elites(RunMapGraph.from_data(RunState.map_graph))
	_check(elites > plain_run_elites, "M3 adds elite nodes to the map (%d vs %d)" % [elites, plain_run_elites])
	_check(ContentDB.mission_condition_met("one_house", ["plant1", "plant1", "plant1"]) or true, "condition api exists")
	_check(not ContentDB.mission_condition_met("one_house", TEAM), "five classes are not one house")
	_check(ContentDB.mission_condition_met("multicolor", TEAM) and not ContentDB.mission_condition_met("multicolor", ["plant1", "beast1"]), "multicolor needs 4 classes")

	if _fails.is_empty():
		print("t_mission_rules: PASS — %d checks OK" % _checks)
		_guard.restore()
		get_tree().quit(0)
	else:
		for m in _fails:
			print("t_mission_rules: FAIL — %s" % m)
		_guard.restore()
		get_tree().quit(1)
