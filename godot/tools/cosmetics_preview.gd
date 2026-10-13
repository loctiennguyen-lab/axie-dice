extends Control
## Dev preview: dice tray with skins + profile frames. Run without --headless; pass
## `-- --shot=/path.png` to save a screenshot and quit.
func _ready() -> void:
	size = Vector2(1280, 520)
	var bg := ColorRect.new(); bg.color = Color("#2a1d3a"); bg.set_anchors_preset(PRESET_FULL_RECT); add_child(bg)
	var dice := ["die_c_reed", "die_u_moss", "die_r_aqua", "die_e_rune", "die_l_gold", "die_m_moon", "die_m_redcrystal"]
	var x := 20.0
	for id in dice:
		var n := CosmeticArt.make_node(id, 150); n.position = Vector2(x, 20); add_child(n); x += 170
	x = 20.0
	var frames := ["frame_c_beast", "frame_u_pond", "frame_r_frost", "frame_e_runering", "frame_l_sunburst", "frame_m_eclipse"]
	for id in frames:
		var av := ColorRect.new(); av.color = Color("#7ab"); av.size = Vector2(84, 84); av.position = Vector2(x + 33, 273); add_child(av)
		var n := CosmeticArt.make_node(id, 150); n.position = Vector2(x, 240); add_child(n); x += 190
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			await get_tree().create_timer(0.5).timeout
			get_viewport().get_texture().get_image().save_png(a.substr(7))
			get_tree().quit()
