class_name ArenaV2Diorama
extends Node3D
## Arena v2 (lane V, 19/10): one hand-built battle diorama per biome, made in Blender from the
## HomeLand / Atia kits and exported as a single GLB per biome (pipeline: tools/art/arena_v2/).
##
## Each GLB is authored in COMBAT STAGE WORLD coordinates (x right, z toward the camera, units on
## y = 0), so it goes straight under CombatStage3D's `_world` at the origin, with no offset and no
## rotation (unlike CombatArena3D, which sits at z = LANE_Z and is turned -90 degrees).
## Stage geometry the dioramas were built against (gate, march line, flat area, keep-outs) is in
## res://assets/atia/arena_v2/stage_layout.json; change it there and re-export.
##
## Boss fights reuse the biome's diorama: the boss look is lighting/fog/sky (CombatArena3D) plus the
## ground tint below, not different geometry.
##
## Wired in by CombatStage3D.set_arena(): a biome with a GLB here gets its diorama under the stage
## world and CombatArena3D (terrain_from_diorama) keeps only sky, fog, sun and the gate portal. A
## missing GLB falls back to the old procedural terrain.

const DIR := "res://assets/atia/arena_v2/"
const STAGE_LAYOUT := "res://assets/atia/arena_v2/stage_layout.json"
## Boss ground tint, the textured stand-in for CombatArena3D._apply_boss_look()'s "saturation x1.3,
## value x0.85" on the flat ground colour: darker, a little warmer. Cool biomes only darken (a warm
## multiply turned the Arctic snow into dirt under the red boss light).
const BOSS_GROUND_TINT := Color(0.88, 0.82, 0.78)
const BOSS_GROUND_TINT_COOL := Color(0.86, 0.86, 0.9)
const COOL_BIOMES := ["arctic", "mystic", "luna"]

## Background preloading (19/10, lane C). The first fight in a biome used to `load()` its ~1.3 MB
## GLB on the spot (a hitch, worst on web). RunMapController calls preload_biomes() with the
## biomes of the next fights; packed_scene() then hands back the finished resource.
## Headless (tests) loads synchronously inside preload_biomes(), so results are deterministic.
const MAX_PRELOAD := 2
## Tests set this to exercise the threaded path under --headless.
static var force_threaded := false
## id -> PackedScene already loaded (kept so the cache entry is not dropped before the fight).
static var _ready_scenes: Dictionary = {}
## ids with a threaded request that has not been collected yet.
static var _pending: Array[String] = []

var biome_id := ""
var _ground_mats: Array[StandardMaterial3D] = []


static func scene_path(id: String) -> String:
	return DIR + id + "/" + id + "_arena.glb"


static func has_biome(id: String) -> bool:
	return id != "" and ResourceLoader.exists(scene_path(id))


static func stage_layout() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(STAGE_LAYOUT)) if FileAccess.file_exists(STAGE_LAYOUT) else null
	return parsed if parsed is Dictionary else {}


static func _threaded_ok() -> bool:
	return force_threaded or DisplayServer.get_name() != "headless"


## Asks for the dioramas of `ids` to be loaded in the background (at most MAX_PRELOAD biomes,
## first ones win). Biomes already loaded or already requested are skipped, so calling this on
## every map refresh is cheap. Scenes kept for biomes no longer wanted are released (a stage that
## is showing one holds its own instance). Returns the ids newly requested by this call.
static func preload_biomes(ids: Array) -> Array[String]:
	var wanted: Array[String] = []
	for raw in ids:
		var id := String(raw)
		if wanted.size() < MAX_PRELOAD and not wanted.has(id) and has_biome(id):
			wanted.append(id)
	if not EventBus.run_ended.is_connected(_on_run_ended):
		EventBus.run_ended.connect(_on_run_ended)   # drop the held scenes when the run ends
	# Drain finished requests first (also stale ones, else _pending would never shrink).
	for pid in _pending.duplicate():
		_collect(pid)
	for k in _ready_scenes.keys():
		if not wanted.has(k):
			_ready_scenes.erase(k)
	var started: Array[String] = []
	for id in wanted:
		if _ready_scenes.has(id) or _pending.has(id):
			continue
		if not _threaded_ok():
			var ps := load(scene_path(id)) as PackedScene
			if ps != null:
				_ready_scenes[id] = ps
				started.append(id)
		elif _pending.size() < MAX_PRELOAD \
				and ResourceLoader.load_threaded_request(scene_path(id), "PackedScene") == OK:
			_pending.append(id)
			started.append(id)
	return started


