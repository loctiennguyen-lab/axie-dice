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
const LAND_EDGE_MARGIN := 0.4       # world units kept free between any prop / Axie and the land edge

const _Econ := preload("res://scripts/meta/economy_db.gd")
## Word on the pill when the entry has something waiting (MetaState.badge_count > 0).
const BADGE_KIND := {"echobox": "FREE", "vault": "NEW", "store": "NEW", "pass": "CLAIM", "missions": "CLAIM", "daily": "CLAIM"}
const ONLINE_ONLY := ["echobox", "pass", "store", "board", "daily"]
const NEWCOMER_LOCK := ["missions", "board"]
## Keys 1-7 -> entry id (v5 key table; 8 is unused: Mastery Hall is cut).
const NUM_KEYS := ["portal", "house", "missions", "echobox", "pass", "vault", "store"]

## QA / tests: force a tier (1-6) instead of reading MetaState.
static var tier_override: int = 0

## Building table. cx/base/w/h are R1 numbers (design px). `lv` buildings step up with the Land tier
## (core-loop-v2 §4.1: House lv1 at Savannah ... lv4 from Genesis, tier 5 and 6 stay lv4).
## `min_tier` = tier that builds it (README: Mastery Hall at Arctic).
const BUILDINGS: Array[Dictionary] = [
	# v5 3x3 lattice around the Portal, pulled in to 0.86 (x) / 0.85 (y) of its old spread about the centre (960, 530)
	# so every footprint, plot and Axie lane stays well inside the diamond (Liam, b831 review).
	{"id": "portal", "dir": "Portal", "pat": "SM_Portal_01", "cx": 960, "base": 580, "w": 300, "h": 300, "yaw": 0.0},
	{"id": "house", "dir": "House", "pat": "House_lv%d", "cx": 444, "base": 581, "w": 200, "h": 196, "w3": 200, "h3": 178},
	{"id": "missions", "dir": "Weaponsmith", "pat": "Weaponsmith_lv%d", "fixed_lv": 1, "cx": 1218, "base": 453, "w": 190, "h": 213},
	{"id": "echobox", "dir": "Alchemy", "pat": "SM_Alchemy_lv%d_Prefab", "cx": 702, "base": 708, "w": 150, "h": 176, "w3": 140, "h3": 204},
	{"id": "pass", "dir": "EquipmentStall", "pat": "EquipmentStall_lv%d", "cx": 1218, "base": 708, "w": 190, "h": 188, "w3": 150, "h3": 213},
	{"id": "vault", "dir": "GemStorage", "pat": "GemStorage_lv%d", "cx": 960, "base": 836, "w": 170, "h": 168, "w3": 125, "h3": 201},
	{"id": "store", "dir": "Jeweler", "pat": "Jeweler_lv%d", "cx": 1476, "base": 581, "w": 150, "h": 183, "w3": 160, "h3": 194},
	{"id": "board", "path": "Item/Land_reward_ss2_ss3/SM_Billboard_Big", "cx": 960, "base": 326, "w": 130, "h": 190, "yaw": 45.0},
	# Gallery: stand-in mesh (old Armorsmith) until lane I names the real one. Built from Genesis (5).
	{"id": "gallery", "dir": "Armorsmith", "pat": "Armorsmith_lv%d", "cx": 702, "base": 453, "w": 160, "h": 135, "yaw": 0.0, "min_tier": 5},
]
## Empty plot (never hidden) shows while its building is not built.
const PLOTS: Array[Dictionary] = [
	{"id": "gallery", "cx": 702, "base": 453, "min_tier": 5},
]
const TIER_NAMES: Array[String] = ["Savannah", "Forest", "Arctic", "Mystic", "Genesis", "LunaLanding"]
## Per biome look. Paths are under Environment/. ground = centre, mid, edge; cliff = top, bottom.
## Optional: lip / strata (hex, cliff turf edge + rock band), stain (0..1, strength of the dirt mottling, default 1), tree_h (rim tree height in world units, default 6).
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
		"tufts": [],
		"lip": "9E82D6", "strata": "3A2C66"},
	{"ground": ["FFF3C8", "F5D87E", "DDAE4E"], "cliff": "9A7A4A", "sky": ["9FD3F5", "FFF1D0"],
		"trees": ["Genesis/Tree/SM_Tree_G_01", "Genesis/Tree/SM_Tree_G_02", "Genesis/Tree/SM_Tree_G_03", "Genesis/Tree/SM_Tree_G_06"],
		"shrubs": ["Genesis/Shrub/G_Shrub01_Allside", "Genesis/Shrub/G_Shrub02_Allside"],
		"rocks": [], "tufts": [], "lip": "F5D87E", "strata": "7A5A32"},
	{"ground": ["FBD3DD", "E69BB5", "BC6A8E"], "cliff": "7A3A5C", "sky": ["3E3480", "C77FAE"], "moon": true,
		"stain": 0.4, "tree_h": 2.6,
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
var _bld_rects: Array[Rect2] = []   # design-px screen rect of every building and empty plot: props keep off them
var _footprints: Array[Dictionary] = []  # {p, r} of every building and prop, for the stay-on-the-land test
var _lanes: Array[Array] = []        # [from, to] ground segments the Axies walk; props stay off them
var _hub := Vector3.ZERO             # where all lanes meet, in front of the Portal
var _axies: Array[Dictionary] = []

var _ui: Control
var _hits := {}                      # id -> Button (clickable box)
var _plot_marks := {}                # id -> Control
var _house_defs := {}                # house_id -> dictionary from houses.json
var _run_plate: Button
var _toast: PanelContainer
var _toasts: Array = []
var _modal: Control
var _moon_card: Node   # Moon Card popup while it is open (has_modal)
var _has_run := false
var _tier := 1
var _live: Array[Dictionary] = []   # buildings built at this tier
var _plots: Array[Dictionary] = []  # plots still empty at this tier
var _hud_tl: VBoxContainer
var _wallet: PanelContainer
var _hud_bl: PanelContainer
var _hud_br: HBoxContainer
var _currencies: Control
var _daily_btn: Button
var _new_run_btn: Button
var _start_hint: VBoxContainer
var _offline_banner: Control
var _hover_id := ""
var _focus_id := ""
var _touch_id := ""
var _touch_mode := false
var _offline := false
var _loading := false
var _guest := false
var _moon_btn: Button
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
	MissionEscrowSync.reconcile()   # remote dice: close a stake the server settled while we were away (no-op otherwise)
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
		if id == "gallery":
			return "Opens at Land tier %d" % int(((_house_defs.get(id, {}) as Dictionary).get("unlock", {}) as Dictionary).get("min_tier", 5))
		return "Builds at %s Land" % _need_name(id)
	if _newcomer and id in NEWCOMER_LOCK:
		return "Opens after %d runs" % int(_Econ.get_table("missions").get("newcomer_runs", 5))
	if _guest and id in ONLINE_ONLY and id != "board":   # the Leaderboard stays readable for guests
		return "Sign in to use"
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
	if _guest and screen_id == &"daily":
		return "Sign in to use"
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
	return maxi(preload("res://scripts/meta/economy_db.gd").land_tier_cost(_tier), 0)


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
		# Soft halo (radial gradient, additive-looking via alpha) behind a lit disc.
		var hg := Gradient.new()
		hg.set_color(0, Color(1.0, 0.95, 0.85, 0.55))
		hg.set_color(1, Color(1.0, 0.85, 0.9, 0.0))
		var ht := GradientTexture2D.new()
		ht.gradient = hg
		ht.fill = GradientTexture2D.FILL_RADIAL
		ht.fill_from = Vector2(0.5, 0.5)
		ht.fill_to = Vector2(1.0, 0.5)
		ht.width = 256
		ht.height = 256
		var halo := TextureRect.new()
		halo.texture = ht
		halo.size = Vector2(420, 420)
		halo.position = Vector2(1630 - 210, 190 - 210)
		halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sky_layer.add_child(halo)
		var moon := Panel.new()
		var msb := StyleBoxFlat.new()
		msb.bg_color = Color("FFF1D0")
		msb.set_corner_radius_all(70)
		msb.border_color = Color("FFD9C4")
		msb.set_border_width_all(6)
		msb.shadow_color = Color(1.0, 0.9, 0.8, 0.45)
		msb.shadow_size = 24
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
	# Optional terrain edge ("lip" = turf colour, "strata" = darker rock band): two thin boxes
	# just outside the slab so the cliff face reads as layered earth, not one flat block.
	var bi: Dictionary = BIOMES[_tier - 1]
	if bi.has("lip"):
		for part in [["lip", 0.3, -0.17, 0.06], ["strata", 0.7, -1.35, 0.04]]:
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(PLOT_SIDE + float(part[3]), float(part[1]), PLOT_SIDE + float(part[3]))
			mi.mesh = bm
			var pm := StandardMaterial3D.new()
			pm.albedo_color = Color(String(bi[part[0]]))
			pm.roughness = 1.0
			mi.material_override = pm
			mi.position.y = float(part[2])
			add_child(mi)

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
	tm.set_shader_parameter("stain", float(BIOMES[_tier - 1].get("stain", 1.0)))
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
uniform float stain = 1.0;
void fragment() {
	vec3 t = texture(tint, UV).rgb;
	// The source texture is low-contrast, so measure each sample against its own blurred mean and
	// amplify the difference: mottled soil patches at two scales.
	float d1 = dot(texture(dirt, UV * 5.0).rgb - textureLod(dirt, UV * 5.0, 9.0).rgb, vec3(0.333));
	float d2 = dot(texture(dirt, UV * 1.7 + vec2(0.31, 0.57)).rgb - textureLod(dirt, UV * 1.7, 9.0).rgb, vec3(0.333));
	float m = clamp(1.0 + (d1 * 7.0 + d2 * 9.0) * stain, 0.5, 1.2);
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
		_footprints.append({"p": ground, "r": reach, "h": h_units, "rs": 0.0})
		_bld_rects.append(Rect2(float(b["cx"]) - float(b["w"]) * 0.5, float(b["base"]) - float(b["h"]), float(b["w"]), float(b["h"])))
	# Run plate zone under the Portal, plus a ~150 px (design) keep-out ring around the Portal itself.
	_blocked.append({"p": _ground_at(960, 530), "r": 8.0})
	# Walking lanes: hub in front of the Portal -> the front of every other house.
	_hub = _ground_at(960, 700)
	for b in _live:
		if String(b["id"]) == "portal":
			continue
		_lanes.append([_hub, _clamp_in(_ground_at(float(b["cx"]), float(b["base"]) + 60.0), 1.0)])
	for p in _plots:
		_blocked.append({"p": _ground_at(float(p["cx"]), float(p["base"]) - 40.0), "r": 6.0})
		_bld_rects.append(Rect2(float(p["cx"]) - 100.0, float(p["base"]) - 108.0, 200.0, 108.0))


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


## Trees stand in a few small clusters (one species and one size per cluster) in the free rim band of the land.
## A tree's top must stay inside the land diamond on screen and clear of buildings, so the clusters land wherever the
## band has room for this tier: front edges mostly, back rim only when a tree fits there. Spots are scanned on a
## fixed grid, so the result is the same every run.
const TREE_CLUSTERS := 3
const TREE_CLUSTER_GAP := 9.0   # world units between cluster seeds
const TREE_RIM_BAND := 12.0       # a tree seed stands at most this far in from the land edge
## Small accents beside the buildings: [design-canvas point, "rock" | "shrub"]. Few on purpose.
const ACCENT_SPOTS: Array = [
	[Vector2(580, 640), "rock"], [Vector2(1355, 520), "shrub"], [Vector2(780, 800), "shrub"],
	[Vector2(1190, 835), "rock"], [Vector2(790, 330), "shrub"], [Vector2(1180, 345), "rock"],
]
const PROP_MIN_SCALE := 0.85   # a prop is dropped rather than shrunk below this share of its intended size


func _build_props() -> void:
	var biome: Dictionary = BIOMES[_tier - 1]
	var trees: Array = biome["trees"]
	var tree_h := float(biome.get("tree_h", 3.2))
	var half := PLOT_SIDE * 0.5
	var seeds: Array[Vector3] = []
	for ci in TREE_CLUSTERS:
		var path := LIB + "Environment/" + String(trees[ci % trees.size()]) + ".tscn"
		var box := _prop_box(path)
		if box.size.y <= 0.0:
			continue
		var sc := tree_h / box.size.y
		var rt := maxf(box.size.x, box.size.z) * sc * 0.5
		var seed_p := Vector3.INF
		var best := INF
		for gx in range(-14, 15):
			for gz in range(-14, 15):
				var c := Vector3(gx, 0, gz)
				var edge := half - maxf(absf(c.x), absf(c.z))
				if edge > TREE_RIM_BAND or not _tree_spot_ok(c, rt, tree_h):
					continue
				var far := true
				for sp in seeds:
					if sp.distance_to(c) < TREE_CLUSTER_GAP:
						far = false
				# prefer the front (camera side) and the nearest rim
				var score := edge - c.dot(-_g) * 0.12 + (0.0 if c.dot(_right) != 0.0 else 0.0)
				if far and score < best:
					best = score
					seed_p = c
		if seed_p == Vector3.INF:
			continue
		seeds.append(seed_p)
		_place_exact(path, seed_p, tree_h)
		var made := 0
		for ang in [35.0, 150.0, 250.0, 100.0, 300.0, 0.0, 200.0, 60.0]:
			if made >= 2:
				break
			var q := seed_p + Vector3(cos(deg_to_rad(ang)), 0, sin(deg_to_rad(ang))) * (rt * 1.25)
			if _tree_spot_ok(q, rt * 0.9, tree_h * 0.9) and _place_exact(path, q, tree_h * 0.9):
				made += 1
	var shrubs: Array = biome["shrubs"]
	var rocks: Array = biome["rocks"]
	var si := 0
	var ri := 0
	for a in ACCENT_SPOTS:
		var pool: Array = rocks if String(a[1]) == "rock" else shrubs
		if pool.is_empty():
			pool = shrubs if not shrubs.is_empty() else rocks
		if pool.is_empty():
			continue
		var idx := ri if String(a[1]) == "rock" else si
		if String(a[1]) == "rock":
			ri += 1
		else:
			si += 1
		var sp: Vector2 = a[0]
		_place_fit(LIB + "Environment/" + String(pool[idx % pool.size()]) + ".tscn", _ground_at(sp.x, sp.y), 1.4, true)


## Place a prop scaled so its height (by_height) or footprint width is `target` world units. The prop is only nudged
## toward the camera / sideways and shrunk to PROP_MIN_SCALE at most; if it still does not fit it is dropped.
## The foot of the mesh (AABB min.y after scaling) always lands on y = 0.
func _place_fit(path: String, p: Vector3, target: float, by_height: bool) -> bool:
	var n := _inst(path)
	if n == null:
		return false
	var box := _aabb(n, Transform3D.IDENTITY)
	var dim := box.size.y if by_height else maxf(box.size.x, box.size.z)
	var s0 := target / maxf(dim, 0.01) * _rng.randf_range(0.95, 1.05)
	var found := false
	var s := s0
	var r := 0.0
	var hh := 0.0
	for k in [1.0, 0.92, PROP_MIN_SCALE]:
		s = s0 * k
		r = maxf(box.size.x, box.size.z) * s * 0.5
		hh = box.size.y * s
		var p0 := _clamp_in(p, r)
		var cands: Array[Vector3] = []
		for st in 13:
			cands.append(_clamp_in(p0 - _g * 0.5 * st, r))
		for st in range(1, 7):
			for sd in [-1.0, 1.0]:
				cands.append(_clamp_in(p0 + _right * sd * 0.7 * st, r))
		for c in cands:
			if _screen_fits(c, r, hh) and not _hits_building(c, r, hh) and not _blocked_at(c, 0.2) and not _hits_prop(c, r):
				p = c
				found = true
				break
		if found:
			break
	if not found:
		n.free()
		return false
	n.position = p - Vector3(0, box.position.y * s, 0)
	n.rotation_degrees.y = _rng.randf() * 360.0
	n.scale = Vector3.ONE * s
	add_child(n)
	_blocked.append({"p": p, "r": 0.9})
	_footprints.append({"p": p, "r": r, "h": hh, "prop": true, "base_y": _aabb(n, n.transform).position.y})
	return true


## Local-space bounds of a prop scene (used to size it before it is placed).
func _prop_box(path: String) -> AABB:
	var n := _inst(path)
	if n == null:
		return AABB()
	var box := _aabb(n, Transform3D.IDENTITY)
	n.free()
	return box


## Free spot for a tree of this footprint radius and height: on the land on screen, off buildings, lanes and props.
func _tree_spot_ok(c: Vector3, r: float, hh: float) -> bool:
	var cc := _clamp_in(c, r)
	return cc.is_equal_approx(c) and _screen_fits(c, r, hh) and not _hits_building(c, r, hh) \
		and not _blocked_at(c, 0.3) and not _hits_prop(c, r)


## Place a prop of height `target` exactly at `p` (no nudging, no shrinking). False when the spot is not free.
func _place_exact(path: String, p: Vector3, target: float) -> bool:
	var n := _inst(path)
	if n == null:
		return false
	var box := _aabb(n, Transform3D.IDENTITY)
	var s := target / maxf(box.size.y, 0.01) * _rng.randf_range(0.97, 1.03)
	var r := maxf(box.size.x, box.size.z) * s * 0.5
	var hh := box.size.y * s
	if not _tree_spot_ok(p, r, hh):
		n.free()
		return false
	n.position = p - Vector3(0, box.position.y * s, 0)
	n.rotation_degrees.y = _rng.randf() * 360.0
	n.scale = Vector3.ONE * s
	add_child(n)
	_blocked.append({"p": p, "r": 0.9})
	_footprints.append({"p": p, "r": r, "h": hh, "prop": true, "base_y": _aabb(n, n.transform).position.y})
	return true


## True when a new prop at `p` (radius `r`) would sit inside another prop's trunk zone (canopies may overlap a little).
func _hits_prop(p: Vector3, r: float) -> bool:
	for f in _footprints:
		if f.has("prop") and (f["p"] as Vector3).distance_to(p) < minf(float(f["r"]), r) * 0.9 + 0.6:
			return true
	return false


## Screen rect (design px) a prop covers: canopy width, from its foot up to its top.
func _prop_rect(p: Vector3, r: float, hh: float) -> Rect2:
	var cx := 960.0 + p.dot(_right) * PPU
	var cy := DIAMOND_CY - p.dot(_g) * sin(deg_to_rad(PITCH)) * PPU
	var up := hh * cos(deg_to_rad(PITCH)) * PPU
	return Rect2(cx - r * PPU, cy - up, r * 2.0 * PPU, up)


func _hits_building(p: Vector3, r: float, hh: float) -> bool:
	var pr := _prop_rect(p, r, hh)
	for br in _bld_rects:
		if pr.intersects(br):
			return true
	return false


## True when a prop at ground point `p` (footprint radius `r`, height `hh`, world units) lies inside the land
## diamond on screen: the base ring and the top ring, `margin` design px inside the edge.
func _screen_fits(p: Vector3, r: float, hh: float, margin: float = 6.0) -> bool:
	var half_w := PLOT_SIDE * 0.5 * sqrt(2.0) * PPU - margin
	var half_h := PLOT_SIDE * 0.5 * sqrt(2.0) * sin(deg_to_rad(PITCH)) * PPU - margin
	var cx := 960.0 + p.dot(_right) * PPU
	var cy := DIAMOND_CY - p.dot(_g) * sin(deg_to_rad(PITCH)) * PPU
	var up := hh * cos(deg_to_rad(PITCH)) * PPU
	for dx in [-r * PPU, 0.0, r * PPU]:
		for dy in [0.0, -up]:
			if absf(cx + dx - 960.0) / half_w + absf(cy + dy - DIAMOND_CY) / half_h > 1.0:
				return false
	return true


## Pulls a ground point in so a disc of radius `r` around it stays on the land (the top is a PLOT_SIDE square).
func _clamp_in(p: Vector3, r: float) -> Vector3:
	var lim := PLOT_SIDE * 0.5 - r - LAND_EDGE_MARGIN
	return Vector3(clampf(p.x, -lim, lim), p.y, clampf(p.z, -lim, lim))


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
	_build_hud()
	_build_banners()
	_build_toast()
	_wire_focus()
	_refresh_signs()


## Focus order (spec 01): Start run, Daily, New run, places in key order (1-7, B), settings, back to Start.
func _wire_focus() -> void:
	var order: Array[Control] = [_run_plate]
	if _daily_btn.visible:
		order.append(_daily_btn)
	if _new_run_btn.visible:
		order.append(_new_run_btn)
	for id in NUM_KEYS + ["board"]:
		if _hits.has(id):
			order.append(_hits[id])
	order.append(find_child("Settings", true, false) as Control)
	for i in order.size():
		var nxt := order[(i + 1) % order.size()]
		var prv := order[(i - 1 + order.size()) % order.size()]
		order[i].focus_next = order[i].get_path_to(nxt)
		order[i].focus_previous = order[i].get_path_to(prv)


func _add_house_hit(id: String) -> void:
	var btn := Button.new()
	btn.name = "Hit_" + id
	btn.flat = true
	btn.focus_mode = Control.FOCUS_ALL   # the name plate shows while focused
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.focus_entered.connect(_focus.bind(id, true))
	btn.focus_exited.connect(_focus.bind(id, false))
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
		if _hits.has(_touch_id):
			UI3Tooltip.hide_for(_hits[_touch_id] as Control)
		_touch_id = ""
		_refresh_signs()


func _on_hit_pressed(id: String) -> void:
	if _is_touch() and id != "portal" and _touch_id != id:
		_touch_id = id
		_refresh_signs()
		UI3Tooltip.show_now(_hits[id] as Control)   # first tap shows the name, second tap opens
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


## Names live in a UI3 tooltip only: hover, keyboard focus, or the first touch tap. The text is rebuilt on every
## hover / focus / state change so status and lock reasons are current.
func _refresh_signs() -> void:
	for id in _hits:
		UI3Tooltip.bind(_hits[id] as Control, _tip_text(id))
	for id in _plot_marks:
		UI3Tooltip.bind(_plot_marks[id] as Control, _tip_text(id))
	_layout()


## "Name  [key]" title, then the lock reason if locked, else the useful status and the sub-line.
func _tip_text(id: String) -> String:
	var m: Dictionary = META.get(id, {"name": id, "key": "", "sub": ""})
	var head := String(m["name"])
	if String(m["key"]) != "":
		head += " · " + String(m["key"])
	var why := _block_reason(id)
	var lines: Array[String] = []
	if why != "":
		lines.append(why)
	else:
		var st := _tag_words(id)
		if st != "":
			lines.append(st)
		var sub := String(m["sub"])
		if id == "portal":
			sub = _continue_line() if _has_run else ""
		if sub != "":
			lines.append(sub)
	if lines.is_empty():
		return head
	return head + "\n" + " · ".join(lines)


func _tag_words(id: String) -> String:
	match _tag(id):
		"FREE":
			return "Free roll ready"
		"CLAIM":
			return "Reward ready to claim"
		"NEW":
			return "Something new"
	return ""


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


# ---------------------------------------------------------------- HUD (UI-03: 4 corner groups)

## Flat clickable layer over a plate cell: hover tint, amber focus ring, content passes mouse through.
func _cell(btn_name: String, content: Control, on_press: Callable) -> MarginContainer:
	var mc := MarginContainer.new()
	mc.theme = UI3Theme.get_theme()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_child(content)
	var b := Button.new()
	b.name = btn_name
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, empty)
	b.add_theme_stylebox_override("hover", UI3Theme.flat(Color(1, 1, 1, 0.08), UI3Theme.radius("s")))
	b.pressed.connect(on_press)
	mc.add_child(b)
	UI3.attach_focus_ring(b)
	return mc


func _build_hud() -> void:
	# Top-left: profile plate (+ quiet Land upgrade link under it).
	_hud_tl = VBoxContainer.new()
	_hud_tl.name = "HudTopLeft"
	_hud_tl.theme = UI3Theme.get_theme()
	_hud_tl.add_theme_constant_override("separation", UI3Theme.space("8"))
	_ui.add_child(_hud_tl)
	var prof := UI3.plate(&"plate")
	prof.name = "ProfilePlate"
	prof.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	prof.add_child(_profile_cell())
	_hud_tl.add_child(prof)
	var lp := UI3.plate(&"plate")
	lp.name = "LandPlate"
	lp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lp.add_child(_land_link())
	_hud_tl.add_child(lp)

	# Top-right: one plate, currencies then settings (spec 01).
	_wallet = UI3.plate(&"plate")
	_wallet.name = "Wallet"
	var wrow := HBoxContainer.new()
	wrow.add_theme_constant_override("separation", UI3Theme.space("24"))
	_wallet.add_child(wrow)
	var cur := UI3.currency_pill(UI3.currency_entries(_loading))   # one order everywhere
	_currencies = cur.get_child(0) as Control   # the pill's own row of icon + value cells
	cur.remove_child(_currencies)
	cur.free()
	_currencies.name = "Currencies"
	_currencies.visible = not _guest   # signed out: currencies hidden
	wrow.add_child(_currencies)
	var st := UI3.icon_button("ui_settings", "Settings")
	st.name = "Settings"
	st.pressed.connect(_open_screen.bind(&"settings"))
	wrow.add_child(st)
	_ui.add_child(_wallet)

	# Bottom-left: Show names (N) and Codex (C).
	_hud_bl = UI3.plate(&"plate")
	_hud_bl.name = "HudBottomLeft"
	var blr := HBoxContainer.new()
	blr.add_theme_constant_override("separation", UI3Theme.space("24"))
	_hud_bl.add_child(blr)
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", UI3Theme.space("12"))
	crow.add_child(UI3.key_hint("C"))
	crow.add_child(UI3.label("Codex"))
	blr.add_child(_cell("Codex", crow, _on_rail_pressed.bind(&"codex")))
	# Moon Card: L1 shows it disabled, no price (answered in round 2). Hidden when signed out.
	_moon_btn = UI3.button("Moon Card · Coming soon", &"secondary", &"S")
	_moon_btn.name = "MoonCardButton"
	_moon_btn.disabled = true
	_moon_btn.visible = not _guest
	blr.add_child(_moon_btn)
	_ui.add_child(_hud_bl)

	# Bottom-right: one primary, up to two secondary.
	_hud_br = HBoxContainer.new()
	_hud_br.name = "HudBottomRight"
	_hud_br.theme = UI3Theme.get_theme()
	_hud_br.add_theme_constant_override("separation", UI3Theme.space("16"))
	_hud_br.alignment = BoxContainer.ALIGNMENT_END
	_ui.add_child(_hud_br)
	_new_run_btn = UI3.button("New run · N", &"secondary", &"M")
	_new_run_btn.name = "NewRunButton"
	_new_run_btn.pressed.connect(_on_new_run_pressed)
	_new_run_btn.visible = _has_run
	_hud_br.add_child(_new_run_btn)
	_daily_btn = UI3.button("Daily run", &"secondary", &"M")
	_daily_btn.name = "Rail_Daily"
	_daily_btn.pressed.connect(_on_rail_pressed.bind(&"daily"))
	var dwhy := _block_reason_screen(&"daily")
	if dwhy != "":
		UI3.set_disabled_reason(_daily_btn, "Daily run · needs connection")
	elif _tag("daily") == "CLAIM":
		_daily_btn.text = "Daily run · claim"
	_daily_btn.visible = not (_first and not _has_run) and not _guest   # first visit / signed out: Daily hidden
	_hud_br.add_child(_daily_btn)
	_load_daily_tries()
	_run_plate = _build_run_button()
	_hud_br.add_child(_run_plate)


## Daily tries left today ("Daily run · 2 of 3"), the same numbers Run Setup shows. Quiet when offline,
## signed out or not server-rolled: the button then keeps its plain label.
func _load_daily_tries() -> void:
	if qa.has("daily_tries"):
		_apply_daily_tries(qa["daily_tries"])
		return
	if _offline or _guest or String(ProjectSettings.get_setting("axie/epoch_source", "")) != "remote":
		return
	var ref: WeakRef = weakref(self)
	RunState.run_session().daily_info(func(ok: bool, data: Dictionary) -> void:
		var me: Variant = ref.get_ref()
		if ok and me != null:
			me._apply_daily_tries({"used": int(data.get("used", 0)), "max": int(data.get("max", 3))}))


func _apply_daily_tries(t: Dictionary) -> void:
	if _daily_btn == null or _daily_btn.disabled:
		return
	var mx := int(t.get("max", 3))
	_daily_btn.text = "Daily run · %d of %d" % [maxi(mx - int(t.get("used", 0)), 0), mx]
	if _offline_banner != null:   # HUD still building when the QA hook answers at once
		_layout()


func _profile_cell() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UI3Theme.space("16"))
	var name := "Guest"
	if not _guest:
		name = AccountService.display_name() if AccountService.is_signed_in() else "Player"
	var av := PanelContainer.new()
	av.add_theme_stylebox_override("panel", UI3Theme.flat(
		UI3Theme.color("disabled") if _guest else UI3Theme.color("accent"), 24))
	av.custom_minimum_size = Vector2(48, 48)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ini := UI3.label("?" if _guest else name.left(1).to_upper(), "LabelDisplay")
	ini.add_theme_color_override("font_color", UI3Theme.color("accent_text"))
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	av.add_child(ini)
	h.add_child(AvatarFrame.wrap_holder(av, 48.0, MetaState.equipped_frame))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var nl := UI3.label(name.left(16), "LabelTitle")
	nl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.custom_minimum_size.x = 220   # name budget 220 px, best line 260 px (ellipsis)
	col.add_child(nl)
	var sub := "Sign in to save online"
	if not _guest:
		sub = _best_line()
		if MetaState.equipped_title != "":
			sub = TitleNames.display(MetaState.equipped_title)
	var bl := UI3.label(sub.left(24), "LabelMuted")
	bl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	bl.custom_minimum_size.x = 220
	col.add_child(bl)
	h.add_child(col)
	h.add_child(UI3.key_hint("P"))
	return _cell("ProfileChip", h, _open_profile)


