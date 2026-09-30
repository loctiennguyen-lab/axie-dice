extends Node
## Reroll tray (scenes/combat/reroll_fx/) driven through the REAL Combat.tscn with juice ON —
## the one path every other combat test switches off. Checks the contract CombatView relies on:
##   · the tray opens, every rerolled die comes back exactly once, and it closes again
##   · each card's toss overlay hides the new face until that die's own cube has landed
##   · afterwards no overlay is left up, the input lock is released, and each card is back at
##     its resting transform
##   · R / the REROLL button during the tray skips it, and a skipped roll still ends clean
## Run: godot --headless --path godot tests/t_reroll_fx.tscn
## Optional: REROLL_FX_SHOTS=/some/dir (with a real display) saves a frame per stage.

var _tree: SceneTree
var _view: Node
var _anomaly := ""
var _returned: Array = []
var _shots := OS.get_environment("REROLL_FX_SHOTS")


func _ready() -> void:
	_tree = get_tree()
	CombatView.disable_juice_for_tests = false
	RunState.pending_combat = {
		"node_id": "reroll_fx_node", "kind": "battle", "pw": 2, "ascension": 0,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 424242,
	}
	_view = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(_view)
	for i in 10:
		await _tree.process_frame
	var combat: CombatEngine = _view.get("_combat")
	_check(combat != null, "no CombatEngine")
	if _anomaly != "":
		return _done()
	combat.rerolls = 2

	# ── run 1: full sequence ──
	var btns: Array = _view.get("_die_slot_buttons")
	var rest := {}
	for b in btns:
		rest[b] = [b.position, b.scale, b.rotation, b.modulate]
	_view.call("_on_reroll_pressed")
	var fx: RerollFX = _view.get("_reroll_fx")
	_check(fx != null, "reroll did not build the tray")
	if _anomaly != "":
		return _done()
	_check(bool(_view.get("_reroll_fx_active")), "tray not marked active after REROLL")
	fx.die_returned.connect(func(id, _f, _m): _returned.append(id))
	var expected: int = (_view.get("_reroll_fx_slot_by_uid") as Dictionary).size()
	_check(expected > 0, "no dice went into the tray")
	# every rerolled card hides its new face while the die is out
	await _until(func(): return fx._stage == "toss")
	await _frames(3)
	for uid in _view.get("_reroll_fx_slot_by_uid"):
		var ov: Control = _view.call("_reroll_overlay_at", _view.get("_reroll_fx_slot_by_uid")[uid])
		_check(ov != null and ov.visible, "card for uid %s shows its new face during the toss" % uid)
	_shot("1_toss")
	await _until(func(): return fx._teasing or fx._stage != "toss")
	await _frames(4)
	_shot("2_tease")
	await _until(func(): return fx._stage == "hold")
	_shot("3_locked")
	await _wait(0.6)
	_shot("4_stamp")
	await _until(func(): return fx._stage == "collect")
	await _frames(4)
	_shot("5_collect")
	await _until(func(): return not bool(_view.get("_reroll_fx_active")), 12.0)
	await _wait(0.6)
	_shot("6_done")
	_check(not bool(_view.get("_reroll_fx_active")), "tray never finished")
	_check(_returned.size() == expected, "returned %d of %d dice" % [_returned.size(), expected])
	_check(_unique(_returned), "a die came back twice")
	_after_checks(btns, rest, "run 1")
	print("t_reroll_fx: run 1 ok — %d dice, grade=%s" % [expected, fx._grade.get("text", "none")])

	# ── run 2: skip mid-toss via the REROLL button path ──
	if combat.rerolls > 0:
		_returned.clear()
		_view.call("_on_reroll_pressed")
		expected = (_view.get("_reroll_fx_slot_by_uid") as Dictionary).size()
		await _until(func(): return fx._stage == "toss")
		await _wait(0.25)
		_view.call("_on_reroll_pressed")   # = skip
		await _until(func(): return not bool(_view.get("_reroll_fx_active")), 8.0)
		await _wait(0.6)
		_check(_returned.size() == expected, "skip: returned %d of %d" % [_returned.size(), expected])
		_after_checks(btns, rest, "run 2 (skip)")
		print("t_reroll_fx: run 2 (skip) ok")
	_done()


func _after_checks(btns: Array, rest: Dictionary, label: String) -> void:
	for i in btns.size():
		var ov: Control = _view.call("_reroll_overlay_at", i)
		if ov != null:
			_check(not ov.visible, "%s: overlay %d still up" % [label, i])
		var b: Button = btns[i]
		if not b.visible:
			continue
		var r: Array = rest[b]
		_check((b.position - r[0]).length() < 0.5, "%s: card %d not back at rest (%s vs %s)" % [label, i, b.position, r[0]])
		_check((b.scale - r[1]).length() < 0.01 and absf(b.rotation - r[2]) < 0.01, "%s: card %d scale/rotation off" % [label, i])
		_check(absf(b.modulate.a - r[3].a) < 0.01 and absf(b.modulate.r - r[3].r) < 0.01, "%s: card %d modulate %s" % [label, i, b.modulate])


func _until(f: Callable, limit: float = 10.0) -> void:
	var t0 := Time.get_ticks_msec()
	while not f.call() and Time.get_ticks_msec() - t0 < limit * 1000.0:
		await _tree.process_frame


func _frames(n: int) -> void:
	for i in n:
		await _tree.process_frame


func _wait(sec: float) -> void:
	await _tree.create_timer(sec).timeout


func _unique(a: Array) -> bool:
	var seen := {}
	for x in a:
		if seen.has(x):
			return false
		seen[x] = true
	return true


func _shot(name: String) -> void:
	if _shots == "" or DisplayServer.get_name() == "headless":
		return
	_tree.root.get_texture().get_image().save_png("%s/%s.png" % [_shots, name])


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


func _done() -> void:
	if _anomaly != "":
		print("t_reroll_fx: FAIL — %s" % _anomaly)
		_tree.quit(1)
	else:
		print("t_reroll_fx: PASS — tray opened, every die returned once, cards restored, skip clean")
		_tree.quit(0)
