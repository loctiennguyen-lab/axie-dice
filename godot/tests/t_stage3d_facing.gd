extends Node
## Regression test for the "party faces the camera instead of the enemy row" bug fix
## (CombatStage3D.gd spawn_unit() / _PARTY_FACING_Y_DEG / _ENEMY_FACING_Y_DEG).
##
## Ground truth for "which rotation.y makes a unit face away from the camera" comes from the
## vendored addon's OWN source comments (third_party/godot-axie-mixer-3d-main/examples/
## {spawner_demo,avatars_demo,collection_demo,mixer_demo}.gd all say, verbatim: "front is +Z,
## toward the camera" at rotation.y=0), not from a screenshot — a real Godot instance was
## already running as the user's own play session while this fix was written, and this
## engine's --headless mode cannot render real pixels anyway (its rendering driver is "dummy" —
## SubViewport.get_texture() returns a null texture, confirmed by a throwaway headless script
## before writing this test), so this gate checks the numeric contract instead: party units get
## rotation.y=180 (front flips from +Z to -Z, i.e. away from the +Z camera, toward the enemy row
## at the more-negative _POS_Z_ENEMY), enemy units keep rotation.y=0 (still facing the camera,
## the JRPG convention the bug report asked for on the enemy side too).
##
## Run: godot --headless --path godot tests/t_stage3d_facing.tscn
## (scene mode — CombatStage3D itself has no autoload dependency, but this project's own test
## suite standardizes on scene mode for anything requiring @onready/unique-name node lookups;
## see t_combatview_smoke.gd's file-header comment for why raw --script mode is avoided here.)

var _anomaly := ""


func _ready() -> void:
	var tree := get_tree()
	var stage: CombatStage3D = load("res://scenes/shared/CombatStage3D.tscn").instantiate()
	add_child(stage)
	await tree.process_frame   # let _ready()/_build_world() run

	# Arrange: one party unit, one enemy unit (spawn_unit() has no gameplay-state dependency —
	# it only needs uid/cls/is_enemy/slot_index/slot_count).
	stage.spawn_unit(101, "beast", false, 0, 1)
	stage.spawn_unit(202, "", true, 0, 1)

	var units: Dictionary = stage.get("_units")
	_check(units.has(101), "party unit 101 was not registered in _units")
	_check(units.has(202), "enemy unit 202 was not registered in _units")
	if _anomaly != "":
		_fail(tree)
		return

	var party_slot: Node3D = units[101]["slot"]
	var enemy_slot: Node3D = units[202]["slot"]

	# Horizontal layout: a unit's forward is local +Z, so the world direction it faces is basis * +Z.
	var party_fwd: Vector3 = party_slot.global_transform.basis * Vector3(0.0, 0.0, 1.0)
	var enemy_fwd: Vector3 = enemy_slot.global_transform.basis * Vector3(0.0, 0.0, 1.0)
	_check(party_fwd.distance_to(Vector3(1.0, 0.0, 0.0)) < 0.001,
		"party must face +X (toward the enemies on the right), faces %s" % str(party_fwd))
	_check(enemy_fwd.distance_to(Vector3(-1.0, 0.0, 0.0)) < 0.001,
		"enemies must face -X (toward the party on the left), faces %s" % str(enemy_fwd))
	_check(party_slot.position.x < enemy_slot.position.x,
		"party must stand left of the enemies (party x %f, enemy x %f)" % [party_slot.position.x, enemy_slot.position.x])

	if _anomaly == "":
		print("t_stage3d_facing: PASS — party faces +X on the left, enemy faces -X on the right")
		stage.dispose_all()
		tree.quit(0)
	else:
		_fail(tree)


func _check(cond: bool, msg: String) -> void:
	if not cond and _anomaly == "":
		_anomaly = msg


func _fail(tree: SceneTree) -> void:
	push_error("t_stage3d_facing: FAIL — %s" % _anomaly)
	print("t_stage3d_facing: FAIL — %s" % _anomaly)
	tree.quit(1)
