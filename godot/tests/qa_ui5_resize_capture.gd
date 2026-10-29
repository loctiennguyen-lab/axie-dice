extends Node
## QA-only (UI-05 b1 QA, item 4): a real fight (Combat.tscn, juice on), window 1920 -> 1280 -> 1920 mid-combat,
## once on the player's turn with a die picked and once during the enemy turn. Shots after each step, a text-clip /
## off-screen audit (qa_ui5_util.gd), and the rects of the dock, run info, enemy plates and dice cards, so the 1920
## layout after the round trip can be compared with the first one. No scale pin: the game's own resize path runs.
##   godot/tools/shot.sh res://tests/qa_ui5_resize_capture.tscn 1920x1080
## QA_KIND=boss|elite|battle (default elite). Prints QA_RESIZE_RESULT {...}.

const U := preload("res://tests/qa_ui5_util.gd")
var _guard := SaveGuard.new()
var _v: CombatView
var _out: Dictionary = {}
var _kind := "elite"
var _pin := false


func _ready() -> void:
	_guard.capture()
	_kind = OS.get_environment("QA_KIND") if OS.get_environment("QA_KIND") != "" else "elite"
	_pin = OS.get_environment("QA_PIN") == "1"
	if _pin:
		UI3Theme.set_scale_override(1.0)
	MetaState.runs = 10
	MetaState.runs_with_battle = 30
	MetaState.runs_completed = 10
	RunState.start_new_run(424242, RunBot.DEFAULT_TEAM, "short", 3, false)
	await get_tree().process_frame
	RunState.power_level = 9 if _kind == "boss" else 6
	var node_id := "r12_c0" if _kind == "boss" else "r8_c0"
	RunState.enter_node(node_id, _kind)
	_v = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(_v)
	await _settle_turn()
	# Step A: player's turn, a die picked.
	_pick_die()
	await _frames(20)
	await _step("A1-1920-pick")
	await _resize(Vector2i(1280, 720))
	await _step("A2-1280-pick")
	await _resize(Vector2i(1920, 1080))
	await _step("A3-1920-back")
	_compare("A1-1920-pick", "A3-1920-back")
	# Step B: during the enemy turn.
	_v._selected_die_uid = -1
	_v._rebuild_all()
	var st := {"on": true}
	var run_end := func() -> void:
		await _v._on_end_turn_pressed()
		st["on"] = false
	run_end.call()
	await get_tree().create_timer(0.5).timeout
	await _step("B1-1920-enemy")
	await _resize(Vector2i(1280, 720))
	await _step("B2-1280-enemy")
	await _resize(Vector2i(1920, 1080))
	for _i in 2000:
		if not st["on"]:
			break
		await get_tree().process_frame
	await _settle_turn()
	await _step("B3-1920-next-turn")
	_compare("A1-1920-pick", "B3-1920-next-turn")
	print("QA_RESIZE_RESULT %s" % JSON.stringify(_out))
	UI3Theme.set_scale_override(-1.0)
	_guard.restore()
	get_tree().quit(0)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _settle_turn() -> void:
	for _i in 900:
		await get_tree().process_frame
		if _v._combat != null and not _v._is_animating and not _v._dice_in_air() and not _v._combat.epoch_pending \
				and _v._combat.phase == CombatEngine.CombatPhase.EXECUTE and not _band_up():
			break
	await get_tree().create_timer(0.6).timeout


func _band_up() -> bool:
	var r := _v.get_node_or_null("Ui5Moments/Root")
	if r == null:
		return false
	for c in r.get_children():
		if (c is U5BossBand or c is U5TurnBanner) and (c as CanvasItem).visible:
			return true
	return false


func _pick_die() -> void:
	var units: Array = _v._party_dice_units()
	for i in units.size():
		var u: Unit = units[i]
		if u.hp > 0 and u.has_rolled() and not u.roll_used():
			_v._on_die_slot_pressed(i)
			return


func _resize(sz: Vector2i) -> void:
	if _pin:
		# A DPR-1 display: 1920 -> scale 1.0, 1280 -> 0.667 (what UI3Theme.scale_for gives there). This Mac is DPR 2,
		# where the same pixel sizes read as 960x540 / 640x360 points (scale 0.5 / 0.333): that is the QA_PIN=0 run.
		UI3Theme.set_scale_override(1.0 if sz.x >= 1600 else 2.0 / 3.0)
	get_window().size = sz
	await _frames(45)
	await get_tree().create_timer(0.3).timeout


func _step(tag: String) -> void:
	var path := U.save(get_viewport(), "resize-%s%s--%s" % [_kind, "-dpr1" if _pin else "-retina", tag])
	var clips := U.clip_audit(get_tree().root, get_viewport().get_visible_rect())
	var rects := _rects()
	_out[tag] = {"shot": path.get_file(), "window": str(get_window().size), "scale": UI3Theme.current_scale(),
		"clips": clips, "rects": rects}
	for c in clips:
		print("QA_CLIP %s | %s" % [tag, c])


func _rects() -> Dictionary:
	var d := {}
	for nm in ["RunInfo", "ActionDock", "AidZone", "EndTurnButton", "RerollButton", "StatusLine", "BossRhythm", "WaitingPill"]:
		var n := _v.find_child(nm, true, false) as Control
		if n != null and n.is_visible_in_tree():
			d[nm] = _screen_rect(n)
	var i := 0
	for n in _v.find_children("*", "", true, false):
		if n is Control and (n as Control).is_visible_in_tree():
			var s := String(n.get_script().resource_path.get_file()) if n.get_script() != null else ""
			if s in ["DieCard.gd", "EnemyPlate.gd", "BossPlate.gd", "IntentBlock.gd"]:
				d["%s#%d" % [s.get_basename(), i]] = _screen_rect(n as Control)
				i += 1
	return d


func _screen_rect(c: Control) -> String:
	var t := c.get_global_transform_with_canvas()
	var r := Rect2(t.origin, c.size * t.get_scale())
	var vp := get_viewport().get_visible_rect()
	return "%s%s" % [str(r.position.round()) + " " + str(r.size.round()), "" if vp.grow(1).encloses(r) else " OUTSIDE"]


func _compare(a: String, b: String) -> void:
	var ra: Dictionary = (_out[a] as Dictionary)["rects"]
	var rb: Dictionary = (_out[b] as Dictionary)["rects"]
	var diffs: Array = []
	for k in ra:
		if String(k).begins_with("RunInfo") or String(k).begins_with("ActionDock") or String(k).begins_with("EndTurn") \
				or String(k).begins_with("DieCard") or String(k).begins_with("EnemyPlate") or String(k).begins_with("BossPlate"):
			if not rb.has(k):
				diffs.append("%s missing after" % k)
			elif ra[k] != rb[k]:
				diffs.append("%s: %s -> %s" % [k, ra[k], rb[k]])
	_out["compare %s vs %s" % [a, b]] = diffs
