extends Node
## QA: M15 Land upgrade screen capture (in-memory state, never saved). Not headless.
## godot --path godot --resolution 1920x1080 res://tests/qa_land_upgrade_capture.tscn -- --out=x.png [--tier=2] [--stone=41200]

func _ready() -> void:
	var out := "user://land_upgrade.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.get_slice("=", 1)
		elif a.begins_with("--tier="):
			MetaState.land_tier = int(a.get_slice("=", 1))
		elif a.begins_with("--stone="):
			MetaState.stone = int(a.get_slice("=", 1))
	var s: LandUpgradeScreen = load("res://scenes/land_upgrade/LandUpgrade.tscn").instantiate()
	s.no_scene_change = true
	add_child(s)
	for i in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	print("CAPTURE ", out)
	get_tree().quit(0)
