extends Node
## R3 M15 Land upgrade: MetaState.land_tier persistence, upgrade_land() (ledgered, one tier per
## call, refuses short / max / switched off), presets slots follow the tier, the screen states.

const Eco := preload("res://scripts/meta/economy_db.gd")
var _fail: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_checks += 1
	if not c:
		_fail.append(msg)


func _switch(on: bool) -> void:
	Eco.get_table("land_tiers")["upgrade_enabled"] = on


func _reset() -> void:
	MetaState.land_tier = 1
	MetaState.stone = 0
	MetaState.ledger = []


func _screen() -> LandUpgradeScreen:
	var s: LandUpgradeScreen = load("res://scenes/land_upgrade/LandUpgrade.tscn").instantiate()
	s.no_scene_change = true
	add_child(s)
	await get_tree().process_frame
	return s


func _ready() -> void:
	print("=== t_land_upgrade: start ===")
	_guard.capture()
	Eco.clear_cache()
	TeamPresets.tier_override = 0
	_reset()
	_ok(Eco.land_max_tier() == 6, "max tier 6")
	_ok(Eco.land_tier_cost(1) == 40000 and Eco.land_tier_cost(5) == 1000000 and Eco.land_tier_cost(6) == -1, "costs from data")
	_ok(Eco.land_upgrade_enabled(), "L1 default: upgrade live")
	_switch(false)

	# switched off in data: nothing moves even with plenty of Stone
	MetaState.stone = 5000000
	_ok(not MetaState.upgrade_land(false) and MetaState.land_tier == 1 and MetaState.stone == 5000000, "off in data -> refused")
	_switch(true)

	# short
	MetaState.stone = 39999
	_ok(not MetaState.upgrade_land(false) and MetaState.land_tier == 1 and MetaState.stone == 39999 and MetaState.ledger.is_empty(), "short by 1 -> refused, nothing spent")

	# exact cost
	MetaState.stone = 40000
	_ok(MetaState.upgrade_land(false), "exact cost upgrades")
	_ok(MetaState.land_tier == 2 and MetaState.stone == 0, "tier 2, stone 0")
	var last: Dictionary = MetaState.ledger.back()
	_ok(last["c"] == "stone" and int(last["d"]) == -40000 and String(last["r"]) == "land_tier_2" and int(last["b"]) == 0, "ledger row")
	_ok(not MetaState.upgrade_land(false) and MetaState.land_tier == 2, "second call with 0 stone refused (no double tier)")

	# one tier per call even with a lot of Stone
	MetaState.stone = 1000000
	_ok(MetaState.upgrade_land(false) and MetaState.land_tier == 3 and MetaState.stone == 900000, "one tier per call")

	# presets slots follow the tier
	_ok(TeamPresets.slot_count() == 9, "tier 3 -> 9 slots")
	MetaState.land_tier = 2
	_ok(TeamPresets.slot_count() == 6, "tier 2 -> 6 slots")
	MetaState.land_tier = 1
	_ok(TeamPresets.slot_count() == 3, "tier 1 -> 3 slots")

	# walk to max, total matches the design (1,820,000), then refuses
	_reset()
	MetaState.stone = 1820000
	var n := 0
	while MetaState.upgrade_land(false):
		n += 1
	_ok(n == 5 and MetaState.land_tier == 6 and MetaState.stone == 0, "five upgrades to LunaLanding spend exactly 1,820,000")
	MetaState.stone = 99999999
	_ok(not MetaState.upgrade_land(false) and MetaState.land_tier == 6 and MetaState.stone == 99999999, "max tier refuses")

	# persistence: save, wipe, reload
	MetaState.land_tier = 4
	MetaState.save_to_disk()
	MetaState.land_tier = 1
	MetaState.reload_from_store()
	_ok(MetaState.land_tier == 4, "land_tier survives reload_from_store")

	# screen
	_reset()
	MetaState.stone = 3860
	_switch(false)
	var s := await _screen()
	_ok(s.find_child("Tier6", true, false) != null, "six rows")
	_ok((s.find_child("Btn", true, false) as Button).disabled, "L1: buttons disabled")
	var texts: Array[String] = []
	for r in 6:
		texts.append((s.find_child("Tier%d" % (r + 1), true, false).find_child("Btn", true, false) as Button).text)
	_ok(texts[1] == "Not in this build" and texts[5] == "Not in this build", "L1 words: Not in this build")
	s.queue_free()
	await get_tree().process_frame

	_switch(true)
	MetaState.stone = 41200
	s = await _screen()
	var b2 := s.find_child("Tier2", true, false).find_child("Btn", true, false) as Button
	_ok(not b2.disabled and b2.text == "Upgrade", "can afford: Upgrade enabled")
	_ok((s.find_child("Tier3", true, false).find_child("Btn", true, false) as Button).disabled, "tier 3 not reachable yet")
	b2.pressed.emit()
	await get_tree().process_frame
	_ok(s.find_child("ConfirmPlate", true, false) != null, "confirm shown")
	_ok(s.confirm_upgrade() and MetaState.land_tier == 2 and MetaState.stone == 1200, "confirm upgrades")
	await get_tree().process_frame
	_ok(s.find_child("Toast", true, false) != null, "toast")
	_ok((s.find_child("Tier3", true, false).find_child("Btn", true, false) as Button).text.begins_with("Need"), "tier 3 shows shortfall")
	MetaState.land_tier = 6
	s.call("_redraw")
	await get_tree().process_frame
	_ok(s.find_child("MaxNote", true, false) != null, "max tier note")
	s.queue_free()

	_ok(LandNav.resolve(&"land_upgrade") == "res://scenes/land_upgrade/LandUpgrade.tscn", "LandNav land_upgrade")

	Eco.clear_cache()
	_guard.restore()
	for m in _fail:
		print("FAIL: ", m)
	if _fail.is_empty():
		print("PASS: t_land_upgrade (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		get_tree().quit(1)
