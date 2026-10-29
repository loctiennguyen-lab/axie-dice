extends Node
## Lane C spacing gate: in every fight shape the party (left) and the enemies (right) are clearly apart,
## no two unit footprints overlap (+20 px), the gate stands behind every enemy, and everything stays inside
## the 3D safe area (clear of the HUD plates). Measured on the real stage camera at the 1920x1080 canvas
## (1280x720 is the same canvas scaled 0.667, so the proportions hold).
## SPACING_PRINT=1 dumps every rectangle.

const CANVAS := Vector2(1920.0, 1080.0)
const MIN_GAP_PX := 20.0            ## footprint + 20 px between any two units
const MIN_TEAM_GAP_PX := 180.0      ## empty field between the party's right edge and the nearest enemy
const MIN_GATE_GAP_PX := 30.0       ## empty space between the last enemy and the gate
const PANEL_X := 1576.0             ## left edge of the top-right enemy panel
## Top of the DieCards: 828 at 1080 with the UI-05 DiceDock (was 884 over the old tray). Set in _ready().
var TRAY_Y := 884.0
const KEYS: Array[String] = ["chomper", "slime", "bugling", "spikelet", "ravenling"]
const CLASSES: Array[String] = ["plant", "beast", "aqua", "reptile", "bug"]

var _fails: Array[String] = []
var _checks := 0
var _dump := OS.get_environment("SPACING_PRINT") != ""


