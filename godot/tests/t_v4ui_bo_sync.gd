extends Node
## v4 UI review item 1: the SET label and the banner always match the engine's CURRENT Set, after a reroll,
## a wild face or any other change. A banner whose Set is gone is cut at once.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _engine_labels(c: CombatEngine) -> Array[String]:
	var out: Array[String] = []
	for g in c.bo:
		out.append(V4Ui.set_label(int(g["size"]), int(g["m100"])))
	return out

func _in_sync(v: Node, what: String) -> void:
	var bl: BoLayer = v._bo_layer
	var c: CombatEngine = v._combat
	_check(bl.group_labels() == _engine_labels(c), "%s: labels %s vs engine %s" % [what, str(bl.group_labels()), str(_engine_labels(c))])
	if bl._banner != null and bl._banner.visible:
		var ok := false
		for g in c.bo:
			if V4Ui.banner_text(int(g["part"]), int(g["size"]), int(g["m100"])) == bl._banner.text:
				ok = true
		_check(ok, "%s: banner '%s' is not a current Set" % [what, bl._banner.text])

func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	await get_tree().process_frame
	RunState.enter_node("r1_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 60:
		await get_tree().process_frame
	v._land_dice_now()
	var c: CombatEngine = v._combat
	var units: Array = v._party_dice_units()
	for u in units:
		u.set_roll(2, false)
	units[4].set_roll(4, false)
	c._snap_bo()
	await get_tree().process_frame
	_in_sync(v, "four")
	var bl: BoLayer = v._bo_layer
	_check(bl.last_banner.begins_with("FOUR") and bl._banner.visible, "four shows its banner")
	# a reroll breaks the four into three: the banner must go with it, in the same frame
	units[3].set_roll(1, false)
	c._snap_bo()
	_in_sync(v, "four -> three")
	_check(not bl._banner.visible, "banner cut when the four is gone")
	_check(bl.group_labels().size() == 1 and String(bl.group_labels()[0]).begins_with("SET OF 3"), "label says three: %s" % str(bl.group_labels()))
	# back to four: announced again
	units[3].set_roll(2, false)
	c._snap_bo()
	_in_sync(v, "three -> four")
	_check(bl._banner.visible, "banner again for the new four")
	# the Set vanishes completely
	units[0].set_roll(1, false)
	units[1].set_roll(3, false)
	c._snap_bo()
	_in_sync(v, "no set")
	_check(bl.group_labels().is_empty() and not bl._banner.visible, "no label and no banner without a Set")
	# a layout pass (tray rebuild) never leaves a stale banner either
	units[0].set_roll(2, false)
	units[1].set_roll(2, false)
	c._snap_bo()
	units[1].set_roll(3, false)
	v._rebuild_all()
	_in_sync(v, "rebuild")
	print("=== t_v4ui_bo_sync: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	_guard.restore()
	if _fails.is_empty():
		print("t_v4ui_bo_sync: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_v4ui_bo_sync: FAIL - %s" % f)
	get_tree().quit(1)
