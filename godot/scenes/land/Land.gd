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
const DIAMOND_CY := 530.0           # v5: design-canvas y of the Land centre (lattice moved up 60 px)
const PLOT_SIDE := 31.0

const INK_PLATE := Color("24140B")
const _Econ := preload("res://scripts/meta/economy_db.gd")
const KEY_CHIP := Color("4A3570")
const BADGE_FILL := {"FREE": Color("8CC85A"), "CLAIM": Color("FF9345"), "NEW": Color("FFC445"),
	"OFFLINE": Color("CFC4B0"), "LOCKED": Color("CFC4B0"), "···": Color("E6D9C0")}
const BADGE_INK := {"FREE": Color("183A0C"), "CLAIM": Color("2A1505"), "NEW": Color("3A2A12"),
	"OFFLINE": Color("3A2214"), "LOCKED": Color("3A2214"), "···": Color("8A6E50")}
## Word on the pill when the entry has something waiting (MetaState.badge_count > 0).
const BADGE_KIND := {"echobox": "FREE", "vault": "NEW", "store": "NEW", "pass": "CLAIM", "missions": "CLAIM", "daily": "CLAIM"}
const ONLINE_ONLY := ["echobox", "pass", "store", "board", "daily"]
const NEWCOMER_LOCK := ["missions", "board"]
## Keys 1-7 -> entry id (v5 key table; 8 is unused: Mastery Hall is cut).
const NUM_KEYS := ["portal", "house", "missions", "echobox", "pass", "vault", "store"]
const LOCK_FILL := Color("E8D6B4")
const LOCK_BORDER := Color("9A7650")
const LOCK_TEXT := Color("6E4A30")

## QA / tests: force a tier (1-6) instead of reading MetaState.
static var tier_override: int = 0

