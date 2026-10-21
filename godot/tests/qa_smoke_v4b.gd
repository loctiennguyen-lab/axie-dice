extends Node
## QA smoke b1188 (run NOT headless, via tools/shot.sh). Drives the REAL flow with real scenes and real
## scene changes: Land -> RunSetup -> begin() -> RunMap (Run Rule offer, Core pick) -> Combat -> ... -> Result.
## No fake Core fires, no injected data. Only setup: MetaState.runs = 1 so the account is on its 2nd run (Run Rules on).
## Pass the phase with env QA_PHASE (1 = Land..first Core, 2 = combat, ...). Shots: production/qa/evidence/smoke_b1188_*.png
var _guard := SaveGuard.new()
var _out := ""
var _log: Array[String] = []

func _ready() -> void:
	_guard.capture()
	get_tree().current_scene = null
	_out = OS.get_environment("ADT_EVIDENCE_DIR")
	if _out == "":
		_out = ProjectSettings.globalize_path("res://").path_join("../production/qa/evidence").simplify_path()
	DirAccess.make_dir_recursive_absolute(_out)
	await frames(2)
	await _flow()
	print("QA: LOG\n", "\n".join(_log))
	_guard.restore()
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
	var p := "%s/smoke_v4b_%s_%dx%d.png" % [_out, name, img.get_width(), img.get_height()]
	img.save_png(p)
	note("shot " + p.get_file())

func cur() -> Node:
	return get_tree().current_scene

func goto(path: String) -> void:
	get_tree().change_scene_to_file(path)
	await frames(30)

