class_name LandHub
extends Node3D
## Land hub (Savannah, tier 1) — the screen the game opens to. R1 design: Dice UI R1 README §2 (01a-01d).
##
## Fixed orthographic camera over a Homeland diorama. Buildings are placed in 3D by projecting the
## R1 layout (centre-x, base-y on a 1920x1080 design canvas) onto the ground plane, so the 3D scene,
## the click boxes and the name plates all come from the same numbers. `dy = (H - 1080) / 2` keeps the
## Land centred when the window is taller (expand stretch); bars stay on their edges.
## Routing goes only through `LandNav` (l1-interfaces.md §7). Nothing here writes a save.

signal moon_card_requested

const LIB := "res://assets/land/homeland/scenes/HomeLand_Asset/"
const BLD := LIB + "Building_HomeLand/"
const HOUSES_JSON := "res://assets/land/houses.json"

# --- camera / projection (README §2: diamond 1800 wide, top tip 180, height 820 => pitch ~27 deg) ---
const VIEW_W_UNITS := 48.0          # ortho size = horizontal extent => 40 px per world unit at 1920
const PPU := 1920.0 / VIEW_W_UNITS
const PITCH := 27.0
const YAW := 45.0
const DIAMOND_CY := 590.0           # design-canvas y of the Land centre (180 + 820 / 2)
const PLOT_SIDE := 31.0

const INK_PLATE := Color("24140B")
const KEY_CHIP := Color("4A3570")
const BADGE_FILL := {"FREE": Color("8CC85A"), "CLAIM": Color("FF9345"), "NEW": Color("FFC445"), "VIP": Color("A27BEA")}
const BADGE_INK := {"FREE": Color("183A0C"), "CLAIM": Color("2A1505"), "NEW": Color("3A2A12"), "VIP": Color("1E1236")}
const LOCK_FILL := Color("E8D6B4")
const LOCK_BORDER := Color("9A7650")
const LOCK_TEXT := Color("6E4A30")

## QA / tests: force a tier (1-6) instead of reading MetaState.
static var tier_override: int = 0

## Building table. cx/base/w/h are R1 numbers (design px). `lv` buildings step up with the Land tier
## (core-loop-v2 §4.1: House lv1 at Savannah ... lv4 from Genesis, tier 5 and 6 stay lv4).
## `min_tier` = tier that builds it (README: Mastery Hall at Arctic).
const BUILDINGS: Array[Dictionary] = [
	{"id": "portal", "dir": "Portal", "pat": "SM_Portal_01", "cx": 960, "base": 640, "w": 360, "h": 360, "yaw": 0.0},
	{"id": "house", "dir": "House", "pat": "House_lv%d", "cx": 560, "base": 470, "w": 250, "h": 230, "yaw": 0.0},
	{"id": "missions", "dir": "Weaponsmith", "pat": "Weaponsmith_lv%d", "cx": 1360, "base": 470, "w": 210, "h": 250, "yaw": 0.0},
	{"id": "echobox", "dir": "Alchemy", "pat": "SM_Alchemy_lv%d_Prefab", "cx": 470, "base": 770, "w": 190, "h": 230, "yaw": 0.0},
	{"id": "pass", "dir": "EquipmentStall", "pat": "EquipmentStall_lv%d", "cx": 1450, "base": 770, "w": 210, "h": 230, "yaw": 0.0},
	{"id": "vault", "dir": "GemStorage", "pat": "GemStorage_lv%d", "cx": 235, "base": 650, "w": 200, "h": 200, "yaw": 0.0},
	{"id": "store", "dir": "Jeweler", "pat": "Jeweler_lv%d", "cx": 1685, "base": 650, "w": 190, "h": 230, "yaw": 0.0},
	{"id": "mastery", "dir": "Armorsmith", "pat": "Armorsmith_lv%d", "cx": 760, "base": 340, "w": 170, "h": 190, "yaw": 0.0, "min_tier": 3},
]
## Plots (never hidden). A plot is drawn while its building is not built; Gallery has no model yet.
const PLOTS: Array[Dictionary] = [
	{"id": "mastery", "cx": 760, "base": 340, "min_tier": 3},
	{"id": "gallery", "cx": 1160, "base": 330, "min_tier": 5},
]
const TIER_NAMES: Array[String] = ["Savannah", "Forest", "Arctic", "Mystic", "Genesis", "LunaLanding"]
## Fallback only: lane E's assets/data/economy/land_tiers.json is the source (cost to reach tier N+1).
const FALLBACK_TIER_COSTS: Array[int] = [40000, 100000, 180000, 500000, 1000000]
## Per biome look. Paths are under Environment/. ground = centre, mid, edge; cliff = top, bottom.
const BIOMES: Array[Dictionary] = [
	{"ground": ["FAD27C", "F2B652", "DE9A3C"], "cliff": "A9673A", "sky": ["8FCBF2", "F6E9C8"],
		"trees": ["Savannah/Tree/S_Tree01_Allside", "Savannah/Tree/S_Tree02_Allside", "Savannah/Tree/S_Tree03_Allside", "Savannah/Tree/S_Tree03a_Allside"],
		"shrubs": ["Savannah/Shrub/S_Shrub01_Allside", "Savannah/Shrub/S_Shrub02_Allside"],
		"rocks": ["Savannah/Rock/SavannahRock_01", "Savannah/Rock/SavannahRock_02"],
		"tufts": ["Savannah/Ground/S_TileGrass_02", "Savannah/Ground/S_TileGrass_03", "Savannah/Ground/S_TileGrass_04"]},
	{"ground": ["B8E27A", "8DCB5A", "64A845"], "cliff": "8A6A3E", "sky": ["8FD0F5", "EAF4D2"],
		"trees": ["Forest/Tree/F_Tree1_AllSide", "Forest/Tree/F_Tree2_AllSide"],
		"shrubs": ["Forest/Shrub/F_Shrub01_Allside", "Forest/Shrub/F_Shrub02_Allside"],
		"rocks": [],
		"tufts": ["Forest/Ground/F_TileGrass_02", "Forest/Ground/F_TileGrass_03", "Forest/Ground/F_TileGrass_04", "Forest/Ground/Flower/Flower_RandomColor"]},
	{"ground": ["F4FBF9", "D6ECE8", "B4D6D2"], "cliff": "7FA8A8", "sky": ["A9D8EE", "F2FAFA"],
		"trees": ["Arctic/Tree/A_Tree01_AllSide", "Arctic/Tree/A_Tree02_AllSide"],
		"shrubs": ["Arctic/Shrub/A_Shrub01_Allside", "Arctic/Shrub/A_Shrub02_Allside"],
		"rocks": ["Arctic/Props/Stone_01", "Arctic/Props/Stone_02"],
		"tufts": ["Arctic/Ground/TileSnow_02", "Arctic/Ground/TileSnow_03", "Arctic/Ground/TileSnow_04"]},
	{"ground": ["C9B2F0", "9E82D6", "6F58AE"], "cliff": "4A3A78", "sky": ["7F8CE0", "E6D6F7"],
		"trees": ["Mystic/Tree/M_Tree_01_Allside", "Mystic/Tree/M_Tree_02_Allside", "Mystic/Tree/M_Tree_03_Allside", "Mystic/Tree/M_Tree_04_Allside"],
		"shrubs": ["Mystic/Shrub/M_Shrub01_Allside", "Mystic/Shrub/M_Shrub02_Allside"],
		"rocks": ["Mystic/Rock/Rock_01", "Mystic/Rock/Rock_02"],
		"tufts": []},
	{"ground": ["FFF3C8", "F5D87E", "DDAE4E"], "cliff": "9A7A4A", "sky": ["9FD3F5", "FFF1D0"],
		"trees": ["Genesis/Tree/SM_Tree_G_01", "Genesis/Tree/SM_Tree_G_02", "Genesis/Tree/SM_Tree_G_03", "Genesis/Tree/SM_Tree_G_06"],
		"shrubs": ["Genesis/Shrub/G_Shrub01_Allside", "Genesis/Shrub/G_Shrub02_Allside"],
		"rocks": [], "tufts": []},
	{"ground": ["F6C2D0", "D8809F", "A34F78"], "cliff": "6A2E4C", "sky": ["2B2255", "9A5C8E"], "moon": true,
		"trees": ["LunaLanding/Tree/Luna_Landing_Tree_1 Variant", "LunaLanding/Tree/Luna_Landing_Tree_2 Variant", "LunaLanding/Tree/Luna_Landing_Tree_3 Variant"],
		"shrubs": ["LunaLanding/Shrub/L_Shrub01_Allside", "LunaLanding/Shrub/LunaLanding_Shrub_01"],
		"rocks": ["LunaLanding/Luna_Landing_Rock/SM_Luna_Landing_Rock_1 Variant", "LunaLanding/Luna_Landing_Rock/SM_Luna_Landing_Rock_2 Variant", "LunaLanding/Rock/SM_Rocks_Luna_A1 Variant", "LunaLanding/Rock/SM_Rocks_Luna_B Variant"],
		"tufts": []},
]
## Plate texts. key = shortcut number.
const META: Dictionary = {
	"portal": {"name": "Run", "key": 1, "sub": ""},
	"house": {"name": "House", "key": 2, "sub": "Team presets"},
	"missions": {"name": "Missions", "key": 3, "sub": ""},
	"echobox": {"name": "Echo Box", "key": 4, "sub": ""},
	"pass": {"name": "Season Pass", "key": 5, "sub": "Season 1 · ends 29 Dec 2026"},
	"vault": {"name": "Vault", "key": 6, "sub": ""},
	"store": {"name": "Store", "key": 7, "sub": ""},
	"mastery": {"name": "Mastery Hall", "key": 8, "sub": ""},
	"gallery": {"name": "Gallery", "key": 9, "sub": ""},
}