## "Best: A3" from the real won-ascension record, "No wins yet" otherwise (never a made-up number).
func _best_line() -> String:
	var best := -1
	for k in MetaState.asc_wins:
		if int(MetaState.asc_wins[k]) > 0:
			best = maxi(best, int(k))
	return "Best: A%d" % best if best >= 0 else "No wins yet"


## Land tier link under the profile plate (key L). Tier 6 has nothing left to upgrade.
func _land_link() -> Control:
	var tn: String = TIER_NAMES[_tier - 1]
	if _tier >= 6:
		var l := UI3.label("%s Land · max tier" % tn, "LabelMuted")
		l.name = "LandChip"
		return l
	var need := _upgrade_cost()
	var have := _meta_int("stone")
	var can_up := preload("res://scripts/meta/economy_db.gd").land_upgrade_enabled() and have >= need
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI3Theme.space("8"))
	row.add_child(UI3.key_hint("L"))
	var txt := "Upgrade Land · %s %d/6" % [tn, _tier]
	row.add_child(UI3.label(txt + (" · ready" if can_up else "")))
	var cell := _cell("UpgradeLand", row, _on_land_pressed)
	cell.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cell.get_node("UpgradeLand").tooltip_text = "%s / %s Land Stone" % [_fmt(have), _fmt(need)]
	return cell


