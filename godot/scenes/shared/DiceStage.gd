class_name DiceStage
extends SubViewportContainer
## One skin die in its own little 3D world: Profile preview, Echo Box reveal card, thumbnail baking
## (dice/_shared.md section 10 camera and light). Transparent background, blob shadow instead of a floor.
## Live use costs one SubViewport; thumbnails are baked once per skin (DiceThumb) and reused.

const CAM_FOV := 26.0
const CAM_DIST := 4.6
const CAM_ELEV_DEG := 34.0
const CAM_TARGET := Vector3(0, 0.45, 0)
const THUMB_ROT := Vector3(-0.08, -0.42, 0.0)   # YXZ euler
const DIE_SIZE := 0.9
## Faces shown on thumbnails: dmg 6 / shield 4 / heal 3 / mana 2 / poison 2 / summon 1.
const THUMB_FACES: Array = [
	{"type": "dmg", "value": 6}, {"type": "shield", "value": 4}, {"type": "heal", "value": 3},
	{"type": "mana", "value": 2}, {"type": "poison", "value": 2}, {"type": "summon", "value": 1}]

var vp: SubViewport
var die: MeshInstance3D = null
var pivot: Node3D
var skin: String = ""
var light_tint := Color("FFF1D6")
var light_energy := 1.1


## `animated` false = held emission, no sparkles (thumbnails, Reduce flashing).
func setup(px: Vector2i, skin_id: String, faces: Array, animated: bool = true) -> void:
	skin = skin_id
	stretch = true
	custom_minimum_size = Vector2(px)
	size = Vector2(px)
	mouse_filter = Control.MOUSE_FILTER_PASS
	vp = SubViewport.new()
	vp.size = px
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if animated else SubViewport.UPDATE_ONCE
	add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	var sky := Sky.new()
	var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color("C99A63")
	pm.sky_horizon_color = Color("794225")
	pm.ground_horizon_color = Color("794225")
	pm.ground_bottom_color = Color("3E2618")
	sky.sky_material = pm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var cam := Camera3D.new()
	cam.fov = CAM_FOV
	var el := deg_to_rad(CAM_ELEV_DEG)
	cam.position = CAM_TARGET + Vector3(0, sin(el), cos(el)) * CAM_DIST
	cam.look_at_from_position(cam.position, CAM_TARGET, Vector3.UP)
	vp.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.light_color = light_tint
	sun.light_energy = light_energy
	sun.shadow_enabled = false
	vp.add_child(sun)
	sun.look_at_from_position(Vector3(2.2, 4.2, 2.6), Vector3.ZERO, Vector3.UP)
	vp.add_child(_blob())
	pivot = Node3D.new()
	pivot.position = Vector3(0, DIE_SIZE * 0.5, 0)
	pivot.rotation = Vector3.ZERO
	vp.add_child(pivot)
	die = DiceRoller3D.make_die_mesh(faces, DIE_SIZE, skin, animated)
	pivot.add_child(die)
	set_pose_thumb()


func set_pose_thumb() -> void:
	pivot.basis = Basis.from_euler(THUMB_ROT, EULER_ORDER_YXZ)


## Soft dark ellipse under the die (stands in for the 25 % shadow catcher).
func _blob() -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(1.7, 1.7)
	q.orientation = PlaneMesh.FACE_Y
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.25))
	g.set_color(1, Color(0, 0, 0, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = gt
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.position = Vector3(0, 0.005, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