const PART_CLASSES := ["Plant", "Beast", "Aquatic", "Reptile", "Bug", "Bird"]
const VARIANTS_6 := [2, 4, 6, 8, 10, 12]
const VARIANTS_4 := [2, 4, 8, 10]
const COLOR_VARIANTS := [8, 3, 14, 30, 20, 26]
const BODIES := [AxieTypes.Body.NORMAL, AxieTypes.Body.FUZZY, AxieTypes.Body.CURLY,
	AxieTypes.Body.BIGYAK, AxieTypes.Body.FROSTY, AxieTypes.Body.WETDOG, AxieTypes.Body.SUMO, AxieTypes.Body.SPIKY]
const WANDERERS := 5                 # budget: ~0.22 ms each on M3 Pro (land_spike); iOS to be measured
const AXIE_SCALE := 1.2
const WALK_SPEED := 1.3
const RUN_SPEED := 3.2

var _rng := RandomNumberGenerator.new()
var _cam: Camera3D
var _g := Vector3.ZERO               # horizontal screen-up direction on the ground
var _right := Vector3.ZERO
var _scene_cache := {}
var _nodes3d := {}                   # id -> {node, scale}
var _blocked: Array[Dictionary] = [] # {p: Vector3, r: float}
var _lanes: Array[Array] = []        # [from, to] ground segments the Axies walk; props stay off them
var _hub := Vector3.ZERO             # where all lanes meet, in front of the Portal
var _axies: Array[Dictionary] = []

var _ui: Control
var _bar: PanelContainer
var _hits := {}                      # id -> Button (clickable box)
var _plates := {}                    # id -> Control (name plate / run plate)
var _badges := {}                    # id -> Control (pill on the box)
var _plot_marks := {}                # id -> Control
var _shortcuts := {}                 # key number -> Button
var _house_defs := {}                # house_id -> dictionary from houses.json
var _run_plate: Control
var _continue_panel: Control
var _toast: PanelContainer
var _toast_tween: Tween
var _modal: Control
var _has_run := false
var _tier := 1
var _live: Array[Dictionary] = []   # buildings built at this tier
var _plots: Array[Dictionary] = []  # plots still empty at this tier
var _upgrade_btn: Button
var _force_run := false   # QA capture only: draw the unfinished-run state without a save


func _ready() -> void:
	# Same onboarding gate MainMenu has: every entry to the game funnels through here.
	if MetaState.needs_tutorial():
		get_tree().change_scene_to_file("res://scenes/tutorial/Tutorial.tscn")
		return
	_rng.seed = 7
	_tier = _current_tier()
	for b in BUILDINGS:
		if _tier >= int(b.get("min_tier", 1)):
			_live.append(b)
	var live_ids := {}
	for b in _live:
		live_ids[String(b["id"])] = true
	for pl in PLOTS:
		if not live_ids.has(String(pl["id"])):
			_plots.append(pl)
	_load_houses()
	_has_run = _force_run or _has_open_run()
	_build_world()
	_build_ground()
	_build_buildings()
	_build_props()
	_build_ui()
	for i in WANDERERS:
		_spawn_axie()
	_layout()
	_account_entered.call_deferred()
	if _should_show_moon_card():
		show_moon_card.call_deferred()


