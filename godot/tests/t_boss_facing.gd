extends Node
## Hard rule (Liam, 20/10): every 3D boss always faces the party Axies in combat. For each boss key whose
## atia registry entry is a 3D model, build the real stage with a full party, spawn the boss in its slot and
## check that the model's forward (local +Z, the engine convention for these rigs) points at the party centre
## within 15 degrees. Sprite bosses are skipped. Data-driven: new Chimera/Brine bosses are covered by BOSS_KEYS.
## Run: godot --headless --path godot res://tests/t_boss_facing.tscn
const MAX_DEG := 15.0
const CLASSES := ["plant", "beast", "aquatic", "reptile", "bug"]

var _checks := 0
var _fails: Array[String] = []


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	print("=== t_boss_facing: start ===")
	var tested := 0
	for key in MonsterArt.BOSS_KEYS:
		var reg := MonsterArt.resolve(String(key), true)
		if String(reg.get("kind", "")) != "glb":
			continue
		tested += 1
		await _case(String(key))
	_check(tested >= 4, "at least the 4 Chimera bosses are 3D (got %d)" % tested)
	for f in _fails:
		print("t_boss_facing: FAIL - %s" % f)
	if _fails.is_empty():
		print("t_boss_facing: PASS - %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)


func _case(key: String) -> void:
	var stage: CombatStage3D = load("res://scenes/shared/CombatStage3D.tscn").instantiate()
	add_child(stage)
	stage.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stage.size = Vector2(1920, 1080)
	await get_tree().process_frame
	stage.frame_band(1080.0, 140.4, 876.0)
	stage.set_encounter_kind("boss")
	stage.set_arena("savannah", true)
	var party: Array = []
	for i in 5:
		stage.spawn_unit(i + 1, CLASSES[i], false, i, 5)
		party.append(i + 1)
	stage.spawn_unit(100, "", true, 0, 1, true, key)
	stage.reseat_side(party, false)
	stage.reseat_side([100], true)
	for _i in 3:
		await get_tree().process_frame
	var boss: Dictionary = stage._units.get(100, {})
	var atia: Dictionary = boss.get("atia", {})
	var model: Node3D = atia.get("node") as Node3D
	_check(model != null, "%s: 3D model was built in combat" % key)
	if model != null:
		var centre := Vector3.ZERO
		for uid in party:
			centre += (stage._units[uid]["slot"] as Node3D).global_position
		centre /= float(party.size())
		var to_party := centre - (boss["slot"] as Node3D).global_position
		to_party.y = 0.0
		var fwd := model.global_transform.basis.z
		fwd.y = 0.0
		var ang := rad_to_deg(fwd.normalized().angle_to(to_party.normalized()))
		print("t_boss_facing: %s faces party within %.1f deg" % [key, ang])
		_check(ang <= MAX_DEG, "%s: model forward is %.1f deg off the party centre (max %.0f)" % [key, ang, MAX_DEG])
	stage.dispose_all()
	stage.queue_free()
	await get_tree().process_frame
