extends Node
## QA smoke b1188 (run NOT headless, via tools/shot.sh). Drives the REAL flow with real scenes and real
## scene changes: Land -> RunSetup -> begin() -> RunMap (Run Rule offer, Core pick) -> Combat -> ... -> Result.
## No fake Core fires, no injected data. Only setup: MetaState.runs = 1 so the account is on its 2nd run (Run Rules on).
## Pass the phase with env QA_PHASE (1 = Land..first Core, 2 = combat, ...). Shots: production/qa/evidence/smoke_b1188_*.png
var _out := ""
var _log: Array[String] = []

func _ready() -> void:
	get_tree().current_scene = null
	_out = OS.get_environment("ADT_EVIDENCE_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	await frames(2)
	await _flow()
	print("QA: LOG\n", "\n".join(_log))
	get_tree().quit(0)

func note(s: String) -> void:
	_log.append(s)
	print("QA: ", s)

func frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame

func shot(name: String) -> void:
	print("QA: shot-begin ", name)
	await frames(6)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var p := "%s/smoke_v4_%s_%dx%d.png" % [_out, name, img.get_width(), img.get_height()]
	img.save_png(p)
	note("shot " + p.get_file())

func cur() -> Node:
	return get_tree().current_scene

func goto(path: String) -> void:
	get_tree().change_scene_to_file(path)
	await frames(30)

func _flow() -> void:
	if OS.get_environment("QA_SPEED") != "":
		Engine.time_scale = float(OS.get_environment("QA_SPEED"))
	ProjectSettings.set_setting("axie/epoch_source", "local")
	# Prod is online-only and QA must not hit the network: use the game's own local-dice path.
	ProjectSettings.set_setting("axie/epoch_source", "local")
	var s1 := OS.get_environment("QA_STAGE1") == "1"
	MetaState.tutorial_seen = true
	MetaState.runs = 0 if s1 else 3
	MetaState.runs_with_battle = 0 if s1 else 3
	MetaState.runs_completed = 0 if s1 else 3
	note("stage1=%s depth_stage()=%d" % [str(s1), MetaState.depth_stage()])
	await goto(LandNav.LAND_SCENE)
	await shot("01_land")
	LandNav.open(&"run_setup")
	await frames(40)
	var rs := cur()
	note("scene=%s party=%s" % [rs.name, str(rs.get("party"))])
	await shot("02_run_setup")
	rs.set("mode", "short")
	var r: Dictionary = await rs.begin()
	if OS.get_environment("QA_STRONG") == "1":
		for e in RunState.roster:
			e["bonus_hp"] = int(e.get("bonus_hp", 0)) + 400
		note("QA_STRONG: +400 bonus_hp on roster")
	note("begin -> %s phase=%s rules_on=%s" % [str(r), str(RunState.phase), str(RunState.rules_on)])
	await frames(60)
	note("scene=%s rule_offer=%s pend=%s" % [cur().name, str(RunState._rule_offer_active), str(RunState.pending_rewards.map(func(c): return c.get("key", "?")))])
	await shot("03_run_rule_offer")
	# Pick Tundra (index 1: no free reroll, Hold) so Hold / reroll-Mana get exercised.
	var m := cur()
	m._select_reward(1)
	await frames(5)
	m._take_selected_reward()
	await frames(40)
	note("after rule: run_rule=%s core_offer=%s pend=%s" % [RunState.run_rule, str(RunState._core_offer_active), str(RunState.pending_rewards.map(func(c): return c.get("key", "?")))])
	var ov_visible: bool = m._overlay_root != null and m._overlay_root.visible
	note("BUG-CHECK core offer overlay visible after rule pick = %s (pending=%d, phase=%s)" % [str(ov_visible), RunState.pending_rewards.size(), str(RunState.phase)])
	if not ov_visible:
		await shot("04_NO_core_overlay_BLOCKER")
		note("BLOCKER: core overlay did not show by itself; stopping")
		return
	await shot("04_core_offer_1")
	await advance_loop()

var _seen := {}
var _core_total_last := 0
var _fire_shot := false

func first(tag: String) -> bool:
	if _seen.has(tag):
		return false
	_seen[tag] = true
	return true

func core_total() -> int:
	var t := 0
	for k in RunState.core_impact:
		var v = RunState.core_impact[k]
		if v is Dictionary:
			for kk in v:
				if v[kk] is int or v[kk] is float:
					t += int(v[kk])
		elif v is int or v is float:
			t += int(v)
	return t

func advance_loop() -> void:
	var steps := 0
	while steps < 400:
		steps += 1
		var sc := cur()
		if sc == null:
			await frames(10)
			continue
		var n := String(sc.name)
		if n == "Result" or sc.scene_file_path.ends_with("Result.tscn"):
			await frames(60)
			await shot("20_result")
			return
		if sc.scene_file_path.ends_with("RunMap.tscn"):
			await map_step(sc)
		elif sc.scene_file_path.ends_with("Combat.tscn"):
			await combat_step(sc)
		else:
			note("unexpected scene " + sc.scene_file_path)
			await shot("99_unexpected_" + str(steps))
			await frames(30)
	note("step cap hit")

func map_step(sc: Node) -> void:
	await frames(20)
	if not RunState.pending_rewards.is_empty():
		var tag := "reward_phase%s_n%s" % [str(RunState.phase), str(RunState.current_node_id)]
		note("reward overlay core=%s rule=%s cards=%s" % [str(RunState._core_offer_active), str(RunState._rule_offer_active), str(RunState.pending_rewards.map(func(c): return c.get("key", "?")))])
		if first(tag):
			await shot("30_reward_%d" % _seen.size())
		await frames(5)
		if not sc._reward_cards.is_empty() and is_instance_valid(sc._reward_cards[0]):
			sc._select_reward(0)
		else:
			note("WARN reward cards freed/empty before select (overlay rebuilt)")
		await frames(3)
		sc._take_selected_reward()
		await frames(30)
		return
	if first("map"):
		await shot("05_run_map")
	var ids: Array = sc._reachable_now_ids()
	note("map node=%s reachable=%s phase=%s" % [str(RunState.current_node_id), str(ids), str(RunState.phase)])
	if ids.is_empty():
		await frames(30)
		return
	var pick: String = ids[0]
	for id in ids:   # prefer elite so the affix/Armor path is covered
		var nd = sc._node_visuals.get(id, {}).get("node")
		if nd != null and nd.node_type == "elite":
			pick = id
	await sc._on_node_pressed(pick)
	await frames(60)

func combat_step(v: Node) -> void:
	await frames(60)
	var kind := "?"
	var gnode := RunMapGraph.from_data(RunState.map_graph).find_node(RunState.current_node_id)
	if gnode != null:
		kind = String(gnode.node_type)
	var tag := "combat_" + kind
	if first(tag + "_start"):
		note("combat start node=%s" % RunState.current_node_id)
		await shot("10_%s_start" % kind)
	if first("v4tests"):
		if OS.get_environment("QA_STAGE1") == "1":
			await stage1_checks(v)
		else:
			await v4_tests(v)
	if kind == "boss" and first("bossrhythm"):
		await shot("boss_rhythm")
	var turns := 0
	while is_instance_valid(v) and v.is_inside_tree() and cur() == v and turns < 25:
		turns += 1
		if v._combat == null or v._result_shown or _over(v):
			await frames(90)
			break
		var uses := 0
		for i in 6:
			if v._is_animating:
				await wait_anim(v)
			v._on_die_slot_pressed(i)
			if v._selected_die_uid == -1:
				continue
			var tried := false
			for e in v._combat.enemies:
				if e.hp > 0:
					v._on_target_clicked(e.uid)
					tried = true
					if v._selected_die_uid == -1:
						break
			if v._selected_die_uid != -1:
				for a in v._combat.party:
					if a.hp > 0:
						v._on_target_clicked(a.uid)
						if v._selected_die_uid == -1:
							break
			if v._selected_die_uid == -1:
				uses += 1
			await wait_anim(v)
			await check_core_fire(kind)
			await check_float(v)
		if first(tag + "_midturn"):
			await shot("11_%s_midturn" % kind)
		note("turn %d uses=%d" % [turns, uses])
		if cur() != v or not is_instance_valid(v):
			break
		v._on_end_turn_pressed()
		await wait_anim(v, 600)
		await check_core_fire(kind)
	await frames(30)

func _over(v: Node) -> bool:
	var e := true
	for u in v._combat.enemies:
		if u.hp > 0:
			e = false
	var p := true
	for u in v._combat.party:
		if u.hp > 0:
			p = false
	return e or p

func wait_anim(v: Node, cap: int = 300) -> void:
	var n := 0
	while is_instance_valid(v) and v.is_inside_tree() and v._is_animating and n < cap:
		n += 1
		await get_tree().process_frame
	await frames(8)

var _float_n := 0
func check_float(v) -> void:
	if is_instance_valid(v) and v.core_float_log.size() > _float_n:
		_float_n = v.core_float_log.size()
		note("core float %s" % str(v.core_float_log.back()))
		if first("floatshot"):
			await get_tree().create_timer(0.35).timeout
			await shot("core_float_%s" % str(RunState.current_node_id))

func check_core_fire(kind: String) -> void:
	var t := core_total()
	if t > _core_total_last:
		_core_total_last = t
		note("core impact total now %d (%s)" % [t, str(RunState.core_impact)])
		if first("firstfire_" + kind):
			await get_tree().create_timer(0.45).timeout
			await shot("12_core_fired_%s" % kind)

func reparent_self() -> void:
	if get_parent() == get_tree().root:
		return
	var p := get_parent()
	if p != null:
		p.remove_child(self)
	get_tree().root.add_child(self)


func hud_vis(v: Node) -> String:
	var h = v._hud_frame
	return "hold=%s wild=%s overcast=%s reroll=%s undo=%s" % [str(h.hold_button.visible), str(h.wild_button.visible), str(h.overcast_button.visible), str(h.reroll_button.visible), str(h.undo_button.visible)]

func snap(v: Node) -> Array:
	var out := []
	for u in v._party_dice_units():
		out.append("%d:%d%s" % [u.uid, u.roll_face_index(), "C" if u.cracked else ""])
	return out

func find_text(n: Node, needle: String, acc: Array) -> void:
	if n is Label and (n as Label).is_visible_in_tree() and needle in (n as Label).text:
		acc.append((n as Label).text)
	elif n is Button and (n as Button).is_visible_in_tree() and needle in (n as Button).text:
		acc.append((n as Button).text)
	for c in n.get_children():
		find_text(c, needle, acc)

func stage1_checks(v: Node) -> void:
	await frames(60)
	note("S1 stage=%d %s" % [v._combat.depth_stage, hud_vis(v)])
	note("S1 coach id=%s text=%s" % [v.coach_shown_id, (v._coach_label.text if v._coach_label != null else "-")])
	note("S1 bo=%s" % str(v._combat.bo))
	await shot("s1_combat")

func pick_group_die(v: Node) -> int:
	for g in v._combat.bo:
		return int((g["uids"] as Array)[0])
	return -1

func press_reroll(v: Node) -> void:
	v._hud_frame.reroll_button.pressed.emit()
	await frames(10)
	await wait_anim(v, 600)

func bo_str(v: Node) -> String:
	return str(v._combat.bo.map(func(g): return "part%s size%s m100=%s uids=%s" % [str(g["part"]), str(g["size"]), str(g["m100"]), str(g["uids"])]))

func v4_tests(v: Node) -> void:
	var c = v._combat
	await wait_anim(v, 600)
	await frames(60)
	note("T0 stage=%d mana=%d rerolls=%d turn=%d %s" % [c.depth_stage, c.mana, c.rerolls, c.turn, hud_vis(v)])
	note("T0 faces=%s bo=%s banner=%s labels=%s" % [str(snap(v)), bo_str(v), str(v._bo_layer.last_banner), str(v._bo_layer.group_labels())])
	await shot("t1_first_roll")
	# --- 2/5: free reroll, then Gamble twice with an Undo in between
	await press_reroll(v)
	note("T2a after free press: rerolls=%d rr_mode=%s faces=%s bo=%s" % [c.rerolls, str(v._rr_mode), str(snap(v)), bo_str(v)])
	await shot("t2a_after_reroll1")
	for _k in 3:
		if v._rr_mode:
			break
		await press_reroll(v)
		note("T2 extra press: rerolls=%d rr_mode=%s mana=%d" % [c.rerolls, str(v._rr_mode), c.mana])
	if not v._rr_mode:
		note("FAIL T2: Gamble/Safe pick mode never opened")
	else:
		await frames(10)
		note("T2 rr bar visible=%s line='%s' gamble='%s' safe='%s'" % [str(v._rr_bar.visible), "?", v._rr_bar.gamble_button.text, v._rr_bar.safe_button.text])
		var lbls := []
		find_text(v, "%", lbls)
		note("T2 texts with %%: %s" % str(lbls))
		await shot("t2b_gamble_safe_bar")
		var before := snap(v)
		var mana0: int = c.mana
		v._rr_bar.gamble_button.pressed.emit()
		await frames(10)
		await wait_anim(v, 600)
		var r1 := snap(v)
		var cr := 0
		for u in v._party_dice_units():
			if u.cracked: cr += 1
		note("T2 gamble: before=%s after=%s cracked=%d mana %d->%d bo=%s" % [str(before), str(r1), cr, mana0, c.mana, bo_str(v)])
		var chips := []
		find_text(v, "1/2", chips)
		note("T2 crack chip texts: %s" % str(chips))
		await shot("t2c_after_gamble")
		# --- 5: undo then repeat gamble -> same result
		v._hud_frame.undo_button.pressed.emit()
		await frames(10)
		var after_undo := snap(v)
		note("T5 undo: faces=%s (before gamble was %s) match=%s" % [str(after_undo), str(before), str(after_undo == before)])
		await press_reroll(v)
		if v._rr_mode:
			v._rr_bar.gamble_button.pressed.emit()
			await frames(10)
			await wait_anim(v, 600)
		var r2 := snap(v)
		note("T5 repeat gamble: %s vs first %s -> same=%s" % [str(r2), str(r1), str(r2 == r1)])
		await shot("t5_after_undo_regamble")
		# Safe: mana
		await press_reroll(v)
		if v._rr_mode:
			var cost: int = c.reroll_mana_cost(false, 1)
			var m1: int = c.mana
			note("T2 safe state: cost=%d mana=%d safe_disabled=%s" % [cost, m1, str(v._rr_bar.safe_button.disabled)])
			if v._rr_bar.safe_button.disabled:
				c.mana += 10
				note("SETUP: mana +10 (safe disabled)")
				m1 = c.mana
				v._rebuild_all()
				await frames(5)
			v._rr_bar.safe_button.pressed.emit()
			await frames(10)
			await wait_anim(v, 600)
			note("T2 safe: mana %d->%d (cost %d) ok=%s faces=%s" % [m1, c.mana, cost, str(m1 - c.mana == cost), str(snap(v))])
			await shot("t2d_after_safe")
		else:
			note("T2 safe: rr mode did not open for 3rd press (rerolls=%d)" % c.rerolls)
	# --- 3: Wild face
	if c.mana < 6:
		c.mana += 10
		note("SETUP: mana topped up to %d for Wild/Overcast" % c.mana)
		v._rebuild_all()
		await frames(5)
	note("T3 pre: bo=%s wild_cost=%d mana=%d" % [bo_str(v), c.wild_cost(), c.mana])
	v._hud_frame.wild_button.pressed.emit()
	await frames(10)
	note("T3 wild_mode=%s" % str(v._wild_mode))
	var best_slot := -1
	var best_uid := -1
	var best_key := 0
	if v._wild_mode:
		for u in v._party_dice_units():
			if not v._wild_valid(u.uid):
				continue
			for slot in 6:
				var pv: Dictionary = c.preview_wild(u.uid, slot)
				if not bool(pv["ok"]):
					continue
				var g: Dictionary = V4Ui.group_of(pv["groups"], u.uid)
				var key := 0 if g.is_empty() else int(g["size"]) * 1000 + int(g["m100"])
				if key > best_key:
					best_key = key; best_slot = slot; best_uid = u.uid
		note("T3 best wild uid=%d slot=%d key=%d" % [best_uid, best_slot, best_key])
		if best_uid != -1:
			v._wild_pick_die(best_uid)
			await frames(10)
			var wl := []
			find_text(v, "SET OF", wl)
			find_text(v, "→", wl)
			note("T3 picker texts: %s" % str(wl))
			await shot("t3_wild_picker")
			var m0: int = c.mana
			v._wild_picker.picked.emit(best_slot)
			await frames(10)
			await wait_anim(v, 600)
			note("T3 after wild: mana %d->%d (cost %d) bo=%s" % [m0, c.mana, c.wild_cost(), bo_str(v)])
			await shot("t3_after_wild")
	# --- 4: Overcast on a die in a Set
	var ou := pick_group_die(v)
	if ou == -1:
		note("T4 no Set on the board; cannot test Overcast-in-Set")
		for u in v._party_dice_units():
			if u.has_rolled() and not u.roll_used():
				ou = u.uid
				break
	if ou != -1:
		var uu = c.by_uid(ou)
		v._selected_die_uid = ou
		v._rebuild_all()
		await frames(10)
		var m_before: int = c.m100_for(uu)
		var pvv = c.overcast_preview(uu)
		note("T4 overcast show=%s enabled=%s text='%s' m100=%d preview=%s in_set=%s" % [str(v._hud_frame.overcast_button.visible), str(not v._hud_frame.overcast_button.disabled), v._hud_frame.overcast_button.text, m_before, str(pvv), str(not V4Ui.group_of(c.bo, ou).is_empty())])
		await shot("t4_overcast_preview")
		if v._hud_frame.overcast_button.visible and not v._hud_frame.overcast_button.disabled:
			var mm: int = c.mana
			v._hud_frame.overcast_button.pressed.emit()
			await frames(10)
			note("T4 after overcast: m100 %d->%d mana %d->%d overcast=%s" % [m_before, c.m100_for(uu), mm, c.mana, str(uu.overcast)])
			await shot("t4_after_overcast")
	# --- 1: damage of a Set die equals its preview
	var du := pick_group_die(v)
	if du == -1:
		du = ou
	if du != -1:
		var dd = c.by_uid(du)
		v._selected_die_uid = du
		v._rebuild_all()
		await frames(10)
		var tgt = null
		for e in c.enemies:
			if e.hp > 0:
				tgt = e
				break
		var fi: int = dd.roll_face_index()
		var pv2: Dictionary = c.preview_damage(dd, tgt, fi)
		var hp0: int = tgt.hp
		note("T1 die uid=%d face=%d type=%s m100=%d preview=%s" % [du, fi, str(dd.die[fi].get("type")), c.m100_for(dd), str(pv2)])
		await shot("t1_set_die_selected")
		v._on_target_clicked(tgt.uid)
		await wait_anim(v, 600)
		note("T1 enemy hp %d -> %d (lost %d)" % [hp0, tgt.hp, hp0 - tgt.hp])
		await shot("t1_after_hit")
