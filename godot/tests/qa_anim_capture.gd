extends Node
## Manual VISUAL QA capture — NOT part of the automated regression suite (no ci gate calls this,
## and its very nature — real wall-clock timing + real rendered pixels — is exactly what this
## project's own testing-standards.md/coding-standards.md carve out as "Visual/Feel" evidence
## (ADVISORY, not a BLOCKING automated gate; see coding-standards.md's Test Evidence table and
## its "What NOT to Automate: ... 'Feel' qualities (input responsiveness, ... timing) ...
## Platform-specific rendering (test on target hardware, not headlessly)").
##
## Drives a REAL combat through CombatView's own click-handler methods (same white-box access
## t_combatview_smoke.gd uses) with juice ENABLED (unlike that test, which deliberately sets
## CombatView.disable_juice_for_tests = true) so the WalkAttack/IdleGetHit/Dead/Run clips wired
## in this animation pass actually play out over real frames — then screenshots the actual
## rendered window at short intervals around EventBus.face_used / hit_landed / unit_died /
## combat_finished(true), to PROVE frame-to-frame motion (not a single static pose).
##
## MUST run non-headless: --headless's rendering driver is "dummy" and get_texture() returns
## nothing there (t_stage3d_facing.gd's own comment already documents this same limitation for
## this engine build). Run as its own separate windowed instance — do not point this at a
## terminal/window the user is actively interacting with.
##
## Run: /path/to/Godot --path godot tests/qa_anim_capture.tscn

const MAX_STEPS := 200
const _CAPTURE_INTERVAL := 0.25   # seconds between frames within one burst — inside the
	# 0.2-0.3s window the task asked for
const _BURST_FRAMES := 4          # ~1.0s per burst — deliberately short enough that even the
	# win-triggered "victory_march" burst finishes safely inside CombatStage3D's own
	# ~1.2s march duration, before CombatView._finish() calls change_scene_to_file() and tears
	# down this script's own node (it IS the loaded main scene here, same situation
	# t_combatview_smoke.gd's file-header comment already documents for the exact same reason).
var _EVIDENCE_DIR := QaPaths.evidence_dir()

var _view: Node2D
var _combat: CombatEngine
var _shot_index := 0
var _captured_action := false
var _captured_hit := false
var _captured_death := false
var _captured_victory := false


func _ready() -> void:
	var tree := get_tree()   # cached up front — see const comment above for why
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)

	RunState.pending_combat = {
		"node_id": "qa_anim_capture",
		"kind": "battle",
		"pw": 2,
		"ascension": 0,
		"roster_snapshot": _synthetic_roster(),
		"relic_ids": [],
		"combat_seed": 13371337,
	}
	EventBus.face_used.connect(_on_face_used)
	EventBus.hit_landed.connect(_on_hit_landed)
	EventBus.unit_died.connect(_on_unit_died)
	EventBus.combat_finished.connect(_on_combat_finished)

	var combat_scene: Node = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(combat_scene)
	_view = combat_scene
	await tree.process_frame
	_combat = _view.get("_combat") as CombatEngine
	print("qa_anim_capture: combat built, party=%d enemies=%d" % [_combat.party.size(), _combat.enemies.size()])

	var steps := 0
	while not (_combat.won or _combat.lost) and steps < MAX_STEPS:
		await _play_one_turn(tree)
		steps += 1

	await tree.create_timer(2.0).timeout   # let combat_finished's victory march / scene change
		# land before this node's own _ready() coroutine (and this whole script) exits
	print("qa_anim_capture: done, %d frame(s) written to %s" % [_shot_index, _EVIDENCE_DIR])
	tree.quit(0)


# ===========================================================================
# EventBus hooks — first occurrence of each only (see _captured_* flags), fire-and-forget async
# bursts (not awaited inline) so the turn-driving loop below is never blocked by them.
# ===========================================================================

func _on_face_used(uid: int, _side, _target_uid, _aoe, _face_part, _face_name, _face_type) -> void:
	if _captured_action:
		return
	_captured_action = true
	_burst("action_uid%d" % uid)


func _on_hit_landed(_src_uid: int, uid: int, _value, _crit) -> void:
	if _captured_hit:
		return
	_captured_hit = true
	_burst("hit_uid%d" % uid)


func _on_unit_died(uid: int) -> void:
	if _captured_death:
		return
	_captured_death = true
	_burst("death_uid%d" % uid)


func _on_combat_finished(won: bool) -> void:
	if not won or _captured_victory:
		return
	_captured_victory = true
	_burst("victory_march")


func _burst(tag: String) -> void:
	for i in _BURST_FRAMES:
		await get_tree().create_timer(_CAPTURE_INTERVAL).timeout
		_save_frame(tag, i)


func _save_frame(tag: String, i: int) -> void:
	if not is_inside_tree():
		return   # scene may have already changed (win path) — see _BURST_FRAMES comment
	var vp := get_viewport()
	if vp == null:
		return
	var img := vp.get_texture().get_image()
	var path := "%s/%s_anim-%s_%02d.png" % [_EVIDENCE_DIR, _today(), tag, i]
	img.save_png(path)
	_shot_index += 1
	print("qa_anim_capture: saved %s" % path)


# ===========================================================================
# Turn-driving loop — same click-handler-only white-box approach as t_combatview_smoke.gd's
# _play_one_turn(), minus the disable_juice_for_tests short-circuit (juice stays ON here on
# purpose) and minus that test's own assertions (this is an evidence-gathering tool, not a gate).
# ===========================================================================

func _play_one_turn(tree: SceneTree) -> void:
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
			_view.call("_on_die_slot_pressed", i)
			if int(_view.get("_selected_die_uid")) != u.uid:
				continue
			var fi := u.roll_face_index()
			var face_type := String(u.die[fi].get("type", ""))
			var target_uid := _pick_target(face_type)
			if target_uid == -1:
				_view.call("_on_die_slot_pressed", i)   # deselect — nothing legal to target
				continue
			_view.call("_on_target_clicked", target_uid)
			await _await_animation_clear(tree)
			acted = true
		if not acted:
			break
	_view.call("_on_end_turn_pressed")
	await _await_animation_clear(tree)


func _await_animation_clear(tree: SceneTree) -> void:
	var guard := 0
	while is_instance_valid(_view) and bool(_view.get("_is_animating")) and guard < 300:
		await tree.process_frame
		guard += 1


func _pick_target(face_type: String) -> int:
	if face_type in ["dmg", "poison", "debuff"]:
		var es: Array = _combat.alive_enemies()
		return es[0].uid if es.size() > 0 else -1
	var us: Array = _combat.party
	for u in us:
		if u.hp > 0:
			return u.uid
	return -1


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


## Today, as `YYYY-MM-DD`, for naming the files this capture writes.
##
## The date used to be typed into the filename by hand. That makes a screenshot LIE the moment
## the capture is re-run: the picture is regenerated, the name still says the day it was first
## written, and anyone reading the folder — or a report linking to it — concludes the evidence is
## stale when it is current. Stamping it at run time means a filename can only ever be right.
func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