## Primary "Start run" (signed out: "Sign in to play"). Name stays RunPlate.
func _build_run_button() -> Button:
	var title := "Start run"
	var tip := "Guided first run" if _first else "Run Setup"
	if _has_run:
		if _mission_run:
			title = "Continue mission"
			tip = _mission_line()
		else:
			title = "Continue run"
			tip = _continue_line()
	elif _guest:
		title = "Sign in to play"
		tip = "Sign in to save your runs online"
	var plate := UI3.button(title, &"primary", &"L")
	plate.name = "RunPlate"
	plate.tooltip_text = tip
	plate.pressed.connect(_on_run_pressed)
	if _offline and not _has_run and not _guest:   # round 2: a new run needs a connection
		UI3.set_disabled_reason(plate, "Start run · needs connection")
	if _first and not _has_run:
		plate.grab_focus.call_deferred()
	# "Start here" coach card (640 wide, 32x20 arrow toward the Start run spotlight).
	_start_hint = VBoxContainer.new()
	_start_hint.name = "StartHint"
	_start_hint.theme = UI3Theme.get_theme()
	_start_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_start_hint.add_theme_constant_override("separation", 0)
	var card := UI3.plate(&"dialog")
	card.custom_minimum_size.x = 640
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hv := VBoxContainer.new()
	hv.add_child(UI3.label("Start here", "LabelTitle"))
	var hb := UI3.label("Your first run is a short guided one", "LabelMuted")
	hb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hb.custom_minimum_size.x = 592   # card 640 minus 24 padding each side
	hv.add_child(hb)
	card.add_child(hv)
	_start_hint.add_child(card)
	var arrow := Control.new()
	arrow.name = "HintArrow"
	arrow.custom_minimum_size = Vector2(640, 20)
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.draw.connect(func() -> void:
		var cx := 640.0 - plate.size.x * 0.5
		arrow.draw_colored_polygon(PackedVector2Array([Vector2(cx - 16, 0), Vector2(cx + 16, 0), Vector2(cx, 20)]),
			UI3Theme.color("panel")))
	_start_hint.add_child(arrow)
	_start_hint.visible = _first and not _has_run and not _guest
	_ui.add_child(_start_hint)
	return plate


