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
	set_process(false)


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


# --- live preview: spin, drag, equip hop, reveal drop ---------------------------------------------

const TURN_S := 12.0          ## full turn; x makes 1 turn and y 2 turns per TURN_S so all six faces show
const DRAG_RAD_PER_PX := 0.012
const DRAG_RESUME_S := 2.0
const DROP_FROM := 3.2
const DROP_S := 0.62
const BOUNCE_S := 0.30

var spinning := false
var _t := 0.0
var _drag := Vector2.ZERO          # accumulated drag rotation (x = pitch, y = yaw)
var _dragging := false
var _resume_at := 0.0              # seconds of spin left paused after a release
var _busy := false                 # equip hop / drop running: the spin does not touch the pivot


## The faces of the Axie in team preset slot 1 (confirmed by Design); the first hero die as a fallback,
## then the thumbnail faces. Always 6 {type, value}.
static func preview_faces() -> Array:
	var key := ""
	if not MetaState.team_presets.is_empty():
		for k in ((MetaState.team_presets[0] as Dictionary).get("party", []) as Array):
			if String(k) != "" and ContentDB.heroes.has(String(k)):
				key = String(k)
				break
	if key == "":
		for k in ContentDB.heroes:
			key = String(k)
			break
	if key != "":
		var die: Array = (ContentDB.heroes[key] as Dictionary).get("die", [])
		if die.size() >= 6:
			var out: Array = []
			for i in 6:
				out.append({"type": String((die[i] as Dictionary).get("type", "blank")),
					"value": FaceAmount.display_value(die[i] as Dictionary, int((die[i] as Dictionary).get("value", 0)))})
			return out
	return THUMB_FACES


## Pose with the +Z face (index 4) turned to the camera (the settled pose of the reveal).
func settled_basis() -> Basis:
	var to_cam := (vp.get_camera_3d().global_position - pivot.global_position).normalized()
	return DiceRoller3D.result_basis(Basis.IDENTITY, 4, to_cam, Vector3.UP)


## Slow auto-spin with drag-to-spin. Reduce flashing: held at the settled pose, drag still works.
func start_spin() -> void:
	spinning = true
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	mouse_filter = Control.MOUSE_FILTER_STOP
	if MetaState.reduce_flash:
		pivot.basis = settled_basis()
	set_process(true)


func _gui_input(ev: InputEvent) -> void:
	if not spinning:
		return
	if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_dragging = (ev as InputEventMouseButton).pressed
		if not _dragging:
			_resume_at = DRAG_RESUME_S
		accept_event()
	elif ev is InputEventMouseMotion and _dragging:
		var rel := (ev as InputEventMouseMotion).relative
		_apply_drag(rel)
		accept_event()


## Pointer delta x 0.012 rad/px: horizontal drags yaw, vertical drags pitch.
func _apply_drag(rel: Vector2) -> void:
	var rot := Basis(Vector3.UP, rel.x * DRAG_RAD_PER_PX) * Basis(Vector3.RIGHT, rel.y * DRAG_RAD_PER_PX)
	pivot.basis = (rot * pivot.basis).orthonormalized()


func _process(dt: float) -> void:
	if not spinning or _busy or pivot == null:
		return
	if _dragging:
		return
	if _resume_at > 0.0:
		_resume_at -= dt
		return
	if MetaState.reduce_flash:
		return
	var w := TAU / TURN_S
	# rate form (x at 1 turn, y at 2 turns per 12 s) so a drag offset is kept
	pivot.basis = (Basis(Vector3.UP, 2.0 * w * dt) * Basis(Vector3.RIGHT, w * dt) * pivot.basis).orthonormalized()


## 49-equip-moment: one extra 360 degree yaw plus a 0.12 m hop over 400 ms (TRANS_CUBIC EASE_OUT).
## Reduce flashing: no move.
func play_equip() -> void:
	if MetaState.reduce_flash or _busy:
		return
	_busy = true
	var base := pivot.basis
	var y0 := pivot.position.y
	var tw := create_tween()
	tw.tween_method(func(w: float) -> void:
		pivot.basis = Basis(Vector3.UP, TAU * w) * base
		pivot.position.y = y0 + 0.12 * sin(PI * w), 0.0, 1.0, 0.4) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		pivot.basis = base
		pivot.position.y = y0
		_busy = false)


## 20-echo-box: the die falls from 3.2 m, lands at 620 ms, one 300 ms bounce, settles on the +Z pose.
## Mythic skins run their settle moment on landing. Reduce flashing: shown settled at once, no settle moment.
## Emits `landed` when it rests.
signal landed


func play_drop() -> void:
	var rest := settled_basis()
	var y_rest := pivot.position.y
	if MetaState.reduce_flash or DisplayServer.get_name() == "headless":
		pivot.basis = rest
		landed.emit()
		return
	_busy = true
	var start := Basis.from_euler(Vector3(1.1, 0.6, -0.8))
	var qa := start.get_rotation_quaternion()
	var qb := rest.get_rotation_quaternion()
	pivot.position.y = y_rest + DROP_FROM
	pivot.basis = start
	var tw := create_tween()
	tw.tween_method(func(w: float) -> void:
		pivot.position.y = y_rest + DROP_FROM * (1.0 - w * w)
		pivot.basis = Basis(qa.slerp(qb, minf(w * 1.0, 1.0)) * Quaternion(Vector3.UP, TAU * 2.0 * (1.0 - w))),
		0.0, 1.0, DROP_S)
	tw.tween_callback(func() -> void:
		var fx := die.get_node_or_null("SkinFx") as DiceSkinFx
		if fx != null:
			fx.play_settle(pivot.get_parent() as Node3D, pivot.global_position, 0.0))
	tw.tween_method(func(w: float) -> void:
		pivot.position.y = y_rest + 0.25 * sin(PI * w), 0.0, 1.0, BOUNCE_S)
	tw.tween_callback(func() -> void:
		pivot.position.y = y_rest
		pivot.basis = rest
		_busy = false
		landed.emit())
