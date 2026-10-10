extends Node3D
## THROWAWAY SPIKE (prototype standards, see README.md). Does a living 3D Land — Homeland
## Savannah plot, four buildings, Axies wandering with Walk/Run/Idle — look right and run fast
## enough? Nothing in the game references this folder.
##
## Run:   godot --path godot res://prototypes/land_spike/LandSpike.tscn
## Bench: godot --path godot res://prototypes/land_spike/LandSpike.tscn -- --axies=20 --bench=10 --shot=/tmp/x.png
## Keys:  wheel zoom · right/middle drag or WASD pan · +/- five Axies more/less · click a building

const LIB := "res://prototypes/land_spike/homeland/scenes/HomeLand_Asset/"
const SAV := LIB + "Environment/Savannah/"
const BLD := LIB + "Building_HomeLand/"

# Ground plot is 300 units wide as imported (different unit scale from the props); 0.1 -> 30x30.
const PLOT_SCALE := 0.1
const HALF := 15.0

const BUILDINGS := [
	{"key": "portal", "label": "PORTAL\nvào run", "scene": BLD + "Portal/SM_Portal_01.tscn", "pos": Vector3(0, 0, -10), "rot": 0.0, "r": 3.5},
	{"key": "echo", "label": "ECHO BOX\ngacha", "scene": BLD + "Alchemy/SM_Alchemy_lv1_Prefab.tscn", "pos": Vector3(-9, 0, -4), "rot": 30.0, "r": 3.5},
	{"key": "contract", "label": "HỢP ĐỒNG\nrisk to earn", "scene": BLD + "SpyQuarter/SpyQuarter_F_01.tscn", "pos": Vector3(8.5, 0, -4), "rot": -30.0, "r": 6.0},
	{"key": "house", "label": "NHÀ", "scene": BLD + "House/House_lv1.tscn", "pos": Vector3(-8, 0, 8), "rot": 45.0, "r": 4.0},
]
const TREES := ["S_Tree01_Allside", "S_Tree02_Allside", "S_Tree03_Allside", "S_Tree03a_Allside"]
const SHRUBS := ["S_Shrub01_Allside", "S_Shrub02_Allside", "S_Shrub03_Allside"]
const ROCKS := ["SavannahRock_01", "SavannahRock_02"]
const TUFTS := ["S_TileGrass_02", "S_TileGrass_03", "S_TileGrass_04"]

const PART_CLASSES := ["Plant", "Beast", "Aquatic", "Reptile", "Bug", "Bird"]
const VARIANTS_6 := [2, 4, 6, 8, 10, 12]   # back / ear / horn / tail
const VARIANTS_4 := [2, 4, 8, 10]          # eye / mouth
const COLOR_VARIANTS := [8, 3, 14, 30, 20, 26]
const BODIES := [AxieTypes.Body.NORMAL, AxieTypes.Body.FUZZY, AxieTypes.Body.CURLY,
	AxieTypes.Body.BIGYAK, AxieTypes.Body.FROSTY, AxieTypes.Body.WETDOG, AxieTypes.Body.SUMO, AxieTypes.Body.SPIKY]

const WALK_SPEED := 1.3
const RUN_SPEED := 3.2
# Homeland buildings are ~5 units tall; the combat rig is ~1. 1.7 reads like Homeland's own ratio.
const AXIE_SCALE := 1.7

var _rng := RandomNumberGenerator.new()
var _cam: Camera3D
var _cam_target := Vector3(0, 0, -1)
var _cam_dist := 40.0
var _hud: Label
var _axies: Array = []          # {char, node, state, t, target, speed}
var _labels := {}               # key -> Label3D
var _selected := ""
var _dragging := false
var _scene_cache := {}

var _bench_secs := 0.0
var _shot := ""
var _elapsed := 0.0
var _frames: PackedFloat32Array = []
var _no_anim := false
var _proc_ms := 0.0
var _gpu_ms := 0.0
var _cpu_render_ms := 0.0
var _no_axie_shadow := false
var _no_outline := false


