extends Node
## A boss fight resumed from a save must draw its summons exactly like the live fight did (SUMMON_SCALE, no overlap
## with the wide-boss layout). The view rebuilds the whole board in _ready() on resume, so the "is a summon" decision
## cannot depend on spawn order. Run: godot --headless --path godot res://tests/t_boss_resume_summons.tscn

var _guard := SaveGuard.new()
var _fails: Array[String] = []
var _checks := 0


func _ready() -> void:
	_guard.capture()
	print("=== t_boss_resume_summons: start ===")
	CombatView.disable_juice_for_tests = true
	for n_adds in [2, 3]:
		await _case("gooey_king", n_adds)
	print("=== t_boss_resume_summons: %d checks, %d failure(s) ===" % [_checks, _fails.size()])
	_guard.restore()
	if _fails.is_empty():
		print("t_boss_resume_summons: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _fails:
		print("t_boss_resume_summons: FAIL — %s" % f)
	get_tree().quit(1)


func _assert(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_fails.append(msg)


func _roster() -> Array:
	var out: Array = []
	var keys := ["plant1", "beast1", "aqua1", "reptile1", "bug1"]
	for i in keys.size():
		out.append({"persistent_id": i + 1, "hero_key": keys[i], "tier": 1,
			"max_hp": ContentDB.heroes[keys[i]]["max_hp"], "muts": [], "growth": {}, "bonus_hp": 0})
	return out


func _scales(view: Node) -> Dictionary:
	var out: Dictionary = {}
	for e in view._combat.enemies:
		if not (e as Unit).is_boss:
			out[(e as Unit).uid] = float(((view._stage3d._units[(e as Unit).uid] as Dictionary)["visual"] as Node3D).scale.x)
	return out


func _case(boss_key: String, n_adds: int) -> void:
	var label := "%s + %d adds" % [boss_key, n_adds]
	RunState.pending_combat = {"node_id": "resume_boss", "kind": "boss", "pw": 8, "ascension": 0,
		"roster_snapshot": _roster(), "relic_ids": [], "combat_seed": 13579, "boss_key": boss_key}
	var live: Node = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(live)
	await get_tree().process_frame
	var boss: Unit = null
	for e in live._combat.enemies:
		if (e as Unit).is_boss:
			boss = e
	_assert(boss != null, "%s: no boss" % label)
	boss.custom_state["adds"] = ["slime"]
	for i in n_adds:
		live._combat.spawn_boss_add(boss, 1.0)
	for _i in 3:
		await get_tree().process_frame
	var live_scales := _scales(live)
	var snap: Dictionary = live._combat.to_data()
	live.queue_free()
	await get_tree().process_frame

	RunState.pending_combat = {}
	RunState.resume_combat = snap
	var resumed: Node = load("res://scenes/combat/Combat.tscn").instantiate()
	add_child(resumed)
	for _i in 4:
		await get_tree().process_frame
	var res_scales := _scales(resumed)
	_assert(res_scales.size() == n_adds, "%s: resumed fight has %d adds, expected %d" % [label, res_scales.size(), n_adds])
	# Reference: the same slime spawned as a plain (non-summon) enemy.
	resumed._stage3d.spawn_unit(99999, "", true, 0, 1, false, "slime", "", false)
	var full := float(((resumed._stage3d._units[99999] as Dictionary)["visual"] as Node3D).scale.x)
	for uid in res_scales:
		_assert(is_equal_approx(float(res_scales[uid]), full * CombatStage3D.SUMMON_SCALE),
			"%s: resumed add %d scale %s is not full size %s x SUMMON_SCALE" % [label, uid, res_scales[uid], full])
		_assert(live_scales.has(uid) and is_equal_approx(float(res_scales[uid]), float(live_scales[uid])),
			"%s: resumed add %d scale %s != live scale %s (summon lost SUMMON_SCALE on resume)" % [label, uid, res_scales[uid], live_scales.get(uid)])
	# (spacing of the summoned layout is t_combat_spacing's job; here the view's stage has no real frame.)
	resumed.queue_free()
	await get_tree().process_frame
