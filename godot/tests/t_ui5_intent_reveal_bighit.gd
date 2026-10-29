extends Node
## UI-05 b1 integration: every live enemy's IntentBlock is back at full alpha once the Your turn band and the intent
## reveal are over, also on a plate that turns big-hit (during the band or after it). The QA capture of
## 02-combat--bighit once showed the Bomblet intent missing and the Ravenling one faded: it was shot mid-reveal.
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []


func _t(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _alphas(v: CombatView) -> Array:
	var out: Array = []
	for e in v._combat.enemies:
		if e.hp <= 0:
			continue
		var p: UnitPortrait = v._portraits.get(e.uid)
		var blk := p.intent_block() if p != null else null
		out.append([e.n, blk.modulate.a if blk != null else -1.0, blk.is_visible_in_tree() if blk != null else false,
			p.is_big_hit() if p != null else false])
	return out


func _big(v: CombatView, idx: int) -> void:
	var ps: Array = []
	for e in v._combat.enemies:
		if e.hp > 0:
			ps.append(v._portraits.get(e.uid))
	if idx < ps.size():
		(ps[idx] as UnitPortrait).set_intent({"show": true, "type": "dmg", "num": 18, "label": "ATTACK", "target": "Olek",
			"big_hit": true})


func _ready() -> void:
	_guard.capture()
	await get_tree().process_frame
	var was_juice := CombatView.disable_juice_for_tests
	CombatView.disable_juice_for_tests = false
	MetaState.runs_with_battle = 99
	for case in ["after", "during"]:
		RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
		RunState.power_level = 3
		RunState.enter_node("r4_c0", "battle")
		var v: CombatView = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
		add_child(v)
		for _i in 5:
			await get_tree().process_frame
		if case == "during":
			_big(v, 1)   # the plate turns big-hit while the Your turn band still hides the intents
			var a0 := _alphas(v)
			_t(a0.size() >= 2 and float(a0[1][1]) < 0.01, "during the band the intents are hidden (%s)" % [a0])
		# band (~1 s) + reveal stagger + pop + the hider's 1 s restore
		await get_tree().create_timer(3.2).timeout
		if case == "after":
			_big(v, 1)
			v._rebuild_all()
			_big(v, 1)
			await get_tree().process_frame
		for row in _alphas(v):
			_t(float(row[1]) > 0.99 and bool(row[2]), "%s: %s intent block alpha %.2f visible %s (big hit %s)" % [case, row[0], row[1], row[2], row[3]])
		v.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	CombatView.disable_juice_for_tests = was_juice
	_guard.restore()
	if _fails.is_empty():
		print("t_ui5_intent_reveal_bighit: PASS - %d checks OK" % _checks)
		get_tree().quit(0)
	else:
		for f in _fails:
			print("t_ui5_intent_reveal_bighit: FAIL - " + f)
		get_tree().quit(1)