func _exit_tree() -> void:
	for a in _axies:
		var ch: AxieCharacter3D = a["char"]
		if ch != null:
			ch.dispose()
	_axies.clear()


# ================================================================ data

func _load_houses() -> void:
	var arr = JSON.parse_string(FileAccess.get_file_as_string(HOUSES_JSON))
	if arr is Array:
		for h in arr:
			_house_defs[String(h.get("house_id", ""))] = h


func _has_open_run() -> bool:
	if RunState.has_method("has_open_run"):   # lane A, once remote runs exist
		return bool(RunState.call("has_open_run"))
	return RunState.has_saved_run()


func _meta_int(field: String) -> int:
	var v: Variant = MetaState.get(field)
	return int(v) if v != null else 0


func _badge_count(house_id: String) -> int:
	var def: Dictionary = _house_defs.get(house_id, {})
	var sid := String(def.get("badge_screen_id", ""))
	if sid == "" or not MetaState.has_method("badge_count"):
		return 0
	return int(MetaState.call("badge_count", StringName(sid)))


## Tier the player is on: test override, else MetaState.land_tier (lane E), else 1.
func _current_tier() -> int:
	if tier_override > 0:
		return clampi(tier_override, 1, 6)
	return clampi(maxi(_meta_int("land_tier"), 1), 1, 6)


## A house is locked while the Land tier is below houses.json `unlock.min_tier` (or runs below min_runs).
func _is_locked(house_id: String) -> bool:
	var u: Dictionary = (_house_defs.get(house_id, {}) as Dictionary).get("unlock", {})
	if u.has("min_tier") and _tier < int(u["min_tier"]):
		return true
	return u.has("min_runs") and MetaState.runs < int(u["min_runs"])


## Name of the Land that builds this house ("Arctic"), "" if it is not tier-gated.
func _need_name(house_id: String) -> String:
	var u: Dictionary = (_house_defs.get(house_id, {}) as Dictionary).get("unlock", {})
	if not u.has("min_tier"):
		return ""
	return TIER_NAMES[clampi(int(u["min_tier"]) - 1, 0, TIER_NAMES.size() - 1)]


## Cost in Land Stone to go from the current tier to the next. EconomyDB (lane E) wins when it exists.
func _upgrade_cost() -> int:
	if _tier >= 6:
		return 0
	var db := get_node_or_null("/root/EconomyDB")
	if db != null and db.has_method("land_tier_cost"):
		return int(db.call("land_tier_cost", _tier))
	return FALLBACK_TIER_COSTS[_tier - 1]


# ================================================================ 3D world

func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS   # the sky gradient lives on a CanvasLayer behind
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var biome: Dictionary = BIOMES[_tier - 1]
	env.ambient_light_color = Color("fff1d6")
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -30, 0)
	sun.light_energy = 1.25
	sun.light_color = Color("ffe2b0")   # warm late-afternoon sun
	sun.shadow_enabled = true
	sun.shadow_blur = 2.2            # soft penumbra
	sun.light_angular_distance = 0.6
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL   # one split: fastest on an ortho camera
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)

	var yaw := deg_to_rad(YAW)
	var pitch := deg_to_rad(PITCH)
	_g = Vector3(-sin(yaw), 0, -cos(yaw))
	_right = Vector3(cos(yaw), 0, -sin(yaw))
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.keep_aspect = Camera3D.KEEP_WIDTH
	_cam.size = VIEW_W_UNITS
	_cam.near = 0.1
	_cam.far = 200.0
	add_child(_cam)
	# Aim 50 design px above the Land centre so the centre sits at y=590 (README) rather than 540.
	var target := _g * ((DIAMOND_CY - 540.0) / PPU / sin(pitch))
	var offs := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * 60.0
	_cam.position = target + offs
	_cam.look_at(target, Vector3.UP)

	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -10
	add_child(sky_layer)
	var sky := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(String(biome["sky"][0])))
	grad.set_color(1, Color(String(biome["sky"][1])))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	sky.texture = gt
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky_layer.add_child(sky)
	if biome.get("moon", false):
		var moon := Panel.new()
		var msb := StyleBoxFlat.new()
		msb.bg_color = Color("FFF3D6")
		msb.set_corner_radius_all(70)
		moon.add_theme_stylebox_override("panel", msb)
		moon.size = Vector2(140, 140)
		moon.position = Vector2(1560, 120)
		moon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sky_layer.add_child(moon)


## Design-canvas point (x, y on 1920x1080) -> ground point, with the Land centre at (960, 590).
func _ground_at(sx: float, sy: float) -> Vector3:
	var up := (DIAMOND_CY - sy) / PPU / sin(deg_to_rad(PITCH))
	return _right * ((sx - 960.0) / PPU) + _g * up


func _build_ground() -> void:
	# Cliff: R1 draws it as the same diamond 36 px lower (#B87440 -> #8A4E28).
	var cliff := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(PLOT_SIDE, 3.0, PLOT_SIDE)
	cliff.mesh = box
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(String(BIOMES[_tier - 1]["cliff"]))
	cm.roughness = 1.0
	cliff.material_override = cm
	cliff.position.y = -1.5 - 0.02
	add_child(cliff)

	var top := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(PLOT_SIDE, PLOT_SIDE)
	top.mesh = plane
	var grad := Gradient.new()
	var gc: Array = BIOMES[_tier - 1]["ground"]
	grad.set_color(0, Color(String(gc[0])))
	grad.add_point(0.55, Color(String(gc[1])))
	grad.set_color(grad.get_point_count() - 1, Color(String(gc[2])))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	# Radial biome tint multiplied by the library's tileable dirt texture (luminance only, so
	# every biome gets the same mottled earth in its own colours).
	var tm := ShaderMaterial.new()
	tm.shader = _ground_shader()
	tm.set_shader_parameter("tint", gt)
	var dirt := load(DIRT_TEX) as Texture2D
	if dirt != null:
		tm.set_shader_parameter("dirt", dirt)
	top.material_override = tm
	add_child(top)


const DIRT_TEX := "res://assets/land/homeland/src/HomeLand_Asset/Environment/Savannah/Ground/Source/Land_Savannah_01_ground.png"


