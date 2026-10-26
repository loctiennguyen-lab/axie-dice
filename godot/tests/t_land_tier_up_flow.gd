extends Node
## LD-A 1: upgrading to tier 2 lands on the new tier at once, with the 2 Rare decor listed.
var _fails: Array[String] = []
var _checks := 0
var _guard := SaveGuard.new()


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails.append(msg)
		printerr("FAIL: ", msg)


func _land() -> LandHub:
	MetaState.tutorial_seen = true
	LandNav.dry_run = true
	LandHub.qa = {"guest": false}
	var h := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate() as LandHub
	add_child(h)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	return h


func _ready() -> void:
	print("=== t_land_tier_up_flow: start ===")
	_guard.capture()
	MetaState.land_gift_granted = true
	MetaState.land_tier = 1
	MetaState.land_tier_banner_seen = 1
	MetaState.stone = 20000
	var s: LandUpgradeScreen = load("res://scenes/land_upgrade/LandUpgrade.tscn").instantiate()
	s.no_scene_change = true
	add_child(s)
	await get_tree().process_frame
	_check(String(LandUpgradeScreen.ADDS[2]).contains("Rare"), "ADDS tier 2 names the Rare decor")
	_check(s.confirm_upgrade(2) and MetaState.land_tier == 2, "upgrade to tier 2")
	s.queue_free()
	var h := await _land()
	_check(int(h.get("_tier")) == 2, "Land opens on tier 2 with no reload")
	var chip := h.find_child("UpgradeLand", true, false)
	_check(chip != null, "chip opens the upgrade screen")
	LandNav.last_path = ""
	h.call("_on_land_pressed")
	_check(LandNav.last_path.contains("land_upgrade"), "chip press goes to the upgrade screen")
	h.queue_free()
	LandHub.qa = {}
	LandNav.dry_run = false
	LandQuality.force_light = -1
	_guard.restore()
	if _fails.is_empty():
		print("PASS: t_land_tier_up_flow (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		printerr("FAIL: t_land_tier_up_flow ", _fails)
		get_tree().quit(1)
