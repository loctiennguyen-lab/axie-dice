extends Node
## Depth v3 combat HUD (lane D): Hold button calls `stash`, reroll price text, FRONT/BACK strip,
## boss rhythm card, Elite affix chip. Spec: design/ux/depth-v3/combat-hud.md

var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _open(kind: String, node_id: String, pw: int, affix: String) -> Node:
	RunState.power_level = pw
	RunState.enter_node(node_id, kind)
	if affix != "":
		RunState.pending_combat["affix"] = affix
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 60:
		await get_tree().process_frame
	v._land_dice_now()
	return v

func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	RunState.start_new_run(424242, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	await get_tree().process_frame
	var v: Node = await _open("elite", "r5_c0", 4, "shell")
	var c: CombatEngine = v._combat
	var hud: CombatHud = v._hud_frame
	# Hold button: disabled with a reason until a die is picked, then it stashes.
	_check(hud.hold_button != null and hud.hold_button.disabled and hud.hold_button.text.contains("pick"), "hold disabled says why")
	var u: Unit = v._party_dice_units()[0]
	u.die[0] = {"type": "dmg", "value": 3, "keywords": []}
	u.set_roll(0, false)
	v._selected_die_uid = u.uid
	v._rebuild_all()
	_check(not hud.hold_button.disabled, "hold enabled with a legal die picked")
	hud.hold_button.pressed.emit()
	await get_tree().process_frame
	_check(c.stash_count() == 1 and c.by_uid(u.uid).held, "Hold button -> engine stash")
	_check(hud.hold_button.text.begins_with("Holding"), "full hold shows Holding n/cap")
	# Reroll price once the free charge is gone.
	c.rerolls = 0
	c.mana = 3
	v._rebuild_all()
	var rr_chip := hud.reroll_button.find_child("CostChip", true, false) as Control
	_check(hud.reroll_button.text == "Reroll" and rr_chip != null and rr_chip.visible \
		and (rr_chip.find_child("Amount", true, false) as Label).text == str(c.reroll_mana_cost()) and not hud.reroll_button.disabled,
		"paid reroll shows its mana price on the CostChip (UI-05)")
	c.mana = 0
	v._rebuild_all()
	_check(hud.reroll_button.disabled and hud.reroll_button.text.contains("need"), "no mana: disabled with reason")
	# Row strip + affix chip.
	_check(v._row_strip != null and v._row_strip.get_child_count() >= 2, "FRONT/BACK strip exists")
	_check(hud.get_node("FoeCard").visible and hud.get_node("FoeCard").find_child("AffixRow", true, false) != null, "affix chip on elite")
	v.queue_free()
	await get_tree().process_frame
	# Boss rhythm card.
	v = await _open("boss", "r6_c0", 6, "")
	hud = v._hud_frame
	var card: Control = hud.get_node("FoeCard")
	_check(card.visible and card.find_child("RhythmChips", true, false) != null, "boss rhythm chips")
	_check(card.find_child("Phase_prep", true, false) != null and card.find_child("Phase_hollow", true, false) != null, "3 phase chips")
	v.queue_free()
	_guard.restore()
	for f in _fails:
		print("t_depthv3_combat_ui: FAIL — %s" % f)
	if _fails.is_empty():
		print("t_depthv3_combat_ui: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
