extends Node3D
## Standalone preview of the Savannah arena v2 diorama (lane V proposal) under the real combat
## camera framing, with simple stand-ins for the party and the enemies. CombatStage3D is not used or
## changed: its camera and slot numbers are copied below.
##
## Env vars:
##   PREVIEW_OLD=1    show the current arena (CombatArena3D) instead, for an A/B compare
##   PREVIEW_BOSS=1   boss look (darker, red gate glow)
##   PREVIEW_SHOT=1   save <ADT_EVIDENCE_DIR>/v-preview-<v2|old>[-boss]-<w>x<h>.png at 1920x1080 and
##                    1280x720, then quit (run with godot/tools/shot.sh, not headless)

## Camera as CombatStage3D sets it on a 1080 canvas after CombatView calls frame_band(1080, 140.4, 876):
## _CAM_POS, _CAM_FOV 19 widened to the full canvas, pitch -30 tipped by the band offset.
const CAM_POS := Vector3(-0.2, 17.0, 28.0)
const CAM_FOV := 27.607
const CAM_PITCH_DEG := -30.829
## Slot maths copied from CombatStage3D (PARTY_X0, PARTY_PITCH_X, PARTY_Z_FRONT/BACK, ENEMY_*).
const PARTY_X0 := -10.0
const PARTY_PITCH_X := 1.3
const PARTY_Z := [3.6, -1.4]
const ENEMY_CENTER_X := 2.1
const ENEMY_PITCH_X := 0.95
const ENEMY_Z := [-4.9, 1.1, 6.4]
const LANE_Z := 1.1

var _env: Environment
var _sun: DirectionalLight3D
var _arena: CombatArena3D
var _diorama: ArenaV2Diorama


func _ready() -> void:
	var old := OS.get_environment("PREVIEW_OLD") != ""
	var boss := OS.get_environment("PREVIEW_BOSS") != ""
	_build_rig()
	# The old arena still provides the gate, sky, fog and sun tint, exactly as in a fight.
	_arena = CombatArena3D.new()
	_arena.name = "Arena"
	_arena.position = Vector3(0.0, 0.0, LANE_Z)
	_arena.rotation_degrees.y = -90.0
	add_child(_arena)
	_arena.build("savannah", _env, _sun, boss)
	if not old:
		ArenaV2Diorama.hide_old_arena_except_gate(_arena)
		_diorama = ArenaV2Diorama.new()
		_diorama.name = "ArenaV2"
		add_child(_diorama)
		_diorama.build("savannah")
	_add_stand_ins()
	if OS.get_environment("PREVIEW_SHOT") != "":
		await _shots("old" if old else "v2", boss)
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


## Capsules where the units stand: blue party (5, two staggered rows), red enemies (3 depth rows).
func _add_stand_ins() -> void:
	var party_mat := StandardMaterial3D.new()
	party_mat.albedo_color = Color(0.35, 0.6, 0.95)
	var enemy_mat := StandardMaterial3D.new()
	enemy_mat.albedo_color = Color(0.9, 0.35, 0.3)
	for i in 5:
		_capsule(Vector3(PARTY_X0 + i * PARTY_PITCH_X, 0.0, PARTY_Z[i % 2]), party_mat)
	for i in 3:
		_capsule(Vector3(ENEMY_CENTER_X + (i - 1.0) * ENEMY_PITCH_X, 0.0, ENEMY_Z[i]), enemy_mat)


func _capsule(at: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = 0.45
	m.height = 1.6
	mi.mesh = m
	mi.material_override = mat
	mi.position = at + Vector3(0.0, 0.8, 0.0)
	add_child(mi)


func _shots(tag: String, boss: bool) -> void:
	var out := OS.get_environment("ADT_EVIDENCE_DIR")
	if out == "":
		out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		get_window().size = size
		for _i in 10:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := "%s/v-preview-%s%s-%dx%d.png" % [out, tag, "-boss" if boss else "", size.x, size.y]
		get_tree().root.get_texture().get_image().save_png(path)
		print("QA: saved ", path.get_file())