## Building table. cx/base/w/h are R1 numbers (design px). `lv` buildings step up with the Land tier
## (core-loop-v2 §4.1: House lv1 at Savannah ... lv4 from Genesis, tier 5 and 6 stay lv4).
## `min_tier` = tier that builds it (README: Mastery Hall at Arctic).
const BUILDINGS: Array[Dictionary] = [
	# v5 3x3 lattice around the Portal: step (300, 150) / (300, -150) design px; c = 530 is the centre.
	{"id": "portal", "dir": "Portal", "pat": "SM_Portal_01", "cx": 960, "base": 580, "w": 300, "h": 300, "yaw": 0.0},
	{"id": "house", "dir": "House", "pat": "House_lv%d", "cx": 360, "base": 590, "w": 200, "h": 196, "w3": 200, "h3": 178},
	{"id": "missions", "dir": "Weaponsmith", "pat": "Weaponsmith_lv%d", "fixed_lv": 1, "cx": 1260, "base": 440, "w": 190, "h": 213},
	{"id": "echobox", "dir": "Alchemy", "pat": "SM_Alchemy_lv%d_Prefab", "cx": 660, "base": 740, "w": 150, "h": 176, "w3": 140, "h3": 204},
	{"id": "pass", "dir": "EquipmentStall", "pat": "EquipmentStall_lv%d", "cx": 1260, "base": 740, "w": 190, "h": 188, "w3": 150, "h3": 213},
	{"id": "vault", "dir": "GemStorage", "pat": "GemStorage_lv%d", "cx": 960, "base": 890, "w": 170, "h": 168, "w3": 125, "h3": 201},
	{"id": "store", "dir": "Jeweler", "pat": "Jeweler_lv%d", "cx": 1560, "base": 590, "w": 150, "h": 183, "w3": 160, "h3": 194},
	{"id": "board", "path": "Item/Land_reward_ss2_ss3/SM_Billboard_Big", "cx": 960, "base": 290, "w": 130, "h": 190, "yaw": 45.0},
	# Gallery: stand-in mesh (old Armorsmith) until lane I names the real one. Built from Genesis (5).
	{"id": "gallery", "dir": "Armorsmith", "pat": "Armorsmith_lv%d", "cx": 660, "base": 440, "w": 160, "h": 135, "yaw": 0.0, "min_tier": 5},
]
## Empty plot (never hidden) shows while its building is not built.
const PLOTS: Array[Dictionary] = [
	{"id": "gallery", "cx": 660, "base": 440, "min_tier": 5},
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
	"portal": {"name": "Run", "key": "1", "sub": ""},
	"house": {"name": "House", "key": "2", "sub": "Team presets"},
	"missions": {"name": "Missions", "key": "3", "sub": "Missions N1–N3"},
	"echobox": {"name": "Echo Box", "key": "4", "sub": "Rolled on the server"},
	"pass": {"name": "Season Pass", "key": "5", "sub": "Season 1 · ends 29 Dec 2026"},
	"vault": {"name": "Vault", "key": "6", "sub": ""},
	"store": {"name": "Store", "key": "7", "sub": ""},
	"board": {"name": "Leaderboard", "key": "B", "sub": "Season ranking"},
	"gallery": {"name": "Gallery", "key": "", "sub": "Coming soon"},
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
var _hits := {}                      # id -> Button (clickable box)
var _plates := {}                    # id -> Control (name plate / run plate)
var _badges := {}                    # id -> Control (pill on the box)
var _plot_marks := {}                # id -> Control
var _house_defs := {}                # house_id -> dictionary from houses.json
var _run_plate: Control
var _toast: PanelContainer
var _toast_tween: Tween
var _modal: Control
var _has_run := false
var _tier := 1
var _live: Array[Dictionary] = []   # buildings built at this tier
var _plots: Array[Dictionary] = []  # plots still empty at this tier
var _hud_tl: HBoxContainer
var _rail: VBoxContainer
var _wallet: HBoxContainer
var _dock: PanelContainer
var _new_run_btn: Button
var _start_hint: Control
var _offline_banner: Control
var _names_btn: Button
var _run_title: Label
var _names_on := false
var _hover_id := ""
var _focus_id := ""
var _touch_id := ""
var _touch_mode := false
var _offline := false
var _loading := false
var _guest := false
var _newcomer := false
var _first := false
var _mission_run := false
## QA / tests only: force a state. Keys: offline, loading, guest, newcomer, first_launch, mission.
static var qa: Dictionary = {}
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
	RunState.discard_unresumable_run()
	_has_run = _force_run or _has_open_run()
	_offline = _flag("offline", _detect_offline())
	_loading = _flag("loading", false)
	_guest = _flag("guest", not AccountService.is_signed_in())
	_newcomer = _flag("newcomer", MetaState.is_newcomer())
	_first = _flag("first_launch", MetaState.runs == 0)
	_touch_mode = _flag("touch", false)
	_mission_run = _has_run and _flag("mission", not MetaState.mission_escrow.is_empty())
	_build_world()
	_build_ground()
	_build_buildings()
	_build_props()
	_build_ui()
	for i in WANDERERS:
		_spawn_axie()
	_layout()
	var _notice := RunState.take_discard_notice()
	if _notice != "":
		_show_toast(_notice, 5.0)
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

func _flag(key: String, real: bool) -> bool:
	return bool(qa[key]) if qa.has(key) else real


## Hook: no connectivity probe exists yet. AccountService.is_online() is used once it does.
func _detect_offline() -> bool:
	var a := get_node_or_null("/root/AccountService")
	return a != null and a.has_method("is_online") and not bool(a.call("is_online"))


## "" = the entry opens; else the reason line shown on its sign and as a toast.
func _block_reason(id: String) -> String:
	if id == "portal":
		return ""
	if _is_locked(id):
		return "Builds at %s Land" % _need_name(id)
	if _newcomer and id in NEWCOMER_LOCK:
		return "Opens after %d runs" % int(_Econ.get_table("missions").get("newcomer_runs", 5))
	if _offline and id in ONLINE_ONLY:
		return "Needs a connection"
	if id == "board" and not LandNav.is_available(&"leaderboard"):
		return "Coming soon"
	if id == "gallery":
		var def: Dictionary = _house_defs.get(id, {})
		if not LandNav.is_available(StringName(String(def.get("screen_id", id)))):
			return "Coming soon"
	return ""


func _block_reason_screen(screen_id: StringName) -> String:
	if _offline and screen_id == &"daily":
		return "Needs a connection"
	return ""


## Word for the pill (never colour only). "" = no pill.
func _tag(id: String) -> String:
	if _is_locked(id):
		return ""
	if _newcomer and id in NEWCOMER_LOCK:
		return "LOCKED"
	if _offline and (id in ONLINE_ONLY):
		return "OFFLINE"
	if _loading:
		return "···" if BADGE_KIND.has(id) else ""
	var sid := "daily" if id == "daily" else id
	var n := 0
	if id == "daily":
		n = int(MetaState.call("badge_count", "daily")) if MetaState.has_method("badge_count") else 0
	else:
		n = _badge_count(id)
	return String(BADGE_KIND.get(id, "CLAIM")) if n > 0 else ""


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
	var c: int = preload("res://scripts/meta/economy_db.gd").land_tier_cost(_tier)
	return c if c >= 0 else FALLBACK_TIER_COSTS[_tier - 1]


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
		var n: Node3D
		if b.has("path"):
			n = _inst(LIB + String(b["path"]) + ".tscn")
		else:
			var pat := String(b["pat"])
			n = _inst(BLD + String(b["dir"]) + "/" + (pat % int(b.get("fixed_lv", lv)) if "%d" in pat else pat) + ".tscn")
		if n == null:
			continue
		var ground := _ground_at(float(b["cx"]), float(b["base"]))
		var box := _aabb(n, Transform3D.IDENTITY)
		var hi := _tier >= 3 and b.has("h3")
		var h_units := float(b["h3"] if hi else b["h"]) / PPU
		var w_units := float(b["w3"] if hi else b["w"]) / PPU
		var s := minf(h_units / maxf(box.size.y, 0.01),
			w_units / maxf((box.size.x + box.size.z) * 0.7071, 0.01))
		n.scale = Vector3.ONE * s
		n.position = ground - Vector3(0, box.position.y * s, 0)
		# Facing fix per house lives in houses.json ("yaw"); the table default is 0.
		n.rotation_degrees.y = float((_house_defs.get(String(b["id"]), {}) as Dictionary).get("yaw", b.get("yaw", 0.0)))
		add_child(n)
		_nodes3d[String(b["id"])] = {"node": n, "scale": s}
		var reach := (box.size.x + box.size.z) * 0.5 * s * 0.5
		_blocked.append({"p": ground, "r": reach + 0.8})
		_blocked.append({"p": ground - _g * (reach + 1.5), "r": 2.6})   # name plate zone
	# Run plate zone under the Portal, plus a ~150 px (design) keep-out ring around the Portal itself.
	_blocked.append({"p": _ground_at(960, 530), "r": 8.0})
	# Walking lanes: hub in front of the Portal -> the front of every other house.
	_hub = _ground_at(960, 700)
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

	# Click boxes first (under signs, pills and HUD).
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
	_build_hud()
	_build_dock()
	_build_banners()
	_build_toast()
	_refresh_signs()


func _add_house_hit(id: String) -> void:
	var btn := Button.new()
	btn.name = "Hit_" + id
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_on_hit_pressed.bind(id))
	btn.mouse_entered.connect(_hover.bind(id, true))
	btn.mouse_exited.connect(_hover.bind(id, false))
	_ui.add_child(btn)
	_hits[id] = btn


## Touch: first tap shows the sign (with Open), second tap opens. Mouse click opens directly.
## Latched by a real InputEventScreenTouch; mouse or keyboard input switches it back off.
func _is_touch() -> bool:
	return _touch_mode


