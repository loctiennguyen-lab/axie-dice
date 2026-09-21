extends Node
## Manual VISUAL QA capture for the Origins skill VFX plate (SkillVfxLayer). Advisory, not
## part of run_tests.sh — same standing and the same reasons as qa_lunge_capture.gd, whose
## header also explains why frames land ~0.42s apart under llvmpipe no matter what interval
## is asked for. A clip runs 1.5-3s, so that spacing still lands several frames inside it.
##
## Drives the REAL CombatView._on_face_used() handler rather than calling the layer directly,
## because the thing worth proving is the whole path: face part -> CombatAudio's shared
## tables -> clip key -> ranged flag -> lunge-or-plant -> the sheet drawn between two
## projected unit positions. Calling SkillVfxLayer.play() with hand-made coordinates would
## prove none of that.

const _CAPTURE_INTERVAL := 0.04
const _BURST_FRAMES := 7
var _EVIDENCE_DIR := QaPaths.evidence_dir()

var _view: Node2D
var _combat: CombatEngine
var _shot_index := 0


func _ready() -> void:
	var tree := get_tree()
	DirAccess.make_dir_recursive_absolute(_EVIDENCE_DIR)
	RunState.pending_combat = {
		"node_id": "qa_skill_vfx_capture", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": _synthetic_roster(), "relic_ids": [], "combat_seed": 13371337,
	}
	var combat_scene: Node = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(combat_scene)
	_view = combat_scene
	await tree.process_frame
	await tree.process_frame
	_combat = _view.get("_combat") as CombatEngine
	if _combat == null:
		push_error("qa_skill_vfx_capture: no combat"); tree.quit(1); return

	var hero: Unit = _combat.party[0]
	var foes: Array = _combat.alive_enemies()
	if foes.is_empty():
		push_error("qa_skill_vfx_capture: no enemy"); tree.quit(1); return
	var foe_uid := int(foes[0].uid)

	# What clip each of these resolves to is printed, so the render can be checked against the
	# mapping instead of against a guess about it.
	for probe in [["eyes", "debuff"], ["mouth", "dmg"], ["horn", "dmg"], ["tail", "poison"]]:
		var part := String(probe[0])
		var ftype := String(probe[1])
		var key := String(_view.call("_vfx_key_for", hero.uid, part, ftype))
		var ranged := SkillVfxCatalog.is_ranged(key)
		print("qa_skill_vfx_capture: part=%-6s type=%-7s -> clip=%-20s ranged=%s dur=%.2fs" % [
			part, ftype, key if key != "" else "(none)", ranged,
			SkillVfxLayer.clip_duration(key)])

	await tree.create_timer(0.30).timeout
	_save_frame("rest", 0)

	# eyes -> cast: the kit marks it ranged, so this is the "bắn chưởng" case and the Axie must
	# NOT lunge for it.
	_view.call("_on_face_used", hero.uid, "party", foe_uid, false, "eyes", "Probe", "debuff")
	await _burst("hero-cast")
	await tree.create_timer(0.8).timeout

	# mouth -> bite: melee, so the lunge stays.
	_view.call("_on_face_used", hero.uid, "party", foe_uid, false, "mouth", "Probe", "dmg")
	await _burst("hero-bite")
	await tree.create_timer(0.8).timeout

	# And the same path from the other side, on a rigless monster.
	_view.call("_on_face_used", foe_uid, "enemy", hero.uid, false, "m", "Probe", "dmg")
	await _burst("enemy-dmg")

	print("qa_skill_vfx_capture: done, %d frame(s) -> %s" % [_shot_index, _EVIDENCE_DIR])
	tree.quit(0)


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
	var path := "%s/%s_skillvfx-%s_%02d.png" % [_EVIDENCE_DIR, _today(), tag, i]
	vp.get_texture().get_image().save_png(path)
	_shot_index += 1
	print("qa_skill_vfx_capture: saved %s" % path)


func _synthetic_roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {},
			"bonus_hp": 0})
	return out


func _today() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