func _ground_shader() -> Shader:
	var sh := Shader.new()
	sh.code = """shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform sampler2D tint : source_color, repeat_disable;
uniform sampler2D dirt : source_color, repeat_enable, filter_linear_mipmap, hint_default_white;
void fragment() {
	vec3 t = texture(tint, UV).rgb;
	// The source texture is low-contrast, so measure each sample against its own blurred mean and
	// amplify the difference: mottled soil patches at two scales.
	float d1 = dot(texture(dirt, UV * 5.0).rgb - textureLod(dirt, UV * 5.0, 9.0).rgb, vec3(0.333));
	float d2 = dot(texture(dirt, UV * 1.7 + vec2(0.31, 0.57)).rgb - textureLod(dirt, UV * 1.7, 9.0).rgb, vec3(0.333));
	float m = clamp(1.0 + d1 * 7.0 + d2 * 9.0, 0.5, 1.2);
	// Darker patches shift toward damp earth brown, so the slab reads as soil, not paint.
	ALBEDO = mix(t * vec3(0.74, 0.6, 0.5), t, smoothstep(0.45, 1.0, m)) * min(m, 1.12);
	ROUGHNESS = 1.0;
}
"""
	return sh


func _build_buildings() -> void:
	var lv := mini(_tier, 4)
	for b in _live:
		var pat := String(b["pat"])
		var n := _inst(BLD + String(b["dir"]) + "/" + (pat % lv if "%d" in pat else pat) + ".tscn")
		if n == null:
			continue
		var ground := _ground_at(float(b["cx"]), float(b["base"]))
		var box := _aabb(n, Transform3D.IDENTITY)
		var h_units := float(b["h"]) / PPU
		var w_units := float(b["w"]) / PPU
		var s := minf(h_units / maxf(box.size.y, 0.01),
			w_units / maxf((box.size.x + box.size.z) * 0.7071, 0.01))
		n.scale = Vector3.ONE * s
		n.position = ground - Vector3(0, box.position.y * s, 0)
		# Facing fix per house lives in houses.json ("yaw"); the table default is 0.
		n.rotation_degrees.y = float((_house_defs.get(String(b["id"]), {}) as Dictionary).get("yaw", b["yaw"]))
		add_child(n)
		_nodes3d[String(b["id"])] = {"node": n, "scale": s}
		var reach := (box.size.x + box.size.z) * 0.5 * s * 0.5
		_blocked.append({"p": ground, "r": reach + 0.8})
		_blocked.append({"p": ground - _g * (reach + 1.5), "r": 2.6})   # name plate zone
	# Run plate zone under the Portal, plus a ~150 px (design) keep-out ring around the Portal itself.
	_blocked.append({"p": _ground_at(960, 700), "r": 4.5})
	_blocked.append({"p": _ground_at(960, 540), "r": 9.0})
	# Walking lanes: hub in front of the Portal -> the front of every other house.
	_hub = _ground_at(960, 760)
	for b in _live:
		if String(b["id"]) == "portal":
			continue
		_lanes.append([_hub, _ground_at(float(b["cx"]), float(b["base"]) + 70.0)])
	for p in _plots:
		_blocked.append({"p": _ground_at(float(p["cx"]), float(p["base"]) - 40.0), "r": 6.0})


func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var have := false
	if n is VisualInstance3D:
		out = xf * (n as VisualInstance3D).get_aabb()
		have = true
	for c in n.get_children():
		if c is Node3D:
			var sub := _aabb(c, xf * (c as Node3D).transform)
			if sub.size != Vector3.ZERO:
				out = sub if not have else out.merge(sub)
				have = true
	return out


func _build_props() -> void:
	var biome: Dictionary = BIOMES[_tier - 1]
	var half := PLOT_SIDE * 0.5 - 1.5
	# Trees stand on the far rim (design-canvas points) so none ever hides a building or a plot.
	var trees: Array = biome["trees"]
	var spots := [Vector2(300, 430), Vector2(1580, 410), Vector2(960, 232), Vector2(430, 340),
		Vector2(1490, 330), Vector2(700, 215), Vector2(1250, 215)]
	for i in spots.size():
		_place_fit(LIB + "Environment/" + String(trees[i % trees.size()]) + ".tscn",
			_ground_at(spots[i].x, spots[i].y), 6.0, true)
	var scatter: Array = []
	for k in (biome["shrubs"] as Array):
		scatter.append([k, 1.5])
	for k in (biome["rocks"] as Array):
		scatter.append([k, 1.3])
	var placed := 0
	var tries := 0
	while not scatter.is_empty() and placed < 30 and tries < 900:
		tries += 1
		var p := Vector3(_rng.randf_range(-half, half), 0, _rng.randf_range(-half, half))
		if _blocked_at(p, 1.5):
			continue
		var pick: Array = scatter[placed % scatter.size()]
		_place_fit(LIB + "Environment/" + String(pick[0]) + ".tscn", p, float(pick[1]), true)
		placed += 1
	var tufts: Array = biome["tufts"]
	placed = 0
	tries = 0
	while not tufts.is_empty() and placed < 60 and tries < 700:
		tries += 1
		var p := Vector3(_rng.randf_range(-half, half), 0, _rng.randf_range(-half, half))
		if _blocked_at(p, 0.5):
			continue
		_place_fit(LIB + "Environment/" + String(tufts[placed % tufts.size()]) + ".tscn", p, 1.6, false)
		placed += 1


## Place a prop scaled so its height (by_height) or footprint width is `target` world units.
func _place_fit(path: String, p: Vector3, target: float, by_height: bool) -> void:
	var n := _inst(path)
	if n == null:
		return
	var box := _aabb(n, Transform3D.IDENTITY)
	var dim := box.size.y if by_height else maxf(box.size.x, box.size.z)
	var s := target / maxf(dim, 0.01) * _rng.randf_range(0.85, 1.15)
	n.position = p - Vector3(0, box.position.y * s, 0)
	n.rotation_degrees.y = _rng.randf() * 360.0
	n.scale = Vector3.ONE * s
	add_child(n)
	_blocked.append({"p": p, "r": 0.9})


## True if `p` is closer than `margin` to a walking lane (props keep off the paths).
func _on_lane(p: Vector3, margin: float) -> bool:
	for l in _lanes:
		var a: Vector3 = l[0]
		var ab: Vector3 = (l[1] as Vector3) - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
		if p.distance_to(a + ab * t) < margin:
			return true
	return false


func _blocked_at(p: Vector3, margin: float) -> bool:
	if _on_lane(p, 1.6 + margin):
		return true
	for b in _blocked:
		if (b["p"] as Vector3).distance_to(p) < float(b["r"]) + margin:
			return true
	return false


func _inst(path: String) -> Node3D:
	var ps: PackedScene = _scene_cache.get(path)
	if ps == null:
		ps = load(path) as PackedScene
		if ps == null:
			push_warning("LandHub: cannot load " + path)
			return null
		_scene_cache[path] = ps
	return ps.instantiate() as Node3D