func _continue_line() -> String:
	if not _has_run:
		return ""
	return "%s · Ascension %d" % [String(RunState.mode).capitalize(), int(RunState.ascension)]


func _mission_line() -> String:
	var e: Dictionary = MetaState.mission_escrow
	return "Mission %s · stake %s" % [String(e.get("mission_id", "N?")).to_upper(), _fmt(int(e.get("stake", 0)))]


func _build_banners() -> void:
	_offline_banner = UI3.net_notice("Offline · Runs, Store, Pass, Echo Box, Daily and Leaderboard need a connection.",
		"Retry", _on_retry)
	_offline_banner.name = "OfflineBanner"
	_offline_banner.custom_minimum_size = Vector2(600, 0)
	var msg := _offline_banner.find_children("*", "Label", true, false)
	if not msg.is_empty():
		(msg[0] as Label).custom_minimum_size.x = 440
	var rb := _offline_banner.find_child("Retry", true, false)
	if rb != null:
		rb.name = "RetryButton"
	_offline_banner.visible = _offline
	_ui.add_child(_offline_banner)


func _on_retry() -> void:
	if _detect_offline():
		_show_toast("Still offline", 1.6, &"error")
		return
	qa.erase("offline")
	get_tree().reload_current_scene()


func _build_toast() -> void:
	# UI-03 18-system: the toast is rebuilt per message by _show_toast (UI3.toast, top-centre 24 px down).
	_toast = null


