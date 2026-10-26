extends Node
## Depth v3 lane D: Plating on the foe (ARM chip, "4 -> 1" preview, coach line, "Plating off" state).
var _guard := SaveGuard.new()
var _checks := 0
var _fails: Array[String] = []

func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)

func _ready() -> void:
	CombatView.disable_juice_for_tests = true
	_guard.capture()
	RunState.start_new_run(424243, ["plant1", "beast1", "aqua1", "reptile1", "bug1"] as Array[String], "short", 6, false)
	await get_tree().process_frame
	# Pure chip list.
	var it := StatusHeads.items_for(0, {}, false, 3, 0, "4 → 1")
	_check(it.size() == 2 and it[0][0] == "preview" and it[1][0] == "plating" and int(it[1][1]) == 3, "items: preview first, then plating")
	_check(StatusHeads.items_for(0, {}, false, 0, 2)[0][0] == "plating_off", "plating off chip while switched off")
	_check(StatusHeads.items_for(0, {}).is_empty(), "no plating, no chip")
	RunState.power_level = 6
	RunState.enter_node("r2_c0", "battle")
	var v: Node = (load("res://scenes/combat/Combat.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(v)
	for _i in 60:
		await get_tree().process_frame
	v._land_dice_now()
	var c: CombatEngine = v._combat
	var e: Unit = c.enemies[0]
	e.plating = 3
	e.plating_off = 0
	var u: Unit = v._party_dice_units()[0]
	u.die[0] = {"type": "dmg", "value": 4, "keywords": []}
	u.set_roll(0, false)
	_check(CombatTraits.plating_of(c, e) == 3, "engine reads plating 3")
	_check(v._plating_preview(e) == "", "no die picked: no preview")
	v._selected_die_uid = u.uid
	_check(v._plating_preview(e) == "4 → 1", "picked 4-dmg die on Plating 3 previews 4 → 1 (got '%s')" % v._plating_preview(e))
	u.die[0] = {"type": "dmg", "value": 4, "keywords": ["pierce"]}
	u.die[0] = {"type": "dmg", "value": 4, "keywords": ["pierce"]}
	_check(v._plating_preview(e) == "", "pierce face: no preview")
	u.die[0] = {"type": "dmg", "value": 4, "keywords": []}
	# Coach only for newcomers.
	c.newcomer = true
	_check(String(v._foe_state().get("coach", "")) != "", "newcomer sees the Plating coach line")
	c.newcomer = false
	_check(not v._foe_state().has("coach"), "non-newcomer: no coach")
	# Break event flips the chip and stops the coach.
	c.newcomer = true
	e.plating_off = 2
	v._on_plating_off(e.uid, 2)
	await get_tree().process_frame
	_check(not v._foe_state().has("coach"), "coach stops once a Plating was broken")
	v._layout_status_heads(Vector2.ZERO)
	_check(CombatTraits.plating_of(c, e) == 0, "off: effective plating 0")
	v.queue_free()
	_guard.restore()
	for f in _fails:
		print("t_depthv3_plating_ui: FAIL — %s" % f)
	if _fails.is_empty():
		print("t_depthv3_plating_ui: PASS — %d checks OK" % _checks)
	get_tree().quit(0 if _fails.is_empty() else 1)
