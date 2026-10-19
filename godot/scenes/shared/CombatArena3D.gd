class_name CombatArena3D
extends Node3D
## Open 3D battlefield behind a fight (L1 lane C). One per CombatStage3D world.
##
## Built from the HomeLand environment kit, data-driven by assets/atia/arenas.json:
##   journey   - ordered biome ids; a run's rows are spread evenly across them
##   biomes    - ground/sky/fog/light colours + prop lists (scene, count, zone, scale)
##   zones     - x/z rectangles per prop zone. Tall props live on the flanks (|x| >= 9) or far
##               behind the enemy row; the centre band stays empty so enemy HP/intent plates
##               and the units are never covered. "low" props (rocks, shrubs) sit at |x| >= 7.5.
##   portal    - SM_Portal_01 at the far end (z), with a glow light
## Placement is seeded by biome id, so the same biome always looks the same.

const REGISTRY_PATH := "res://assets/atia/arenas.json"
const GROUND_SIZE := 160.0

const BOSS_LIGHT_MUL := 0.72
const BOSS_FOG_DENSITY := 0.0035
const BOSS_PORTAL_MUL := 1.15
const BOSS_PORTAL_Z := -6.45   # pushed back so the 1.3x tower still fits under the frame top
## SM_Portal_01 has a detached spire (separate piece, mesh-local y > 7.5) that floats above the tower; dropped.
const PORTAL_FINIAL_Y := 7.5
## Same sun / ambient as the Land hub; a biome only tints these a little (it owns sky + ground).
const LAND_SUN := Color("ffe2b0")
const LAND_SUN_ENERGY := 1.25
const LAND_AMBIENT := Color("fff1d6")
const LAND_AMBIENT_ENERGY := 0.75
const BASE_FOG_DENSITY := 0.006
## Default for registry "path_end_gap": the path lane ends this far in front of the portal origin
## (tile centre), so the pedestal stays visible.
const PATH_END_GAP := 2.8
## Default for registry portal "yaw_deg": gate turned 90 degrees about Y (Liam 16/10).
const PORTAL_YAW_DEG := 90.0
## Prop keep-out (|x| / z): enemy flanks (enemy row z -6.5, x 0/+-5.1) and the portal line.
const KEEPOUT_ENEMY_Z := [-15.0, 16.0]   # arena z = world -x: the whole fight line incl. party
## arena x = world z - lane z. The 3 depth rows stand at world z -6 .. +7 around a lane at z 1.1.
const KEEPOUT_ENEMY_X := [-27.0, 9.0]
const KEEPOUT_PORTAL_Z := -6.5   # anything behind this z keeps |x| >= KEEPOUT_PORTAL_X
const KEEPOUT_PORTAL_X := 6.0

static var _registry: Dictionary = {}
static var _loaded := false

var biome_id := ""
var is_boss := false
var _props_root: Node3D
var _portal: Node3D
var _portal_light: OmniLight3D
var _sun: DirectionalLight3D
var _ground_mat: StandardMaterial3D
var _env: Environment


static func registry() -> Dictionary:
	if not _loaded:
		_loaded = true
		if FileAccess.file_exists(REGISTRY_PATH):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY_PATH))
			if parsed is Dictionary:
				_registry = parsed
	return _registry


## Biome for a combat. `row` is 1-based; spreads the run over `journey` evenly. `total_rows`
## is 18 for the standard run, 30 for the full run.
static func biome_for(row: int, is_boss: bool, total_rows: int = 18) -> String:
	var reg := registry()
	var journey: Array = reg.get("journey", [])
	if journey.is_empty():
		return ""
	if is_boss and String(reg.get("boss_biome", "")) != "":
		return String(reg["boss_biome"])
	var idx := clampi(int(floor(float(maxi(row, 1) - 1) / float(maxi(total_rows, 1)) * journey.size())),
		0, journey.size() - 1)
	return String(journey[idx])


