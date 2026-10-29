extends Node
## v5 real flow: Resonance Shell on Elite (stage 2+), coach C8 once, off-SET dmg halved on the Shell + float, SET dmg full.
## Path: real RunMap scene + RunState.enter_node (the elite row is not reachable from row 0, so the node is entered through
## the same RunState call the map button makes) -> real Combat scene.

const TEAM: Array[String] = ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
var _fail := 0
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail += 1
		print("FAIL: ", msg)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _fight(stage: int, kind: String) -> Node:
	print("step: fight stage ", stage, " ", kind)
	RunState.start_run_with_epoch(LocalEpochSource.new(PackedByteArray(), 707), {"team_keys": TEAM, "mode": "short",
		"ascension": 0, "ranked": false, "anchor": false, "depth_stage": stage, "loadout": {"rules_on": false}}, 707)
	RunState.depth_stage = stage
	var rm: Node = load("res://scenes/run_map/RunMap.tscn").instantiate()
	add_child(rm)
	await _frames(6)
	print("step: map up")
	RunState.set_phase(RunState.RunPhase.MAP)
	rm.free()   # RunMap listens to node_entered and would change_scene away from this test
	await _frames(2)
	RunState.enter_node("r1_c0", kind)
	print("step: entered node, loading combat")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	add_child(v)
	await _frames(40)
	print("step: combat up")
	return v


func _shell_plate(v: Node, e: Unit) -> UnitPortrait:
	v._update_portrait(e)
	return v._portraits.get(e.uid) as UnitPortrait


func _ready() -> void:
	print("=== t_v5_flow_shell: start ===")
	_guard.capture()
	CombatView.disable_juice_for_tests = true
	ProjectSettings.set_setting("axie/epoch_source", "local")
	V4Coach.reset_for_tests()
	V4Coach.enabled_in_tests = true
	# stage 1 elite: no Shell
	var v1 := await _fight(1, "elite")
	var e1: CombatEngine = v1._combat
	_ok(e1.kind == "elite", "stage1: elite fight")
	_ok(int(e1.enemies[0].custom_state.get("shell", 0)) == 0, "stage1: no Shell on the Elite")
	var p1 := _shell_plate(v1, e1.enemies[0])
	_ok(p1 != null and not p1.has_shell(), "stage1: no SHELL bar")
	_ok(v1.coach_shown_id != "C8", "stage1: no C8 coach")
	v1.free()
	# stage 2 elite
	var v := await _fight(2, "elite")
	var e: CombatEngine = v._combat
	var boss: Unit = e.enemies[0]
	var sh := int(boss.custom_state.get("shell", 0))
	_ok(sh > 0 and int(boss.custom_state.get("shell_max", 0)) == sh, "stage2: Elite has Shell (%d)" % sh)
	var p := _shell_plate(v, boss)
	_ok(p != null and p.has_shell(), "stage2: SHELL bar visible")
	var lbl := p.find_child("ShellValue", true, false) as Label if p != null else null
	_ok(lbl != null and lbl.text == "%d/%d" % [sh, sh], "plate label SHELL n/n: " + (lbl.text if lbl != null else "?"))
	_ok(v.coach_shown_id == "C8", "C8 coach shown first time (%s)" % v.coach_shown_id)
	boss.hp = 9999
	boss.max_hp = 9999
	var d5 := BoTestBase.face("dmg", 5)
	var got: Array = []
	var cb := func(_u, _s, _m, ab) -> void:
		if ab > 0:
			got.append(int(ab))
	EventBus.shell_changed.connect(cb)
	# one die outside any SET
	e.rerolls = 0
	BoTestBase.force(e, [0, 1, 2, 3, 4], [d5, d5, d5, d5, d5])
	e._snap_bo()
	e.use_die(e.party[0].uid, boss.uid)
	await _frames(4)
	var after1 := int(boss.custom_state.get("shell", 0))
	_ok(got.size() == 1 and got[0] > 0 and got[0] < 5, "off-SET die: Shell takes reduced hit %s" % str(got))
	_ok(after1 == sh - int(got[0] if got.size() > 0 else 0), "Shell value dropped by absorbed")
	_ok(v.shell_notes.size() == 1 and String(v.shell_notes[0]).contains("Outside a SET"), "float note: %s" % str(v.shell_notes))
	EventBus.shell_changed.disconnect(cb)
	v.free()
	# second Elite fight: C8 does not show again
	var v2 := await _fight(2, "elite")
	# SET of three
	var boss2: Unit = v2._combat.enemies[0]
	e = v2._combat
	v = v2
	boss2.hp = 9999
	boss2.max_hp = 9999
	got.clear()
	EventBus.shell_changed.connect(cb)
	boss2.custom_state["shell"] = 100   # a Shell big enough that three SET dice cannot empty it (the real one is 25% of a small Elite)
	boss2.custom_state["shell_max"] = 100
	var before2 := int(boss2.custom_state.get("shell", 0))
	boss = boss2
	e.rerolls = 0
	got.clear()
	BoTestBase.force(e, [1, 1, 1, 2, 3], [d5, d5, d5, d5, d5])
	e._snap_bo()
	_ok(not e.bo.is_empty(), "SET of 3 formed")
	for i in 3:
		var used := e.use_die(e.party[i].uid, boss.uid)
		print("step: use_die ", i, " -> ", used, " got ", got)
	await _frames(4)
	var lost2 := before2 - int(boss.custom_state.get("shell", 0))
	var sum_got := 0
	for g in got:
		sum_got += int(g)
	_ok(sum_got == lost2 and lost2 >= 15, "SET dice: Shell loses full value (%d, hits %s)" % [lost2, str(got)])
	_ok(v.shell_notes.is_empty(), "no off-SET float for SET dice")
	EventBus.shell_changed.disconnect(cb)
	_ok(v2.coach_shown_id != "C8", "C8 not shown 2nd time (%s)" % v2.coach_shown_id)
	_ok(V4Coach.seen("C8"), "C8 marked seen")
	v2.free()
	V4Coach.enabled_in_tests = false
	V4Coach.persist = true
	CombatView.disable_juice_for_tests = false
	_guard.restore()
	print("=== t_v5_flow_shell: %d checks, %d failure(s) ===" % [_checks, _fail])
	if _fail == 0:
		print("t_v5_flow_shell: PASS")
	get_tree().quit(0 if _fail == 0 else 1)