func _input(event: InputEvent) -> void:
	var was := _touch_mode
	if event is InputEventScreenTouch:
		_touch_mode = true
	elif event is InputEventKey or (event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION):
		_touch_mode = false
		_touch_id = ""
	if was != _touch_mode:
		_refresh_signs()


## Touch: a tap that no sign/button/HUD control consumed (empty ground) closes the open sign.
func _unhandled_input(event: InputEvent) -> void:
	if not _touch_mode or _touch_id == "":
		return
	# Only the emulated mouse press: Controls consume it when hit, ScreenTouch is never consumed.
	var tap: bool = event is InputEventMouseButton and event.pressed and event.device == InputEvent.DEVICE_ID_EMULATION
	if tap:
		_touch_id = ""
		_refresh_signs()


func _on_hit_pressed(id: String) -> void:
	if _is_touch() and id != "portal" and _touch_id != id:
		_touch_id = id
		_refresh_signs()
		return
	_on_house_pressed(id)


func _hover(id: String, on: bool) -> void:
	if on:
		_hover_id = id
	elif _hover_id == id:
		_hover_id = ""
	_refresh_signs()
	if not _nodes3d.has(id):
		return
	var n: Node3D = _nodes3d[id]["node"]
	var s := float(_nodes3d[id]["scale"])
	var t := create_tween()
	t.tween_property(n, "scale", Vector3.ONE * s * (1.05 if on else 1.0), 0.12)


func _focus(id: String, on: bool) -> void:
	if on:
		_focus_id = id
	elif _focus_id == id:
		_focus_id = ""
	_refresh_signs()


## Signs are hidden at rest. Hover, keyboard focus on the dock tile, or the Names toggle shows them.
## An empty plot keeps its label on always (no hover needed on touch).
func _refresh_signs() -> void:
	for id in _plates:
		var always: bool = _plot_marks.has(id)
		var op := (_plates[id] as Control).find_child("SignOpen", true, false)
		if op != null:
			op.visible = _touch_mode
		(_plates[id] as Control).visible = always or _names_on or _hover_id == id or _focus_id == id or _touch_id == id
	_layout()


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


