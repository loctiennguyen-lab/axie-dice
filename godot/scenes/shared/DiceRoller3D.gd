extends Node
class_name DiceRoller3D
## 3D dice throw (UI-03 handoff, motion.md "Combat · dice roll"). PURELY VISUAL.
##
## The value on every die is the one the caller passes in (combat engine / epoch source). Physics
## decides where a cube lands and how it bounces, never what it shows: each die is the unit's real
## six-face die (one texture per mesh surface) and in the last 180 ms of the settle it is turned so
## the engine's RESULT face looks at the camera. Nothing here touches the combat engine,
## and the random faces shown while tumbling come from a PRIVATE RandomNumberGenerator, never the
## game's rng.
##
## Owned by CombatStage3D (which calls setup()). Decoupled from the HUD: the caller passes a
## `tray_target` Callable(index) -> Vector2 (centre of that die's tray slot, in the stage Control's
## local space, the same space CombatStage3D.get_unit_screen_pos() returns).
##
## Timeline per die i: wait 110 ms x i, throw from the unit toward the stage centre (480 ms
## flight), squash on the first bounce (300 ms, crit 1.22/0.78), tumble faces for ~1.08 s, settle
## (180 ms hold), then a 2D tile flies to the tray slot (240 ms). A crit landing shakes the camera
## +-6 px in 3 steps. At most 11 bodies, a box collider each, all freed when the die leaves.
##
## Skip path (no physics, no tween): headless runs, `reduced_motion`, or skip() (click on the stage
## while dice fly). Every die jumps to its tray slot; signals still fire, in order.

## Die `i` came to rest on the stage (value already locked).
signal die_settled(i: int)
## Die `i` reached its tray slot (the HUD can now show its own card).
signal die_arrived(i: int)
## Every die of the current roll arrived. Emitted once per roll().
signal all_arrived

const MAX_DICE := 11
const STAGGER := 0.110
const FLIGHT := 0.480
const LAND_CENTER_X := 3.0   ## world x the dice fan out around (between the teams)
const LAND_Z := 7.0          ## world z of the first landing line (the open floor in front of both teams)
const TUMBLE_STEP := 0.090
const TUMBLE_TOTAL := 1.080
const SQUASH_TIME := 0.300
const SETTLE_HOLD := 0.180
const FLY_TIME := 0.240
const SHAKE_PX := 6.0
const SHAKE_STEP := 0.080
const SETTLE_TIMEOUT := 2.4
const TILE_BIG := 88.0
const TILE_SMALL := 56.0
const IVORY := Color("FFE5B4")      # token kam-9
const INK := Color("291808")        # token kam-1
const _DIE_SCENE := preload("res://assets/dice/axie_die.glb")
const _MESH_SIZE := 0.5            # axie_die.glb is a 0.5 m rounded cube
const BODY_COLOR := Color("F3D7A6")
const PLATE_PX := 256
## Face index i of a unit's die -> mesh surface i+1 (Face_+X, -X, +Y, -Y, +Z, -Z) -> local normal.
const FACE_NORMALS: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN,
	Vector3.BACK, Vector3.FORWARD]
## Local "up" of each face's texture (+Y top uses -Z as up, per the model notes).
const FACE_UPS: Array[Vector3] = [Vector3.UP, Vector3.UP, Vector3.FORWARD, Vector3.BACK,
	Vector3.UP, Vector3.UP]
const _TYPE_RING := {
	"dmg": Color("B81221"), "shield": Color("1E8FBF"), "poison": Color("7A3FB5"),
	"heal": Color("2E9E2C"), "debuff": Color("E07A1F"), "buff": Color("C98A1E"),
	"mana": Color("8A5CE0"), "summon": Color("1FA89A"), "blank": Color("8A8F99"),
}
static var _tex_cache: Dictionary = {}   # "type:value" (no skin) or "skin|type:value" -> ImageTexture
## Skin face layout (cosmetics R2, dice/_shared.md section 3). All in 256 px plate space.
const GLYPH_BOX := Rect2(68, 28, 120, 120)
const VALUE_BOX := Rect2(82, 164, 92, 60)
const SKIN_INK := Color("2B1E17")   # neutral-1, the value ink on skin faces
const VALUE_FONT := 80
const VALUE_FONT_MIN := 44
const VALUE_BASELINE := 222.0
const BLANK_BAR := Rect2(108, 189, 40, 10)
const _LAYER_DIE := 1 << 18
const _LAYER_GROUND := 1 << 19

