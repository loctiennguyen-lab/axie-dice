extends Node
## QA-only (UI-05 b1 QA, item 2 + determinism): plays a WHOLE run through the real screens (RunMap -> Combat -> reward /
## Core / event / treasure / shop / pact -> ... -> Result), juice and moments ON, and screenshots the key beats.
## Decisions mirror RunBot exactly (path next_ids[0], dice in legal_moves order, card 0, event 0, shop buy all, pact 0),
## so the same seed played headless by RunBot must give the SAME action log and score: the UI cannot change a result.
## At the end the UI run's own log + tape go through RunVerifier, and (QA_FLOW=win) are compared with RunBot.play_run.
##
##   QA_FLOW=win  QA_SEED=59 godot/tools/shot.sh res://tests/qa_ui5_flow_capture.tscn 1920x1080
##   QA_FLOW=free QA_SEED=2  ...   (first defeat: free sample Continue, second defeat: End run)
##   QA_FLOW=paid QA_SEED=7  ...   (free sample already used, 500 fake Gem: paid Continue, then End run)
## 1280x720 pins the 2/3 design scale. Shots: UI5_SHOT_DIR (default production/qa/ui05-b1/qa/shots).
## Prints QA_FLOW_RESULT {...} at the end, QA_ANOMALY lines on the way. Runs on the worktree's own user dir (with_lock).

const U := preload("res://tests/qa_ui5_util.gd")

var is_driver := false
var _guard := SaveGuard.new()
var _flow := "win"
var _seed := 59
var _tag := ""
var _shots: Dictionary = {}
var _anomalies: Array[String] = []
var _clips: Array[String] = []
var _log: ActionLog = null
var _epoch = null
var _combat_id := 0
var _fight_n := 0
var _kinds_seen: Dictionary = {}
var _defeats := 0
var _continue_results: Array[String] = []
var _done := false
var _t0 := 0
var _last_progress_ms := 0
var _ui_log_size := 0


func _ready() -> void:
	if not is_driver:
		var d: Node = (get_script() as GDScript).new()
		d.set("is_driver", true)
		d.name = "QaUi5FlowDriver"
		get_tree().root.add_child.call_deferred(d)
		return
	_guard.capture()
	_flow = OS.get_environment("QA_FLOW") if OS.get_environment("QA_FLOW") != "" else "win"
	_seed = int(OS.get_environment("QA_SEED")) if OS.get_environment("QA_SEED") != "" else 59
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	_tag = "flow-%s" % _flow
	_meta()
	RunState.submit_hook = func(_id: String) -> void: print("QA: ranked submit hook (no network) run_id=", _id)
	var boost := OS.get_environment("QA_BOOST") == "1"
	RunState.start_new_run(_seed, RunBot.DEFAULT_TEAM, "short", 0, not boost)
	if boost:
		# QA only, visuals only: a party that cannot lose, to reach the final boss, Victory and the won Result.
		# The run is unranked and its state is edited, so it is NOT verified (the other flows are).
		_tag = "flow-boost"
		for e in RunState.roster:
			e["bonus_hp"] = int(e.get("bonus_hp", 0)) + 400
	_log = RunState.action_log
	_epoch = RunState.epoch
	_t0 = Time.get_ticks_msec()
	_last_progress_ms = _t0
	print("QA: flow=%s seed=%d ranked=%s stage=%d" % [_flow, _seed, RunState.ranked, MetaState.depth_stage()])
	get_tree().change_scene_to_file("res://scenes/run_map/RunMap.tscn")
	_loop()


func _meta() -> void:
	MetaState.runs = 10
	MetaState.runs_with_battle = 30
	MetaState.runs_completed = 10
	MetaState.free_continue_used = _flow == "paid"
	MetaState.gems_cache = 500 if _flow == "paid" else 0
	MetaState.reduce_motion = OS.get_environment("QA_REDUCE_MOTION") == "1"


func _loop() -> void:
	while not _done:
		await get_tree().create_timer(0.12).timeout
		if RunState.action_log != null and RunState.action_log.size() != _ui_log_size:
			_ui_log_size = RunState.action_log.size()
			_last_progress_ms = Time.get_ticks_msec()
		if Time.get_ticks_msec() - _last_progress_ms > 90000:
			_anomaly("no progress for 90 s on %s" % _scene_name())
			_shot("STUCK")
			await _finish()
			return
		var cs := get_tree().current_scene
		if cs == null:
			continue
		if cs is CombatView:
			await _combat_tick(cs as CombatView)
		elif cs.has_method("_show_reward_overlay"):
			await _map_tick(cs)
		elif cs.scene_file_path.contains("result"):
			await _result_tick(cs)