func _ready() -> void:
	_rng.seed = 7
	var want_axies := 8
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--axies="):
			want_axies = int(a.get_slice("=", 1))
		elif a.begins_with("--bench="):
			_bench_secs = float(a.get_slice("=", 1))
		elif a.begins_with("--shot="):
			_shot = a.get_slice("=", 1)
		elif a == "--combine":
			AxieCharacter3D.default_combine_meshes = true
		elif a == "--noanim":
			_no_anim = true
		elif a == "--noshadow":
			_no_axie_shadow = true
		elif a == "--nooutline":
			_no_outline = true
	if _bench_secs > 0.0:
		# Measure the frame, not the display: uncap vsync and max_fps.
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
	_build_world()
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_build_ground()
	_build_buildings()
	_build_props()
	_build_hud()
	_set_axie_count(want_axies)


# ---------------------------------------------------------------- world

func _build_world() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("8fc6ff")
	sky_mat.sky_horizon_color = Color("e9e4d0")
	sky_mat.ground_horizon_color = Color("e9e4d0")
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)

	_cam = Camera3D.new()
	_cam.fov = 35.0
	add_child(_cam)
	_update_camera()


func _update_camera() -> void:
	var yaw := deg_to_rad(45.0)
	var pitch := deg_to_rad(42.0)
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * _cam_dist
	_cam.position = _cam_target + offset
	_cam.look_at(_cam_target, Vector3.UP)


func _build_ground() -> void:
	# Wide flat skirt so the plot does not float in the sky colour.
	var skirt := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(160, 160)
	skirt.mesh = plane
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("c9a45c")
	m.roughness = 1.0
	skirt.material_override = m
	skirt.position.y = -0.05
	add_child(skirt)

	var plot := _inst(SAV + "Ground/S_Plot_Module_3x3.tscn")
	if plot:
		plot.scale = Vector3.ONE * PLOT_SCALE
		add_child(plot)
	# Stone path from the centre to the portal.
	for i in 5:
		var tile := _inst(SAV + "Decoration/StonePath/S_StonePath_Straight.tscn")
		if tile:
			tile.position = Vector3(0, 0.01, -1.9 * i)
			add_child(tile)


func _build_buildings() -> void:
	for b in BUILDINGS:
		var n := _inst(b["scene"])
		if n == null:
			continue
		n.position = b["pos"]
		n.rotation_degrees.y = b["rot"]
		add_child(n)
		var lbl := Label3D.new()
		lbl.text = b["label"]
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.font_size = 64
		lbl.pixel_size = 0.01
		lbl.outline_size = 14
		lbl.modulate = Color("fff4d6")
		lbl.position = b["pos"] + Vector3(0, 8.0 if b["key"] == "portal" else 6.5, 0)
		add_child(lbl)
		_labels[b["key"]] = lbl


func _build_props() -> void:
	# Trees and big shrubs ring the edge, rocks and tufts scatter over the whole plot; nothing
	# lands on a building or on the walking area in the middle.
	for i in 10:
		_place_random(SAV + "Tree/" + TREES[i % TREES.size()] + ".tscn", true, 0.7, true)
	for i in 8:
		_place_random(SAV + "Shrub/" + SHRUBS[i % SHRUBS.size()] + ".tscn", true, 0.45)
	for i in 6:
		_place_random(SAV + "Rock/" + ROCKS[i % ROCKS.size()] + ".tscn", false, 0.6)
	for i in 5:
		_place_random(SAV + "Ground/Flower/Cattail2.tscn", false, 0.6)
	for i in 70:
		_place_random(SAV + "Ground/" + TUFTS[i % TUFTS.size()] + ".tscn", false, 1.6)


func _place_random(path: String, edge: bool, scale: float, back_only: bool = false) -> void:
	var n := _inst(path)
	if n == null:
		return
	var p := Vector3.ZERO
	for attempt in 40:
		if edge:
			# The camera sits at +x+z; "back" is the half facing away from it, so tall trees
			# never stand between the camera and the plot.
			var a := _rng.randf() * TAU
			if back_only:
				a = deg_to_rad(_rng.randf_range(135.0, 315.0))
			var r := _rng.randf_range(12.0, 14.5)
			p = Vector3(cos(a) * r, 0, sin(a) * r)
		else:
			p = Vector3(_rng.randf_range(-HALF + 1, HALF - 1), 0, _rng.randf_range(-HALF + 1, HALF - 1))
		if not _blocked(p, 1.0):
			break
	n.position = p
	n.rotation_degrees.y = _rng.randf() * 360.0
	n.scale = Vector3.ONE * scale * _rng.randf_range(0.85, 1.15)
	add_child(n)