# ================================================================ wandering Axies

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
		return
	var holder := Node3D.new()
	add_child(holder)
	holder.add_child(ch.root)
	holder.scale = Vector3.ONE * AXIE_SCALE
	holder.position = _walk_point()
	ch.playable.set_default(AnimNames.Idle)
	ch.playable.play(AnimNames.Idle, "", true)
	_axies.append({"char": ch, "node": holder, "state": "idle", "t": _rng.randf_range(0.5, 3.0),
		"target": holder.position, "speed": 0.0})


func _walk_point() -> Vector3:
	if _lanes.is_empty():
		return _hub
	var l: Array = _lanes[_rng.randi() % _lanes.size()]
	return (l[0] as Vector3).lerp(l[1], _rng.randf())


## True if two ground points are not on the same lane segment (so the direct line is unsafe).
func _on_other_lane(a: Vector3, b: Vector3) -> bool:
	for l in _lanes:
		var p0: Vector3 = l[0]
		var ab: Vector3 = (l[1] as Vector3) - p0
		var ok := true
		for q in [a, b]:
			var t := clampf(((q as Vector3) - p0).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
			if (q as Vector3).distance_to(p0 + ab * t) > 0.6:
				ok = false
		if ok:
			return false
	return true


func _process(delta: float) -> void:
	for a in _axies:
		var node: Node3D = a["node"]
		var ch: AxieCharacter3D = a["char"]
		if a["state"] == "idle":
			a["t"] -= delta
			if a["t"] <= 0.0:
				var dest := _walk_point()
				# Different lane: go through the hub first so the straight line never cuts across props.
				a["via"] = [dest] if _on_other_lane(node.position, dest) else []
				a["target"] = _hub if not (a["via"] as Array).is_empty() else dest
				var run := _rng.randf() < 0.2
				a["speed"] = RUN_SPEED if run else WALK_SPEED
				a["state"] = "move"
				ch.playable.play(AnimNames.Run if run else AnimNames.Walk, "", true)
		else:
			var to: Vector3 = a["target"] - node.position
			to.y = 0
			var d := to.length()
			if d < 0.15 and not (a.get("via", []) as Array).is_empty():
				a["target"] = (a["via"] as Array).pop_back()
				continue
			if d < 0.15:
				a["state"] = "idle"
				a["t"] = _rng.randf_range(1.0, 4.5)
				ch.playable.play(AnimNames.Idle, "", true)
				continue
			var dir := to / d
			node.position += dir * minf(d, float(a["speed"]) * delta)
			node.rotation.y = lerp_angle(node.rotation.y, atan2(dir.x, dir.z), minf(1.0, delta * 10.0))


# ================================================================ UI

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_ui)
	_ui.resized.connect(_layout)

	# Click boxes first (under plates and bar).
	for b in _live:
		_add_house_hit(String(b["id"]))
	for p in _plots:
		_add_plot(String(p["id"]))
	for b in _live:
		var id := String(b["id"])
		if id != "portal":
			_plates[id] = _make_plate(id)
			_ui.add_child(_plates[id])
		var pill := _make_badge_pill(id)
		if pill != null:
			_badges[id] = pill
			_ui.add_child(pill)
	_build_run_plate()
	_build_bar()
	_build_toast()


func _add_house_hit(id: String) -> void:
	var btn := Button.new()
	btn.name = "Hit_" + id
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_on_house_pressed.bind(id))
	btn.mouse_entered.connect(_hover.bind(id, true))
	btn.mouse_exited.connect(_hover.bind(id, false))
	_ui.add_child(btn)
	_hits[id] = btn


func _hover(id: String, on: bool) -> void:
	if not _nodes3d.has(id):
		return
	var n: Node3D = _nodes3d[id]["node"]
	var s := float(_nodes3d[id]["scale"])
	var t := create_tween()
	t.tween_property(n, "scale", Vector3.ONE * s * (1.05 if on else 1.0), 0.12)


func _add_plot(id: String) -> void:
	var mark := PlotMark.new()
	mark.locked = _is_locked(id)
	mark.name = "Plot_" + id
	mark.mouse_filter = Control.MOUSE_FILTER_STOP
	mark.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mark.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_on_house_pressed(id))
	_ui.add_child(mark)
	_plot_marks[id] = mark
	var plate := _make_plate(id)
	_ui.add_child(plate)
	_plates[id] = plate


func _style(kind: DangoTheme.Surface, radius: int, border: int, pad: Vector2, border_color: Color = Color.BLACK) -> StyleBoxFlat:
	var sb := DangoTheme.surface_style(kind, radius, border, 0.0, pad)
	sb.border_color = border_color
	return sb