func _scene_name() -> String:
	var cs := get_tree().current_scene
	return "null" if cs == null else cs.scene_file_path.get_file()


func _anomaly(s: String) -> void:
	_anomalies.append(s)
	print("QA_ANOMALY %s" % s)


func _shot(name: String) -> void:
	var path := U.save(get_viewport(), "%s--%s" % [_tag, name])
	_shots[name] = path.get_file()
	for line in U.clip_audit(get_tree().root, get_viewport().get_visible_rect()):
		var l := "%s | %s" % [name, line]
		_clips.append(l)
		print("QA_CLIP %s" % l)


func _shot_once(name: String) -> void:
	if not _shots.has(name):
		_shot(name)


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


# ------------------------------------------------------------------ combat

func _combat_tick(v: CombatView) -> void:
	var c: CombatEngine = v._combat
	if c == null:
		return
	if v.get_instance_id() != _combat_id:
		_combat_id = v.get_instance_id()
		_fight_n += 1
		_kinds_seen[c.kind] = int(_kinds_seen.get(c.kind, 0)) + 1
		print("QA: fight %d kind=%s node=%s enemies=%d" % [_fight_n, c.kind, c.node_id, c.enemies.size()])
		if c.kind == "boss":
			# The in-combat boss band (U5BossBand) holds the turn start: catch it mid-hold.
			for _i in 200:
				await get_tree().process_frame
				if _boss_band(v) != null:
					break
			if _boss_band(v) != null:
				await _wait(0.6)
				_shot_once("boss-band-%d" % _kinds_seen["boss"])
			else:
				_anomaly("boss fight %s: no U5BossBand seen" % c.node_id)
	if _boss_band(v) != null:
		return
	if v._defeat != null and v._defeat.visible:
		await _handle_defeat(v)
		return
	if v._result_shown or c.won or c.lost:
		if c.won and not _shots.has("victory-%d" % _fight_n) and (c.kind != "battle" or _fight_n == 1):
			await _wait(0.5)
			if is_instance_valid(v) and v.is_inside_tree():
				_shot("victory-%d-%s" % [_fight_n, c.kind])
				_shots["victory-%d" % _fight_n] = true
		return
	if c.epoch_pending or v._is_animating or v._dice_in_air():
		if v._dice_in_air():
			v._land_dice_now()
		return
	await _player_turn(v, c)


func _boss_band(v: CombatView) -> Node:
	var r := v.get_node_or_null("Ui5Moments/Root")
	if r == null:
		return null
	for ch in r.get_children():
		if ch is U5BossBand and (ch as CanvasItem).visible:
			return ch
	return null


func _clear_anim(v: CombatView) -> bool:
	for _i in 600:
		if not is_instance_valid(v) or not v.is_inside_tree():
			return false
		if not v._is_animating and not v._combat.epoch_pending and _boss_band(v) == null:
			return true
		await get_tree().process_frame
	_anomaly("combat: _is_animating stuck for 600 frames")
	return false


## RunBot.play_turn, through the screen: dice in legal_moves order (pass after pass), then End turn.
func _player_turn(v: CombatView, c: CombatEngine) -> void:
	var first_turn := c.turn <= 1
	var key := "%s-%d" % [c.kind, _kinds_seen[c.kind]]
	if first_turn and (c.kind != "battle" or _kinds_seen[c.kind] <= 2):
		await _wait(0.4)
		_shot_once("turn1-%s" % key)
	var guard := 0
	while guard < 64:
		guard += 1
		var acted := false
		for move in RunBot.legal_moves(c):
			if not await _clear_anim(v):
				return
			var uid := int(move[0])
			var tgt := int(move[1])
			var units: Array = v._party_dice_units()
			var slot := -1
			for i in units.size():
				if (units[i] as Unit).uid == uid:
					slot = i
			var u := c.by_uid(uid)
			if slot < 0 or u == null:
				_anomaly("die uid %d has no dock slot" % uid)
				continue
			if v._selected_die_uid != -1:
				v._selected_die_uid = -1
			var used_before := u.roll_used()
			var logn := c.action_log.size() if c.action_log != null else -1
			v._on_die_slot_pressed(slot)
			if v._selected_die_uid != uid:
				if not u.held:
					_anomaly("slot %d did not select uid %d (fight %d turn %d)" % [slot, uid, _fight_n, c.turn])
				continue
			if not _shots.has("die-picked"):
				await _wait(0.25)
				_shot("die-picked")
			var t := c.by_uid(tgt)
			if t == null or t.hp <= 0 or v._illegal_reason_for(t) != "":
				v._on_die_slot_pressed(slot)   # deselect: RunBot's use_die would fail on this target too
				if v._inspect_panel != null:
					v._close_unit_inspect()
				continue
			v._on_target_clicked(tgt)
			if v._inspect_panel != null:
				v._close_unit_inspect()
			if u.roll_used() and not used_before:
				acted = true
			elif c.action_log != null and c.action_log.size() != logn:
				acted = true
			if c.won or c.lost:
				return
		if not acted:
			break
	if not await _clear_anim(v):
		return
	if c.won or c.lost:
		return
	if v._selected_die_uid != -1:
		v._selected_die_uid = -1
	# End turn without awaiting, so the enemy turn can be captured while it plays.
	var state := {"running": true}
	var run_end := func() -> void:
		await v._on_end_turn_pressed()
		state["running"] = false
	run_end.call()
	if not _shots.has("enemy-turn") and c.turn >= 1:
		await _wait(0.7)
		if state["running"] and is_instance_valid(v) and v.is_inside_tree():
			_shot("enemy-turn")
	for _i in 4000:
		if not state["running"]:
			break
		await get_tree().process_frame
	if state["running"]:
		_anomaly("end turn never finished (fight %d)" % _fight_n)


