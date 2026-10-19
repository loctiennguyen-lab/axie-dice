class_name VenomPool
extends Node3D
## Poison pool plus low venom mist around the waist of the Venom Chimera (a bust: the mesh ends in a
## flat cut). Child of the model, so it moves, scales and fades with it (the Dead clip sinks the body
## into the pool; the slot's scale-to-zero takes the pool away with the unit). Presentation only.
## Cost: two small meshes, one fragment shader, no particles, no textures.
## Reduce flashing (MetaState.reduce_flash): the mist stops drifting, the pool stops moving.

const SHADER := preload("res://resources/shaders/venom_pool.gdshader")
const CUT_FRAC := 0.095       ## waist cut height as a fraction of the model height (above its lowest point)
const POOL_R_FRAC := 0.30     ## pool radius / model height
const MIST_R_FRAC := 0.24     ## mist tube radius / model height
const MIST_H_FRAC := 0.24     ## mist tube height / model height


## True for the models that need a pool (the Venom Chimera only).
static func wants(model_path: String) -> bool:
	return model_path.contains("chimera_venom")


## Adds a VenomPool to `model` (already in the tree, untransformed or fitted: sizes come from its
## local-space bounds, so the fit scale carries over). Returns the node, null if the model has no mesh.
static func attach(model: Node3D, reduced_motion: bool) -> VenomPool:
	var box := CombatStage3D._model_aabb(model)
	if box.size.y < 0.05:
		return null
	var pool := VenomPool.new()
	pool.name = "VenomPool"
	var h := box.size.y
	var cut_y := box.position.y + h * CUT_FRAC
	var c := box.get_center()
	pool.position = Vector3(c.x, cut_y, c.z)
	var motion := 0.0 if reduced_motion else 1.0
	pool._build(h, motion)
	model.add_child(pool)
	return pool


func _build(h: float, motion: float) -> void:
	var disc := MeshInstance3D.new()
	disc.name = "Pool"
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * h * POOL_R_FRAC * 2.0
	disc.mesh = plane
	disc.position.y = h * 0.012
	disc.material_override = _mat(0, motion, 0.95, 1.0)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)
	var mist := MeshInstance3D.new()
	mist.name = "Mist"
	var tube := CylinderMesh.new()
	tube.top_radius = h * MIST_R_FRAC
	tube.bottom_radius = h * MIST_R_FRAC * 1.25
	tube.height = h * MIST_H_FRAC
	tube.radial_segments = 20
	tube.rings = 1
	tube.cap_top = false
	tube.cap_bottom = false
	mist.mesh = tube
	mist.position.y = h * MIST_H_FRAC * 0.5
	mist.material_override = _mat(1, motion, 1.0, 2.0)
	mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mist)


static func _mat(mode: int, motion: float, strength: float, seed_v: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("mode", mode)
	m.set_shader_parameter("motion", motion)
	m.set_shader_parameter("strength", strength)
	m.set_shader_parameter("seed", seed_v)
	return m
