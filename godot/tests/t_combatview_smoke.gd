extends Node
## Headless smoke test for Combat.tscn + CombatView.gd (godot-port-rule-spec.md task:
## "chơi được 1 trận đấu THẬT bằng chuột"). Loads the REAL scene — real autoloads, real
## AxieMixerBoot, real CombatEngine, real UnitPortrait/AxieCharacter3D — and drives several
## turns by calling CombatView's own click-handler methods directly (white-box access, same
## pattern t_vertical_slice.gd already uses on CombatEngine fields). This proves CombatView's
## input wiring actually reaches CombatEngine's public API, not just that the engine works in
## isolation (t_vertical_slice.gd already covers that).
##
## Run: godot --headless --path godot tests/t_combatview_smoke.tscn
## (scene mode, not raw --script — see t_vertical_slice.gd's comment for why: autoload
## singletons aren't resolvable as compile-time identifiers in --script SceneTree mode.)
##
## JUICE (checklist step 7) INTERACTION: CombatView._on_die_slot_pressed()/_on_target_clicked()
## now reject input while CombatView._is_animating is true (hit/damage Tween sequence running).
## This test drives an entire combat by calling those handlers back-to-back, script-fast — far
## faster than a human, and repeated across dozens of turns. Investigating a real hang here
## (see report) found that paying real Tween/SceneTreeTimer wall-clock cost that many times in
## one headless run is not just slow but, deep into a run, unreliable — a `sample` capture of
## the stuck process showed the main thread parked in `nanosleep` well past when timers should
## have fired. Per this project's own testing-standards.md ("Visual/Feel ... timing" is
## explicitly NOT something to automate/gate on), the fix is CombatView.disable_juice_for_tests
## (set below, before Combat.tscn is instantiated): it skips creating any juice Tween/Timer at
## all, so this test exercises exactly the same CombatEngine-driving code path as a real click,
## with zero dependency on headless frame/timer timing. _await_animation_clear() below is kept
## as a cheap, bounded defensive check (not the fix) in case that flag ever fails to suppress
## something.

const MAX_STEPS := 200
const _ANIM_CLEAR_FRAME_GUARD := 300

var _view: Node2D
var _anomaly := ""


func _ready() -> void:
	# Cache the SceneTree BEFORE any gameplay action can run: a real win legitimately calls
	# get_tree().change_scene_to_file() (CombatView._finish()), which detaches this test node
	# (it IS the loaded main scene here) from the tree — self.get_tree() would return null
	# afterward. Grabbing it once up front sidesteps that, without touching CombatView.gd.
	var tree := get_tree()

	CombatView.disable_juice_for_tests = true   # see file-level JUICE comment above

	# Arrange: same CombatSetup shape RunMapController would hand off (RunState.gd, enter_node()).
	RunState.pending_combat = {
		"node_id": "smoke_node",
		"kind": "battle",
		"pw": 2,
		"ascension": 0,
		"roster_snapshot": _synthetic_roster(),
		"relic_ids": [],
		"combat_seed": 13371337,
	}

	var combat_scene: Node = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(combat_scene)
	_view = combat_scene
	await tree.process_frame   # let AxieMixerInitializer/onready wiring settle

	# Assert: scene loaded and wired a real CombatEngine + a portrait per unit.
	var combat: CombatEngine = _view.get("_combat") as CombatEngine
	_check(combat != null, "CombatView did not build a CombatEngine")
	if _anomaly != "":
		_fail(tree)
		return
	_check(combat.party.size() == 5, "expected 5 party units, got %d" % combat.party.size())
	_check(combat.enemies.size() > 0, "expected at least 1 enemy")

	var portraits: Dictionary = _view.get("_portraits") as Dictionary
	var expected_uids: Array = []
	for u in combat.party:
		expected_uids.append(u.uid)
	for e in combat.enemies:
		expected_uids.append(e.uid)
	for uid in expected_uids:
		_check(portraits.has(uid), "no UnitPortrait spawned for uid=%d" % uid)

	print("=== t_combatview_smoke: initial party=%s enemies=%s ===" % [
		_describe(combat.party), _describe(combat.enemies)])

	# Act: play real turns purely through CombatView's click handlers.
	var steps := 0
	while not (combat.won or combat.lost) and steps < MAX_STEPS and _anomaly == "":
		await _play_one_turn(combat, tree)
		steps += 1

	print("=== t_combatview_smoke: combat ended after %d simulated turn(s), won=%s lost=%s ===" % [
		steps, combat.won, combat.lost])

	# Assert: combat actually finished through the UI-driven path, and CombatView's own
	# result plumbing ran (RunState.apply_combat_result / result overlay).
	_check(combat.won or combat.lost, "combat never finished within %d steps" % MAX_STEPS)
	_check(steps < MAX_STEPS, "combat ran away past %d steps" % MAX_STEPS)
	_check(bool(_view.get("_result_shown")), "CombatView never showed a result after combat_finished")

	CombatView.disable_juice_for_tests = false   # integration tests clean up after themselves
		# (test-standards.md) — harmless in a single-test process, but keeps this static flag
		# from ever leaking into a hypothetical future in-process test chain

	if _anomaly == "":
		print("t_combatview_smoke: PASS — Combat.tscn loaded, portraits wired, click handlers drove CombatEngine to a real finish")
		tree.quit(0)
	else:
		_fail(tree)