func _handle_defeat(v: CombatView) -> void:
	_defeats += 1
	await _wait(1.0)   # scrim + panel in
	var d: DefeatPanel = v._defeat
	_shot("defeat-%d" % _defeats)
	var cont := d.find_child("Continue*", true, false)
	var can_continue := false
	var co := AidPurchase.offer("continue", v._combat, false)
	can_continue = bool(co.get("show", false)) and bool(co.get("enabled", false))
	print("QA: defeat %d offer=%s gems=%d" % [_defeats, str(co), MetaState.gem_wallet().balance()])
	if _flow in ["free", "paid"] and can_continue:
		var gems_before := MetaState.gem_wallet().balance()
		await v._on_defeat_continue()
		var res := "continue #%d price=%d gems %d -> %d free_used=%s" % [_defeats, int(co.get("price", -1)), gems_before,
			MetaState.gem_wallet().balance(), MetaState.free_continue_used]
		_continue_results.append(res)
		print("QA: %s" % res)
		await _wait(1.2)
		_shot("after-continue-%d" % _defeats)
		if v._defeat != null and v._defeat.visible:
			_anomaly("defeat panel still visible after Continue")
	else:
		if _flow in ["free", "paid"] and _defeats == 1:
			_anomaly("first defeat offered no Continue: %s" % str(co))
		var _c := cont
		v._on_defeat_end_run()
		await _wait(0.3)


# ------------------------------------------------------------------ map / screens

func _map_tick(m: Node) -> void:
	if m.get("_taking"):
		return
	var ov: Control = m.get("_overlay_root")
	var boss_layer := m.get_node_or_null("BossIntroLayer")
	if boss_layer != null:
		_shot_once("boss-intro-%d" % (int(_kinds_seen.get("boss", 0)) + 1))
		return
	if ov != null and ov.visible:
		await _screen_tick(m, ov)
		return
	if RunState.phase == RunState.RunPhase.WON or RunState.phase == RunState.RunPhase.LOST:
		return
	await _wait(0.5)
	if not is_instance_valid(m) or not m.is_inside_tree() or (ov != null and ov.visible):
		return
	var pw := RunState.power_level
	if pw <= 0 or not _shots.has("map-1"):
		_shot_once("map-1")
	elif pw == 6 or pw == 12:
		_shot_once("map-pw%d" % pw)
	var graph := RunMapGraph.from_data(RunState.map_graph)
	var id := ""
	if RunState.current_node_id == "":
		id = graph.start_node_id
	else:
		var cur := graph.find_node(RunState.current_node_id)
		if cur == null or cur.next_ids.is_empty():
			_anomaly("map: no next node from %s" % RunState.current_node_id)
			await _finish()
			return
		id = String(cur.next_ids[0])
	if not (m.call("_reachable_now_ids") as Array).has(id):
		_anomaly("map: RunBot's next node %s is not reachable on screen (reachable %s)" % [id, str(m.call("_reachable_now_ids"))])
	print("QA: travel -> %s (pw %d)" % [id, pw])
	m.call("_select_node", id)
	await _wait(0.2)
	await m.call("_on_node_pressed", id)
	await _wait(0.3)


