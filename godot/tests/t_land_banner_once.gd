extends Node
## LD-A 1: the new-tier banner shows once per tier, survives save/load.
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
	print("=== t_land_banner_once: start ===")
	_guard.capture()
	MetaState.land_gift_granted = true
	MetaState.land_tier = 2
	MetaState.land_tier_banner_seen = 1
	var h := await _land()
	_check(h.find_child("TierBanner", true, false) != null, "banner shows on first visit to tier 2")
	_check(MetaState.land_tier_banner_seen == 2, "seen = 2")
	h.queue_free()
	await get_tree().process_frame
	MetaState.save_to_disk()
	MetaState.reload_from_store()
	_check(MetaState.land_tier_banner_seen == 2 and MetaState.land_tier == 2, "seen survives save/load")
	var h2 := await _land()
	_check(h2.find_child("TierBanner", true, false) == null, "no banner second time")
	h2.queue_free()
	MetaState.land_tier = 1
	MetaState.land_tier_banner_seen = 1
	var h3 := await _land()
	_check(h3.find_child("TierBanner", true, false) == null, "no banner on tier 1")
	h3.queue_free()
	LandHub.qa = {}
	LandNav.dry_run = false
	LandQuality.force_light = -1
	_guard.restore()
	if _fails.is_empty():
		print("PASS: t_land_banner_once (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		printerr("FAIL: t_land_banner_once ", _fails)
		get_tree().quit(1)
