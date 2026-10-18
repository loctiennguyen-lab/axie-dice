extends Node
## QA: capture the Land hub from the game viewport (not the screen) and measure FPS.
## godot --path godot --resolution 1920x1080 res://tests/qa_land_capture.tscn -- --out=/path/x.png [--run] [--secs=4]
## Not headless: the dummy rasterizer returns a blank image.

func _ready() -> void:
	var out := "user://land.png"
	var secs := 4.0
	var with_run := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.get_slice("=", 1)
		elif a.begins_with("--secs="):
			secs = float(a.get_slice("=", 1))
		elif a.begins_with("--tier="):
			LandHub.tier_override = int(a.get_slice("=", 1))
		elif a.begins_with("--qa="):
			for kv in a.get_slice("=", 1).split(","):
				LandHub.qa[kv.get_slice(":", 0)] = kv.get_slice(":", 1) != "0"
		elif a.begins_with("--frame="):
			MetaState.equipped_frame = a.get_slice("=", 1)   # in memory only
		elif a == "--run":
			with_run = true
	MetaState.tutorial_seen = true   # in memory only, never saved
	var hub := (load("res://scenes/land/Land.tscn") as PackedScene).instantiate()
	if with_run:
		hub.set("_force_run", true)
	add_child(hub)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var frames := 0
	var t := 0.0
	var warm := 1.5
	while t < warm + secs:
		await get_tree().process_frame
		t += get_process_delta_time()
		if t > warm:
			frames += 1
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("LAND_CAPTURE size=%s fps=%.1f shot=%s" % [str(get_viewport().get_visible_rect().size), frames / secs, out])
	get_tree().quit(0)
