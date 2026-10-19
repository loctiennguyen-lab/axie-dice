extends Node
## DiceRoller3D API contract + skip path. Headless, so roll() must take the skip path: no bodies,
## no tweens, every die "appears in the tray" and the signals still fire in order. The shown value
## is whatever the caller passed in (physics never picks it), which the entries dict proves is
## untouched. Run: godot --headless --path godot res://tests/t_dice_roller3d.tscn

var _fails: Array[String] = []
var _checks := 0
var _log: Array[String] = []


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)
		print("FAIL: ", msg)


func _on_settled(i: int) -> void:
	_log.append("s%d" % i)


func _on_arrived(i: int) -> void:
	_log.append("a%d" % i)


func _on_all() -> void:
	_log.append("all")


func _ready() -> void:
	print("=== t_dice_roller3d: start ===")
	# Landing layout: for every dice count 1..11 no two dice land closer than a die can tumble across.
	for n in range(1, DiceRoller3D.MAX_DICE + 1):
		for i in n:
			for j in range(i + 1, n):
				var a := DiceRoller3D.landing_spot(i, n, Vector3(2.0, 0.5, -1.0))
				var b := DiceRoller3D.landing_spot(j, n, Vector3(2.0, 0.5, -1.0))
				_ok(absf(a.x - b.x) >= DiceRoller3D.LAND_GAP_X - 0.001 or absf(a.z - b.z) >= DiceRoller3D.LAND_GAP_Z - 0.001,
					"dice %d and %d of %d land too close" % [i, j, n])
	var mid := Vector3(5.0, 0.5, 3.0)
	var sx := 0.0
	for i in 11:
		sx += DiceRoller3D.landing_spot(i, 11, mid).x
	_ok(absf(sx / 11.0 - mid.x) < 0.3, "11 dice are centred on the landing centre")
	var world := Node3D.new()
	add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	var stage := Control.new()
	stage.size = Vector2(1920, 1080)
	add_child(stage)
	var roller := DiceRoller3D.new()
	add_child(roller)
	roller.setup(world, cam, stage)
	roller.die_settled.connect(_on_settled)
	roller.die_arrived.connect(_on_arrived)
	roller.all_arrived.connect(_on_all)

	_ok(roller.will_skip(), "headless run takes the skip path")
	_ok(not roller.is_rolling(), "idle before roll()")

	var slot := Node3D.new()
	world.add_child(slot)
	var entries: Array = []
	for i in 5:
		entries.append({"slot_node": slot, "face_type": "dmg", "value": i + 1, "crit": i == 2})
	var snapshot := entries.duplicate(true)
	var children_before := world.get_child_count()
	var targets: Array[int] = []
	roller.roll(entries, func(i: int) -> Vector2:
		targets.append(i)
		return Vector2(100 * i, 50))
	_ok(roller.is_rolling(), "rolling flag set right after roll()")
	_ok(_log.is_empty(), "skip signals are deferred, not emitted inside roll()")
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(not roller.is_rolling(), "not rolling after skip path finished")
	_ok(_log.size() == 11, "5 settled + 5 arrived + all_arrived (got %d)" % _log.size())
	_ok(_log.back() == "all", "all_arrived last")
	for i in 5:
		_ok(_log.has("s%d" % i) and _log.has("a%d" % i), "die %d settled and arrived" % i)
		_ok(_log.find("s%d" % i) < _log.find("a%d" % i), "die %d settles before it arrives" % i)
	_ok(entries == snapshot, "entries (values) untouched by the roller")
	_ok(world.get_child_count() == children_before, "skip path creates no physics bodies")
	_ok(cam.h_offset == 0.0, "no camera shake on the skip path")

	# Face -> surface mapping and the result-face turn, by maths (same function the tween uses).
	var cam_dir := Vector3(0.0, 0.25, 1.0).normalized()   # camera pitch -14 deg: up a little, mostly toward it
	var cam_up := Vector3.UP.slide(cam_dir).normalized()
	_ok(DiceRoller3D.FACE_NORMALS.size() == 6 and DiceRoller3D.FACE_UPS.size() == 6, "six faces mapped")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var worst := 0.0
	for r in 6:
		for trial in 20:
			var cur := Basis(Quaternion(Vector3(rng.randf() - 0.5, rng.randf() - 0.5, rng.randf() - 0.5).normalized(),
				rng.randf() * TAU))
			var nb := DiceRoller3D.result_basis(cur, r, cam_dir, cam_up)
			var ang := rad_to_deg((nb * DiceRoller3D.FACE_NORMALS[r]).angle_to(cam_dir))
			worst = maxf(worst, ang)
			var up_ang := rad_to_deg((nb * DiceRoller3D.FACE_UPS[r]).angle_to(cam_up))
			_ok(up_ang < 20.0, "face %d plate upright (%.1f deg)" % [r, up_ang]) if trial == 0 else null
			_ok(nb.is_equal_approx(nb.orthonormalized()), "result basis stays a rotation") if trial == 0 else null
	_ok(worst < 0.5, "result face points at the camera (worst %.3f deg)" % worst)
	# nearest: a die already showing the result face keeps its orientation
	var same := DiceRoller3D.result_basis(Basis.IDENTITY.rotated(Vector3.UP, 0.0), 4, Vector3.BACK, Vector3.UP)
	_ok(same.is_equal_approx(Basis.IDENTITY), "already facing camera: no turn")

	_log.clear()
	roller.roll([], Callable())
	await get_tree().process_frame
	_ok(_log == ["all"], "empty roll still emits all_arrived once")

	_log.clear()
	var many: Array = []
	for i in 14:
		many.append({"slot_node": slot, "face_type": "heal", "value": 3, "crit": false})
	roller.roll(many, Callable())
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(_log.count("all") == 1, "one all_arrived for a capped roll")
	_ok(_log.filter(func(s: String) -> bool: return s.begins_with("a") and s != "all").size() == DiceRoller3D.MAX_DICE,
		"roll is capped at MAX_DICE (%d)" % DiceRoller3D.MAX_DICE)

	_log.clear()
	roller.roll(entries, Callable())
	roller.skip()
	_ok(not roller.is_rolling(), "skip() ends a roll at once")
	_ok(_log.back() == "all", "skip() emits all_arrived")

	# A second roll during a roll lands the first one; nothing of the old roll fires afterwards.
	_log.clear()
	roller.roll(entries, Callable())
	roller.roll(many.slice(0, 3), Callable())
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(_log.count("all") == 2, "each roll() ends with its own all_arrived (got %d)" % _log.count("all"))
	_ok(not roller.is_rolling(), "idle after a roll replaced a roll")

	# Mesh surface i+1 of axie_die.glb faces FACE_NORMALS[i] (average vertex normal per surface).
	var die_mi := DiceRoller3D.make_die_mesh(many.slice(0, 6), 0.5)
	var mesh := die_mi.mesh
	_ok(mesh.get_surface_count() == 7, "die mesh has 7 surfaces")
	for i in 6:
		var arrays := mesh.surface_get_arrays(i + 1)
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var sum := Vector3.ZERO
		for nrm in normals:
			sum += nrm
		var avg := sum.normalized()
		_ok(avg.dot(DiceRoller3D.FACE_NORMALS[i]) > 0.98,
			"surface %d (%s) faces FACE_NORMALS[%d] (dot %.3f)" % [i + 1, mesh.surface_get_material(i + 1).resource_name, i, avg.dot(DiceRoller3D.FACE_NORMALS[i])])

	die_mi.free()

	if _fails.is_empty():
		print("PASS: t_dice_roller3d (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		print("FAIL: t_dice_roller3d %d of %d" % [_fails.size(), _checks])
		get_tree().quit(1)