## The diorama scene for `id`: the preloaded one when it is ready, otherwise a synchronous load
## (also when its threaded request is still running; load() then waits for it). Null if missing.
static func packed_scene(id: String) -> PackedScene:
	if not has_biome(id):
		return null
	_collect(id)
	if _ready_scenes.has(id):
		return _ready_scenes[id]
	var ps := load(scene_path(id)) as PackedScene
	_pending.erase(id)
	if ps != null:
		_ready_scenes[id] = ps
	return ps


## True when packed_scene(id) would not block (already loaded, or the thread has finished).
static func is_ready(id: String) -> bool:
	_collect(id)
	return _ready_scenes.has(id)


## True when `id` has a request in flight or a loaded scene held by the preload cache.
static func is_requested(id: String) -> bool:
	return _pending.has(id) or _ready_scenes.has(id)


## Moves a finished threaded request into _ready_scenes (never blocks).
static func _collect(id: String) -> void:
	if not _pending.has(id):
		return
	var path := scene_path(id)
	var st := ResourceLoader.load_threaded_get_status(path)
	if st == ResourceLoader.THREAD_LOAD_LOADED:
		_pending.erase(id)
		var ps := ResourceLoader.load_threaded_get(path) as PackedScene
		if ps != null:
			_ready_scenes[id] = ps
	elif st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_pending.erase(id)


static func _on_run_ended(_won: bool) -> void:
	clear_preload()


## Forgets every preload (tests, QA timing). Does not touch scenes a stage has instanced.
static func clear_preload() -> void:
	_ready_scenes.clear()
	_pending.clear()


## Instantiates the diorama for `id` under this node. Returns false when there is none.
func build(id: String, boss: bool = false) -> bool:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	biome_id = ""
	_ground_mats.clear()
	if not has_biome(id):
		return false
	var packed := packed_scene(id)
	if packed == null:
		return false
	var root := packed.instantiate() as Node3D
	root.name = "Diorama"
	add_child(root)
	biome_id = id
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		# The ground only receives shadows; props cast them (sun shadows are on with an arena).
		var is_ground := mi.name.begins_with("G_")
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if is_ground else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for s in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(s) as StandardMaterial3D
			if src == null:
				continue
			# Per-instance copy: the imported GLB's materials are cached and shared, never edit them.
			var m := src.duplicate() as StandardMaterial3D
			m.roughness = 1.0
			m.metallic_specular = 0.0
			# The glTF importer drops these two; the pipeline names them (tools/art/arena_v2/kit.py):
			# cliffs are painted with vertex colours (COLOR_0, linear), "_cut" materials are cut-out cards.
			if (mi.mesh.surface_get_format(s) & Mesh.ARRAY_FORMAT_COLOR) != 0:
				m.vertex_color_use_as_albedo = true
			if m.resource_name.ends_with("_cut") or m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				m.alpha_scissor_threshold = 0.5
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
			if is_ground:
				_ground_mats.append(m)
			mi.set_surface_override_material(s, m)
	set_boss(boss)
	return true


## Boss variant of the same diorama: darker, warmer ground (lighting is CombatArena3D's job).
func set_boss(boss: bool) -> void:
	for m in _ground_mats:
		var tint := BOSS_GROUND_TINT_COOL if COOL_BIOMES.has(biome_id) else BOSS_GROUND_TINT
		m.albedo_color = tint if boss else _compat_ground_tint()


## Number of triangles in the diorama as drawn (instances counted), for the budget check.
## QA only: copies every surface's arrays.
func triangle_count() -> int:
	var tris := 0
	for n in find_children("*", "MeshInstance3D", true, false):
		var mesh := (n as MeshInstance3D).mesh
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var a := mesh.surface_get_arrays(s)
			var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
			tris += (idx.size() if not idx.is_empty() else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return tris


## Web (gl_compatibility) only: a biome may tone its textured ground down ("compat_ground_tint"), because that
## renderer burns bright grounds (Savannah) to flat yellow (Liam 28/10). White = untouched.
func _compat_ground_tint() -> Color:
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		return Color.WHITE
	var b: Dictionary = (CombatArena3D.registry().get("biomes", {}) as Dictionary).get(biome_id, {})
	return Color(String(b.get("compat_ground_tint", "#ffffff")))
