extends Node
## B12: equip ownership rules, save/reload, pool ids -> art, equip is cosmetic only, Profile screen.

var _fail := 0
var _n := 0
var _save_guard := SaveGuard.new()


func _ok(c: bool, msg: String) -> void:
	_n += 1
	if not c:
		_fail += 1
		print("FAIL: ", msg)


func _ready() -> void:
	_save_guard.capture()
	await _run()
	_save_guard.restore()
	print("t_cosmetics_equip: %d checks, %d failed" % [_n, _fail])
	print("PASS" if _fail == 0 else "FAIL")
	get_tree().quit(1 if _fail > 0 else 0)


func _run() -> void:
	# pool ids all resolve to art (every rarity, every id)
	var box: Dictionary = load("res://scripts/meta/economy_db.gd").get_table("echobox")["boxes"]["normal"]
	var seen := {}
	for r in box["pool"]:
		for id in EchoBox.pool_ids(box, r):
			var a := Cosmetics.art_id(String(id))
			_ok(a != "" and CosmeticArt.has_art(a), "%s resolves (%s)" % [id, a])
			seen[a] = true
			var tier := ["common", "uncommon", "rare", "epic", "legendary", "mythic"].find(r)
			var m: Dictionary = CosmeticArt.manifest()
			var e: Dictionary = (m["dice"] as Dictionary).get(a, (m["frames"] as Dictionary).get(a, {}))
			_ok(int(e.get("tier", -1)) == tier, "%s art tier matches %s" % [id, r])
	_ok(seen.size() >= 30, "pool uses %d distinct art" % seen.size())
	_ok(Cosmetics.art_id("fx_c_leaf") == "" and Cosmetics.art_id("title:x") == "", "fx/title have no art")

	# equip rules
	MetaState.cosmetics_owned.clear()
	MetaState.equipped_die_skin = ""
	MetaState.equipped_frame = ""
	_ok(MetaState.equip_cosmetic("die_c_reed") != "", "cannot equip unowned")
	_ok(MetaState.equipped_die_skin == "", "unowned stays unequipped")
	MetaState.cosmetics_owned.append("die_c_reed")
	MetaState.cosmetics_owned.append("frame_u_vine")
	MetaState.cosmetics_owned.append("std_r_001")   # placeholder -> real art
	_ok(MetaState.equip_cosmetic("die_c_reed") == "", "equip owned die")
	_ok(MetaState.equip_cosmetic("frame_u_vine") == "", "equip owned frame")
	_ok(MetaState.equip_cosmetic("frame_c_plant") != "", "frame not owned")
	_ok(MetaState.equip_cosmetic("fx_c_leaf") != "" and MetaState.equip_cosmetic("std_r_001") != "", "fx / raw placeholder id not equippable")
	var rare_art := Cosmetics.art_id("std_r_001")
	_ok(MetaState.equip_cosmetic(rare_art) == "", "placeholder-owned art equippable: " + rare_art)
	# save / reload
	MetaState.reload_from_store()
	_ok(MetaState.equipped_frame == "frame_u_vine" and Cosmetics.slot_of(MetaState.equipped_die_skin) == "die", "equip survives reload")
	MetaState.cosmetics_owned.erase("frame_u_vine")
	MetaState.save_to_disk()
	MetaState.reload_from_store()
	_ok(MetaState.equipped_frame == "", "equipped but no longer owned -> none")
	MetaState.unequip_cosmetic("die")
	_ok(MetaState.equipped_die_skin == "", "unequip")

	# cosmetic only: no combat rule file mentions equip state or Cosmetics
	var rx := RegEx.create_from_string("\\b(equipped_[a-z_]*|Cosmetics|CosmeticArt|cosmetics_owned)\\b")
	var dir := DirAccess.open("res://scripts/core")
	var scanned := 0
	for f in dir.get_files():
		if f.ends_with(".gd"):
			scanned += 1
			_ok(rx.search(FileAccess.get_file_as_string("res://scripts/core/" + f)) == null, "core/%s has no cosmetic state" % f)
	_ok(scanned > 5, "scanned core")

	# Profile screen lists owned art and equips
	MetaState.cosmetics_owned.append("die_c_clay")
	var pv: ProfileView = load("res://scenes/profile/Profile.tscn").instantiate()
	pv.no_scene_change = true
	add_child(pv)
	await get_tree().process_frame
	var t := pv.find_child("Tile_die_c_clay", true, false)
	_ok(t != null, "Profile shows owned skin tile")
	if t != null:
		(t.find_child("Equip", true, false) as Button).pressed.emit()
		_ok(MetaState.equipped_die_skin == "die_c_clay", "Profile equip button equips")
	pv.queue_free()