func _show_toast(text: String, hold: float = 1.6, tone: StringName = &"ok") -> void:
	# Stack of at most 3, top-centre, 24 px from the top, 8 px gap (UI-03 18-system).
	_toasts = _toasts.filter(func(t: Variant) -> bool: return is_instance_valid(t))
	while _toasts.size() >= 3:
		(_toasts.pop_front() as Node).queue_free()
	var tw_node := UI3.toast(text, tone)
	tw_node.name = "Toast"
	tw_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(tw_node)
	_toasts.append(tw_node)
	_toast = tw_node
	_layout_toasts()
	var tw := create_tween()
	tw.tween_interval(hold)
	tw.tween_property(tw_node, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void:
		if is_instance_valid(tw_node):
			tw_node.queue_free()
		_toasts.erase(tw_node)
		_layout_toasts())


func _layout_toasts() -> void:
	var y := 24.0
	for t in _toasts:
		if not is_instance_valid(t) or t.is_queued_for_deletion():
			continue
		var c := t as Control
		c.reset_size()
		c.position = Vector2((_ui.size.x - c.size.x) * 0.5, y)
		y += c.size.y + 8.0


func _fmt(v: int) -> String:
	return UI3.fmt(v)


# ================================================================ layout (design px + dy)

func _layout() -> void:
	if _ui == null or _hud_br == null:
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
	for p in _plots:
		var id := String(p["id"])
		var cx := float(p["cx"])
		var base := float(p["base"]) + dy
		var mark: Control = _plot_marks[id]
		mark.size = Vector2(200, 108)
		mark.position = Vector2(cx - 100.0, base - 108.0)


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
	_hud_tl.reset_size()
	_hud_tl.scale = sc
	_hud_tl.position = Vector2(24, 24)
	_wallet.reset_size()
	_wallet.scale = sc
	_wallet.position = Vector2(w - 24.0 - _wallet.get_combined_minimum_size().x * f, 24)
	_hud_bl.reset_size()
	_hud_bl.scale = sc
	_hud_bl.position = Vector2(24, h - 24.0 - _hud_bl.get_combined_minimum_size().y * f)
	_hud_br.reset_size()
	var bsz := _hud_br.get_combined_minimum_size()
	_hud_br.scale = sc
	_hud_br.position = Vector2(w - 24.0 - bsz.x * f, h - 24.0 - bsz.y * f)
	_start_hint.reset_size()
	var hs := _start_hint.get_combined_minimum_size()
	_start_hint.scale = sc
	_start_hint.position = Vector2(w - 24.0 - hs.x * f, h - 24.0 - bsz.y * f - 4.0 * f - hs.y * f)
	_offline_banner.reset_size()
	var os := _offline_banner.get_combined_minimum_size()
	_offline_banner.scale = sc
	_offline_banner.position = Vector2((w - os.x * f) * 0.5, h - 24.0 - os.y * f)   # bottom centre: clear of every place chip


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
	if _guest:   # sign-in stays required before a run
		AccountService.sign_in()
		return
	_open_screen(&"run_setup")


