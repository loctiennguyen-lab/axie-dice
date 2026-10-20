extends Node
## QA: Land v1 Edit Land capture (in-memory state, never saved). Not headless.
## godot --path godot --resolution 1920x1080 res://tests/qa_land_edit_capture.tscn -- --out=x.png [--tab=place|craft|rewards] [--view] [--ghost]
func _ready() -> void:
	var out := "user://land_edit.png"
	var tab := "place"
	var view := false
	var ghost := false
	var args: Array = Array(OS.get_cmdline_user_args()) + Array(OS.get_environment("QA_ARGS").split(" ", false))   # shot.sh passes no user args: use env QA_ARGS
	for a in args:
		if a.begins_with("--out="):
			out = a.get_slice("=", 1)
		elif a.begins_with("--tab="):
			tab = a.get_slice("=", 1)
		elif a == "--view":
			view = true
		elif a == "--ghost":
			ghost = true
	MetaState.tutorial_seen = true
	MetaState.land_tier = 4
	MetaState.shard_pool = 500
	MetaState.land_decor_owned = {"decor_sav_tree": 3, "decor_sav_rock": 2, "decor_for_flower": 2, "decor_arc_stone": 2,
		"decor_mys_tree": 1, "decor_sav_shrub": 2}
	MetaState.land_decor_placed = [
		{"id": "decor_sav_tree", "x": -11.0, "z": 9.0, "rot": 0}, {"id": "decor_sav_tree", "x": -8.5, "z": 12.0, "rot": 2},
		{"id": "decor_sav_rock", "x": 11.0, "z": -10.0, "rot": 1}, {"id": "decor_for_flower", "x": 9.0, "z": -12.0, "rot": 0},
		{"id": "decor_arc_stone", "x": 12.0, "z": 10.0, "rot": 3}, {"id": "decor_mys_tree", "x": -12.0, "z": -9.0, "rot": 0}]
	var hub := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate()
	add_child(hub)
	for i in 20:
		await get_tree().process_frame
	var ed: LandEdit = hub.get("_edit")
	if not view:
		ed.enter()
		ed._set_tab(tab)
		if ghost:
			ed._pick_stored("decor_sav_shrub")
			# a screen point over empty ground, then one on the Portal zone (invalid)
			ed._on_motion(Vector2(1000, 760))
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("CAPTURE ", out)
	get_tree().quit(0)