## Builds (or rebuilds) the arena for `id`. Returns false when the biome is unknown.
## `env`/`sun` are the stage's own, retinted instead of duplicated.
## `boss` builds the boss variant of the biome: darker/redder light and fog, a bigger portal that
## glows red, a denser ring of flank props. Purely cosmetic and seeded by biome id, so it never
## touches the game RNG.
func build(id: String, env: Environment, sun: DirectionalLight3D, boss: bool = false) -> bool:
	var reg := registry()
	var biomes: Dictionary = reg.get("biomes", {})
	if not biomes.has(id):
		return false
	clear()
	biome_id = id
	is_boss = boss
	_env = env
	_sun = sun
	var b: Dictionary = biomes[id]
	_tint_environment(b)
	_props_root = Node3D.new()
	_props_root.name = "Props"
	add_child(_props_root)
	_add_ground(b)
	_add_path(b)
	_add_flecks(b)
	_scatter(b, reg.get("zones", {}))
	_add_portal(reg.get("portal", {}))
	if boss:
		_apply_boss_look()
	return true


func clear() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_portal = null
	_portal_light = null
	biome_id = ""
	is_boss = false


## Boss set piece: dim the sun and push it toward ember red, thicken and darken the fog, and
## make the far portal 1.5x taller with a red glow. Called after the biome tint.
func _apply_boss_look() -> void:
	_sun.light_energy *= BOSS_LIGHT_MUL
	_sun.light_color = _sun.light_color.lerp(Color(1.0, 0.55, 0.4), 0.35)
	# dark red-maroon sky with an orange horizon band so the horizon still reads
	var sky_mat := _env.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = Color("2e0b12")
	sky_mat.sky_horizon_color = Color("e8742c")
	sky_mat.ground_horizon_color = Color("a04a24")
	sky_mat.sky_curve = 0.12
	_env.fog_density = BOSS_FOG_DENSITY
	_env.fog_light_color = Color("8a3a22")
	_env.ambient_light_energy = 0.7
	if _ground_mat != null:
		var c := _ground_mat.albedo_color
		_ground_mat.albedo_color = Color.from_hsv(c.h, minf(c.s * 1.3, 1.0), c.v * 0.85)
	if _portal != null:
		var z := float(registry().get("portal", {}).get("z", -20.0))
		_portal.scale *= BOSS_PORTAL_MUL
		_portal.position.x -= (_portal.transform * _aabb_of(_portal).get_center()).x   # scaling about the origin pushed the centre off x = 0
		_portal.position.z += BOSS_PORTAL_Z - z
		if _portal_light != null:
			_portal_light.position.z += BOSS_PORTAL_Z - z
	if _portal_light != null:
		_portal_light.light_color = Color(1.0, 0.35, 0.25)
		_portal_light.light_energy = 2.4
		_portal_light.omni_range = 14.0


func _tint_environment(b: Dictionary) -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(String(b.get("sky_top", "#6fb3e8")))
	sky_mat.sky_horizon_color = Color(String(b.get("sky_horizon", "#f4e2b0")))
	sky_mat.ground_horizon_color = Color(String(b.get("fog", "#efdcae")))
	sky_mat.ground_bottom_color = Color(String(b.get("ground", "#c9b46a")))
	var sky := Sky.new()
	sky.sky_material = sky_mat
	_env.sky = sky
	_env.background_mode = Environment.BG_SKY
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = LAND_AMBIENT.lerp(Color(String(b.get("sky_horizon", "#ffffff"))), 0.2)
	_env.ambient_light_energy = LAND_AMBIENT_ENERGY * float(b.get("ambient_mul", 1.0))
	_env.fog_enabled = true
	_env.fog_light_color = Color(String(b.get("fog", "#efdcae")))
	_env.fog_density = float(b.get("fog_density", BASE_FOG_DENSITY))
	_sun.light_color = LAND_SUN.lerp(Color(String(b.get("light", "#ffffff"))), 0.3)
	_sun.light_energy = LAND_SUN_ENERGY * lerpf(1.0, float(b.get("light_energy", 1.15)) / 1.15, 0.5)


