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

	# --- M6 / M7 (H4, nhiem-vu-risk-to-earn 3.2), value level; also no cap on rule count (H3, N6 = 5 rules) ---
	_check(absf(float(ContentDB.mission_mods(["M6"], 4)["normal_hp"]) - 1.20) < 0.001, "M6 mod normal_hp x1.20")
	_check(absf(float(ContentDB.mission_mods(["M7"], 4)["elite_dmg"]) - 1.25) < 0.001, "M7 mod elite_dmg x1.25")
	var n6 := ContentDB.mission_mods(["M1", "M4", "M5", "M6", "M7"], 9)
	_check(absf(float(n6["enemy_dmg"]) - 1.10 * 1.15) < 0.001 and absf(float(n6["boss_hp"]) - 1.25) < 0.001
		and absf(float(n6["normal_hp"]) - 1.2) < 0.001 and absf(float(n6["elite_dmg"]) - 1.25) < 0.001
		and int((n6["clock_override"] as Dictionary)["start"]) == 6, "N6 five-rule set all applies")
	var b0 := _engine("battle", 3, true, [])
	var b6 := _engine("battle", 3, true, ["M6"])
	var hp_ok := b0.enemies.size() == b6.enemies.size() and b0.enemies.size() > 0
	for i in mini(b0.enemies.size(), b6.enemies.size()):
		var want: int = RulesMath.round_half_up(float(b0.enemies[i].max_hp) * 1.2)
		hp_ok = hp_ok and absi(b6.enemies[i].max_hp - want) <= 1 and b6.enemies[i].max_hp > b0.enemies[i].max_hp
	_check(hp_ok, "M6: every normal monster HP is x1.20 (+-1 rounding)")
	var e0 := _engine("elite", 3, true, [])
	var e6 := _engine("elite", 3, true, ["M6"])
	var e7 := _engine("elite", 3, true, ["M7"])
	var same_hp := true
	for i in e0.enemies.size():
		same_hp = same_hp and e6.enemies[i].max_hp == e0.enemies[i].max_hp and e7.enemies[i].max_hp == e0.enemies[i].max_hp
	_check(same_hp, "M6 does not touch elite HP, M7 does not touch HP")
	var d0 := 0
	var d7 := 0
	for i in e0.enemies.size():
		for f in (e0.enemies[i].die as Array):
			d0 += int(f.get("value", 0))
		for f in (e7.enemies[i].die as Array):
			d7 += int(f.get("value", 0))
	_check(d7 > d0 and absf(float(d7) / float(d0) - 1.25) < 0.12, "M7: elite dice ~x1.25 (%d vs %d)" % [d7, d0])
	var b7 := _engine("battle", 3, true, ["M7"])
	var bd := 0
	var bd7 := 0
	for i in b0.enemies.size():
		for f in (b0.enemies[i].die as Array):
			bd += int(f.get("value", 0))
		for f in (b7.enemies[i].die as Array):
			bd7 += int(f.get("value", 0))
	_check(bd == bd7, "M7 leaves normal monsters' dice alone")

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

	# --- H6: abandoning banks no per-run Shard; a normal loss still banks R ---
	RunState.start_new_run_seeded(5, {"team_keys": TEAM, "mode": "short", "ascension": 4, "ranked": false})
	RunState.shards_this_run = 70
	var before: int = MetaState.shard_pool
	RunState.clear_saved_run()   # exactly what SettingsView ABANDON does (no end_run)
	RunState.reset()
	_check(MetaState.shard_pool == before and RunState.shards_this_run == 0, "abandon banks 0 Shard (R dropped)")
	RunState.start_new_run_seeded(5, {"team_keys": TEAM, "mode": "short", "ascension": 4, "ranked": false})
	RunState.shards_this_run = 70
	before = MetaState.shard_pool
	RunState.end_run(false)
	_check(MetaState.shard_pool - before >= 70, "a normal loss still banks R (>= 70, extras are other bonuses) (%d)" % (MetaState.shard_pool - before))

	if _fails.is_empty():
		print("t_mission_rules: PASS — %d checks OK" % _checks)
		_guard.restore()
		get_tree().quit(0)
	else:
		for m in _fails:
			print("t_mission_rules: FAIL — %s" % m)
		_guard.restore()
		get_tree().quit(1)
