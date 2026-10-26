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
	MetaState.ledger = []
	var s: LandUpgradeScreen = load("res://scenes/land_upgrade/LandUpgrade.tscn").instantiate()
	s.no_scene_change = true
	add_child(s)
	await get_tree().process_frame
	_check(String(LandUpgradeScreen.ADDS[2]).contains("Rare"), "ADDS tier 2 names the Rare decor")
	_check(s.confirm_upgrade(2) and MetaState.land_tier == 2, "upgrade to tier 2")
	_check(MetaState.stone == 0 and MetaState.ledger.size() == 1, "Stone spent exactly once")
	_check(not s.confirm_upgrade(2) and MetaState.land_tier == 2 and MetaState.stone == 0, "second confirm refused, nothing spent")
	_check(s.find_child("Toast", true, false) != null and (s.find_child("Toast", true, false) as Label).text.begins_with("Your Land is now"), "no error toast after double press")
	# The back_to_land() branch is skipped under no_scene_change (the screen is a child node here);
	# LandNav.back_to_land itself is covered by t_land_nav (dry_run).
	s.queue_free()
	var h := await _land()
	_check(int(h.get("_tier")) == 2, "Land opens on tier 2 with no reload")
	var chip := h.find_child("UpgradeLand", true, false)
	_check(chip != null, "chip opens the upgrade screen")
	_check(h.find_child("TierBanner", true, false) != null, "banner after the upgrade")
	var okb := h.find_child("TierBannerOk", true, false) as Button
	await get_tree().process_frame
	_check(okb != null and okb.has_focus(), "banner button has keyboard focus")
	h.call("_close_modal")
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
