extends Node
## QA-only, UI-05 b23 lane S11b: shots of 19-store--* .
##   ADT_EVIDENCE_DIR=production/qa/ui05-b23/s11b godot/tools/shot.sh res://tests/qa_ui5_store_capture.tscn 1280x720
var _guard := SaveGuard.new()
var _dir := QaPaths.evidence_dir()


func _shot(frame: String, small: bool) -> void:
	for _i in 10:
		await get_tree().process_frame
	var path := "%s/%s%s.png" % [_dir, frame, "--1280" if small else ""]
	get_viewport().get_texture().get_image().save_png(path)
	print("qa_ui5_store_capture: saved ", path)


func _make(state := "normal", remote := false) -> StoreScreen:
	var s: StoreScreen = load("res://scenes/store/StoreScreen.tscn").instantiate()
	s.use_account = false
	s.state = state
	s.remote_on = remote
	s.no_scene_change = true
	s.test_mode = true
	add_child(s)
	return s


func _ready() -> void:
	_guard.capture()
	DirAccess.make_dir_recursive_absolute(_dir)
	var small := get_window().size.x < 1600
	UI3Theme.set_scale_override(2.0 / 3.0 if small else 1.0)
	MetaState.gems_cache = 400
	MetaState.gem_gift_day = ""
	MetaState.cosmetics_owned.clear()
	var s := _make()
	var gem: Dictionary = (load("res://scripts/meta/economy_db.gd") as Script).get_table("gem")
	await _shot("19-store--gem-packs", small)
	s.select("usd_%d" % int((gem.store.gem_packs as Array)[1].gems))
	await _shot("19-store--gem-pack-picked", small)
	s.set_tab("cosmetics")
	await _shot("19-store--cosmetics", small)
	var items := s.cosmetic_items()
	s.select("cos_" + String(items[0].id))
	await _shot("19-store--cosmetic-picked", small)
	MetaState.gems_cache = 10
	s.select("cos_" + String(items[items.size() - 1].id))
	await _shot("19-store--short-of-gem", small)
	MetaState.gems_cache = 400
	s.set_tab("tickets")
	s.select("ticket_%d" % int((gem.store.ticket_bundles as Array)[1].tickets))
	await _shot("19-store--tickets", small)
	(s.find_child("BuyButton", true, false) as Button).pressed.emit()   # the real path: 15 tickets / Adds 15 Echo Box tickets.
	await _shot("19-store--confirm", small)
	s.close_modal()
	MetaState.gems_cache = 5000
	s.set_tab("cosmetics")
	s.buy_cosmetic(String(items[0].id), String(items[0].rarity))
	s.select("cos_" + String(items[0].id))
	await _shot("19-store--owned-result", small)
	s.set_tab("moon")
	await _shot("19-store--moon-card", small)
	MetaState.gems_cache = 400
	s.set_tab("tickets")
	s.claim_gift()
	await _shot("19-store--gift-claimed", small)
	MetaState.gem_gift_day = ""
	MetaState.gems_cache = int(gem.gift.balance_cap)
	s._refresh()
	await _shot("19-store--gem-full", small)
	s.queue_free()
	MetaState.gems_cache = 400
	MetaState.gem_gift_day = ""
	var o := _make("offline", true)
	o.set_tab("cosmetics")
	o.select("cos_" + String(items[1].id))
	await _shot("19-store--offline", small)
	o.queue_free()
	var g := _make("guest", true)
	g.set_tab("cosmetics")
	g.select("cos_" + String(items[1].id))
	await _shot("19-store--guest", small)
	_guard.restore()
	get_tree().quit(0)
