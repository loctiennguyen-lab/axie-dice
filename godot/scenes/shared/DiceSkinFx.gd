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
var _was_tumbling := false
var _boost := 1.0   ## emission multiplier of the Mythic settle moment (1 = off)
var _settled_once := false


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
		_body.emission_energy_multiplier = lerpf(float(g[0]), float(g[1]), w) * _boost
		var b: Array = _motion.get("band", [0.35, 0.85])
		for f in _faces:
			if f != null and f.emission_enabled:
				f.emission_energy_multiplier = lerpf(float(b[0]), float(b[1]), w)
	if _motion.has("flow"):
		_body.uv1_offset = Vector3(0, fposmod(t / float(_motion["flow"]), 1.0), 0)
	if _motion.has("sheen") and _body.next_pass is StandardMaterial3D:
		(_body.next_pass as StandardMaterial3D).uv1_offset = Vector3(fposmod(t / float(_motion["sheen"]), 1.0), 0, 0)
	_step_sparkles(t)
	var tum := is_tumbling()
	if _was_tumbling and not tum and not _settled_once and _rb != null and _motion.has("settle"):
		_settled_once = true
		play_settle(_rb.get_parent() as Node3D, _rb.global_position, 0.0)
	_was_tumbling = tum


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


## Mythic settle moment (<= 0.6 s, one shot; never with Reduce flashing). Moon: floor halo + emission x2.
## Red crystal: emission x1 -> x2.8 -> x1 and six shards. Effect nodes are added to `host` at `at` and free
## themselves; they do not delay anything (the 2D tile flies meanwhile).
func play_settle(host: Node3D, at: Vector3, floor_y: float) -> void:
	if not _moving or host == null or not _motion.has("settle"):
		return
	var kind := String(_motion["settle"])
	var peak := 2.0 if kind == "halo" else 2.8
	var tw := create_tween()
	tw.tween_property(self, "_boost", peak, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_boost", 1.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	if kind == "halo":
		var tx := DiceSkin.texture(skin, "settle_halo.png")
		if tx == null:
			return
		var q := QuadMesh.new()
		q.size = Vector2(1.2, 1.2)
		q.orientation = PlaneMesh.FACE_Y
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_texture = tx
		m.albedo_color = Color(1, 1, 1, 0.9)
		var halo := MeshInstance3D.new()
		halo.mesh = q
		halo.material_override = m
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		host.add_child(halo)
		halo.global_position = Vector3(at.x, floor_y + 0.02, at.z)
		halo.scale = Vector3.ONE * 0.6
		var ht := halo.create_tween().set_parallel(true)
		ht.tween_property(halo, "scale", Vector3.ONE * 1.8, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		ht.tween_property(m, "albedo_color:a", 0.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		ht.chain().tween_callback(halo.queue_free)
	else:
		var tx2 := DiceSkin.texture(skin, "settle_shard.png")
		if tx2 == null:
			return
		var p := CPUParticles3D.new()
		p.one_shot = true
		p.amount = 6
		p.lifetime = 0.5
		p.explosiveness = 1.0
		p.direction = Vector3.UP
		p.spread = 70.0
		p.initial_velocity_min = 1.2
		p.initial_velocity_max = 1.8
		p.gravity = Vector3(0, -6, 0)
		var q2 := QuadMesh.new()
		q2.size = Vector2(0.12, 0.12)
		var m2 := StandardMaterial3D.new()
		m2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m2.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m2.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m2.albedo_texture = tx2
		q2.material = m2
		p.mesh = q2
		host.add_child(p)
		p.global_position = at
		p.emitting = true
		p.get_tree().create_timer(0.7).timeout.connect(p.queue_free)