## Set true for reduce-motion: dice appear in the tray at once. Headless always skips.
var reduced_motion: bool = false

var _world: Node3D
var _camera: Camera3D
var _stage: Control
var _tile_layer: Control
var _ground: StaticBody3D
var _dice: Array[Dictionary] = []
var _active: bool = false
var _rng := RandomNumberGenerator.new()
var _shake_tween: Tween
var _tray_target: Callable
var _arrived_count: int = 0
var _roll_token: int = 0
var _gen: int = 0   # bumped by every roll()/_clear(); late tween callbacks of an old roll check it


## `world` holds the bodies, `camera` is the stage camera, `stage` is the Control that owns the
## viewport (flying tiles live inside it).
func setup(world: Node3D, camera: Camera3D, stage: Control) -> void:
	_world = world
	_camera = camera
	_stage = stage
	set_process(false)


func is_rolling() -> bool:
	return _active


## True when roll() will take the skip path right now.
func will_skip() -> bool:
	return reduced_motion or DisplayServer.get_name() == "headless" \
		or _world == null or _camera == null or not is_inside_tree()


## entries: Array of {slot_node: Node3D, face_type: String, value: int, crit: bool, small: bool (opt),
## faces: Array of 6 {type, value} (the unit's real die, index = engine face index, optional),
## result_index: int (which of the 6 is the result, optional, default 0)}.
## Index in `entries` = die index in the signals and in `tray_target`.
func roll(entries: Array, tray_target: Callable) -> void:
	if _active:
		skip()
	_clear()
	_tray_target = tray_target
	_arrived_count = 0
	var n := mini(entries.size(), MAX_DICE)
	if n == 0:
		_active = false
		call_deferred("_emit_all_arrived")
		return
	_active = true
	_rng.seed = 90 + n   # private, fixed: only the throw spread and the tumble glyphs use it
	var skipping := will_skip()
	for i in n:
		var e: Dictionary = entries[i]
		_dice.append({
			"i": i, "face_type": String(e.get("face_type", "blank")), "value": int(e.get("value", 0)),
			"crit": bool(e.get("crit", false)), "small": bool(e.get("small", false)),
			"skin": _skin_of(e), "faces": _faces_of(e), "result_index": clampi(int(e.get("result_index", 0)), 0, 5),
			"slot": e.get("slot_node"), "phase": 0, "t": 0.0, "air": 0.0, "tnext": 0.0,
			"locked": false, "settled": false, "bounced": false,
			"body": null, "pivot": null, "face": null, "glyph": null, "num": null, "tile": null,
		})
	var in_use: Array = []
	for d in _dice:
		in_use.append(String(d["skin"]))
	free_plates_except(in_use)   # only the skins of this roll keep their faces in memory
	DiceSkin.release_except(in_use)
	DiceSkin.release_materials_except(in_use)
	if skipping:
		call_deferred("_skip_all")
		return
	_roll_token += 1
	_begin_physics(_roll_token)


## Cache key of one face texture. The skin id is part of it, so two skins never share a plate.
static func _key(f: Dictionary, skin: String = "") -> String:
	var k := "%s:%d" % [String(f.get("type", "blank")), int(f.get("value", 0))]
	return k if skin == "" else "%s|%s" % [skin, k]


## Skin of one throw entry: its own "skin", else the equipped one. "" = today's plain die.
static func _skin_of(e: Dictionary) -> String:
	var s := String(e.get("skin", MetaState.equipped_die_skin))
	return s if DiceSkin.has(s) else ""


## Largest Rowdies size (<= 80, >= 44) at which `text` fits `box_w` px, from real font metrics.
static func fit_value_font(text: String, font: Font, box_w: float = VALUE_BOX.size.x) -> int:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, VALUE_FONT).x
	if w <= box_w:
		return VALUE_FONT
	return clampi(floori(float(VALUE_FONT) * box_w / w), VALUE_FONT_MIN, VALUE_FONT)


