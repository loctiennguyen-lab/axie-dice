extends Node3D
## Standalone preview of an arena v2 diorama (lane V) under the real combat camera framing, with
## simple stand-ins for the party and the enemies. CombatStage3D is not used or changed: its camera
## numbers are copied below, slot positions come from res://assets/atia/arena_v2/stage_layout.json
## (lane C's current formation), and the old arena only provides the gate, sky, fog and sun.
##
## Env vars:
##   PREVIEW_BIOME=forest   which biome (default savannah)
##   PREVIEW_OLD=1          show the current arena instead, for an A/B compare
##   PREVIEW_BOSS=1         boss look (darker, red gate glow)
##   PREVIEW_SHOT=1         save <ADT_EVIDENCE_DIR>/v-preview-<biome>-<v2|old>[-boss]-<w>x<h>.png at
##                          1920x1080 and 1280x720, then quit (godot/tools/shot.sh, not headless)

## Camera as CombatStage3D sets it on a 1080 canvas after CombatView calls frame_band(1080, 140.4, 876):
## _CAM_POS, _CAM_FOV 19 widened to the full canvas, pitch -30 tipped by the band offset.
const CAM_POS := Vector3(-0.2, 17.0, 28.0)
const CAM_FOV := 27.607
const CAM_PITCH_DEG := -30.829

var _env: Environment
var _sun: DirectionalLight3D
var _arena: CombatArena3D
var _diorama: ArenaV2Diorama


func _ready() -> void:
	var biome := OS.get_environment("PREVIEW_BIOME")
	if biome == "":
		biome = "savannah"
	var old := OS.get_environment("PREVIEW_OLD") != ""
	var boss := OS.get_environment("PREVIEW_BOSS") != ""
	_build_rig()
	ArenaV2Diorama.patch_registry()
	_arena = CombatArena3D.new()
	_arena.name = "Arena"
	_arena.rotation_degrees.y = -90.0
	add_child(_arena)
	_arena.build(biome, _env, _sun, boss)
	ArenaV2Diorama.align_old_arena(_arena, _env)
	if not old:
		ArenaV2Diorama.hide_old_arena_except_gate(_arena)
		_diorama = ArenaV2Diorama.new()
		_diorama.name = "ArenaV2"
		add_child(_diorama)
		_diorama.build(biome, boss)
	_add_stand_ins()
	if OS.get_environment("PREVIEW_SHOT") != "":
		await _shots("%s-%s%s" % [biome, "old" if old else "v2", "-boss" if boss else ""])
		get_tree().quit(0)


func _build_rig() -> void:
	var cam := Camera3D.new()
	cam.position = CAM_POS
	cam.rotation_degrees = Vector3(CAM_PITCH_DEG, 0.0, 0.0)
	cam.fov = CAM_FOV
	cam.current = true
	add_child(cam)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
	_sun.shadow_enabled = true
	_sun.shadow_blur = 2.0
	_sun.directional_shadow_max_distance = 45.0
	_sun.shadow_opacity = 0.55
	add_child(_sun)
	var we := WorldEnvironment.new()
	_env = Environment.new()
	we.environment = _env
	add_child(we)


## Capsules where the units stand: blue party (5, two staggered rows), red enemies (3, lane C pattern).
func _add_stand_ins() -> void:
	var st := ArenaV2Diorama.stage_layout()
	var party_mat := StandardMaterial3D.new()
	party_mat.albedo_color = Color(0.35, 0.6, 0.95)
	var enemy_mat := StandardMaterial3D.new()
	enemy_mat.albedo_color = Color(0.9, 0.35, 0.3)
	var p: Dictionary = st.get("party", {})
	for i in 5:
		_capsule(Vector3(float(p.get("x0", -10.0)) + i * float(p.get("pitch", 1.3)), 0.0, float(p["z"][i % 2])), party_mat)
	var e: Dictionary = st.get("enemies", {})
	for ent in e.get("pattern_3", []):
		_capsule(Vector3(float(e["center_x"]) + float(ent[0]) * float(e["pitch"]), 0.0, float(e["rows_z"][int(ent[1]) + 1])), enemy_mat)


func _capsule(at: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = 0.45
	m.height = 1.6
	mi.mesh = m
	mi.material_override = mat
	mi.position = at + Vector3(0.0, 0.8, 0.0)
	add_child(mi)


func _shots(tag: String) -> void:
	var out := OS.get_environment("ADT_EVIDENCE_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	var sizes: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(1280, 720)]
	if OS.get_environment("CAP_SIZE") != "":
		var pz := OS.get_environment("CAP_SIZE").split("x")
		sizes = [Vector2i(int(pz[0]), int(pz[1]))]
	for size in sizes:
		get_window().size = size
		for _i in 10:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := "%s/v-preview-%s-%dx%d.png" % [out, tag, size.x, size.y]
		get_tree().root.get_texture().get_image().save_png(path)
		print("QA: saved ", path.get_file())