func _play_one_turn(combat: CombatEngine, tree: SceneTree) -> void:
	var guard := 0
	while guard < 32:
		guard += 1
		var acted := false
		var units: Array = _view.call("_party_dice_units")
		for i in units.size():
			var u: Unit = units[i]
			if u.hp <= 0 or not u.has_rolled() or u.roll_used():
				continue

			await _await_animation_clear(tree)
			if _anomaly != "":
				return
			_view.call("_on_die_slot_pressed", i)
			if int(_view.get("_selected_die_uid")) != u.uid:
				_anomaly = "die slot click did not select uid=%d" % u.uid
				return

			var fi := u.roll_face_index()
			var face_type := String(u.die[fi].get("type", ""))
			var target_uid := _pick_target(combat, u, face_type)
			if target_uid == -1:
				_view.call("_on_die_slot_pressed", i)   # deselect — nothing legal to target
				continue

			_view.call("_on_target_clicked", target_uid)
			await _await_animation_clear(tree)
			if _anomaly != "":
				return
			if int(_view.get("_selected_die_uid")) != -1:
				_anomaly = "selection not cleared after _on_target_clicked"
				return
			acted = true
		if not acted:
			break
	_view.call("_on_end_turn_pressed")
	await _await_animation_clear(tree)   # enemy intents can land hits too — drain the lock
		# before the next _play_one_turn() call presses a die slot again


## Defensive-only (see file-level JUICE comment — CombatView.disable_juice_for_tests is the
## actual fix, this should always be a same-frame no-op). Bails with an anomaly rather than
## hanging if _is_animating ever unexpectedly stays true, so a real regression fails loudly.
func _await_animation_clear(tree: SceneTree) -> void:
	var guard := 0
	while is_instance_valid(_view) and bool(_view.get("_is_animating")) and guard < _ANIM_CLEAR_FRAME_GUARD:
		await tree.process_frame
		guard += 1
	if is_instance_valid(_view) and bool(_view.get("_is_animating")):
		_anomaly = "CombatView._is_animating never cleared within %d frames" % _ANIM_CLEAR_FRAME_GUARD


func _pick_target(combat: CombatEngine, u: Unit, face_type: String) -> int:
	if face_type in ["dmg", "poison", "debuff"]:
		var es: Array = combat.alive_enemies()
		return es[0].uid if es.size() > 0 else -1
	return u.uid   # shield/heal/buff/mana/summon/blank all accept self as a safe target_uid


func _synthetic_roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({
			"persistent_id": i + 1,
			"hero_key": keys[i],
			"tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"],
			"muts": [],
			"growth": {},
			"bonus_hp": 0,
		})
	return out


func _describe(units: Array) -> String:
	var parts: Array = []
	for u in units:
		parts.append("%s#%d[hp=%d/%d]" % [u.key, u.uid, u.hp, u.max_hp])
	return ", ".join(parts)


func _check(cond: bool, msg: String) -> void:
	if not cond and _anomaly == "":
		_anomaly = msg


func _fail(tree: SceneTree) -> void:
	print("t_combatview_smoke: FAIL — %s" % _anomaly)
	CombatView.disable_juice_for_tests = false
	tree.quit(1)