## Free every cached plate of skins other than `keep` (the plain die "" is never freed).
static func free_plates_except(keep: Array) -> void:
	for k in _tex_cache.keys():
		var s := String(k).get_slice("|", 0) if String(k).contains("|") else ""
		if s != "" and not keep.has(s):
			_tex_cache.erase(k)


## The textured die (body + one plate per surface). `faces` = 6 {type, value}; textures must be in
## the cache already (see prepare()).
## `animated` false = held emission, no sheen / sparkles (thumbnails, tests).
static func make_die_mesh(faces: Array, size: float, skin: String = "", animated: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _die_mesh()
	mi.scale = Vector3.ONE * (size / _MESH_SIZE)
	if skin != "" and DiceSkin.has(skin):
		mi.set_surface_override_material(0, DiceSkin.body_material(skin))
		for fi in 6:
			mi.set_surface_override_material(fi + 1,
				DiceSkin.face_material(skin, _tex_cache.get(_key(faces[fi], skin))))
		DiceSkinFx.attach(mi, skin, animated)
		return mi
	var bm := StandardMaterial3D.new()
	bm.albedo_color = BODY_COLOR
	bm.roughness = 0.4
	mi.set_surface_override_material(0, bm)
	for fi in 6:
		var fm := StandardMaterial3D.new()
		fm.albedo_texture = _tex_cache.get(_key(faces[fi], skin))
		fm.roughness = 0.4
		mi.set_surface_override_material(fi + 1, fm)
	return mi


## Draw (and cache) the plates for these "type:value" keys. Await it.
func prepare(faces: Array, skin: String = "") -> void:
	var keys: Array = []
	for f in faces:
		keys.append(_key(f, skin))
	await _ensure_textures(keys)


static func _die_mesh() -> Mesh:
	var inst := _DIE_SCENE.instantiate()
	var found: Mesh = null
	var stack: Array = [inst]
	while not stack.is_empty() and found == null:
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			found = (n as MeshInstance3D).mesh
		stack.append_array(n.get_children())
	inst.free()
	return found


## Draws every missing "type:value" plate into one SubViewport, one frame, then caches each as a
## texture (cache is shared by all dice and all rolls). Plate = ivory kam-9 rounded square on the body
## colour, a thin ring in the type colour, the glyph, the value.
func _ensure_textures(keys: Array) -> void:
	var missing: Array[String] = []
	for k in keys:
		if not _tex_cache.has(k) and not missing.has(k):
			missing.append(k)
	if missing.is_empty():
		return
	var cols := 8
	var rows := ceili(float(missing.size()) / cols)
	var vp := SubViewport.new()
	vp.size = Vector2i(PLATE_PX * cols, PLATE_PX * rows)
	vp.transparent_bg = false
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var root := Control.new()
	root.size = Vector2(vp.size)
	vp.add_child(root)
	for idx in missing.size():
		var skin_id := ""
		var tv: String = missing[idx]
		if tv.contains("|"):
			skin_id = tv.get_slice("|", 0)
			tv = tv.get_slice("|", 1)
		var parts: PackedStringArray = tv.split(":")
		root.add_child(_plate(parts[0], int(parts[1]),
			Vector2((idx % cols) * PLATE_PX, (idx / cols) * PLATE_PX), skin_id))
	add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	for idx in missing.size():
		var r := Rect2i((idx % cols) * PLATE_PX, (idx / cols) * PLATE_PX, PLATE_PX, PLATE_PX)
		var tile_img := img.get_region(r)
		tile_img.generate_mipmaps()
		_tex_cache[missing[idx]] = ImageTexture.create_from_image(tile_img)


func _plate(type: String, value: int, at: Vector2, skin: String = "") -> Control:
	if skin != "":
		return _skin_plate(type, value, at, skin)
	var bg := ColorRect.new()
	bg.color = BODY_COLOR
	bg.position = at
	bg.size = Vector2(PLATE_PX, PLATE_PX)
	var plate := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = IVORY
	sb.set_corner_radius_all(40)
	sb.set_border_width_all(8)
	sb.border_color = _TYPE_RING.get(type, _TYPE_RING["blank"])
	plate.add_theme_stylebox_override("panel", sb)
	plate.position = Vector2(14, 14)
	plate.size = Vector2(PLATE_PX - 28, PLATE_PX - 28)
	bg.add_child(plate)
	var icon := TextureRect.new()
	icon.texture = UI3.icon(String(UI3.FACE_ICON[TrayColumn.ui3_face(type)]))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var has_value := value > 0
	# Like the tray tile: glyph centred at ~55% of the plate, value bottom-right, all upright in UV.
	var g := PLATE_PX * 0.62
	icon.size = Vector2(g, g)
	icon.position = Vector2((PLATE_PX - g) * 0.5, (PLATE_PX - g) * 0.5 - (6.0 if has_value else 0.0))
	bg.add_child(icon)
	if has_value:
		var lbl := Label.new()
		lbl.text = str(value)
		lbl.add_theme_font_override("font", UI3Theme.font_display())
		lbl.add_theme_font_size_override("font_size", 72)
		lbl.add_theme_color_override("font_color", INK)
		lbl.add_theme_color_override("font_outline_color", IVORY)
		lbl.add_theme_constant_override("outline_size", 10)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl.size = Vector2(110, 90)
		lbl.position = Vector2(PLATE_PX - 110 - 30, PLATE_PX - 90 - 24)
		bg.add_child(lbl)
	return bg


## Skin face: the skin's plate.png, then (game) ring stroke, glyph, value. Order and numbers from
## dice/_shared.md section 3: ring inset 14 / 8 px / r 40 stroke only, glyph box (68,28)-(188,148), value box
## (82,164)-(174,224) Rowdies 700 INK, no outline, auto-fit to the box width, blank = INK bar.
func _skin_plate(type: String, value: int, at: Vector2, skin: String) -> Control:
	var bg := TextureRect.new()
	bg.texture = DiceSkin.texture(skin, "plate.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.position = at
	bg.size = Vector2(PLATE_PX, PLATE_PX)
	var ring := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_corner_radius_all(40)
	sb.set_border_width_all(8)
	sb.border_color = _TYPE_RING.get(type, _TYPE_RING["blank"])
	ring.add_theme_stylebox_override("panel", sb)
	ring.position = Vector2(14, 14)
	ring.size = Vector2(PLATE_PX - 28, PLATE_PX - 28)
	bg.add_child(ring)
	var icon := TextureRect.new()
	icon.texture = UI3.icon(String(UI3.FACE_ICON[TrayColumn.ui3_face(type)]))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = GLYPH_BOX.position
	icon.size = GLYPH_BOX.size
	bg.add_child(icon)
	if value > 0:
		var font := UI3Theme.font_display()
		var txt := str(value)
		var fs := fit_value_font(txt, font)
		var lbl := Label.new()
		lbl.text = txt
		lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", fs)
		lbl.add_theme_color_override("font_color", SKIN_INK)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.size = Vector2(VALUE_BOX.size.x, font.get_height(fs))
		lbl.position = Vector2(VALUE_BOX.position.x, VALUE_BASELINE - font.get_ascent(fs))
		bg.add_child(lbl)
	else:
		var bar := Panel.new()
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = SKIN_INK
		bsb.set_corner_radius_all(5)
		bar.add_theme_stylebox_override("panel", bsb)
		bar.position = BLANK_BAR.position
		bar.size = BLANK_BAR.size
		bg.add_child(bar)
	return bg


func _faces_of(e: Dictionary) -> Array:
	var f: Array = e.get("faces", [])
	if f.size() == 6:
		return f
	var one := {"type": String(e.get("face_type", "blank")), "value": int(e.get("value", 0))}
	return [one, one, one, one, one, one]


func _begin_physics(token: int) -> void:
	var keys: Array = []
	for d in _dice:
		for f in d["faces"]:
			keys.append(_key(f, String(d["skin"])))
	await _ensure_textures(keys)
	if token != _roll_token or not _active or _dice.is_empty():
		return   # skipped or replaced while the plates were being drawn
	_build_ground()
	for d in _dice:
		_build_die(d)
	set_process(true)


## Jump every die to its tray slot now (tween.custom_step(9999) in the handoff's words).
func skip() -> void:
	if not _active:
		return
	_skip_all()


func _skip_all() -> void:
	if not _active:
		return
	_roll_token += 1
	set_process(false)
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	if _camera != null and is_instance_valid(_camera):
		_camera.h_offset = 0.0
	for d in _dice:
		if int(d["phase"]) >= 4:
			continue
		_free_tile(d)
		_free_body(d)
		if not bool(d["settled"]):
			d["settled"] = true
			die_settled.emit(int(d["i"]))
		d["phase"] = 4
		_arrived_count += 1
		die_arrived.emit(int(d["i"]))
	_finish()


func _finish() -> void:
	_active = false
	set_process(false)
	_clear_ground()
	_emit_all_arrived()


func _emit_all_arrived() -> void:
	all_arrived.emit()


func _clear() -> void:
	_gen += 1
	for d in _dice:
		_free_tile(d)
		_free_body(d)
	_dice.clear()
	_clear_ground()


func _exit_tree() -> void:
	_clear()
	if _camera != null and is_instance_valid(_camera):
		_camera.h_offset = 0.0


# --- build --------------------------------------------------------------------------------------

func _build_ground() -> void:
	_ground = StaticBody3D.new()
	_ground.collision_layer = _LAYER_GROUND
	_ground.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40.0, 1.0, 40.0)
	cs.shape = box
	_ground.add_child(cs)
	_ground.position = Vector3(0.0, -0.5, 0.0)
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.35
	pm.friction = 0.8
	_ground.physics_material_override = pm
	_world.add_child(_ground)


func _clear_ground() -> void:
	if _ground != null and is_instance_valid(_ground):
		_ground.queue_free()
	_ground = null


func _die_size(d: Dictionary) -> float:
	return 0.77 if bool(d["small"]) else 1.0   # x1.4 of the first pass (80 px was too small)


func _build_die(d: Dictionary) -> void:
	var size := _die_size(d)
	var body := RigidBody3D.new()
	body.collision_layer = _LAYER_DIE
	body.collision_mask = _LAYER_GROUND   # dice never collide with each other: no pile-up chaos
	body.mass = 1.0
	body.gravity_scale = 1.6
	body.linear_damp = 0.15
	body.angular_damp = 0.8
	body.contact_monitor = true
	body.max_contacts_reported = 2
	body.freeze = true            # parked until its stagger delay is over
	body.visible = false
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.35
	pm.friction = 0.8
	body.physics_material_override = pm
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * size
	cs.shape = box
	body.add_child(cs)
	var pivot := Node3D.new()
	body.add_child(pivot)
	var mi := make_die_mesh(d["faces"], size, String(d["skin"]))
	pivot.add_child(mi)
	_world.add_child(body)
	body.body_entered.connect(_on_body_entered.bind(int(d["i"])))
	d["body"] = body
	d["pivot"] = pivot


func _launch(d: Dictionary) -> void:
	var body := d["body"] as RigidBody3D
	var slot = d["slot"]
	var start := Vector3(0.0, 1.8, 4.0)
	if slot is Node3D and is_instance_valid(slot):
		start = (slot as Node3D).global_position + Vector3(0.0, 1.6, 0.0)
	var n := _dice.size()
	var i := int(d["i"])
	# Land on the open floor in FRONT of both teams (between the party's front row and the camera), fanned
	# out sideways, so a die never comes to rest on a unit (horizontal layout: teams left / right).
	var gap := minf(1.6, 6.4 / maxf(float(n - 1), 1.0))
	var target := Vector3(LAND_CENTER_X + (float(i) - float(n - 1) * 0.5) * gap, 0.5,
		LAND_Z + float(i % 2) * 1.1 + _rng.randf_range(-0.2, 0.2))
	var g := 9.8 * body.gravity_scale
	var v := (target - start - Vector3(0.0, -0.5 * g * FLIGHT * FLIGHT, 0.0)) / FLIGHT
	body.global_position = start
	body.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)
	body.visible = true
	body.freeze = false
	body.apply_central_impulse(v * body.mass)
	body.apply_torque_impulse(Vector3(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-9.0, 9.0),
		_rng.randf_range(-4.0, 4.0)))
	d["phase"] = 1
	d["air"] = 0.0
	d["tnext"] = 0.0