func _add_ground(b: Dictionary) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(GROUND_SIZE, GROUND_SIZE)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(String(b.get("ground", "#c9b46a")))
	mat.roughness = 1.0
	_ground_mat = mat
	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = plane
	mi.material_override = mat
	mi.position = Vector3(0.0, -0.01, -40.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_props_root.add_child(mi)


## A lane of stone path tiles from the party row to the portal, centred, so the battlefield
## reads as a road to somewhere. Tile length is measured from the scene, not assumed.
func _add_path(b: Dictionary) -> void:
	var path := String(b.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		return
	var packed := load(path) as PackedScene
	if packed == null:
		return
	var probe := packed.instantiate() as Node3D
	_props_root.add_child(probe)
	var box := _aabb_of(probe)
	var len := maxf(box.size.z, 0.5)
	var tint: Material = null   # optional per-biome recolour of the tiles: "path_tint": "#rrggbbaa"
	if String(b.get("path_tint", "")) != "":
		var tm := StandardMaterial3D.new()
		tm.albedo_color = Color(String(b["path_tint"]))
		tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		tint = tm
	var z := float(registry().get("path_start_z", 0.8))
	var end_z := float(registry().get("portal", {}).get("z", -15.0)) + float(registry().get("path_end_gap", PATH_END_GAP))   # stop short of the pedestal
	var zs: Array[float] = []
	while z > end_z and zs.size() < 40:
		zs.append(z)
		z -= len
	if zs.is_empty():
		probe.queue_free()
		return
	# One MultiMeshInstance3D per mesh in the tile scene (a tile has 2 surfaces) instead of one node
	# per tile: ~3 draw calls for the whole lane. Surface materials are copied from the scene.
	for n in probe.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var mesh := mi.mesh.duplicate() as Mesh
		for k in mesh.get_surface_count():
			mesh.surface_set_material(k, mi.get_active_material(k))
		var local := probe.global_transform.affine_inverse() * mi.global_transform
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = zs.size()
		for k in zs.size():
			mm.set_instance_transform(k, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.0, zs[k])) * local)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "PathLane"
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if tint != null:
			mmi.material_overlay = tint
		_props_root.add_child(mmi)
	probe.queue_free()


func _scatter(b: Dictionary, zones: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(biome_id)
	for entry in b.get("props", []):
		var scene_path := String(entry.get("scene", ""))
		if not ResourceLoader.exists(scene_path):
			continue
		var packed := load(scene_path) as PackedScene
		if packed == null:
			continue
		var zone: Dictionary = zones.get(String(entry.get("zone", "flank")), {})
		var xr: Array = zone.get("x", [9.0, 24.0])
		var zr: Array = zone.get("z", [-26.0, 3.0])
		var hm: Array = entry.get("height_m", [])
		var sc: Array = entry.get("scale", [1.0, 1.0])
		for i in int(ceil(float(entry.get("count", 1)) * (1.5 if is_boss else 1.0))):
			var n := packed.instantiate() as Node3D
			if n == null:
				continue
			_props_root.add_child(n)
			var x := 0.0
			var z := 0.0
			for _try in 12:   # rejection sampling against the keep-out zones (deterministic rng)
				x = rng.randf_range(float(xr[0]), float(xr[1]))
				# flank / low zones are given as positive |x|; mirror half of them to the left
				# (the arena is turned -90 deg: arena +x is toward the camera, so props only go to the far side)
				if float(xr[0]) >= 0.0:
					x = -x
				z = rng.randf_range(float(zr[0]), float(zr[1]))
				if not in_keepout(x, z):
					break
			if in_keepout(x, z):
				n.queue_free()
				continue
			n.position = Vector3(x, 0.0, z)
			n.rotation_degrees.y = rng.randf_range(0.0, 360.0)
			if hm.size() == 2:
				# height_m: normalise to a target height measured from the scene itself, since the
				# kit's units differ per biome (Luna rocks are building-sized)
				var box := _aabb_of(n)
				if box.size.y > 0.001:
					var f := rng.randf_range(float(hm[0]), float(hm[1])) / box.size.y
					n.scale = Vector3.ONE * f
					n.position.y = -box.position.y * f
			else:
				n.scale = Vector3.ONE * rng.randf_range(float(sc[0]), float(sc[1]))


## True when a prop at (x, z) would crowd the enemy row or stand on the portal line.
static func in_keepout(x: float, z: float) -> bool:
	if z >= float(KEEPOUT_ENEMY_Z[0]) and z <= float(KEEPOUT_ENEMY_Z[1]) and x >= float(KEEPOUT_ENEMY_X[0]) and x <= float(KEEPOUT_ENEMY_X[1]):
		return true
	return z < KEEPOUT_PORTAL_Z and (absf(x) < KEEPOUT_PORTAL_X or (x >= float(KEEPOUT_ENEMY_X[0]) and x <= float(KEEPOUT_ENEMY_X[1])))


## Optional per-biome ground flecks (`flecks`: {color, count}) so a dark ground is not a flat slab.
func _add_flecks(b: Dictionary) -> void:
	var cfg: Dictionary = b.get("flecks", {})
	if cfg.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(biome_id) + 7
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.35
	mesh.bottom_radius = 0.35
	mesh.height = 0.01
	mesh.radial_segments = 8
	mesh.rings = 1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(String(cfg.get("color", "#7a80a6")))
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if mat.albedo_color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	var count := int(cfg.get("count", 80))
	mm.instance_count = count
	for i in count:
		var x := rng.randf_range(-30.0, 30.0)
		var z := rng.randf_range(-40.0, 9.0)
		var sc := rng.randf_range(0.5, 2.2)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(sc, 1.0, sc * rng.randf_range(0.5, 1.0))), Vector3(x, 0.005, z)))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Flecks"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_props_root.add_child(mmi)


