extends Node
## Headless verification gate for the content-expansion pass (18 heroes, new enemy roles,
## 2 boss entries, 20 relics). Every assertion here drives the REAL production code paths
## (CombatEngine/DamagePipeline/StatusEngine/RelicHooks, unmodified this pass) rather than
## re-implementing the expected behaviour in the test — see project test-standards.md
## "every bug fix must have a regression test", generalized here to "every new content
## claim must have a test that actually exercises the engine, not just reads the data back".
##
## Implemented as a scene (t_content_expansion.tscn), same reasoning as every other
## autoload-dependent gate in this suite (t_combat_roundtrip.gd's header comment) — a bare
## `--script` SceneTree override can't resolve ContentDB/EventBus/RelicRegistry as globals.

var _failures: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_content_expansion: start ===")
	_check_heroes()
	_check_enemies()
	_check_boss_data()
	_check_boss_phase_transition()
	_check_relic_pure_data()
	_check_relic_hooks()
	_check_full_combat_with_all_relics()

	print("=== t_content_expansion: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_content_expansion: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _failures:
			print("t_content_expansion: FAIL — %s" % f)
		get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _synthetic_roster(keys: Array) -> Array:
	var out: Array = []
	for i in keys.size():
		out.append({
			"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0,
		})
	return out


## Fresh CombatEngine with a synthetic 5-hero roster and the given relic_ids, seeded
## deterministically. Same shape RunState would hand CombatEngine.setup_new() for a real fight.
func _new_combat(relic_ids: Array, combat_seed: int = 424242) -> CombatEngine:
	var c := CombatEngine.new()
	c.setup_new({
		"node_id": "t_content_expansion", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": _synthetic_roster(["plant1", "beast1", "aqua1", "reptile1", "bug1"]),
		"relic_ids": relic_ids, "combat_seed": combat_seed,
	})
	return c


# ===========================================================================
# 1. Heroes — 18 total (6 class x tier 1/2/3)
# ===========================================================================
func _check_heroes() -> void:
	_assert(ContentDB.heroes.size() == 18, "expected 18 heroes, got %d" % ContentDB.heroes.size())
	for cls in ["plant", "beast", "aqua", "reptile", "bug", "bird"]:
		var prev_hp := 0
		for tier in [1, 2, 3]:
			var key := "%s%d" % [cls, tier]
			var h: Dictionary = ContentDB.heroes.get(key, {})
			_assert(not h.is_empty(), "missing hero %s" % key)
			if h.is_empty():
				continue
			_assert(String(h.get("cls", "")) == cls, "%s: cls mismatch (%s)" % [key, h.get("cls")])
			_assert(int(h.get("tier", 0)) == tier, "%s: tier mismatch" % key)
			_assert((h.get("die", []) as Array).size() == 6, "%s: die must have 6 faces" % key)
			var hp := int(h.get("max_hp", 0))
			_assert(hp > prev_hp, "%s: max_hp %d should exceed tier %d's %d" % [key, hp, tier - 1, prev_hp])
			prev_hp = hp


# ===========================================================================
# 2. Enemies — new roles buildable through the real Unit-construction path
# ===========================================================================
func _check_enemies() -> void:
	var expect_roles := {
		"chomper": "bruiser", "ravenling": "assassin", "spikelet": "tank",
		"jellyfin": "healer", "bugling": "poisoner", "hexeye": "mage",
	}
	var combat := CombatEngine.new()   # no setup_new() needed — _mk_monster only reads ContentDB
	for key in expect_roles:
		var m: Dictionary = ContentDB.enemies.get(key, {})
		_assert(not m.is_empty(), "missing enemy %s" % key)
		if m.is_empty():
			continue
		_assert(String(m.get("role", "")) == expect_roles[key], "%s: role mismatch" % key)
		var u: Unit = combat._mk_monster(key, 1.0, {"hp": 1.0, "dmg": 1.0})
		_assert(u.hp > 0 and u.max_hp == u.hp, "%s: built unit has invalid hp %d/%d" % [key, u.hp, u.max_hp])
		_assert(u.die.size() == 6, "%s: built unit die must have 6 faces" % key)
		_assert(u.role == expect_roles[key], "%s: built unit role mismatch" % key)


# ===========================================================================
# 3. Boss data — ContentDB.boss_stats() pure formula (src/engine.js mkBoss port)
# ===========================================================================
func _check_boss_data() -> void:
	var mods := {"hp": 1.0, "dmg": 1.0, "boss_hp": 1.0}
	var agony := ContentDB.boss_stats("agony", 6, mods)
	_assert(not agony.is_empty(), "agony boss_stats() returned empty")
	_assert(String(agony.get("trait", "")) == "phase", "agony: trait should be 'phase'")
	_assert(int(agony.get("max_hp", 0)) > 0, "agony: max_hp must be positive")
	_assert((agony.get("die", []) as Array).size() == 6, "agony: die must have 6 faces")
	_assert(agony.has("max_hp2") and int(agony["max_hp2"]) > int(agony["max_hp"]),
		"agony: phase-2 max_hp should exceed phase-1 (hpk2=2.5 > hpk=2.0)")
	_assert((agony.get("die2", []) as Array).size() == 6, "agony: die2 must have 6 faces")

	var gooey := ContentDB.boss_stats("gooey_king", 6, mods)
	_assert(not gooey.is_empty(), "gooey_king boss_stats() returned empty")
	_assert(String(gooey.get("trait", "")) == "split", "gooey_king: trait should be 'split'")
	_assert(int(gooey.get("add_cap", 0)) == 2, "gooey_king: add_cap should be 2")
	_assert((gooey.get("adds", []) as Array) == ["slime"], "gooey_king: adds should be ['slime']")
	_assert(not gooey.has("max_hp2"), "gooey_king: should have no phase-2 data (die2 empty in content)")


# ===========================================================================
# 4. Boss phase transition — proves DamagePipeline.check_boss_phase() (already generic,
# unmodified) correctly drives a REAL "agony" boss built from ContentDB.boss_stats()
# through its phase-1 -> phase-2 transition, with zero combat_engine.gd/damage_pipeline.gd
# changes needed.
# ===========================================================================
func _check_boss_phase_transition() -> void:
	var combat := _new_combat([])
	var stats := ContentDB.boss_stats("agony", 6, {"hp": 1.0, "dmg": 1.0, "boss_hp": 1.0})

	var boss := Unit.new()
	boss.uid = combat._alloc_token_uid()
	boss.side = "e"
	boss.key = "agony"
	boss.n = String(stats["n"])
	boss.role = "boss"
	boss.is_boss = true
	boss.max_hp = int(stats["max_hp"])
	boss.hp = boss.max_hp
	boss.die = (stats["die"] as Array).duplicate(true)
	boss.custom_state = {
		"trait": "phase", "hp2": int(stats["max_hp2"]), "die2": (stats["die2"] as Array).duplicate(true),
	}
	combat.enemies = [boss]

	# NOTE: GDScript lambdas capture local variables BY VALUE, not by reference — an `int`
	# incremented inside the lambda would never be visible outside it. Use a 1-element Array
	# as a mutable box instead (Arrays are reference types in GDScript).
	var phase_signal_count := [0]
	var on_phase := func(_uid): phase_signal_count[0] += 1
	EventBus.boss_phase_changed.connect(on_phase)

	var dealt := DamagePipeline.resolve({"combat": combat, "src": null, "tgt": boss, "value": 999999, "pierce": true})

	EventBus.boss_phase_changed.disconnect(on_phase)

	_assert(dealt > 0, "phase transition: expected damage to be dealt")
	_assert(int(boss.custom_state.get("phase", 1)) == 2, "boss should be in phase 2 after lethal hit")
	_assert(boss.hp == int(stats["max_hp2"]), "boss hp should reset to phase-2 max_hp (%d), got %d" % [stats["max_hp2"], boss.hp])
	_assert(boss.max_hp == int(stats["max_hp2"]), "boss max_hp should switch to phase-2 value")
	_assert(boss.die == stats["die2"], "boss die should switch to die2")
	_assert(not boss._dead, "boss should no longer be marked dead after surviving via phase-2")
	_assert(phase_signal_count[0] == 1, "boss_phase_changed should fire exactly once, fired %d" % phase_signal_count[0])


# ===========================================================================
# 5. Relics — pure aggregate-data fields (no hook_key logic), read through the real
# RelicHooks.sum/has/max_val call sites.
# ===========================================================================
func _check_relic_pure_data() -> void:
	var c1 := _new_combat(["r_luckycharm"])
	_assert(RelicHooks.sum(c1, "critBonus") == 35.0, "r_luckycharm: critBonus should be 35.0")

	var c2 := _new_combat(["r_hollowbone"])
	_assert(RelicHooks.sum(c2, "piercePlus") == 3.0, "r_hollowbone: piercePlus should be 3.0")

	var c3 := _new_combat(["r_hivemind"])
	_assert(RelicHooks.has(c3, "hiveMind"), "r_hivemind: has(hiveMind) should be true")
	_assert(RelicHooks.sum(c3, "hiveMind") == 1.0, "r_hivemind: sum(hiveMind) should be 1.0")

	var c4 := _new_combat(["r_holyfont"])
	_assert(RelicHooks.has(c4, "healShield"), "r_holyfont: has(healShield) should be true")

	var c5 := _new_combat(["r_mirrorshell"])
	_assert(RelicHooks.max_val(c5, "thornsMult", 1.0) == 2.0, "r_mirrorshell: thornsMult should be 2.0")

	var c6 := _new_combat(["r_solarcore"])
	_assert(RelicHooks.max_val(c6, "burnMult", 1.0) == 2.0, "r_solarcore: burnMult should be 2.0")

	var c7 := _new_combat(["r_venomengine"])
	_assert(RelicHooks.max_val(c7, "poisonTicks", 1.0) == 2.0, "r_venomengine: poisonTicks should be 2.0")

	var c8 := _new_combat(["r_hearthcore"])
	_assert(RelicHooks.max_val(c8, "burnTicks", 1.0) == 2.0, "r_hearthcore: burnTicks should be 2.0")
	_assert(RelicHooks.max_val(c8, "burnTickRatio", 0.7) == 0.7, "r_hearthcore: burnTickRatio should be 0.7")

	# Sanity: an unrelated combat with NO relics gets the untouched baseline defaults.
	var c0 := _new_combat([])
	_assert(RelicHooks.sum(c0, "critBonus") == 0.0, "no relics: critBonus baseline should be 0")
	_assert(not RelicHooks.has(c0, "hiveMind"), "no relics: has(hiveMind) should be false")


# ===========================================================================
# 6. Relics — hook_key logic in relic_hooks.gd's TABLE, exercised through the exact
# ctx shapes damage_pipeline.gd/status_engine.gd/combat_engine.gd pass at their real call
# sites (RelicHooks.fire/run_value_hook), against real Unit objects from a real CombatEngine.
# ===========================================================================
func _check_relic_hooks() -> void:
	_check_mod_dmg_relic("r_rotbite", "poison", 2.0, func(v): return v + 2.0)
	_check_mod_dmg_relic("r_tinderbox", "burn", 2.0, func(v): return v + 2.0)
	_check_mod_dmg_relic("r_openwound", "poison", 2.0, func(v): return ceil(v * 1.3))
	_check_scentofblood()
	_check_lastwall()
	_check_spines()
	_check_ember()
	_check_bloodhymn()
	_check_bastionplate()
	_check_chainreact()
	_check_cullingorder()
	_check_manaspring()


func _check_mod_dmg_relic(relic_id: String, status_key: String, stack: float, expected: Callable) -> void:
	var combat := _new_combat([relic_id])
	var src: Unit = combat.alive_party()[0]
	var tgt: Unit = combat.alive_enemies()[0]
	var base_v := 10.0

	tgt.hp = tgt.max_hp
	var dealt_plain := DamagePipeline.resolve({"combat": combat, "src": src, "tgt": tgt, "value": base_v, "attack": true, "face_type": "dmg"})
	_assert(dealt_plain == int(base_v), "%s: baseline (no %s) dealt should be %d, got %d" % [relic_id, status_key, int(base_v), dealt_plain])

	tgt.hp = tgt.max_hp
	tgt.status[status_key] = int(stack)
	var dealt_boosted := DamagePipeline.resolve({"combat": combat, "src": src, "tgt": tgt, "value": base_v, "attack": true, "face_type": "dmg"})
	var expected_v := int(expected.call(base_v))
	_assert(dealt_boosted == expected_v, "%s: with %s, dealt should be %d, got %d" % [relic_id, status_key, expected_v, dealt_boosted])


func _check_scentofblood() -> void:
	var combat := _new_combat(["r_scentofblood"])
	var src: Unit = combat.alive_party()[0]
	var tgt: Unit = combat.alive_enemies()[0]

	tgt.hp = tgt.max_hp   # full HP -> no bonus
	var dealt_full := DamagePipeline.resolve({"combat": combat, "src": src, "tgt": tgt, "value": 10.0, "attack": true, "face_type": "dmg"})
	_assert(dealt_full == 10, "r_scentofblood: full-hp target should take base 10, got %d" % dealt_full)

	tgt.hp = int(tgt.max_hp * 0.4)   # below half -> +4
	var dealt_low := DamagePipeline.resolve({"combat": combat, "src": src, "tgt": tgt, "value": 10.0, "attack": true, "face_type": "dmg"})
	# `dealt` is the hit VALUE applied (DamagePipeline.resolve's `iv`), not the HP actually
	# removed — it is not re-clamped even if it overkills (only tgt.hp itself is clamped to
	# 0). So this should be exactly base+4, independent of tgt's remaining HP.
	_assert(dealt_low == 14, "r_scentofblood: <50%% hp target should take base+4=14, got %d" % dealt_low)


func _check_lastwall() -> void:
	var combat := _new_combat(["r_lastwall"])
	var weakest: Unit = combat.alive_party()[0]
	for u in combat.alive_party():
		if u.hp + u.shield < weakest.hp + weakest.shield:
			weakest = u
	RelicHooks.fire(combat, "on_turn_start", {"combat": combat})
	_assert(int(weakest.status.get("undying", 0)) == 1, "r_lastwall: weakest ally should gain Undying")


func _check_spines() -> void:
	var combat := _new_combat(["r_spines"])
	RelicHooks.fire(combat, "on_turn_start", {"combat": combat})
	for u in combat.alive_party():
		_assert(int(u.status.get("thorns", 0)) >= 2, "r_spines: %s should have Thorns >= 2" % u.key)


func _check_ember() -> void:
	var combat := _new_combat(["r_ember"])
	var src: Unit = combat.alive_party()[0]
	var tgt: Unit = combat.alive_enemies()[0]
	RelicHooks.fire(combat, "on_hit", {"type": "dmg", "dealt": 5, "tgt": tgt, "crit": false, "src": src, "combat": combat})
	_assert(int(tgt.status.get("burn", 0)) == 2, "r_ember: dealing >=4 should apply Burn 2, got %d" % int(tgt.status.get("burn", 0)))


func _check_bloodhymn() -> void:
	var combat := _new_combat(["r_bloodhymn"])
	var src: Unit = combat.alive_party()[0]
	var tgt: Unit = combat.alive_enemies()[0]
	var mana_before := combat.mana
	RelicHooks.fire(combat, "on_hit", {"type": "dmg", "dealt": 5, "tgt": tgt, "crit": true, "src": src, "combat": combat})
	_assert(combat.mana == mana_before + 2, "r_bloodhymn: crit hit should grant 2 mana, mana=%d" % combat.mana)


func _check_bastionplate() -> void:
	var combat := _new_combat(["r_bastionplate"])
	var tgt: Unit = combat.alive_party()[0]   # on_shield only fires for side=='p' targets
	# Splash lands on a RANDOM enemy (combat._rng-driven), so check TOTAL enemy hp across
	# the board dropped, rather than assuming a specific enemy index was hit.
	var total_before := 0
	for e in combat.alive_enemies():
		total_before += e.hp
	RelicHooks.fire(combat, "on_shield", {"v": 10, "tgt": tgt, "combat": combat})
	var total_after := 0
	for e in combat.alive_enemies():
		total_after += e.hp
	_assert(total_after < total_before, "r_bastionplate: a random enemy should take splash damage from a Shield event")


func _check_chainreact() -> void:
	var combat := _new_combat(["r_chainreact"])
	var hp_before := {}
	for u in combat.alive_party() + combat.alive_enemies():
		hp_before[u.uid] = u.hp
	var dead_enemy: Unit = combat.alive_enemies()[0]
	RelicHooks.fire(combat, "on_kill", {"tgt": dead_enemy, "combat": combat})
	var any_damaged := false
	for u in combat.party + combat.enemies:
		if hp_before.has(u.uid) and u.hp < hp_before[u.uid]:
			any_damaged = true
	_assert(any_damaged, "r_chainreact: on_kill should deal 5 dmg to every surviving unit")


func _check_cullingorder() -> void:
	var combat := _new_combat(["r_cullingorder"])
	var party := combat.alive_party()
	var weakest: Unit = party[0]
	for u in party:
		if float(u.hp) / u.max_hp < float(weakest.hp) / weakest.max_hp:
			weakest = u
	weakest.hp = max(1, weakest.hp - 5)
	var hp_before := weakest.hp
	var shield_before := weakest.shield
	RelicHooks.fire(combat, "on_kill", {"tgt": combat.alive_enemies()[0], "combat": combat})
	# Plant's BULWARK class passive adds +2 to every Shield created (damage_pipeline.gd
	# apply_shield()) — account for it if the most-wounded ally happens to be Plant.
	var expected_shield_gain := 4 + (2 if weakest.cls == "plant" else 0)
	_assert(weakest.hp == min(weakest.max_hp, hp_before + 4), "r_cullingorder: most-wounded ally should heal 4")
	_assert(weakest.shield == shield_before + expected_shield_gain,
		"r_cullingorder: most-wounded ally (%s) should gain %d Shield, got %d" % [weakest.cls, expected_shield_gain, weakest.shield - shield_before])


func _check_manaspring() -> void:
	var combat := _new_combat(["r_manaspring"])
	var mana_before := combat.mana
	RelicHooks.fire(combat, "on_turn_start", {"combat": combat})
	_assert(combat.mana == mana_before + 2, "r_manaspring: turn start should grant 2 mana")


# ===========================================================================
# 7. Holistic proof — a full real combat (auto-bot, same pattern as t_vertical_slice) with
# ALL 20 new relics owned simultaneously, against the new "hexeye" mage enemy, run through
# several real turns via CombatEngine's actual FSM (roll/reroll/execute/end_turn). Proves
# nothing crashes, no anomalies appear, and combat reaches a real conclusion with 20 relics'
# worth of hooks firing every turn together.
# ===========================================================================
const ALL_20_RELIC_IDS := [
	"r_rotbite", "r_tinderbox", "r_lastwall", "r_spines", "r_luckycharm", "r_ember",
	"r_openwound", "r_holyfont", "r_hivemind", "r_scentofblood", "r_bloodhymn",
	"r_bastionplate", "r_hollowbone", "r_chainreact", "r_cullingorder", "r_hearthcore",
	"r_manaspring", "r_venomengine", "r_mirrorshell", "r_solarcore",
]

func _check_full_combat_with_all_relics() -> void:
	var combat := _new_combat(ALL_20_RELIC_IDS, 999001)
	# Swap the default (slime-only) encounter for one of this pass's new enemies, so this
	# holistic run also exercises new enemy content, not just new relics. (CombatEngine's
	# own encounter generator is hardcoded to slimes — see ContentDB.gd's boss/enemy content
	# comments — so this is a direct, test-only substitution, same technique as the boss
	# phase-transition check above.)
	var hexeye: Unit = combat._mk_monster("hexeye", 1.2, {"hp": 1.0, "dmg": 1.0})
	combat.enemies = [hexeye]
	combat._roll_unit(hexeye)
	combat._pick_enemy_intent(hexeye)
	# Same by-value-lambda-capture caveat as the boss phase test above — use a 1-element
	# Array as a mutable box so the handler's writes are actually visible out here.
	var anomaly := [""]
	var on_hp = func(uid, hp, max_hp, shield):
		if hp < 0 or shield < 0 or max_hp <= 0 or is_nan(hp) or is_nan(shield):
			anomaly[0] = "unit %d has invalid numbers hp=%s max_hp=%s shield=%s" % [uid, hp, max_hp, shield]
	EventBus.hp_changed.connect(on_hp)

	var turns := 0
	while not combat.won and not combat.lost and turns < 100:
		_play_one_turn(combat)
		turns += 1

	EventBus.hp_changed.disconnect(on_hp)

	_assert(anomaly[0] == "", "full combat w/ 20 relics: %s" % anomaly[0])
	_assert(combat.won or combat.lost, "full combat w/ 20 relics: never reached a conclusion in %d turns" % turns)
	print("t_content_expansion: full-combat-with-relics finished after %d turn(s), won=%s, mana=%d" % [turns, combat.won, combat.mana])


func _play_one_turn(combat: CombatEngine) -> void:
	var guard := 0
	while guard < 64:
		guard += 1
		var acted := false
		for u in combat.party.duplicate():
			if u.hp <= 0 or not u.has_rolled() or u.roll_used():
				continue
			var fi: int = u.roll_face_index()
			var f: Dictionary = u.die[fi]
			var face_type := String(f.get("type", ""))
			var tgt_uid := -1
			if face_type in ["dmg", "poison", "debuff"]:
				var es: Array = combat.alive_enemies()
				if es.size() > 0:
					tgt_uid = es[0].uid
			else:
				tgt_uid = u.uid
			if combat.use_die(u.uid, tgt_uid):
				acted = true
		if not acted:
			break
	combat.end_turn()
