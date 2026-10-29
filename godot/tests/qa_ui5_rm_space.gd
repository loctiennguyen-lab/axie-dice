extends Node
## QA-only (UI-05 b1 QA, item 5): Reduce motion + Space in a real boss fight (Combat.tscn, juice on, not headless).
##  1. Boss band and the first Your turn band: one Space press each (also during the band's warm-up frames) must
##     only skip the band, never end the turn.
##  2. Hits under Reduce motion: Engine.time_scale never drops (no hit-stop), no 2D/3D particles, the 3D stage
##     never moves (no shake). Same scene with QA_RM=0 gives the comparison numbers.
##  3. Each new player turn: frames between the phase flip and the Your turn band, and whether End turn was live in
##     that gap (a Space press there would end the new turn unseen); then one Space press N frames after the
##     flip (N = 0,1,2,3,5,8,13), turn must not end while a band is up.
##   QA_RM=1 godot/tools/shot.sh res://tests/qa_ui5_rm_space.tscn 1920x1080      -> prints QA_RM_RESULT {...}

const U := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()
var _v: CombatView
var _c: CombatEngine
var _rm := true
var _out := {"band": [], "hits": {}, "turns": []}


func _ready() -> void:
	_guard.capture()
	_rm = OS.get_environment("QA_RM") != "0"
	MetaState.reduce_motion = _rm
	MetaState.runs = 10
	MetaState.runs_with_battle = 99
	MetaState.runs_completed = 10
	RunState.start_new_run(424242, RunBot.DEFAULT_TEAM, "short", 0, false)
	await get_tree().process_frame
	RunState.power_level = 9
	RunState.enter_node("r12_c0", "boss")
	_v = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(_v)
	await get_tree().process_frame
	await get_tree().process_frame
	_c = _v._combat
	for u in _c.party:   # QA only: the party must live through the trials
		u.max_hp = 999
		u.hp = 999
	await _band_trials()
	await _hit_probe()
	for off in [0, 1, 2, 3, 5, 8, 13]:
		if _c.won or _c.lost:
			break
		await _turn_trial(off)
	_out["reduce_motion"] = _rm
	print("QA_RM_RESULT %s" % JSON.stringify(_out))
	_guard.restore()
	get_tree().quit(0)


func _root() -> Node:
	return _v.get_node_or_null("Ui5Moments/Root")


func _find(cls: String) -> Node:
	var r := _root()
	if r == null:
		return null
	for ch in r.get_children():
		if cls == "boss" and ch is U5BossBand and (ch as U5BossBand).showing():
			return ch
		if cls == "turn" and ch is U5TurnBanner and (ch as CanvasItem).visible and not (ch as U5TurnBanner).run.done:
			return ch
	return null


func _space() -> void:
	var e := InputEventKey.new()
	e.keycode = KEY_SPACE
	e.physical_keycode = KEY_SPACE
	e.pressed = true
	Input.parse_input_event(e)
	var e2 := e.duplicate() as InputEventKey
	e2.pressed = false
	Input.parse_input_event(e2)


func _state() -> Dictionary:
	return {"turn": _c.turn, "phase": _c.phase, "end_live": not _v._end_turn_button.disabled}


func _band_trials() -> void:
	# Boss band: press once in its first frames (warm-up) and once mid-hold, on two runs of the band? One band per
	# fight, so: first press right when it exists.
	for _i in 600:
		await get_tree().process_frame
		if _find("boss") != null:
			break
	var b := _find("boss")
	var rec := {"boss_band_seen": b != null}
	if b != null:
		var before := _state()
		U.save(get_viewport(), "rm%d--boss-band" % int(_rm))
		_space()
		for _i in 3:
			await get_tree().process_frame
		var after := _state()
		rec["boss_press"] = {"before": before, "after": after, "band_still_up": _find("boss") != null}
	# Then the Your turn band that follows the boss band.
	for _i in 300:
		await get_tree().process_frame
		if _find("turn") != null:
			break
	var t := _find("turn")
	rec["turn_band_seen"] = t != null
	if t != null:
		var before2 := _state()
		U.save(get_viewport(), "rm%d--your-turn-after-boss" % int(_rm))
		_space()
		for _i in 30:
			await get_tree().process_frame
		rec["turn_press"] = {"before": before2, "after": _state(), "band_still_up": _find("turn") != null}
	(_out["band"] as Array).append(rec)
	await _settle()