func _lbl(text: String, size: int, color: Color, display: bool = true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", DangoTheme.FONT_DISPLAY_BOLD if display else DangoTheme.FONT_UI)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _key_chip(key: int, size: int = 26) -> PanelContainer:
	var chip := PanelContainer.new()
	var sb := _style(DangoTheme.Surface.PANEL, 6, 0, Vector2(0, 0))
	sb.bg_color = KEY_CHIP
	chip.add_theme_stylebox_override("panel", sb)
	chip.custom_minimum_size = Vector2(size, size)
	var l := _lbl(str(key), size - 8, Color("FFF8EA"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(l)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return chip


func _make_plate(id: String) -> PanelContainer:
	var m: Dictionary = META[id]
	var locked := _is_locked(id)
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := _style(DangoTheme.Surface.CREAM, 12, 3, Vector2(14, 5), INK_PLATE)
	if locked:
		sb.bg_color = LOCK_FILL
		sb.border_color = LOCK_BORDER
	plate.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(row)
	row.add_child(_key_chip(int(m["key"])))
	row.add_child(_lbl(String(m["name"]), 22, DangoTheme.INK))
	var sub := String(m["sub"])
	if locked:
		sub = "Builds at %s Land" % _need_name(id)
	elif id == "gallery":
		sub = "Coming soon"
	if sub != "":
		var s := _lbl(sub, 18, LOCK_TEXT if locked else DangoTheme.INK_ON_CREAM_MUTED, false)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(s)
	return plate


func _make_badge_pill(id: String) -> Control:
	if _is_locked(id) or _badge_count(id) <= 0:
		return null
	var kind := "CLAIM"
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := _style(DangoTheme.Surface.CREAM, 15, 3, Vector2(10, 0))
	sb.bg_color = BADGE_FILL[kind]
	pill.add_theme_stylebox_override("panel", sb)
	pill.custom_minimum_size = Vector2(0, 30)
	pill.add_child(_lbl(kind, 14, BADGE_INK[kind]))
	return pill


func _build_run_plate() -> void:
	# Plain run plate (01a): 340x84, r18, border 4, primary.
	var plate := Button.new()
	plate.name = "RunPlate"
	plate.custom_minimum_size = Vector2(340, 84)
	plate.focus_mode = Control.FOCUS_ALL
	DangoTheme.style_button(plate, true)
	plate.pressed.connect(_on_run_pressed)
	var inner := HBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 14)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(inner)
	inner.add_child(_lbl("RUN", 38, DangoTheme.INK_ON_PRIMARY))
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_lbl("Enter the Portal", 15, DangoTheme.INK_ON_PRIMARY))
	col.add_child(_lbl("Run Setup", 12, DangoTheme.INK_ON_PRIMARY_DIM, false))
	inner.add_child(col)
	var enter := PanelContainer.new()
	enter.add_theme_stylebox_override("panel", _style(DangoTheme.Surface.PANEL, 6, 0, Vector2(8, 2)))
	enter.add_child(_lbl("Enter", 12, Color("FFF8EA")))
	enter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	inner.add_child(enter)
	_run_plate = plate
	_ui.add_child(plate)

	# Unfinished run (01b): 420-wide panel, Continue (h68, primary) + New run (h48) + note.
	var panel := PanelContainer.new()
	panel.name = "ContinuePanel"
	panel.add_theme_stylebox_override("panel", _style(DangoTheme.Surface.CREAM, 18, 4, Vector2(14, 14), INK_PLATE))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var cont := Button.new()
	cont.name = "ContinueButton"
	cont.custom_minimum_size = Vector2(0, 68)
	cont.text = "Continue run"
	DangoTheme.style_button(cont, true)
	cont.pressed.connect(_on_continue_pressed)
	v.add_child(cont)
	var line := _lbl(_continue_line(), 13, DangoTheme.INK_ON_CREAM_MUTED, false)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(line)
	var nr := Button.new()
	nr.name = "NewRunButton"
	nr.custom_minimum_size = Vector2(0, 48)
	nr.text = "New run"
	DangoTheme.style_button(nr, false)
	nr.pressed.connect(_on_new_run_pressed)
	v.add_child(nr)
	var note := _lbl("New run asks to confirm before it ends the current run.", 12, DangoTheme.INK_ON_CREAM_MUTED, false)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(note)
	panel.custom_minimum_size = Vector2(420, 0)
	_continue_panel = panel
	_ui.add_child(panel)
	_run_plate.visible = not _has_run
	_continue_panel.visible = _has_run


func _continue_line() -> String:
	if not _has_run:
		return ""
	return "%s · Ascension %d" % [String(RunState.mode).capitalize(), int(RunState.ascension)]


func _build_bar() -> void:
	_bar = PanelContainer.new()
	_bar.name = "ShortcutBar"
	_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bar.offset_left = 16
	_bar.offset_right = -16
	_bar.offset_top = 16
	_bar.custom_minimum_size = Vector2(0, 68)
	_bar.add_theme_stylebox_override("panel", _style(DangoTheme.Surface.CREAM, 20, 3, Vector2(10, 7), INK_PLATE))
	_ui.add_child(_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_bar.add_child(row)

	row.add_child(_profile_chip())
	for k in range(1, 10):
		var btn := _shortcut(k)
		_shortcuts[k] = btn
		row.add_child(btn)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	if _tier < 6:
		_upgrade_btn = _build_upgrade_button()
		row.add_child(_upgrade_btn)
	row.add_child(_currency("Gene Shard", _meta_int("shard_pool"), Color("FF9345"), false))
	row.add_child(_currency("Land Stone", _meta_int("land_stone"), Color("B8A27A"), false))
	row.add_child(_currency("Lunar Gem", _meta_int("lunar_gem"), Color("A27BEA"), true))
	row.add_child(_square_button("Codex", "?", &"codex"))
	row.add_child(_square_button("Settings", "", &"settings"))


func _profile_chip() -> Control:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _style(DangoTheme.Surface.CREAM_RAISED, 12, 3, Vector2(8, 4), INK_PLATE))
	chip.custom_minimum_size = Vector2(0, 52)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	chip.add_child(h)
	var name := "Player"
	if AccountService.is_signed_in():
		name = AccountService.display_name()
	var av := PanelContainer.new()
	var asb := _style(DangoTheme.Surface.PANEL, 20, 3, Vector2(0, 0))
	asb.bg_color = Color("FFC445")
	av.add_theme_stylebox_override("panel", asb)
	av.custom_minimum_size = Vector2(40, 40)
	var ini := _lbl(name.left(1).to_upper(), 20, DangoTheme.INK)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(ini)
	h.add_child(av)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_lbl(name.left(14), 15, DangoTheme.INK))
	col.add_child(_lbl("%s Land" % TIER_NAMES[_tier - 1], 12, DangoTheme.INK_ON_CREAM_MUTED, false))
	h.add_child(col)
	return chip


func _shortcut(k: int) -> Button:
	var id := ""
	for key in META:
		if int(META[key]["key"]) == k:
			id = key
	var locked := _is_locked(id) if id not in ["portal"] else false
	var btn := Button.new()
	btn.name = "Shortcut%d" % k
	btn.custom_minimum_size = Vector2(0, 52)
	btn.text = String(META[id]["name"]).replace("Season ", "").replace("Mastery Hall", "Mastery")
	if id == "portal":
		btn.text = "Run"
	elif id == "house":
		btn.text = "Teams"
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_font_override("font", DangoTheme.FONT_DISPLAY_BOLD)
	btn.add_theme_color_override("font_color", DangoTheme.INK)
	btn.add_theme_color_override("font_hover_color", DangoTheme.INK)
	btn.add_theme_color_override("font_pressed_color", DangoTheme.INK)
	btn.add_theme_color_override("font_focus_color", DangoTheme.INK)
	var fill := LOCK_FILL if locked else DangoTheme.CREAM_RAISED
	var border := LOCK_BORDER if locked else INK_PLATE
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := _style(DangoTheme.Surface.CREAM_RAISED, 12, 3, Vector2(14, 6), border)
		sb.bg_color = fill
		if st == "hover":
			sb.bg_color = DangoTheme.CREAM_HI
		if st == "focus":
			sb.border_color = DangoTheme.PRIMARY
		btn.add_theme_stylebox_override(st, sb)
	btn.pressed.connect(_on_house_pressed.bind(id))
	var hint := _lbl(_need_name(id) if locked else str(k), 12,
		LOCK_TEXT if locked else DangoTheme.INK_ON_CREAM_MUTED)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.offset_right = -6
	hint.offset_bottom = -2
	btn.add_child(hint)
	# Extra right padding so the label never collides with the key hint.
	for st in ["normal", "hover", "pressed", "focus"]:
		(btn.get_theme_stylebox(st) as StyleBoxFlat).content_margin_right = 22
	var dot := _badge_dot(id)
	if dot != null:
		btn.add_child(dot)
	return btn