func _flow() -> void:

	ProjectSettings.set_setting("axie/epoch_source", "local")
	# Prod is online-only and QA must not hit the network: use the game's own local-dice path.
	ProjectSettings.set_setting("axie/epoch_source", "local")
	var s1 := OS.get_environment("QA_STAGE1") == "1"
	MetaState.tutorial_seen = true
	MetaState.runs = 0 if s1 else 3
	MetaState.runs_with_battle = 0 if s1 else 3
	MetaState.runs_completed = 0 if s1 else 3
	note("stage1=%s depth_stage()=%d" % [str(s1), MetaState.depth_stage()])
	EventBus.combo_fired.connect(func(id): note("EVENT combo_fired " + str(id)))
	EventBus.combo_formed.connect(func(id, t): note("EVENT combo_formed %s %s" % [str(id), str(t)]))
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
	if s1:
		var memes := []
		for d in CoreOffer.valid_pool(RunState._core_ctx(0)):
			if String(d.id).begins_with("c_meme"):
				memes.append(String(d.id))
		note("ITEM6 new account: memes in pool=%s pending=%s (expect [] and no c_meme)" % [str(memes), str(RunState.pending_rewards.map(func(c): return c.get("key", "?")))])
		note("S1: pend=%s phase=%s" % [str(RunState.pending_rewards.map(func(c): return c.get("key", "?"))), str(RunState.phase)])
		await advance_loop()
		return
	m._select_reward(1)
	await frames(5)
	m._take_selected_reward()
	await frames(4)
	var rv0 = m._reveal
	note("ITEM1 right after rule pick: reveal running=%s log=%s" % [str(rv0 != null and is_instance_valid(rv0) and rv0.running), str(m.gacha_log)])
	await shot("01_facedown")
	await frames(40)
	note("after rule: run_rule=%s core_offer=%s pend=%s" % [RunState.run_rule, str(RunState._core_offer_active), str(RunState.pending_rewards.map(func(c): return c.get("key", "?")))])
	var ov_visible: bool = m._overlay_root != null and m._overlay_root.visible
	note("BUG-CHECK core offer overlay visible after rule pick = %s (pending=%d, phase=%s)" % [str(ov_visible), RunState.pending_rewards.size(), str(RunState.phase)])
	if not ov_visible:
		await shot("04_NO_core_overlay_BLOCKER")
		note("BLOCKER: core overlay did not show by itself; stopping")
		return
	await shot("04_core_offer_1")
	await core_checks(m)
	if OS.get_environment("QA_SPEED") != "":
		Engine.time_scale = float(OS.get_environment("QA_SPEED"))
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
			await result_checks(sc)
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
		if is_instance_valid(v):
			pass
		if OS.get_environment("QA_STAGE1") == "1":
			await stage1_checks(v)
		else:
			pass
	if kind == "boss" and first("bossrhythm"):
		await shot("boss_rhythm")
	var turns := 0
	while is_instance_valid(v) and v.is_inside_tree() and cur() == v and turns < 25:
		turns += 1
		if v._combat == null or v._result_shown or _over(v):
			await frames(90)
			break
		await turn_probe(v)
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
	note("S1 DONE")
	get_tree().quit(0)

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
	var alt := OS.get_environment("QA_ALT") == "1"
	if alt:
		await press_reroll(v)
		c.mana += 4
		note("SETUP: mana +4 -> %d" % c.mana)
		v._rebuild_all()
		await frames(5)
		await press_reroll(v)
		if v._rr_mode:
			var cost: int = c.reroll_mana_cost(false, 1)
			var m1: int = c.mana
			await shot("t2e_safe_bar")
			v._rr_bar.safe_button.pressed.emit()
			await frames(10)
			await wait_anim(v, 600)
			note("T2 safe: mana %d->%d cost=%d ok=%s cracked=%d faces=%s" % [m1, c.mana, cost, str(m1 - c.mana == cost), v._party_dice_units().filter(func(u): return u.cracked).size(), str(snap(v))])
			await shot("t2f_after_safe")
		else:
			note("T2 safe: rr not open")
	else:
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
			note("T5 undo_stack size after gamble=%d (engine clears it on reroll unless safeReroll relic)" % c.undo_stack.size())
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
	# --- hunt for a Set / pair over the next turns (end turn, natural roll + the free reroll). QA_STRONG keeps the party alive.
	for attempt in 10:
		var any_ok := false
		for u in v._party_dice_units():
			if v._wild_valid(u.uid):
				any_ok = true
		if any_ok or (not alt and not c.bo.is_empty()):
			note("HUNT done at turn %d (attempt %d): wild_ok=%s bo=%s faces=%s" % [c.turn, attempt, str(any_ok), bo_str(v), str(snap(v))])
			break
		if c.rerolls > 0:
			await press_reroll(v)
			continue
		v._on_end_turn_pressed()
		await wait_anim(v, 900)
		await frames(60)
		await wait_anim(v, 900)
	await shot("t3_pre_wild_pair")
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
	# --- 1: a Set die's effect equals its preview
	var du := -1
	for g in c.bo:
		for uid in g["uids"]:
			var f: Dictionary = c.by_uid(int(uid)).current_face()
			if String(f.get("type", "")) in ["dmg", "shield"] and du == -1:
				du = int(uid)
	if du == -1:
		du = pick_group_die(v)
	if du == -1:
		note("T1 no Set die available")
	else:
		var dd = c.by_uid(du)
		v._selected_die_uid = du
		v._rebuild_all()
		await frames(10)
		var fi: int = dd.roll_face_index()
		var ftype := String(dd.die[fi].get("type"))
		var tgt = null
		if ftype == "dmg":
			for e in c.enemies:
				if e.hp > 0:
					tgt = e
					break
		else:
			for a in c.party:
				if a.hp > 0 and a.uid != du:
					tgt = a
					break
		var pv2: Dictionary = c.preview_damage(dd, tgt, fi) if ftype == "dmg" else {"after": c._face_value(dd, fi)}
		var hp0: int = tgt.hp
		var sh0: int = tgt.shield
		note("T1 die uid=%d face=%d type=%s m100=%d preview=%s target=%d" % [du, fi, ftype, c.m100_for(dd), str(pv2), tgt.uid])
		await shot("t1_set_die_selected")
		v._on_target_clicked(tgt.uid)
		await wait_anim(v, 600)
		note("T1 result: enemy/ally hp %d -> %d, shield %d -> %d" % [hp0, tgt.hp, sh0, tgt.shield])
		await shot("t1_after_hit")
	note("V4 TESTS DONE")
	get_tree().quit(0)


func ov_texts(m: Node, needle: String) -> Array:
	var acc := []
	find_text(m._overlay_root if m._overlay_root != null else m, needle, acc)
	return acc