## Dark key cap ("2", "B", "Enter"). 14 px text is the floor.
func _key_chip(key: String, size: int = 22) -> PanelContainer:
	var chip := PanelContainer.new()
	var sb := _style(DangoTheme.Surface.PANEL, 6, 0, Vector2(4, 0))
	sb.bg_color = KEY_CHIP
	chip.add_theme_stylebox_override("panel", sb)
	chip.custom_minimum_size = Vector2(size, size)
	var l := _lbl(key, 14, Color("FFF8EA"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(l)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return chip


## Same fill on all four states; hover lightens, focus gets the primary ring.
func _btn_styles(btn: Button, fill: Color, border: Color, radius: int, bw: int) -> void:
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := _style(DangoTheme.Surface.CREAM_RAISED, radius, bw, Vector2(0, 0), border)
		sb.bg_color = fill
		if st == "hover":
			sb.bg_color = DangoTheme.CREAM_HI if fill == DangoTheme.CREAM_RAISED else fill.lightened(0.12)
		if st == "focus":
			sb.border_color = DangoTheme.PRIMARY
			sb.set_border_width_all(bw + 2)
		btn.add_theme_stylebox_override(st, sb)


## Fills a Button with a layout of non-clickable children and sizes the button to fit it.
func _fill_button(btn: Button, inner: Control, pad: Vector2) -> void:
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = pad.x
	inner.offset_right = -pad.x
	inner.offset_top = pad.y
	inner.offset_bottom = -pad.y
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(inner)
	var ms := inner.get_combined_minimum_size()
	btn.custom_minimum_size = Vector2(maxf(btn.custom_minimum_size.x, ms.x + pad.x * 2.0),
		maxf(btn.custom_minimum_size.y, ms.y + pad.y * 2.0))


func _make_plate(id: String) -> PanelContainer:
	var m: Dictionary = META[id]
	var why := _block_reason(id)
	var plate := PanelContainer.new()
	plate.name = "Sign_" + id
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := _style(DangoTheme.Surface.CREAM, 12, 3, Vector2(14, 6), INK_PLATE)
	if why != "":
		sb.bg_color = LOCK_FILL
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
	if String(m["key"]) != "":
		row.add_child(_key_chip(String(m["key"])))
	row.add_child(_lbl(String(m["name"]), 19, DangoTheme.INK))
	var sub := String(m["sub"])
	if _is_locked(id):
		sub = "Builds at %s Land" % _need_name(id)
		why = ""
	if sub != "":
		var s := _lbl(sub, 14, LOCK_TEXT if why != "" else DangoTheme.INK_ON_CREAM_MUTED, false)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(s)
	if why != "":
		var w := _lbl(why, 14, Color("8A3E22"), false)
		w.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(w)
	if id != "portal" and not _is_locked(id):
		var open := Button.new()
		open.name = "SignOpen"
		open.visible = _touch_mode
		open.text = "Open"
		open.custom_minimum_size = Vector2(0, 44)
		DangoTheme.style_button(open, true)
		open.pressed.connect(_on_house_pressed.bind(id))
		col.add_child(open)
	return plate


## Word pill (never colour only): FREE / CLAIM / NEW / OFFLINE / LOCKED / "···".
func _pill(kind: String, h: int = 24) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := _style(DangoTheme.Surface.CREAM, h / 2, 2, Vector2(8, 0), INK_PLATE)
	sb.bg_color = BADGE_FILL.get(kind, Color("FF9345"))
	pill.add_theme_stylebox_override("panel", sb)
	pill.custom_minimum_size = Vector2(0, h)
	var l := _lbl(kind, 14, BADGE_INK.get(kind, Color("2A1505")))
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(l)
	return pill


func _make_badge_pill(id: String) -> Control:
	var tag := _tag(id)
	if tag == "":
		return null
	return _pill(tag)


## Pin a pill to the top-right corner of its parent, sticking out by (10, 12).
func _corner_pill(parent: Control, tag: String) -> void:
	var p := _pill(tag)
	p.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p.offset_left = 10
	p.offset_right = 10
	p.offset_top = -12
	p.offset_bottom = -12
	parent.add_child(p)


# ---------------------------------------------------------------- HUD (top-left, rail, wallet)

func _build_hud() -> void:
	_hud_tl = HBoxContainer.new()
	_hud_tl.name = "HudTopLeft"
	_hud_tl.add_theme_constant_override("separation", 12)
	_hud_tl.position = Vector2(24, 24)
	_ui.add_child(_hud_tl)
	_hud_tl.add_child(_profile_chip())
	_hud_tl.add_child(_land_chip())

	_rail = VBoxContainer.new()
	_rail.name = "Rail"
	_rail.add_theme_constant_override("separation", 14)
	_rail.position = Vector2(24, 116)
	_ui.add_child(_rail)
	_rail.add_child(_rail_button("Daily", "D", &"daily", 88, _tag("daily")))
	_rail.add_child(_rail_button("Codex", "C", &"codex", 88, ""))
	_names_btn = _rail_button("Names", "N", &"", 56, "")
	_names_btn.name = "NamesToggle"
	_names_btn.pressed.connect(_toggle_names)
	_rail.add_child(_names_btn)

	_wallet = HBoxContainer.new()
	_wallet.name = "Wallet"
	_wallet.add_theme_constant_override("separation", 10)
	_wallet.position = Vector2(1500, 24)
	_ui.add_child(_wallet)
	_wallet.add_child(_currency("Gene Shard", _meta_int("shard_pool"), Color("FF9345"), false))
	_wallet.add_child(_currency("Land Stone", _meta_int("stone"), Color("B8A27A"), false))
	_wallet.add_child(_currency("Lunar Gem", _meta_int("lunar_gem"), Color("A27BEA"), true))
	_wallet.add_child(_settings_button())


func _profile_chip() -> Control:
	var btn := Button.new()
	btn.name = "ProfileChip"
	btn.custom_minimum_size = Vector2(0, 68)
	btn.focus_mode = Control.FOCUS_ALL
	_btn_styles(btn, DangoTheme.CREAM_RAISED, Color("8A3E22"), 18, 4)
	btn.pressed.connect(_open_profile)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var name := "Guest"
	if not _guest:
		name = AccountService.display_name() if AccountService.is_signed_in() else "Player"
	var av := PanelContainer.new()
	var asb := _style(DangoTheme.Surface.PANEL, 23, 3, Vector2(0, 0))
	asb.bg_color = Color("CFC4B0") if _guest else Color("DDBF8C")
	av.add_theme_stylebox_override("panel", asb)
	av.custom_minimum_size = Vector2(46, 46)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ini := _lbl("?" if _guest else name.left(1).to_upper(), 19, LOCK_TEXT)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(ini)
	h.add_child(AvatarFrame.wrap(av, 56.0, MetaState.equipped_frame, 40.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_lbl(name.left(14), 20, DangoTheme.INK))
	var sub := "Sign in to save online" if _guest else "Profile · Unlocks"
	if not _guest and MetaState.equipped_title != "":
		sub = TitleNames.display(MetaState.equipped_title)
	col.add_child(_lbl(sub.left(22), 14,
		Color("A3261A") if _guest else DangoTheme.INK_ON_CREAM_MUTED, false))
	h.add_child(col)
	h.add_child(_key_chip("P"))
	h.add_child(_lbl("›", 20, Color("8A3E22")))
	_fill_button(btn, h, Vector2(14, 8))
	return btn


func _land_chip() -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 68)
	btn.focus_mode = Control.FOCUS_ALL
	btn.name = "UpgradeLand" if _tier < 6 else "LandChip"
	_btn_styles(btn, DangoTheme.CREAM_RAISED, Color("8A3E22"), 18, 4)
	btn.pressed.connect(_on_land_pressed)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_lbl("%s Land" % TIER_NAMES[_tier - 1], 19, DangoTheme.INK))
	top.add_child(_lbl("%d / 6" % _tier, 14, DangoTheme.INK_ON_CREAM_MUTED, false))
	col.add_child(top)
	if _tier >= 6:
		col.add_child(_lbl("Max tier · no further upgrade", 14, DangoTheme.INK_ON_CREAM_MUTED, false))
	else:
		var need := _upgrade_cost()
		var have := _meta_int("stone")
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dot := Panel.new()
		var dsb := StyleBoxFlat.new()
		dsb.bg_color = Color("B8A27A")
		dsb.set_corner_radius_all(9)
		dsb.set_border_width_all(2)
		dsb.border_color = INK_PLATE
		dot.add_theme_stylebox_override("panel", dsb)
		dot.custom_minimum_size = Vector2(18, 18)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(dot)
		var bar := ProgressBar.new()
		bar.name = "LandStoneBar"
		bar.show_percentage = false
		bar.min_value = 0
		bar.max_value = maxf(need, 1)
		bar.value = clampf(have, 0, need)
		bar.custom_minimum_size = Vector2(120, 14)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bg := _style(DangoTheme.Surface.PANEL, 7, 2, Vector2(0, 0), INK_PLATE)
		bg.bg_color = Color(0.54, 0.24, 0.13, 0.22)
		var fg := StyleBoxFlat.new()
		fg.bg_color = Color("FF9345")
		fg.set_corner_radius_all(7)
		bar.add_theme_stylebox_override("background", bg)
		bar.add_theme_stylebox_override("fill", fg)
		row.add_child(bar)
		row.add_child(_lbl("%s / %s" % [_fmt(have), _fmt(need)], 14, DangoTheme.INK, false))
		col.add_child(row)
	h.add_child(col)
	var can_up := _tier < 6 and preload("res://scripts/meta/economy_db.gd").land_upgrade_enabled() and _meta_int("stone") >= _upgrade_cost()
	if can_up:
		var up := PanelContainer.new()
		var usb := _style(DangoTheme.Surface.PANEL, 12, 3, Vector2(14, 0), INK_PLATE)
		usb.bg_color = Color("FF9345")
		up.add_theme_stylebox_override("panel", usb)
		up.custom_minimum_size = Vector2(0, 42)
		up.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		up.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ul := _lbl("Upgrade", 18, Color("2A1505"))
		ul.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		up.add_child(ul)
		h.add_child(up)
	if _tier < 6:
		h.add_child(_key_chip("L"))
	_fill_button(btn, h, Vector2(14, 8))
	if can_up:
		_corner_pill_text(btn, "UPGRADE", Color("FF9345"), Color("2A1505"))
	return btn


func _corner_pill_text(parent: Control, text: String, fill: Color, ink: Color) -> void:
	var p := PanelContainer.new()
	var sb := _style(DangoTheme.Surface.CREAM, 12, 2, Vector2(8, 0), INK_PLATE)
	sb.bg_color = fill
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(0, 24)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(_lbl(text, 14, ink))
	p.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p.offset_left = 14
	p.offset_right = 14
	p.offset_top = -13
	p.offset_bottom = -13
	parent.add_child(p)


func _rail_button(title: String, key: String, screen_id: StringName, h: int, tag: String) -> Button:
	var b := Button.new()
	b.name = "Rail_" + title
	b.custom_minimum_size = Vector2(88, h)
	b.focus_mode = Control.FOCUS_ALL
	var why := _block_reason_screen(screen_id)
	_btn_styles(b, Color("EDE4D4") if why != "" else DangoTheme.CREAM_RAISED, INK_PLATE, 18, 3)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 3)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_lbl(title, 16, LOCK_TEXT if why != "" else DangoTheme.INK))
	row.add_child(_key_chip(key, 20))
	v.add_child(row)
	_fill_button(b, v, Vector2(4, 4))
	b.custom_minimum_size.y = h
	if tag != "":
		_corner_pill(b, tag)
	if screen_id != &"":
		b.pressed.connect(_on_rail_pressed.bind(screen_id))
	return b