func _add_portal(cfg: Dictionary) -> void:
	var path := String(cfg.get("scene", ""))
	if path == "" or not ResourceLoader.exists(path):
		return
	var packed := load(path) as PackedScene
	if packed == null:
		return
	_portal = packed.instantiate() as Node3D
	_props_root.add_child(_portal)
	var tex_path := String(cfg.get("texture", ""))
	if tex_path != "" and ResourceLoader.exists(tex_path):
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = load(tex_path)
		for m in _portal.find_children("*", "MeshInstance3D", true, false):
			(m as MeshInstance3D).material_override = mat
	var box := _aabb_of(_portal)
	if box.size.y > 0.001:
		var f := float(cfg.get("height_m", 4.5)) / box.size.y
		_portal.scale = Vector3.ONE * f
		# Yaw about Y (registry portal.yaw_deg, default PORTAL_YAW_DEG). The mesh-local centre
		# is rotated with the node, so re-solve the origin so the tower stays on x = 0 and keeps
		# the same z it had at yaw 0 (arena z = origin z at yaw 0).
		var yaw := deg_to_rad(float(cfg.get("yaw_deg", PORTAL_YAW_DEG)))
		_portal.rotation.y = yaw
		var c := box.get_center()
		var off := Basis(Vector3.UP, yaw) * Vector3(c.x * f, 0.0, c.z * f)
		_portal.position = Vector3(-off.x, -box.position.y * f, float(cfg.get("z", -15.0)) + c.z * f - off.z)
	for m in _portal.find_children("*", "MeshInstance3D", true, false):
		_drop_finial(m as MeshInstance3D)
	_portal_light = OmniLight3D.new()
	_portal_light.light_color = Color(0.55, 0.8, 1.0)
	_portal_light.light_energy = 1.2
	_portal_light.omni_range = 9.0
	_portal_light.position = Vector3(0.0, 2.2, float(cfg.get("z", -15.0)) + 1.0)
	_props_root.add_child(_portal_light)


## Rebuild the mesh without triangles lying entirely above PORTAL_FINIAL_Y (the floating spire).
static func _drop_finial(mi: MeshInstance3D) -> void:
	var src := mi.mesh as ArrayMesh
	if src == null:
		return
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var a := src.surface_get_arrays(s)
		var v: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		if idx.is_empty():
			return
		var keep := PackedInt32Array()
		for t in idx.size() / 3:
			var i0 := idx[t * 3]
			var i1 := idx[t * 3 + 1]
			var i2 := idx[t * 3 + 2]
			if minf(v[i0].y, minf(v[i1].y, v[i2].y)) <= PORTAL_FINIAL_Y:
				keep.append_array(PackedInt32Array([i0, i1, i2]))
		a[Mesh.ARRAY_INDEX] = keep
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		out.surface_set_material(s, src.surface_get_material(s))
	mi.mesh = out


## AABB of all meshes under `root`, in root's local space (all node transforms applied).
static func _aabb_of(root: Node3D) -> AABB:
	var inv := root.global_transform.affine_inverse()
	var box := AABB()
	var first := true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var b: AABB = inv * mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## World position of the top of the portal tower, or ZERO when this arena has none.
func portal_top_position() -> Vector3:
	if _portal == null:
		return Vector3.ZERO
	var box := _aabb_of(_portal)
	return _portal.global_transform * Vector3(box.get_center().x, box.end.y, box.get_center().z)


## World-space bounding box of the portal model.
func portal_world_aabb() -> AABB:
	if _portal == null:
		return AABB()
	return _portal.global_transform * _aabb_of(_portal)


## World position of the portal, or ZERO when this arena has none.
func portal_position() -> Vector3:
	return _portal.global_position if _portal != null else Vector3.ZERO