func _settle() -> void:
	for _i in 600:
		await get_tree().process_frame
		if not _v._is_animating and not _v._dice_in_air() and not _c.epoch_pending and _find("turn") == null \
				and _find("boss") == null and _c.phase == CombatEngine.CombatPhase.EXECUTE:
			break
	await get_tree().create_timer(0.3).timeout


func _particles(n: Node) -> int:
	var k := 0
	if n is CPUParticles2D or n is GPUParticles2D or n is CPUParticles3D or n is GPUParticles3D:
		if (n as Node).get("emitting") == true:
			k += 1
	for ch in n.get_children():
		k += _particles(ch)
	return k


func _hit_probe() -> void:
	var units: Array = _v._party_dice_units()
	var boss: Unit = _c.alive_enemies()[0] if not _c.alive_enemies().is_empty() else null
	var hits := 0
	var min_ts := 1.0
	var max_p := 0
	var max_shift := 0.0
	var base: Vector2 = _v._stage3d.position
	var shot_done := false
	for i in units.size():
		var u: Unit = units[i]
		if boss == null or u.hp <= 0 or not u.has_rolled() or u.roll_used():
			continue
		var f: Dictionary = u.die[u.roll_face_index()]
		if String(f.get("type", "")) not in ["dmg", "poison"]:
			continue
		_v._on_die_slot_pressed(i)
		_v._on_target_clicked(boss.uid)
		hits += 1
		for fr in 90:
			await get_tree().process_frame
			min_ts = minf(min_ts, Engine.time_scale)
			max_p = maxi(max_p, _particles(_v))
			max_shift = maxf(max_shift, (_v._stage3d.position - base).length())
			if fr == 12 and not shot_done:
				U.save(get_viewport(), "rm%d--hit" % int(_rm))
				shot_done = true
		for _w in 300:
			if not _v._is_animating:
				break
			await get_tree().process_frame
	_out["hits"] = {"hits": hits, "min_time_scale": min_ts, "max_emitting_particles": max_p, "max_stage_shift_px": max_shift}


func _turn_trial(offset: int) -> void:
	await _settle()
	var t0 := _c.turn
	_v._selected_die_uid = -1
	_v._on_end_turn_pressed()
	# Wait for the new player turn (phase back to EXECUTE with turn + 1).
	var gap_frames := -1
	var gap_live := 0
	var f := 0
	for _i in 2400:
		await get_tree().process_frame
		if _c.won or _c.lost:
			return
		if _c.turn > t0 and _c.phase != CombatEngine.CombatPhase.END_TURN:
			break
	# Now inside the new turn: count frames until the band shows, and whether End turn was live meanwhile.
	var rec := {"offset": offset, "turn": _c.turn}
	var pressed := false
	var band_at_press := false
	var state_at_press := {}
	while f < 120:
		if _find("turn") != null and gap_frames < 0:
			gap_frames = f
		elif _find("turn") == null and gap_frames < 0 and not _v._end_turn_button.disabled:
			gap_live += 1
		if f == offset and not pressed:
			band_at_press = _find("turn") != null
			state_at_press = _state()
			if offset == 3:
				U.save(get_viewport(), "rm%d--your-turn-band" % int(_rm))
			_space()
			pressed = true
		await get_tree().process_frame
		f += 1
		if pressed and f > offset + 40:
			break
	rec["band_after_frames"] = gap_frames
	rec["frames_end_turn_live_before_band"] = gap_live
	rec["band_up_at_press"] = band_at_press
	rec["at_press"] = state_at_press
	rec["after"] = _state()
	rec["turn_ended_by_press"] = _c.turn != int(rec["turn"]) or _c.phase != CombatEngine.CombatPhase.EXECUTE
	(_out["turns"] as Array).append(rec)