func _toggle_names() -> void:
	_names_on = not _names_on
	if _names_btn != null:
		_btn_styles(_names_btn, Color("FF9345") if _names_on else DangoTheme.CREAM_RAISED, INK_PLATE, 18, 3)
	_refresh_signs()


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
	h.add_child(_lbl("···" if _loading else _fmt(value), 16, DangoTheme.INK))
	if plus:
		var b := Button.new()
		b.name = "GemPlus"
		b.text = "+"
		b.custom_minimum_size = Vector2(44, 44)
		b.focus_mode = Control.FOCUS_ALL
		b.disabled = _offline
		b.add_theme_font_override("font", DangoTheme.FONT_DISPLAY_BOLD)
		b.add_theme_color_override("font_color", Color("FFF8EA"))
		b.add_theme_color_override("font_disabled_color", Color("FFF8EA"))
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			var pb := _style(DangoTheme.Surface.PANEL, 13, 2, Vector2(0, 0))
			pb.bg_color = Color("A27BEA") if st != "disabled" else Color("A27BEA").darkened(0.2)
			b.add_theme_stylebox_override(st, pb)
		b.pressed.connect(_on_house_pressed.bind("store"))
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)
	return chip


func _settings_button() -> Button:
	var b := Button.new()
	b.name = "Settings"
	b.tooltip_text = "Settings"
	b.custom_minimum_size = Vector2(68, 68)
	b.icon = load("res://assets/icons/web/settings.svg") as Texture2D
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for ic in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		b.add_theme_color_override(ic, DangoTheme.INK)
	_btn_styles(b, DangoTheme.CREAM_RAISED, Color("8A3E22"), 18, 4)
	for st in ["normal", "hover", "pressed", "focus"]:
		(b.get_theme_stylebox(st) as StyleBoxFlat).set_content_margin_all(16)
	b.pressed.connect(_open_screen.bind(&"settings"))
	var esc := _key_chip("Esc", 22)
	esc.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	esc.grow_horizontal = Control.GROW_DIRECTION_BOTH
	esc.offset_top = 56
	esc.offset_bottom = 56
	b.add_child(esc)
	return b


# ---------------------------------------------------------------- dock (bottom) + RUN

func _dock_tile(id: String, title: String, sub: String) -> Button:
	var m: Dictionary = META[id]
	var why := _block_reason(id)
	var b := Button.new()
	b.name = "Dock_" + id
	b.custom_minimum_size = Vector2(116, 92)
	b.focus_mode = Control.FOCUS_ALL
	b.size_flags_vertical = Control.SIZE_SHRINK_END
	_btn_styles(b, Color("EDE4D4") if why != "" else Color("FFF8EA"), INK_PLATE, 16, 3)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 3)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_lbl(title, 16, Color("8A6E50") if why != "" else DangoTheme.INK))
	row.add_child(_key_chip(String(m["key"]), 20))
	v.add_child(row)
	if sub != "":
		var s := _lbl(sub, 14, LOCK_TEXT, false)
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(s)
	_fill_button(b, v, Vector2(4, 4))
	b.custom_minimum_size.y = 92
	var tag := _tag(id)
	if tag != "":
		_corner_pill(b, tag)
	b.pressed.connect(_on_house_pressed.bind(id))
	b.focus_entered.connect(_focus.bind(id, true))
	b.focus_exited.connect(_focus.bind(id, false))
	b.mouse_entered.connect(_hover.bind(id, true))
	b.mouse_exited.connect(_hover.bind(id, false))
	return b