func _badge_dot(id: String) -> Control:
	if _is_locked(id) or _badge_count(id) <= 0:
		return null
	var dot := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("FF9345")
	sb.set_corner_radius_all(9)
	sb.set_border_width_all(2)
	sb.border_color = INK_PLATE
	dot.add_theme_stylebox_override("panel", sb)
	dot.custom_minimum_size = Vector2(18, 18)
	dot.size = Vector2(18, 18)
	dot.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dot.position = Vector2(-12, -6)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return dot


func _currency(label: String, value: int, color: Color, plus: bool) -> Control:
	var chip := PanelContainer.new()
	chip.name = "Currency_" + label.replace(" ", "")
	chip.add_theme_stylebox_override("panel", _style(DangoTheme.Surface.CREAM_RAISED, 12, 3, Vector2(8, 2), INK_PLATE))
	chip.custom_minimum_size = Vector2(0, 44)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	chip.add_child(h)
	var dot := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(9)
	sb.set_border_width_all(2)
	sb.border_color = INK_PLATE
	dot.add_theme_stylebox_override("panel", sb)
	dot.custom_minimum_size = Vector2(18, 18)
	dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dot.tooltip_text = label
	h.add_child(dot)
	h.add_child(_lbl(_fmt(value), 16, DangoTheme.INK))
	if plus:
		var b := Button.new()
		b.text = "+"
		b.custom_minimum_size = Vector2(26, 26)
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_font_override("font", DangoTheme.FONT_DISPLAY_BOLD)
		b.add_theme_color_override("font_color", Color("FFF8EA"))
		for st in ["normal", "hover", "pressed", "focus"]:
			var pb := _style(DangoTheme.Surface.PANEL, 13, 2, Vector2(0, 0))
			pb.bg_color = Color("A27BEA")
			b.add_theme_stylebox_override(st, pb)
		b.pressed.connect(_on_house_pressed.bind("store"))
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
	return chip


func _build_upgrade_button() -> Button:
	var cost := _upgrade_cost()
	var b := Button.new()
	b.name = "UpgradeLand"
	b.custom_minimum_size = Vector2(0, 44)
	b.text = "Upgrade Land · %s" % _fmt(cost)
	b.tooltip_text = "Land Stone %s / %s → %s Land" % [_fmt(_meta_int("land_stone")), _fmt(cost), TIER_NAMES[_tier]]
	DangoTheme.style_button(b, true)
	b.add_theme_font_size_override("font_size", 15)
	b.disabled = _meta_int("land_stone") < cost
	b.pressed.connect(_on_upgrade_pressed)
	return b


func _on_upgrade_pressed() -> void:
	if _modal != null or _tier >= 6:
		return
	var cost := _upgrade_cost()
	_open_confirm("Upgrade to %s Land?" % TIER_NAMES[_tier],
		"Costs %s Land Stone. Your buildings level up and the Land changes look." % _fmt(cost),
		"Upgrade", _do_upgrade)


## Spending is lane E's job (MetaState.upgrade_land); this only asks and redraws the Land.
func _do_upgrade() -> void:
	_close_modal()
	if not MetaState.has_method("upgrade_land"):
		_show_toast("Land upgrades are not available yet")
		return
	if bool(MetaState.call("upgrade_land")):
		get_tree().reload_current_scene()
	else:
		_show_toast("Not enough Land Stone")


func _fmt(v: int) -> String:
	var s := str(v)
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += ","
		out += s[i]
	return out


func _square_button(tip: String, text: String, screen_id: StringName) -> Button:
	var b := Button.new()
	b.name = tip
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(48, 48)
	b.text = text
	b.add_theme_font_override("font", DangoTheme.FONT_DISPLAY_BOLD)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", DangoTheme.INK)
	if text == "":
		b.icon = load("res://assets/icons/web/settings.svg") as Texture2D
		b.expand_icon = true
		for ic in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
			b.add_theme_color_override(ic, DangoTheme.INK)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := _style(DangoTheme.Surface.CREAM_RAISED, 12, 3, Vector2(4, 4), INK_PLATE)
		if st == "hover":
			sb.bg_color = DangoTheme.CREAM_HI
		if st == "focus":
			sb.border_color = DangoTheme.PRIMARY
		b.add_theme_stylebox_override(st, sb)
	b.pressed.connect(_open_screen.bind(screen_id))
	return b


func _build_toast() -> void:
	_toast = PanelContainer.new()
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_theme_stylebox_override("panel", _style(DangoTheme.Surface.CREAM, 14, 3, Vector2(18, 8), INK_PLATE))
	_toast.add_child(_lbl("", 17, DangoTheme.INK))
	_ui.add_child(_toast)


func _show_toast(text: String) -> void:
	(_toast.get_child(0) as Label).text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast.reset_size()
	_toast.position = Vector2((_ui.size.x - _toast.size.x) * 0.5, 100)
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func() -> void: _toast.visible = false)


# ================================================================ layout (design px + dy)