# --- per frame -----------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _active:
		set_process(false)
		return
	for d in _dice:
		var phase := int(d["phase"])
		if phase >= 4:
			continue
		d["t"] = float(d["t"]) + delta
		if phase == 0:
			if float(d["t"]) >= STAGGER * float(d["i"]):
				_launch(d)
		elif phase == 1:
			_step_air(d, delta)
		elif phase == 2:
			d["hold"] = float(d["hold"]) + delta
			if float(d["hold"]) >= SETTLE_HOLD:
				_start_fly(d)


func _step_air(d: Dictionary, delta: float) -> void:
	var body := d["body"] as RigidBody3D
	d["air"] = float(d["air"]) + delta
	var air := float(d["air"])
	if not bool(d["bounced"]) and air >= FLIGHT + 0.15:
		_on_first_bounce(d)   # fallback when the contact signal never came
	var rest := air > FLIGHT + 0.2 and body.linear_velocity.length() < 0.2 \
		and body.angular_velocity.length() < 0.6
	if rest or body.sleeping or air >= SETTLE_TIMEOUT:
		body.freeze = true
		d["settled"] = true
		d["phase"] = 2
		d["hold"] = 0.0
		_start_face_turn(d)
		die_settled.emit(int(d["i"]))


## Last 180 ms of the settle: tween the frozen cube to the nearest orientation where the RESULT
## face looks at the camera. Physics already decided where it lies; this only turns it.
func _start_face_turn(d: Dictionary) -> void:
	var body := d["body"] as RigidBody3D
	if body == null or _camera == null:
		return
	var to_cam := (_camera.global_position - body.global_position).normalized()
	var cam_up := _camera.global_transform.basis.y
	var from_q := body.global_transform.basis.get_rotation_quaternion()
	var to_b := result_basis(body.global_transform.basis, int(d["result_index"]), to_cam, cam_up)
	var to_q := to_b.get_rotation_quaternion()
	var tw := create_tween()
	tw.tween_method(_turn_step.bind(body, from_q, to_q), 0.0, 1.0, SETTLE_HOLD) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	d["turn"] = tw


