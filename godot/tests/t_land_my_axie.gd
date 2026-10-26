extends Node
## LD-A 2: Land Axies come from preset 0, deduped; light mode = 2.
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
	print("=== t_land_my_axie: start ===")
	_guard.capture()
	MetaState.land_gift_granted = true
	MetaState.team_presets = [{"name": "A", "party": ["plant1", "beast1", "plant1", "aqua1", ""]}]
	var k := LandAxies.pick_keys(5)
	_check(k == ["plant1", "beast1", "aqua1"], "preset 0, no duplicates: %s" % [k])
	_check(LandAxies.pick_keys(2).size() == 2, "limit respected")
	_check(LandAxies.descriptor_for("plant1") != null, "descriptor from hero key")
	_check(LandAxies.descriptor_for("nope") == null, "unknown key -> null")
	MetaState.team_presets = []
	_check(LandAxies.pick_keys(5).is_empty(), "no preset -> random fallback")
	MetaState.team_presets = [{"name": "A", "party": ["plant1", "beast1"]}]
	LandQuality.force_light = 0
	var h := await _land()
	_check((h.get("_axies") as Array).size() == 5, "5 Axies on desktop")
	_check((h.get("_wander_keys") as Array).size() == 2, "2 are the player's own")
	h.queue_free()
	await get_tree().process_frame
	LandQuality.force_light = 1
	var h2 := await _land()
	_check((h2.get("_axies") as Array).size() == 2, "light mode: 2 Axies")
	h2.queue_free()
	LandHub.qa = {}
	LandNav.dry_run = false
	LandQuality.force_light = -1
	_guard.restore()
	if _fails.is_empty():
		print("PASS: t_land_my_axie (%d checks)" % _checks)
		get_tree().quit(0)
	else:
		printerr("FAIL: t_land_my_axie ", _fails)
		get_tree().quit(1)