func _layout() -> void:
	if _ui == null:
		return
	var dy := (_ui.size.y - 1080.0) * 0.5
	for b in _live:
		var id := String(b["id"])
		var w := float(b["w"])
		var h := float(b["h"])
		var cx := float(b["cx"])
		var base := float(b["base"]) + dy
		var hit: Button = _hits[id]
		hit.position = Vector2(cx - w * 0.5, base - h)
		hit.size = Vector2(w, h)
		if _plates.has(id):
			var plate: Control = _plates[id]
			plate.reset_size()
			plate.position = Vector2(cx - plate.get_combined_minimum_size().x * 0.5, base - 4.0)
		if _badges.has(id):
			var pill: Control = _badges[id]
			pill.reset_size()
			if _plates.has(id):
				var pl: Control = _plates[id]
				var pr := pl.position + Vector2(pl.get_combined_minimum_size().x, 0.0)
				pill.position = Vector2(pr.x - pill.get_combined_minimum_size().x * 0.6, pr.y - 20.0)
			else:
				pill.position = Vector2(cx + w * 0.5 - 6.0 - pill.get_combined_minimum_size().x, base - h + 4.0)
	for p in _plots:
		var id := String(p["id"])
		var cx := float(p["cx"])
		var base := float(p["base"]) + dy
		var mark: Control = _plot_marks[id]
		mark.size = Vector2(200, 108)
		mark.position = Vector2(cx - 100.0, base - 108.0)
		var plate: Control = _plates[id]
		plate.reset_size()
		plate.position = Vector2(cx - plate.get_combined_minimum_size().x * 0.5, base - 4.0)
	# Run plate / continue panel sit under the Portal.
	var portal_base := 640.0 + dy
	_run_plate.reset_size()
	_run_plate.position = Vector2(960.0 - 170.0, portal_base + 14.0)
	_continue_panel.reset_size()
	_continue_panel.position = Vector2(960.0 - 210.0, portal_base + 14.0)
	var portal_hit: Button = _hits["portal"]
	portal_hit.size.y = maxf(portal_hit.size.y, 1.0)


# ================================================================ actions

func _open_screen(screen_id: StringName) -> void:
	if not LandNav.is_available(screen_id):
		_show_toast("Coming soon")
		return
	LandNav.open(screen_id)


func _on_house_pressed(id: String) -> void:
	if id == "portal":
		_on_run_pressed()
		return
	if _is_locked(id):
		_show_toast("Builds at %s Land" % _need_name(id))
		return
	var def: Dictionary = _house_defs.get(id, {})
	_open_screen(StringName(String(def.get("screen_id", id))))


func _on_run_pressed() -> void:
	if _modal != null:
		return
	if _has_run:
		_on_continue_pressed()
		return
	_open_screen(&"run_setup")


func _on_continue_pressed() -> void:
	if not RunState.load_run():
		push_warning("LandHub: saved run could not be loaded")
		RunState.clear_saved_run()
		_has_run = false
		_run_plate.visible = true
		_continue_panel.visible = false
		_show_toast("That run could not be loaded")
		return
	if not RunState.resume_combat.is_empty():
		get_tree().change_scene_to_file("res://scenes/combat/Combat.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/run_map/RunMap.tscn")


func _on_new_run_pressed() -> void:
	_open_confirm("End the current run?",
		"Starting a new run ends the one in progress. Its rewards so far are not kept.",
		"End run, start new", func() -> void:
			RunState.clear_saved_run()
			_has_run = false
			LandNav.open(&"run_setup"), true)


func _open_confirm(title: String, body: String, ok_text: String, on_ok: Callable, warning: bool = false) -> void:
	if _modal != null:
		return
	_modal = Control.new()
	_modal.name = "Confirm"
	_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	panel.add_theme_stylebox_override("panel", _style(DangoTheme.Surface.CREAM, 22, 4, Vector2(24, 20), INK_PLATE))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(_lbl(title, 26, DangoTheme.INK))
	var msg := _lbl(body, 14, DangoTheme.INK_ON_CREAM_SOFT, false)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size = Vector2(470, 0)
	v.add_child(msg)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.custom_minimum_size = Vector2(0, 52)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DangoTheme.style_button(cancel, false)
	cancel.pressed.connect(_close_modal)
	row.add_child(cancel)
	var ok := Button.new()
	ok.name = "ConfirmOk"
	ok.text = ok_text
	ok.custom_minimum_size = Vector2(0, 52)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DangoTheme.style_button(ok, true, warning)
	ok.pressed.connect(on_ok)
	row.add_child(ok)
	_ui.add_child(_modal)
	cancel.grab_focus()


func _close_modal() -> void:
	if _modal != null:
		_modal.queue_free()
		_modal = null


func _unhandled_key_input(event: InputEvent) -> void:
	var ke := event as InputEventKey
	if ke == null or not ke.pressed or ke.echo:
		return
	if ke.keycode == KEY_ESCAPE:
		if _modal != null:
			_close_modal()
			get_viewport().set_input_as_handled()
		return
	if _modal != null:
		return
	var k := ke.keycode - KEY_0
	if ke.keycode >= KEY_KP_0 and ke.keycode <= KEY_KP_9:
		k = ke.keycode - KEY_KP_0
	if k >= 1 and k <= 9 and _shortcuts.has(k):
		(_shortcuts[k] as Button).emit_signal("pressed")
		get_viewport().set_input_as_handled()
	elif ke.keycode in [KEY_ENTER, KEY_KP_ENTER] and get_viewport().gui_get_focus_owner() == null:
		_on_run_pressed()
		get_viewport().set_input_as_handled()


# ================================================================ accounts + Moon Card hook

## Same entry duties MainMenu had (accounts doc §7): apply a cloud save that arrived mid-run,
## explain a sign-in error, offer the first-launch panel.
func _account_entered() -> void:
	AccountService.menu_entered()
	AccountService.show_pending_error()
	if AccountService.should_offer_welcome():
		AccountService.mark_welcome_shown()
		AccountUI.show_welcome(AccountService._ui_layer())


## Hook for lane M/E (R1 01c: second-day login, at most once a day, never on the defeat screen).
## Returns false until the rule exists; the popup itself is `res://scenes/store/MoonCardPopup.tscn`.
func _should_show_moon_card() -> bool:
	return false


func show_moon_card() -> void:
	moon_card_requested.emit()
	var path := "res://scenes/store/MoonCardPopup.tscn"
	if ResourceLoader.exists(path):
		var popup := (load(path) as PackedScene).instantiate()
		_ui.add_child(popup)


# ================================================================ plot marker

## Dashed diamond with a lock (R1 "Empty plot"): 200x108, 3 px dashed #8A3E22.
class PlotMark extends Control:
	var locked := true

	func _draw() -> void:
		var c := size * 0.5
		var pts := PackedVector2Array([Vector2(c.x, 0), Vector2(size.x, c.y), Vector2(c.x, size.y), Vector2(0, c.y)])
		draw_colored_polygon(pts, Color(0.91, 0.84, 0.71, 0.55))
		for i in 4:
			draw_dashed_line(pts[i], pts[(i + 1) % 4], Color("8A3E22"), 3.0, 9.0)
		if not locked:
			return
		# Lock: body + shackle.
		var body := Rect2(c.x - 11, c.y - 4, 22, 18)
		draw_rect(body, Color("9A7650"))
		draw_rect(body, Color("24140B"), false, 2.0)
		draw_arc(Vector2(c.x, c.y - 4), 7.0, PI, TAU, 12, Color("24140B"), 3.0)
