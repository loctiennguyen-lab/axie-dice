extends Node
## Lane C spacing gate: in every fight shape the party (left) and the enemies (right) are clearly apart,
## no two unit footprints overlap (+20 px), the gate stands behind every enemy, and everything stays inside
## the 3D safe area (clear of the HUD plates). Measured on the real stage camera at the 1920x1080 canvas
## (1280x720 is the same canvas scaled 0.667, so the proportions hold).
## SPACING_PRINT=1 dumps every rectangle.

const CANVAS := Vector2(1920.0, 1080.0)
const MIN_GAP_PX := 20.0            ## footprint + 20 px between any two units
const MIN_TEAM_GAP_PX := 200.0      ## empty field between the party's right edge and the nearest enemy
const MIN_GATE_GAP_PX := 40.0       ## empty space between the last enemy and the gate
const PANEL_X := 1576.0             ## left edge of the top-right enemy panel
const TRAY_Y := 884.0               ## top of the bottom tray
const KEYS: Array[String] = ["chomper", "slime", "bugling", "spikelet", "ravenling"]
const CLASSES: Array[String] = ["plant", "beast", "aqua", "reptile", "bug"]

var _fails: Array[String] = []
var _checks := 0
var _dump := OS.get_environment("SPACING_PRINT") != ""


func _ready() -> void:
	print("=== t_combat_spacing: start ===")
	for n in [1, 2, 3, 4, 5]:
		await _case("%d enemies" % n, "battle", n, false, 0, 0)
	await _case("elite alone", "elite", 1, false, 0, 0)
	await _case("elite + 2", "elite", 3, false, 0, 0)
	await _case("elite + 4", "elite", 5, false, 0, 0)
	await _case("boss", "boss", 1, true, 0, 0)
	await _case("boss + 2 summons", "boss", 3, true, 0, 0)
	await _case("boss + 4 summons", "boss", 5, true, 0, 0)
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


func _case(label: String, kind: String, n_enemy: int, boss: bool, eggs: int, party_minus: int) -> void:
	var stage: CombatStage3D = load("res://scenes/shared/CombatStage3D.tscn").instantiate()
	add_child(stage)
	stage.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stage.size = CANVAS
	await get_tree().process_frame
	stage.frame_band(CANVAS.y, 140.4, 876.0)
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
		stage.spawn_unit(uid, "", true, i, n_enemy, is_boss, "gooey_king" if is_boss else KEYS[i % KEYS.size()])
		enemies.append(uid)
		uid += 1
	stage.reseat_side(party, false)
	stage.reseat_side(enemies, true)
	for _i in 3:
		await get_tree().process_frame
	var rects: Dictionary = {}
	for u in party + enemies:
		rects[u] = stage.unit_screen_rect(int(u))
	var gate: Rect2 = stage.gate_screen_rect()
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
	_assert(enemy_left - party_right >= MIN_TEAM_GAP_PX, "%s: party/enemy gap %.0f px < %d" % [label, enemy_left - party_right, int(MIN_TEAM_GAP_PX)])
	# 3. safe area / HUD
	for u in all:
		var r: Rect2 = rects[u]
		_assert(r.position.x >= 24.0 and r.end.x <= CANVAS.x - 24.0, "%s: unit %d outside the side margins %s" % [label, u, r])
		_assert(r.end.y <= TRAY_Y, "%s: unit %d runs into the bottom tray %s" % [label, u, r])
		_assert(not (r.position.x < 424.0 and r.position.y < 190.0), "%s: unit %d under the top-left plate %s" % [label, u, r])
	for u in enemies:
		_assert((rects[u] as Rect2).end.x <= PANEL_X - 8.0 or (rects[u] as Rect2).position.y > 600.0,
			"%s: enemy %d under the enemy panel %s" % [label, u, rects[u]])
	# 4. gate behind every enemy, fully visible, clear of the panel
	_assert(gate != Rect2(), "%s: no gate" % label)
	var enemy_top := 1.0e9
	for u in enemies:
		enemy_top = minf(enemy_top, (rects[u] as Rect2).position.y)
	_assert(gate.position.x >= enemy_right + MIN_GATE_GAP_PX or gate.end.y <= enemy_top - MIN_GATE_GAP_PX * 0.5,
		"%s: gate %s is neither right of the last enemy (right %.0f) nor above the highest enemy (top %.0f)" % [label, gate, enemy_right, enemy_top])
	for u in enemies:
		_assert(not gate.grow(MIN_GAP_PX * 0.5).intersects((rects[u] as Rect2).grow(MIN_GAP_PX * 0.5)), "%s: enemy %d touches the gate" % [label, u])
	var panel := Rect2(1416.0, 24.0, 480.0, 170.0) if boss else Rect2(PANEL_X, 24.0, CANVAS.x - PANEL_X, 104.0 * float(n_enemy) + 4.0)
	_assert(gate.position.y >= 0.0 and gate.end.x <= CANVAS.x - 24.0 and not gate.intersects(panel), "%s: gate off screen or under the enemy panel %s vs %s" % [label, gate, panel])
	stage.dispose_all()
	stage.queue_free()
	await get_tree().process_frame
