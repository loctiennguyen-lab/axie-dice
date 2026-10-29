extends Node
## v4 UI item 1 (UI-05 look): part chip on every card, SET ring + SetBanner from the engine snapshot, a pop only for four / five.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

## UI-05: the SetBanners row is centred on the dock, every SET member card wears the ring in its SET colour, nobody else does.
func _check_row(v: Node, bl: BoLayer, tag: String) -> void:
	var dock: Control = v._dock_plate
	var rr := bl.row.get_global_rect()
	_check(absf(rr.get_center().x - dock.get_global_rect().get_center().x) <= 1.0, "%s: SetBanners row centred on the dock" % tag)
	_check(absf(rr.position.y - dock.get_global_rect().position.y) <= 1.0, "%s: SetBanners row is the dock's top band" % tag)
	var units: Array = v._party_dice_units()
	var c: CombatEngine = v._combat
	for i in units.size():
		var card: DieCard = (v._die_slot_content[i] as Dictionary)["card"]
		var key := SetPreview.set_key(c.bo, int(units[i].uid))
		_check(card.set_ring.visible == (key != ""), "%s: card %d ring %s vs in SET %s" % [tag, i, card.set_ring.visible, key])
		if key != "":
			var sb: StyleBoxFlat = card.set_ring.get_theme_stylebox("panel")
			_check(sb.border_color == UI3Theme.color(SetPreview.colour_token(key)), "%s: card %d ring in the SET colour" % [tag, i])
	for bnr in bl.banners():
		_check(bnr.get_global_rect().position.x >= rr.position.x - 1.0 and bnr.get_global_rect().end.x <= rr.end.x + 1.0,
			"%s: banner inside the row" % tag)
	_check(bl.banners().size() == c.bo.size(), "%s: one banner per SET (%d vs %d)" % [tag, bl.banners().size(), c.bo.size()])


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
	_check(String(labels[0]).begins_with("SET OF 3") and String(labels[0]).contains("×1.3"), "set of 3 x1.3 at default knobs: %s" % str(labels))
	_check(bl.last_banner == "", "no banner for a set of 3")
	# Anchor Gambler with a Gamble bonus: the group label must use m100_for (what each die shows), not the raw snapshot m100.
	c.anchor_id = "a_gambler"
	c.anchor_turn["gb100"] = 30
	c._snap_bo()
	v._rebuild_all()
	await get_tree().process_frame
	await get_tree().process_frame
	var raw_m := int(c.bo[0]["m100"])
	var real_m := c.m100_for(c.by_uid(int((c.bo[0]["uids"] as Array)[0])))
	_check(real_m == raw_m + 30, "Gambler gb100 raises m100_for: %d vs raw %d" % [real_m, raw_m])
	var a_labels := bl.group_labels()
	_check(a_labels[0] == V4Ui.set_label(int(c.bo[0]["size"]), real_m), "Anchor: label uses m100_for: %s" % str(a_labels))
	_check(a_labels[0] != V4Ui.set_label(int(c.bo[0]["size"]), raw_m), "Anchor: label differs from the raw snapshot m100")
	c.anchor_id = ""
	c.anchor_turn["gb100"] = 0
	c._snap_bo()
	v._rebuild_all()
	await get_tree().process_frame
	var chips := 0
	for b in v._die_slot_buttons:
		if b.visible and b.find_child("PartChip", true, false) != null:
			chips += 1
	_check(chips == units.size(), "part chip on every card: %d/%d" % [chips, units.size()])
	var any_pv := false
	for b in v._die_slot_buttons:
		var pl: Label = b.find_child("SetDelta", true, false)
		if pl != null and pl.visible and (String(pl.text).contains("→") or String(pl.text).begins_with("+")):
			any_pv = true
	_check(any_pv, "preview 'v0 -> v' shows on a die in a Set")
	# four -> banner
	for i in 4:
		units[i].set_roll(2, false)
	c._snap_bo()
	await get_tree().process_frame
	_check(bl.last_banner.begins_with("SET OF 4") and bl.banner_texts().has(bl.last_banner), "banner for four: %s" % bl.last_banner)
	for _i in 4:
		await get_tree().process_frame
	_check_row(v, bl, "four")
	units[1].set_roll(1, false)   # a die of another part in the middle splits the group: 0, 2, 3 stay one Set of 3
	c._snap_bo()
	await get_tree().process_frame
	await get_tree().process_frame
	_check_row(v, bl, "split")
	units[1].set_roll(2, false)
	c._snap_bo()
	await get_tree().process_frame
	var logged := false
	for ln in v._log_lines:
		if String(ln).begins_with("[set]"):
			logged = true
	_check(logged, "a [set] line reached the battle log")
	var words := 0
	if v._row_strip != null:
		for ch in v._row_strip.get_children():
			if ch is Label and ch.visible:
				words += 1
	_check(words >= 1, "UI-05: FRONT/BACK words stay visible while a Set is on the tray (banners have their own row)")
	print("=== t_v4ui_bo: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	_guard.restore()
	if _fails.is_empty():
		print("t_v4ui_bo: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_v4ui_bo: FAIL - %s" % f)
	get_tree().quit(1)
