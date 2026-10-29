extends Node
## UI-05 (Liam 29/10): when the Elite / boss dies, the adds still alive regroup on the plain-fight ENEMY_PATTERNS
## (CombatStage3D._regroup_after_lead). Checks: positions = the n-enemy pattern, dead adds left out, slide over
## REGROUP_SEC when the death was seen, instant under Reduce motion / headless juice off / an already-dead lead,
## nothing moves while the lead lives, more than 5 adds keep the add layout, and the regrouped adds stay clear of
## the DieCards and the enemy plate column at the game's band (CombatView.stage_band).

const CANVAS := Vector2(1920.0, 1080.0)
const PANEL_X := 1576.0
const KEYS: Array[String] = ["chomper", "slime", "bugling", "spikelet", "ravenling", "jellyfin", "shiitake"]

var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	print("=== t_ui5_lead_regroup: start ===")
	var saved_juice := CombatView.disable_juice_for_tests
	var saved_rm: bool = MetaState.reduce_motion
	CombatView.disable_juice_for_tests = true
	MetaState.reduce_motion = false

	# 1. Elite + 2 adds: the elite lives -> add slots; the elite dies -> the 2-enemy pattern, instantly here.
	var c := await _build("elite", 3, false)
	var st: CombatStage3D = c.stage
	var en: Array = c.enemies
	var add_pos := [_pos(st, en[1]), _pos(st, en[2])]
	st.reseat_side(en, true)
	_assert(_pos(st, en[1]).is_equal_approx(add_pos[0]) and _pos(st, en[2]).is_equal_approx(add_pos[1]),
		"elite alive: adds must not move")
	st.set_alive(en[0], false)
	st.reseat_side(en, true)
	_expect_pattern(st, [en[1], en[2]], "elite dead, 2 adds")
	_expect_clear(st, [en[1], en[2]], "elite dead, 2 adds")
	st.reseat_side(en, true)   # every rebuild calls it again: stays put
	_expect_pattern(st, [en[1], en[2]], "elite dead, second reseat")
	await _free(c)

	# 2. Elite + 2, one add died first: the survivor takes the 1-enemy slot.
	c = await _build("elite", 3, false)
	st = c.stage
	en = c.enemies
	st.set_alive(en[2], false)
	st.set_alive(en[0], false)
	st.reseat_side(en, true)
	_expect_pattern(st, [en[1]], "elite + dead add")
	await _free(c)

	# 3. Boss + 2 summons, boss dead (the fight goes on): the 2-enemy pattern. Same with 4 summons.
	for n in [3, 5]:
		c = await _build("boss", n, true)
		st = c.stage
		en = c.enemies
		st.set_alive(en[0], false)
		st.reseat_side(en, true)
		var adds: Array = en.slice(1)
		_expect_pattern(st, adds, "boss dead, %d summons" % (n - 1))
		_expect_clear(st, adds, "boss dead, %d summons" % (n - 1))
		await _free(c)

	# 4. Boss + 6 summons, boss dead: no 6-enemy pattern, the add layout stays.
	c = await _build("boss", 7, true)
	st = c.stage
	en = c.enemies
	var before: Array = []
	for u in en:
		before.append(_pos(st, u))
	st.set_alive(en[0], false)
	st.reseat_side(en, true)
	var same := true
	for i in en.size():
		same = same and _pos(st, en[i]).is_equal_approx(before[i])
	_assert(same, "boss dead, 6 summons: positions must not change")
	await _free(c)

	# 5. Death seen live (play_death), juice on: the adds slide (not there yet, rest_pos already the target),
	#    then arrive within REGROUP_SEC.
	CombatView.disable_juice_for_tests = false
	c = await _build("elite", 3, false)
	st = c.stage
	en = c.enemies
	st.play_death(en[0])
	st.reseat_side(en, true)
	var target := st._slot_position(true, 0, 2)
	_assert(not _pos(st, en[1]).is_equal_approx(target), "animated: add 1 should not jump")
	_assert(((st._units[en[1]] as Dictionary)["rest_pos"] as Vector3).is_equal_approx(target), "animated: rest_pos is the target")
	await get_tree().create_timer(CombatStage3D.REGROUP_SEC + 0.15).timeout
	_expect_pattern(st, [en[1], en[2]], "animated, after the slide")
	await _free(c)

	# 5b. Slide in flight (animate = true), then the add lunges: the lunge kills the slide, starts from the new
	#     rest_pos, and the add ends on the pattern slot (not dragged back by the slide).
	c = await _build("elite", 3, false)
	st = c.stage
	en = c.enemies
	st.play_death(en[0])
	st.reseat_side(en, true)
	var e1: Dictionary = st._units[en[1]]
	var rg = e1.get("regroup_tween")
	_assert(rg is Tween and (rg as Tween).is_valid() and (rg as Tween).is_running(), "animate: the regroup tween runs")
	await get_tree().create_timer(CombatStage3D.REGROUP_SEC * 0.4).timeout
	_assert(not _pos(st, en[1]).is_equal_approx(st._slot_position(true, 0, 2)), "animate: add 1 mid-slide")
	st.play_action(en[1], "dmg", 1)
	_assert(not ((rg as Tween).is_valid() and (rg as Tween).is_running()), "lunge: the regroup tween is killed")
	_assert(e1.get("regroup_tween") == null, "lunge: regroup_tween cleared")
	await get_tree().create_timer(CombatStage3D.action_motion_duration() + 0.2).timeout
	_expect_pattern(st, [en[1], en[2]], "slide then lunge")
	# _stop_action_motion also stops a slide: start one, stop, the slot is on rest_pos at once.
	st._units[en[2]]["rest_pos"] = Vector3(9, 0, 9)
	var tw2 := st.create_tween()
	tw2.tween_property((st._units[en[2]] as Dictionary)["slot"], "position", Vector3(0, 0, 0), 1.0)
	st._units[en[2]]["regroup_tween"] = tw2
	st._stop_action_motion(st._units[en[2]])
	_assert(not tw2.is_valid() or not tw2.is_running(), "stop_action_motion kills the slide")
	_assert(_pos(st, en[2]).is_equal_approx(Vector3(9, 0, 9)), "stop_action_motion: slot on rest_pos")
	await _free(c)

	# 6. Same, Reduce motion on: instant.
	MetaState.reduce_motion = true
	c = await _build("elite", 3, false)
	st = c.stage
	en = c.enemies
	st.play_death(en[0])
	st.reseat_side(en, true)
	_expect_pattern(st, [en[1], en[2]], "reduce motion")
	await _free(c)

	CombatView.disable_juice_for_tests = saved_juice
	MetaState.reduce_motion = saved_rm
	print("=== t_ui5_lead_regroup: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	if _fails.is_empty():
		print("t_ui5_lead_regroup: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_ui5_lead_regroup: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)


func _pos(st: CombatStage3D, uid: int) -> Vector3:
	return ((st._units[uid] as Dictionary)["slot"] as Node3D).position


func _build(kind: String, n_enemy: int, boss: bool) -> Dictionary:
	var stage: CombatStage3D = load("res://scenes/shared/CombatStage3D.tscn").instantiate()
	add_child(stage)
	stage.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stage.size = CANVAS
	await get_tree().process_frame
	var band := CombatView.stage_band(CANVAS.y)
	stage.frame_band(CANVAS.y, band.x, band.y)
	stage.set_encounter_kind(kind)
	stage.set_arena("savannah", boss)
	var party: Array = []
	var enemies: Array = []
	var uid := 1
	for i in 5:
		stage.spawn_unit(uid, ["plant", "beast", "aqua", "reptile", "bug"][i], false, i, 5)
		party.append(uid)
		uid += 1
	for i in n_enemy:
		var is_boss := boss and i == 0
		stage.spawn_unit(uid, "", true, i, n_enemy, is_boss, "gooey_king" if is_boss else KEYS[i % KEYS.size()], "", boss and not is_boss)
		enemies.append(uid)
		uid += 1
	stage.reseat_side(party, false)
	stage.reseat_side(enemies, true)
	for _i in 2:
		await get_tree().process_frame
	return {"stage": stage, "party": party, "enemies": enemies}


func _free(c: Dictionary) -> void:
	(c.stage as Node).queue_free()
	await get_tree().process_frame


func _expect_pattern(st: CombatStage3D, adds: Array, label: String) -> void:
	for i in adds.size():
		var want := st._slot_position(true, i, adds.size())
		var got := _pos(st, adds[i])
		_assert(got.is_equal_approx(want), "%s: add %d at %s, want %s" % [label, i, got, want])
		_assert(((st._units[adds[i]] as Dictionary)["rest_pos"] as Vector3).is_equal_approx(want), "%s: add %d rest_pos" % [label, i])


func _expect_clear(st: CombatStage3D, adds: Array, label: String) -> void:
	var card_top := TrayColumn.card_top(CANVAS.y)
	for u in adds:
		var r: Rect2 = st.unit_screen_rect(int(u))
		_assert(r.size.x > 0.0, "%s: add %d has no screen rect" % [label, u])
		_assert(r.end.y <= card_top, "%s: add %d runs into the DieCards %s (card top %.0f)" % [label, u, r, card_top])
		_assert(r.end.x <= PANEL_X - 8.0, "%s: add %d under the enemy plate column %s" % [label, u, r])
