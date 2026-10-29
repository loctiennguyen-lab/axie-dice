extends Node
## QA-only (UI-05 b1 QA2, item 2): a real Elite or boss fight (Combat.tscn, juice on, Reduce motion off), the bot
## aims at the lead first so the lead dies while its adds live. Every frame: the screen box of every enemy still on
## the field (CombatStage3D.unit_screen_rect) against every visible DieCard -> any overlap is logged (with whether the
## enemy was mid-lunge) and the first one is shot. When the lead dies: shots at death, mid-slide, after, and the adds'
## final positions are compared with the plain-fight pattern (_slot_position). Party actions: a mid-action shot of
## the first few, with the clip CombatAnim picked (entry.last_clip). The party gets +400 HP so it lives long enough
## (unranked, visuals only, nothing verified).
##   QA_KIND=elite QA_SEED=424242 QA_NODE=r8_c0 godot/tools/shot.sh res://tests/qa_ui5_stage_capture.tscn 1920x1080
## 1280x720 pins the 2/3 design scale. Shots: UI5_SHOT_DIR. Prints QA_STAGE_RESULT {...}.

const U := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()
var _v: CombatView
var _kind := "elite"
var _tag := ""
var _out := {}
var _overlaps: Array = []
var _overlap_shot := false
var _min_gap := 99999.0
var _min_gap_at := ""
var _frames_checked := 0
var _lead_uid := -1
var _lead_dead_seen := false
var _regroup := {}
var _actions: Array = []
var _clips_seen := {}
var _done := false
var _monitor_on := true
var _turn_after := 0


func _ready() -> void:
	_guard.capture()
	_kind = OS.get_environment("QA_KIND") if OS.get_environment("QA_KIND") != "" else "elite"
	var sd := int(OS.get_environment("QA_SEED")) if OS.get_environment("QA_SEED") != "" else 424242
	var node_id := OS.get_environment("QA_NODE")
	if node_id == "":
		node_id = "r12_c0" if _kind == "boss" else "r8_c0"
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	_tag = "stage-%s-s%d" % [_kind, sd]
	MetaState.runs = 10
	MetaState.runs_with_battle = 30
	MetaState.runs_completed = 10
	MetaState.reduce_motion = false
	RunState.start_new_run(sd, RunBot.DEFAULT_TEAM, "short", int(OS.get_environment("QA_STAGE")) if OS.get_environment("QA_STAGE") != "" else 3, false)
	for e in RunState.roster:
		e["bonus_hp"] = int(e.get("bonus_hp", 0)) + 400
	await get_tree().process_frame
	RunState.power_level = int(OS.get_environment("QA_PW")) if OS.get_environment("QA_PW") != "" else (9 if _kind == "boss" else 6)
	RunState.enter_node(node_id, _kind)
	_v = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(_v)
	for _i in 30:
		await get_tree().process_frame
	var c: CombatEngine = _v._combat
	var names: Array = []
	for u in c.enemies:
		names.append("%s(uid %d hp %d)" % [(u as Unit).key if "key" in u else "?", (u as Unit).uid, (u as Unit).hp])
	_lead_uid = (c.enemies[0] as Unit).uid
	_out["encounter"] = {"kind": c.kind, "node": node_id, "seed": sd, "enemies": names, "window": str(get_window().size),
		"scale": UI3Theme.current_scale()}
	print("QA: encounter %s" % str(_out["encounter"]))
	_monitor()
	await _play()
	_finalize()


var _finalized := false
func _finalize() -> void:
	if _finalized:
		return
	_finalized = true
	_monitor_on = false
	_out["frames_checked"] = _frames_checked
	_out["overlaps"] = _overlaps.slice(0, 40)
	_out["overlap_count"] = _overlaps.size()
	_out["overlap_count_not_lunging"] = _overlaps.filter(func(o): return not bool(o["lunging"])).size()
	_out["min_gap_enemy_bottom_to_card_top_px"] = _min_gap
	_out["min_gap_at"] = _min_gap_at
	_out["regroup"] = _regroup
	_out["actions"] = _actions
	_out["clips_seen"] = _clips_seen
	if _v != null and is_instance_valid(_v) and _v._combat != null:
		_out["combat_end"] = {"won": _v._combat.won, "lost": _v._combat.lost, "turn": _v._combat.turn}
	print("QA_STAGE_RESULT %s" % JSON.stringify(_out))
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)