func _screen_tick(m: Node, ov: Control) -> void:
	await _wait(0.6)
	if not is_instance_valid(m) or not m.is_inside_tree() or not ov.visible or m.get("_taking"):
		return
	var pact := ov.find_child("PactView", true, false) as PactView
	if pact != null:
		var psheet := pact.find_child("SlotSwapSheet", true, false)
		if psheet != null:
			# RunBot: take_pact(0) without a sell fails, then skip_pact(). Mirror it: Leave it, then Skip.
			_shot_once("pact-make-room")
			var lv := psheet.find_child("SwapLeave", true, false) as Button
			if lv != null:
				lv.pressed.emit()
			await _wait(0.3)
			if RunState.pact_can_skip():
				pact.skipped.emit()
			else:
				_anomaly("forced pact needs a sell: RunBot cannot mirror this")
			await _wait(0.6)
			return
		_shot_once("pact-%d" % _fight_n)
		if pact.cards.size() > 0 and bool((pact.cards[0] as Dictionary).get("ok", false)):
			pact.select(0)
			pact._on_accept()
			await _wait(0.4)
			var mk := pact.find_child("PactMake", true, false) as Button
			if mk != null:
				_shot_once("pact-confirm")
				mk.pressed.emit()
		else:
			pact.skipped.emit()
		await _wait(0.6)
		return
	var anchor := ov.find_child("AnchorPick", true, false)
	if anchor != null:
		_anomaly("anchor offer in a ranked run")
		_shot_once("anchor")
		anchor.call("select", 0)
		anchor.call("_take")
		return
	var sheet := ov.find_child("SlotSwapSheet", true, false)
	if sheet != null:
		_shot_once("slot-swap")
		_anomaly("slot swap sheet opened (RunBot path has no sheet): taking the first sell cell")
		for b in sheet.find_children("SlotCell_*", "Button", true, false):
			(b as Button).pressed.emit()
			break
		var conf := sheet.find_child("SwapConfirm", true, false) as Button
		if conf != null:
			conf.pressed.emit()
		return
	if ov.find_child("LeaveShop", true, false) != null:
		_shot_once("shop")
		var n := RunState.shop_items.size()
		for i in n:
			await m.call("_on_shop_buy", i)
			await _wait(0.15)
		_shot_once("shop-after-buy")
		var leave := ov.find_child("LeaveShop", true, false) as Button
		if leave != null:
			leave.pressed.emit()
		return
	if ov.find_child("OpenChest", true, false) != null:
		_shot_once("treasure-closed")
		(ov.find_child("OpenChest", true, false) as Button).pressed.emit()
		return
	var ev_act := ov.find_child("EventAction", true, false) as Button
	if ev_act != null:
		if ov.find_child("EventOption0", true, false) != null and m.get("_event_sel") == -1 and not _shots.has("event-outcome-%d" % RunState.power_level):
			if not ev_act.text.begins_with(tr("Continue")):
				_shot_once("event-%d" % RunState.power_level)
				if RunState.event_options().is_empty():
					_anomaly("event with no options")
				await m.call("_on_event_choice", 0)
				await _wait(0.5)
				_shot("event-outcome-%d" % RunState.power_level)
				return
		var go := ov.find_child("EventAction", true, false) as Button
		if go != null:
			go.pressed.emit()
		return
	if ov.find_child("RewardPick", true, false) != null or ov.find_child("TreasureCards", true, false) != null:
		var core: bool = m.call("_core_offer_active")
		var label := "core" if core else ("treasure" if ov.find_child("TreasureCards", true, false) != null else "reward")
		var has_chaos := false
		for r in RunState.pending_rewards:
			has_chaos = has_chaos or String((r as Dictionary).get("t", "")) in ["chaos", "curse"]
		_shot_once("%s-%d" % [label, _count(label)])
		m.call("_select_reward", 0)
		await _wait(0.2)
		m.call("_take_selected_reward")
		await _wait(0.4)
		var bar := ov.find_child("ConfirmBar", true, false)
		if bar == null:
			for ch in ov.find_children("*", "", true, false):
				if ch.has_signal("confirmed") and ch.has_signal("back_pressed"):
					bar = ch
		if bar != null:
			_shot("%s-chaos-confirm" % label)
			bar.emit_signal("confirmed")
		elif has_chaos and String((RunState.pending_rewards[0] if not RunState.pending_rewards.is_empty() else {}).get("t", "")) in ["chaos", "curse"]:
			_anomaly("chaos/curse card 0 taken without the confirm bar")
		await _wait(0.3)
		return
	_shot_once("unknown-overlay-%d" % RunState.power_level)
	_anomaly("unknown overlay at pw %d: %s" % [RunState.power_level, str(ov.get_children().map(func(x): return x.name))])


var _counts: Dictionary = {}
func _count(k: String) -> int:
	_counts[k] = int(_counts.get(k, 0)) + 1
	return _counts[k]


