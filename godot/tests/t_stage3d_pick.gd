extends Node
## Regression test for the "clicking the 3D model does nothing" bug fix — covers
## CombatStage3D._pick_unit_at() (screen-space nearest-unit test, see that file's
## _CLICK_PICK_RADIUS_PX comment for why there is no physics/CollisionShape3D involved) and its
## unit_clicked signal, without depending on a rendered frame (headless can't produce real
## pixels here — SubViewport.get_texture() returns null under --headless, confirmed with a
## throwaway script before writing this — so this exercises the math directly instead).
##
## Run: godot --headless --path godot tests/t_stage3d_pick.tscn

var _anomaly := ""
var _got_uid := -999


func _on_unit_clicked(uid: int) -> void:
	_got_uid = uid


func _ready() -> void:
	var tree := get_tree()
	var stage: CombatStage3D = load("res://scenes/shared/CombatStage3D.tscn").instantiate()
	add_child(stage)
	# CombatStage3D.tscn stretches this Control to fill its parent (anchors_preset=15); reset to
	# a fixed top-left rect before forcing an explicit size, matching Viewport3D's fixed
	# internal size 1:1 — isolates _pick_unit_at()'s own nearest-point logic from the separate
	# container-size/viewport-size stretch scaling (a one-line multiply, not the risky part).
	# Size must track Viewport3D's own internal `size` (CombatStage3D.tscn) — bumped from
	# 1280x640 to 1280x720 in the review-uiux-battle-screen.md layout pass (Stage3D now fills
	# the full 16:9 screen instead of a 2:1 mid-band; see that file's report) — update both in
	# the same commit if either ever changes again, or this 1:1 isolation silently breaks.
	stage.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stage.size = Vector2(1280, 720)
	await tree.process_frame

	# Arrange: two party units side by side (spacing = CombatStage3D._ROW_SPACING) plus one
	# enemy, all alive.
	stage.spawn_unit(1, "beast", false, 0, 2)
	stage.spawn_unit(2, "plant", false, 1, 2)
	stage.spawn_unit(3, "", true, 0, 1)
	await tree.process_frame

	var units: Dictionary = stage.get("_units")
	var cam: Camera3D = stage.get("_camera")
	_check(cam != null, "CombatStage3D never built its Camera3D (_camera is null)")
	if _anomaly != "":
		_fail(tree)
		return

	# Act/Assert 1: clicking exactly on unit 1's projected screen position picks uid 1, not its
	# neighbor uid 2 (proves this is a nearest-match, not "first in dict").
	var p1: Vector2 = cam.unproject_position(
		(units[1]["slot"] as Node3D).global_transform.origin + Vector3(0.0, 0.9, 0.0))
	var picked := stage._pick_unit_at(p1)
	_check(picked == 1, "clicking exactly on unit 1's projected position picked uid=%d, want 1" % picked)

	# Act/Assert 2: same for unit 2, and for the enemy (uid 3, far row) — every spawned unit is
	# independently pickable, not just the first one registered.
	var p2: Vector2 = cam.unproject_position(
		(units[2]["slot"] as Node3D).global_transform.origin + Vector3(0.0, 0.9, 0.0))
	picked = stage._pick_unit_at(p2)
	_check(picked == 2, "clicking exactly on unit 2's projected position picked uid=%d, want 2" % picked)

	var p3: Vector2 = cam.unproject_position(
		(units[3]["slot"] as Node3D).global_transform.origin + Vector3(0.0, 0.9, 0.0))
	picked = stage._pick_unit_at(p3)
	_check(picked == 3, "clicking exactly on the enemy's projected position picked uid=%d, want 3" % picked)

	# Act/Assert 3: clicking far from every unit (a corner of the viewport) picks nothing.
	picked = stage._pick_unit_at(Vector2(5.0, 5.0))
	_check(picked == -1, "clicking an empty corner of the viewport picked uid=%d, want -1 (no hit)" % picked)

	# Act/Assert 4: a dead/hidden unit (slot.visible = false, mirrors set_alive(uid, false)'s
	# fallback-hide path) is no longer pickable even at its exact former screen position.
	stage.set_alive(2, false)
	picked = stage._pick_unit_at(p2)
	_check(picked != 2, "a hidden/dead unit's slot was still pickable (uid=2 came back)")

	# Act/Assert 5: unit_clicked signal actually fires with the right uid end-to-end through
	# _gui_input() (not just the private helper) — synthesize the same InputEventMouseButton
	# _gui_input() expects.
	stage.unit_clicked.connect(_on_unit_clicked)   # bound method, not a lambda — sidesteps any
		# ambiguity about GDScript lambda variable-capture semantics for this assertion
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = p1
	stage._gui_input(ev)
	_check(_got_uid == 1, "unit_clicked signal fired with uid=%d, want 1" % _got_uid)

	if _anomaly == "":
		print("t_stage3d_pick: PASS — screen-space nearest-unit picking + unit_clicked signal " +
			"both behave correctly")
		stage.dispose_all()
		tree.quit(0)
	else:
		_fail(tree)


func _check(cond: bool, msg: String) -> void:
	if not cond and _anomaly == "":
		_anomaly = msg


func _fail(tree: SceneTree) -> void:
	push_error("t_stage3d_pick: FAIL — %s" % _anomaly)
	print("t_stage3d_pick: FAIL — %s" % _anomaly)
	tree.quit(1)
