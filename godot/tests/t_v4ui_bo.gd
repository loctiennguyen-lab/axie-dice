extends Node
## v4 UI item 1: part chip on every card, Set frame + label from the engine snapshot, banner only for four / five.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

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
	for i in range(3, units.size()):
		units[i].set_roll(1 if i == 3 else 4, false)   # different parts for the rest
	c._snap_bo()
	v._rebuild_all()
	await get_tree().process_frame
	var bl: BoLayer = v._bo_layer
	_check(bl != null, "BoLayer exists")
	var labels := bl.group_labels()
	_check(labels.size() >= 1 and labels[0] == V4Ui.set_label(int(c.bo[0]["size"]), int(c.bo[0]["m100"])), "label from engine: %s" % str(labels))
	_check(String(labels[0]).begins_with("SET OF 3") and String(labels[0]).contains("×1.4"), "set of 3 x1.4 at default knobs: %s" % str(labels))
	_check(bl.last_banner == "", "no banner for a set of 3")
	var chips := 0
	for b in v._die_slot_buttons:
		if b.visible and b.find_child("PartChip", true, false) != null:
			chips += 1
	_check(chips == units.size(), "part chip on every card: %d/%d" % [chips, units.size()])
	var any_pv := false
	for b in v._die_slot_buttons:
		var pl: Label = b.find_child("SetPreview", true, false)
		if pl != null and pl.visible and String(pl.text).contains("→"):
			any_pv = true
	_check(any_pv, "preview 'v0 -> v' shows on a die in a Set")
	# four -> banner
	for i in 4:
		units[i].set_roll(2, false)
	c._snap_bo()
	await get_tree().process_frame
	_check(bl.last_banner.begins_with("FOUR"), "banner for four: %s" % bl.last_banner)
	var logged := false
	for ln in v._log_lines:
		if String(ln).begins_with("[set]"):
			logged = true
	_check(logged, "a [set] line reached the battle log")
	var words_hidden := true
	if v._row_strip != null:
		for ch in v._row_strip.get_children():
			if ch is Label and ch.visible:
				words_hidden = false
	_check(words_hidden, "FRONT/BACK words hidden while a Set is on the tray")
	print("=== t_v4ui_bo: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	_guard.restore()
	if _fails.is_empty():
		print("t_v4ui_bo: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_v4ui_bo: FAIL - %s" % f)
	get_tree().quit(1)
