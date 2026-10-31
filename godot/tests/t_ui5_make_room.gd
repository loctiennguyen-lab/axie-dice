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
	for n in ["MakeRoomSheet", "Title", "Line", "OwnedList", "SellRow", "CoreSlot", "TierChip", "SellButton", "Footer", "BackButton", "ConfirmButton"]:
		_ok(sheet.find_child(n, true, false) != null, "%s: node %s" % [tag, n])
	var conf := sheet.find_child("ConfirmButton", true, false) as Button
	_ok(conf.disabled and conf.text == "Pick one to sell", tag + ": confirm off, says why")
	for b in sheet.find_children("SellButton", "Button", true, false):
		_ok(not (b as Button).button_pressed, tag + ": nothing preselected")
	_ok(get_viewport().gui_get_focus_owner() == sheet.find_child("BackButton", true, false), tag + ": initial focus on Back")
	_ok(Align.pairs(sheet) > 0, tag + ": align pairs measured")
	_ok(Align.check(sheet).is_empty(), tag + ": icon/label centred %s" % str(Align.check(sheet)))
	_small(sheet, tag, sc)
	var pick: Button = null
	for b in sheet.find_children("SellButton", "Button", true, false):
		if String((b as Button).get_meta("relic_id")) == "r_claw":
			pick = b
	pick.pressed.emit()
	_ok(not conf.disabled, tag + ": pick enables confirm")
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
	ban.queue_free()
	layer.queue_free()
	UI3Gacha.instant_override = -1
	await _frames(2)
