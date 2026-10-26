extends Node
## Gate for the beta prelude fields in MetaState (production/beta-plan.md "Prelude"):
## land_tier_banner_seen, land_gift_granted, mission_unlock_cache.
##
## Each one must survive save -> reload_from_store() (the path a sign-in or a cloud-save apply takes),
## and a fresh account must start clean. A field that is saved but not reset in reload_from_store()
## leaks the previous player's state into the next account.
##
## Run: godot --headless --path godot res://tests/t_meta_fields_beta.tscn

var _failures: Array[String] = []
var _checks := 0
var _save_guard := SaveGuard.new()


func _ready() -> void:
	print("=== t_meta_fields_beta: start ===")
	_save_guard.capture()

	test_meta_beta_fields_survive_save_and_reload()
	test_meta_land_gift_granted_only_once()
	test_meta_beta_fields_reset_for_empty_save()

	_save_guard.restore()
	MetaState.reload_from_store()
	print("=== t_meta_fields_beta: %d checks, %d failure(s) ===" % [_checks, _failures.size()])
	if _failures.is_empty():
		print("t_meta_fields_beta: PASS — %d checks OK" % _checks)
		get_tree().quit(0)
		return
	for f in _failures:
		print("t_meta_fields_beta: FAIL — %s" % f)
	get_tree().quit(1)


func _check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func test_meta_beta_fields_survive_save_and_reload() -> void:
	# Arrange (banner_seen never loads ahead of the owned tier, so own tier 2 first)
	MetaState.land_tier = 2
	MetaState.land_tier_banner_seen = 2
	MetaState.land_gift_granted = true
	MetaState.set_mission_unlocks(["N1", "N2", "N2"], false)
	# Act
	MetaState.save_to_disk()
	MetaState.reload_from_store()
	# Assert
	_check(MetaState.land_tier_banner_seen == 2, "land_tier_banner_seen lost on reload (got %d)" % MetaState.land_tier_banner_seen)
	_check(MetaState.land_gift_granted, "land_gift_granted lost on reload")
	_check(MetaState.mission_unlock_cache == ["N1", "N2"], "mission_unlock_cache wrong after reload: %s" % str(MetaState.mission_unlock_cache))
	# A save whose banner is ahead of the owned tier (hand-edited / bad cloud copy) is pulled back to the tier.
	MetaState.land_tier = 1
	MetaState.land_tier_banner_seen = 3
	MetaState.save_to_disk()
	MetaState.reload_from_store()
	_check(MetaState.land_tier_banner_seen == 1, "banner_seen ahead of land_tier was not clamped (got %d)" % MetaState.land_tier_banner_seen)


func test_meta_land_gift_granted_only_once() -> void:
	# Arrange
	MetaState.land_gift_granted = false
	MetaState.land_decor_owned = {}
	# Act
	var empty_id: bool = MetaState.grant_land_gift_once([""], false)
	var flag_after_empty: bool = MetaState.land_gift_granted
	var first: bool = MetaState.grant_land_gift_once(["decor_test_gift", "decor_test_b"], false)
	var second: bool = MetaState.grant_land_gift_once(["decor_test_gift"], false)
	# Assert
	_check(first, "first grant_land_gift_once returned false")
	_check(not second, "second grant_land_gift_once returned true")
	_check(not empty_id, "grant_land_gift_once accepted an empty id")
	_check(not flag_after_empty, "an empty gift call burned the one-time flag")
	_check(int(MetaState.land_decor_owned.get("decor_test_gift", 0)) == 1,
		"gift granted %d times, expected 1" % int(MetaState.land_decor_owned.get("decor_test_gift", 0)))
	_check(int(MetaState.land_decor_owned.get("decor_test_b", 0)) == 1, "second id of the gift was not granted")


func test_meta_beta_fields_reset_for_empty_save() -> void:
	# Arrange: a save with the beta fields set, then an empty save (a brand-new account)
	MetaState.land_tier_banner_seen = 3
	MetaState.land_gift_granted = true
	MetaState.set_mission_unlocks(["N1"], false)
	MetaState.save_to_disk()
	SaveStore.write_text(MetaState.SAVE_PATH, "")
	# Act
	MetaState.reload_from_store()
	# Assert
	_check(MetaState.land_tier_banner_seen == 1, "land_tier_banner_seen leaked into empty save (got %d)" % MetaState.land_tier_banner_seen)
	_check(not MetaState.land_gift_granted, "land_gift_granted leaked into empty save")
	_check(MetaState.mission_unlock_cache.is_empty(), "mission_unlock_cache leaked into empty save")
