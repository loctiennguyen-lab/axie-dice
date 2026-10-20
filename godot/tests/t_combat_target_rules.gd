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
	# Depth v3: a new run opens on the Core offers; these tests are about the map flow, so skip them (test switch).
	RunState.start_run_with_epoch(LocalEpochSource.new(PackedByteArray(), 424242), {
		"team_keys": Array(["plant1", "beast1", "aqua1", "reptile1", "bug1"]), "mode": "short", "ascension": 6, "ranked": false,
		"loadout": {"core_off": true}}, 424242)
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
		var first_alive_uid := -1
		for fe in combat.enemies:
			if fe.hp > 0:
				first_alive_uid = fe.uid
				break
		for e in combat.enemies:
			var p: UnitPortrait = view._portraits[e.uid]
			var chip: String = p._chip_text.text
			if legal_side == "e":
				_check(chip.begins_with("Target") and p._lit, "%s: enemy %s should show Target label" % [t, e.n])
			else:
				# Depth v3 UX: ONE sibling (the first living unit of the side) carries the reason strip; the rest are only dimmed.
				if e.uid == first_alive_uid:
					_check(chip.contains("can only target allies") and not p._lit, "%s: enemy %s should show the reason" % [t, e.n])
				else:
					_check(not p._lit and not chip.begins_with("Target"), "%s: enemy %s is dimmed without a repeated reason" % [t, e.n])
		var foe: Unit = combat.enemies[0]
		var before: int = view._selected_die_uid
		if legal_side != "e":
			view._on_target_clicked(foe.uid)
			_check(view._selected_die_uid == before and not src.roll_used(), "%s: illegal click keeps the die picked" % t)
	# Engine agreement: the view's reason line must match what CombatEngine.use_die actually allows.
	var src_uid: int = src.uid
	var ally_uid: int = (combat.party[1] as Unit).uid
	var foe_uid: int = (combat.enemies[0] as Unit).uid
	for t in ["dmg", "poison", "debuff", "shield", "heal", "buff", "mana", "summon", "blank"]:
		for target in [{"uid": foe_uid, "side": "e"}, {"uid": ally_uid, "side": "p"}]:
			var su: Unit = combat.by_uid(src_uid)   # undo restores units, so re-fetch each time
			su.die[0] = {"type": t, "value": 3, "keywords": []}
			su.set_roll(0, false)
			var ok: bool = combat.use_die(src_uid, int(target["uid"]))
			var legal := CombatView.face_target_reason(t, String(target["side"])) == ""
			_check(ok == legal, "%s on %s: engine says %s, view says %s" % [t, target["side"], ok, legal])
			if ok:
				combat.undo_last()
	view.queue_free()
	await tree.process_frame
