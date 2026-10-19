class_name ArenaV2Diorama
extends Node3D
## Arena v2 (lane V, proposal 19/10): one hand-built battle diorama per biome, made in Blender from
## the HomeLand / Atia kits and exported as a single GLB (tools/art/arena_v2/). Savannah only so far.
##
## The GLB is authored in COMBAT STAGE WORLD coordinates (x right, z toward the camera, units on
## y = 0), so it goes straight under CombatStage3D's `_world` at the origin, with no offset and no
## rotation (unlike CombatArena3D, which sits at z = LANE_Z and is turned -90 degrees).
## The battle area (party x -11..-4, enemies x -1.5..5.5, z -12.5..8, gate x 6.7 on z 1.1) is flat
## at y = 0; everything else rises gently or is set dressing.
##
## Not wired into the game yet: CombatArena3D still builds the old arena. See the lane V report
## for what integration needs.

const SCENES := {
	"savannah": "res://assets/atia/arena_v2/savannah/savannah_arena.glb",
}

var biome_id := ""


static func has_biome(id: String) -> bool:
	return SCENES.has(id) and ResourceLoader.exists(String(SCENES[id]))


## Instantiates the diorama for `id` under this node. Returns false when there is none.
func build(id: String) -> bool:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	biome_id = ""
	if not has_biome(id):
		return false
	var packed := load(String(SCENES[id])) as PackedScene
	if packed == null:
		return false
	var root := packed.instantiate() as Node3D
	root.name = "Diorama"
	add_child(root)
	biome_id = id
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		# The ground only receives shadows; props cast them (sun shadows are on with an arena).
		var is_ground := mi.name.begins_with("SA_Ground")
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if is_ground else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for s in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(s) as StandardMaterial3D
			if src == null:
				continue
			# Per-instance copy: the imported GLB's materials are cached and shared, never edit them.
			var m := src.duplicate() as StandardMaterial3D
			m.roughness = 1.0
			m.metallic_specular = 0.0
			# The glTF importer drops these two; the mesh names them (tools/art/arena_v2/):
			# cliffs are painted with vertex colours (COLOR_0, linear), foliage cards need cut-out.
			if (mi.mesh.surface_get_format(s) & Mesh.ARRAY_FORMAT_COLOR) != 0:
				m.vertex_color_use_as_albedo = true
			if m.resource_name.begins_with("M_SA_Tree") or m.resource_name.begins_with("M_SA_Shrub") \
					or m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				m.alpha_scissor_threshold = 0.5
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
			mi.set_surface_override_material(s, m)
	return true


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
