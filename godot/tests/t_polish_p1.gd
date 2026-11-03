extends Node
## Polish 3/11 lane P1 (combat): #5 tool keys say why, #16 egg die + enrage chip, #17 status row clamp, #18 tier gem size.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []


func _ok(c: bool, m: String) -> void:
	_checks += 1
	if not c:
		_fails.append(m)


func _ready() -> void:
	_guard.capture()
	CombatView.disable_juice_for_tests = true
	await get_tree().process_frame
	UI3Theme.set_scale_override(1.0)
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 0, false)
	RunState.owned_relic_ids.append("c_bastion")
	# #18: the tier gem is >= 12 real px at 1280 (scale 2/3)
	UI3Theme.set_scale_override(2.0 / 3.0)
	var host := Control.new()
	host.theme = UI3Theme.get_theme()
	add_child(host)
	var p := CorePanel.new()
	host.add_child(p)
	p.refresh()
	for _i in 4:
		await get_tree().process_frame
	var gem := p.find_child("TierShards*", true, false) as Control
	_ok(gem != null, "#18 gem exists")
	if gem != null:
		_ok(gem.custom_minimum_size.y * (2.0 / 3.0) >= 12.0, "#18 gem >= 12 px at 1280 (%.1f)" % (gem.custom_minimum_size.y * 2.0 / 3.0))
	host.queue_free()
	UI3Theme.set_scale_override(1.0)
	# #17: a row anchored above the top edge stays inside
	var sh := StatusHeads.new()
	sh.size = Vector2(1280, 720)
	add_child(sh)
	sh.sync([{"uid": 1, "anchor": Vector2(600, -30), "shield": 0, "status": {"poison": 3, "weaken": 2}}])
	var row := sh._rows[1]["row"] as Control
	_ok(row.position.y >= 0.0, "#17 status row y >= 0 (%.1f)" % row.position.y)
	# #5 / #16: real combat
	RunState.pending_combat = {"node_id": "p1", "kind": "battle", "pw": 4, "ascension": 0,
		"roster_snapshot": RunState.roster.duplicate(true), "relic_ids": [], "combat_seed": 77}
	var view: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(view)
	for _i in 8:
		await get_tree().process_frame
	view._combat.mana = 0
	view._rebuild_all()
	var hud: CombatHud = view._hud_frame
	var undo := hud.find_child("UndoKey", true, false) as Ui5ToolKey
	var hold := hud.find_child("HoldKey", true, false) as Ui5ToolKey
	_ok(undo.button.disabled and undo.reason_text() != "", "#5 disabled Undo has a reason")
	_ok(hold.button.disabled and hold.reason_text().begins_with("Hold"), "#5 disabled Hold reason: %s" % hold.reason_text())
	_ok(hold.reason_text() == hold.button.text, "#5 reason = button state text")
	hud._reason_show(undo, false)
	_ok(hud._hint.text == undo.reason_text(), "#5 StatusLine shows the reason (%s)" % hud._hint.text)
	hud._reason_key = null
	hud._reason_until_ms = 0
	hud.update_right_hint_refresh()
	_ok(hud._hint.text != undo.reason_text(), "#5 reason clears")
	# #16: a summoned Egg (roster_index < 0) gets is_egg and no part chip
	var eu = view._combat.party[0]
	var saved_ri: int = eu.roster_index
	eu.roster_index = -1
	var ed: Dictionary = view._v4_card_data(eu)
	eu.roster_index = saved_ri
	_ok(bool(ed.get("is_egg", false)) and String(ed["part_text"]) == "", "#16 egg card: is_egg, no part chip")
	_ok(not bool(view._v4_card_data(eu).get("is_egg", false)), "#16 hero card is not an egg")
	# #4: motes land, then the burst hook fires once
	CombatView.disable_juice_for_tests = false
	var got: Array = []
	var cp := CorePanel.new()
	add_child(cp)
	cp.refresh()
	var fx := CoreFireFX.new().setup(cp, func(_u: int) -> Vector2: return Vector2(900, 500))
	fx.burst = func(uid: int, kind: String, anc: bool) -> void: got.append([uid, kind, anc])
	add_child(fx)
	fx.fire("c_bastion", 1, 3, "shield")
	await get_tree().create_timer(0.8).timeout
	_ok(got.size() == 1 and got[0][1] == "shield", "#4 burst fires once after the motes land (%s)" % str(got))
	# FX target = the unit with that uid (same unit the float note stands beside): near its own head anchor, nearest of all
	var xf: Transform2D = view._unit_visuals_root.get_global_transform()
	var units: Array = view._party_dice_units()
	_ok(units.size() >= 2, "#4 target: at least 2 party units")
	for u in units:
		var fp: Vector2 = view._core_fx_unit_pos(int(u.uid))
		var raw: Vector2 = view._status_head_anchor(int(u.uid), true, view._stage3d.position)
		if raw.x < 0.0:   # headless: the 3D stage projects nothing, so both must agree on "not on screen"
			_ok(fp.x < 0.0, "#4 headless: no head anchor -> no FX target")
			continue
		var hd: Vector2 = xf * raw
		_ok(absf(fp.x - hd.x) < 40.0 and fp.y > hd.y and fp.y - hd.y < 160.0, "#4 target of uid %d sits on its own body (%s vs head %s)" % [u.uid, fp, hd])
		for o in units:
			if o != u:
				var oh: Vector2 = xf * view._status_head_anchor(int(o.uid), true, view._stage3d.position)
				_ok(fp.distance_to(hd) < fp.distance_to(oh), "#4 target of uid %d is nearer to itself than to uid %d" % [u.uid, o.uid])
	view.queue_free()
	_guard.restore()
	if _fails.is_empty():
		print("t_polish_p1: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_polish_p1: FAIL — %s" % f)
		get_tree().quit(1)