func _shot(name: String) -> String:
	var p := U.save(get_viewport(), "%s--%s" % [_tag, name])
	return p.get_file()


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


# ------------------------------------------------------------------ per-frame overlap monitor

func _card_rects() -> Array:
	var out: Array = []
	for n in _v.find_children("*", "", true, false):
		if n is DieCard and (n as Control).is_visible_in_tree():
			var t := (n as Control).get_global_transform_with_canvas()
			out.append(Rect2(t.origin, (n as Control).size * t.get_scale()))
	return out


func _enemy_rect(st: CombatStage3D, uid: int) -> Rect2:
	var r := st.unit_screen_rect(uid)
	if r.size.x <= 0.0:
		return Rect2()
	var t := st.get_global_transform_with_canvas()
	return Rect2(t * r.position, r.size * t.get_scale())


func _monitor() -> void:
	while _monitor_on:
		if not is_inside_tree():
			return
		await get_tree().process_frame
		if not _monitor_on:
			return
		if not is_instance_valid(_v) or not _v.is_inside_tree() or _v._combat == null:
			continue
		if _v._combat.won or _v._combat.lost:
			if not _out.has("shot_fight_over"):
				_out["shot_fight_over"] = _shot("fight-over")
				_regroup["fight_over_when_lead_died"] = _lead_dead_seen
			_finalize()
			return
		var st: CombatStage3D = _v._stage3d
		var cards := _card_rects()
		if cards.is_empty():
			continue
		_frames_checked += 1
		var card_top := 99999.0
		for cr in cards:
			card_top = minf(card_top, (cr as Rect2).position.y)
		for u in _v._combat.enemies:
			var uid := (u as Unit).uid
			if (u as Unit).hp <= 0 or st._slot_dead(uid):
				continue
			var er := _enemy_rect(st, uid)
			if er.size.x <= 0.0:
				continue
			var entry: Dictionary = st._units.get(uid, {})
			var slot: Node3D = entry.get("slot")
			var lunging := is_instance_valid(slot) and not slot.position.is_equal_approx(entry.get("rest_pos", slot.position))
			# gap only for enemies whose box is horizontally above a card
			for cr in cards:
				var r := cr as Rect2
				if er.position.x < r.end.x and er.end.x > r.position.x:
					var gap := r.position.y - er.end.y
					if gap < _min_gap and not lunging:
						_min_gap = gap
						_min_gap_at = "uid %d turn %d %s" % [uid, _v._combat.turn, _rs(er)]
				if er.intersects(r):
					var ov := er.intersection(r)
					if ov.size.x > 2.0 and ov.size.y > 2.0:
						_overlaps.append({"uid": uid, "turn": _v._combat.turn, "enemy": _rs(er), "card": _rs(r),
							"overlap": str(ov.size.round()), "lunging": lunging, "lead_dead": _lead_dead_seen})
						if _overlaps.size() <= 30:
							print("QA_OVERLAP %s" % JSON.stringify(_overlaps[-1]))
						if not _overlap_shot:
							_overlap_shot = true
							_out["first_overlap_shot"] = _shot("OVERLAP")
		# lead death -> regroup capture
		var lead := _v._combat.by_uid(_lead_uid)
		if not _lead_dead_seen and lead != null and lead.hp <= 0 and not (_v._combat.won or _v._combat.lost):
			_lead_dead_seen = true
			_capture_regroup()


