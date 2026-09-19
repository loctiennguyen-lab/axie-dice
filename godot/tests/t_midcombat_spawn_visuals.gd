extends Node
## Regression gate: a unit that JOINS a fight already in progress must get the same visuals as
## one that started in it.
##
## THE BUG
## -------
## `CombatView` built a nameplate, head HUD and 3D slot for every unit exactly once, in
## `_ready()`. Five separate places add a unit mid-combat — gooey_king's SPLIT
## (`combat_engine.gd` `spawn_boss_add`), a summoner monster's adds, the `summon` die face, the
## `summon` active card, and the `r_broodmother` relic (in `relic_hooks.gd`, a different file
## again). None of them told the view. The result was a monster with no name, no HP bar, no
## status pills and, once audio was wired, no sound at all.
##
## Nothing crashed. `_update_portrait()` returns quietly for a uid it does not know, so the
## missing unit rendered as a bare sprite and read as a styling choice rather than a defect —
## the same shape as every other bug this port has had to find by looking rather than by
## testing.
##
## WHAT IS ASSERTED
## ----------------
## Not "the signal fired". The signal is only there for promptness; `CombatView` reconciles its
## whole roster on every rebuild, precisely so that a sixth spawn site added later cannot
## reintroduce this by forgetting to announce itself. So the assertion is the outcome: after a
## real mid-combat spawn, EVERY living unit the engine knows about has a portrait, a head HUD,
## a 3D slot and an audio voice — and no two units share a position.
##
## Run: godot --headless --path godot res://tests/t_midcombat_spawn_visuals.tscn

var _failures: Array[String] = []
var _checks := 0
var _view: Node2D


func _ready() -> void:
	print("=== t_midcombat_spawn_visuals: start ===")
	var tree := get_tree()
	CombatView.disable_juice_for_tests = true

	RunState.pending_combat = {
		"node_id": "midspawn_node", "kind": "battle", "pw": 3, "ascension": 0,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 246810,
	}
	var scene: Node = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(scene)
	_view = scene
	await tree.process_frame

	test_every_starting_unit_has_visuals()
	await test_a_unit_added_mid_combat_gets_visuals()
	test_no_two_units_share_a_slot_position()

	print("=== t_midcombat_spawn_visuals: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_midcombat_spawn_visuals: PASS — %d checks OK" % _checks)
		tree.quit(0)
		return
	for f in _failures:
		print("t_midcombat_spawn_visuals: FAIL — %s" % f)
	tree.quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func _roster() -> Array:
	var out: Array = []
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	for i in keys.size():
		out.append({
			"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [], "growth": {}, "bonus_hp": 0,
		})
	return out


## Every visual a unit is supposed to own, checked together — a unit with a nameplate but no
## audio voice is the half-fixed version of this bug.
func _assert_fully_visualised(u: Unit, context: String) -> void:
	_assert(_view._portraits.has(u.uid),
		"%s: unit %d (%s) has no UnitPortrait — no name, no HP bar" % [context, u.uid, u.n])
	_assert(_view._head_huds.has(u.uid),
		"%s: unit %d (%s) has no UnitHeadHUD — no status pills, no intent badge"
			% [context, u.uid, u.n])
	_assert(_view._stage3d.has_unit(u.uid),
		"%s: unit %d (%s) has no 3D slot on the stage" % [context, u.uid, u.n])
	_assert(_view._audio._voices.has(u.uid),
		"%s: unit %d (%s) has no audio voice registered — it would fight in silence"
			% [context, u.uid, u.n])
	# Existing is not enough: a portrait built but never painted shows 0/0 with an empty bar,
	# which reads as a monster that spawned already dead. This is the half of the bug the
	# first version of this test missed entirely — it asked "is there a nameplate?" and never
	# "does the nameplate say the right thing?".
	var p: UnitPortrait = _view._portraits.get(u.uid)
	if p != null and u.hp > 0:
		var shown: String = p._hp_label.text          # what the player actually reads
		var want := "%d/%d" % [u.hp, u.max_hp]
		_assert(shown == want,
			"%s: unit %d (%s) nameplate reads '%s' but the engine says '%s'"
				% [context, u.uid, u.n, shown, want])


func test_every_starting_unit_has_visuals() -> void:
	for u in _view._combat.party:
		_assert_fully_visualised(u, "at combat start")
	for e in _view._combat.enemies:
		_assert_fully_visualised(e, "at combat start")


## Drives a real spawn through the engine rather than reaching into the view, so the path under
## test is the one the game actually uses.
func test_a_unit_added_mid_combat_gets_visuals() -> void:
	var combat = _view._combat
	var enemies_before: int = combat.enemies.size()
	var boss: Unit = combat.enemies[0]
	# `adds` is what a splitting boss spawns; giving it to a rank-and-file enemy here exercises
	# the same spawn_boss_add() path without needing to drive a whole boss fight to 2/3 HP.
	boss.custom_state["adds"] = ["slime"]
	combat.spawn_boss_add(boss, 1.0)
	await get_tree().process_frame

	_assert(combat.enemies.size() == enemies_before + 1,
		"spawn_boss_add() did not actually add an enemy (%d -> %d)"
			% [enemies_before, combat.enemies.size()])
	if combat.enemies.size() <= enemies_before:
		return

	var newcomer: Unit = combat.enemies[combat.enemies.size() - 1]
	_assert_fully_visualised(newcomer, "after a mid-combat spawn")

	# And the reconcile must hold without the signal too: that is the whole reason it exists.
	# Appending directly is exactly what a future spawn site that forgets to emit would do.
	var quiet: Unit = combat._mk_ally()
	combat.party.append(quiet)
	_view._rebuild_all()
	_assert_fully_visualised(quiet, "after a spawn that emitted no signal")


## The row re-seat. Every slot is positioned from the slot_count known when it was built, so a
## newcomer lands on an existing unit unless the whole row is re-seated.
func test_no_two_units_share_a_slot_position() -> void:
	var seen: Dictionary = {}
	for u in (_view._combat.party + _view._combat.enemies):
		if not _view._stage3d._units.has(u.uid):
			continue
		var slot: Node3D = _view._stage3d._units[u.uid]["slot"]
		var key := "%s@%.3f,%.3f" % [u.side, slot.position.x, slot.position.z]
		_assert(not seen.has(key),
			"units %d and %d occupy the same spot (%s) — the row was not re-seated after a spawn"
				% [int(seen.get(key, -1)), u.uid, key])
		seen[key] = u.uid
	_assert(seen.size() >= 6, "expected at least 6 positioned units, found %d" % seen.size())
