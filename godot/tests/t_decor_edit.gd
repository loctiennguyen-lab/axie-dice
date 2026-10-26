extends Node
## Land v1: Edit Land mode in the real hub: enter/exit hides the hub, craft pays Shard, place/rotate/store persist,
## decor reappears on the next Land load, placement refusal explains why.
var _f: Array[String] = []
func _ok(c: bool, m: String) -> void:
	if not c:
		_f.append(m)
func _ready() -> void:
	var g := SaveGuard.new()
	g.capture()
	MetaState.reload_from_store()
	MetaState.tutorial_seen = true
	MetaState.land_tier = 2
	MetaState.land_tier_banner_seen = 2   # no banner modal in this test
	MetaState.shard_pool = 100
	var hub: LandHub = (load("res://scenes/land/Land.tscn") as PackedScene).instantiate()
	add_child(hub)
	await get_tree().process_frame
	var ed: LandEdit = hub.get("_edit")
	_ok(ed != null and not ed.active, "edit node exists, off")
	hub._handle_key(KEY_E)
	_ok(ed.active and ed.find_child("EditPanel", false, false) == null or ed.active, "E enters")
	_ok(not (hub.get("_hud_br") as Control).visible, "hub HUD hidden in edit mode")
	var tip := ed.get("_panel") as Control
	_ok(tip.visible, "panel visible")
	ed._craft("decor_sav_tree")
	_ok(MetaState.shard_pool == 60 and int(MetaState.land_decor_owned.get("decor_sav_tree", 0)) == 1, "craft pays 40 Shard")
	ed._craft("decor_arc_tree")
	_ok(MetaState.shard_pool == 60, "tier-locked craft refused")
	ed._pick_stored("decor_sav_tree")
	ed._place_new("decor_sav_tree", Vector3(0, 0, 0))   # inside the Portal zone
	_ok(MetaState.land_decor_placed.is_empty(), "blocked spot refused")
	var ctx: Dictionary = hub._decor_ctx()
	var spot := Vector3.INF
	var spot2 := Vector3.INF
	for gx in range(-13, 14):
		for gz in range(-13, 14):
			var c := Vector3(gx, 0, gz)
			if LandDecor.placement_block("decor_sav_tree", c, [], ctx, 2, MetaState.land_decor_owned) == "":
				if spot == Vector3.INF:
					spot = c
				elif spot2 == Vector3.INF and c.distance_to(spot) > 3.0:
					spot2 = c
	_ok(spot != Vector3.INF and spot2 != Vector3.INF, "the Land has free ground")
	ed._place_new("decor_sav_tree", spot)
	_ok(MetaState.land_decor_placed.size() == 1, "placed")
	_ok(String(ed.get("_sel_id")) == "", "selection cleared when storage empty")
	if MetaState.land_decor_placed.is_empty():
		_fail_out()
		return
	ed.set("_sel_idx", 0)
	ed.rotate_selected()
	_ok(int(MetaState.land_decor_placed[0]["rot"]) == 1, "rotated one step")
	ed._move_to(0, spot2)
	_ok(is_equal_approx(float(MetaState.land_decor_placed[0]["z"]), spot2.z), "moved")
	var saved: Dictionary = JSON.parse_string(SaveStore.read_text(MetaState.SAVE_PATH))
	_ok((saved["land_decor_placed"] as Array).size() == 1, "persisted through SaveStore")
	hub._handle_key(KEY_ESCAPE)
	_ok(not ed.active and (hub.get("_hud_br") as Control).visible, "Esc leaves, hub back")
	hub.queue_free()
	await get_tree().process_frame
	var hub2: LandHub = (load("res://scenes/land/Land.tscn") as PackedScene).instantiate()
	add_child(hub2)
	await get_tree().process_frame
	var n := 0
	for c in hub2.get_children():
		if c is Node3D and absf((c as Node3D).position.x - spot2.x) < 0.01 and absf((c as Node3D).position.z - spot2.z) < 0.01 and c.scale.x < 0.9:
			n += 1
	_ok(n == 1, "decor shows again on the next Land load (%d)" % n)
	var ed2: LandEdit = hub2.get("_edit")
	ed2.enter()
	ed2.set("_sel_idx", 0)
	ed2.store_selected()
	_ok(MetaState.land_decor_placed.is_empty() and int(MetaState.land_decor_owned["decor_sav_tree"]) == 1, "store keeps the copy")
	hub2.queue_free()
	g.restore()
	for x in _f:
		print("FAIL ", x)
	print("t_decor_edit: %s" % ("PASS" if _f.is_empty() else "FAIL"))
	get_tree().quit(1 if not _f.is_empty() else 0)

func _fail_out() -> void:
	for x in _f:
		print("FAIL ", x)
	get_tree().quit(1)
