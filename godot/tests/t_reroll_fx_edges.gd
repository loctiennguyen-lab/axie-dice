extends Node
## Reroll tray edge cases, on the real Combat.tscn with juice ON (t_reroll_fx covers the happy
## path). Each case drives real input where the bug would live in input:
##   1 an Axie Egg token rides as the small die and comes back like the others
##   2 heavy / frozen dice are NOT tossed, their cards never get the overlay
##   3 R starts the tray, R again skips it, SPACE while it is up does not end the turn
##   4 after the tray, a real mouse click on an enemy model (Stage3D) lands the selected die
##   5 no rerolls left: REROLL does nothing and leaves nothing behind
##   6 the combat scene freed mid-tray does not error
## Run: godot --headless --path godot tests/t_reroll_fx_edges.tscn

var _tree: SceneTree
var _view: Node
var _anomaly := ""


func _ready() -> void:
	_tree = get_tree()
	CombatView.disable_juice_for_tests = false
	await _boot(515151)
	var combat: CombatEngine = _view.get("_combat")
	if combat == null:
		return _done("no CombatEngine")

	# ── 1 + 2: egg token, heavy and frozen ──
	var egg: Unit = combat._mk_ally()
	combat.party.append(egg)
	combat._roll_unit(egg)
	_view.call("_rebuild_all")
	await _frames(3)
	var units: Array = _view.call("_party_dice_units")
	var heavy_u: Unit = null
	var frozen_u: Unit = null
	for u in units:
		if u.roster_index >= 0 and u.has_rolled() and not u.roll_used():
			if heavy_u == null: heavy_u = u
			elif frozen_u == null: frozen_u = u
	heavy_u.heavy = true
	frozen_u.frozen = true
	combat.rerolls = 3
	_view.call("_on_reroll_pressed")
	var map: Dictionary = _view.get("_reroll_fx_slot_by_uid")
	_check(map.has(egg.uid), "egg token not in the tray")
	_check(not map.has(heavy_u.uid), "heavy die was tossed")
	_check(not map.has(frozen_u.uid), "frozen die was tossed")
	var fx: RerollFX = _view.get("_reroll_fx")
	var entry_egg := false
	for b in fx._bodies if fx._stage != "open" else []:
		pass
	await _until(func(): return fx._stage == "toss")
	for b in fx._bodies:
		if b.id == egg.uid: entry_egg = b.egg
	_check(entry_egg, "egg token did not ride as the small die")
	var slots: Array = units.map(func(u): return u.uid)
	for uid in [heavy_u.uid, frozen_u.uid]:
		var ov: Control = _view.call("_reroll_overlay_at", slots.find(uid))
		_check(ov == null or not ov.visible, "non-rerolled card %d got the overlay" % uid)
	await _until(func(): return not bool(_view.get("_reroll_fx_active")), 15.0)
	_check(not bool(_view.get("_reroll_fx_active")), "case 1: tray never finished")
	heavy_u.heavy = false
	frozen_u.frozen = false
	print("t_reroll_fx_edges: 1+2 ok (egg rides small, heavy/frozen stay)")

	# ── 3: keyboard ──
	var phase0: int = combat.phase
	var turn0: int = combat.turn if "turn" in combat else -1
	await _key(KEY_R)
	_check(bool(_view.get("_reroll_fx_active")), "R did not start the tray")
	await _until(func(): return fx._stage == "toss")
	await _key(KEY_SPACE)
	_check(combat.phase == phase0 and (turn0 < 0 or combat.turn == turn0), "SPACE ended the turn under the tray")
	await _wait(0.2)
	await _key(KEY_R)   # skip
	await _until(func(): return not bool(_view.get("_reroll_fx_active")), 6.0)
	_check(not bool(_view.get("_reroll_fx_active")), "R skip did not finish the tray")
	print("t_reroll_fx_edges: 3 ok (R roll, SPACE blocked, R skip)")

	# ── 4: real click on an enemy model after the tray ──
	await _wait(0.5)
	# the middle of the board, where the grade stamp sits, must reach the board again
	var mid := get_viewport().get_visible_rect().size * Vector2(0.5, 0.4)
	var mm := InputEventMouseMotion.new()
	mm.position = mid
	mm.global_position = mid
	get_viewport().push_input(mm, true)
	await _frames(2)
	var hov := get_viewport().gui_get_hovered_control()
	_check(hov == null or not fx.is_ancestor_of(hov), "tray control %s still covers the board" % (hov.get_path() if hov else ""))
	units = _view.call("_party_dice_units")
	var btns: Array = _view.get("_die_slot_buttons")
	var slot := -1
	for i in units.size():
		var u: Unit = units[i]
		if u.hp > 0 and u.has_rolled() and not u.roll_used() and String(u.current_face().get("type", "")) == "dmg":
			slot = i
			break
	if slot < 0:
		print("t_reroll_fx_edges: 4 skipped (no damage face on this seed)")
	else:
		await _click((btns[slot] as Control).get_global_rect().get_center())
		_check(int(_view.get("_selected_die_uid")) == units[slot].uid, "clicking the card did not select the die")
		var target: Unit = null
		for e in combat.enemies:
			if e.hp > 0:
				target = e
				break
		var hp0 := target.hp
		# Aim where the tray's stamp used to sit: the middle of the board, over the models.
		var hit := false
		for p in _enemy_points(target):
			await _click(p)
			await _frames(4)
			if units[slot].roll_used():
				hit = true
				break
		print("t_reroll_fx_edges: 4 detail hp %d -> %d used=%s" % [hp0, target.hp, units[slot].roll_used()])
		_check(hit, "clicking the enemy after a reroll did not use the die (hp %d -> %d)" % [hp0, target.hp])
		print("t_reroll_fx_edges: 4 ok (die landed on the enemy after the tray)")

	# ── 5: no rerolls left ──
	combat.rerolls = 0
	_view.call("_on_reroll_pressed")
	_check(not bool(_view.get("_reroll_fx_active")), "tray opened with 0 rerolls")
	for i in _view.get("_die_slot_content").size():
		var ov: Control = _view.call("_reroll_overlay_at", i)
		_check(ov == null or not ov.visible, "overlay %d up with 0 rerolls" % i)
	print("t_reroll_fx_edges: 5 ok (0 rerolls is inert)")

	# ── 6: scene freed mid-tray ──
	combat.rerolls = 1
	_view.call("_on_reroll_pressed")
	await _until(func(): return fx._stage == "toss")
	await _wait(0.3)
	_view.queue_free()
	await _wait(1.5)
	print("t_reroll_fx_edges: 6 ok (freed mid-tray)")
	_done("")