func _capture_regroup() -> void:
	var st: CombatStage3D = _v._stage3d
	var adds: Array = []
	for u in _v._combat.enemies:
		if (u as Unit).uid != _lead_uid and (u as Unit).hp > 0:
			adds.append((u as Unit).uid)
	_regroup["adds_alive"] = adds
	_regroup["turn"] = _v._combat.turn
	_regroup["fight_over"] = _v._combat.won or _v._combat.lost
	var before := {}
	for a in adds:
		before[str(a)] = str((st._units[a]["slot"] as Node3D).position)
	_regroup["pos_at_death"] = before
	_regroup["shot_death"] = _shot("lead-dies")
	await _wait(0.5)   # death anim starts, reseat, slide 0.3 s
	_regroup["shot_mid"] = _shot("regroup-mid")
	await _wait(0.9)
	_regroup["shot_after"] = _shot("regroup-after")
	var alive: Array = []
	for a in adds:
		var u := _v._combat.by_uid(a)
		if u != null and u.hp > 0 and not st._slot_dead(a):
			alive.append(a)
	var after := {}
	var on_pattern := true
	for i in alive.size():
		var p := (st._units[alive[i]]["slot"] as Node3D).position
		var want := st._slot_position(true, i, alive.size())
		var rp: Vector3 = st._units[alive[i]].get("rest_pos", p)
		after[str(alive[i])] = "pos %s rest_pos %s want %s" % [str(p), str(rp), str(want)]
		on_pattern = on_pattern and rp.is_equal_approx(want)
	_regroup["pos_after"] = after
	_regroup["on_plain_pattern"] = on_pattern if alive.size() > 0 and alive.size() <= 5 else "n/a (%d adds)" % alive.size()
	var cards := _card_rects()
	var clear := true
	for a in alive:
		var er := _enemy_rect(st, a)
		for cr in cards:
			if er.intersects(cr as Rect2):
				clear = false
	_regroup["adds_clear_of_cards_after"] = clear


# ------------------------------------------------------------------ the bot

func _band_up() -> bool:
	var r := _v.get_node_or_null("Ui5Moments/Root")
	if r == null:
		return false
	for ch in r.get_children():
		if (ch is U5BossBand or ch is U5TurnBanner) and (ch as CanvasItem).visible:
			return true
	return false


func _settle() -> bool:
	for _i in 900:
		await get_tree().process_frame
		if not is_instance_valid(_v) or _v._combat == null:
			return false
		var c := _v._combat
		if c.won or c.lost or _v._result_shown:
			return false
		if not _v._is_animating and not _v._dice_in_air() and not c.epoch_pending and not _band_up() \
				and c.phase == CombatEngine.CombatPhase.EXECUTE:
			return true
		if _v._dice_in_air():
			_v._land_dice_now()
	return false