func _build_dock() -> void:
	_dock = PanelContainer.new()
	_dock.name = "Dock"
	_dock.add_theme_stylebox_override("panel", _style(DangoTheme.Surface.CREAM, 24, 4, Vector2(8, 8), Color("8A3E22")))
	_ui.add_child(_dock)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_dock.add_child(row)
	row.add_child(_dock_tile("house", "House", ""))
	row.add_child(_dock_tile("missions", "Missions", ""))
	row.add_child(_dock_tile("vault", "Vault", ""))
	# RUN is raised: a 92 px slot in the row, the 120 px button sticks out 28 px above it.
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(300, 92)
	row.add_child(slot)
	_run_plate = _build_run_button()
	slot.add_child(_run_plate)
	row.add_child(_dock_tile("echobox", "Echo Box", ""))
	row.add_child(_dock_tile("pass", "Pass", "" if _offline else "ends 29 Dec"))
	row.add_child(_dock_tile("store", "Store", ""))

	_new_run_btn = Button.new()
	_new_run_btn.name = "NewRunButton"
	_new_run_btn.custom_minimum_size = Vector2(170, 96)
	_new_run_btn.focus_mode = Control.FOCUS_ALL
	_btn_styles(_new_run_btn, DangoTheme.CREAM_RAISED, Color("8A3E22"), 18, 4)
	var nv := VBoxContainer.new()
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	nv.add_theme_constant_override("separation", 6)
	nv.add_child(_lbl("New run", 22, DangoTheme.INK))
	var nr := HBoxContainer.new()
	nr.alignment = BoxContainer.ALIGNMENT_CENTER
	nr.add_theme_constant_override("separation", 6)
	nr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nr.add_child(_key_chip("N", 22))
	nr.add_child(_lbl("asks first", 14, DangoTheme.INK_ON_CREAM_MUTED, false))
	nv.add_child(nr)
	_fill_button(_new_run_btn, nv, Vector2(8, 8))
	_new_run_btn.pressed.connect(_on_new_run_pressed)
	_new_run_btn.visible = _has_run
	_ui.add_child(_new_run_btn)

	# "Start here" hint over RUN until the first run starts.
	_start_hint = PanelContainer.new()
	_start_hint.name = "StartHint"
	_start_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hsb := _style(DangoTheme.Surface.PANEL, 14, 3, Vector2(18, 8), INK_PLATE)
	hsb.bg_color = Color("3B2618")
	_start_hint.add_theme_stylebox_override("panel", hsb)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	hv.add_child(_lbl("Start here", 20, Color("FFF8EA")))
	hv.add_child(_lbl("Your first run is a short guided one", 14, Color("DDBF8C"), false))
	_start_hint.add_child(hv)
	_start_hint.visible = _first and not _has_run
	_ui.add_child(_start_hint)


func _build_run_button() -> Button:
	var plate := Button.new()
	plate.name = "RunPlate"
	plate.custom_minimum_size = Vector2(300, 120)
	plate.size = Vector2(300, 120)
	plate.position = Vector2(0, -28)
	plate.focus_mode = Control.FOCUS_ALL
	DangoTheme.style_button(plate, true)
	plate.pressed.connect(_on_run_pressed)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(v)
	var title := "RUN"
	var size := 50
	var sub := "Guided first run" if _first else "Run Setup"
	if _has_run:
		if _mission_run:
			title = "Continue mission"
			size = 32
			sub = _mission_line()
		else:
			title = "Continue run"
			size = 34
			sub = _continue_line()
	_run_title = _lbl(title, size, DangoTheme.INK_ON_PRIMARY)
	_run_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_run_title)
	var s := _lbl(sub, 14, DangoTheme.INK_ON_PRIMARY, false)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 5)
	chips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips.add_child(_key_chip("Enter", 22))
	chips.add_child(_key_chip("1", 22))
	v.add_child(chips)
	return plate


func _continue_line() -> String:
	if not _has_run:
		return ""
	return "%s · Ascension %d" % [String(RunState.mode).capitalize(), int(RunState.ascension)]


func _mission_line() -> String:
	var e: Dictionary = MetaState.mission_escrow
	return "Mission %s · stake %s" % [String(e.get("mission_id", "N?")).to_upper(), _fmt(int(e.get("stake", 0)))]


func _build_banners() -> void:
	_offline_banner = PanelContainer.new()
	_offline_banner.name = "OfflineBanner"
	var sb := _style(DangoTheme.Surface.PANEL, 16, 3, Vector2(20, 8), INK_PLATE)
	sb.bg_color = Color("3B2618")
	_offline_banner.add_theme_stylebox_override("panel", sb)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	_offline_banner.add_child(h)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.add_child(_lbl("Offline", 19, Color("FFF8EA")))
	col.add_child(_lbl("Store, Pass, Echo Box, Daily and Leaderboard need a connection. Runs still work.", 14, Color("DDBF8C"), false))
	h.add_child(col)
	var retry := Button.new()
	retry.name = "RetryButton"
	retry.text = "Retry"
	retry.custom_minimum_size = Vector2(0, 40)
	DangoTheme.style_button(retry, false)
	retry.pressed.connect(_on_retry)
	h.add_child(retry)
	_offline_banner.visible = _offline
	_ui.add_child(_offline_banner)


func _on_retry() -> void:
	if _detect_offline():
		_show_toast("Still offline")
		return
	qa.erase("offline")
	get_tree().reload_current_scene()


func _build_toast() -> void:
	_toast = PanelContainer.new()
	_toast.visible = false
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_theme_stylebox_override("panel", _style(DangoTheme.Surface.CREAM, 14, 3, Vector2(18, 8), INK_PLATE))
	_toast.add_child(_lbl("", 17, DangoTheme.INK))
	_ui.add_child(_toast)


