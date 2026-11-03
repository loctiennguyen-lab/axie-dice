extends Node
## Polish 3/11 lane P2 regression checks: #2 room sentence, #6 long boss name wraps, #7 shop long sell name keeps its price,
## #14 old relic rows carry a headline + scroll bar, #22 "Take <name>" once a card is picked.
const MakeRoomSheet := preload("res://scenes/run_map/ui5/MakeRoomSheet.gd")
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


func _ready() -> void:
	print("=== t_polish_p2: start ===")
	_guard.capture()
	await _frames(1)
	# #2: one sentence, two words, never "Passive ... (9 of 8)"
	var l1 := MakeRoomSheet.room_line(true, 6, 6, "Fossil")
	_ok(l1 == "Cores: 6 of 6. Sell one to take Fossil", "core line: " + l1)
	var l2 := MakeRoomSheet.room_line(false, 8, 8, "Brittle Dice")
	_ok(l2 == "Relics: 8 of 8. Sell one to take Brittle Dice", "relic line: " + l2)
	_ok(not MakeRoomSheet.room_line(false, -1, 0, "X").contains("Passive"), "no Passive wording")
	var team: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	RunState.start_new_run(797, team, "short", 0, false)
	for sc in [1.0, 2.0 / 3.0]:
		UI3Theme.set_scale_override(sc)
		await _map_and_shop(sc)
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	print("=== t_polish_p2: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_polish_p2: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("FAIL: " + f)
		get_tree().quit(1)


func _map_and_shop(sc: float) -> void:
	var tag := "scale %.2f" % sc
	RunState.owned_relic_ids.assign(["c_bastion", "c_backline_glow", "r_ironvow"])
	var m: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(m)
	await _frames(6)
	# #14: every OwnedCore row has name + headline, list scrolls with a visible bar
	var rows := (m.find_child("OwnedList", true, false) as Control).get_children()
	_ok(rows.size() == 3, "%s: 3 owned rows (%d)" % [tag, rows.size()])
	for r in rows:
		_ok(r.find_child("CoreName", true, false) != null and r.find_child("Headline", true, false) != null and r.find_child("CoreSlot", true, false) != null,
			"%s: row has socket, name, headline" % tag)
	var sl := m.find_child("OwnedList", true, false)
	if sl != null:
		_ok((sl.get_parent() as ScrollContainer).vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_ALWAYS, "%s: scroll bar always shown" % tag)
	# #6: boss captions wrap (no clip), two lines tall
	var seen_boss := false
	for v in (m.get("_node_visuals") as Dictionary).values():
		var nd = v["node"]
		var cp = v["caption"]
		if cp != null and nd.node_type == "boss":
			seen_boss = true
			_ok((cp as Label).autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and not (cp as Label).clip_text and (cp as Label).size.y >= 50.0, "%s: boss caption wraps, 2 lines tall" % tag)
	# #7: long name in the Sell column keeps its price inside the button
	var long_def = RelicRegistry.get_def("r_ironvow")
	var old_name = long_def.name
	long_def.name = "Extremely Long Contract Of The Lone Wolf"
	RunState.shards_this_run = 100
	m.call("_render_shop")
	await _frames(4)
	for sb in m.find_children("SellButton", "Button", true, false):
		var pl := sb.find_child("SellPrice", true, false) as Label
		var nl := sb.find_child("SellName", true, false) as Label
		_ok(pl != null and pl.get_global_rect().end.x <= (sb as Button).get_global_rect().end.x + 0.5, "%s: price inside button" % tag)
		_ok(nl != null and nl.size.x > 20.0, "%s: name keeps some room" % tag)
		if nl != null and String((sb as Button).get_meta("relic_id")) == "r_ironvow":
			_ok(Ui5Ellipsis.full_text(nl).begins_with("Extremely") and nl.text.ends_with("…"), "%s: long name ends in an ellipsis (%s)" % [tag, nl.text])
	long_def.name = old_name
	# #22: Take caption
	RunState.pending_rewards = [{"t": "relic", "key": "c_bastion", "rar": 0, "tier": 0, "axis": "stat", "title": "CORE", "desc": "Bastion", "sub": ""}]
	m.call("_show_reward_overlay", "CHOOSE A CORE")
	await _frames(3)
	var tb := m.find_child("TakeButton", true, false) as Button
	if tb != null:
		_ok(tb.text.begins_with("Pick") or tb.text.begins_with("Reveal"), "%s: Take says Pick/Reveal before a pick (%s)" % [tag, tb.text])
	_ok(String(m.get("_offers").take_caption(0)) == "Take Bastion", "%s: caption names the card (%s)" % [tag, m.get("_offers").take_caption(0)])
	m.queue_free()
	await _frames(2)
