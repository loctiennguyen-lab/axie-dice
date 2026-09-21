extends Node
## Manual VISUAL QA capture — evidence that CombatStage3D._play_action_motion()'s lunge/cast
## actually RENDERS, for an ENEMY as well as for a party Axie. Same advisory-not-blocking
## standing as qa_anim_capture.gd / qa_action_variety_capture.gd, and the same reasons: real
## wall-clock timing and real rendered pixels.
##
## Why a separate file rather than more cases in qa_action_variety_capture.gd: that capture
## proves the CLIP choice per die-face type, and it only ever drives a PARTY uid. The lunge is
## a Tween on the unit's `slot` Node3D, it is the only motion a rigless sprite enemy gets at
## all, and nothing in this repo had ever captured an enemy mid-action. This file exists to
## close exactly that gap.
##
## SAMPLING - read this before trusting a frame count. `_CAPTURE_INTERVAL` is a FLOOR, not the
## real spacing. `Viewport.get_texture().get_image()` is a GPU->CPU readback, and under llvmpipe
## (the software GL the xvfb capture path uses) one 1920x1080 readback measured ~0.38-0.42s on
## this machine. So frames land ~0.42s apart no matter what the interval says, and the whole
## ~0.38s lunge (out 0.13 + hold 0.05 + back 0.20) fits between two of them: exactly ONE frame
## ever lands inside the motion.
##
## That is why this script also PROBES `_units[uid]` directly at each frame and prints the
## slot's live position, its distance from rest, its scale and whether the tween is running.
## The pixels prove the motion is on screen; the probe proves how far it actually went. An
## earlier pass of this audit read only the pixels, saw nine near-identical frames, and was
## about to conclude the lunge was not firing - it was, the rig just could not sample it.
## If a denser arc is ever needed, drop --resolution (readback cost scales with pixel count)
## rather than lowering _CAPTURE_INTERVAL, which does nothing.
##
## MUST run with real rendering (not --headless) — a headless viewport gives blank pixels.
## Run: xvfb-run -a -s "-screen 0 1920x1080x24" <godot> --path godot --rendering-driver opengl3 \
##          --resolution 1920x1080 res://tests/qa_lunge_capture.tscn

const _CAPTURE_INTERVAL := 0.04
const _BURST_FRAMES := 12
var _EVIDENCE_DIR := QaPaths.evidence_dir()

var _view: Node2D
var _combat: CombatEngine
var _shot_index := 0
var _stage: Node = null
var _probe_uid := -1
var _t0 := 0.0


func _ready() -> void:
	var tree := get_tree()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)

	RunState.pending_combat = {
		"node_id": "qa_lunge_capture",
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
	await tree.process_frame
	_combat = _view.get("_combat") as CombatEngine
	var stage3d = _view.get("_stage3d")
	if _combat == null or not is_instance_valid(stage3d):
		push_error("qa_lunge_capture: no combat/stage")
		tree.quit(1)
		return
	print("qa_lunge_capture: party=%d enemies=%d" % [_combat.party.size(), _combat.enemies.size()])

	var hero_uid := int(_combat.party[0].uid)
	_stage = stage3d
	var foes: Array = _combat.alive_enemies()
	if foes.is_empty():
		push_error("qa_lunge_capture: no live enemy")
		tree.quit(1)
		return
	var foe_uid := int(foes[0].uid)

	# Baseline BEFORE anything moves, so the measurement has a rest frame to diff against.
	await tree.create_timer(0.30).timeout
	_save_frame("rest", 0)

	# 1. ENEMY lunges at a party Axie — the case that had no evidence at all.
	_probe_uid = foe_uid
	_t0 = Time.get_ticks_msec() / 1000.0
	stage3d.play_action(foe_uid, "dmg", hero_uid)
	await _burst("enemy-dmg")

	await _settle(tree)
	_save_frame("rest", 1)

	# 2. Party Axie lunges at the enemy — lunge riding on top of the WalkAttack clip.
	_probe_uid = hero_uid
	_t0 = Time.get_ticks_msec() / 1000.0
	stage3d.play_action(hero_uid, "dmg", foe_uid)
	await _burst("hero-dmg")

	await _settle(tree)

	# 3. A non-lunge face on the same enemy: `shield` is not in _LUNGE_FACE_TYPES, so this must
	#    show the cast dip/rise, NOT a forward step. Captured so the two can be told apart.
	_probe_uid = foe_uid
	_t0 = Time.get_ticks_msec() / 1000.0
	stage3d.play_action(foe_uid, "shield")
	await _burst("enemy-shield")

	await _settle(tree)
	_save_frame("rest", 2)

	print("qa_lunge_capture: done, %d frame(s) -> %s" % [_shot_index, _EVIDENCE_DIR])
	tree.quit(0)


func _settle(tree: SceneTree) -> void:
	await tree.create_timer(0.60).timeout


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
	var path := "%s/%s_lunge-%s_%02d.png" % [_EVIDENCE_DIR, _today(), tag, i]
	img.save_png(path)
	_shot_index += 1
	var probe := ""
	if _stage != null and _probe_uid >= 0:
		var units: Dictionary = _stage.get("_units")
		var e: Dictionary = units.get(_probe_uid, {})
		var slot = e.get("slot")
		var rest = e.get("rest_pos", Vector3.ZERO)
		var tw = e.get("action_tween")
		var running := (tw is Tween) and (tw as Tween).is_valid() and (tw as Tween).is_running()
		if slot != null:
			probe = "  pos=%s rest=%s d=%.4f scale=%s tween_running=%s" % [
				slot.position, rest, (slot.position - rest).length(), slot.scale, running]
	print("qa_lunge_capture: saved %s t=%.3f%s" % [path, (Time.get_ticks_msec() / 1000.0) - _t0, probe])


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


func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