func _on_continue_pressed() -> void:
	if RunContinue.busy:
		_show_toast("Still reconnecting to the server…")   # never a silent press
		return
	if not RunState.load_run():
		push_warning("LandHub: saved run could not be loaded")
		RunState.clear_saved_run()
		_has_run = false
		_new_run_btn.visible = false
		_show_toast("That run could not be loaded", 1.6, &"error")
		return
	var plate := find_child("RunPlate", true, false) as Button
	_set_continue_busy(plate, true)
	var st: String = await RunContinue.reconnect(self, _on_continue_pressed, plate)
	if not is_inside_tree():
		return
	_set_continue_busy(plate, false)
	if st == "gone":
		_has_run = false
		_new_run_btn.visible = false
		_show_toast(RunState.take_discard_notice(), 5.0)
		return
	if st != "ok":
		# "failed": NetNotice (with RETRY / SIGN IN) is up. If it could not show, say so with a toast.
		if st == "failed" and get_node_or_null(NetNotice.NODE_NAME) == null:
			_show_toast("Could not reconnect to your run. Try again.", 3.0, &"error")
		return
	if not RunState.resume_combat.is_empty():
		get_tree().change_scene_to_file("res://scenes/combat/Combat.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/run_map/RunMap.tscn")


## Run plate shows "Reconnecting…" (disabled, with its reason) while Continue is out; restored after.
func _set_continue_busy(plate: Button, on: bool) -> void:
	if plate == null or not is_instance_valid(plate):
		return
	if on:
		UI3.set_disabled_reason(plate, "Reconnecting…")
	else:
		UI3.clear_disabled_reason(plate)


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