func _turn_step(w: float, body: RigidBody3D, from_q: Quaternion, to_q: Quaternion) -> void:
	if is_instance_valid(body):
		body.global_transform.basis = Basis(from_q.slerp(to_q, w))


## Pure maths: the basis nearest to `current` (shortest arc, then the roll about the view axis so the
## plate reads upright) in which face `result_index` points along `to_cam`.
static func result_basis(current: Basis, result_index: int, to_cam: Vector3, cam_up: Vector3) -> Basis:
	var n_local := FACE_NORMALS[clampi(result_index, 0, 5)]
	var u_local := FACE_UPS[clampi(result_index, 0, 5)]
	var n_world := (current * n_local).normalized()
	var arc := Quaternion(n_world, to_cam.normalized())
	var b := Basis(arc) * current
	var up_w := (b * u_local)
	var want := (cam_up - to_cam * cam_up.dot(to_cam)).normalized()
	var have := (up_w - to_cam * up_w.dot(to_cam)).normalized()
	var ang := have.signed_angle_to(want, to_cam)
	return Basis(to_cam.normalized(), ang) * b


func _on_body_entered(_other: Node, i: int) -> void:
	if i >= 0 and i < _dice.size():
		_on_first_bounce(_dice[i])


func _on_first_bounce(d: Dictionary) -> void:
	if bool(d["bounced"]):
		return
	d["bounced"] = true
	var crit := bool(d["crit"])
	var pivot := d["pivot"] as Node3D
	if pivot != null and is_instance_valid(pivot):
		pivot.scale = Vector3(1.22, 0.78, 1.22) if crit else Vector3(1.06, 0.94, 1.06)
		var tw := create_tween()
		tw.tween_property(pivot, "scale", Vector3.ONE, SQUASH_TIME) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if crit:
		_shake()


