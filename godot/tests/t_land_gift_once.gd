extends Node
## LD-A 3: starter decor granted once, survives save/load, Profile shows Land section.
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
	print("=== t_land_gift_once: start ===")
	_guard.capture()
	MetaState.land_gift_granted = true
	MetaState.land_gift_granted = false
	MetaState.land_decor_owned = {}
	var h := await _land()
	for id in LandAxies.GIFT_DECOR:
		_check(int(MetaState.land_decor_owned.get(id, 0)) == 1 and LandDecor.def(id).size() > 0, "gift " + id)
	_check(MetaState.land_gift_granted, "flag set")
	h.queue_free()
	await get_tree().process_frame
	MetaState.save_to_disk()
	MetaState.reload_from_store()
	_check(MetaState.land_gift_granted, "flag survives save/load")
	var h2 := await _land()
	_check(int(MetaState.land_decor_owned.get("decor_sav_tree2", 0)) == 1, "not granted twice")
	h2.queue_free()
	var p: ProfileView = load("res://scenes/profile/Profile.tscn").instantiate()
	p.no_scene_change = true
	add_child(p)
	await get_tree().process_frame
	_check(p.find_child("LandSection", true, false) != null, "Profile has a Land section")
	_check(p.find_child("LandTier", true, false) != null and p.find_child("LandScore", true, false) != null, "tier + score rows")
	LandHub.qa = {}
	LandNav.dry_run = false
	LandQuality.force_light = -1
	_guard.restore()
	if _fails.is_empty():
		print("PASS: t_land_gift_once (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		printerr("FAIL: t_land_gift_once ", _fails)
		get_tree().quit(1)