# ------------------------------------------------------------------ result + verdicts

func _result_tick(_cs: Node) -> void:
	await _wait(2.0)
	_shot("result")
	await _finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	var ui_won := RunState.phase == RunState.RunPhase.WON
	# The screen must be gone before the referee / RunBot drive RunState (RunMap listens to EventBus.node_entered).
	if get_tree().current_scene != null:
		get_tree().unload_current_scene()
	for _i in 5:
		await get_tree().process_frame
	var tape: Array = _epoch.tape() if _epoch != null else []
	var log_json := JSON.stringify(_log.to_data())
	var ui_score := RunState.compute_run_xp(ui_won)
	var ui_pw := RunState.power_level
	var out := {
		"flow": _flow, "seed": _seed, "window": str(get_window().size), "secs": (Time.get_ticks_msec() - _t0) / 1000.0,
		"ui_won": ui_won, "ui_score": ui_score, "ui_power_level": ui_pw, "fights": _fight_n, "kinds": _kinds_seen,
		"defeats": _defeats, "continues": _continue_results, "log_actions": _log.entries.size(),
		"log_complete": _log.is_complete(), "anomalies": _anomalies, "clips": _clips.size(), "shots": _shots.keys(),
	}
	if OS.get_environment("QA_BOOST") != "1":
		# 1) The UI's own log + tape, as recorded.
		var v1 := RunVerifier.verify(_log, tape)
		out["verify_raw"] = {"ok": v1["ok"], "error": v1.get("error", ""), "message": v1.get("message", ""),
			"action_index": v1.get("action_index", -1), "score": v1.get("score", -1), "won": v1.get("won", false)}
		# 2) Same seeds, but each `reward` epoch's hash re-chained to include the move that ended the fight (the order
		#    RunVerifier replays in). If this verifies to the UI's own score, the UI changed nothing but that ordering.
		var pt := _patched_tape(tape)
		var v2 := RunVerifier.verify(_log, pt["tape"])
		out["verify_patched"] = {"ok": v2["ok"], "error": v2.get("error", ""), "message": v2.get("message", ""),
			"action_index": v2.get("action_index", -1), "score": v2.get("score", -1), "won": v2.get("won", false),
			"reward_epochs_rechained": pt["patched"], "reward_epochs": pt["rewards"]}
		out["patched_matches_ui"] = bool(v2["ok"]) and int(v2.get("score", -1)) == ui_score and bool(v2.get("won", false)) == ui_won
		var tf := FileAccess.open("%s/%s-%dx%d.tape.json" % [U.out_dir(), _tag, get_window().size.x, get_window().size.y], FileAccess.WRITE)
		if tf != null:
			tf.store_string(JSON.stringify(tape))
			tf.close()
	var f := FileAccess.open("%s/%s-%dx%d.log.json" % [U.out_dir(), _tag, get_window().size.x, get_window().size.y], FileAccess.WRITE)
	if f != null:
		f.store_string(log_json)
		f.close()
	print("QA_FLOW_RESULT %s" % JSON.stringify(out))
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)


const _COMBAT_FNS := ["use_die", "play_active", "reroll_dice", "undo_last", "end_turn", "tweak", "hold_pick", "loaded_pick",
	"continue", "stash", "overcast", "wild_face"]


## The UI tape with every `reward` epoch re-chained one log entry later when the entry at its log_len is the combat move
## that ended the fight (CombatView asks for the reward inside that move, before the engine logs it). Seeds unchanged.
func _patched_tape(tape: Array) -> Dictionary:
	var out: Array = tape.duplicate(true)
	var patched := 0
	var rewards := 0
	if out.is_empty():
		return {"tape": out, "patched": 0, "rewards": 0}
	var run_id := String(((out[0] as Dictionary).get("extra", {}) as Dictionary).get("run_id", ""))
	var prev := EpochCanon.h0(run_id)
	var sent := 0
	for k in range(1, out.size()):
		var e: Dictionary = out[k]
		var ex: Dictionary = e.get("extra", {})
		if not ex.has("h"):
			continue
		var n := int(ex.get("log_len", 0))
		if String(e.get("kind", "")) == "reward":
			rewards += 1
			if n < _log.entries.size() and String((_log.entries[n] as Dictionary).get("fn", "")) in _COMBAT_FNS:
				n += 1
				patched += 1
		var d := EpochCanon.delta(_log.entries.slice(sent, n))
		var h := EpochCanon.chain_step(prev, String(d["canon"]))
		ex["h"] = h.hex_encode()
		ex["log_len"] = n
		prev = h
		sent = n
	return {"tape": out, "patched": patched, "rewards": rewards}
