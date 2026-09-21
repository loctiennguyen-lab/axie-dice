extends Node
## Regression test for the "ra chiêu" MOTION — CombatStage3D._play_action_motion().
##
## WHY IT IS A SEPARATE FILE. Every other combat test sets
## `CombatView.disable_juice_for_tests = true` before instantiating Combat.tscn, and that flag
## is the first line of every juice entry point in the build — including this one. A suite
## where every test disables the animation cannot notice the animation is gone. This test
## deliberately runs with juice ON and pays the real wall-clock cost of a few tweens.
##
## WHAT IT PINS. Until 2026-09-21 `play_action()` returned early for any unit without a
## skeletal rig, and EVERY monster in the game is a billboarded Sprite3D — so a slime
## telegraphed an attack, the damage number appeared, and nothing on the field moved. The
## no-rig case is therefore the first thing asserted here, and it is asserted on a unit that
## really has `character == null` rather than on a party Axie that happens to work.
##
## Run: godot --headless --path godot res://tests/t_action_motion.tscn

## SAVE GUARD. This test drives real combat, and combat writes: CombatView._ready() ends with
## `_save_run_progress()`, and a finished fight banks into MetaState. Both land in the file a
## real player's run history lives in. Every progression-touching gate in this suite borrows
## and restores it — see save_guard.gd's own header for the measurement that made that a rule.
var _guard := SaveGuard.new()


var _stage: CombatStage3D
var _view: Node2D
var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	var tree := get_tree()
	CombatView.disable_juice_for_tests = false   # the whole point — see the class comment
	print("=== t_action_motion: start ===")
	_guard.capture()

	RunState.pending_combat = {
		"node_id": "motion_node", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": _synthetic_roster(), "relic_ids": [], "combat_seed": 909090,
	}
	_view = load("res://scenes/combat/Combat.tscn").instantiate() as Node2D
	add_child(_view)
	await tree.process_frame
	await tree.process_frame
	_stage = _view.get("_stage3d")

	var combat: CombatEngine = _view.get("_combat") as CombatEngine
	var enemy: Unit = combat.enemies[0]
	var ally: Unit = combat.party[0]

	_test_the_impact_delay_matches_the_lunge_apex()
	await _test_a_rigless_monster_lunges_at_its_target(tree, enemy.uid, ally.uid)
	await _test_a_support_face_stays_on_its_mark(tree, ally.uid)
	await _test_dying_mid_lunge_puts_the_slot_back(tree, enemy.uid, ally.uid)
	await _test_a_ranged_face_plants_instead_of_lunging(tree, ally.uid, enemy.uid)

	CombatView.disable_juice_for_tests = false
	if _fails.is_empty():
		print("=== t_action_motion: %d checks, 0 failure(s) ===" % _checks)
		print("t_action_motion: PASS — %d checks OK" % _checks)
		_guard.restore()
		tree.quit(0)
	else:
		for f in _fails:
			print("t_action_motion: FAIL — %s" % f)
		_guard.restore()
		tree.quit(1)


## The two numbers are a pair by design: the damage number is timed to appear when the
## attacker is furthest into its lunge. They live in different files, so nothing but this
## check stops one of them being tuned alone.
func _test_the_impact_delay_matches_the_lunge_apex() -> void:
	var apex: float = CombatStage3D._LUNGE_OUT + CombatStage3D._LUNGE_HOLD
	_check(is_equal_approx(CombatView.impact_delay(), apex),
		"CombatView.impact_delay() is %.3fs but the lunge reaches its apex at %.3fs — the "
		% [CombatView.impact_delay(), apex]
		+ "damage number no longer lands with the blow")


## THE headline case: a unit with no rig at all still moves, and moves the right way.
func _test_a_rigless_monster_lunges_at_its_target(tree: SceneTree, uid: int,
		target_uid: int) -> void:
	var entry: Dictionary = _stage._units.get(uid, {})
	_check(entry.get("character") == null,
		"this test needs a RIGLESS enemy to be meaningful, but uid=%d has an AxieCharacter3D — "
		% uid + "pick a different encounter seed")
	var slot: Node3D = entry.get("slot")
	var rest: Vector3 = entry.get("rest_pos")
	var toward: Vector3 = (_stage._units[target_uid]["rest_pos"] as Vector3) - rest

	_stage.play_action(uid, "dmg", target_uid)
	# Sample at the apex, where the displacement is largest and the sign is unambiguous.
	await tree.create_timer(CombatStage3D._LUNGE_OUT).timeout
	var moved: Vector3 = slot.position - rest
	_check(moved.length() > 0.05,
		"a rigless monster did not move at all on a dmg face (displacement %.4fm) — this is "
		% moved.length() + "the exact defect play_action() had before it grew a motion path")
	_check(moved.normalized().dot(toward.normalized()) > 0.9,
		"the lunge went the wrong way: moved %s, target lies %s" % [moved, toward])
	_check(not slot.scale.is_equal_approx(Vector3.ONE),
		"the lunge carried no squash/stretch — scale stayed %s" % slot.scale)

	# And it comes home. A unit left off its mark drifts further every attack.
	await tree.create_timer(CombatStage3D._LUNGE_HOLD + CombatStage3D._LUNGE_BACK + 0.15).timeout
	_check(slot.position.distance_to(rest) < 0.01,
		"the monster never returned to its mark: %s vs rest %s" % [slot.position, rest])
	_check(slot.scale.is_equal_approx(Vector3.ONE),
		"the slot was left scaled at %s after the lunge" % slot.scale)


