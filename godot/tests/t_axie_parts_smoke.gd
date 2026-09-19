extends Node
## Headless regression test for CombatStage3D's part-mixing (godot-port task: "Axie chỉ là
## THÂN TRƠN — thêm part hợp lý cho mỗi class"). Verifies AxieDescriptor.parts is populated
## with a full 6-slot set (Mouth/Horn/Back/Tail/Ear/Eye — CombatStage3D._PART_TYPES order) for
## every hero class, and that each part actually resolved to a real catalog asset (not just
## "no crash" — AxiePartResolver.resolve()["ok"] must be true, meaning AxieFactory found a real
## glb and did not silently skip the slot).
##
## Isolated from CombatEngine/RunState/Combat.tscn entirely (test-standards.md: "Unit tests
## must not depend on external state") — instantiates CombatStage3D.tscn directly and drives
## its public spawn_unit() API, exactly like a CombatView would, with a synthetic uid/slot.
## AxieMixerBoot (project autoload, project.godot) has already assigned AxieFactory.default_factory
## by the time this scene's _ready() runs, same guarantee t_combatview_smoke.gd relies on.
##
## Run: godot --headless --path godot tests/t_axie_parts_smoke.tscn

const _STAGE_SCENE := "res://scenes/shared/CombatStage3D.tscn"

## Mirrors CombatStage3D._CLASS_PART_CLASS — kept as a literal copy (not a reference into the
## scene under test) so this test still catches an accidental typo/rename in that mapping.
const _EXPECTED_PART_CLASS := {
	"plant": "Plant", "beast": "Beast", "aqua": "Aquatic",
	"reptile": "Reptile", "bug": "Bug", "bird": "Bird",
}
const _EXPECTED_PART_TYPE_NAMES := ["Mouth", "Horn", "Back", "Tail", "Ear", "Eye"]

var _anomaly := ""


func _ready() -> void:
	var tree := get_tree()
	await tree.process_frame   # let AxieMixerBoot's own onready wiring settle (see file header)

	var stage: Node = (load(_STAGE_SCENE) as PackedScene).instantiate()
	add_child(stage)
	await tree.process_frame   # CombatStage3D._ready() builds _world/_viewport on this frame

	# Act + Assert, per hero class: spawn_unit() must produce a real AxieCharacter3D whose
	# resolved descriptor carries all 6 part slots, each pointing at a real catalog asset.
	var uid := 1
	for cls in _EXPECTED_PART_CLASS.keys():
		_check_class_has_full_parts(stage, cls, uid)
		uid += 1

	# Non-hero enemy (ContentDB "slime": cls=="") must NOT crash and must stay a plain body —
	# same documented fallback as before this change, not a new failure mode.
	_check_empty_class_has_no_parts(stage, uid)
	uid += 1

	stage.call("dispose_all")

	if _anomaly == "":
		print("t_axie_parts_smoke: PASS — all 6 hero classes spawn with a resolved 6-slot part set; non-hero cls=='' stays plain-body")
		tree.quit(0)
	else:
		push_error("t_axie_parts_smoke: FAIL — %s" % _anomaly)
		tree.quit(1)


func _check_class_has_full_parts(stage: Node, cls: String, uid: int) -> void:
	stage.call("spawn_unit", uid, cls, false, 0, 1)
	var units: Dictionary = stage.get("_units")
	var entry: Dictionary = units.get(uid, {})
	if entry.is_empty():
		_anomaly = "cls=%s: spawn_unit() did not register a unit entry" % cls
		return
	var character: AxieCharacter3D = entry.get("character")
	if character == null or character.descriptor == null:
		_anomaly = "cls=%s: no AxieCharacter3D/descriptor built (placeholder capsule path taken?)" % cls
		return

	var parts: Array = character.descriptor.parts
	if parts.size() != _EXPECTED_PART_TYPE_NAMES.size():
		_anomaly = "cls=%s: expected %d parts, got %d" % [
			cls, _EXPECTED_PART_TYPE_NAMES.size(), parts.size()]
		return

	var seen_type_names: Array = []
	var factory: AxieFactory = AxieFactory.default_factory
	for part in parts:
		var p: AxiePartDescriptor = part
		var type_name := AxieTypes.part_name(p.type)
		seen_type_names.append(type_name)
		if p.part_class != _EXPECTED_PART_CLASS[cls]:
			_anomaly = "cls=%s: part_class=%s does not match expected %s for slot %s" % [
				cls, p.part_class, _EXPECTED_PART_CLASS[cls], type_name]
			return
		var resolved := factory.resolve_part(p)
		if not bool(resolved.get("ok", false)):
			_anomaly = "cls=%s slot=%s: AxiePartResolver could not resolve a real asset (%s)" % [
				cls, type_name, resolved.get("name", "?")]
			return

	for expected_name in _EXPECTED_PART_TYPE_NAMES:
		if not seen_type_names.has(expected_name):
			_anomaly = "cls=%s: missing expected slot %s (got %s)" % [cls, expected_name, seen_type_names]
			return

	# Visual proof the resolved parts actually attached real meshes to the body, not just that
	# the descriptor "looks" full — character.root must have MeshInstance3D children beyond
	# just the bare body (a plain-body Axie already has 1 from the body glb itself).
	var mesh_count := AxieFactory.all_mesh_instances(character.root).size()
	if mesh_count < 2:
		_anomaly = "cls=%s: only %d MeshInstance3D under root after spawn — parts did not attach visually" % [
			cls, mesh_count]


func _check_empty_class_has_no_parts(stage: Node, uid: int) -> void:
	stage.call("spawn_unit", uid, "", true, 0, 1)
	var units: Dictionary = stage.get("_units")
	var entry: Dictionary = units.get(uid, {})
	if entry.is_empty():
		_anomaly = "cls=(empty): spawn_unit() did not register a unit entry"
		return
	var character: AxieCharacter3D = entry.get("character")
	if character == null or character.descriptor == null:
		return   # placeholder capsule fallback is also an acceptable "no crash" outcome here
	if not character.descriptor.parts.is_empty():
		_anomaly = "cls=(empty): expected 0 parts (no Mech part set exists in the catalog), got %d" % \
			character.descriptor.parts.size()