func _open_confirm(title: String, body: String, ok_text: String, on_ok: Callable, _warning: bool = false,
		cancel_text: String = "Cancel", loss: Array = [], _head: Color = Color(0, 0, 0, 0)) -> void:
	if _modal != null:
		return
	# UI-03 18-system: UI3.modal (560 w dialog). Destructive (`loss` given) = red button + focus on Cancel;
	# otherwise amber primary + focus on the primary action.
	var destructive := loss.size() >= 2
	var cancel := UI3.button(cancel_text, &"secondary")
	cancel.name = "ConfirmCancel"
	cancel.pressed.connect(_close_modal)
	var ok := UI3.button(ok_text, &"danger" if destructive else &"primary")
	ok.name = "ConfirmOk"
	ok.pressed.connect(on_ok)
	var m := UI3.modal(title, body, [cancel, ok], 0 if destructive else 1)
	m.name = "Confirm"
	m.cancelled.connect(_close_modal)
	if destructive:
		var row := ok.get_parent()
		var lb := UI3.plate(&"row")
		lb.name = "LossRow"
		lb.custom_minimum_size = Vector2(0, 48)
		var lv := VBoxContainer.new()
		lv.add_child(UI3.label(String(loss[0])))
		lv.add_child(UI3.label(String(loss[1]), "LabelMuted"))
		lb.add_child(lv)
		row.get_parent().add_child(lb)
		row.get_parent().move_child(lb, row.get_index())
	_modal = m
	_ui.add_child(_modal)


