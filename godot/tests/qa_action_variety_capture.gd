extends Node
## Manual VISUAL QA capture (ui-programmer follow-up pass, tasks A + C) — NOT part of the
## automated regression suite, same rationale qa_anim_capture.gd's own header already documents
## (real wall-clock timing + real rendered pixels = "Visual/Feel" evidence, ADVISORY not
## BLOCKING — coding-standards.md's Test Evidence table). This capture is scoped to the two
## things this pass changed that qa_anim_capture.gd (previous round) does not exercise:
##
##  1. CombatStage3D.play_action(uid, face_type) now picks a different clip/time_scale per die
##     face `type` (see that method's _ACTION_ANIM_BY_TYPE comment) instead of always WalkAttack.
##     Captured via a DIRECT call on a live party uid, immediately after spawn — deterministic,
##     not dependent on which faces this seed happens to roll or how fast this fixed roster wins
##     (an earlier version of this script drove a full RNG combat instead and — real report from
##     running it — hung indefinitely: the combat won in ~2 turns, CombatView's own victory-march
##     async handler called get_tree().change_scene_to_file() WHILE this script's own coroutine
##     was still suspended inside an `await` for a later burst, and a GDScript coroutine that
##     resumes on a Node the scene-change just freed never resumes at all. Capturing all 7 types
##     up front, before any turn is even played, removes any dependency on combat outcome/timing).
##  2. CombatView._on_reroll_pressed()'s new "tung xúc xắc" toss overlay (_start_reroll_toss()) —
##     captured on turn 1 (forced reroll), then this script quits immediately after that turn
##     ends, without any extra idle wait — see the _ready() comment above `tree.quit(0)` for why
##     no buffer delay is used here (same race this file's own header just described).
##
## MUST run non-headless (real GPU rendering) — see qa_anim_capture.gd's own header for why
## --headless can't produce real pixels here. Run as its own separate windowed instance — do not
## point this at a terminal/window the user is actively interacting with (checked via `ps aux`
## before launching, per this task's own instructions).
##
## Run: /path/to/Godot --path godot tests/qa_action_variety_capture.tscn

const _CAPTURE_INTERVAL := 0.12   # tighter than qa_anim_capture.gd's 0.25s — the per-type clips
	# here are short one-shots (IdleCarryItem/RunAttack), and the reroll toss is only ~0.36s
	# total, so a denser sampling interval is needed to actually land frames mid-motion.
const _BURST_FRAMES := 4
const _ALL_TYPES := ["dmg", "shield", "heal", "poison", "mana", "buff", "debuff"]
var _EVIDENCE_DIR := QaPaths.evidence_dir()

var _view: Node2D
var _combat: CombatEngine
var _shot_index := 0


func _ready() -> void:
	var tree := get_tree()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)

	RunState.pending_combat = {
		"node_id": "qa_action_variety_capture",
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
	await tree.process_frame
	_combat = _view.get("_combat") as CombatEngine
	print("qa_action_variety_capture: combat built, party=%d enemies=%d" % [_combat.party.size(), _combat.enemies.size()])

	# --- Task A evidence: all 7 types, deterministic, before any turn is played -----------------
	var stage3d = _view.get("_stage3d")
	var uid1 := int(_combat.party[0].uid)
	for face_type in _ALL_TYPES:
		if not is_instance_valid(stage3d):
			break
		stage3d.play_action(uid1, face_type)
		await _burst("type_%s_uid%d" % [face_type, uid1])

	# --- Task C evidence: one real turn, reroll forced at the start -----------------------------
	await _play_one_turn_with_forced_reroll(tree)

	print("qa_action_variety_capture: done — %d frame(s) written to %s" % [_shot_index, _EVIDENCE_DIR])
	tree.quit(0)   # no buffer sleep here on purpose — see file-header comment: this must finish
		# and quit before CombatView's own async victory-march/change_scene_to_file (if this
		# turn happened to end the fight) has a chance to free this script's own node mid-await.


func _burst(tag: String) -> void:
	for i in _BURST_FRAMES:
		await get_tree().create_timer(_CAPTURE_INTERVAL).timeout
		_save_frame(tag, i)


func _save_frame(tag: String, i: int) -> void:
	if not is_inside_tree():
		return
	var vp := get_viewport()
	if vp == null:
		return
	var img := vp.get_texture().get_image()
	var path := "%s/%s_action-variety-%s_%02d.png" % [_EVIDENCE_DIR, _today(), tag, i]
	img.save_png(path)
	_shot_index += 1
	print("qa_action_variety_capture: saved %s" % path)


# ===========================================================================
# Single-turn driver — same click-handler-only white-box approach as qa_anim_capture.gd, plus a
# forced reroll (via the real _on_reroll_pressed() handler) at the very start of the turn, with a
# burst captured mid-toss before the turn continues normally.
# ===========================================================================

func _play_one_turn_with_forced_reroll(tree: SceneTree) -> void:
	var has_rerollable := false
	for u in _view.call("_party_dice_units"):
		if u.hp > 0 and u.has_rolled() and not u.roll_used() and not u.heavy and not u.frozen:
			has_rerollable = true
			break
	if has_rerollable:
		_view.call("_on_reroll_pressed")
		await _burst("reroll")

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