func _blocked(p: Vector3, margin: float) -> bool:
	for b in BUILDINGS:
		if p.distance_to(b["pos"]) < float(b["r"]) + margin:
			return true
	return absf(p.x) < 1.5 and p.z < 0.5 and p.z > -9.0   # the stone path


func _inst(path: String) -> Node3D:
	var ps: PackedScene = _scene_cache.get(path)
	if ps == null:
		ps = load(path) as PackedScene
		if ps == null:
			push_warning("spike: cannot load " + path)
			return null
		_scene_cache[path] = ps
	return ps.instantiate() as Node3D


# ---------------------------------------------------------------- axies

func _set_axie_count(n: int) -> void:
	n = clampi(n, 0, 200)
	while _axies.size() > n:
		var a: Dictionary = _axies.pop_back()
		(a["char"] as AxieCharacter3D).dispose()
		(a["node"] as Node3D).queue_free()
	while _axies.size() < n:
		_spawn_axie()


func _spawn_axie() -> void:
	var desc := AxieDescriptor.new()
	desc.body = BODIES[_rng.randi() % BODIES.size()]
	desc.color_variant = COLOR_VARIANTS[_rng.randi() % COLOR_VARIANTS.size()]
	var parts: Array[AxiePartDescriptor] = []
	for pt in [AxieTypes.Part.MOUTH, AxieTypes.Part.HORN, AxieTypes.Part.BACK,
			AxieTypes.Part.TAIL, AxieTypes.Part.EAR, AxieTypes.Part.EYE]:
		var vars: Array = VARIANTS_4 if pt in [AxieTypes.Part.MOUTH, AxieTypes.Part.EYE] else VARIANTS_6
		parts.append(AxiePartDescriptor.new(pt, 0, PART_CLASSES[_rng.randi() % 6], vars[_rng.randi() % vars.size()], 1))
	desc.parts = parts
	var ch := AxieCharacter3D.from_descriptor(desc)
	if ch == null or ch.root == null:
		push_warning("spike: Axie build failed")
		return
	var holder := Node3D.new()
	add_child(holder)
	holder.add_child(ch.root)
	holder.scale = Vector3.ONE * AXIE_SCALE
	if _no_axie_shadow or _no_outline:
		_strip(ch.root)
	holder.position = _random_walk_point()
	ch.playable.set_default(AnimNames.Idle)
	if _no_anim:
		ch.playable.stop()
	else:
		ch.playable.play(AnimNames.Idle, "", true)
	_axies.append({"char": ch, "node": holder, "state": "idle", "t": _rng.randf_range(0.5, 3.0),
		"target": holder.position, "speed": 0.0})


func _strip(n: Node) -> void:
	if n is GeometryInstance3D:
		var g := n as GeometryInstance3D
		if _no_axie_shadow:
			g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if _no_outline and n is MeshInstance3D:
			var mi := n as MeshInstance3D
			for i in mi.get_surface_override_material_count():
				var m := mi.get_active_material(i)
				if m != null and m.next_pass != null:
					var c := m.duplicate() as Material
					c.next_pass = null
					mi.set_surface_override_material(i, c)
	for c in n.get_children():
		_strip(c)


func _random_walk_point() -> Vector3:
	for attempt in 30:
		var p := Vector3(_rng.randf_range(-11, 11), 0, _rng.randf_range(-11, 11))
		if not _blocked(p, 0.8):
			return p
	return Vector3(0, 0, 3)


func _tick_axies(delta: float) -> void:
	if _no_anim:
		return
	for a in _axies:
		var node: Node3D = a["node"]
		var ch: AxieCharacter3D = a["char"]
		if a["state"] == "idle":
			a["t"] -= delta
			if a["t"] <= 0.0:
				a["target"] = _random_walk_point()
				var run := _rng.randf() < 0.25
				a["speed"] = RUN_SPEED if run else WALK_SPEED
				a["state"] = "move"
				ch.playable.play(AnimNames.Run if run else AnimNames.Walk, "", true)
		else:
			var to: Vector3 = a["target"] - node.position
			to.y = 0
			var d := to.length()
			if d < 0.15:
				a["state"] = "idle"
				a["t"] = _rng.randf_range(1.0, 4.5)
				ch.playable.play(AnimNames.Idle, "", true)
				continue
			var dir := to / d
			node.position += dir * minf(d, float(a["speed"]) * delta)
			# Model forward is +Z (CombatStage3D faces the party with 180 deg to look at -Z).
			var want := atan2(dir.x, dir.z)
			node.rotation.y = lerp_angle(node.rotation.y, want, minf(1.0, delta * 10.0))


