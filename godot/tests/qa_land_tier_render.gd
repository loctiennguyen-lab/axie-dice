extends Node
## QA (not headless): renders the Land at each of the 6 tiers without HUD and saves
## res://assets/land/tier_previews/tier_<n>.png (640 wide) for the Land upgrade screen. In-memory only, nothing saved.
## godot --path godot --resolution 1920x1080 res://tests/qa_land_tier_render.tscn

func _ready() -> void:
	MetaState.tutorial_seen = true   # in memory only
	var dir := ProjectSettings.globalize_path("res://assets/land/tier_previews")
	DirAccess.make_dir_recursive_absolute(dir)
	for n in range(1, 7):
		LandHub.tier_override = n
		var hub: Node = (load("res://scenes/land/Land.tscn") as PackedScene).instantiate()
		add_child(hub)
		for i in 90:
			await get_tree().process_frame
		var ui = hub.get("_ui")
		if ui is Control:
			(ui as Control).visible = false
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.resize(640, int(640.0 * img.get_height() / img.get_width()), Image.INTERPOLATE_LANCZOS)
		img.save_png("%s/tier_%d.png" % [dir, n])
		hub.queue_free()
		await get_tree().process_frame
	LandHub.tier_override = 0
	print("TIER_RENDER done")
	get_tree().quit(0)