func _shake() -> void:
	if _camera == null or not is_instance_valid(_camera):
		return
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	var vh := 640.0
	var vp := _camera.get_viewport()
	if vp != null:
		vh = maxf(float(vp.get_visible_rect().size.y), 1.0)
	# 6 px in the stage viewport, converted to world units at the camera's working distance.
	var per_px := 2.0 * 13.0 * tan(deg_to_rad(_camera.fov) * 0.5) / vh
	var a := SHAKE_PX * per_px
	_shake_tween = create_tween()
	for off in [a, -a, 0.0]:
		_shake_tween.tween_property(_camera, "h_offset", off, SHAKE_STEP) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# --- fly to tray ---------------------------------------------------------------------------------

func _stage_scale() -> Vector2:
	var vp := _camera.get_viewport()
	if _stage == null or vp == null:
		return Vector2.ONE
	var vs := Vector2(vp.get_visible_rect().size)
	if vs.x <= 0.0 or vs.y <= 0.0:
		return Vector2.ONE
	return _stage.size / vs


func _start_fly(d: Dictionary) -> void:
	var body = d["body"]
	var from := Vector2.ZERO
	if body != null and is_instance_valid(body) and _camera != null:
		from = _camera.unproject_position((body as Node3D).global_position) * _stage_scale()
	_free_body(d)
	var tile := _make_tile(d)
	tile.position = from - tile.size * 0.5
	_ensure_layer().add_child(tile)
	d["tile"] = tile
	d["phase"] = 3
	var to := Vector2.ZERO
	if _tray_target.is_valid():
		to = _tray_target.call(int(d["i"]))
	var tw := create_tween()
	tw.tween_property(tile, "position", to - tile.size * 0.5, FLY_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	d["fly"] = tw
	tw.finished.connect(_on_fly_done.bind(int(d["i"]), _gen))


func _on_fly_done(i: int, gen: int) -> void:
	if gen != _gen or i < 0 or i >= _dice.size() or int(_dice[i]["phase"]) != 3:
		return
	var d := _dice[i]
	_free_tile(d)
	d["phase"] = 4
	_arrived_count += 1
	die_arrived.emit(i)
	if _arrived_count >= _dice.size():
		_finish()


func _ensure_layer() -> Control:
	if _tile_layer == null or not is_instance_valid(_tile_layer):
		_tile_layer = Control.new()
		_tile_layer.name = "DiceFlightLayer"
		_tile_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tile_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_tile_layer.z_index = 30
		_stage.add_child(_tile_layer)
	return _tile_layer


func _make_tile(d: Dictionary) -> Control:
	var s := TILE_SMALL if bool(d["small"]) else TILE_BIG
	var tile := Panel.new()
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.size = Vector2(s, s)
	var sb := StyleBoxFlat.new()
	sb.bg_color = IVORY
	sb.set_corner_radius_all(14 if not bool(d["small"]) else 10)
	sb.shadow_color = Color("2B1E17")
	sb.shadow_offset = Vector2(0, 4)
	sb.shadow_size = 0
	tile.add_theme_stylebox_override("panel", sb)
	var tex := UI3.icon(String(UI3.FACE_ICON[TrayColumn.ui3_face(String(d["face_type"]))]))
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(s * 0.5, s * 0.5)
	icon.position = Vector2(s * 0.25, s * 0.08)
	tile.add_child(icon)
	var lbl := Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.text = str(int(d["value"])) if int(d["value"]) > 0 else ""
	lbl.add_theme_color_override("font_color", INK)
	lbl.add_theme_font_size_override("font_size", int(s * 0.32))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(s, s * 0.36)
	lbl.position = Vector2(0, s * 0.58)
	tile.add_child(lbl)
	return tile


func _free_tile(d: Dictionary) -> void:
	var fly = d.get("fly")
	if fly is Tween and (fly as Tween).is_valid():
		(fly as Tween).kill()
	d["fly"] = null
	var t = d.get("tile")
	if t != null and is_instance_valid(t):
		(t as Node).queue_free()
	d["tile"] = null


func _free_body(d: Dictionary) -> void:
	var b = d.get("body")
	if b != null and is_instance_valid(b):
		(b as Node).queue_free()
	d["body"] = null
	d["pivot"] = null
	d["face"] = null
	d["glyph"] = null
	d["num"] = null
