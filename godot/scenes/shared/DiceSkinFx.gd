class_name DiceSkinFx
extends Node
## Motion of one 3D skin die (dice/_shared.md section 8): emission pulse, rune flow, sheen, sparkles.
## Child of the die's MeshInstance3D; added by DiceRoller3D.make_die_mesh when `animated`.
##
## Pulse: every die with the same skin shares ONE body material, and the value is computed from the
## wall clock, so all of them glow in phase without a Tween per die. With MetaState.reduce_flash on (or
## animated = false: thumbnails) nothing moves: body emission is held at the spec's "fixed" value, face
## band at 0.6, no next_pass, no sparkles.

const FACE_BAND_FIXED := 0.6
const SPARKLE_FPS := 12.0
const SPARKLE_FRAMES := 8
const SPARKLE_WAIT := 0.6
const SPARKLE_SIZE := 0.14
const CORNERS: Array[Vector3] = [Vector3(0.21, 0.25, 0.21), Vector3(-0.21, 0.25, 0.21),
	Vector3(0.21, 0.25, -0.21), Vector3(-0.21, 0.25, -0.21)]

var skin: String = ""
var _body: StandardMaterial3D
var _faces: Array[StandardMaterial3D] = []
var _motion: Dictionary = {}
var _sparkles: Array[MeshInstance3D] = []
var _sparkle_corner: Array[int] = []
var _rb: RigidBody3D = null
var _moving := false
var _rb_searched := false


## Attach to `mi` (a die made by make_die_mesh with this skin). `animated` false = static mid look.
static func attach(mi: MeshInstance3D, skin_id: String, animated: bool = true) -> DiceSkinFx:
	var fx := DiceSkinFx.new()
	fx.name = "SkinFx"
	fx.skin = skin_id
	fx._body = mi.get_surface_override_material(0) as StandardMaterial3D
	for i in 6:
		fx._faces.append(mi.get_surface_override_material(i + 1) as StandardMaterial3D)
	fx._motion = (DiceSkin.info(skin_id).get("motion", {}) as Dictionary)
	fx._moving = animated and not MetaState.reduce_flash
	mi.add_child(fx)
	fx._build(mi)
	return fx


func _build(mi: MeshInstance3D) -> void:
	apply_static()
	if _moving:
		var sh := DiceSkin.sheen_material(skin) if _motion.has("sheen") else null
		_body.next_pass = sh
		if _motion.has("sparkles"):
			_make_sparkles(mi, int(_motion["sparkles"]))
	set_process(_moving)


## Held values (Reduce flashing, thumbnails): mid emission, no overlay.
func apply_static() -> void:
	if _motion.has("glow"):
		_body.emission_energy_multiplier = float((_motion["glow"] as Array)[3])
	if not _moving:
		_body.next_pass = null
		_body.uv1_offset = Vector3.ZERO
	for f in _faces:
		if f != null and f.emission_enabled:
			f.emission_energy_multiplier = FACE_BAND_FIXED


func _make_sparkles(mi: MeshInstance3D, count: int) -> void:
	var tex := DiceSkin.texture(skin, "sparkle_sheet.png")
	if tex == null:
		return
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_texture = tex
	mat.uv1_scale = Vector3(1.0 / SPARKLE_FRAMES, 1, 1)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	for i in count:
		var q := QuadMesh.new()
		q.size = Vector2(SPARKLE_SIZE, SPARKLE_SIZE)
		var m := MeshInstance3D.new()
		m.mesh = q
		m.material_override = mat.duplicate()
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.visible = false
		mi.add_child(m)
		_sparkles.append(m)
		_sparkle_corner.append(i)
		m.position = CORNERS[i % 4]


## True while the die is thrown (parked-and-frozen dice and dice without a body count as settled).
func is_tumbling() -> bool:
	if _rb == null and not _rb_searched and is_inside_tree():
		_rb_searched = true
		var n: Node = get_parent()
		while n != null and not (n is RigidBody3D):
			n = n.get_parent()
		_rb = n as RigidBody3D
	return _rb != null and is_instance_valid(_rb) and not _rb.freeze


func _process(_dt: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	if _motion.has("glow"):
		var g: Array = _motion["glow"]
		var w := 0.5 - 0.5 * cos(TAU * t / float(g[2]))
		_body.emission_energy_multiplier = lerpf(float(g[0]), float(g[1]), w)
		var b: Array = _motion.get("band", [0.35, 0.85])
		for f in _faces:
			if f != null and f.emission_enabled:
				f.emission_energy_multiplier = lerpf(float(b[0]), float(b[1]), w)
	if _motion.has("flow"):
		_body.uv1_offset = Vector3(0, fposmod(t / float(_motion["flow"]), 1.0), 0)
	if _motion.has("sheen") and _body.next_pass is StandardMaterial3D:
		(_body.next_pass as StandardMaterial3D).uv1_offset = Vector3(fposmod(t / float(_motion["sheen"]), 1.0), 0, 0)
	_step_sparkles(t)


func _step_sparkles(t: float) -> void:
	var hide := is_tumbling()
	var cycle := float(SPARKLE_FRAMES) / SPARKLE_FPS + SPARKLE_WAIT
	for i in _sparkles.size():
		var s := _sparkles[i]
		var lt := t + float(i) * cycle / float(_sparkles.size())
		var k := int(floor(lt / cycle))
		var local := lt - float(k) * cycle
		if hide or local >= float(SPARKLE_FRAMES) / SPARKLE_FPS:
			s.visible = false
			continue
		s.position = CORNERS[(k + i) % 4]
		(s.material_override as StandardMaterial3D).uv1_offset = Vector3(float(int(local * SPARKLE_FPS)) / SPARKLE_FRAMES, 0, 0)
		s.visible = true