func _play() -> void:
	var turn_shots := 0
	var t0 := Time.get_ticks_msec()
	for _turn in 30:
		if Time.get_ticks_msec() - t0 > 170000:
			_out["stopped"] = "deadline 170 s"
			break
		if _out.has("shot_enemy_turn_after_regroup") and _regroup.has("adds_clear_of_cards_after") and _turn_after > 1:
			_out["stopped"] = "regroup seen + 2 enemy turns"
			break
		if not await _settle():
			break
		var c := _v._combat
		if turn_shots == 0:
			_out["shot_turn1"] = _shot("turn1")
		turn_shots += 1
		var guard := 0
		while guard < 40:
			guard += 1
			var moves: Array = RunBot.legal_moves(c)
			if moves.is_empty():
				break
			# lead first: move whose target is the lead, else the first
			var pick: Array = moves[0]
			for m in moves:
				if int(m[1]) == _lead_uid:
					pick = m
					break
			var uid := int(pick[0])
			var tgt := int(pick[1])
			var units: Array = _v._party_dice_units()
			var slot := -1
			for i in units.size():
				if (units[i] as Unit).uid == uid:
					slot = i
			var u := c.by_uid(uid)
			if slot < 0 or u == null:
				break
			_v._selected_die_uid = -1
			_v._on_die_slot_pressed(slot)
			if _v._selected_die_uid != uid:
				break
			var t := c.by_uid(tgt)
			if t == null or t.hp <= 0 or _v._illegal_reason_for(t) != "":
				_v._on_die_slot_pressed(slot)
				break
			var face: Dictionary = u.current_face() if u.has_method("current_face") else {}
			_v._on_target_clicked(tgt)
			if _v._inspect_panel != null:
				_v._close_unit_inspect()
			if _actions.size() < 8:
				await _wait(0.16)   # lunge out (0.13) + hold: the attacker furthest into its swing
				var entry: Dictionary = _v._stage3d._units.get(uid, {})
				var clip := String(entry.get("last_clip", ""))
				var name := "action-%d-%s" % [_actions.size() + 1, clip if clip != "" else "noclip"]
				var a := {"attacker": uid, "target": tgt, "face": String(face.get("type", "")), "part": String(face.get("part", "")),
					"clip": clip, "shot": ""}
				if not _clips_seen.has(clip) or _actions.size() < 3:
					a["shot"] = _shot(name)
				_clips_seen[clip] = int(_clips_seen.get(clip, 0)) + 1
				_actions.append(a)
			else:
				var entry2: Dictionary = _v._stage3d._units.get(uid, {})
				var clip2 := String(entry2.get("last_clip", ""))
				_clips_seen[clip2] = int(_clips_seen.get(clip2, 0)) + 1
			for _i in 400:
				if not _v._is_animating and not c.epoch_pending:
					break
				await get_tree().process_frame
			if c.won or c.lost:
				break
		if c.won or c.lost:
			break
		if _lead_dead_seen and _regroup.has("shot_after") and _out.has("shot_enemy_turn_after_regroup"):
			pass
		_v._selected_die_uid = -1
		var st := {"on": true}
		var run_end := func() -> void:
			await _v._on_end_turn_pressed()
			st["on"] = false
		run_end.call()
		if not _out.has("shot_enemy_turn"):
			await _wait(0.8)
			_out["shot_enemy_turn"] = _shot("enemy-turn")
		elif _lead_dead_seen and not _out.has("shot_enemy_turn_after_regroup"):
			await _wait(0.8)
			_out["shot_enemy_turn_after_regroup"] = _shot("enemy-turn-after-regroup")
		if _lead_dead_seen:
			_turn_after += 1
		for _i in 3000:
			if not st["on"]:
				break
			await get_tree().process_frame
		if st["on"]:
			_out["anomaly_end_turn_stuck"] = true
			_shot("STUCK")
			break
	await _wait(1.6)   # regroup capture may still be running
	if _lead_dead_seen and is_instance_valid(_v) and _v._combat != null and not (_v._combat.won or _v._combat.lost):
		var st2: CombatStage3D = _v._stage3d
		var alive2: Array = []
		for u in _v._combat.enemies:
			if (u as Unit).uid != _lead_uid and (u as Unit).hp > 0 and not st2._slot_dead((u as Unit).uid):
				alive2.append((u as Unit).uid)
		var fin := {}
		var ok := true
		for i in alive2.size():
			var p2 := (st2._units[alive2[i]]["slot"] as Node3D).position
			var w2 := st2._slot_position(true, i, alive2.size())
			fin[str(alive2[i])] = "pos %s want %s" % [str(p2), str(w2)]
			ok = ok and p2.is_equal_approx(w2)
		_regroup["final_positions_player_turn"] = fin
		_regroup["final_on_plain_pattern"] = ok
	var c2 := _v._combat
	_out["end"] = {"won": c2.won, "lost": c2.lost, "turn": c2.turn, "lead_dead": _lead_dead_seen}
	_out["shot_end"] = _shot("end")


func _rs(r: Rect2) -> String:
	return "%s %s" % [str(r.position.round()), str(r.size.round())]
