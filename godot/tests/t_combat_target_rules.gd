extends Node
## UI target legality must match CombatEngine._do_face: dmg / poison / debuff aim at the opposite side,
## shield / heal / buff at the same side, mana / summon anywhere, blank nowhere. The enemy plate shows
## "Target · Name" only for a legal target and the red reason otherwise; clicking an illegal target keeps
## the die picked. Run: godot --headless --path godot res://tests/t_combat_target_rules.tscn

var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

const _FOE := ["dmg", "poison", "debuff"]
const _FRIEND := ["shield", "heal", "buff"]


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)


func _ready() -> void:
	var tree := get_tree()
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	print("=== t_combat_target_rules: start ===")
	_static_rules()
	await _view_rules(tree)
	_guard.restore()
	for f in _fails:
		print("t_combat_target_rules: FAIL — %s" % f)
	if _fails.is_empty():
		print("t_combat_target_rules: PASS — %d checks OK" % _checks)
	tree.quit(0 if _fails.is_empty() else 1)


func _static_rules() -> void:
	for t in _FOE:
		_check(CombatView.face_target_reason(t, "e") == "", "%s must be legal on an enemy" % t)
		_check(CombatView.face_target_reason(t, "p").contains("can only target enemies"), "%s must be illegal on an ally" % t)
	for t in _FRIEND:
		_check(CombatView.face_target_reason(t, "p") == "", "%s must be legal on an ally" % t)
		_check(CombatView.face_target_reason(t, "e").contains("can only target allies"), "%s must be illegal on an enemy" % t)
	for t in ["mana", "summon"]:
		_check(CombatView.face_target_reason(t, "p") == "" and CombatView.face_target_reason(t, "e") == "",
			"%s ignores the target side" % t)
	_check(CombatView.face_target_reason("blank", "e") != "" and CombatView.face_target_reason("blank", "p") != "",
		"blank is never usable")


func _view_rules(tree: SceneTree) -> void:
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"], "short", 6, false)
	await tree.process_frame
	RunState.power_level = 3
	RunState.enter_node("r4_c0", "battle")
	var view: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	tree.root.add_child(view)
	for _i in 60:
		await tree.process_frame
	view._land_dice_now()
	var combat: CombatEngine = view._combat
	var src: Unit = view._party_dice_units()[0]
	var cases := {"dmg": ["e", "p"], "poison": ["e", "p"], "debuff": ["e", "p"],
		"shield": ["p", "e"], "heal": ["p", "e"], "buff": ["p", "e"]}
	for t in cases:
		src.die[0] = {"type": t, "value": 3, "keywords": []}
		src.set_roll(0, false)
		view._selected_die_uid = src.uid
		view._rebuild_all()
		var legal_side: String = cases[t][0]
		for e in combat.enemies:
			var p: UnitPortrait = view._portraits[e.uid]
			var chip: String = p._chip_text.text
			if legal_side == "e":
				_check(chip.begins_with("Target") and p._lit, "%s: enemy %s should show Target label" % [t, e.n])
			else:
				_check(chip.contains("can only target allies") and not p._lit, "%s: enemy %s should show the reason" % [t, e.n])
		var foe: Unit = combat.enemies[0]
		var before: int = view._selected_die_uid
		if legal_side != "e":
			view._on_target_clicked(foe.uid)
			_check(view._selected_die_uid == before and not src.roll_used(), "%s: illegal click keeps the die picked" % t)
	view.queue_free()
	await tree.process_frame
