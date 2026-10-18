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

	if _fails.is_empty():
		print("PASS: t_dice_roller3d (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		print("FAIL: t_dice_roller3d %d of %d" % [_fails.size(), _checks])
		get_tree().quit(1)