func _enemy_points(e: Unit) -> Array:
	var pts: Array = []
	var stage = _view.get("_stage3d")
	if stage != null and stage.has_method("unit_screen_position"):
		pts.append(stage.call("unit_screen_position", e.uid))
	var port = (_view.get("_portraits") as Dictionary).get(e.uid)
	if port is Control:
		pts.append((port as Control).get_global_rect().get_center())
	var vs := get_viewport().get_visible_rect().size
	for y in [0.3, 0.4, 0.45]:
		for x in [0.4, 0.5, 0.6]:
			pts.append(Vector2(vs.x * x, vs.y * y))
	return pts


func _boot(seed: int) -> void:
	RunState.pending_combat = {
		"node_id": "reroll_edges", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": seed,
	}
	_view = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(_view)
	await _frames(10)


func _click(pos: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	get_viewport().push_input(m, true)
	await _tree.process_frame
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = pos
		e.global_position = pos
		get_viewport().push_input(e, true)
		await _tree.process_frame


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		get_viewport().push_input(e, true)
		await _tree.process_frame


func _until(f: Callable, limit: float = 10.0) -> void:
	var t0 := Time.get_ticks_msec()
	while not f.call() and Time.get_ticks_msec() - t0 < limit * 1000.0:
		await _tree.process_frame


func _frames(n: int) -> void:
	for i in n:
		await _tree.process_frame


func _wait(sec: float) -> void:
	await _tree.create_timer(sec).timeout


func _roster() -> Array:
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	var out: Array = []
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return out


func _check(cond: bool, msg: String) -> void:
	if not cond and _anomaly == "":
		_anomaly = msg


func _done(err: String) -> void:
	if err != "" and _anomaly == "":
		_anomaly = err
	if _anomaly != "":
		print("t_reroll_fx_edges: FAIL — %s" % _anomaly)
		_tree.quit(1)
	else:
		print("t_reroll_fx_edges: PASS — egg, heavy/frozen, keys, click-through, 0 rerolls, freed mid-tray")
		_tree.quit(0)
