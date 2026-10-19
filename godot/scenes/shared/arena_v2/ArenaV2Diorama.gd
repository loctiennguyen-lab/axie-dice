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
## Not wired into the game yet: CombatArena3D still builds the old arena. See the lane V report.

const DIR := "res://assets/atia/arena_v2/"
const STAGE_LAYOUT := "res://assets/atia/arena_v2/stage_layout.json"
## Boss ground tint, the textured equivalent of CombatArena3D._apply_boss_look()'s
## "saturation x1.3, value x0.85" on the flat ground colour.
const BOSS_GROUND_TINT := Color(0.9, 0.8, 0.74)

var biome_id := ""
var _ground_mats: Array[StandardMaterial3D] = []


static func scene_path(id: String) -> String:
	return DIR + id + "/" + id + "_arena.glb"


static func has_biome(id: String) -> bool:
	return id != "" and ResourceLoader.exists(scene_path(id))


static func stage_layout() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(STAGE_LAYOUT)) if FileAccess.file_exists(STAGE_LAYOUT) else null
	return parsed if parsed is Dictionary else {}


## Instantiates the diorama for `id` under this node. Returns false when there is none.
func build(id: String, boss: bool = false) -> bool:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	biome_id = ""
	_ground_mats.clear()
	if not has_biome(id):
		return false
	var packed := load(scene_path(id)) as PackedScene
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
		m.albedo_color = BOSS_GROUND_TINT if boss else Color.WHITE


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


## Preview / QA helper until integration: hides everything an old CombatArena3D built (ground plane,
## path tiles, flecks, scattered props) except its gate and gate light, so the diorama shows through
## while the gate, sky, fog and sun stay exactly as the game sets them.
static func hide_old_arena_except_gate(arena: CombatArena3D) -> void:
	if arena == null:
		return
	for root in arena.get_children():
		for c in root.get_children():
			if c != arena._portal and c != arena._portal_light and c is Node3D:
				(c as Node3D).visible = false


## Preview / QA helper until lane C merges: lane C's environment overrides (toned-down Arctic) that
## this branch's arenas.json does not have yet, merged into CombatArena3D's in-memory registry. Call
## once before any arena is built. ambient_mul is not read by this branch's CombatArena3D, so
## align_old_arena() applies it.
static func patch_registry() -> void:
	var ov: Dictionary = stage_layout().get("preview_env_overrides", {})
	var biomes: Dictionary = CombatArena3D.registry().get("biomes", {})
	for id in ov:
		if biomes.has(id) and ov[id] is Dictionary:
			(biomes[id] as Dictionary).merge(ov[id], true)


## Preview / QA helper until lane C merges: moves an old arena so its gate stands where
## stage_layout.json says (lane C's LANE_Z / portal z). Call after the arena is built.
static func align_old_arena(arena: CombatArena3D, env: Environment) -> void:
	if arena == null:
		return
	var st := stage_layout()
	var dx := float(st.get("gate_x", 6.7)) - float(st.get("old_arena_portal_world_x", 6.7))
	arena.position = Vector3(dx, 0.0, float(st.get("lane_z", arena.position.z)))
	var ov: Dictionary = st.get("preview_env_overrides", {}).get(arena.biome_id, {})
	if env != null and not arena.is_boss and ov.has("ambient_mul"):
		env.ambient_light_energy = CombatArena3D.LAND_AMBIENT_ENERGY * float(ov["ambient_mul"])
