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
const BOSS_FOG_DENSITY := 0.011
const BOSS_PORTAL_MUL := 1.5

static var _registry: Dictionary = {}
static var _loaded := false

var biome_id := ""
var is_boss := false
var _props_root: Node3D
var _portal: Node3D
var _portal_light: OmniLight3D
var _sun: DirectionalLight3D
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
	_env.fog_density = BOSS_FOG_DENSITY
	_env.fog_light_color = _env.fog_light_color.lerp(Color(0.25, 0.1, 0.12), 0.45)
	_env.ambient_light_energy = 0.7
	if _portal != null:
		_portal.scale *= BOSS_PORTAL_MUL
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
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.ambient_light_energy = 0.9
	_env.fog_enabled = true
	_env.fog_light_color = Color(String(b.get("fog", "#efdcae")))
	_env.fog_density = 0.006
	_sun.light_color = Color(String(b.get("light", "#ffffff")))
	_sun.light_energy = float(b.get("light_energy", 1.15))


func _add_ground(b: Dictionary) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(GROUND_SIZE, GROUND_SIZE)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(String(b.get("ground", "#c9b46a")))
	mat.roughness = 1.0
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
	probe.queue_free()
	var len := maxf(box.size.z, 0.5)
	var z := 8.0
	var end_z := float(registry().get("portal", {}).get("z", -15.0)) - 2.0
	var i := 0
	while z > end_z and i < 40:
		var t := packed.instantiate() as Node3D
		_props_root.add_child(t)
		t.position = Vector3(0.0, 0.0, z)
		z -= len
		i += 1


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
			var x := rng.randf_range(float(xr[0]), float(xr[1]))
			# flank / low zones are given as positive |x|; mirror half of them to the left
			if float(xr[0]) >= 0.0 and rng.randf() < 0.5:
				x = -x
			var z := rng.randf_range(float(zr[0]), float(zr[1]))
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
		_portal.position = Vector3(-box.get_center().x * f, -box.position.y * f, float(cfg.get("z", -15.0)))
	_portal_light = OmniLight3D.new()
	_portal_light.light_color = Color(0.55, 0.8, 1.0)
	_portal_light.light_energy = 1.2
	_portal_light.omni_range = 9.0
	_portal_light.position = Vector3(0.0, 2.2, float(cfg.get("z", -15.0)) + 1.0)
	_props_root.add_child(_portal_light)


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


## World position of the portal, or ZERO when this arena has none.
func portal_position() -> Vector3:
	return _portal.global_position if _portal != null else Vector3.ZERO