func key(ev: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = ev
	e.physical_keycode = ev
	e.pressed = true
	Input.parse_input_event(e)
	await frames(2)
	e.pressed = false
	Input.parse_input_event(e)

func core_checks(m: Node) -> void:
	var rv = m._reveal
	note("ITEM1 reveal running=%s log=%s" % [str(rv != null and is_instance_valid(rv) and rv.running), str(m.gacha_log)])
	var leak := []
	for w in ["Next", "next pick", "Crystal", "Amber", "Moss"]:
		leak.append("%s=%s" % [w, str(ov_texts(m, w))])
	note("ITEM1 tier-word texts in overlay: " + " | ".join(leak))
	await key(KEY_SPACE)
	await frames(5)
	note("ITEM1 after Space: running=%s" % str(rv != null and is_instance_valid(rv) and rv.running))
	await shot("01_after_skip")
	# 2: reroll card 0 through its button
	var left0: int = RunState.core_reroll_left
	var old_key := String(RunState.pending_rewards[0].get("key", ""))
	var btn = m.find_child("CardReroll0", true, false)
	note("ITEM2 btn=%s disabled=%s left=%d texts=%s" % [str(btn != null), str(btn.disabled if btn else "-"), left0, str(ov_texts(m, "reroll"))])
	if btn != null and not btn.disabled:
		btn.pressed.emit()
		await get_tree().create_timer(0.15).timeout
		await shot("02_reroll_out")
		await get_tree().create_timer(0.35).timeout
		await shot("02_reroll_in")
		await frames(30)
		note("ITEM2 key %s -> %s left %d -> %d log=%s note_text=%s counter=%s" % [old_key, String(RunState.pending_rewards[0].get("key", "")), left0, RunState.core_reroll_left, str(m.gacha_log), str(ov_texts(m, "come back")), str(ov_texts(m, "reroll"))])
	await key(KEY_SPACE)
	await frames(20)
	# 3: combo. SETUP (injected): grant Core A, swap in a real CoreOffer.build_offer containing partner B.
	var cands := ["combo_shield_engine", "combo_turtle_fort", "combo_molt", "combo_bramble_hide", "combo_toxic_guard"]
	var done := false
	for cid in cands:
		var row := CoreCombos.get_combo(cid)
		if row.is_empty() or row.get("pair") == null:
			continue
		var a := String(row["pair"][0])
		var b := String(row["pair"][1])
		if RunState.owned_relic_ids.has(b):
			continue
		if not RunState.owned_relic_ids.has(a):
			RunState.acquire_relic(a, "qa")
		var found := []
		for sd in 3000:
			var off := CoreOffer.build_offer(Rng.new(sd), 0, RunState._core_ctx(RunState._core_offer_pick), 3)
			for c in off:
				if String(c["key"]) == b:
					found = off
					break
			if not found.is_empty():
				break
		if found.is_empty():
			note("ITEM3 no offer with %s (tier0) for %s" % [b, cid])
			continue
		note("ITEM3 SETUP injected: own %s, offer contains %s combo=%s" % [a, b, cid])
		RunState.pending_rewards = found
		RunState.core_rerolled_slots = []
		m._show_reward_overlay("x")
		await frames(30)
		await key(KEY_SPACE)
		await frames(10)
		note("ITEM3 card texts PAIR=%s With=%s" % [str(ov_texts(m, "PAIR")), str(ov_texts(m, "With"))])
		await shot("03_pair_label")
		var idx := 0
		for k in found.size():
			if String(found[k]["key"]) == b:
				idx = k
		m._select_reward(idx)
		await frames(3)
		var rr0: int = RunState.core_reroll_left
		m.find_child("TakeButton", true, false).pressed.emit()
		await get_tree().create_timer(0.5).timeout
		await shot("03_banner_pair")
		note("ITEM3 log=%s banner PAIR texts=%s" % [str(m.gacha_log), str(_find(get_tree().root, "PAIR"))])
		await frames(150)
		note("ITEM3 core_reroll_left %d -> %d combo_done=%s" % [rr0, RunState.core_reroll_left, str(RunState.combo_done)])
		done = true
		break
	if not done:
		note("ITEM3 could not set up")

var _probe_done := {}
var _combo_seen := 0

func btn_state(b: Button) -> String:
	return "vis=%s dis=%s text='%s' tip='%s'" % [str(b.visible), str(b.disabled), b.text, b.tooltip_text]

func turn_probe(v: Node) -> void:
	var c = v._combat
	await wait_anim(v, 300)
	var sizes = c.bo.map(func(g): return int(g["size"]))
	var h = v._hud_frame
	note("PROBE turn=%d bo_sizes=%s overcast[%s] wild[%s]" % [c.turn, str(sizes), btn_state(h.overcast_button), btn_state(h.wild_button)])
	if v.combo_float_log.size() > _combo_seen:
		_combo_seen = v.combo_float_log.size()
		note("ITEM4 combo banner log=%s" % str(v.combo_float_log))
		await shot("04_combat_combo")
	# 5a: no Set -> overcast should be gray with "Needs a Set"
	if sizes.is_empty() and first("oc_noset"):
		for u in v._party_dice_units():
			if u.has_rolled() and not u.roll_used():
				v._selected_die_uid = u.uid
				v._rebuild_all()
				await frames(8)
				note("ITEM5 NO-SET overcast[%s] preview=%s" % [btn_state(h.overcast_button), str(c.overcast_preview(u))])
				await shot("05_overcast_noset")
				break
	if not sizes.is_empty():
		if first("oc_set"):
			var uid := pick_group_die(v)
			var uu = c.by_uid(uid)
			v._selected_die_uid = uid
			v._rebuild_all()
			await frames(8)
			note("ITEM5 SET overcast[%s] group=%s preview=%s" % [btn_state(h.overcast_button), bo_str(v), str(c.overcast_preview(uu))])
			await shot("05_overcast_set_preview")
			if not h.overcast_button.disabled and h.overcast_button.visible:
				h.overcast_button.pressed.emit()
				await frames(10)
				note("ITEM5 after overcast: overcast=%s wild_valid_on_it=%s" % [str(uu.overcast), str(v._wild_valid(uid))])
				await shot("05_after_overcast")
		var triple = sizes.any(func(s): return s >= 3)
		var pair_only = sizes.any(func(s): return s == 2) and not triple
		if pair_only and first("wild_pair"):
			note("ITEM5 PAIR-ONLY wild[%s]" % btn_state(h.wild_button))
			await shot("05_wild_pair_only")
		if triple and first("wild_triple"):
			note("ITEM5 TRIPLE wild[%s]" % btn_state(h.wild_button))
			if not h.wild_button.disabled and h.wild_button.visible:
				h.wild_button.pressed.emit()
				await frames(10)
				for u in v._party_dice_units():
					if v._wild_valid(u.uid):
						for slot in 6:
							if bool(c.preview_wild(u.uid, slot)["ok"]):
								v._wild_pick_die(u.uid)
								await frames(8)
								v._wild_picker.picked.emit(slot)
								await frames(10)
								await wait_anim(v, 600)
								note("ITEM5 wild used: wild[%s]" % btn_state(h.wild_button))
								await shot("05_wild_used")
								return
	if _probe_done.has("wild_after") == false and first("wild_triple") == false and false:
		pass

func result_checks(sc: Node) -> void:
	for w in ["Combos", "Skipped", "Pair", "Full"]:
		note("ITEM7 result '%s' = %s" % [w, str(ov_texts(sc, w) if false else _find(sc, w))])
	await frames(30)
	await goto("res://scenes/codex/Codex.tscn")
	var cx := cur()
	if cx != null and cx.has_method("_select_tab"):
		cx._select_tab("combos")
		await frames(20)
		note("ITEM7 codex tabs=%s texts=%s" % [str(cx._tab_buttons.keys()), str(_find(cx, "combo"))])
		await shot("07_codex_combos")
	else:
		note("ITEM7 codex scene unavailable")
	await goto("res://scenes/daily/DailyScreen.tscn")
	note("ITEM7 daily 'Form combo' = %s" % str(_find(cur(), "Form combo")))
	await shot("07_daily")

func _find(n: Node, w: String) -> Array:
	var acc := []
	find_text(n, w, acc)
	return acc