## A shield/heal/buff must NOT walk at anybody — the motion would claim a target the face does
## not have. It still has to do something, or the face reads as "nothing happened".
func _test_a_support_face_stays_on_its_mark(tree: SceneTree, uid: int) -> void:
	var entry: Dictionary = _stage._units.get(uid, {})
	var slot: Node3D = entry.get("slot")
	var rest: Vector3 = entry.get("rest_pos")
	_stage.play_action(uid, "shield", -1)
	await tree.create_timer(CombatStage3D._CAST_DIP).timeout
	_check(slot.position.distance_to(rest) < 0.001,
		"a shield face moved the unit off its mark by %.4fm" % slot.position.distance_to(rest))
	_check(not slot.scale.is_equal_approx(Vector3.ONE),
		"a shield face produced no motion at all — scale stayed %s" % slot.scale)
	await tree.create_timer(CombatStage3D._CAST_RISE * 2.0 + 0.15).timeout
	_check(slot.scale.is_equal_approx(Vector3.ONE),
		"the cast left the slot scaled at %s" % slot.scale)


## A unit can die inside its own attack (thorns, a counter). The death fade tweens `slot.scale`
## to zero while the lunge is tweening the same property back to ONE, and whichever lands last
## wins — which is how a corpse ends up full size, mid-air, off its mark.
func _test_dying_mid_lunge_puts_the_slot_back(tree: SceneTree, uid: int,
		target_uid: int) -> void:
	var entry: Dictionary = _stage._units.get(uid, {})
	var slot: Node3D = entry.get("slot")
	var rest: Vector3 = entry.get("rest_pos")
	_stage.play_action(uid, "dmg", target_uid)
	await tree.create_timer(CombatStage3D._LUNGE_OUT * 0.5).timeout
	_stage.play_death(uid)
	_check(slot.position.distance_to(rest) < 0.01,
		"killing a unit mid-lunge left its slot at %s instead of its mark %s — the death fade "
		% [slot.position, rest] + "and the lunge are now fighting over the same properties")


## A RANGED face must not lunge. The kit's own capture marks cast/projectile/throw as
## `isRanged`, and CombatStage3D reads that flag to decide whether the attacker closes the
## distance or plants and lets the effect cover it. Asserted against a MELEE face on the same
## unit and the same target, so a bug that simply disabled all motion cannot pass this.
##
## This lives here rather than in t_skill_vfx.gd because it is a MOTION assertion, and this is
## the only file in the suite that runs with juice on — see the class comment.
func _test_a_ranged_face_plants_instead_of_lunging(tree: SceneTree, uid: int,
		target_uid: int) -> void:
	var entry: Dictionary = _stage._units.get(uid, {})
	var slot: Node3D = entry.get("slot")
	var rest: Vector3 = entry.get("rest_pos")

	var melee_key := SkillVfxCatalog.clip_key("plant", "mouth", "dmg")
	var ranged_key := SkillVfxCatalog.clip_key("plant", "eyes", "debuff")
	_check(melee_key != "" and not SkillVfxCatalog.is_ranged(melee_key),
		"expected a mouth/dmg face to resolve to a MELEE clip, got '%s' (ranged=%s)"
		% [melee_key, SkillVfxCatalog.is_ranged(melee_key)])
	_check(ranged_key != "" and SkillVfxCatalog.is_ranged(ranged_key),
		"expected an eyes/debuff face to resolve to a RANGED clip, got '%s' (ranged=%s)"
		% [ranged_key, SkillVfxCatalog.is_ranged(ranged_key)])

	# Melee first, as the control: the same call path DOES move this unit.
	_stage.play_action(uid, "dmg", target_uid, melee_key)
	await tree.create_timer(CombatStage3D._LUNGE_OUT).timeout
	var melee_moved := slot.position.distance_to(rest)
	await tree.create_timer(CombatStage3D._LUNGE_HOLD + CombatStage3D._LUNGE_BACK + 0.15).timeout

	_stage.play_action(uid, "debuff", target_uid, ranged_key)
	await tree.create_timer(CombatStage3D._LUNGE_OUT).timeout
	var ranged_moved := slot.position.distance_to(rest)
	await tree.create_timer(CombatStage3D._CAST_RISE * 2.0 + 0.2).timeout

	_check(melee_moved > 0.05,
		"the melee control did not lunge (%.4fm) — this case cannot tell you anything about "
		% melee_moved + "the ranged one until the control moves")
	_check(ranged_moved < 0.001,
		"a ranged face moved the attacker %.4fm off its mark; it should plant and let the "
		% ranged_moved + "effect cover the distance (melee control moved %.4fm)" % melee_moved)
	_check(not slot.scale.is_equal_approx(Vector3.ONE) or ranged_moved == 0.0,
		"the ranged face produced no motion at all — a cast still has to dip and rise")
	_check(slot.position.distance_to(rest) < 0.01,
		"the unit was left off its mark at %s after the ranged face" % slot.position)


func _synthetic_roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({
			"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [], "growth": {}, "bonus_hp": 0,
		})
	return out


func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)