func _ready() -> void:
	print("=== t_combat_spacing: start ===")
	TRAY_Y = TrayColumn.card_top(CANVAS.y)
	for n in [1, 2, 3, 4, 5]:
		await _case("%d enemies" % n, "battle", n, false, 0, 0)
	await _case("elite alone", "elite", 1, false, 0, 0)
	await _case("elite + 2", "elite", 3, false, 0, 0)
	await _case("elite + 4", "elite", 5, false, 0, 0)
	await _case("boss", "boss", 1, true, 0, 0)
	await _case("boss + 2 summons", "boss", 3, true, 0, 0)
	await _case("boss + 4 summons", "boss", 5, true, 0, 0)
	await _case("boss + 6 summons", "boss", 7, true, 0, 0)
	await _case("4 eggs, 3 enemies", "battle", 3, false, 4, 0)
	await _case("4 eggs, 5 enemies", "battle", 5, false, 4, 0)
	await _case("4 party, 5 enemies", "battle", 5, false, 0, 1)
	print("=== t_combat_spacing: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_combat_spacing: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_combat_spacing: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)


## Each case runs at the 1920x1080 canvas and at a 1280x720 stage (same layout, scale 0.667); all rects are
## brought back to 1920 space before checking.
func _case(label: String, kind: String, n_enemy: int, boss: bool, eggs: int, party_minus: int) -> void:
	await _case_k(label, kind, n_enemy, boss, eggs, party_minus, 1.0)
	await _case_k(label + " @1280", kind, n_enemy, boss, eggs, party_minus, 1280.0 / 1920.0)


func _case_k(label: String, kind: String, n_enemy: int, boss: bool, eggs: int, party_minus: int, k: float) -> void:
	var stage: CombatStage3D = load("res://scenes/shared/CombatStage3D.tscn").instantiate()
	add_child(stage)
	stage.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stage.size = CANVAS * k
	await get_tree().process_frame
	var band := CombatView.stage_band(CANVAS.y)   # the band the game uses (UI-05 dock)
	stage.frame_band(CANVAS.y * k, band.x * k, band.y * k)
	stage.set_encounter_kind(kind)
	stage.set_arena("savannah", boss)
	var party: Array = []
	var enemies: Array = []
	var uid := 1
	var n_party := 5 - party_minus
	for i in n_party:
		stage.spawn_unit(uid, CLASSES[i], false, i, n_party)
		party.append(uid)
		uid += 1
	for i in eggs:
		stage.spawn_unit(uid, "plant", false, i, eggs, false, "egg")
		party.append(uid)
		uid += 1
	for i in n_enemy:
		var is_boss := boss and i == 0
		# Next to a live boss every other enemy is a summon, and combat spawns those with is_summon=true so they
		# are drawn at SUMMON_SCALE (0.7). Spawn them the same way here, otherwise the test measures full-size
		# adds that never occur in the game.
		stage.spawn_unit(uid, "", true, i, n_enemy, is_boss, "gooey_king" if is_boss else KEYS[i % KEYS.size()], "", boss and not is_boss)
		enemies.append(uid)
		uid += 1
	stage.reseat_side(party, false)
	stage.reseat_side(enemies, true)
	for _i in 3:
		await get_tree().process_frame
	var rects: Dictionary = {}
	for u in party + enemies:
		var rk: Rect2 = stage.unit_screen_rect(int(u))
		rects[u] = Rect2(rk.position / k, rk.size / k)
	var gk: Rect2 = stage.gate_screen_rect()
	var gate := Rect2(gk.position / k, gk.size / k)
	if _dump:
		for u in party + enemies:
			print("  ", label, " uid ", u, " ", "enemy" if enemies.has(u) else "party", " ", rects[u])
		print("  ", label, " gate ", gate)
	# 1. no overlap, 20 px apart
	var all: Array = party + enemies
	for i in all.size():
		for j in range(i + 1, all.size()):
			var a: Rect2 = rects[all[i]]
			var b: Rect2 = rects[all[j]]
			_assert(not a.grow(MIN_GAP_PX * 0.5).intersects(b.grow(MIN_GAP_PX * 0.5)),
				"%s: units %d and %d overlap or are closer than %d px (%s vs %s)" % [label, all[i], all[j], int(MIN_GAP_PX), a, b])
	# 2. team gap
	var party_right := -1.0e9
	var enemy_left := 1.0e9
	var enemy_right := -1.0e9
	for u in party:
		party_right = maxf(party_right, (rects[u] as Rect2).end.x)
	for u in enemies:
		enemy_left = minf(enemy_left, (rects[u] as Rect2).position.x)
		enemy_right = maxf(enemy_right, (rects[u] as Rect2).end.x)
	# A boss or elite with four adds is the most crowded board there is; its far-left add may stand 160 px off.
	var need_gap := 160.0 if (kind != "battle" and n_enemy >= 5) else MIN_TEAM_GAP_PX
	_assert(enemy_left - party_right >= need_gap, "%s: party/enemy gap %.0f px < %d" % [label, enemy_left - party_right, int(need_gap)])
	# 3. safe area / HUD
	for u in all:
		var r: Rect2 = rects[u]
		_assert(r.position.x >= 24.0 and r.end.x <= CANVAS.x - 24.0, "%s: unit %d outside the side margins %s" % [label, u, r])
		_assert(r.end.y <= TRAY_Y, "%s: unit %d runs into the bottom tray %s" % [label, u, r])
		_assert(not (r.position.x < 424.0 and r.position.y < 190.0), "%s: unit %d under the top-left plate %s" % [label, u, r])
	for u in enemies:
		_assert((rects[u] as Rect2).end.x <= PANEL_X - 8.0 or (rects[u] as Rect2).position.y > 600.0,
			"%s: enemy %d under the enemy panel %s" % [label, u, rects[u]])
	# 3b. every unit is really on screen (non-empty rect inside the canvas) and not standing inside a tall prop
	for u in all:
		var rr: Rect2 = rects[u]
		_assert(rr.size.x >= 40.0 and rr.size.y >= 40.0, "%s: unit %d has an empty or tiny screen rect %s" % [label, u, rr])
		_assert(Rect2(Vector2.ZERO, CANVAS).encloses(rr), "%s: unit %d is not fully on screen %s" % [label, u, rr])
	var arena: Node = stage.get("_arena")
	var props: Node = arena.get("_props_root")
	for pn in props.get_children():
		if not (pn is Node3D) or pn is MeshInstance3D or pn is MultiMeshInstance3D or pn is OmniLight3D or pn == arena.get("_portal"):
			continue
		var pb: AABB = (pn as Node3D).global_transform * CombatArena3D._aabb_of(pn as Node3D)
		if pb.size.y < 1.0:
			continue
		var foot := Rect2(pb.position.x, pb.position.z, pb.size.x, pb.size.z).grow(0.3)
		for u in all:
			var sp: Vector3 = (stage.slot_node_of(int(u)) as Node3D).global_position
			_assert(not foot.has_point(Vector2(sp.x, sp.z)), "%s: unit %d stands inside prop %s %s box %s" % [label, u, pn.name, (pn as Node3D).scene_file_path, pb])
	# 3c. the gate is the axis of the enemy group: centroid of the enemy rects within 40 px (vertically) of the gate centre
	var cy := 0.0
	for u in enemies:
		cy += (rects[u] as Rect2).get_center().y
	cy /= float(enemies.size())
	_assert(enemies.size() > 5 or absf(cy - gate.get_center().y) <= 40.0, "%s: enemy group centroid y %.0f is off the gate axis %.0f" % [label, cy, gate.get_center().y])
	# 3d. the dice landing zone (1..8 dice) fits in the empty gap between the teams; 9..11 dice may spill 0.7 m
	# into it. The fence bounds the zone, so settled dice stay inside it.
	for nd in [1, 5, 8, 11]:
		var zone := DiceRoller3D.landing_zone(nd, stage.landing_center())
		var zr: Rect2 = stage._project_box(AABB(Vector3(zone.position.x, 0.0, zone.position.y), Vector3(zone.size.x, 0.1, zone.size.y)))
		var zr1 := Rect2(zr.position / k, zr.size / k)
		var slack := 30.0 if nd <= 6 else 90.0
		_assert(zr1.position.x >= party_right - slack and zr1.end.x <= enemy_left + slack,
			"%s: %d-dice landing zone %s is not inside the gap between party (right %.0f) and enemies (left %.0f)" % [label, nd, zr1, party_right, enemy_left])
	# 3e. settled dice never overlap or touch: the screen rects of all landing cells are disjoint (4 px gap), 1..11 dice
	for nd in range(1, 12):
		var centre: Vector3 = stage.landing_center()
		var drects: Array[Rect2] = []
		for di in nd:
			var sp := DiceRoller3D.landing_spot(di, nd, centre)
			var db: Rect2 = stage._project_box(AABB(sp - Vector3.ONE * DiceRoller3D.DIE_M * 0.5, Vector3.ONE * DiceRoller3D.DIE_M))
			drects.append(Rect2(db.position / k, db.size / k))
		for a in nd:
			for b in range(a + 1, nd):
				_assert(not (drects[a] as Rect2).grow(2.0).intersects((drects[b] as Rect2).grow(2.0)),
					"%s: %d dice: dice %d and %d overlap or touch on screen (%s vs %s)" % [label, nd, a, b, drects[a], drects[b]])
	# 4. gate behind every enemy, fully visible, clear of the panel
	_assert(gate != Rect2(), "%s: no gate" % label)
	var enemy_top := 1.0e9
	for u in enemies:
		enemy_top = minf(enemy_top, (rects[u] as Rect2).position.y)
	_assert(gate.position.x >= enemy_right + MIN_GATE_GAP_PX or gate.end.y <= enemy_top - MIN_GATE_GAP_PX * 0.5,
		"%s: gate %s is neither right of the last enemy (right %.0f) nor above the highest enemy (top %.0f)" % [label, gate, enemy_right, enemy_top])
	for u in enemies:
		_assert(not gate.grow(MIN_GAP_PX * 0.5).intersects((rects[u] as Rect2).grow(MIN_GAP_PX * 0.5)), "%s: enemy %d touches the gate" % [label, u])
	var panel := Rect2(1416.0, 24.0, 480.0, 170.0) if boss else Rect2(PANEL_X, 24.0, CANVAS.x - PANEL_X, 103.0 * float(n_enemy))
	_assert(gate.position.y >= 0.0 and gate.end.x <= PANEL_X - 30.0 and not gate.intersects(panel) and gate.end.y <= TRAY_Y + 8.0,
		"%s: gate not fully left of the enemy panel column / off screen %s vs %s" % [label, gate, panel])
	stage.dispose_all()
	stage.queue_free()
	await get_tree().process_frame
