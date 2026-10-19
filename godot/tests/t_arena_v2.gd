extends Node
## Lane V gate for arena v2 (Blender dioramas, res://assets/atia/arena_v2/):
##  1. stage_layout.json (what the dioramas were built against) still matches CombatStage3D's unit
##     slots / lane and the gate position in arenas.json. If this fails, update stage_layout.json and
##     re-export the dioramas (tools/art/arena_v2/export.py), or the plaza/props will be off.
##  2. every journey biome has a diorama that loads, has a ground, and stays under the tri budget.
##  3. no diorama prop footprint covers any unit slot (party, eggs, 1-5 enemy patterns on both row
##     sets, boss/elite and every add incl. the second back row).
##  4. CombatStage3D.set_arena() uses the diorama (old terrain skipped, gate kept) and falls back to
##     the old terrain when v2 is off.

const MAX_TRIS := 60000
const SLOT_CLEARANCE := 0.5   # metres between a prop footprint and a unit's feet

var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_arena_v2: start ===")
	var st := ArenaV2Diorama.stage_layout()
	_assert(not st.is_empty(), "stage_layout.json did not load")
	_check_layout(st)
	var journey: Array = CombatArena3D.registry().get("journey", [])
	for b in journey:
		_check_biome(String(b))
	await _check_stage(journey)
	print("=== t_arena_v2: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_arena_v2: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_arena_v2: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)


func _near(a: float, b: float) -> bool:
	return absf(a - b) < 0.001


func _same_pattern(json_pat: Variant, code_pat: Array) -> bool:
	if not (json_pat is Array) or (json_pat as Array).size() != code_pat.size():
		return false
	for i in code_pat.size():
		var a: Array = (json_pat as Array)[i]
		var c: Array = code_pat[i]
		if not (_near(float(a[0]), float(c[0])) and _near(float(a[1]), float(c[1]))):
			return false
	return true


func _check_layout(st: Dictionary) -> void:
	var portal_z := float(CombatArena3D.registry().get("portal", {}).get("z", 0.0))
	# The arena node is turned -90 deg about Y at x = 0: arena z -> world -x.
	_assert(_near(float(st.get("gate_x", 0.0)), -portal_z), "stage_layout gate_x %s != -portal z %s" % [st.get("gate_x"), portal_z])
	_assert(_near(float(st.get("lane_z", 0.0)), CombatStage3D.LANE_Z), "stage_layout lane_z != CombatStage3D.LANE_Z")
	var f: Dictionary = st.get("formation", {})
	var scalars := {
		"PARTY_X0": CombatStage3D.PARTY_X0, "PARTY_PITCH_X": CombatStage3D.PARTY_PITCH_X,
		"PARTY_Z_FRONT": CombatStage3D.PARTY_Z_FRONT, "PARTY_Z_BACK": CombatStage3D.PARTY_Z_BACK,
		"EGG_X0": CombatStage3D.EGG_X0, "EGG_PITCH_X": CombatStage3D.EGG_PITCH_X, "EGG_Z": CombatStage3D.EGG_Z,
		"ENEMY_CENTER_X": CombatStage3D.ENEMY_CENTER_X, "ENEMY_PITCH_X": CombatStage3D.ENEMY_PITCH_X,
		"ADD_PITCH_X": CombatStage3D.ADD_PITCH_X, "ADD_Z_BACK": CombatStage3D.ADD_Z_BACK,
		"ADD_Z_FRONT": CombatStage3D.ADD_Z_FRONT, "ADD_Z_BACK2": CombatStage3D.ADD_Z_BACK2,
	}
	for k in scalars:
		_assert(f.has(k) and _near(float(f[k]), float(scalars[k])), "stage_layout formation.%s != CombatStage3D.%s (%s)" % [k, k, scalars[k]])
	var rows: Array = f.get("ENEMY_ROWS", [])
	_assert(rows.size() == 3 and _near(float(rows[0]), CombatStage3D.ENEMY_Z_BACK) and _near(float(rows[1]), CombatStage3D.ENEMY_Z_MID)
		and _near(float(rows[2]), CombatStage3D.ENEMY_Z_FRONT), "stage_layout ENEMY_ROWS != ENEMY_Z_BACK/MID/FRONT")
	var tight: Array = f.get("ENEMY_ROWS_TIGHT", [])
	_assert(tight.size() == 3 and _same_pattern([[tight[0], tight[1]]], [[CombatStage3D.ENEMY_ROWS_TIGHT[0], CombatStage3D.ENEMY_ROWS_TIGHT[1]]])
		and _near(float(tight[2]), CombatStage3D.ENEMY_ROWS_TIGHT[2]), "stage_layout ENEMY_ROWS_TIGHT differs")
	var bp: Array = f.get("BOSS_POS", [0, 0])
	var ep: Array = f.get("ELITE_POS", [0, 0])
	_assert(_near(float(bp[0]), CombatStage3D.BOSS_POS.x) and _near(float(bp[1]), CombatStage3D.BOSS_POS.z), "stage_layout BOSS_POS differs")
	_assert(_near(float(ep[0]), CombatStage3D.ELITE_POS.x) and _near(float(ep[1]), CombatStage3D.ELITE_POS.z), "stage_layout ELITE_POS differs")
	var ep_json: Dictionary = f.get("ENEMY_PATTERNS", {})
	_assert(ep_json.size() == CombatStage3D.ENEMY_PATTERNS.size(), "stage_layout ENEMY_PATTERNS count differs")
	for n in CombatStage3D.ENEMY_PATTERNS:
		_assert(_same_pattern(ep_json.get(str(n)), CombatStage3D.ENEMY_PATTERNS[n]), "stage_layout ENEMY_PATTERNS[%d] differs" % n)
	var ap_json: Dictionary = f.get("ADD_PATTERNS", {})
	_assert(ap_json.size() == CombatStage3D.ADD_PATTERNS.size(), "stage_layout ADD_PATTERNS count differs")
	for n in CombatStage3D.ADD_PATTERNS:
		_assert(_same_pattern(ap_json.get(str(n)), CombatStage3D.ADD_PATTERNS[n]), "stage_layout ADD_PATTERNS[%d] differs" % n)
	_assert(_same_pattern(f.get("ADD_EXTRA"), CombatStage3D.ADD_EXTRA), "stage_layout ADD_EXTRA differs")


## Every (x, z) a unit can stand on, straight from CombatStage3D's constants.
static func unit_slots() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in 5:
		out.append(Vector2(CombatStage3D.PARTY_X0 + i * CombatStage3D.PARTY_PITCH_X,
			CombatStage3D.PARTY_Z_FRONT if i % 2 == 0 else CombatStage3D.PARTY_Z_BACK))
	for i in 4:
		out.append(Vector2(CombatStage3D.EGG_X0 + i * CombatStage3D.EGG_PITCH_X, CombatStage3D.EGG_Z))
	var row_sets := [[CombatStage3D.ENEMY_Z_BACK, CombatStage3D.ENEMY_Z_MID, CombatStage3D.ENEMY_Z_FRONT], CombatStage3D.ENEMY_ROWS_TIGHT]
	for n in CombatStage3D.ENEMY_PATTERNS:
		for rows in row_sets:
			for ent in CombatStage3D.ENEMY_PATTERNS[n]:
				out.append(Vector2(CombatStage3D.ENEMY_CENTER_X + float(ent[0]) * CombatStage3D.ENEMY_PITCH_X, float(rows[int(ent[1]) + 1])))
	var adds: Array = []
	for n in CombatStage3D.ADD_PATTERNS:
		adds.append_array(CombatStage3D.ADD_PATTERNS[n])
	adds.append_array(CombatStage3D.ADD_EXTRA)
	for lead in [CombatStage3D.BOSS_POS, CombatStage3D.ELITE_POS]:
		out.append(Vector2(lead.x, lead.z))
		for ent in adds:
			var r := int(ent[1])
			var z := CombatStage3D.ADD_Z_FRONT if r > 0 else (CombatStage3D.ADD_Z_BACK2 if r < -1 else CombatStage3D.ADD_Z_BACK)
			out.append(Vector2(lead.x + float(ent[0]) * CombatStage3D.ADD_PITCH_X, z))
	return out


func _check_biome(b: String) -> void:
	_assert(ArenaV2Diorama.has_biome(b), "biome %s has no arena v2 GLB" % b)
	var d := ArenaV2Diorama.new()
	add_child(d)
	_assert(d.build(b), "biome %s diorama does not build" % b)
	var tris := d.triangle_count()
	_assert(tris > 1000 and tris <= MAX_TRIS, "biome %s diorama has %d tris (budget %d)" % [b, tris, MAX_TRIS])
	var has_ground := false
	var slots := unit_slots()
	for n in d.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.name.begins_with("G_"):
			has_ground = true
			_check_flat(b, mi, slots)
			continue
		var box: AABB = mi.global_transform * mi.get_aabb()
		# Trees overhang with their canopy and the big mesas are long and shallow (as in layout.py).
		var k := 0.35 if mi.name.contains("_tree_") else (0.45 if (mi.name.contains("_mesa_") or mi.name.contains("_ridge")) else 1.0)
		var c := box.get_center()
		var foot := Rect2(c.x - box.size.x * 0.5 * k, c.z - box.size.z * 0.5 * k, box.size.x * k, box.size.z * k).grow(SLOT_CLEARANCE)
		for s in slots:
			_assert(not foot.has_point(s), "biome %s prop %s footprint %s covers unit slot %s" % [b, mi.name, foot, s])
	_assert(has_ground, "biome %s diorama has no G_ ground mesh" % b)
	remove_child(d)
	d.queue_free()


## Units stand on y = 0: every ground vertex within 1.5 m of a unit slot must be flat (no unit sunk
## into a slope, e.g. the second back row of adds at z -18.3).
func _check_flat(b: String, mi: MeshInstance3D, slots: Array[Vector2]) -> void:
	var xf := mi.global_transform
	for s in mi.mesh.get_surface_count():
		var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
		var worst := 0.0
		for v in verts:
			var w := xf * v
			for sl in slots:
				if absf(w.x - sl.x) <= 1.5 and absf(w.z - sl.y) <= 1.5:
					worst = maxf(worst, absf(w.y))
					break
		_assert(worst < 0.05, "biome %s ground is not flat under a unit slot (|y| up to %.2f m)" % [b, worst])


func _check_stage(journey: Array) -> void:
	var stage: CombatStage3D = load("res://scenes/shared/CombatStage3D.tscn").instantiate()
	add_child(stage)
	await get_tree().process_frame
	for b in journey:
		for boss in [false, true]:
			_assert(stage.set_arena(String(b), boss), "set_arena %s boss=%s failed" % [b, boss])
			var d := stage.arena_diorama()
			_assert(d != null and d.biome_id == String(b), "%s boss=%s: no diorama in the stage" % [b, boss])
			_assert(stage.has_gate(), "%s boss=%s: gate missing with the diorama" % [b, boss])
	stage.arena_v2_enabled = false
	_assert(stage.set_arena("savannah", false), "set_arena with v2 off failed")
	_assert(stage.arena_diorama() == null, "v2 off: the diorama should be gone (old terrain)")
	_assert(stage.has_gate(), "v2 off: gate missing")
	stage.queue_free()
	await get_tree().process_frame