func _show_toast(text: String, hold: float = 1.6) -> void:
	(_toast.get_child(0) as Label).text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast.reset_size()
	_toast.position = Vector2((_ui.size.x - _toast.size.x) * 0.5, 180)
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(hold)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func() -> void: _toast.visible = false)


func _fmt(v: int) -> String:
	var s := str(v)
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += ","
		out += s[i]
	return out


# ================================================================ layout (design px + dy)

func _layout() -> void:
	if _ui == null or _dock == null:
		return
	var dy := (_ui.size.y - 1080.0) * 0.5
	var f := _ui_floor()
	_place_hud(f)
	for b in _live:
		var id := String(b["id"])
		var w := float(b["w"])
		var h := float(b["h"])
		var cx := float(b["cx"])
		var base := float(b["base"]) + dy
		var hit: Button = _hits[id]
		hit.position = Vector2(cx - w * 0.5, base - h)
		hit.size = Vector2(w, h)
		var top := base - h
		var pill: Control = _badges.get(id)
		if pill != null:
			pill.reset_size()
		var pms := pill.get_combined_minimum_size() if pill != null else Vector2.ZERO
		if _plates.has(id):
			var plate: Control = _plates[id]
			plate.reset_size()
			var pm := plate.get_combined_minimum_size()
			plate.position = Vector2(cx - pm.x * 0.5, top + 4.0 - pm.y)
			if pill != null:
				if plate.visible:
					pill.position = Vector2(plate.position.x + pm.x - pms.x + 16.0, plate.position.y - 15.0)
				else:
					pill.position = Vector2(cx - pms.x * 0.5, top + 6.0 - pms.y)
		elif pill != null:
			pill.position = Vector2(cx - pms.x * 0.5, top + 6.0 - pms.y)
	for p in _plots:
		var id := String(p["id"])
		var cx := float(p["cx"])
		var base := float(p["base"]) + dy
		var mark: Control = _plot_marks[id]
		mark.size = Vector2(200, 108)
		mark.position = Vector2(cx - 100.0, base - 108.0)
		var plate: Control = _plates[id]
		plate.reset_size()
		var pm := plate.get_combined_minimum_size()
		plate.position = Vector2(cx - pm.x * 0.5, base - 54.0 - pm.y * 0.5)


## HUD scale boost so text never renders below 0.85 of design size (v5 "Min text"): the canvas
## scales by min(w/1920, h/1080); where that is under 0.85 the HUD groups grow by the difference.
func _ui_floor() -> float:
	var win := get_window().size
	var cs := minf(win.x / 1920.0, win.y / 1080.0)
	return clampf(0.85 / cs, 1.0, 1.4) if cs > 0.0 and cs < 0.85 else 1.0


func _place_hud(f: float) -> void:
	var w := _ui.size.x
	var h := _ui.size.y
	var sc := Vector2(f, f)
	_hud_tl.scale = sc
	_hud_tl.position = Vector2(24, 24)
	_rail.scale = sc
	_rail.position = Vector2(24, 24 + 92.0 * f)
	_wallet.reset_size()
	_wallet.scale = sc
	_wallet.position = Vector2(w - 24.0 - _wallet.get_combined_minimum_size().x * f, 24)
	_dock.reset_size()
	var dsz := _dock.get_combined_minimum_size()
	_dock.scale = sc
	_dock.pivot_offset = Vector2(dsz.x * 0.5, dsz.y)
	_dock.position = Vector2((w - dsz.x) * 0.5, h - 20.0 - dsz.y)
	_new_run_btn.scale = sc
	_new_run_btn.pivot_offset = Vector2(0, 96)
	_new_run_btn.position = Vector2(w * 0.5 + 554.0 * f, h - 20.0 - 96.0)
	_start_hint.reset_size()
	var hs := _start_hint.get_combined_minimum_size()
	_start_hint.scale = sc
	_start_hint.pivot_offset = Vector2(hs.x * 0.5, hs.y)
	_start_hint.position = Vector2((w - hs.x) * 0.5, h - 20.0 - 146.0 * f - hs.y)
	_offline_banner.reset_size()
	var bs := _offline_banner.get_combined_minimum_size()
	_offline_banner.scale = sc
	_offline_banner.pivot_offset = Vector2(bs.x * 0.5, 0)
	_offline_banner.position = Vector2((w - bs.x) * 0.5, 24.0 + 80.0 * f)


# ================================================================ actions

func _open_screen(screen_id: StringName) -> void:
	if not LandNav.is_available(screen_id):
		_show_toast("Coming soon")
		return
	LandNav.open(screen_id)


func _on_house_pressed(id: String) -> void:
	if _modal != null:
		return
	if id == "portal":
		_on_run_pressed()
		return
	var why := _block_reason(id)
	if why != "":
		_show_toast(why)
		return
	var def: Dictionary = _house_defs.get(id, {})
	_open_screen(StringName(String(def.get("screen_id", id))))


func _on_rail_pressed(screen_id: StringName) -> void:
	if _modal != null:
		return
	var why := _block_reason_screen(screen_id)
	if why != "":
		_show_toast(why)
		return
	_open_screen(screen_id)


func _open_profile() -> void:
	if _modal != null:
		return
	_open_screen(&"profile")


func _on_land_pressed() -> void:
	if _modal != null:
		return
	_open_screen(&"land_upgrade")


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
		_new_run_btn.visible = false
		_show_toast("That run could not be loaded")
		return
	if not RunState.resume_combat.is_empty():
		get_tree().change_scene_to_file("res://scenes/combat/Combat.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/run_map/RunMap.tscn")