# ---------------------------------------------------------------- input, hud, bench

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_cam_dist = maxf(12.0, _cam_dist * 0.9)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_cam_dist = minf(90.0, _cam_dist * 1.1)
		elif mb.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_dragging = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_pick(mb.position)
		_update_camera()
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		var right := _cam.global_transform.basis.x
		var fwd := Vector3(-right.z, 0, right.x)
		_cam_target -= (right * mm.relative.x - fwd * mm.relative.y) * _cam_dist * 0.0015
		_update_camera()
	elif event is InputEventKey and event.pressed:
		var k := (event as InputEventKey).keycode
		if k in [KEY_PLUS, KEY_EQUAL, KEY_KP_ADD]:
			_set_axie_count(_axies.size() + 5)
		elif k in [KEY_MINUS, KEY_KP_SUBTRACT]:
			_set_axie_count(_axies.size() - 5)


func _pick(screen: Vector2) -> void:
	var best := ""
	var best_d := 90.0
	for b in BUILDINGS:
		var p: Vector3 = b["pos"] + Vector3(0, 2.5, 0)
		if _cam.is_position_behind(p):
			continue
		var d := _cam.unproject_position(p).distance_to(screen)
		if d < best_d:
			best_d = d
			best = b["key"]
	_selected = best
	for key in _labels:
		(_labels[key] as Label3D).modulate = Color("ffd34d") if key == _selected else Color("fff4d6")
	if best != "":
		print("spike: clicked ", best)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(16, 12)
	_hud.add_theme_font_size_override("font_size", 18)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 6)
	layer.add_child(_hud)


func _process(delta: float) -> void:
	var kd := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if kd != Vector2.ZERO:
		var right := _cam.global_transform.basis.x
		var fwd := Vector3(-right.z, 0, right.x)
		_cam_target += (right * kd.x - fwd * kd.y) * delta * 14.0
		_update_camera()
	_tick_axies(delta)

	var rm := str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	var rd := RenderingServer.get_current_rendering_method()
	_hud.text = "FPS %d  (%.1f ms)\nAxies %d   draw calls %d   prims %dk   objects %d\nrenderer %s   video mem %d MB\n%s" % [
		Engine.get_frames_per_second(), delta * 1000.0, _axies.size(),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME) / 1000,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		rd if rd != "" else rm,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576,
		("selected: " + _selected) if _selected != "" else "click a building · +/- Axies"]

	if _bench_secs > 0.0:
		_elapsed += delta
		if _elapsed > 2.0:
			_frames.append(delta)
			_proc_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			_gpu_ms += RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
			_cpu_render_ms += RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid())
		if _elapsed > 2.0 + _bench_secs:
			_finish_bench(rd if rd != "" else rm)


func _finish_bench(renderer: String) -> void:
	_bench_secs = 0.0
	var sorted := _frames.duplicate()
	sorted.sort()
	var sum := 0.0
	for f in _frames:
		sum += f
	var avg_ms := sum / _frames.size() * 1000.0
	var nf := float(_frames.size())
	print("BENCH split process_ms=%.2f render_cpu_ms=%.2f render_gpu_ms=%.2f" % [_proc_ms / nf, _cpu_render_ms / nf, _gpu_ms / nf])
	var p99_ms: float = sorted[int(sorted.size() * 0.99) - 1] * 1000.0
	print("BENCH axies=%d renderer=%s frames=%d avg_ms=%.2f avg_fps=%.1f p99_ms=%.2f draw_calls=%d prims=%d vmem_mb=%d" % [
		_axies.size(), renderer, _frames.size(), avg_ms, 1000.0 / avg_ms, p99_ms,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576])
	if _shot != "":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_shot)
		print("BENCH shot ", _shot)
	get_tree().quit()