## True while anything the hub shows over the land is open: the confirm dialog, the net notice (RunContinue
## failed), the Moon Card popup, the account welcome panel.
## Not the touch sign preview: it is only a label that a tap-away clears, and a rebuild merely closes it, so it must
## never be able to hold the account rebuild (AccountService polls this with no cap). AccountService waits for
## this before rebuilding the screen, so a reload never eats a panel the player is reading.
func has_modal() -> bool:
	if _modal != null:
		return true
	if get_node_or_null(NetNotice.NODE_NAME) != null:
		return true
	if is_instance_valid(_moon_card) and not _moon_card.is_queued_for_deletion():
		return true
	return AccountService.find_child("AccountWelcome", true, false) != null


func _close_modal() -> void:
	if _modal != null:
		_modal.queue_free()
		_modal = null


## Keys (v5 table): 1-7, B, N, L, P, D, C, Enter, Esc. Returns true when the key was used.
func _handle_key(keycode: int) -> bool:
	if keycode == KEY_ESCAPE:
		if _modal != null:
			_close_modal()
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
	# A key can navigate away (LandNav -> change_scene): the hub leaves the tree inside _handle_key and
	# get_viewport() is then null. Take the viewport first.
	var vp := get_viewport()
	if _handle_key(ke.keycode) and vp != null:
		vp.set_input_as_handled()


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
		_moon_card = popup
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
