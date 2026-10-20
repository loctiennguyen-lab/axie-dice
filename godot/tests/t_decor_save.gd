extends Node
## Land v1: 3 raw decor fields round-trip through SaveStore + reload_from_store (spec land-v1-spec.md §3).

func _ready() -> void:
	var guard := SaveGuard.new()
	guard.capture()
	var fails := 0
	MetaState.reload_from_store()
	MetaState.land_decor_owned = {"decor_sav_tree": 3}
	MetaState.land_decor_placed = [{"id": "decor_sav_tree", "x": 1.5, "z": -2.0, "rot": 3}]
	MetaState.land_milestones_claimed = ["m1"]
	MetaState.save_to_disk()
	MetaState.land_decor_owned = {}
	MetaState.land_decor_placed = []
	MetaState.land_milestones_claimed.clear()
	MetaState.reload_from_store()
	if int(MetaState.land_decor_owned.get("decor_sav_tree", 0)) != 3:
		print("FAIL owned"); fails += 1
	if MetaState.land_decor_placed.size() != 1 or int(MetaState.land_decor_placed[0]["rot"]) != 3 \
			or not is_equal_approx(float(MetaState.land_decor_placed[0]["x"]), 1.5):
		print("FAIL placed"); fails += 1
	if MetaState.land_milestones_claimed != ["m1"]:
		print("FAIL milestones"); fails += 1
	# Sign-out style reset: a blank profile must not keep the previous player's decor.
	SaveStore.write_text(MetaState.SAVE_PATH, "{}")
	MetaState.reload_from_store()
	if not MetaState.land_decor_placed.is_empty() or not MetaState.land_decor_owned.is_empty() \
			or not MetaState.land_milestones_claimed.is_empty():
		print("FAIL reset"); fails += 1
	guard.restore()
	print("t_decor_save: %s" % ("PASS" if fails == 0 else "FAIL"))
	get_tree().quit(1 if fails else 0)