## N / New run. Only with an open run. Mission run: names the mission and the exact stake.
func _on_new_run_pressed() -> void:
	if _modal != null or not _has_run:
		return
	if _mission_run:
		var e: Dictionary = MetaState.mission_escrow
		var stake := int(e.get("stake", 0))
		var mid := String(e.get("mission_id", "mission")).to_upper()
		_open_confirm("Abandon this mission?",
			"Starting a new run abandons Mission %s. The stake is not returned." % mid,
			"Abandon · −%s" % _fmt(stake), _end_run_and_setup, true, "Keep playing",
			["You lose %s Gene Shard" % _fmt(stake), "Mission %s stake · this run's progress is lost too" % mid],
			Color("A3261A"))
	else:
		_open_confirm("Start a new run?", "Your current run ends now and cannot be continued.",
			"End run", _end_run_and_setup, true, "Keep playing",
			["Run progress is lost", _continue_line()], Color("8A3E22"))


func _end_run_and_setup() -> void:
	MetaState.settle_mission_stake(false, true)   # no-op unless a mission stake is open
	RunState.clear_saved_run()
	_has_run = false
	LandNav.open(&"run_setup")


func _open_confirm(title: String, body: String, ok_text: String, on_ok: Callable, warning: bool = false,
		cancel_text: String = "Cancel", loss: Array = [], head: Color = Color(0, 0, 0, 0)) -> void:
	if _modal != null:
		return
	_modal = Control.new()
	_modal.name = "Confirm"
	_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.14, 0.08, 0.04, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 0)
	var psb := _style(DangoTheme.Surface.CREAM, 28, 4, Vector2(0, 0), Color("8A3E22"))
	psb.set_content_margin_all(0)
	psb.set_expand_margin_all(0)
	panel.add_theme_stylebox_override("panel", psb)
	panel.clip_contents = true
	center.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	panel.add_child(outer)
	if head.a > 0.0:
		var hb := PanelContainer.new()
		var hsb := StyleBoxFlat.new()
		hsb.bg_color = head
		hsb.content_margin_left = 26
		hsb.content_margin_right = 26
		hb.add_theme_stylebox_override("panel", hsb)
		hb.custom_minimum_size = Vector2(0, 64)
		var ht := _lbl(title, 28, Color("FFF8EA"))
		ht.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(ht)
		outer.add_child(hb)
	var mg := MarginContainer.new()
	mg.add_theme_constant_override("margin_left", 26)
	mg.add_theme_constant_override("margin_right", 26)
	mg.add_theme_constant_override("margin_top", 22)
	mg.add_theme_constant_override("margin_bottom", 24)
	outer.add_child(mg)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	mg.add_child(v)
	if head.a <= 0.0:
		v.add_child(_lbl(title, 26, DangoTheme.INK))
	var msg := _lbl(body, 18, DangoTheme.INK, false)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size = Vector2(660, 0)
	v.add_child(msg)
	if loss.size() >= 2:
		var lb := PanelContainer.new()
		lb.add_theme_stylebox_override("panel", _style(DangoTheme.Surface.CREAM, 14, 3, Vector2(16, 12), INK_PLATE))
		var lv := VBoxContainer.new()
		lv.add_theme_constant_override("separation", 2)
		lv.add_child(_lbl(String(loss[0]), 20, DangoTheme.INK))
		lv.add_child(_lbl(String(loss[1]), 14, DangoTheme.INK_ON_CREAM_MUTED, false))
		lb.add_child(lv)
		v.add_child(lb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	v.add_child(row)
	var cancel := Button.new()
	cancel.name = "ConfirmCancel"
	cancel.text = cancel_text
	cancel.custom_minimum_size = Vector2(0, 62)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DangoTheme.style_button(cancel, loss.size() >= 2)
	cancel.add_theme_font_size_override("font_size", 22)
	cancel.pressed.connect(_close_modal)
	var ok := Button.new()
	ok.name = "ConfirmOk"
	ok.text = ok_text
	ok.custom_minimum_size = Vector2(0, 62)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DangoTheme.style_button(ok, loss.size() < 2, warning and loss.size() < 2)
	ok.add_theme_font_size_override("font_size", 22)
	if loss.size() >= 2:
		ok.add_theme_color_override("font_color", Color("A3261A"))
		ok.add_theme_color_override("font_hover_color", Color("A3261A"))
		ok.add_theme_color_override("font_focus_color", Color("A3261A"))
	ok.pressed.connect(on_ok)
	row.add_child(cancel)
	row.add_child(ok)
	_ui.add_child(_modal)
	cancel.grab_focus()


func _close_modal() -> void:
	if _modal != null:
		_modal.queue_free()
		_modal = null


## Keys (v5 table): 1-7, B, N, L, P, D, C, Enter, Esc. Returns true when the key was used.
func _handle_key(keycode: int) -> bool:
	if keycode == KEY_ESCAPE:
		if _modal != null:
			_close_modal()
		elif _names_on:
			_toggle_names()
		else:
			_open_screen(&"settings")
		return true
	if _modal != null:
		return false
	var num := keycode - KEY_0
	if keycode >= KEY_KP_0 and keycode <= KEY_KP_9:
		num = keycode - KEY_KP_0
	if num >= 1 and num <= 7:
		var id: String = NUM_KEYS[num - 1]
		_on_house_pressed(id)
		return true
	match keycode:
		KEY_B:
			_on_house_pressed("board")
		KEY_N:
			if _has_run:
				_on_new_run_pressed()
			else:
				_toggle_names()
		KEY_L:
			_on_land_pressed()
		KEY_P:
			_open_profile()
		KEY_D:
			_on_rail_pressed(&"daily")
		KEY_C:
			_on_rail_pressed(&"codex")
		KEY_ENTER, KEY_KP_ENTER:
			if get_viewport().gui_get_focus_owner() != null:
				return false
			_on_run_pressed()
		_:
			return false
	return true


func _unhandled_key_input(event: InputEvent) -> void:
	var ke := event as InputEventKey
	if ke == null or not ke.pressed or ke.echo:
		return
	if ke.alt_pressed or ke.ctrl_pressed or ke.meta_pressed:
		return
	if _handle_key(ke.keycode):
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
