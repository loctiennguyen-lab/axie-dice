extends Node
## UI-05 b23 lane R4: MakeRoomSheet + ComboBand against 47-core-offer--make-room / --combo-banner (1920 + 1280).
const Align := preload("res://tests/ui5_align_check.gd")
var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _frames(n := 4) -> void:
	for _i in n:
		await get_tree().process_frame


func _small(root: Node, tag: String, sc: float) -> void:
	var bad := []
	for n in root.find_children("*", "", true, false):
		if n is Label and (n as Label).is_visible_in_tree() and (n as Label).text != "" \
				and float((n as Label).get_theme_font_size("font_size")) * sc < 13.99:
			bad.append((n as Label).text)
		elif n is Button and (n as Button).is_visible_in_tree() and (n as Button).text != "" \
				and float((n as Button).get_theme_font_size("font_size")) * sc < 13.99:
			bad.append((n as Button).text)
	_ok(bad.is_empty(), "%s: text >= 14 real px (%s)" % [tag, str(bad)])


func _ready() -> void:
	print("=== t_ui5_make_room: start ===")
	_guard.capture()
	await _frames(1)
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(797, team, "short", 0, false)
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _room(sc)
		await _core_room(sc)
		await _band(sc)
	UI3Theme.set_scale_override(1.0)
	_guard.restore()
	print("=== t_ui5_make_room: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_make_room: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)


func _room(sc: float) -> void:
	var tag := "room %.2f" % sc
	var full := ["r_claw", "r_carapace", "r_pierceall", "r_cleaveall", "r_bloodmouth", "r_gorehook", "r_barbedhide", "r_heart"]
	RunState.owned_relic_ids.assign(full)
	RunState.relic_stickers = {"r_heart": "eternal"}
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	await _frames(6)
	RunState.pending_rewards = [{"t": "relic", "key": "r_seedling", "rar": 0, "title": "RELIC", "desc": "Seedling", "sub": ""}]
	m.call("_show_reward_overlay", "CHOOSE A REWARD")
	await _frames(2)
	m.call("_take_selected_reward")
	await _frames(4)
	var sheet := m.find_child("SlotSwapSheet", true, false)
	_ok(sheet != null, tag + ": sheet opens")
	if sheet == null:
		m.queue_free()
		return
	for n in ["MakeRoomSheet", "Title", "Line", "OwnedList", "SellRow", "CoreSlot", "TierChip", "SellButton", "Footer", "BackButton"]:
		_ok(sheet.find_child(n, true, false) != null, "%s: node %s" % [tag, n])
	_ok(sheet.find_child("ConfirmButton", true, false) == null, tag + ": no ConfirmButton (frame has none)")
	for b in sheet.find_children("SellButton", "Button", true, false):
		var et := String(RunState.relic_stickers.get(String((b as Button).get_meta("relic_id")), "")) == "eternal"
		_ok((b as Button).disabled == et, tag + ": SellButton enabled unless Eternal (%s)" % (b as Button).text)
		if not et:
			_ok((b as Button).icon_alignment == HORIZONTAL_ALIGNMENT_RIGHT, tag + ": shard icon after the text")
	_ok(get_viewport().gui_get_focus_owner() == sheet.find_child("BackButton", true, false), tag + ": initial focus on Back")
	_ok(Align.pairs(sheet) > 0, tag + ": align pairs measured")
	_ok(Align.check(sheet).is_empty(), tag + ": icon/label centred %s" % str(Align.check(sheet)))
	_small(sheet, tag, sc)
	var pick: Button = null
	for b in sheet.find_children("SellButton", "Button", true, false):
		if String((b as Button).get_meta("relic_id")) == "r_claw":
			pick = b
	var shards0 := RunState.shards_this_run
	pick.pressed.emit()
	pick.pressed.emit()
	await _frames(2)
	_ok(RunState.owned_relic_ids.has("r_seedling") and not RunState.owned_relic_ids.has("r_claw"), tag + ": Sell took the new Core, sold r_claw")
	_ok(RunState.shards_this_run == shards0 + RelicSlots.sell_price("r_claw", RunState.ascension), tag + ": sale paid")
	await _frames(1)
	m.queue_free()
	await _frames(2)


func _band(sc: float) -> void:
	var tag := "band %.2f" % sc
	UI3Gacha.instant_override = 0
	var layer := CanvasLayer.new()
	add_child(layer)
	var cid := ""
	for r in CoreCombos.all():
		cid = String(r.get("id", ""))
		if AnchorAdapter.house_of_combo(cid) != "":
			break
	var house := AnchorAdapter.house_of_combo(cid)
	var ban := preload("res://scenes/run_map/ui5/ComboBand.gd").build(layer, "full", UI3Gacha.combo_name(cid), house, house != "")
	await _frames(4)
	for n in ["ComboBanner", "ComboTag", "ComboName", "ContinueHint"] + (["MutationBox"] if house != "" else []):
		_ok(ban.name == n or ban.find_child(n, true, false) != null, "%s: node %s" % [tag, n])
	_ok((ban.find_child("ComboWord", true, false) as Label).text == "FULL", tag + ": FULL tag")
	_ok((ban.find_child("ComboName", true, false) as Label).text == UI3Gacha.combo_name(cid), tag + ": combo name from data")
	_ok(ban.running, tag + ": waits for click (no timer)")
	_ok(Align.pairs(ban) > 0, tag + ": align pairs measured")
	_ok(Align.check(ban).is_empty(), tag + ": icon/label centred %s" % str(Align.check(ban)))
	_small(ban, tag, sc)
	var rl := ban.find_child("MutationRule", true, false) as Label
	if rl != null:
		_ok(rl.get_line_count() == 1, tag + ": MutationRule on one line (%d)" % rl.get_line_count())
	_ok(ban.find_child("Band", true, false).find_child("ContinueHint", true, false) != null, tag + ": ContinueHint inside the band")
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(3)
	_ok(not is_instance_valid(ban), tag + ": Space dismisses")
	ban = preload("res://scenes/run_map/ui5/ComboBand.gd").build(layer, "pair", UI3Gacha.combo_name(cid), house, house != "")
	await _frames(2)
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	mb.position = Vector2(100, 100)
	Input.parse_input_event(mb)
	await _frames(3)
	_ok(not is_instance_valid(ban), tag + ": click dismisses")
	layer.queue_free()
	UI3Gacha.instant_override = -1
	await _frames(2)


## A real Core with the 6 Core slots full: title and line say "6 of 6" / "All 6 Core slots full" (frame make-room).
func _core_room(sc: float) -> void:
	var tag := "core room %.2f" % sc
	var ids: Array[String] = []
	for f in DirAccess.get_files_at("res://resources/relics"):
		if f.begins_with("c_") and f.ends_with(".tres"):
			var id := f.get_basename()
			var d = RelicRegistry.get_def(id)
			if d != null and String(d.core_axis) != "" and String(d.core_axis) != "run_rule":
				ids.append(id)
	var m_slots := RelicSlots.tuning().core_slots
	_ok(ids.size() > m_slots, tag + ": enough Cores for the fixture")
	if ids.size() <= m_slots:
		return
	RunState.owned_relic_ids.assign(ids.slice(0, m_slots))
	RunState.relic_stickers = {}
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	await _frames(6)
	var nk := ids[m_slots]
	RunState.pending_rewards = [{"t": "relic", "key": nk, "rar": 0, "title": "RELIC", "desc": "x", "sub": ""}]
	m.call("_show_reward_overlay", "CHOOSE A REWARD")
	await _frames(2)
	m.call("_take_selected_reward")
	await _frames(4)
	var sheet := m.find_child("SlotSwapSheet", true, false)
	_ok(sheet != null, tag + ": sheet opens for a full Core bar")
	if sheet != null:
		var tt := (sheet.find_child("Title", true, false) as Label).text
		var ln := (sheet.find_child("Line", true, false) as Label).text
		_ok(tt.contains("%d of %d" % [m_slots, m_slots]), tag + ": title says N of M (%s)" % tt)
		_ok(ln.begins_with("All %d Core slots full" % m_slots), tag + ": line says All M Core slots full (%s)" % ln)
		_ok(sheet.find_children("SellRow*", "", true, false).size() == m_slots, tag + ": one row per owned Core (%d)" % sheet.find_children("SellRow*", "", true, false).size())
	m.queue_free()
	await _frames(2)
